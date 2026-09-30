#===============================================================================
#  Fight Menu functionality part
#===============================================================================

#===============================================================================
#  Pre-Battle Pokedex Snapshot (Fix for Effectiveness Text)
#===============================================================================
class Battle
  attr_accessor :already_known_species

  alias ebdx_known_species_init initialize
  def initialize(*args)
    ebdx_known_species_init(*args)
    @already_known_species = []
    # Check the opponent's party before the battle officially starts
    if $player && $player.pokedex && @party2
      @party2.each do |pkmn|
        next if !pkmn
        # If it was already in the Pokedex before this fight, remember it!
        @already_known_species.push(pkmn.species) if $player.pokedex.seen?(pkmn.species)
      end
    end
  end
end

class Battle::Scene
  #-----------------------------------------------------------------------------
  #  main fight menu override
  #-----------------------------------------------------------------------------
  def pbFightMenu(idxBattler, megaEvoPossible = false)
    battler = @battle.battlers[idxBattler]
    self.clearMessageWindow
    @fightWindow.battler = battler
    @fightWindow.refreshMegaButton

    moveIndex = 0
    if battler.moves[@lastMove[idxBattler]] && battler.moves[@lastMove[idxBattler]].id
      moveIndex = @lastMove[idxBattler]
    end
    @fightWindow.index = (battler.moves[moveIndex].id != 0) ? moveIndex : 0
    
    # Initialize mode (0: Moves, 1: Mega). Keep existing mode if reloading.
    @fightWindow.mode = 0 if !@fightWindow.mode

    @fightWindow.generateButtons
    @sprites["dataBox_#{idxBattler}"].selected = true
    pbSEPlay("EBDX/SE_Zoom4", 50)
    @fightWindow.showPlay

    # Init last mouse position
    @last_mouse_x = Input.mouse_x
    @last_mouse_y = Input.mouse_y

    loop do
      oldIndex = @fightWindow.index
      self.updateWindow(@fightWindow)

      # --- MOUSE HOVER LOGIC ---
      current_mouse_x = Input.mouse_x
      current_mouse_y = Input.mouse_y

      if current_mouse_x != @last_mouse_x || current_mouse_y != @last_mouse_y
        # Check Moves
        mouse_idx = @fightWindow.getMouseIndex
        if mouse_idx >= 0
          if @fightWindow.mode != 0 || @fightWindow.index != mouse_idx
            @fightWindow.mode = 0
            @fightWindow.index = mouse_idx
            pbSEPlay("EBDX/SE_Select1")
          end
        # Check Mega
        elsif @fightWindow.isMouseOverMega?
          if @fightWindow.mode != 1 && @fightWindow.can_mega_evolve?
            @fightWindow.mode = 1
            pbSEPlay("EBDX/SE_Select1")
          end
        end
        @last_mouse_x = current_mouse_x
        @last_mouse_y = current_mouse_y
      end
      # -------------------------

      # --- KEYBOARD NAVIGATION ---
      if Input.trigger?(Input::UP)
        if @fightWindow.mode == 0
          @fightWindow.index -= 1
          @fightWindow.index = @fightWindow.nummoves - 1 if @fightWindow.index < 0
        end
      elsif Input.trigger?(Input::DOWN)
        if @fightWindow.mode == 0
          @fightWindow.index += 1
          @fightWindow.index = 0 if @fightWindow.index >= @fightWindow.nummoves
        end
      elsif Input.trigger?(Input::LEFT)
        # Navigate TO Mega Button
        if @fightWindow.mode == 0 && @fightWindow.can_mega_evolve?
          @fightWindow.mode = 1
          pbSEPlay("EBDX/SE_Select1")
        end
      elsif Input.trigger?(Input::RIGHT)
        # Return TO Moves
        if @fightWindow.mode == 1
          @fightWindow.mode = 0
          pbSEPlay("EBDX/SE_Select1")
        end
      end

      pbSEPlay("EBDX/SE_Select1") if @fightWindow.index != oldIndex

      # --- CONFIRM SELECTION (Keyboard 'C' or Mouse Click) ---
      if Input.trigger?(Input::C) || Input.trigger?(Input::MOUSELEFT)
        
        # If Mouse Click, validate target
        if Input.trigger?(Input::MOUSELEFT)
          
          # Clicked Back Button with Scale Animation
          if @fightWindow.isMouseOverBack?
            # --- 0.7 SCALE SHRINK & RETURN ANIMATION ---
            4.times do |i|
              scale = 1.0 - ((i + 1) * 0.075)
              @fightWindow.backButton.zoom_x = scale
              @fightWindow.backButton.zoom_y = scale
              Graphics.update
              Input.update
            end
            4.times do |i|
              scale = 0.7 + ((i + 1) * 0.075)
              @fightWindow.backButton.zoom_x = scale
              @fightWindow.backButton.zoom_y = scale
              Graphics.update
              Input.update
            end
            # -------------------------------------------
            pbPlayCancelSE
            break if yield -1
          end

          clicked_idx = @fightWindow.getMouseIndex
          if clicked_idx >= 0
             # Clicked a Move
             @fightWindow.mode = 0
             @fightWindow.index = clicked_idx if @fightWindow.index != clicked_idx
             
             # Play Move Button Click Animation
             @fightWindow.animateButtonPress(clicked_idx)
             
             pbSEPlay("EBDX/SE_Select2")
             break if yield @fightWindow.index
          elsif @fightWindow.isMouseOverMega?
             # Clicked Mega
             @fightWindow.mode = 1
          else
             # Clicked empty space
             next 
          end
        end

        # ACTION BASED ON MODE (Keyboard 'C' fallback)
        if @fightWindow.mode == 1
          # Toggle Mega
          if @fightWindow.can_mega_evolve?
             @fightWindow.megaButtonTrigger
             pbSEPlay("DX Action Button")
             break if yield -2 
          end
        else
          # Select Move via Keyboard
          @fightWindow.animateButtonPress(@fightWindow.index)
          pbSEPlay("EBDX/SE_Select2")
          break if yield @fightWindow.index
        end
        
      elsif Input.trigger?(Input::B)
        pbPlayCancelSE
        break if yield -1
      elsif Input.trigger?(Input::A)
        # Shortcut key for Mega
        if @fightWindow.can_mega_evolve?
          @fightWindow.megaButtonTrigger
          pbSEPlay("DX Action Button")
          @fightWindow.mode = 1 if @fightWindow.mode == 0 
          break if yield -2
        end
      end
    end

    self.pbResetParams if @ret > -1
    @fightWindow.hidePlay
    self.pbDeselectAll
    @lastMove[idxBattler] = @fightWindow.index
  end
  #-----------------------------------------------------------------------------
end

#===============================================================================
#  Fight Menu (Next Generation)
#===============================================================================
class FightWindowEBDX
  attr_accessor :index
  attr_accessor :mode # 0: Moves, 1: Mega
  attr_accessor :battler
  attr_accessor :refreshpos
  attr_reader :nummoves
  attr_reader :backButton # Exposed for click animation
  attr_reader :button     # Exposed for move click animations

  #-----------------------------------------------------------------------------
  def refreshMegaButton
    @showMega = false
    @megaSelected = false
    @megaFlare.visible = false if @megaFlare
    
    return if !@battler || !@battle

    # 1. Basic Capability Check
    can_mega = @battle.pbCanMegaEvolve?(@battler.index)
    
    # 2. Strict History Check (One Per Battle Per Side)
    side = @battler.idxOwnSide
    if @battle.respond_to?(:megaEvolution)
       history = @battle.megaEvolution[side]
       if history.is_a?(Array)
         if history.flatten.any? { |val| val != -1 }
            can_mega = false
         end
       end
    end

    # 3. Active Field Check
    @battle.battlers.each do |b|
      if b && b.idxOwnSide == side && b.mega?
        can_mega = false
      end
    end

    # 4. Handle Selection State
    is_candidate = false
    if @battle.respond_to?(:mega_evolve_candidate)
       is_candidate = (@battle.mega_evolve_candidate == @battler.index)
    end
    
    if is_candidate
       @megaSelected = true
       @showMega = true
    else
       @megaSelected = false
       @showMega = can_mega
    end

    @megaButton.visible = @showMega
    @megaFlare.visible = (@showMega && @megaSelected)
  end

  def can_mega_evolve?
    return @showMega
  end
  #-----------------------------------------------------------------------------
  def inspect
    str = self.to_s.chop
    str << format(' index: %s>', @index)
    return str
  end
  #-----------------------------------------------------------------------------
  def initialize(viewport = nil, battle = nil, scene = nil)
    @viewport = viewport
    @battle = battle
    @scene = scene
    @index = 0
    @mode = 0
    @oldindex = -1
    @over = false
    @refreshpos = false
    @battler = nil
    @nummoves = 0

    @path = "Graphics/EBDX/Pictures/UI/"
    self.applyMetrics

    @buttonBitmap = pbBitmap(@path + @cmdImg)
    
    lang = pbGetSelectedLanguage
    typeBitmapPath = pbResolveBitmap("Graphics/EBDX/Pictures/UI/types_"+lang)
    @typebitmap = typeBitmapPath ? pbBitmap(typeBitmapPath) : pbBitmap(@path + @typImg)
    @typebitmap = pbBitmap("Graphics/EBDX/Pictures/UI/types") if !@typebitmap
    @catBitmap = pbBitmap(@path + @catImg)

    @background = Sprite.new(@viewport)
    @background.create_rect(@viewport.width,64,Color.new(0,0,0,0))
    @background.bitmap = pbBitmap(@path + @barImg) if !@barImg.nil?
    @background.y = Graphics.height - @background.bitmap.height
    @background.z = 100

    # --- BACK BUTTON SETUP (Center Origin & Position) ---
    back_x, back_y = 16, 16
    @backBmp = pbBitmap(@path + "back")
    @backSelBmp = pbBitmap(@path + "back")
    @backButton = Sprite.new(@viewport)
    @backButton.bitmap = @backBmp
    @backButton.x = back_x + 48
    @backButton.y = back_y + 48
    @backButton.ox = 48
    @backButton.oy = 48
    @backButton.z = 101
    @backButton.visible = false

    # --- MEGA BUTTON SETUP ---
    @megaButton = Sprite.new(@viewport)
    @megaButton.bitmap = pbBitmap(@path + @megaImg)
    @megaButton.z = 101
    @megaButton.ox = @megaButton.bitmap.width / 2
    @megaButton.oy = @megaButton.bitmap.height / 2
    
    # --- CALCULATE FINAL POSITION ---
    @mega_target_x = @viewport.width - 392 - (@megaButton.bitmap.width / 2)
    @mega_target_y = @viewport.height - 8 - (@megaButton.bitmap.height / 2)
    
    @megaButton.x = @mega_target_x
    @megaButton.y = @mega_target_y
    
    # --- RAINBOW FLARE (TINT) SPRITE ---
    @megaFlare = Sprite.new(@viewport)
    @megaFlare.bitmap = @megaButton.bitmap.clone
    @megaFlare.ox = @megaButton.ox
    @megaFlare.oy = @megaButton.oy
    @megaFlare.x = @megaButton.x
    @megaFlare.y = @megaButton.y
    @megaFlare.z = 102 # On Top of Button
    @megaFlare.blend_type = 1 # Additive (Glow)
    @megaFlare.visible = false
    @megaFlare.opacity = 0
    
    # --- PARTICLE FIRE SYSTEM SETUP ---
    @particles = []
    @megaSelected = false
    @rainbow_step = 0
    
    @particle_bmp = Bitmap.new(8, 8)
    @particle_bmp.fill_rect(2, 0, 4, 8, Color.new(255, 255, 255))
    @particle_bmp.fill_rect(0, 2, 8, 4, Color.new(255, 255, 255))
    # ----------------------------------

    @sel = Sprite.new(@viewport)
    @sel.bitmap = pbBitmap(@path + "arrow")
    @sel.ox = @sel.bitmap.width / 2
    @sel.oy = @sel.bitmap.height / 2
    @sel.z = 199
    @sel.visible = true
    @sel_bounce_x = 0
    @sel_bounce_dir = 1
    @sel_bounce_speed = 0.8
    @sel_bounce_limit = 3

    @button = {}
    @moved = false
    @showMega = false

    eff = [_INTL("Normal damage"),_INTL("Not very effective"),_INTL("Super effective"),_INTL("No effect")]
    @typeInd = Sprite.new(@viewport)
    @typeInd.bitmap = Bitmap.new(228,24*4)
    pbSetSmallFont(@typeInd.bitmap)
    for i in 0...4
      pbDrawOutlineText(@typeInd.bitmap,0,24*i + 5,228,24,eff[i],Color.new(255, 255, 255),Color.new(0,0,0,0),1)
    end
    @typeInd.src_rect.set(0,0,228,24)
    @typeInd.ox = 228/2
    @typeInd.oy = 16
    @typeInd.z = 200
    @typeInd.visible = false
  end

  #-----------------------------------------------------------------------------
  def applyMetrics
    @cmdImg = "moveSelButtons"
    @selImg = "cmdSel"
    @typImg = "types"
    @catImg = "category"
    @megaImg = "megaButton"
    @barImg = nil
    @showTypeAdvantage = false
    d1 = EliteBattle.get(:nextUI)
    d1 = d1[:FIGHTMENU] if d1 && d1.has_key?(:FIGHTMENU)
    d2 = EliteBattle.get_data(:FIGHTMENU, :Metrics, :METRICS)
    d7 = EliteBattle.get_map_data(:FIGHTMENU_METRICS)
    d6 = @battle.opponent ? EliteBattle.get_trainer_data(@battle.opponent[0].trainer_type, :FIGHTMENU_METRICS, @battle.opponent[0]) : nil
    d5 = !@battle.opponent ? EliteBattle.get_data(@battle.battlers[1].species, :Species, :FIGHTMENU_METRICS, (@battle.battlers[1].form rescue 0)) : nil
    for data in [d2, d7, d6, d5, d1]
      next if data.nil?
      @megaImg = data[:MEGABUTTONGRAPHIC] if data.has_key?(:MEGABUTTONGRAPHIC) && data[:MEGABUTTONGRAPHIC].is_a?(String)
      @cmdImg = data[:BUTTONGRAPHIC] if data.has_key?(:BUTTONGRAPHIC) && data[:BUTTONGRAPHIC].is_a?(String)
      @selImg = data[:SELECTORGRAPHIC] if data.has_key?(:SELECTORGRAPHIC) && data[:SELECTORGRAPHIC].is_a?(String)
      @barImg = data[:BARGRAPHIC] if data.has_key?(:BARGRAPHIC) && data[:BARGRAPHIC].is_a?(String)
      @typImg = data[:TYPEGRAPHIC] if data.has_key?(:TYPEGRAPHIC) && data[:TYPEGRAPHIC].is_a?(String)
      @catImg = data[:CATEGORYGRAPHIC] if data.has_key?(:CATEGORYGRAPHIC) && data[:CATEGORYGRAPHIC].is_a?(String)
      @showTypeAdvantage = data[:SHOWTYPEADVANTAGE] if data.has_key?(:SHOWTYPEADVANTAGE)
    end
  end

  #-----------------------------------------------------------------------------
  def generateButtons
    @moves = @battler.moves
    @x = []; @y = []
    @nummoves = 0

    for i in 0...4
      @button[i.to_s]&.dispose
      @nummoves += 1 if @moves[i] && @moves[i].id
    end

    target = @battler.pbDirectOpposing
    
    target_known = false
    if target && target.pokemon
      target_known = @battle.already_known_species.include?(target.species) || $player.pokedex.owned?(target.species)
    end

    margin_x = 8
    margin_y = 8
    manual_offset_y = -72
    spacing = 78
    
    # Center-origin offsets for smooth scaling animation
    width_half = 180
    height_half = 36

    for i in 0...@nummoves
      @x[i] = @viewport.width - margin_x - width_half
      @y[i] = @viewport.height - margin_y - (@nummoves - i - 1) * spacing + manual_offset_y + height_half
    end

    for i in 0...@nummoves
      battle_move = @moves[i]
      movedata = GameData::Move.get(battle_move.id)
      category = movedata.physical? ? 0 : (movedata.special? ? 1 : 2)
      type_data = GameData::Type.get(movedata.type)
      type_icon = type_data.icon_position

      @button[i.to_s] = Sprite.new(@viewport)
      @button[i.to_s].param = category
      @button[i.to_s].z = 82
      @button[i.to_s].bitmap = Bitmap.new(360*2,72)
      @button[i.to_s].bitmap.blt(0,0,@buttonBitmap,Rect.new(0,type_icon*72,360,72))
      @button[i.to_s].bitmap.blt(3,72,@typebitmap,Rect.new(0,type_icon*22,72,22))

      pbSetSmallFont(@button[i.to_s].bitmap)
      
      eff_text = ""
      if target_known && !@battle.doublebattle? && !@battle.triplebattle? && movedata.category != 2
        begin
          t_types = target.types
          type2 = t_types[1] || t_types[0]
          mod = Effectiveness.calculate(movedata.type, t_types[0], type2)
          
          if Effectiveness.ineffective?(mod)
            eff_text = _INTL("No effect")
          elsif Effectiveness.not_very_effective?(mod)
            eff_text = _INTL("Not effective")
          elsif Effectiveness.super_effective?(mod)
            eff_text = _INTL("Super effective")
          else
            eff_text = _INTL("Effective")
          end
        rescue
          eff_text = ""
        end
      end

      if eff_text != "" && eff_text != nil
      #move name
        @button[i.to_s].bitmap.font.size = 24
        text_name = [[movedata.name, 42, 12, 10, Color.new(0, 0, 0), Color.new(0,0,0,0)]]
        pbDrawTextPositions(@button[i.to_s].bitmap, text_name)
        
        @button[i.to_s].bitmap.font.size = 18
        text_eff = [[eff_text, 42, 40, 0, Color.new(0, 0, 0), Color.new(0,0,0,0)]]
        pbDrawTextPositions(@button[i.to_s].bitmap, text_eff)
      else
        @button[i.to_s].bitmap.font.size = 24
        text_name = [[movedata.name, 42, 22, 10, Color.new(0, 0, 0), Color.new(0,0,0,0)]]
        pbDrawTextPositions(@button[i.to_s].bitmap, text_name)
      end

      @button[i.to_s].bitmap.font.size = 24
      pp = "#{battle_move.pp}/#{battle_move.total_pp}"
      pbDrawOutlineText(@button[i.to_s].bitmap,-14,24,360,72,pp,Color.new(255, 255, 255),Color.new(0,0,0,0),2)

      @button[i.to_s].src_rect.set(0,0,360,72)
      @button[i.to_s].ox = width_half
      @button[i.to_s].oy = height_half
      @button[i.to_s].x = @x[i]
      @button[i.to_s].y = @y[i]
      @button[i.to_s].visible = true
    end
  end

  #-----------------------------------------------------------------------------
  #  Animate Move Button Click (0.7 Scale Shrink & Bounce)
  #-----------------------------------------------------------------------------
  def animateButtonPress(index)
    btn = @button[index.to_s]
    return if !btn || btn.disposed?
    
    4.times do |i|
      scale = 1.0 - ((i + 1) * 0.075)
      btn.zoom_x = scale
      btn.zoom_y = scale
      Graphics.update
      Input.update
    end
    4.times do |i|
      scale = 0.7 + ((i + 1) * 0.075)
      btn.zoom_x = scale
      btn.zoom_y = scale
      Graphics.update
      Input.update
    end
    btn.zoom_x = 1.0
    btn.zoom_y = 1.0
  end

  def show
    @sel.visible = false
    @typeInd.visible = false
    @background.y -= (@background.bitmap.height/8)
    @backButton.visible = true
    for i in 0...@nummoves
      @button[i.to_s].x = @x[i]
      @button[i.to_s].y = @y[i]
      @button[i.to_s].visible = true
    end
  end

  def showPlay
    @megaButton.y = @mega_target_y
    8.times do
      self.show; @scene.wait(1, true)
    end
  end

  def hide
    @sel.visible = false
    @typeInd.visible = false
    @background.y += (@background.bitmap.height/8)
    @backButton.visible = false
    @megaButton.y = @viewport.height + 100
    
    for i in 0...@nummoves
      @button[i.to_s].x = -200
      @button[i.to_s].visible = false
    end
    @showMega = false
    @megaFlare.visible = false
    
    if @particles
      @particles.each { |p| p[0].dispose if p[0] }
      @particles.clear
    end
  end

  def hidePlay
    8.times do
      self.hide; @scene.wait(1, true)
    end
  end

  def megaButton
    @showMega = true
  end

  def megaButtonTrigger
    @megaSelected = !@megaSelected
  end
  
  #-----------------------------------------------------------------------------
  #  Helper: Get Mouse Index for Moves (Updated for Center Origin)
  #-----------------------------------------------------------------------------
  def getMouseIndex
    return -1 if !defined?(Input.mouse_x)
    mx, my = Input.mouse_x, Input.mouse_y
    
    for i in 0...@nummoves
      sprite = @button["#{i}"]
      next if !sprite || sprite.disposed? || !sprite.visible
      
      s_width = 360 
      s_height = 72
      # With center origin (ox = 180, oy = 36), calculate bounding box:
      s_left = sprite.x - 180
      s_right = sprite.x + 180
      s_top = sprite.y - 36
      s_bottom = sprite.y + 36
      
      if mx >= s_left && mx < s_right && my >= s_top && my < s_bottom
        return i
      end
    end
    return -1
  end

  #-----------------------------------------------------------------------------
  #  Helper: Check if mouse is over Mega Button
  #-----------------------------------------------------------------------------
  def isMouseOverMega?
    return false if !@showMega || !@megaButton || !@megaButton.visible
    return false if !defined?(Input.mouse_x)
    mx, my = Input.mouse_x, Input.mouse_y
    
    w = 104
    h = 90
    l = @megaButton.x - (w/2)
    r = @megaButton.x + (w/2)
    t = @megaButton.y - (h/2)
    b = @megaButton.y + (h/2)
    
    return (mx >= l && mx < r && my >= t && my < b)
  end

  #-----------------------------------------------------------------------------
  #  Helper: Check if mouse is over Back Button
  #-----------------------------------------------------------------------------
  def isMouseOverBack?
    return false if !@backButton || !@backButton.visible
    return false if !defined?(Input.mouse_x)
    mx, my = Input.mouse_x, Input.mouse_y
    
    left = @backButton.x - 48
    top = @backButton.y - 48
    return (mx >= left && mx < left + 96 && my >= top && my < top + 96)
  end

  #-----------------------------------------------------------------------------
  #  UPDATE: Handles Animation, Particles, and Cursor
  #-----------------------------------------------------------------------------
  def update
    @sel.visible = true

    if isMouseOverBack? && Input.press?(Input::MOUSELEFT)
      @backButton.bitmap = @backSelBmp
    else
      @backButton.bitmap = @backBmp
    end

    if @showMega
      @megaButton.y -= 10 if @megaButton.y > @mega_target_y
      @megaFlare.x = @megaButton.x
      @megaFlare.y = @megaButton.y
      
      if @megaSelected
        @megaFlare.visible = true
        @rainbow_step += 0.2
        r = (Math.sin(@rainbow_step) * 127 + 128).to_i
        g = (Math.sin(@rainbow_step + 2) * 127 + 128).to_i
        b = (Math.sin(@rainbow_step + 4) * 127 + 128).to_i
        rainbow_color = Color.new(r, g, b)
        
        @megaFlare.color = rainbow_color
        @megaFlare.opacity = 128 + (Math.sin(@rainbow_step * 2) * 30).to_i

        2.times do 
          sprite = Sprite.new(@viewport)
          sprite.bitmap = @particle_bmp
          sprite.ox = 4
          sprite.oy = 4
          sprite.z = 102
          
          w_half = @megaButton.bitmap.width / 2 - 10
          sprite.x = @megaButton.x + rand(w_half * 2) - w_half
          sprite.y = @megaButton.y + (@megaButton.bitmap.height / 2) - 10
          
          sprite.blend_type = 1
          sprite.color = rainbow_color
          
          speed_x = (rand(10) - 5) * 0.2
          speed_y = -2 - rand(3)
          life = 20 + rand(20)
          @particles.push([sprite, speed_x, speed_y, life, life])
        end
      else
        @megaFlare.visible = false
      end

      @particles.each_with_index do |p, i|
        sprite, sx, sy, life, max_life = p
        sprite.x += sx
        sprite.y += sy
        p[3] -= 1
        
        prog = 1.0 - (life.to_f / max_life.to_f)
        sprite.opacity = 255 * (1.0 - prog)
        
        if p[3] <= 0
          sprite.dispose
          @particles[i] = nil
        end
      end
      @particles.compact!
    else
      @megaFlare.visible = false
      if !@particles.empty?
        @particles.each { |p| p[0].dispose }
        @particles.clear
      end
    end

    if @oldindex != @index
      @oldindex = @index
      if @showTypeAdvantage && !(@battle.doublebattle? || @battle.triplebattle?)
        move = @battler.moves[@index]
        @modifier = move.pbCalcTypeMod(move.type, @player, @opponent)
      end
    end

    if @mode == 1 # MEGA MODE
      @sel.x = @megaButton.x - 60 
      @sel.y = @megaButton.y
    else # MOVES MODE (Adjusted for center origin selector placement)
      @sel.x = @button["#{@index}"].x - 180 - 18
      @sel.y = @button["#{@index}"].y
    end

    @sel_bounce_x ||= 0
    @sel_bounce_dir ||= 1
    @sel_bounce_speed ||= 0.8
    @sel_bounce_limit ||= 4
    @sel_bounce_x += @sel_bounce_dir * @sel_bounce_speed
    @sel_bounce_dir *= -1 if @sel_bounce_x > @sel_bounce_limit || @sel_bounce_x < -@sel_bounce_limit
    @sel.x += @sel_bounce_x
    @sel.update

    if @mode == 0 && @showTypeAdvantage && !(@battle.doublebattle? || @battle.triplebattle?)
      @typeInd.visible = true
      @typeInd.y = @button["#{@index}"].y
      @typeInd.x = @button["#{@index}"].x - 180
      eff = 0
      if @button["#{@index}"].param == 2
        eff = 4
      elsif @modifier == 0
        eff = 3
      elsif @modifier < 8
        eff = 1
      elsif @modifier > 8
        eff = 2
      end
      @typeInd.src_rect.y = 24 * eff
    else
      @typeInd.visible = false
    end
  end

  #-----------------------------------------------------------------------------
  def dispose
    @buttonBitmap.dispose
    @catBitmap.dispose
    @typeBitmap.dispose if @typeBitmap
    @background.dispose
    @megaButton.dispose
    @megaFlare.dispose if @megaFlare
    @typeInd.dispose
    pbDisposeSpriteHash(@button)
    
    @backBmp.dispose if @backBmp
    @backSelBmp.dispose if @backSelBmp
    @backButton.dispose if @backButton

    if @particles
      @particles.each { |p| p[0].dispose if p[0] }
      @particles.clear
    end
    @particle_bmp.dispose if @particle_bmp
  end
end
