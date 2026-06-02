#===============================================================================
#
#===============================================================================

class CustomAnimatedPokeSprite < Sprite
  def initialize(viewport)
    super(viewport)
    @frames_array = []
    @frame_timer = 0
    @current_frame = 0
    @anim_speed = 3
    
    # Keeping your 5x scale!
    self.zoom_x = 5.0
    self.zoom_y = 5.0
  end

  def set_spritesheet(path)
    # 1. Clear old frames from memory to prevent leaks
    @frames_array.each { |bmp| bmp.dispose if bmp && !bmp.disposed? }
    @frames_array.clear
    self.bitmap = nil
    
    # 2. Load the raw massive image (the "Mega Surface") safely into RAM
    temp_mega = Bitmap.new(path)
    
    # 3. Calculate frame sizes (for EBDX, height = width of one frame)
    frame_width = temp_mega.height
    frame_height = temp_mega.height
    total_frames = temp_mega.width / frame_width
    total_frames = 1 if total_frames <= 0
    
    # 4. Slice the mega surface into individual, GPU-safe Bitmaps
    total_frames.times do |i|
      frame_bmp = Bitmap.new(frame_width, frame_height)
      src_rect = Rect.new(i * frame_width, 0, frame_width, frame_height)
      frame_bmp.blt(0, 0, temp_mega, src_rect) # Copy the square into the new frame
      @frames_array.push(frame_bmp)
    end
    
    # 5. Dispose the massive image from RAM, we don't need it anymore
    temp_mega.dispose
    
    # 6. Initialize the animation using the first safe frame
    @current_frame = 0
    @frame_timer = 0
    self.bitmap = @frames_array[@current_frame]
    
    # 7. Center the sprite
    self.ox = frame_width / 2
    self.oy = frame_height / 2
  end

  def update
    super
    return if @frames_array.length <= 1
    
    @frame_timer += 1
    if @frame_timer >= @anim_speed
      @frame_timer = 0
      @current_frame = (@current_frame + 1) % @frames_array.length
      # Swap the bitmap to the next frame (Flipbook style)
      self.bitmap = @frames_array[@current_frame]
    end
  end
  
  def dispose
    @frames_array.each { |bmp| bmp.dispose if bmp && !bmp.disposed? }
    @frames_array.clear
    super
  end
end

class Window_Pokedex < Window_DrawableCommand
  def initialize(x, y, width, height, viewport)
    @commands = []
    super(x, y, width, height, viewport)
	#@arrow = AnimatedBitmap.new("Graphics/UI/sel_arrow")
    @selarrow     = AnimatedBitmap.new("Graphics/UI/Pokedex/cursor_list")
    @unsel_bg     = AnimatedBitmap.new("Graphics/UI/Pokedex/unsel_list") # Load the new graphic
    @pokeballOwn  = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_own")
    @pokeballSeen = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_seen")
    self.baseColor   = Color.new(8, 72, 108)
    self.shadowColor = Color.new(168, 184, 184, 0)
    self.windowskin  = nil
	@arrow_bmp = AnimatedBitmap.new("Graphics/UI/sel_arrow")
    @arrow_sprite = Sprite.new(viewport)
    @arrow_sprite.bitmap = @arrow_bmp.bitmap
    @arrow_sprite.z = 99999
  end

  def commands=(value)
    @commands = value
    refresh
  end

  def dispose
    @pokeballOwn.dispose
    @pokeballSeen.dispose
    super
  end

  def species
    return (@commands.length == 0) ? 0 : @commands[self.index][:species]
  end



  def itemCount
    return @commands.length
  end

  def drawItem(index, _count, _rect)
    top = @real_top_row || 0
    return if index < top || index >= top + 8
    
    y_pos = (index - top) * 72
    rect = Rect.new(16, y_pos, self.width - 48, 64)
    
    # Draw Background: cursor_list if selected, unsel_list if not
    bg_bitmap = (index == self.index) ? @selarrow.bitmap : @unsel_bg.bitmap
    pbCopyBitmap(self.contents, bg_bitmap, rect.x - 16, rect.y + 6)
    
    species     = @commands[index][:species]
    indexNumber = @commands[index][:number]
    indexNumber -= 1 if @commands[index][:shift]
    
    if $player.seen?(species)
      # Pokeball icon
      if $player.owned?(species)
        pbCopyBitmap(self.contents, @pokeballOwn.bitmap, rect.x - 2, rect.y + 24)
      else
        pbCopyBitmap(self.contents, @pokeballSeen.bitmap, rect.x - 2, rect.y + 24)
      end
      
      # Pokémon Icon (Loaded once per drawItem)
      icon_path = GameData::Species.icon_filename(species)
      icon_bitmap = AnimatedBitmap.new(icon_path)
      src_rect = Rect.new(0, 0, 64, 64)
	  self.contents.blt(rect.x + 60, rect.y + 0, icon_bitmap.bitmap, src_rect)
      icon_bitmap.dispose
      
      num_text = sprintf("No. %03d", indexNumber)
      name_text = @commands[index][:name]
    else
      num_text = sprintf("No. %03d", indexNumber)
      name_text = "?????"
    end
    
    # Draw text
	selected = (index == self.index)
	
    pbDrawShadowText(self.contents, rect.x + 170, rect.y + 16, rect.width, rect.height, num_text, selected ? Color.new(255,255,255) : self.baseColor, selected ? self.shadowColor : self.shadowColor)
    pbDrawShadowText(self.contents, rect.x + 300, rect.y + 16, rect.width, rect.height, name_text, selected ? Color.new(255,255,255) : self.baseColor, selected ? self.shadowColor : self.shadowColor)
  end

  def refresh
    @item_max = itemCount
    dwidth  = self.width - self.borderX
    dheight = self.height - self.borderY
    self.contents = pbDoEnsureBitmap(self.contents, dwidth, dheight)
    self.contents.clear
    
    # --- SYNCHRONIZE SCROLL POSITION ON LOAD ---
    @real_top_row ||= 0
    @real_top_row = self.index - 7 if self.index >= @real_top_row + 8
    @real_top_row = self.index if self.index < @real_top_row
    max_row = [0, itemCount - 8].max
    @real_top_row = max_row if @real_top_row > max_row
    # -------------------------------------------
    
    @item_max.times do |i|
      next if i < @real_top_row || i >= @real_top_row + 8
      
      y_pos = (i - @real_top_row) * 72
      rect = Rect.new(16, y_pos, self.width - 48, 64)
      
      # 1. Draw static background
      bg = (i == self.index) ? @selarrow.bitmap : @unsel_bg.bitmap
      pbCopyBitmap(self.contents, bg, rect.x - 16, rect.y + 6)
      
      # 2. Draw content (Text/Icons)
      drawItem(i, @item_max, nil)
    end
  end

  def update
    old_index = self.index
    super
    @uparrow.visible   = false
    @downarrow.visible = false
    
    @real_top_row ||= 0
    
    # If cursor moves below the 8th item, scroll down
    if self.index >= @real_top_row + 8
      @real_top_row = self.index - 7
    end
    
    # If cursor moves above the 1st item, scroll up
    if self.index < @real_top_row
      @real_top_row = self.index
    end
    
    # Prevent empty gaps from appearing at the very end of the list
    max_row = [0, itemCount - 8].max
    @real_top_row = max_row if @real_top_row > max_row
    
    # Freeze the engine's built-in scrolling behavior permanently
    self.oy = 0
    
    # Force a graphics refresh if the cursor moved or the list scrolled
    if @last_real_top_row != @real_top_row || old_index != self.index
      @last_real_top_row = @real_top_row
      refresh
    end
	# --- ANIMATED SPRITE CURSOR ---
    if @arrow_sprite
      # Calculate the Y position based on the current row
      row_y = (self.index - @real_top_row) * 72
      
      # Classic bobbing math
      bob = (Math.sin(Graphics.frame_count * 0.25) * 4).round
      
      # Position the sprite globally (avoids window clipping)
      # self.x and self.y are the window's position on screen.
      # Adjust the -4 (X) and +40 (Y) numbers if you need to fine-tune the position.
      @arrow_sprite.x = self.x - 16 + bob
      @arrow_sprite.y = self.y + row_y + 22
      @arrow_sprite.visible = self.visible
    end
	end
  end
#===============================================================================
#
def dispose
    @arrow_sprite.dispose if @arrow_sprite
    @arrow_bmp.dispose if @arrow_bmp
    super
  end
#===============================================================================
class PokedexSearchSelectionSprite < Sprite
  attr_reader :index
  attr_accessor :cmds
  attr_accessor :minmax

  def initialize(viewport = nil)
    super(viewport)
    @selbitmap = AnimatedBitmap.new("Graphics/UI/Pokedex/cursor_search")
    self.bitmap = @selbitmap.bitmap
    self.mode = -1
    @index = 0
    refresh
  end

  def dispose
    @selbitmap.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def mode=(value)
    @mode = value
    case @mode
    when 0     # Order
      @xstart = 54
      @ystart = 136
      @xgap = 236
      @ygap = 64
      @cols = 2
    when 1     # Name
      @xstart = 86
      @ystart = 124
      @xgap = 52
      @ygap = 52
      @cols = 7
    when 2     # Type
      @xstart = 16
      @ystart = 112
      @xgap = 124
      @ygap = 44
      @cols = 4
    when 3, 4   # Height, weight
      @xstart = 52
      @ystart = 118
      @xgap = 8
      @ygap = 112
    when 5     # Color
      @xstart = 70
      @ystart = 122
      @xgap = 132
      @ygap = 52
      @cols = 3
    when 6     # Shape
      @xstart = 90
      @ystart = 124
      @xgap = 70
      @ygap = 70
      @cols = 5
    end
  end

  def refresh
    # Size and position cursor
    if @mode == -1   # Main search screen
      case @index
      when 0     # Order
        self.src_rect.y = 0
        self.src_rect.height = 44
      when 1, 5   # Name, color
        self.src_rect.y = 44
        self.src_rect.height = 44
      when 2     # Type
        self.src_rect.y = 88
        self.src_rect.height = 44
      when 3, 4   # Height, weight
        self.src_rect.y = 132
        self.src_rect.height = 44
      when 6     # Shape
        self.src_rect.y = 176
        self.src_rect.height = 68
      else       # Reset/start/cancel
        self.src_rect.y = 244
        self.src_rect.height = 40
      end
      case @index
      when 0         # Order
        self.x = 314
        self.y = 60
      when 1, 2, 3, 4   # Name, type, height, weight
        self.x = 122
        self.y = 118 + ((@index - 1) * 52)
      when 5         # Color
        self.x = 370
        self.y = 118
      when 6         # Shape
        self.x = 420 + 8
        self.y = 224
      #when 7, 8, 9     # Reset, start, cancel
      #  self.x = 12 + ((@index - 7) * 176)
      #  self.y = 342
	  when 7, 8, 9     # Reset, Start, Cancel
  case @index
  when 7 # Reset button
    self.x = 18
    self.y = 342
  when 8 # Start button
    self.x = 188
    self.y = 342
  when 9 # Cancel button
    self.x = 358
    self.y = 342
	end
      end
    else   # Parameter screen
      case @index
      when -2, -3   # OK, Cancel
        self.src_rect.y = 244
        self.src_rect.height = 40
      else
        case @mode
        when 0     # Order
          self.src_rect.y = 0
          self.src_rect.height = 44
        when 1     # Name
          self.src_rect.y = 284
          self.src_rect.height = 44
        when 2, 5   # Type, color
          self.src_rect.y = 44
          self.src_rect.height = 44
        when 3, 4   # Height, weight
          self.src_rect.y = (@minmax == 1) ? 328 : 424
          self.src_rect.height = 96
        when 6     # Shape
          self.src_rect.y = 176
          self.src_rect.height = 68
        end
      end
      case @index
      when -1   # Blank option
        if @mode == 3 || @mode == 4   # Height/weight range
          self.x = @xstart + ((@cmds + 1) * @xgap * (@minmax % 2))
          self.y = @ystart + (@ygap * ((@minmax + 1) % 2))
        else
          self.x = @xstart + ((@cols - 1) * @xgap)
          self.y = @ystart + ((@cmds / @cols).floor * @ygap)
        end
      when -2   # OK
        self.x = 4 + 14
        self.y = 334 + 8
      when -3   # Cancel
        self.x = 356 + 2
        self.y = 334 + 8
      else
        case @mode
        when 0, 1, 2, 5, 6   # Order, name, type, color, shape
          if @index >= @cmds
            self.x = @xstart + ((@cols - 1) * @xgap)
            self.y = @ystart + ((@cmds / @cols).floor * @ygap)
          else
            self.x = @xstart + ((@index % @cols) * @xgap)
            self.y = @ystart + ((@index / @cols).floor * @ygap)
          end
        when 3, 4         # Height, weight
          if @index >= @cmds
            self.x = @xstart + ((@cmds + 1) * @xgap * ((@minmax + 1) % 2))
          else
            self.x = @xstart + ((@index + 1) * @xgap)
          end
          self.y = @ystart + (@ygap * ((@minmax + 1) % 2))
        end
      end
    end
  end
end

#===============================================================================
# Pokédex main screen
#===============================================================================
class PokemonPokedex_Scene
  MODENUMERICAL = 0
  MODEATOZ      = 1
  MODETALLEST   = 2
  MODESMALLEST  = 3
  MODEHEAVIEST  = 4
  MODELIGHTEST  = 5



  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    @sprites["anim_icon"].update if @sprites["anim_icon"]
  end

  def pbStartScene
    @sliderbitmap       = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_slider")
    @typebitmap         = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_types"))
    @shapebitmap        = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_shapes")
    @hwbitmap           = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_hw"))
    @selbitmap          = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_searchsel")
    @searchsliderbitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_searchslider"))
    
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999 # Keeps the whole scene on top of the map
	
	
	
    # 1. Base Background (Bottom layer)
    addBackgroundPlane(@sprites, "base_bg", "Pokedex/bg", @viewport)
    @sprites["base_bg"].z = 0
    
    # 2. YOUR ANIMATED SPRITE (Above base, Below list)
    @sprites["anim_icon"] = CustomAnimatedPokeSprite.new(@viewport)
    @sprites["anim_icon"].x = 412
    @sprites["anim_icon"].y = 332
    @sprites["anim_icon"].z = 5 
    
    # 3. List Background (Above sprite)
    addBackgroundPlane(@sprites, "background", "Pokedex/bg_list", @viewport)
    @sprites["background"].z = 10
    
    # 4. Search Background
    addBackgroundPlane(@sprites, "searchbg", "Pokedex/bg_search", @viewport)
    @sprites["searchbg"].visible = false
    @sprites["searchbg"].z = 100000
    
    # 5. Pokedex Window
    @sprites["pokedex"] = Window_Pokedex.new(Graphics.width - 640 - 116, 64, 640, 656, @viewport)
    @sprites["pokedex"].z = 20
    
    # 6. Text Overlay (Highest layer for text/counters)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = 100001
    pbSetSystemFont(@sprites["overlay"].bitmap)
    
    # 7. Search Cursor (Topmost UI)
    @sprites["searchcursor"] = PokedexSearchSelectionSprite.new(@viewport)
    @sprites["searchcursor"].visible = false
    @sprites["searchcursor"].z = 100002
    
    # Hidden engine icon (keep initialized)
    @sprites["icon"] = PokemonSprite.new(@viewport)
    @sprites["icon"].setOffset(PictureOrigin::CENTER)
    @sprites["icon"].x = 112
    @sprites["icon"].y = 196
    @sprites["icon"].visible = false
    
    @searchResults = false
    @searchParams  = [$PokemonGlobal.pokedexMode, -1, -1, -1, -1, -1, -1, -1, -1, -1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
	
	@sprites["switch_button"] = IconSprite.new(@viewport)
    @sprites["switch_button"].setBitmap("Graphics/UI/switch.png")
    @sprites["switch_button"].x = 444
    @sprites["switch_button"].y = 624
    @sprites["switch_button"].z = 99999
	
	@sprites["back_button"] = IconSprite.new(@viewport)
    @sprites["back_button"].setBitmap("Graphics/UI/back.png")
    @sprites["back_button"].x = 16
    @sprites["back_button"].y = 16
    @sprites["back_button"].z = 99999
	
	# --- LOAD THE GRAPHICAL SCROLL ARROWS ---
    @sprites["arrow_up"] = IconSprite.new(@viewport)
    @sprites["arrow_up"].setBitmap("Graphics/UI/Pokedex/arrow_up.png")
    @sprites["arrow_up"].x = 1500 # 16px from right edge of 1600 width
    @sprites["arrow_up"].y = 64   # 64px from top edge
    @sprites["arrow_up"].z = 99999

    @sprites["arrow_down"] = IconSprite.new(@viewport)
    @sprites["arrow_down"].setBitmap("Graphics/UI/Pokedex/arrow_down.png")
    @sprites["arrow_down"].x = 1500 # 16px from right edge of 1600 width
    @sprites["arrow_down"].y = 640  # 640px from top edge
    @sprites["arrow_down"].z = 99999
	
	@sprites["scrollbar_btn"] = IconSprite.new(@viewport)
    @sprites["scrollbar_btn"].setBitmap("Graphics/UI/Pokedex/scrollbar.png")
    @sprites["scrollbar_btn"].x = 1500 # 16px from right edge of 1600 width
    @sprites["scrollbar_btn"].y = 128  # Starts at y=128
    @sprites["scrollbar_btn"].z = 99999
	
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
	@sprites["back_button"].dispose if @sprites["back_button"]
    @sprites["switch_button"].dispose if @sprites["switch_button"]
    @sprites["arrow_up"].dispose if @sprites["arrow_up"]
    @sprites["arrow_down"].dispose if @sprites["arrow_down"]
	@sprites["scrollbar_btn"].dispose if @sprites["scrollbar_btn"]
    pbDisposeSpriteHash(@sprites)
    @anim_poke_bmp.dispose if @anim_poke_bmp # Clears the animation data
    @sliderbitmap.dispose
    @typebitmap.dispose
    @shapebitmap.dispose
    @hwbitmap.dispose
    @selbitmap.dispose
    @searchsliderbitmap.dispose
    @viewport.dispose
  end

  # Gets the region used for displaying Pokédex entries. Species will be listed
  # according to the given region's numbering and the returned region can have
  # any value defined in the town map data file. It is currently set to the
  # return value of pbGetCurrentRegion, and thus will change according to the
  # current map's MapPosition metadata setting.
  def pbGetPokedexRegion
    if Settings::USE_CURRENT_REGION_DEX
      region = pbGetCurrentRegion
      region = -1 if region >= $player.pokedex.dexes_count - 1
      return region
    else
      return $PokemonGlobal.pokedexDex   # National Dex -1, regional Dexes 0, 1, etc.
    end
  end

  # Determines which index of the array $PokemonGlobal.pokedexIndex to save the
  # "last viewed species" in. All regional dexes come first in order, then the
  # National Dex at the end.
  def pbGetSavePositionIndex
    index = pbGetPokedexRegion
    if index == -1   # National Dex (comes after regional Dex indices)
      index = $player.pokedex.dexes_count - 1
    end
    return index
  end

  def pbCanAddForModeList?(mode, species)
    case mode
    when MODEATOZ
      return $player.seen?(species)
    when MODEHEAVIEST, MODELIGHTEST, MODETALLEST, MODESMALLEST
      return $player.owned?(species)
    end
    return true   # For MODENUMERICAL
  end

  def pbGetDexList
    region = pbGetPokedexRegion
    regionalSpecies = pbAllRegionalSpecies(region)
    if !regionalSpecies || regionalSpecies.length == 0
      # If no Regional Dex defined for the given region, use the National Pokédex
      regionalSpecies = []
      GameData::Species.each_species { |s| regionalSpecies.push(s.id) }
    end
    shift = Settings::DEXES_WITH_OFFSETS.include?(region)
    ret = []
    regionalSpecies.each_with_index do |species, i|
      next if !species
      next if !pbCanAddForModeList?($PokemonGlobal.pokedexMode, species)
      _gender, form, _shiny = $player.pokedex.last_form_seen(species)
      species_data = GameData::Species.get_species_form(species, form)
      ret.push({
        :species => species,
        :name    => species_data.name,
        :height  => species_data.height,
        :weight  => species_data.weight,
        :number  => i + 1,
        :shift   => shift,
        :types   => species_data.types,
        :color   => species_data.color,
        :shape   => species_data.shape
      })
    end
    return ret
  end

  def pbRefreshDexList(index = 0)
    dexlist = pbGetDexList
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL
      # Hide the Dex number 0 species if unseen
      dexlist[0] = nil if dexlist[0][:shift] && !$player.seen?(dexlist[0][:species])
      # Remove unseen species from the end of the list
      i = dexlist.length - 1
      loop do
        break if i < 0 || !dexlist[i] || $player.seen?(dexlist[i][:species])
        dexlist[i] = nil
        i -= 1
      end
      dexlist.compact!
      # Sort species in ascending order by Regional Dex number
      dexlist.sort! { |a, b| a[:number] <=> b[:number] }
    when MODEATOZ
      dexlist.sort! { |a, b| (a[:name] == b[:name]) ? a[:number] <=> b[:number] : a[:name] <=> b[:name] }
    when MODEHEAVIEST
      dexlist.sort! { |a, b| (a[:weight] == b[:weight]) ? a[:number] <=> b[:number] : b[:weight] <=> a[:weight] }
    when MODELIGHTEST
      dexlist.sort! { |a, b| (a[:weight] == b[:weight]) ? a[:number] <=> b[:number] : a[:weight] <=> b[:weight] }
    when MODETALLEST
      dexlist.sort! { |a, b| (a[:height] == b[:height]) ? a[:number] <=> b[:number] : b[:height] <=> a[:height] }
    when MODESMALLEST
      dexlist.sort! { |a, b| (a[:height] == b[:height]) ? a[:number] <=> b[:number] : a[:height] <=> b[:height] }
    end
    @dexlist = dexlist
    @sprites["pokedex"].commands = @dexlist
    @sprites["pokedex"].index    = index
    @sprites["pokedex"].refresh
    if @searchResults
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_list")
    end
    pbRefresh
  end

  def pbRefresh
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(8, 100, 156)
    shadow = Color.new(168, 184, 184, 0)
    iconspecies = @sprites["pokedex"].species
    iconspecies = nil if !$player.seen?(iconspecies)
    # Write various bits of text
    dexname = _INTL("Pokédex")
    if $player.pokedex.dexes_count > 1
      thisdex = Settings.pokedex_names[pbGetSavePositionIndex]
      if thisdex
        dexname = (thisdex.is_a?(Array)) ? thisdex[0] : thisdex
      end
    end
    textpos = [
      [dexname, 16, 652, :left, Color.new(255,255,255), Color.new(10,10,10,0)]
    ]
    #textpos.push([GameData::Species.get(iconspecies).name, 112, 58, :center, base, shadow]) if iconspecies
    if @searchResults
      textpos.push([_INTL("Search results"), 112, 314, :center, base, shadow])
      textpos.push([@dexlist.length.to_s, 112, 346, :center, base, shadow])
    else
      textpos.push([_INTL("Seen"), 412, 10, :left, Color.new(8, 100, 156), Color.new(0,0,0,0)])
      textpos.push([$player.pokedex.seen_count(pbGetPokedexRegion).to_s, 502, 10, :left, Color.new(8, 100, 156), Color.new(0,0,0,0)])
      textpos.push([_INTL("Owned"), 652, 10, :left, Color.new(8, 100, 156), Color.new(0,0,0,0)])
      textpos.push([$player.pokedex.owned_count(pbGetPokedexRegion).to_s, 762, 10, :left, Color.new(8, 100, 156), Color.new(0,0,0,0)])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Set Pokémon sprite
    setIconBitmap(iconspecies)
    # Draw slider arrows
    itemlist = @sprites["pokedex"]
    showslider = false
    # Get the exact top row from our custom scrolling logic
    top_index = itemlist.instance_variable_get(:@real_top_row) || 0
    visible_items = 8

    if top_index > 0
      # Hiding native up arrow so it doesn't interfere with custom arrow_up.png
      # overlay.blt(Graphics.width - 100, 64, @sliderbitmap.bitmap, Rect.new(0, 0, 84, 64))
      showslider = true
    end
    
    if top_index + visible_items < itemlist.itemCount
      # Hiding native down arrow so it doesn't interfere with custom arrow_down.png
      # overlay.blt(Graphics.width - 100, 640, @sliderbitmap.bitmap, Rect.new(0, 64, 84, 64))
      showslider = true
    end
    
    # Draw slider box
    if showslider
      sliderheight = 512
      # Use our exact item counts instead of the engine's default row math
      boxheight = (sliderheight * visible_items / itemlist.itemCount).floor
      boxheight += [(sliderheight - boxheight) / 2, sliderheight / 6].min
      boxheight = [boxheight.floor, 128].max
      
      y = 128
      if itemlist.itemCount > visible_items
        y += ((sliderheight - boxheight) * top_index / (itemlist.itemCount - visible_items)).floor
      end
      
      # HIDING NATIVE SLIDER PARTS
      # overlay.blt(Graphics.width - 100, y, @sliderbitmap.bitmap, Rect.new(84, 0, 84, 16))
      # i = 0
      # while i * 16 < boxheight - 8 - 16
      #   height = [boxheight - 8 - 16 - (i * 16), 16].min
      #   overlay.blt(Graphics.width - 100, y + 16 + (i * 16), @sliderbitmap.bitmap, Rect.new(84, 16, 84, height))
      #   i += 1
      # end
      # overlay.blt(Graphics.width - 100, y + boxheight - 16, @sliderbitmap.bitmap, Rect.new(84, 112, 84, 16))
    end
  end

  def pbRefreshDexSearch(params, cursor_index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    
    # Force overlay above cursor
    @sprites["overlay"].z = 100003
    
    # Text colors for the search screen
    base1  = Color.new(255, 255, 255) # White (Hover state)
    base   = Color.new(8, 72, 108)    # Blue (Unfocused state)
    shadow = Color.new(72, 72, 72, 0)
    
    # Helper: Returns White if hovered, Blue if not
    def get_val_color(i, cursor, white, normal)
      return (i == cursor) ? white : normal
    end
    
    # Pre-calculate the color for all 10 slots
    c = []
    10.times { |i| c[i] = get_val_color(i, cursor_index, base1, base) }

    # Write titles (Always base1/White) and buttons (Dynamic Color)
    textpos = [
      [_INTL("Search Mode"), 264, 14, :center, base1, shadow],
      [_INTL("Order"), 302, 64, :right, base1, shadow],
      [_INTL("Name"), 114, 122, :right, base1, shadow],
      [_INTL("Type"), 114, 174, :right, base1, shadow],
      [_INTL("Height"), 114, 226, :right, base1, shadow],
      [_INTL("Weight"), 114, 278, :right, base1, shadow],
      [_INTL("Color"), 362, 122, :right, base1, shadow],
      [_INTL("Shape"), 462, 174, :center, base1, shadow],
      [_INTL("Reset"), 92, 346, :center, c[7], shadow, 1],
      [_INTL("Start"), 262, 346, :center, c[8], shadow, :outline],
      [_INTL("Cancel"), 432, 346, :center, c[9], shadow, :outline]
    ]
    
    # Write dynamic values (Using dynamic color 'c')
    textpos.push([@orderCommands[params[0]], 402, 66, :center, c[0], shadow, :outline])
    textpos.push([(params[1] < 0) ? "----" : @nameCommands[params[1]], 184, 124, :center, c[1], shadow, :outline])
    textpos.push([(params[8] < 0) ? "----" : @colorCommands[params[8]].name, 434, 124, :center, c[5], shadow, :outline])
    
    # Draw type icons or empty text
    if params[2] >= 0
      type_number = @typeCommands[params[2]].icon_position
      typerect = Rect.new(0, type_number * 32, 96, 32)
      overlay.blt(136, 176, @typebitmap.bitmap, typerect)
    else
      textpos.push(["----", 186, 176, :center, c[2], shadow, :outline])
    end
    if params[3] >= 0
      type_number = @typeCommands[params[3]].icon_position
      typerect = Rect.new(0, type_number * 32, 96, 32)
      overlay.blt(264, 176, @typebitmap.bitmap, typerect)
    else
      textpos.push(["----", 314, 176, :center, c[2], shadow, :outline])
    end
    
    # Write height and weight limits
    ht1 = (params[4] < 0) ? 0 : (params[4] >= @heightCommands.length) ? 999 : @heightCommands[params[4]]
    ht2 = (params[5] < 0) ? 999 : (params[5] >= @heightCommands.length) ? 0 : @heightCommands[params[5]]
    wt1 = (params[6] < 0) ? 0 : (params[6] >= @weightCommands.length) ? 9999 : @weightCommands[params[6]]
    wt2 = (params[7] < 0) ? 9999 : (params[7] >= @weightCommands.length) ? 0 : @weightCommands[params[7]]
    hwoffset = false
    if System.user_language[3..4] == "US"
      ht1 = (params[4] >= @heightCommands.length) ? 99 * 12 : (ht1 / 0.254).round
      ht2 = (params[5] < 0) ? 99 * 12 : (ht2 / 0.254).round
      wt1 = (params[6] >= @weightCommands.length) ? 99_990 : (wt1 / 0.254).round
      wt2 = (params[7] < 0) ? 99_990 : (wt2 / 0.254).round
      textpos.push([sprintf("%d'%02d''", ht1 / 12, ht1 % 12), 176, 228, :center, c[3], shadow, :outline])
      textpos.push([sprintf("%d'%02d''", ht2 / 12, ht2 % 12), 304, 228, :center, c[3], shadow, :outline])
      textpos.push([sprintf("%.1f", wt1 / 10.0), 176, 280, :center, c[4], shadow, :outline])
      textpos.push([sprintf("%.1f", wt2 / 10.0), 304, 280, :center, c[4], shadow, :outline])
      hwoffset = true
    else
      textpos.push([sprintf("%.1f", ht1 / 10.0), 176, 228, :center, c[3], shadow, :outline])
      textpos.push([sprintf("%.1f", ht2 / 10.0), 304, 228, :center, c[3], shadow, :outline])
      textpos.push([sprintf("%.1f", wt1 / 10.0), 176, 280, :center, c[4], shadow, :outline])
      textpos.push([sprintf("%.1f", wt2 / 10.0), 304, 280, :center, c[4], shadow, :outline])
    end
    overlay.blt(354, 214, @hwbitmap.bitmap, Rect.new(0, (hwoffset) ? 44 : 0, 32, 44))
    overlay.blt(353, 266, @hwbitmap.bitmap, Rect.new(32, (hwoffset) ? 44 : 0, 32, 44))
    
    # Draw shape icon
    if params[9] >= 0
      shape_number = @shapeCommands[params[9]].icon_position
      shaperect = Rect.new(0, shape_number * 60, 60, 60)
      overlay.blt(432, 224, @shapebitmap.bitmap, shaperect)
    end
    
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def pbRefreshDexSearchParam(mode, cmds, sel, cursor_index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    
    # 1. Spotlight Colors
    c_white = Color.new(255, 255, 255)
    c_blue  = Color.new(8, 72, 108)
    s_none  = Color.new(0, 0, 0, 0)
    s_dark  = Color.new(72, 72, 72, 0)

    # Helper: Returns [White, No Shadow] if hovered, otherwise [Blue, Dark Shadow]
    def get_style(idx, cursor, white, blue, none, dark)
      return (idx == cursor) ? [white, none] : [blue, dark]
    end

    # Dynamic styles for OK/Cancel (-2 and -3)
    ok_s     = get_style(-2, cursor_index, c_white, c_blue, s_none, s_dark)
    cancel_s = get_style(-3, cursor_index, c_white, c_blue, s_none, s_dark)

    textpos = [
      [_INTL("Search Mode"), 264, 14, :center, c_white, s_dark],
      [_INTL("OK"), 92, 346, :center, ok_s[0], ok_s[1], :outline],
      [_INTL("Cancel"), 432, 346, :center, cancel_s[0], cancel_s[1], :outline]
    ]
    title = [_INTL("Order"), _INTL("Name"), _INTL("Type"), _INTL("Height"),
             _INTL("Weight"), _INTL("Color"), _INTL("Shape")][mode]
    textpos.push([title, 102, (mode == 6) ? 70 : 64, :left, c_white, s_dark])
    
    case mode
    when 0   # Order
      xstart = 54; ystart = 128; xgap = 236; ygap = 64; halfwidth = 92; cols = 2
      selbuttony = 0; selbuttonheight = 44
    when 1   # Name
      xstart = 86; ystart = 114; xgap = 52; ygap = 52; halfwidth = 22; cols = 7
      selbuttony = 156; selbuttonheight = 44
    when 2   # Type
      xstart = 16; ystart = 112; xgap = 124; ygap = 44; halfwidth = 62; cols = 4
      selbuttony = 44; selbuttonheight = 44
    when 3, 4   # Height, weight
      xstart = 52; ystart = 118; xgap = 304 / (cmds.length + 1); ygap = 112
      halfwidth = 60; cols = cmds.length + 1
    when 5   # Color
      xstart = 70; ystart = 114; xgap = 132; ygap = 52; halfwidth = 62; cols = 3
      selbuttony = 44; selbuttonheight = 44
    when 6   # Shape
      xstart = 90; ystart = 124; xgap = 70; ygap = 70; halfwidth = 0; cols = 5
      selbuttony = 88; selbuttonheight = 68
    end
    
    # Draw selected option(s) text in top bar (Keeps default blue)
    case mode
    when 2   # Type icons
      2.times do |i|
        if !sel[i] || sel[i] < 0
          textpos.push(["----", 306 + (128 * i), 66, :center, c_blue, s_dark, :outline])
        else
          type_number = @typeCommands[sel[i]].icon_position
          typerect = Rect.new(0, type_number * 32, 96, 32)
          overlay.blt(258 + (128 * i), 66, @typebitmap.bitmap, typerect)
        end
      end
    when 3   # Height range
      ht1 = (sel[0] < 0) ? 0 : (sel[0] >= @heightCommands.length) ? 999 : @heightCommands[sel[0]]
      ht2 = (sel[1] < 0) ? 999 : (sel[1] >= @heightCommands.length) ? 0 : @heightCommands[sel[1]]
      hwoffset = false
      if System.user_language[3..4] == "US"
        ht1 = (sel[0] >= @heightCommands.length) ? 99 * 12 : (ht1 / 0.254).round
        ht2 = (sel[1] < 0) ? 99 * 12 : (ht2 / 0.254).round
        txt1 = sprintf("%d'%02d''", ht1 / 12, ht1 % 12)
        txt2 = sprintf("%d'%02d''", ht2 / 12, ht2 % 12)
        hwoffset = true
      else
        txt1 = sprintf("%.1f", ht1 / 10.0)
        txt2 = sprintf("%.1f", ht2 / 10.0)
      end
      textpos.push([txt1, 294, 66, :center, c_blue, s_dark, :outline])
      textpos.push([txt2, 422, 66, :center, c_blue, s_dark, :outline])
      overlay.blt(462, 52, @hwbitmap.bitmap, Rect.new(0, (hwoffset) ? 44 : 0, 32, 44))
    when 4   # Weight range
      wt1 = (sel[0] < 0) ? 0 : (sel[0] >= @weightCommands.length) ? 9999 : @weightCommands[sel[0]]
      wt2 = (sel[1] < 0) ? 9999 : (sel[1] >= @weightCommands.length) ? 0 : @weightCommands[sel[1]]
      hwoffset = false
      if System.user_language[3..4] == "US"
        wt1 = (sel[0] >= @weightCommands.length) ? 99_990 : (wt1 / 0.254).round
        wt2 = (sel[1] < 0) ? 99_990 : (wt2 / 0.254).round
        txt1 = sprintf("%.1f", wt1 / 10.0)
        txt2 = sprintf("%.1f", wt2 / 10.0)
        hwoffset = true
      else
        txt1 = sprintf("%.1f", wt1 / 10.0)
        txt2 = sprintf("%.1f", wt2 / 10.0)
      end
      textpos.push([txt1, 293, 66, :center, c_blue, s_dark, :outline])
      textpos.push([txt2, 421, 66, :center, c_blue, s_dark, :outline])
      overlay.blt(462, 52, @hwbitmap.bitmap, Rect.new(32, (hwoffset) ? 44 : 0, 32, 44))
    when 5   # Color
      if sel[0] < 0
        textpos.push(["----", 396, 66, :center, c_blue, s_dark, :outline])
      else
        textpos.push([cmds[sel[0]].name, 396, 66, :center, c_blue, s_dark, :outline])
      end
    when 6   # Shape icon
      if sel[0] >= 0
        shaperect = Rect.new(0, @shapeCommands[sel[0]].icon_position * 60, 60, 60)
        overlay.blt(374, 58, @shapebitmap.bitmap, shaperect)
      end
    else
      if sel[0] < 0
        text = ["----", "-", "----", "", "", "----", ""][mode]
        textpos.push([text, 380, 66, :center, c_blue, s_dark, :outline])
      else
        textpos.push([cmds[sel[0]], 380, 66, :center, c_blue, s_dark, :outline])
      end
    end
    
    # Draw selected option(s) button graphic
    if [3, 4].include?(mode)   # Height, weight
      xpos1 = xstart + ((sel[0] + 1) * xgap)
      xpos1 = xstart if sel[0] < -1
      xpos2 = xstart + ((sel[1] + 1) * xgap)
      xpos2 = xstart + (cols * xgap) if sel[1] < 0
      xpos2 = xstart if sel[1] >= cols - 1
      ypos1 = ystart + 180
      ypos2 = ystart + 36
      overlay.blt(16, 120, @searchsliderbitmap.bitmap, Rect.new(0, 192, 32, 44)) if sel[1] < cols - 1
      overlay.blt(464, 120, @searchsliderbitmap.bitmap, Rect.new(32, 192, 32, 44)) if sel[1] >= 0
      overlay.blt(16, 264, @searchsliderbitmap.bitmap, Rect.new(0, 192, 32, 44)) if sel[0] >= 0
      overlay.blt(464, 264, @searchsliderbitmap.bitmap, Rect.new(32, 192, 32, 44)) if sel[0] < cols - 1
      hwrect = Rect.new(0, 0, 120, 96)
      overlay.blt(xpos2, ystart, @searchsliderbitmap.bitmap, hwrect)
      hwrect.y = 96
      overlay.blt(xpos1, ystart + ygap, @searchsliderbitmap.bitmap, hwrect)
      textpos.push([txt1, xpos1 + halfwidth, ypos1, :center, c_blue])
      textpos.push([txt2, xpos2 + halfwidth, ypos2, :center, c_blue])
    else
      sel.length.times do |i|
        selrect = Rect.new(0, selbuttony, @selbitmap.bitmap.width, selbuttonheight)
        if sel[i] >= 0
          overlay.blt(xstart + ((sel[i] % cols) * xgap),
                      ystart + ((sel[i] / cols).floor * ygap),
                      @selbitmap.bitmap, selrect)
        else
          overlay.blt(xstart + ((cols - 1) * xgap),
                      ystart + ((cmds.length / cols).floor * ygap),
                      @selbitmap.bitmap, selrect)
        end
      end
    end
    
    # Draw Options (Dynamic Spotlight applied here)
    case mode
    when 0, 1   # Order, name
      cmds.length.times do |i|
        x = xstart + halfwidth + ((i % cols) * xgap)
        y = ystart + 14 + ((i / cols).floor * ygap)
        opt_s = get_style(i, cursor_index, c_white, c_blue, s_none, s_dark)
        textpos.push([cmds[i], x, y, :center, opt_s[0], opt_s[1], :outline])
      end
      if mode != 0
        blank_s = get_style(-1, cursor_index, c_white, c_blue, s_none, s_dark)
        textpos.push([(mode == 1) ? "-" : "----",
                      xstart + halfwidth + ((cols - 1) * xgap),
                      ystart + 14 + ((cmds.length / cols).floor * ygap),
                      :center, blank_s[0], blank_s[1], :outline])
      end
    when 2   # Type
      typerect = Rect.new(0, 0, 96, 32)
      cmds.length.times do |i|
        typerect.y = @typeCommands[i].icon_position * 32
        overlay.blt(xstart + 14 + ((i % cols) * xgap),
                    ystart + 6 + ((i / cols).floor * ygap),
                    @typebitmap.bitmap, typerect)
      end
      blank_s = get_style(-1, cursor_index, c_white, c_blue, s_none, s_dark)
      textpos.push(["----",
                    xstart + halfwidth + ((cols - 1) * xgap),
                    ystart + 14 + ((cmds.length / cols).floor * ygap),
                    :center, blank_s[0], blank_s[1], :outline])
    when 5   # Color
      cmds.length.times do |i|
        x = xstart + halfwidth + ((i % cols) * xgap)
        y = ystart + 14 + ((i / cols).floor * ygap)
        opt_s = get_style(i, cursor_index, c_white, c_blue, s_none, s_dark)
        textpos.push([cmds[i].name, x, y, :center, opt_s[0], opt_s[1], :outline])
      end
      blank_s = get_style(-1, cursor_index, c_white, c_blue, s_none, s_dark)
      textpos.push(["----",
                    xstart + halfwidth + ((cols - 1) * xgap),
                    ystart + 14 + ((cmds.length / cols).floor * ygap),
                    :center, blank_s[0], blank_s[1], :outline])
    when 6   # Shape
      shaperect = Rect.new(0, 0, 60, 60)
      cmds.length.times do |i|
        shaperect.y = @shapeCommands[i].icon_position * 60
        overlay.blt(xstart + 4 + ((i % cols) * xgap),
                    ystart + 4 + ((i / cols).floor * ygap),
                    @shapebitmap.bitmap, shaperect)
      end
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def setIconBitmap(species)
    gender, form, _shiny = $player.pokedex.last_form_seen(species)
    
    # 1. Let the engine and EBDX update the hidden sprite so they don't crash
    @sprites["icon"].setSpeciesBitmap(species, gender, form, false)
    
    return if !species
    
    # 2. Get the path and redirect to the EBDX folder
    filename = GameData::Species.front_sprite_filename(species, form, gender)
    if filename
      ebdx_path = filename.sub("Graphics/Pokemon/", "Graphics/EBDX/Battlers/")
      
      # 3. Pass the path to our manual slicer
      if File.exist?(ebdx_path)
        @sprites["anim_icon"].set_spritesheet(ebdx_path)
      else
        @sprites["anim_icon"].set_spritesheet(filename) # Fallback if missing
      end
    end
  end

  def pbSearchDexList(params)
    $PokemonGlobal.pokedexMode = params[0]
    dexlist = pbGetDexList
    # Filter by name
    if params[1] >= 0
      scanNameCommand = @nameCommands[params[1]].scan(/./)
      dexlist = dexlist.find_all do |item|
        next false if !$player.seen?(item[:species])
        firstChar = item[:name][0, 1]
        next scanNameCommand.any? { |v| v == firstChar }
      end
    end
    # Filter by type
    if params[2] >= 0 || params[3] >= 0
      stype1 = (params[2] >= 0) ? @typeCommands[params[2]].id : nil
      stype2 = (params[3] >= 0) ? @typeCommands[params[3]].id : nil
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        types = item[:types]
        if stype1 && stype2
          # Find species that match both types
          next types.include?(stype1) && types.include?(stype2)
        elsif stype1
          # Find species that match first type entered
          next types.include?(stype1)
        elsif stype2
          # Find species that match second type entered
          next types.include?(stype2)
        else
          next false
        end
      end
    end
    # Filter by height range
    if params[4] >= 0 || params[5] >= 0
      minh = (params[4] < 0) ? 0 : (params[4] >= @heightCommands.length) ? 999 : @heightCommands[params[4]]
      maxh = (params[5] < 0) ? 999 : (params[5] >= @heightCommands.length) ? 0 : @heightCommands[params[5]]
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        height = item[:height]
        next height >= minh && height <= maxh
      end
    end
    # Filter by weight range
    if params[6] >= 0 || params[7] >= 0
      minw = (params[6] < 0) ? 0 : (params[6] >= @weightCommands.length) ? 9999 : @weightCommands[params[6]]
      maxw = (params[7] < 0) ? 9999 : (params[7] >= @weightCommands.length) ? 0 : @weightCommands[params[7]]
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        weight = item[:weight]
        next weight >= minw && weight <= maxw
      end
    end
    # Filter by color
    if params[8] >= 0
      scolor = @colorCommands[params[8]].id
      dexlist = dexlist.find_all do |item|
        next $player.seen?(item[:species]) && item[:color] == scolor
      end
    end
    # Filter by shape
    if params[9] >= 0
      sshape = @shapeCommands[params[9]].id
      dexlist = dexlist.find_all do |item|
        next $player.seen?(item[:species]) && item[:shape] == sshape
      end
    end
    # Remove all unseen species from the results
    dexlist = dexlist.find_all { |item| next $player.seen?(item[:species]) }
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL then dexlist.sort! { |a, b| a[:number] <=> b[:number] }
    when MODEATOZ      then dexlist.sort! { |a, b| a[:name] <=> b[:name] }
    when MODEHEAVIEST  then dexlist.sort! { |a, b| b[:weight] <=> a[:weight] }
    when MODELIGHTEST  then dexlist.sort! { |a, b| a[:weight] <=> b[:weight] }
    when MODETALLEST   then dexlist.sort! { |a, b| b[:height] <=> a[:height] }
    when MODESMALLEST  then dexlist.sort! { |a, b| a[:height] <=> b[:height] }
    end
    return dexlist
  end

  def pbCloseSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    oldspecies = @sprites["pokedex"].species
    @searchResults = false
    $PokemonGlobal.pokedexMode = MODENUMERICAL
    @searchParams = [$PokemonGlobal.pokedexMode, -1, -1, -1, -1, -1, -1, -1, -1, -1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    @dexlist.length.times do |i|
      next if @dexlist[i][:species] != oldspecies
      @sprites["pokedex"].index = i
      pbRefresh
      break
    end
    $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbDexEntry(index)
    oldsprites = pbFadeOutAndHide(@sprites)
    region = -1
    if !Settings::USE_CURRENT_REGION_DEX
      dexnames = Settings.pokedex_names
      if dexnames[pbGetSavePositionIndex].is_a?(Array)
        region = dexnames[pbGetSavePositionIndex][1]
      end
    end
    scene = PokemonPokedexInfo_Scene.new
    screen = PokemonPokedexInfoScreen.new(scene)
    ret = screen.pbStartScreen(@dexlist, index, region)
    if @searchResults
      dexlist = pbSearchDexList(@searchParams)
      @dexlist = dexlist
      @sprites["pokedex"].commands = @dexlist
      ret = @dexlist.length - 1 if ret >= @dexlist.length
      ret = 0 if ret < 0
    else
      pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
      $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = ret
    end
    @sprites["pokedex"].index = ret
    @sprites["pokedex"].refresh
    pbRefresh
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbDexSearchCommands(mode, selitems, mainindex)
    cmds = [@orderCommands, @nameCommands, @typeCommands, @heightCommands,
            @weightCommands, @colorCommands, @shapeCommands][mode]
    cols = [2, 7, 4, 1, 1, 3, 5][mode]
    ret = nil
    # Set background
    case mode
    when 0    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_order")
    when 1    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_name")
    when 2
      count = 0
      GameData::Type.each { |t| count += 1 if !t.pseudo_type && t.id != :SHADOW }
      if count == 18
        @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_type_18")
      else
        @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_type")
      end
    when 3, 4 then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_size")
    when 5    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_color")
    when 6    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_shape")
    end
    selindex = selitems.clone
    index     = selindex[0]
    oldindex  = index
    minmax    = 1
    oldminmax = minmax
    index = oldindex = selindex[minmax] if [3, 4].include?(mode)
    @sprites["searchcursor"].mode   = mode
    @sprites["searchcursor"].cmds   = cmds.length
    @sprites["searchcursor"].minmax = minmax
    @sprites["searchcursor"].index  = index
    nextparam = cmds.length % 2
    pbRefreshDexSearchParam(mode, cmds, selindex, index)
    loop do
      pbUpdate
      if index != oldindex || minmax != oldminmax
        @sprites["searchcursor"].minmax = minmax
        @sprites["searchcursor"].index  = index
        
        # ---> ADD THIS LINE <---
        pbRefreshDexSearchParam(mode, cmds, selindex, index)
        
        oldindex  = index
        oldminmax = minmax
      end
      Graphics.update
      Input.update
      if [3, 4].include?(mode)
        if Input.trigger?(Input::UP)
          if index < -1   # From OK/Cancel
            minmax = 0
            index = selindex[minmax]
          elsif minmax == 0
            minmax = 1
            index = selindex[minmax]
          end
          if index != oldindex || minmax != oldminmax
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.trigger?(Input::DOWN)
          case minmax
          when 1
            minmax = 0
            index = selindex[minmax]
          when 0
            minmax = -1
            index = -2
          end
          if index != oldindex || minmax != oldminmax
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.repeat?(Input::LEFT)
          if index == -3
            index = -2
          elsif index >= -1
            if minmax == 1 && index == -1
              index = cmds.length - 1 if selindex[0] < cmds.length - 1
            elsif minmax == 1 && index == 0
              index = cmds.length if selindex[0] < 0
            elsif index > -1 && !(minmax == 1 && index >= cmds.length)
              index -= 1 if minmax == 0 || selindex[0] <= index - 1
            end
          end
          if index != oldindex
            selindex[minmax] = index if minmax >= 0
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.repeat?(Input::RIGHT)
          if index == -2
            index = -3
          elsif index >= -1
            if minmax == 1 && index >= cmds.length
              index = 0
            elsif minmax == 1 && index == cmds.length - 1
              index = -1
            elsif index < cmds.length && !(minmax == 1 && index < 0)
              index += 1 if minmax == 1 || selindex[1] == -1 ||
                            (selindex[1] < cmds.length && selindex[1] >= index + 1)
            end
          end
          if index != oldindex
            selindex[minmax] = index if minmax >= 0
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        end
      else
        if Input.trigger?(Input::UP)
          if index == -1   # From blank
            index = cmds.length - 1 - ((cmds.length - 1) % cols) - 1
          elsif index == -2   # From OK
            index = ((cmds.length - 1) / cols).floor * cols
          elsif index == -3 && mode == 0   # From Cancel
            index = cmds.length - 1
          elsif index == -3   # From Cancel
            index = -1
          elsif index >= cols
            index -= cols
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::DOWN)
          if index == -1   # From blank
            index = -3
          elsif index >= 0
            if index + cols < cmds.length
              index += cols
            elsif (index / cols).floor < ((cmds.length - 1) / cols).floor
              index = (index % cols < cols / 2.0) ? cmds.length - 1 : -1
            else
              index = (index % cols < cols / 2.0) ? -2 : -3
            end
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::LEFT)
          if index == -3
            index = -2
          elsif index == -1
            index = cmds.length - 1
          elsif index > 0 && index % cols != 0
            index -= 1
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::RIGHT)
          if index == -2
            index = -3
          elsif index == cmds.length - 1 && mode != 0
            index = -1
          elsif index >= 0 && index % cols != cols - 1
            index += 1
          end
          pbPlayCursorSE if index != oldindex
        end
      end
      if Input.trigger?(Input::ACTION)
        index = -2
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        ret = nil
        break
      elsif Input.trigger?(Input::USE)
        if index == -2      # OK
          pbSEPlay("GUI pokedex open")
          ret = selindex
          break
        elsif index == -3   # Cancel
          pbPlayCloseMenuSE
          ret = nil
          break
        elsif selindex != index && mode != 3 && mode != 4
          if mode == 2
            if index == -1
              nextparam = (selindex[1] >= 0) ? 1 : 0
            elsif index >= 0
              nextparam = (selindex[0] < 0) ? 0 : (selindex[1] < 0) ? 1 : nextparam
            end
            if index < 0 || selindex[(nextparam + 1) % 2] != index
              pbPlayDecisionSE
              selindex[nextparam] = index
              nextparam = (nextparam + 1) % 2
            end
          else
            pbPlayDecisionSE
            selindex[0] = index
          end
          pbRefreshDexSearchParam(mode, cmds, selindex, index)
        end
      end
    end
    Input.update
    # Set background image
    @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
    @sprites["searchcursor"].mode = -1
    @sprites["searchcursor"].index = mainindex
    return ret
  end

  def pbDexSearch
    # oldsprites = pbFadeOutAndHide(@sprites) # <--- COMMENTED OUT
    @search_open = true # <--- ADDED: Tells the main screen to freeze
    
    params = @searchParams.clone
    @orderCommands = []
    @orderCommands[MODENUMERICAL] = _INTL("Numerical")
    @orderCommands[MODEATOZ]      = _INTL("A to Z")
    @orderCommands[MODEHEAVIEST]  = _INTL("Heaviest")
    @orderCommands[MODELIGHTEST]  = _INTL("Lightest")
    @orderCommands[MODETALLEST]   = _INTL("Tallest")
    @orderCommands[MODESMALLEST]  = _INTL("Smallest")
    @nameCommands = [_INTL("A"), _INTL("B"), _INTL("C"), _INTL("D"), _INTL("E"),
                     _INTL("F"), _INTL("G"), _INTL("H"), _INTL("I"), _INTL("J"),
                     _INTL("K"), _INTL("L"), _INTL("M"), _INTL("N"), _INTL("O"),
                     _INTL("P"), _INTL("Q"), _INTL("R"), _INTL("S"), _INTL("T"),
                     _INTL("U"), _INTL("V"), _INTL("W"), _INTL("X"), _INTL("Y"),
                     _INTL("Z")]
    @typeCommands = []
    GameData::Type.each { |t| @typeCommands.push(t) if !t.pseudo_type }
    @heightCommands = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                       11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                       21, 22, 23, 24, 25, 30, 35, 40, 45, 50,
                       55, 60, 65, 70, 80, 90, 100]
    @weightCommands = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50,
                       55, 60, 70, 80, 90, 100, 110, 120, 140, 160,
                       180, 200, 250, 300, 350, 400, 500, 600, 700, 800,
                       900, 1000, 1250, 1500, 2000, 3000, 5000]
    @colorCommands = []
    GameData::BodyColor.each { |c| @colorCommands.push(c) if c.id != :None }
    @shapeCommands = []
    GameData::BodyShape.each { |s| @shapeCommands.push(s) if s.id != :None }
    @sprites["searchbg"].visible     = true
    @sprites["overlay"].visible      = true
    @sprites["searchcursor"].visible = true
    index = 0
    oldindex = index
    @sprites["searchcursor"].mode    = -1
    @sprites["searchcursor"].index   = index
    pbRefreshDexSearch(params, index)
    
    # pbFadeInAndShow(@sprites) # <--- COMMENTED OUT
    
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if index != oldindex
        @sprites["searchcursor"].index = index
        pbRefreshDexSearch(params, index) # <--- ADD THIS LINE HERE
        oldindex = index
      end
      if Input.trigger?(Input::UP)
        if index >= 7
          index = 4
        elsif index == 5
          index = 0
        elsif index > 0
          index -= 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::DOWN)
        if [4, 6].include?(index)
          index = 8
        elsif index < 7
          index += 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::LEFT)
        if index == 5
          index = 1
        elsif index == 6
          index = 3
        elsif index > 7
          index -= 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::RIGHT)
        if index == 1
          index = 5
        elsif index >= 2 && index <= 4
          index = 6
        elsif [7, 8].include?(index)
          index += 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::ACTION)
        index = 8
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbSEPlay("GUI pokedex open") if index != 9
        case index
        when 0   # Choose sort order
          newparam = pbDexSearchCommands(0, [params[0]], index)
          params[0] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 1   # Filter by name
          newparam = pbDexSearchCommands(1, [params[1]], index)
          params[1] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 2   # Filter by type
          newparam = pbDexSearchCommands(2, [params[2], params[3]], index)
          if newparam
            params[2] = newparam[0]
            params[3] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 3   # Filter by height range
          newparam = pbDexSearchCommands(3, [params[4], params[5]], index)
          if newparam
            params[4] = newparam[0]
            params[5] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 4   # Filter by weight range
          newparam = pbDexSearchCommands(4, [params[6], params[7]], index)
          if newparam
            params[6] = newparam[0]
            params[7] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 5   # Filter by color filter
          newparam = pbDexSearchCommands(5, [params[8]], index)
          params[8] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 6   # Filter by shape
          newparam = pbDexSearchCommands(6, [params[9]], index)
          params[9] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 7   # Clear filters
          10.times do |i|
            params[i] = (i == 0) ? MODENUMERICAL : -1
          end
          pbRefreshDexSearch(params, index)
        when 8   # Start search (filter)
          dexlist = pbSearchDexList(params)
          if dexlist.length == 0
            pbMessage(_INTL("No matching Pokémon were found."))
          else
            @dexlist = dexlist
            @sprites["pokedex"].commands = @dexlist
            @sprites["pokedex"].index    = 0
            @sprites["pokedex"].refresh
            @searchResults = true
            @searchParams = params
            break
          end
        when 9   # Cancel
          pbPlayCloseMenuSE
          break
        end
      end
    end
    
    # pbFadeOutAndHide(@sprites) # <--- COMMENTED OUT
    @sprites["searchbg"].visible     = false # <--- ADDED: Manually hide elements instead
    @sprites["searchcursor"].visible = false # <--- ADDED
    @search_open = false # <--- ADDED: Tells main screen to unfreeze
    
    if @searchResults
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_list")
    end
    pbRefresh
    # pbFadeInAndShow(@sprites, oldsprites) # <--- COMMENTED OUT
    Input.update
    return 0
  end

  def pbPokedex
    scroll_hold_timer = 0
    is_dragging_scrollbar = false
    
    # --- MOBILE LIST DRAG & CLICK VARIABLES ---
    is_dragging_list = false
    drag_start_x = 0
    drag_start_y = 0
    drag_start_index = 0
    drag_sensitivity = 32
    
    # Mathematical boundaries for the scrollbar track
    track_start_y = 128
    track_total_h = 512
    bar_h         = 128
    track_end_y   = track_start_y + track_total_h - bar_h

    pbActivateWindow(@sprites, "pokedex") do
      loop do
        Graphics.update
        Input.update
        
        # ---> ADDED: FREEZE GATE STARTS HERE <---
        if !@search_open
        
          oldindex = @sprites["pokedex"].index
          pbUpdate
          
          if oldindex != @sprites["pokedex"].index
            $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index if !@searchResults
            pbRefresh
            @sprites["pokedex"].refresh rescue nil
          end

          if @sprites["scrollbar_btn"] && !is_dragging_scrollbar
            item_count = @sprites["pokedex"].itemCount
            if item_count > 1
              percent = @sprites["pokedex"].index.to_f / (item_count - 1)
              @sprites["scrollbar_btn"].y = track_start_y + (percent * (track_end_y - track_start_y)).floor
            else
              @sprites["scrollbar_btn"].y = track_start_y
            end
          end
          
          if Input.press?(Input::MOUSELEFT) || Input.press?(1)
            mx, my = Input.mouse_x, Input.mouse_y
            
            if is_dragging_scrollbar || (!is_dragging_list && mx >= 1500 && mx <= 1584 && my >= @sprites["scrollbar_btn"].y && my <= @sprites["scrollbar_btn"].y + 128)
              is_dragging_scrollbar = true
              target_y = my - 64
              target_y = track_start_y if target_y < track_start_y
              target_y = track_end_y   if target_y > track_end_y
              @sprites["scrollbar_btn"].y = target_y
              
              item_count = @sprites["pokedex"].itemCount
              if item_count > 1
                drag_percent = (target_y - track_start_y).to_f / (track_end_y - track_start_y)
                target_index = (drag_percent * (item_count - 1)).round
                
                if @sprites["pokedex"].index != target_index
                  @sprites["pokedex"].index = target_index
                  $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = target_index if !@searchResults
                  pbRefresh
                  @sprites["pokedex"].refresh rescue nil
                  pbPlayCursorSE rescue nil
                end
              end

            elsif mx >= 860 && mx <= 1470 && my >= 86 && my <= 656
              if !is_dragging_list
                is_dragging_list = true
                drag_start_x = mx
                drag_start_y = my
                drag_start_index = @sprites["pokedex"].index
              end
              
              pixel_diff = drag_start_y - my
              if pixel_diff.abs > 5 || (mx - drag_start_x).abs > 5
                index_offset = (pixel_diff / drag_sensitivity).to_i
                target_index = drag_start_index + index_offset
                target_index = 0 if target_index < 0
                max_idx = @sprites["pokedex"].itemCount - 1
                target_index = max_idx if target_index > max_idx
                
                if @sprites["pokedex"].index != target_index
                  @sprites["pokedex"].index = target_index
                  $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = target_index if !@searchResults
                  pbRefresh
                  @sprites["pokedex"].refresh rescue nil
                  pbPlayCursorSE rescue nil
                end
              end

            elsif mx >= 16 && mx <= 112 && my >= 16 && my <= 112
              if @sprites["back_button"] && @sprites["back_button"].bitmap
                btn_w = @sprites["back_button"].bitmap.width
                btn_h = @sprites["back_button"].bitmap.height
                @sprites["back_button"].zoom_x = (btn_w - 16).to_f / btn_w
                @sprites["back_button"].zoom_y = (btn_h - 16).to_f / btn_h
                @sprites["back_button"].x = 16 + 8
                @sprites["back_button"].y = 16 + 8
              end
              
            elsif mx >= 440 && mx <= 536 && my >= 618 && my <= 714
              if @sprites["switch_button"] && @sprites["switch_button"].bitmap
                btn_w = @sprites["switch_button"].bitmap.width
                btn_h = @sprites["switch_button"].bitmap.height
                @sprites["switch_button"].zoom_x = (btn_w - 16).to_f / btn_w
                @sprites["switch_button"].zoom_y = (btn_h - 16).to_f / btn_h
                @sprites["switch_button"].x = 440 + 8
                @sprites["switch_button"].y = 618 + 8
              end

            elsif mx >= 1500 && mx <= 1584 && my >= 64 && my <= 128
              if @sprites["arrow_up"] && @sprites["arrow_up"].bitmap
                btn_w = @sprites["arrow_up"].bitmap.width
                btn_h = @sprites["arrow_up"].bitmap.height
                @sprites["arrow_up"].zoom_x = (btn_w - 16).to_f / btn_w
                @sprites["arrow_up"].zoom_y = (btn_h - 16).to_f / btn_h
                @sprites["arrow_up"].x = 1500 + 8
                @sprites["arrow_up"].y = 64 + 8
              end
              
              if scroll_hold_timer == 0 || (scroll_hold_timer > 12 && scroll_hold_timer % 4 == 0)
                if @sprites["pokedex"].index > 0
                  @sprites["pokedex"].index -= 1
                else
                  @sprites["pokedex"].index = @sprites["pokedex"].itemCount - 1
                end
                $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index if !@searchResults
                pbRefresh
                @sprites["pokedex"].refresh rescue nil
                pbPlayCursorSE rescue nil
              end
              scroll_hold_timer += 1

            elsif mx >= 1500 && mx <= 1584 && my >= 640 && my <= 704
              if @sprites["arrow_down"] && @sprites["arrow_down"].bitmap
                btn_w = @sprites["arrow_down"].bitmap.width
                btn_h = @sprites["arrow_down"].bitmap.height
                @sprites["arrow_down"].zoom_x = (btn_w - 16).to_f / btn_w
                @sprites["arrow_down"].zoom_y = (btn_h - 16).to_f / btn_h
                @sprites["arrow_down"].x = 1500 + 8
                @sprites["arrow_down"].y = 640 + 8
              end
              
              if scroll_hold_timer == 0 || (scroll_hold_timer > 12 && scroll_hold_timer % 4 == 0)
                if @sprites["pokedex"].index < @sprites["pokedex"].itemCount - 1
                  @sprites["pokedex"].index += 1
                else
                  @sprites["pokedex"].index = 0
                end
                $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index if !@searchResults
                pbRefresh
                @sprites["pokedex"].refresh rescue nil
                pbPlayCursorSE rescue nil
              end
              scroll_hold_timer += 1
            end
          else
            if is_dragging_list
              mx, my = Input.mouse_x, Input.mouse_y
              if (my - drag_start_y).abs <= 5 && (mx - drag_start_x).abs <= 5
                if mx >= 860 && mx <= 1470 && my >= 86 && my <= 656
                  clicked_slot = ((my - 86) / 71.25).floor
                  clicked_slot = 7 if clicked_slot > 7
                  
                  top_row = @sprites["pokedex"].instance_variable_get(:@real_top_row) || 0
                  target_index = top_row + clicked_slot
                  
                  max_idx = @sprites["pokedex"].itemCount - 1
                  target_index = max_idx if target_index > max_idx
                  
                  if @sprites["pokedex"].index != target_index
                    @sprites["pokedex"].index = target_index
                    $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = target_index if !@searchResults
                    pbRefresh
                    @sprites["pokedex"].refresh rescue nil
                    pbPlayCursorSE rescue nil
                  else
                    if $player.seen?(@sprites["pokedex"].species)
                      pbSEPlay("GUI pokedex open")
                      pbDexEntry(@sprites["pokedex"].index)
                    end
                  end
                end
              end
            end

            is_dragging_scrollbar = false
            is_dragging_list = false
            scroll_hold_timer = 0
            if @sprites["back_button"]
              @sprites["back_button"].zoom_x, @sprites["back_button"].zoom_y = 1.0, 1.0
              @sprites["back_button"].x, @sprites["back_button"].y = 16, 16
            end
            if @sprites["switch_button"]
              @sprites["switch_button"].zoom_x, @sprites["switch_button"].zoom_y = 1.0, 1.0
              @sprites["switch_button"].x, @sprites["switch_button"].y = 440, 618
            end
            if @sprites["arrow_up"]
              @sprites["arrow_up"].zoom_x, @sprites["arrow_up"].zoom_y = 1.0, 1.0
              @sprites["arrow_up"].x, @sprites["arrow_up"].y = 1500, 64
            end
            if @sprites["arrow_down"]
              @sprites["arrow_down"].zoom_x, @sprites["arrow_down"].zoom_y = 1.0, 1.0
              @sprites["arrow_down"].x, @sprites["arrow_down"].y = 1500, 640
            end
          end

          if Input.trigger?(Input::MOUSELEFT) || Input.trigger?(1)
            mx, my = Input.mouse_x, Input.mouse_y
            
            if mx >= 16 && mx <= 112 && my >= 16 && my <= 112
              pbPlayCloseMenuSE
              if @searchResults
                pbCloseSearch
              else
                break
              end
            elsif mx >= 440 && mx <= 536 && my >= 618 && my <= 714
              pbSEPlay("GUI pokedex open")
              @sprites["pokedex"].active = false
              pbDexSearch
              @sprites["pokedex"].active = true
            end
          end

          if Input.trigger?(Input::ACTION)
            pbSEPlay("GUI pokedex open")
            @sprites["pokedex"].active = false
            pbDexSearch
            @sprites["pokedex"].active = true
          elsif Input.trigger?(Input::BACK)
            pbPlayCloseMenuSE
            if @searchResults
              pbCloseSearch
            else
              break
            end
          elsif Input.trigger?(Input::USE)
            if $player.seen?(@sprites["pokedex"].species)
              pbSEPlay("GUI pokedex open")
              pbDexEntry(@sprites["pokedex"].index)
            end
          end
          
        # ---> ADDED: FREEZE GATE ENDS HERE <---
        else
          # Only update search UI if window is open
          @sprites["searchcursor"].update if @sprites["searchcursor"]
        end
        
      end
    end
  end
  end

#===============================================================================
#
#===============================================================================
class PokemonPokedexScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbPokedex
    @scene.pbEndScene
  end
end
