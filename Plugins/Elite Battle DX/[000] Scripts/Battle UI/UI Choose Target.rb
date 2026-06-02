#===============================================================================
#  Target selection UI (Clean Version - No Glow/Zoom)
#===============================================================================
class TargetWindowEBDX
  attr_reader :index, :buttons
  #-----------------------------------------------------------------------------
  def applyMetrics
    @btnImg = "btnEmpty"
    @btnImgFoe  = "redbutton"
    @btnImgAlly = "bluebutton"
    d1 = EliteBattle.get(:nextUI)
    d1 = d1[:TARGETMENU] if !d1.nil? && d1.has_key?(:TARGETMENU)
    d2 = EliteBattle.get_data(:TARGETMENU, :Metrics, :METRICS)
    d7 = EliteBattle.get_map_data(:TARGETMENU_METRICS)
    d6 = @battle.opponent ? EliteBattle.get_trainer_data(@battle.opponent[0].trainer_type, :TARGETMENU_METRICS, @battle.opponent[0]) : nil
    d5 = !@battle.opponent ? EliteBattle.get_data(@battle.battlers[1].species, :Species, :TARGETMENU_METRICS, (@battle.battlers[1].form rescue 0)) : nil
    for data in [d2, d7, d6, d5, d1]
      if !data.nil?
        @btnImg = data[:BUTTONGRAPHIC] if data.has_key?(:BUTTONGRAPHIC) && data[:BUTTONGRAPHIC].is_a?(String)
      end
    end
  end
  #-----------------------------------------------------------------------------
  def initialize(viewport, battle, scene)
    @viewport = viewport
    @battle = battle
    @scene = scene
    @index = 0
    @disposed = false
    @buttons = {}
    @path = "Graphics/EBDX/Pictures/UI/"
    self.applyMetrics
    
    # --- ARROW BOBBING CURSOR ---
    @sel = Sprite.new(@viewport)
    @sel.bitmap = pbBitmap(@path + "arrow")
    @sel.ox = @sel.bitmap.width / 2
    @sel.oy = @sel.bitmap.height / 2
    @sel.z = 999999
    @sel.visible = false
    @sel_dir = 1
    @sel_speed = 1
    @sel_max = 4
    @sel_offset = 0
    @arrow_x_offset = -6 
    
    @background = Sprite.new(@viewport)
    @background.create_rect(@viewport.width, 64, Color.new(0, 0, 0, 0))
    @background.bitmap = pbBitmap(@path + @barImg) if !@barImg.nil?
    @background.y = Graphics.height - @background.bitmap.height + 80
    @background.z = 100

    # --- BACK BUTTON SETUP ---
    @backBmp = pbBitmap(@path + "back")
    @backSelBmp = pbBitmap(@path + "back_sel")
    @backButton = Sprite.new(@viewport)
    @backButton.bitmap = @backBmp
    @backButton.x = 16
    @backButton.y = 16
    @backButton.z = 101
    @backButton.visible = false
  end
  #-----------------------------------------------------------------------------
  def refresh(texts)
    pbDisposeSpriteHash(@buttons)
    bmp_foe  = pbBitmap(@path + @btnImgFoe)
    bmp_ally = pbBitmap(@path + @btnImgAlly)
    
    # --- CUSTOM METRICS ---
    fw = 128; fh = 98; fs = 12
    pw = 74;  ph = 64; ps = 20

    max_cols = @battle.pbMaxSize
    
    foe_grid_w = (max_cols * fw) + ((max_cols - 1) * fs)
    player_grid_w = (max_cols * pw) + ((max_cols - 1) * ps)
    
    final_foe_y = @viewport.height - fh - 98
    final_player_y = @viewport.height - ph - 12
    
    foe_y = final_foe_y + 240
    player_y = final_player_y + 240
    
    foe_start_x = @viewport.width - 20 - foe_grid_w
    player_start_x = @viewport.width - 60 - player_grid_w

    battlers = @battle.battlers
    for i in 0...battlers.length
      b = battlers[i]
      is_foe = b.opposes?
      
      bmp = is_foe ? bmp_foe : bmp_ally
      bw  = is_foe ? fw : pw
      bh  = is_foe ? fh : ph
      
      @buttons["#{i}"] = Sprite.new(@viewport)
      @buttons["#{i}"].bitmap = Bitmap.new(bw, bh)
      @buttons["#{i}"].bitmap.stretch_blt(Rect.new(0, 0, bw, bh), bmp, bmp.rect)
      
      if b.displayPokemon
        pkmn = b.displayPokemon
        icon = pbBitmap(GameData::Species.icon_filename_from_pokemon(pkmn))
        icon_w = icon.width / 2
        ix = (bw - icon_w) / 2
        iy = (bh - icon.height) / 2 - 9
        @buttons["#{i}"].bitmap.blt(ix, iy, icon, Rect.new(0, 0, icon_w, bh - 4 - iy), 216)
      end
      
      if b.hp <= 0
        @buttons["#{i}"].opacity = 180
        @buttons["#{i}"].color = Color.new(100, 100, 100, 160)
        @buttons["#{i}"].tone = Tone.new(-255, -255, -255) 
      elsif texts[i].nil?
        @buttons["#{i}"].opacity = 180
        @buttons["#{i}"].color = Color.new(100, 100, 100, 80)
      else
        @buttons["#{i}"].opacity = 255
        @buttons["#{i}"].color = Color.new(0, 0, 0, 0)
      end
      
      col = i / 2
      
      if is_foe
        @buttons["#{i}"].x = foe_start_x + col * (fw + fs)
        @buttons["#{i}"].y = foe_y
      else
        @buttons["#{i}"].x = player_start_x + col * (pw + ps)
        @buttons["#{i}"].y = player_y
      end
      
      @buttons["#{i}"].z = 100
    end
    
    bmp_foe.dispose
    bmp_ally.dispose
  end
  #-----------------------------------------------------------------------------
  def index=(val)
    @index = val
  end
  #-----------------------------------------------------------------------------
  #  Helper: Check if mouse is over Back Button
  #-----------------------------------------------------------------------------
  def isMouseOverBack?
    return false if !@backButton || !@backButton.visible
    return false if !defined?(Input.mouse_x)
    mx, my = Input.mouse_x, Input.mouse_y
    return (mx >= @backButton.x && mx < @backButton.x + 96 && my >= @backButton.y && my < @backButton.y + 96)
  end
  #-----------------------------------------------------------------------------
  def update
    # --- ARROW BOBBING ANIMATION ---
    @sel_offset += @sel_speed * @sel_dir
    @sel_dir *= -1 if @sel_offset.abs >= @sel_max
    
    # --- BACK BUTTON VISUAL STATE ---
    if isMouseOverBack? && Input.press?(Input::MOUSELEFT)
      @backButton.bitmap = @backSelBmp
    else
      @backButton.bitmap = @backBmp
    end

    btn = @buttons["#{@index}"]
    if btn && !btn.disposed?
      # Setup Cursor pointing at the left edge of the selected button
      @sel.visible = true
      @sel.x = btn.x + @sel_offset + @arrow_x_offset
      @sel.y = btn.y + (btn.bitmap.height / 2)
    else
      @sel.visible = false
    end
  end
  #-----------------------------------------------------------------------------
  def showPlay
    $ebd_target_active = true 
    @backButton.visible = true
    10.times do
      for key in @buttons.keys
        @buttons[key].y -= 24 
      end
      @background.y -= 8
      @scene.wait
    end
  end
  #-----------------------------------------------------------------------------
  def hidePlay
    $ebd_target_active = false 
    @sel.visible = false
    @backButton.visible = false
    10.times do
      for key in @buttons.keys
        @buttons[key].y += 24 
      end
      @background.y += 8
      @scene.wait
    end
  end
  #-----------------------------------------------------------------------------
  def dispose
    return if self.disposed?
    @sel.dispose
    @background.dispose
    @backBmp.dispose if @backBmp
    @backSelBmp.dispose if @backSelBmp
    @backButton.dispose if @backButton
    pbDisposeSpriteHash(@buttons)
    @disposed = true
  end
  def disposed?; return @disposed; end
end

#===============================================================================
#  Target Choice functionality part
#===============================================================================
class Battle::Scene
  alias pbChooseTarget_ebdx pbChooseTarget unless self.method_defined?(:pbChooseTarget_ebdx)
  def pbChooseTarget(idxBattler, target_data, visibleSprites = nil)
    
    $ebd_target_active = true 
    
    @fightWindow.hidePlay
    texts = pbCreateTargetTexts(idxBattler,target_data)
    mode = (target_data.num_targets == 1) ? 0 : 1
    @targetWindow.refresh(texts)
    
    first_opposing = (0...texts.length).find do |i|
      !texts[i].nil? && @battle.battlers[i].hp > 0 && @battle.battlers[i].opposes?(@battle.battlers[idxBattler])
    end
    first_any = (0...texts.length).find do |i|
      !texts[i].nil? && @battle.battlers[i].hp > 0
    end
    @targetWindow.index = first_opposing || first_any || 0

    if @targetWindow.index == -1
      $ebd_target_active = false
      raise RuntimeError.new(_INTL("No targets somehow..."))
    end

    ret = -1
    pbSelectBattler((mode==0) ? @targetWindow.index : texts, 2)
    @targetWindow.update 
    @targetWindow.showPlay

    # Track mouse location so hover doesn't interfere with keyboard
    @last_mouse_x = Input.mouse_x
    @last_mouse_y = Input.mouse_y

    loop do
      oldIndex = @targetWindow.index
      pbUpdate

      # --- MOUSE HOVER & CLICK LOGIC ---
      mouse_moved = (@last_mouse_x != Input.mouse_x || @last_mouse_y != Input.mouse_y)
      @last_mouse_x = Input.mouse_x
      @last_mouse_y = Input.mouse_y

      mouse_clicked = false

      # Check Back Button Click
      if @targetWindow.isMouseOverBack? && Input.trigger?(Input::MOUSELEFT)
        ret = -1
        pbPlayCancelSE
        mouse_clicked = true
      end
      break if mouse_clicked

      # Check Target Buttons
      for i in 0...texts.length
        next if texts[i].nil? || @battle.battlers[i].hp <= 0
        btn = @targetWindow.buttons["#{i}"]
        next if btn.nil?
        
        bx = btn.x
        by = btn.y
        bw = btn.bitmap.width
        bh = btn.bitmap.height
        
        if Input.mouse_x >= bx && Input.mouse_x <= bx + bw &&
           Input.mouse_y >= by && Input.mouse_y <= by + bh
          
          if mouse_moved && mode == 0 && @targetWindow.index != i
            @targetWindow.index = i
            pbSEPlay("EBDX/SE_Select1")
            pbSelectBattler(@targetWindow.index)
          end
          
          if Input.trigger?(Input::MOUSELEFT)
            ret = @targetWindow.index
            pbSEPlay("EBDX/SE_Select1")
            $ebd_target_clicked = true 
            mouse_clicked = true
            break
          end
        end
      end
      break if mouse_clicked

      # --- KEYBOARD LOGIC ---
      if mode == 0
        if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
          inc = ((@targetWindow.index % 2) == 0) ? -2 : 2
          inc *= -1 if Input.trigger?(Input::LEFT)
          indexLength = @battle.sideSizes[@targetWindow.index % 2] * 2
          newIndex = @targetWindow.index
          loop do
            newIndex += inc
            break if newIndex < 0 || newIndex >= indexLength
            next if texts[newIndex].nil? || @battle.battlers[newIndex].hp <= 0
            @targetWindow.index = newIndex
            break
          end
        elsif Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
          current_row = @targetWindow.index % 2
          target_row = current_row ^ 1
          col_index = @targetWindow.index / 2
          found = false
          for i in 0...texts.length
            next if texts[i].nil? || @battle.battlers[i].hp <= 0
            if i % 2 == target_row && i / 2 == col_index
              @targetWindow.index = i
              found = true
              break
            end
          end
          if !found
            for i in 0...texts.length
              next if texts[i].nil? || @battle.battlers[i].hp <= 0
              if i % 2 == target_row
                @targetWindow.index = i
                break
              end
            end
          end
        end
        if @targetWindow.index != oldIndex
          pbSEPlay("EBDX/SE_Select1")
          pbSelectBattler(@targetWindow.index)
        end
      end

      @targetWindow.update

      if Input.trigger?(Input::C)
        ret = @targetWindow.index
        pbSEPlay("EBDX/SE_Select1")
        break
      end

      if Input.trigger?(Input::B)
        ret = -1
        pbPlayCancelSE
        break
      end
    end

    self.pbDeselectAll(ret < 0 ? idxBattler : nil)
    @targetWindow.hidePlay
    @fightWindow.showPlay if ret < 0
    
    $ebd_target_active = false 
    
    return ret
  end
end