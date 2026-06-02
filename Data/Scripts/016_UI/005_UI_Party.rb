#===============================================================================
# JOIPLAY ANDROID COMPATIBILITY FIX
#===============================================================================
class Bitmap
  # JoiPlay doesn't support clear_rect, so we define it manually using fill_rect
  unless method_defined?(:clear_rect)
    def clear_rect(x, y, width, height)
      self.fill_rect(x, y, width, height, Color.new(0, 0, 0, 0))
    end
  end
end
#===============================================================================

#===============================================================================
# Pokémon party buttons and menu
#===============================================================================
class PokemonPartyConfirmCancelSprite < Sprite
  attr_reader :selected

  def initialize(text, x, y, narrowbox = false, viewport = nil)
    super(viewport)
    @refreshBitmap = true

    @bgsprite = ChangelingSprite.new(0, 0, viewport)
    if narrowbox
      @bgsprite.addBitmap("desel", "Graphics/UI/Party/icon_cancel_narrow")
      @bgsprite.addBitmap("sel", "Graphics/UI/Party/icon_cancel_narrow_sel")
    else
      @bgsprite.addBitmap("desel", "Graphics/UI/Party/icon_cancel")
      @bgsprite.addBitmap("sel", "Graphics/UI/Party/icon_cancel_sel")
    end
    @bgsprite.changeBitmap("desel")
    @overlaysprite = BitmapSprite.new(@bgsprite.bitmap.width, @bgsprite.bitmap.height, viewport)
    @overlaysprite.z = self.z + 1
    pbSetSystemFont(@overlaysprite.bitmap)
    textpos = [[text, 56 + 11, (narrowbox) ? 8 : 14, :center, Color.black, Color.new(40, 40, 40, 0)]]
    pbDrawTextPositions(@overlaysprite.bitmap, textpos)
    self.x = x
    self.y = y
  end

  def dispose
    @bgsprite.dispose
    @overlaysprite.bitmap.dispose
    @overlaysprite.dispose
    super
  end

  def viewport=(value)
    super
    refresh
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    refresh
  end

  def selected=(value)
    if @selected != value
      @selected = value
      refresh
    end
  end

  def refresh
    if @bgsprite && !@bgsprite.disposed?
      @bgsprite.changeBitmap((@selected) ? "sel" : "desel")
      @bgsprite.x     = self.x
      @bgsprite.y     = self.y
      @bgsprite.color = self.color
    end
    if @overlaysprite && !@overlaysprite.disposed?
      @overlaysprite.x     = self.x
      @overlaysprite.y     = self.y
      @overlaysprite.color = self.color
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPartyCancelSprite < PokemonPartyConfirmCancelSprite
  def initialize(viewport = nil)
    #super(_INTL("Cancel"), 726 - 11, 320, false, viewport)
	super(_INTL("Cancel"), 1350, 620, false, viewport)
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPartyConfirmSprite < PokemonPartyConfirmCancelSprite
  def initialize(viewport = nil)
    super(_INTL("CONFIRM"), 690, 305, true, viewport)
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPartyCancelSprite2 < PokemonPartyConfirmCancelSprite
  def initialize(viewport = nil)
    super(_INTL("CANCEL"), 690, 340, true, viewport)
  end
end

#===============================================================================
#
#===============================================================================
class Window_CommandPokemonColor < Window_CommandPokemon
  def item_height; return 44; end

  def initialize(commands, width = nil)
    @cursor_timer = 0
    @colorKey = []
    commands.length.times { |i| 
      if commands[i].is_a?(Array)
        @colorKey[i] = commands[i][1]
        commands[i] = commands[i][0]
      end
    }
    super(commands, width)
    
    self.height = (@commands.length * self.item_height) + 32
    if self.contents && !self.contents.disposed?
      self.contents.dispose
    end
    self.contents = Bitmap.new([1, self.width - 32].max, [1, self.height - 32].max)
    refresh
  end

  def drawCursor(index, rect); return rect; end

  # Helper: 9-Slice Drawing
  def draw_9_slice(bitmap, rect, alpha)
    m = 8 
    w = rect.width
    h = rect.height
    bw = bitmap.width
    bh = bitmap.height

    # Corners
    self.contents.stretch_blt(Rect.new(rect.x, rect.y, m, m), bitmap, Rect.new(0, 0, m, m), alpha)
    self.contents.stretch_blt(Rect.new(rect.x + w - m, rect.y, m, m), bitmap, Rect.new(bw - m, 0, m, m), alpha)
    self.contents.stretch_blt(Rect.new(rect.x, rect.y + h - m, m, m), bitmap, Rect.new(0, bh - m, m, m), alpha)
    self.contents.stretch_blt(Rect.new(rect.x + w - m, rect.y + h - m, m, m), bitmap, Rect.new(bw - m, bh - m, m, m), alpha)

    # Sides
    self.contents.stretch_blt(Rect.new(rect.x + m, rect.y, w - 2*m, m), bitmap, Rect.new(m, 0, bw - 2*m, m), alpha)
    self.contents.stretch_blt(Rect.new(rect.x + m, rect.y + h - m, w - 2*m, m), bitmap, Rect.new(m, bh - m, bw - 2*m, m), alpha)
    self.contents.stretch_blt(Rect.new(rect.x, rect.y + m, m, h - 2*m), bitmap, Rect.new(0, m, m, bh - 2*m), alpha)
    self.contents.stretch_blt(Rect.new(rect.x + w - m, rect.y + m, m, h - 2*m), bitmap, Rect.new(bw - m, m, m, bh - 2*m), alpha)

    # Center
    self.contents.stretch_blt(Rect.new(rect.x + m, rect.y + m, w - 2*m, h - 2*m), bitmap, Rect.new(m, m, bw - 2*m, bh - 2*m), alpha)
  end

  def drawItem(index, _count, rect)
    h = self.item_height
    real_y = (index * h)
    
    self.contents.clear_rect(rect.x, real_y, rect.width, h)
    
    # --- DRAW CONDITIONAL SELECTION GRAPHIC ---
    if index == self.index
      # Logic: Top, Bottom, or Middle
      sel_graphic = "Graphics/Windowskins/choice sel" 
      
      if index == 0
        sel_graphic = "Graphics/Windowskins/choice sel top"
      elsif index == @commands.length - 1
        sel_graphic = "Graphics/Windowskins/choice sel bottom"
      end

      if pbResolveBitmap(sel_graphic)
        bitmap_obj = AnimatedBitmap.new(sel_graphic)
        bitmap_bg = bitmap_obj.bitmap
        
        # New Pulse Speed: 0.12
        alpha = 150 + (105 * Math.sin((@cursor_timer || 0) * 0.12)).to_i
        
        draw_9_slice(bitmap_bg, Rect.new(rect.x, real_y, rect.width, h), alpha)
        
        bitmap_obj.dispose
      end
    end

    pbSetSystemFont(self.contents)
    self.contents.font.size = 32
    text_y = real_y + 6
    arrow_y = real_y + 11
    
    if index == self.index
      if pbResolveBitmap("Graphics/UI/arrow_choices")
        bob_x = (Math.sin((@cursor_timer || 0) * 0.2) * 6).to_i
        pbDrawImagePositions(self.contents, [
          ["Graphics/UI/arrow_choices", rect.x + bob_x, arrow_y]
        ])
      end
    end

    base   = Color.black
    shadow = Color.new(192, 32, 40, 0)
    pbDrawShadowText(self.contents, rect.x + 20, text_y,
                     rect.width - 20, 32, @commands[index], base, shadow)
  end
end

#===============================================================================
# Blank party panel
#===============================================================================
class PokemonPartyBlankPanel < Sprite
  attr_accessor :text

  def initialize(_pokemon, index, viewport = nil)
    super(viewport)
	if index < 3
      self.x = 378 + (index * (256 + 29))
      self.y = 158
    else
      self.x = 434 + ((index - 3) * (256 + 29))
      self.y = 382
    end
    @panelbgsprite = AnimatedBitmap.new("Graphics/UI/Party/panel_blank")
    self.bitmap = @panelbgsprite.bitmap
    
    # --- NEW: UNIQUE GRAPHIC FOR BLANK PANEL ---
    @custom_graphic = IconSprite.new(self.x + 20, self.y + 18, viewport)
    @custom_graphic.setBitmap("Graphics/UI/Party/pk#{index + 1}")
    @custom_graphic.z = self.z + 1
	@custom_graphic.visible = false 
    @text = nil
  end

  def dispose
    @panelbgsprite.dispose
	@custom_graphic.dispose if @custom_graphic
    super
  end

  def selected; return false; end
  def selected=(value); end
  def preselected; return false; end
  def preselected=(value); end
  def switching; return false; end
  def switching=(value); end
  def refresh; end
end

#===============================================================================
# Pokémon party panel
#===============================================================================
class PokemonPartyPanel < Sprite
  attr_reader :pokemon
  attr_reader :active
  attr_reader :selected
  attr_reader :preselected
  attr_reader :switching
  attr_reader :text

  TEXT_BASE_COLOR    = Color.black
  TEXT_SHADOW_COLOR  = Color.new(192, 32, 40, 0)
  HP_BAR_WIDTH       = 100
  NAME_FONT_SIZE    = 32
  STATUS_ICON_WIDTH  = 100
  STATUS_ICON_HEIGHT = 40

  def initialize(pokemon, index, viewport = nil)
    super(viewport)
    @pokemon = pokemon
    @active = (index == 0)   # true = rounded panel, false = rectangular panel
    @refreshing = true
    if index < 3
      self.x = 378 + (index * (256 + 29))
      self.y = 158
    else
      self.x = 434 + ((index - 3) * (256 + 29))
      self.y = 382
    end
    @panelbgsprite = ChangelingSprite.new(0, 0, viewport)
    @panelbgsprite.z = self.z
	# --- NEW: UNIQUE GRAPHIC INITIALIZATION ---
    @custom_graphic = IconSprite.new(self.x + 20, self.y + 18, viewport)
    @custom_graphic.setBitmap("Graphics/UI/Party/pk#{index + 1}")
    @custom_graphic.z = self.z + 1
    if @active   # Rounded panel
      @panelbgsprite.addBitmap("able", "Graphics/UI/Party/panel_round")
      @panelbgsprite.addBitmap("ablesel", "Graphics/UI/Party/panel_round_sel")
      @panelbgsprite.addBitmap("fainted", "Graphics/UI/Party/panel_round_faint")
      @panelbgsprite.addBitmap("faintedsel", "Graphics/UI/Party/panel_round_faint_sel")
      @panelbgsprite.addBitmap("swap", "Graphics/UI/Party/panel_round_swap")
      @panelbgsprite.addBitmap("swapsel", "Graphics/UI/Party/panel_round_swap_sel")
      @panelbgsprite.addBitmap("swapsel2", "Graphics/UI/Party/panel_round_swap_sel2")
    else   # Rectangular panel
      @panelbgsprite.addBitmap("able", "Graphics/UI/Party/panel_rect")
      @panelbgsprite.addBitmap("ablesel", "Graphics/UI/Party/panel_rect_sel")
      @panelbgsprite.addBitmap("fainted", "Graphics/UI/Party/panel_rect_faint")
      @panelbgsprite.addBitmap("faintedsel", "Graphics/UI/Party/panel_rect_faint_sel")
      @panelbgsprite.addBitmap("swap", "Graphics/UI/Party/panel_rect_swap")
      @panelbgsprite.addBitmap("swapsel", "Graphics/UI/Party/panel_rect_swap_sel")
      @panelbgsprite.addBitmap("swapsel2", "Graphics/UI/Party/panel_rect_swap_sel2")
    end
    @hpbgsprite = ChangelingSprite.new(0, 0, viewport)
    @hpbgsprite.z = self.z + 1
    @hpbgsprite.addBitmap("able", _INTL("Graphics/UI/Party/overlay_hp_back"))
    @hpbgsprite.addBitmap("fainted", _INTL("Graphics/UI/Party/overlay_hp_back_faint"))
    @hpbgsprite.addBitmap("swap", _INTL("Graphics/UI/Party/overlay_hp_back_swap"))
    #@ballsprite = ChangelingSprite.new(0, 0, viewport)
    #@ballsprite.z = self.z + 1
    #@ballsprite.addBitmap("desel", "Graphics/UI/Party/icon_ball")
    #@ballsprite.addBitmap("sel", "Graphics/UI/Party/icon_ball_sel")
    @pkmnsprite = PokemonIconSprite.new(pokemon, viewport)
    @pkmnsprite.setOffset(PictureOrigin::CENTER)
    @pkmnsprite.active = @active
    @pkmnsprite.z      = self.z + 2
    @helditemsprite = HeldItemIconSprite.new(0, 0, @pokemon, viewport)
    @helditemsprite.z = self.z + 3
    @overlaysprite = BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    @overlaysprite.z = self.z + 4
    pbSetSystemFont(@overlaysprite.bitmap)
    @hpbar    = AnimatedBitmap.new("Graphics/UI/Party/overlay_hp")
    @statuses = AnimatedBitmap.new(_INTL("Graphics/UI/statuses"))
    @selected      = false
    @preselected   = false
    @switching     = false
    @text          = nil
    @refreshBitmap = true
    @refreshing    = false
    refresh
  end

  def dispose
    @panelbgsprite.dispose
    @hpbgsprite.dispose
    #@ballsprite.dispose
    @pkmnsprite.dispose
    @helditemsprite.dispose
    @custom_graphic.dispose if @custom_graphic # Add this line
    @overlaysprite.bitmap.dispose
    @overlaysprite.dispose
    @hpbar.dispose
    @statuses.dispose
    super
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    refresh
  end

  def text=(value)
    return if @text == value
    @text = value
    @refreshBitmap = true
    refresh
  end

  def pokemon=(value)
    @pokemon = value
    @pkmnsprite.pokemon = value if @pkmnsprite && !@pkmnsprite.disposed?
    @helditemsprite.pokemon = value if @helditemsprite && !@helditemsprite.disposed?
    @refreshBitmap = true
    refresh
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    refresh
  end

  def preselected=(value)
    return if @preselected == value
    @preselected = value
    refresh
  end

  def switching=(value)
    return if @switching == value
    @switching = value
    refresh
  end

  def hp; return @pokemon.hp; end

  def refresh_panel_graphic
    return if !@panelbgsprite || @panelbgsprite.disposed?
    if self.selected
      if self.preselected
        @panelbgsprite.changeBitmap("swapsel2")
      elsif @switching
        @panelbgsprite.changeBitmap("swapsel")
      elsif @pokemon.fainted?
        @panelbgsprite.changeBitmap("faintedsel")
      else
        @panelbgsprite.changeBitmap("ablesel")
      end
    else
      if self.preselected
        @panelbgsprite.changeBitmap("swap")
      elsif @pokemon.fainted?
        @panelbgsprite.changeBitmap("fainted")
      else
        @panelbgsprite.changeBitmap("able")
      end
    end
    @panelbgsprite.x     = self.x
    @panelbgsprite.y     = self.y
    @panelbgsprite.color = self.color
  end

  def refresh_hp_bar_graphic
    return if !@hpbgsprite || @hpbgsprite.disposed?
    @hpbgsprite.visible = (!@pokemon.egg? && !(@text && @text.length > 0))
    return if !@hpbgsprite.visible
    if self.preselected || (self.selected && @switching)
      @hpbgsprite.changeBitmap("swap")
    elsif @pokemon.fainted?
      @hpbgsprite.changeBitmap("fainted")
    else
      @hpbgsprite.changeBitmap("able")
    end
    @hpbgsprite.x     = self.x + 128
	@hpbgsprite.y     = self.y + 122
    @hpbgsprite.color = self.color
  end

  #def refresh_ball_graphic
  #  return if !@ballsprite || @ballsprite.disposed?
  #  @ballsprite.changeBitmap((self.selected) ? "sel" : "desel")
  #  @ballsprite.x     = self.x + 10 + 11
  #  @ballsprite.y     = self.y
  #  @ballsprite.color = self.color
  #end

  def refresh_pokemon_icon
    return if !@pkmnsprite || @pkmnsprite.disposed?
    @pkmnsprite.x        = self.x + 128
	@pkmnsprite.y        = self.y + 50
    @pkmnsprite.color    = self.color
    @pkmnsprite.selected = self.selected
  end

  def refresh_held_item_icon
    return if !@helditemsprite || @helditemsprite.disposed? || !@helditemsprite.visible
    @helditemsprite.x     = self.x + 220
    @helditemsprite.y     = self.y + 18
    @helditemsprite.color = self.color
  end

  def refresh_overlay_information
    return if !@refreshBitmap
    @overlaysprite.bitmap&.clear
    draw_name
    draw_level
    draw_gender
    draw_hp
    draw_status
    draw_shiny_icon
    draw_annotation
  end

  def draw_name
    @overlaysprite.bitmap.font.size = NAME_FONT_SIZE # Set to 32
    namepos = [[@pokemon.name, 128, 82, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]]
    pbDrawTextPositions(@overlaysprite.bitmap, namepos)
  end

  def draw_level
    return if @pokemon.egg?
    @overlaysprite.bitmap.font.size = 28 # Keep level slightly smaller
    levpos = [[_INTL("Lv. {1}", @pokemon.level), 28, 126, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]]
    pbDrawTextPositions(@overlaysprite.bitmap, levpos)
  end

  def draw_gender
    return if @pokemon.egg? || @pokemon.genderless?
    gender_text  = (@pokemon.male?) ? _INTL("♂") : _INTL("♀")
    base_color   = (@pokemon.male?) ? Color.new(0, 112, 248) : Color.new(232, 32, 16)
    shadow_color = (@pokemon.male?) ? Color.new(120, 184, 232, 0) : Color.new(248, 168, 184, 0)
    pbDrawTextPositions(@overlaysprite.bitmap,
                        [[gender_text, 108, 126, :left, base_color, shadow_color]])
  end

  def draw_hp
    return if @pokemon.egg? || (@text && @text.length > 0)
    @overlaysprite.bitmap.font.size = 24
    hp_text = sprintf("%d/%d", @pokemon.hp, @pokemon.totalhp)
    hppos = [[hp_text, 228, 142, :right, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]]
    pbDrawTextPositions(@overlaysprite.bitmap, hppos)
	if @pokemon.able?
      # Calculate width based on your new HP_BAR_WIDTH (240)
      w = @pokemon.hp * HP_BAR_WIDTH / @pokemon.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      
      # Determine color zone (Green, Yellow, Red)
      hpzone = 0
      hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
      
      # Define the source rectangle from overlay_hp.png
      hprect = Rect.new(0, hpzone * 16, w, 16)
      
      # Draw it onto the overlay at the NEW relative coordinates
      # Matches the @hpbgsprite position: x + 40, y + 110
      @overlaysprite.bitmap.blt(128, 122, @hpbar.bitmap, hprect)
    end
  end

  def draw_status
    return if @pokemon.egg? || (@text && @text.length > 0)
    status = -1
    if @pokemon.fainted?
      status = GameData::Status.count - 1
    elsif @pokemon.status != :NONE
      status = GameData::Status.get(@pokemon.status).icon_position
    elsif @pokemon.pokerusStage == 1
      status = GameData::Status.count
    end
    return if status < 0
    statusrect = Rect.new(0, STATUS_ICON_HEIGHT * status, STATUS_ICON_WIDTH, STATUS_ICON_HEIGHT)
    @overlaysprite.bitmap.blt(28, 122, @statuses.bitmap, statusrect)
  end

  def draw_shiny_icon
    return if @pokemon.egg? || !@pokemon.shiny?
    pbDrawImagePositions(@overlaysprite.bitmap,
                         [["Graphics/UI/shiny", 80, 50, 0, 0, 16, 16]])
  end

  def draw_annotation
    return if !@text || @text.length == 0
    pbDrawTextPositions(@overlaysprite.bitmap,
                        [[@text, 96 + 11, 62, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]])
  end

def refresh_custom_graphic
    return if !@custom_graphic || @custom_graphic.disposed?
    @custom_graphic.x       = self.x + 20
    @custom_graphic.y       = self.y + 18
    @custom_graphic.color   = self.color
    # This ensures it is only visible if the panel sprite itself is visible
    @custom_graphic.visible = self.visible 
  end
  
  def refresh
    return if disposed?
    return if @refreshing
    @refreshing = true
    refresh_panel_graphic
    refresh_hp_bar_graphic
    #refresh_ball_graphic
    refresh_pokemon_icon
    refresh_held_item_icon
	refresh_custom_graphic
    if @overlaysprite && !@overlaysprite.disposed?
      @overlaysprite.x     = self.x
      @overlaysprite.y     = self.y
      @overlaysprite.color = self.color
    end
    refresh_overlay_information
    @refreshBitmap = false
    @refreshing = false
  end

  def update
    super
    @panelbgsprite.update if @panelbgsprite && !@panelbgsprite.disposed?
    @hpbgsprite.update if @hpbgsprite && !@hpbgsprite.disposed?
    #@ballsprite.update if @ballsprite && !@ballsprite.disposed?
    @pkmnsprite.update if @pkmnsprite && !@pkmnsprite.disposed?
    @helditemsprite.update if @helditemsprite && !@helditemsprite.disposed?
  end
end

#===============================================================================
# Pokémon party visuals
#===============================================================================
class PokemonParty_Scene
  def pbStartScene(party, starthelptext, annotations = nil, multiselect = false, can_access_storage = false)
    @sprites = {}
    @party = party
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @multiselect = multiselect
    @can_access_storage = can_access_storage
    addBackgroundPlane(@sprites, "partybg", "Party/bg", @viewport)
		
	@sprites["btn_back"] = IconSprite.new(16, 16, @viewport)
    @sprites["btn_back"].setBitmap("Graphics/UI/back")
    @sprites["btn_back"].z = 250
	
	@sprites["btn_boxes"] = IconSprite.new(16, 608, @viewport)
    @sprites["btn_boxes"].setBitmap("Graphics/UI/button")
    @sprites["btn_boxes"].z = 250
	
	@sprites["btn_switch"] = IconSprite.new(432, 608, @viewport)
    @sprites["btn_switch"].setBitmap("Graphics/UI/button")
    @sprites["btn_switch"].z = 250
	
	@sprites["cursor"] = Sprite.new(@viewport)
    @sprites["cursor"].bitmap = Bitmap.new("Graphics/UI/sel_arrow")
    @sprites["cursor"].src_rect.set(0, 0, 64, 64) # Adjust if your arrow is a different size
    @sprites["cursor"].z = 200 # Ensure it is above the panels
    @cursor_offset = 0
    @cursor_timer = 0
	
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].z              = 50
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
	@sprites["messagebox"].windowskin = Bitmap.new("Graphics/Windowskins/choice 4")
    pbBottomLeftLines(@sprites["messagebox"], 2)
    @sprites["storagetext"] = Window_UnformattedTextPokemon.new(
      @can_access_storage ? _INTL("[D]: To Boxes") : ""
    )
    @sprites["storagetext"].x           = 16
    @sprites["storagetext"].y           = 330
    @sprites["storagetext"].z           = 10
    #@sprites["storagetext"].viewport    = @viewport
    @sprites["storagetext"].baseColor   = Color.new(248, 248, 248)
    @sprites["storagetext"].shadowColor = Color.new(192, 32, 40, 0)
    @sprites["storagetext"].windowskin  = nil
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new(starthelptext)
    #@sprites["helpwindow"].viewport = @viewport
    @sprites["helpwindow"].visible  = true
	@sprites["helpwindow"].windowskin = Bitmap.new("Graphics/Windowskins/choice 5")
    pbBottomLeftLines(@sprites["helpwindow"], 1)
    pbSetHelpText(starthelptext)
    # Add party Pokémon sprites
    Settings::MAX_PARTY_SIZE.times do |i|
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonPartyPanel.new(@party[i], i, @viewport)
        # Ensure graphic is visible for active members
        @sprites["pokemon#{i}"].instance_eval { @custom_graphic.visible = true }
      else
        @sprites["pokemon#{i}"] = PokemonPartyBlankPanel.new(@party[i], i, @viewport)
        # HIDE the pk#.png graphic because the slot is empty
        @sprites["pokemon#{i}"].instance_eval { @custom_graphic.visible = false }
      end
      @sprites["pokemon#{i}"].text = annotations[i] if annotations
    end
    #if @multiselect
    #  @sprites["pokemon#{Settings::MAX_PARTY_SIZE}"] = PokemonPartyConfirmSprite.new(@viewport)
    #  @sprites["pokemon#{Settings::MAX_PARTY_SIZE + 1}"] = PokemonPartyCancelSprite2.new(@viewport)
    #else
    #  @sprites["pokemon#{Settings::MAX_PARTY_SIZE}"] = PokemonPartyCancelSprite.new(@viewport)
    #end
    # Select first Pokémon
    @activecmd = 0
    @sprites["pokemon0"].selected = true
    pbFadeInAndShow(@sprites) { update }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbDisplay(message)
    $msg_style = :system
    pbMessage(message)
    $msg_style = nil
  end

  def pbConfirm(message)
    $msg_style = :system
    ret = pbConfirmMessage(message)
    $msg_style = nil
    return ret
  end

  def pbShowCommands(helptext, commands, index = 0)
    ret = -1
    helpwindow = @sprites["helpwindow"]
    helpwindow.visible = true
    using(cmdwindow = Window_CommandPokemonColor.new(commands)) do
      cmdwindow.z     = @viewport.z + 1
      cmdwindow.index = index
      pbBottomRight(cmdwindow)
      helpwindow.resizeHeightToFit(helptext, Graphics.width - cmdwindow.width)
      helpwindow.text = helptext
      pbBottomLeft(helpwindow)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        self.update
        if Input.trigger?(Input::BACK)
          pbPlayCancelSE
          ret = -1
          break
        elsif Input.trigger?(Input::USE)
          pbPlayDecisionSE
          ret = cmdwindow.index
          break
        end
      end
    end
    return ret
  end

  def pbChooseNumber(helptext, maximum, initnum = 1)
    return UIHelper.pbChooseNumber(@sprites["helpwindow"], helptext, maximum, initnum) { update }
  end

  def pbSetHelpText(helptext)
    helpwindow = @sprites["helpwindow"]
    pbBottomLeftLines(helpwindow, 1)
    helpwindow.text = helptext
    helpwindow.width = 398
    helpwindow.visible = true
  end

  def pbHasAnnotations?
    return !@sprites["pokemon0"].text.nil?
  end

  def pbAnnotate(annot)
    Settings::MAX_PARTY_SIZE.times do |i|
      @sprites["pokemon#{i}"].text = (annot) ? annot[i] : nil
    end
  end

  def pbSelect(item)
    @activecmd = item
    numsprites = Settings::MAX_PARTY_SIZE
    numsprites.times do |i|
      @sprites["pokemon#{i}"].selected = (i == @activecmd)
    end
  end

  def pbPreSelect(item)
    @activecmd = item
  end

  def pbSwitchBegin(oldid, newid)
    pbSEPlay("GUI party switch")
    oldsprite = @sprites["pokemon#{oldid}"]
    newsprite = @sprites["pokemon#{newid}"]
    old_start_x = oldsprite.x
    new_start_x = newsprite.x
    old_mult = oldid.even? ? -1 : 1
    new_mult = newid.even? ? -1 : 1
    timer_start = System.uptime
    loop do
      oldsprite.x = lerp(old_start_x, old_start_x + (old_mult * Graphics.width / 2), 0.4, timer_start, System.uptime)
      newsprite.x = lerp(new_start_x, new_start_x + (new_mult * Graphics.width / 2), 0.4, timer_start, System.uptime)
      Graphics.update
      Input.update
      self.update
      break if oldsprite.x == old_start_x + (old_mult * Graphics.width / 2)
    end
  end

  def pbSwitchEnd(oldid, newid)
    pbSEPlay("GUI party switch")
    oldsprite = @sprites["pokemon#{oldid}"]
    newsprite = @sprites["pokemon#{newid}"]
    oldsprite.pokemon = @party[oldid]
    newsprite.pokemon = @party[newid]
    old_start_x = oldsprite.x
    new_start_x = newsprite.x
    old_mult = oldid.even? ? -1 : 1
    new_mult = newid.even? ? -1 : 1
    timer_start = System.uptime
    loop do
      oldsprite.x = lerp(old_start_x, old_start_x - (old_mult * Graphics.width / 2), 0.4, timer_start, System.uptime)
      newsprite.x = lerp(new_start_x, new_start_x - (new_mult * Graphics.width / 2), 0.4, timer_start, System.uptime)
      Graphics.update
      Input.update
      self.update
      break if oldsprite.x == old_start_x - (old_mult * Graphics.width / 2)
    end
    Settings::MAX_PARTY_SIZE.times do |i|
      @sprites["pokemon#{i}"].preselected = false
      @sprites["pokemon#{i}"].switching   = false
    end
    pbRefresh
  end

  def pbClearSwitching
    Settings::MAX_PARTY_SIZE.times do |i|
      @sprites["pokemon#{i}"].preselected = false
      @sprites["pokemon#{i}"].switching   = false
    end
  end

  def pbSummary(pkmnid, inbattle = false)
    oldsprites = pbFadeOutAndHide(@sprites)
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene, inbattle)
    screen.pbStartScreen(@party, pkmnid)
    yield if block_given?
    pbRefresh
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbChooseItem(bag)
    ret = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, bag)
      ret = screen.pbChooseItemScreen(proc { |item| GameData::Item.get(item).can_hold? })
      yield if block_given?
    end
    return ret
  end

  def pbUseItem(bag, pokemon)
    ret = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, bag)
      ret = screen.pbChooseItemScreen(proc { |item|
        itm = GameData::Item.get(item)
        next false if !pbCanUseOnPokemon?(itm)
        next false if pokemon.hyper_mode && !GameData::Item.get(item)&.is_scent?
        if itm.is_machine?
          move = itm.move
          next false if pokemon.hasMove?(move) || !pokemon.compatible_with_move?(move)
        end
        next true
      })
      yield if block_given?
    end
    return ret
  end

  def pbChoosePokemon(switching = false, initialsel = -1, canswitch = 0)
    Settings::MAX_PARTY_SIZE.times do |i|
      @sprites["pokemon#{i}"].preselected = (switching && i == @activecmd)
      @sprites["pokemon#{i}"].switching   = switching
    end
    @activecmd = initialsel if initialsel >= 0
    pbRefresh
    
    # Init mouse tracking
    last_mx, last_my = Input.mouse_x, Input.mouse_y
    
    loop do
      Graphics.update
      Input.update
      self.update
      oldsel = @activecmd
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        @activecmd = pbChangeSelection(key, @activecmd)
      end

      # --- MOUSE SUPPORT: HOVER TO SELECT ---
      mx, my = Input.mouse_x, Input.mouse_y
      
      if mx != last_mx || my != last_my
        @party.length.times do |i|
          sprite = @sprites["pokemon#{i}"]
          next if !sprite || !sprite.visible
          
          # Hitbox Check: Panel Width approx 260px, Height approx 120px
          if mx >= sprite.x && mx <= sprite.x + 260 &&
             my >= sprite.y && my <= sprite.y + 120
            
            if @activecmd != i
              @activecmd = i
            end
          end
        end
        last_mx, last_my = mx, my
      end

      # --- CLICK LOGIC (PANELS & BUTTONS) ---
      if Input.trigger?(Input::MOUSELEFT)
        # 1. BUTTON: Back (Bottom Right, 122x46)
        # Position: Aligned to bottom-right corner
        b1_w, b1_h = 122, 46
        b1_x = Graphics.width - b1_w
        b1_y = Graphics.height - b1_h
        
        if mx >= b1_x && mx <= Graphics.width && my >= b1_y && my <= Graphics.height
          pbPlayCloseMenuSE if !switching
          return -1
        end

        # 2. BUTTON: Switch/Move (Left of Back Button, 238x46)
        # Position: 12px gap from Back Button
        b2_w, b2_h = 238, 46
        b2_x = b1_x - 12 - b2_w
        b2_y = Graphics.height - b2_h
        
        if mx >= b2_x && mx <= b2_x + b2_w && my >= b2_y && my <= Graphics.height
          if canswitch == 1 && @activecmd != (Settings::MAX_PARTY_SIZE + ((@multiselect) ? 1 : 0))
            pbPlayDecisionSE
            return [1, @activecmd]
          end
        end

        # 3. BUTTON: PC Storage (Left of Switch Button, 284x46)
        # Position: 12px gap from Switch Button
        b3_w, b3_h = 284, 46
        b3_x = b2_x - 12 - b3_w
        b3_y = Graphics.height - b3_h
        
        if mx >= b3_x && mx <= b3_x + b3_w && my >= b3_y && my <= Graphics.height
          if @can_access_storage && canswitch != 2
            pbPlayDecisionSE
            pbFadeOutIn do
              scene = PokemonStorageScene.new
              screen = PokemonStorageScreen.new(scene, $PokemonStorage)
              screen.pbStartScreen(0)
              pbHardRefresh
            end
          end
        end

        # 4. PANEL SELECTION (Only if hovering active panel)
        mouse_is_over_panel = false
        cur_sprite = @sprites["pokemon#{@activecmd}"]
        if cur_sprite && cur_sprite.visible
          if mx >= cur_sprite.x && mx <= cur_sprite.x + 260 &&
             my >= cur_sprite.y && my <= cur_sprite.y + 120
            mouse_is_over_panel = true
          end
        end
        
        if mouse_is_over_panel
          pbPlayDecisionSE
          return @activecmd
        end
      end
      # --------------------------------------

      if @activecmd != oldsel   # Changing selection
        pbPlayCursorSE
        @party.length.times do |i|
          @sprites["pokemon#{i}"].selected = (i == @activecmd)
        end
      end
      
      cancelsprite = Settings::MAX_PARTY_SIZE + ((@multiselect) ? 1 : 0)
      
      if Input.trigger?(Input::SPECIAL) && @can_access_storage && canswitch != 2
        pbPlayDecisionSE
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(0)
          pbHardRefresh
        end
      elsif Input.trigger?(Input::ACTION) && canswitch == 1 && @activecmd != cancelsprite
        pbPlayDecisionSE
        return [1, @activecmd]
      elsif Input.trigger?(Input::ACTION) && canswitch == 2
        return -1
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE if !switching
        return -1
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        return @activecmd
      end
    end
  end

  def pbChangeSelection(key, currentsel)
    numsprites = Settings::MAX_PARTY_SIZE
    # Calculate the actual number of Pokémon in the party
    party_count = @party.length 
    
    new_sel = currentsel
    case key
    when Input::LEFT
      new_sel -= 1
    when Input::RIGHT
      new_sel += 1
    when Input::UP
      new_sel -= 3
    when Input::DOWN
      new_sel += 3
    end
    
    # Loop to ensure we don't land on an empty slot
    new_sel %= numsprites
    
    # If the new selection is higher than the number of Pokémon we have,
    # find the nearest valid Pokémon slot.
    if new_sel >= party_count
      # If moving right/down, wrap back to the first Pokémon
      if key == Input::RIGHT || key == Input::DOWN
        new_sel = 0
      # If moving left/up, go to the last valid Pokémon
      else
        new_sel = party_count - 1
      end
    end
    
    return new_sel
  end

  def pbHardRefresh
    oldtext = []
    lastselected = -1
    Settings::MAX_PARTY_SIZE.times do |i|
      oldtext.push(@sprites["pokemon#{i}"].text)
      lastselected = i if @sprites["pokemon#{i}"].selected
      @sprites["pokemon#{i}"].dispose
    end
    lastselected = @party.length - 1 if lastselected >= @party.length
    lastselected = Settings::MAX_PARTY_SIZE if lastselected < 0
    Settings::MAX_PARTY_SIZE.times do |i|
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonPartyPanel.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PokemonPartyBlankPanel.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = oldtext[i]
    end
    pbSelect(lastselected)
  end

  def pbRefresh
    Settings::MAX_PARTY_SIZE.times do |i|
      sprite = @sprites["pokemon#{i}"]
      if sprite
        if sprite.is_a?(PokemonPartyPanel)
          sprite.pokemon = sprite.pokemon
        else
          sprite.refresh
        end
      end
    end
  end

  def pbRefreshSingle(i)
    sprite = @sprites["pokemon#{i}"]
    if sprite
      if sprite.is_a?(PokemonPartyPanel)
        sprite.pokemon = sprite.pokemon
      else
        sprite.refresh
      end
    end
  end

  def update
    pbUpdateSpriteHash(@sprites)
    
    # --- NEW: CURSOR ANIMATION & POSITIONING ---
    if @sprites["cursor"]
      # Bobbing logic (moves left and right)
      @cursor_timer += 1
      @cursor_offset = Math.sin(@cursor_timer * 0.25) * 8 # 8 is the distance of the bob
      
      # Get current selected panel
      current_panel = @sprites["pokemon#{@activecmd}"]
      if current_panel
        # Position the cursor to the left of the panel
        # Adjust '32' and '88' to align specifically with your graphic's height
        @sprites["cursor"].x = current_panel.x - 40 + @cursor_offset
        @sprites["cursor"].y = current_panel.y + (176 / 2) - (@sprites["cursor"].bitmap.height / 2)
        @sprites["cursor"].visible = !@sprites["pokemon#{@activecmd}"].disposed?
      end
    end
	end
  end

#===============================================================================
# Pokémon party mechanics
#===============================================================================
class PokemonPartyScreen
  attr_reader :scene
  attr_reader :party

  def initialize(scene, party)
    @scene = scene
    @party = party
  end

  def pbStartScene(helptext, _numBattlersOut, annotations = nil)
    @scene.pbStartScene(@party, helptext, annotations)
  end

  def pbChoosePokemon(helptext = nil)
    @scene.pbSetHelpText(helptext) if helptext
    return @scene.pbChoosePokemon
  end

  def pbPokemonGiveScreen(item)
    @scene.pbStartScene(@party, _INTL("Give to which Pokémon?"))
    pkmnid = @scene.pbChoosePokemon
    ret = false
    if pkmnid >= 0
      ret = pbGiveItemToPokemon(item, @party[pkmnid], self, pkmnid)
    end
    pbRefreshSingle(pkmnid)
    @scene.pbEndScene
    return ret
  end

  def pbPokemonGiveMailScreen(mailIndex)
    @scene.pbStartScene(@party, _INTL("Give to which Pokémon?"))
    pkmnid = @scene.pbChoosePokemon
    if pkmnid >= 0
      pkmn = @party[pkmnid]
      if pkmn.hasItem? || pkmn.mail
        pbDisplay(_INTL("This Pokémon is holding an item. It can't hold mail."))
      elsif pkmn.egg?
        pbDisplay(_INTL("Eggs can't hold mail."))
      else
        pbDisplay(_INTL("Mail was transferred from the Mailbox."))
        pkmn.mail = $PokemonGlobal.mailbox[mailIndex]
        pkmn.item = pkmn.mail.item
        $PokemonGlobal.mailbox.delete_at(mailIndex)
        pbRefreshSingle(pkmnid)
      end
    end
    @scene.pbEndScene
  end

  def pbEndScene
    @scene.pbEndScene
  end

  def pbUpdate
    @scene.update
  end

  def pbHardRefresh
    @scene.pbHardRefresh
  end

  def pbRefresh
    @scene.pbRefresh
  end

  def pbRefreshSingle(i)
    @scene.pbRefreshSingle(i)
  end

  def pbDisplay(text)
    @scene.pbDisplay(text)
  end

  def pbConfirm(text)
    return @scene.pbConfirm(text)
  end

  def pbShowCommands(helptext, commands, index = 0)
    return @scene.pbShowCommands(helptext, commands, index)
  end

  # Checks for identical species.
  # Unused.
  def pbCheckSpecies(array)
    array.length.times do |i|
      (i + 1...array.length).each do |j|
        return false if array[i].species == array[j].species
      end
    end
    return true
  end

  # Checks for identical held items.
  # Unused.
  def pbCheckItems(array)
    array.length.times do |i|
      next if !array[i].hasItem?
      (i + 1...array.length).each do |j|
        return false if array[i].item == array[j].item
      end
    end
    return true
  end

  def pbSwitch(oldid, newid)
    if oldid != newid
      @scene.pbSwitchBegin(oldid, newid)
      tmp = @party[oldid]
      @party[oldid] = @party[newid]
      @party[newid] = tmp
      @scene.pbSwitchEnd(oldid, newid)
    end
  end

  def pbChooseMove(pokemon, helptext, index = 0)
    movenames = []
    pokemon.moves.each do |i|
      next if !i || !i.id
      if i.total_pp <= 0
        movenames.push(_INTL("{1} (PP: ---)", i.name))
      else
        movenames.push(_INTL("{1} (PP: {2}/{3})", i.name, i.pp, i.total_pp))
      end
    end
    return @scene.pbShowCommands(helptext, movenames, index)
  end

  # For after using an evolution stone.
  def pbRefreshAnnotations(ableProc)
    return if !@scene.pbHasAnnotations?
    annot = []
    @party.each do |pkmn|
      elig = ableProc.call(pkmn)
      annot.push((elig) ? _INTL("ABLE") : _INTL("NOT ABLE"))
    end
    @scene.pbAnnotate(annot)
  end

  def pbClearAnnotations
    @scene.pbAnnotate(nil)
  end

  def pbPokemonMultipleEntryScreenEx(ruleset)
    annot = []
    statuses = []
    ordinals = [_INTL("INELIGIBLE"), _INTL("NOT ENTERED"), _INTL("BANNED")]
    positions = [_INTL("FIRST"), _INTL("SECOND"), _INTL("THIRD"), _INTL("FOURTH"),
                 _INTL("FIFTH"), _INTL("SIXTH"), _INTL("SEVENTH"), _INTL("EIGHTH"),
                 _INTL("NINTH"), _INTL("TENTH"), _INTL("ELEVENTH"), _INTL("TWELFTH")]
    Settings::MAX_PARTY_SIZE.times do |i|
      if i < positions.length
        ordinals.push(positions[i])
      else
        ordinals.push("#{i + 1}th")
      end
    end
    return nil if !ruleset.hasValidTeam?(@party)
    ret = nil
    addedEntry = false
    @party.length.times do |i|
      statuses[i] = (ruleset.isPokemonValid?(@party[i])) ? 1 : 2
      annot[i] = ordinals[statuses[i]]
    end
    @scene.pbStartScene(@party, _INTL("Choose Pokémon and confirm."), annot, true)
    loop do
      realorder = []
      @party.length.times do |i|
        @party.length.times do |j|
          if statuses[j] == i + 3
            realorder.push(j)
            break
          end
        end
      end
      realorder.length.times do |i|
        statuses[realorder[i]] = i + 3
      end
      @party.length.times do |i|
        annot[i] = ordinals[statuses[i]]
      end
      @scene.pbAnnotate(annot)
      if realorder.length == ruleset.number && addedEntry
        @scene.pbSelect(Settings::MAX_PARTY_SIZE)
      end
      @scene.pbSetHelpText(_INTL("Choose Pokémon and confirm."))
      pkmnid = @scene.pbChoosePokemon
      addedEntry = false
      if pkmnid == Settings::MAX_PARTY_SIZE   # Confirm was chosen
        ret = []
        realorder.each do |i|
          ret.push(@party[i])
        end
        error = []
        break if ruleset.isValid?(ret, error)
        pbDisplay(error[0])
        ret = nil
      end
      break if pkmnid < 0   # Cancelled
      cmdEntry   = -1
      cmdNoEntry = -1
      cmdSummary = -1
      commands = []
      if (statuses[pkmnid] || 0) == 1
        commands[cmdEntry = commands.length]   = _INTL("Entry")
      elsif (statuses[pkmnid] || 0) > 2
        commands[cmdNoEntry = commands.length] = _INTL("No Entry")
      end
      pkmn = @party[pkmnid]
      commands[cmdSummary = commands.length]   = _INTL("Summary")
      commands[commands.length]                = _INTL("Cancel")
      command = @scene.pbShowCommands(_INTL("Do what with {1}?", pkmn.name), commands) if pkmn
      if cmdEntry >= 0 && command == cmdEntry
        if realorder.length >= ruleset.number && ruleset.number > 0
          pbDisplay(_INTL("No more than {1} Pokémon may enter.", ruleset.number))
        else
          statuses[pkmnid] = realorder.length + 3
          addedEntry = true
          pbRefreshSingle(pkmnid)
        end
      elsif cmdNoEntry >= 0 && command == cmdNoEntry
        statuses[pkmnid] = 1
        pbRefreshSingle(pkmnid)
      elsif cmdSummary >= 0 && command == cmdSummary
        @scene.pbSummary(pkmnid) do
          @scene.pbSetHelpText((@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
        end
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbChooseAblePokemon(ableProc, allowIneligible = false)
    annot = []
    eligibility = []
    @party.each do |pkmn|
      elig = ableProc.call(pkmn)
      eligibility.push(elig)
      annot.push((elig) ? _INTL("ABLE") : _INTL("NOT ABLE"))
    end
    ret = -1
    @scene.pbStartScene(
      @party,
      (@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."),
      annot
    )
    loop do
      @scene.pbSetHelpText(
        (@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel.")
      )
      pkmnid = @scene.pbChoosePokemon
      break if pkmnid < 0
      if !eligibility[pkmnid] && !allowIneligible
        pbDisplay(_INTL("This Pokémon can't be chosen."))
      else
        ret = pkmnid
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbChooseTradablePokemon(ableProc, allowIneligible = false)
    annot = []
    eligibility = []
    @party.each do |pkmn|
      elig = ableProc.call(pkmn)
      elig = false if pkmn.egg? || pkmn.shadowPokemon? || pkmn.cannot_trade
      eligibility.push(elig)
      annot.push((elig) ? _INTL("ABLE") : _INTL("NOT ABLE"))
    end
    ret = -1
    @scene.pbStartScene(
      @party,
      (@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."),
      annot
    )
    loop do
      @scene.pbSetHelpText(
        (@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel.")
      )
      pkmnid = @scene.pbChoosePokemon
      break if pkmnid < 0
      if !eligibility[pkmnid] && !allowIneligible
        pbDisplay(_INTL("This Pokémon can't be chosen."))
      else
        ret = pkmnid
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbPokemonScreen
    can_access_storage = false
    if ($player.has_box_link || $bag.has?(:POKEMONBOXLINK)) &&
       !$game_switches[Settings::DISABLE_BOX_LINK_SWITCH] &&
       !$game_map.metadata&.has_flag?("DisableBoxLink")
      can_access_storage = true
    end
    @scene.pbStartScene(@party,
                        (@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."),
                        nil, false, can_access_storage)
    # Main loop
    loop do
      # Choose a Pokémon or cancel or press Action to quick switch
      @scene.pbSetHelpText((@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
      party_idx = @scene.pbChoosePokemon(false, -1, 1)
      break if (party_idx.is_a?(Numeric) && party_idx < 0) || (party_idx.is_a?(Array) && party_idx[1] < 0)
      # Quick switch
      if party_idx.is_a?(Array) && party_idx[0] == 1   # Switch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        old_party_idx = party_idx[1]
        party_idx = @scene.pbChoosePokemon(true, -1, 2)
        pbSwitch(old_party_idx, party_idx) if party_idx >= 0 && party_idx != old_party_idx
        next
      end
      # Chose a Pokémon
      pkmn = @party[party_idx]
      # Get all commands
      command_list = []
      commands = []
      MenuHandlers.each_available(:party_menu, self, @party, party_idx) do |option, hash, name|
        command_list.push(name)
        commands.push(hash)
      end
      command_list.push(_INTL("Cancel"))
      # Add field move commands
      if !pkmn.egg?
        insert_index = ($DEBUG) ? 2 : 1
        pkmn.moves.each_with_index do |move, i|
          next if !HiddenMoveHandlers.hasHandler(move.id) &&
                  ![:MILKDRINK, :SOFTBOILED].include?(move.id)
          command_list.insert(insert_index, [move.name, 1])
          commands.insert(insert_index, i)
          insert_index += 1
        end
      end
      # Choose a menu option
      choice = @scene.pbShowCommands(_INTL("Do what with {1}?", pkmn.name), command_list)
      next if choice < 0 || choice >= commands.length
      # Effect of chosen menu option
      case commands[choice]
      when Hash   # Option defined via a MenuHandler below
        commands[choice]["effect"].call(self, @party, party_idx)
      when Integer   # Hidden move's index
        move = pkmn.moves[commands[choice]]
        if [:MILKDRINK, :SOFTBOILED].include?(move.id)
          amt = [(pkmn.totalhp / 5).floor, 1].max
          if pkmn.hp <= amt
            pbDisplay(_INTL("Not enough HP..."))
            next
          end
          @scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
          old_party_idx = party_idx
          loop do
            @scene.pbPreSelect(old_party_idx)
            party_idx = @scene.pbChoosePokemon(true, party_idx)
            break if party_idx < 0
            newpkmn = @party[party_idx]
            movename = move.name
            if party_idx == old_party_idx
              pbDisplay(_INTL("{1} can't use {2} on itself!", pkmn.name, movename))
            elsif newpkmn.egg?
              pbDisplay(_INTL("{1} can't be used on an Egg!", movename))
            elsif newpkmn.fainted? || newpkmn.hp == newpkmn.totalhp
              pbDisplay(_INTL("{1} can't be used on that Pokémon.", movename))
            else
              pkmn.hp -= amt
              hpgain = pbItemRestoreHP(newpkmn, amt)
              pbDisplay(_INTL("{1}'s HP was restored by {2} points.", newpkmn.name, hpgain))
              pbRefresh
            end
            break if pkmn.hp <= amt
          end
          @scene.pbSelect(old_party_idx)
          pbRefresh
        elsif pbCanUseHiddenMove?(pkmn, move.id)
          if pbConfirmUseHiddenMove(pkmn, move.id)
            @scene.pbEndScene
            if move.id == :FLY
              scene = PokemonRegionMap_Scene.new(-1, false)
              screen = PokemonRegionMapScreen.new(scene)
              ret = screen.pbStartFlyScreen
              if ret
                $game_temp.fly_destination = ret
                return [pkmn, move.id]
              end
              @scene.pbStartScene(
                @party, (@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel.")
              )
              next
            end
            return [pkmn, move.id]
          end
        end
      end
    end
    @scene.pbEndScene
    return nil
  end
end

#===============================================================================
# Party screen menu commands.
# Note that field moves are inserted into the list of commands after the first
# command, which is usually "Summary". If playing in Debug mode, they are
# inserted after the second command instead, which is usually "Debug". See
# insert_index above if you need to change this.
#===============================================================================
MenuHandlers.add(:party_menu, :summary, {
  "name"      => _INTL("Summary"),
  "order"     => 10,
  "effect"    => proc { |screen, party, party_idx|
    screen.scene.pbSummary(party_idx) do
      screen.scene.pbSetHelpText((party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
    end
  }
})

MenuHandlers.add(:party_menu, :debug, {
  "name"      => _INTL("Debug"),
  "order"     => 20,
  "condition" => proc { |screen, party, party_idx| next $DEBUG },
  "effect"    => proc { |screen, party, party_idx|
    screen.pbPokemonDebug(party[party_idx], party_idx)
  }
})

MenuHandlers.add(:party_menu, :switch, {
  "name"      => _INTL("Switch"),
  "order"     => 30,
  "condition" => proc { |screen, party, party_idx| next party.length > 1 },
  "effect"    => proc { |screen, party, party_idx|
    screen.scene.pbSetHelpText(_INTL("Move to where?"))
    old_party_idx = party_idx
    party_idx = screen.scene.pbChoosePokemon(true)
    screen.pbSwitch(old_party_idx, party_idx) if party_idx >= 0 && party_idx != old_party_idx
  }
})

MenuHandlers.add(:party_menu, :mail, {
  "name"      => _INTL("Mail"),
  "order"     => 40,
  "condition" => proc { |screen, party, party_idx| next !party[party_idx].egg? && party[party_idx].mail },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    command = screen.scene.pbShowCommands(_INTL("Do what with the mail?"),
                                          [_INTL("Read"), _INTL("Take"), _INTL("Cancel")])
    case command
    when 0   # Read
      pbFadeOutIn do
        pbDisplayMail(pkmn.mail, pkmn)
        screen.scene.pbSetHelpText((party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
      end
    when 1   # Take
      if pbTakeItemFromPokemon(pkmn, screen)
        screen.pbRefreshSingle(party_idx)
      end
    end
  }
})

MenuHandlers.add(:party_menu, :item, {
  "name"      => _INTL("Item"),
  "order"     => 50,
  "condition" => proc { |screen, party, party_idx| next !party[party_idx].egg? && !party[party_idx].mail },
  "effect"    => proc { |screen, party, party_idx|
    # Get all commands
    command_list = []
    commands = []
    MenuHandlers.each_available(:party_menu_item, screen, party, party_idx) do |option, hash, name|
      command_list.push(name)
      commands.push(hash)
    end
    command_list.push(_INTL("Cancel"))
    # Choose a menu option
    choice = screen.scene.pbShowCommands(_INTL("Do what with an item?"), command_list)
    next if choice < 0 || choice >= commands.length
    commands[choice]["effect"].call(screen, party, party_idx)
  }
})

MenuHandlers.add(:party_menu_item, :use, {
  "name"      => _INTL("Use"),
  "order"     => 10,
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    item = screen.scene.pbUseItem($bag, pkmn) do
      screen.scene.pbSetHelpText((party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
    end
    next if !item
    pbUseItemOnPokemon(item, pkmn, screen)
    screen.pbRefreshSingle(party_idx)
  }
})

MenuHandlers.add(:party_menu_item, :give, {
  "name"      => _INTL("Give"),
  "order"     => 20,
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    # Select Item
    item = screen.scene.pbChooseItem($bag) do
      screen.scene.pbSetHelpText((party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
    end
    
    next if !item # Player cancelled

    # Get the correctly formatted name (e.g., "Potion" instead of "POTION")
    item_data = GameData::Item.get(item)
    item_name = item_data.name

    # --- CUSTOM GIVE LOGIC ---
    if pkmn.egg?
      screen.pbDisplay(_INTL("Eggs can't hold items."))
    elsif pkmn.mail
      screen.pbDisplay(_INTL("Mail must be removed before holding an item."))
    elsif pkmn.hasItem?
      # If holding an item, ask to switch
      old_item_data = GameData::Item.get(pkmn.item)
      old_item_name = old_item_data.name
      
      if screen.pbConfirm(_INTL("{1} is already holding {2}. Would you like to switch the two items?", pkmn.name, old_item_name))
        olditem = pkmn.item
        pkmn.item = item
        $bag.add(olditem)
        $bag.remove(item)
        screen.pbDisplay(_INTL("{1} was given the {2} to hold.", pkmn.name, item_name))
        screen.pbDisplay(_INTL("The {1} was taken and put in the Bag.", old_item_name))
        screen.pbRefreshSingle(party_idx)
      end
    else
      # Simple Give
      pkmn.item = item
      $bag.remove(item)
      screen.pbDisplay(_INTL("{1} was given the {2} to hold.", pkmn.name, item_name))
      screen.pbRefreshSingle(party_idx)
    end
  }
})

MenuHandlers.add(:party_menu_item, :take, {
  "name"      => _INTL("Take"),
  "order"     => 30,
  "condition" => proc { |screen, party, party_idx| next party[party_idx].hasItem? },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    # --- CUSTOM TAKE LOGIC ---
    if pkmn.mail
      screen.pbDisplay(_INTL("Mail must be removed before holding an item."))
    else
      item = pkmn.item
      pkmn.item = nil
      if $bag.add(item)
        screen.pbDisplay(_INTL("Received the {1} from {2}.", item.name, pkmn.name))
      else
        pkmn.item = item
        screen.pbDisplay(_INTL("The Bag is full. The Pokémon was left holding the item."))
      end
      screen.pbRefreshSingle(party_idx)
    end
  }
})
MenuHandlers.add(:party_menu_item, :move, {
  "name"      => _INTL("Move"),
  "order"     => 40,
  "condition" => proc { |screen, party, party_idx| next party[party_idx].hasItem? && !party[party_idx].item.is_mail? },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    item = pkmn.item
    itemname = item.name
    portionitemname = item.portion_name
    screen.scene.pbSetHelpText(_INTL("Move {1} to where?", itemname))
    old_party_idx = party_idx
    moved = false
    loop do
      screen.scene.pbPreSelect(old_party_idx)
      party_idx = screen.scene.pbChoosePokemon(true, party_idx)
      break if party_idx < 0
      newpkmn = party[party_idx]
      break if party_idx == old_party_idx
      if newpkmn.egg?
        screen.pbDisplay(_INTL("Eggs can't hold items."))
        next
      elsif !newpkmn.hasItem?
        newpkmn.item = item
        pkmn.item = nil
        screen.scene.pbClearSwitching
        screen.pbRefresh
        screen.pbDisplay(_INTL("{1} was given the {2} to hold.", newpkmn.name, portionitemname))
        moved = true
        break
      elsif newpkmn.item.is_mail?
        screen.pbDisplay(_INTL("{1}'s mail must be removed before giving it an item.", newpkmn.name))
        next
      end
      # New Pokémon is also holding an item; ask what to do with it
      newitem = newpkmn.item
      newitemname = newitem.portion_name
      if newitemname.starts_with_vowel?
        screen.pbDisplay(_INTL("{1} is already holding an {2}.", newpkmn.name, newitemname) + "\1")
      else
        screen.pbDisplay(_INTL("{1} is already holding a {2}.", newpkmn.name, newitemname) + "\1")
      end
      next if !screen.pbConfirm(_INTL("Would you like to switch the two items?"))
      newpkmn.item = item
      pkmn.item = newitem
      screen.scene.pbClearSwitching
      screen.pbRefresh
      screen.pbDisplay(_INTL("{1} was given the {2} to hold.", newpkmn.name, portionitemname) + "\1")
      screen.pbDisplay(_INTL("{1} was given the {2} to hold.", pkmn.name, newitemname))
      moved = true
      break
    end
    screen.scene.pbSelect(old_party_idx) if !moved
  }
})

#===============================================================================
# Open the party screen
#===============================================================================
def pbPokemonScreen
  pbFadeOutIn do
    sscene = PokemonParty_Scene.new
    sscreen = PokemonPartyScreen.new(sscene, $player.party)
    sscreen.pbPokemonScreen
  end
end

#===============================================================================
# Choose a Pokémon in the party
#===============================================================================
# Choose a Pokémon/egg from the party.
# Stores result in variable _variableNumber_ and the chosen Pokémon's name in
# variable _nameVarNumber_; result is -1 if no Pokémon was chosen
def pbChoosePokemon(variableNumber, nameVarNumber, ableProc = nil, allowIneligible = false)
  chosen = 0
  pbFadeOutIn do
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene, $player.party)
    if ableProc
      chosen = screen.pbChooseAblePokemon(ableProc, allowIneligible)
    else
      screen.pbStartScene(_INTL("Choose a Pokémon."), false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    end
  end
  pbSet(variableNumber, chosen)
  if chosen >= 0
    pbSet(nameVarNumber, $player.party[chosen].name)
  else
    pbSet(nameVarNumber, "")
  end
end

def pbChooseNonEggPokemon(variableNumber, nameVarNumber)
  pbChoosePokemon(variableNumber, nameVarNumber, proc { |pkmn| !pkmn.egg? })
end

def pbChooseAblePokemon(variableNumber, nameVarNumber)
  pbChoosePokemon(variableNumber, nameVarNumber, proc { |pkmn| !pkmn.egg? && pkmn.hp > 0 })
end

# Same as pbChoosePokemon, but prevents choosing an egg or a Shadow Pokémon.
def pbChooseTradablePokemon(variableNumber, nameVarNumber, ableProc = nil, allowIneligible = false)
  chosen = 0
  pbFadeOutIn do
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene, $player.party)
    if ableProc
      chosen = screen.pbChooseTradablePokemon(ableProc, allowIneligible)
    else
      screen.pbStartScene(_INTL("Choose a Pokémon."), false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    end
  end
  pbSet(variableNumber, chosen)
  if chosen >= 0
    pbSet(nameVarNumber, $player.party[chosen].name)
  else
    pbSet(nameVarNumber, "")
  end
end

#def pbMessage(text)
#   @scene.pbDisplay(text)
#  end
  
  

def pbChoosePokemonForTrade(variableNumber, nameVarNumber, wanted)
  wanted = GameData::Species.get(wanted).species
  pbChooseTradablePokemon(variableNumber, nameVarNumber, proc { |pkmn|
    next pkmn.species == wanted
  })
end


