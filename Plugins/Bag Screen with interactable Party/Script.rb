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
# Creating specific Bag and Party functionalities
#===============================================================================

# Making a minor edit to SpriteWindow_Selectable's update to avoid the
# pbPlayCursorSE to play while you scroll through the items' list
class SpriteWindow_Selectable < SpriteWindow_Base
  attr_reader :index
  attr_writer :ignore_input

  def update
    super
    if self.active && @item_max > 0 && @index >= 0 && !@ignore_input && @bag #BAG
      if Input.repeat?(Input::UP)
        if @index >= @column_max ||
           (Input.trigger?(Input::UP) && (@item_max % @column_max) == 0)
          oldindex = @index
          @index = (@index - @column_max + @item_max) % @item_max
          if @index != oldindex
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::DOWN) #BAG
        if @index < @item_max - @column_max ||
           (Input.trigger?(Input::DOWN) && (@item_max % @column_max) == 0)
          oldindex = @index
          @index = (@index + @column_max) % @item_max
          if @index != oldindex
            update_cursor_rect
          end
        end
      end
    elsif  self.active && @item_max > 0 && @index >= 0 && !@ignore_input
      if Input.repeat?(Input::UP)
        if @index >= @column_max ||
           (Input.trigger?(Input::UP) && (@item_max % @column_max) == 0)
          oldindex = @index
          @index = (@index - @column_max + @item_max) % @item_max
          if @index != oldindex
            pbPlayCursorSE
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::DOWN)
        if @index < @item_max - @column_max ||
           (Input.trigger?(Input::DOWN) && (@item_max % @column_max) == 0)
          oldindex = @index
          @index = (@index + @column_max) % @item_max
          if @index != oldindex
            pbPlayCursorSE
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::LEFT)
        if @column_max >= 2 && @index > 0
          oldindex = @index
          @index -= 1
          if @index != oldindex
            pbPlayCursorSE
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::RIGHT)
        if @column_max >= 2 && @index < @item_max - 1
          oldindex = @index
          @index += 1
          if @index != oldindex
            pbPlayCursorSE
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::JUMPUP)
        if @index > 0
          oldindex = @index
          @index = [self.index - self.page_item_max, 0].max
          if @index != oldindex
            pbPlayCursorSE
            self.top_row -= self.page_row_max
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::JUMPDOWN)
        if @index < @item_max - 1
          oldindex = @index
          @index = [self.index + self.page_item_max, @item_max - 1].min
          if @index != oldindex
            pbPlayCursorSE
            self.top_row += self.page_row_max
            update_cursor_rect
          end
        end
      end
    end
  end
end

class Window_PokemonBag < Window_DrawableCommand
  attr_reader :pocket
  attr_accessor :sorting
  attr_accessor :party1sel
  attr_accessor :party2sel

  def draw_9_patch(bitmap, x, y, width, height, corner_size = 12)
    return if !bitmap || bitmap.disposed?
    
    sw = bitmap.width
    sh = bitmap.height
    c = corner_size 
    
    # 1. Corners 
    self.contents.blt(x, y, bitmap, Rect.new(0, 0, c, c))
    self.contents.blt(x + width - c, y, bitmap, Rect.new(sw - c, 0, c, c))
    self.contents.blt(x, y + height - c, bitmap, Rect.new(0, sh - c, c, c))
    self.contents.blt(x + width - c, y + height - c, bitmap, Rect.new(sw - c, sh - c, c, c))
    
    # 2. Edges 
    self.contents.stretch_blt(Rect.new(x + c, y, width - 2 * c, c), bitmap, Rect.new(c, 0, sw - 2 * c, c))
    self.contents.stretch_blt(Rect.new(x + c, y + height - c, width - 2 * c, c), bitmap, Rect.new(c, sh - c, sw - 2 * c, c))
    self.contents.stretch_blt(Rect.new(x, y + c, c, height - 2 * c), bitmap, Rect.new(0, c, c, sh - 2 * c))
    self.contents.stretch_blt(Rect.new(x + width - c, y + c, c, height - 2 * c), bitmap, Rect.new(sw - c, c, c, sh - 2 * c))
    
    # 3. Center
    self.contents.stretch_blt(Rect.new(x + c, y + c, width - 2 * c, height - 2 * c), bitmap, Rect.new(c, c, sw - 2 * c, sh - 2 * c))
  end

  def initialize(bag, filterlist, pocket, x, y, width, height)
    @bag        = bag
    @filterlist = filterlist
    @pocket     = pocket
    @sorting  = false
    @party1sel = false
    @party2sel = false
    @adapter  = PokemonMartAdapter.new
    @btn_sel = AnimatedBitmap.new("Graphics/Windowskins/button sel")
    @btn_unsel = AnimatedBitmap.new("Graphics/Windowskins/button unsel")
    super(x, y, width, height)
    @row_height = 64
    self.contents.font.size = 32
    
    @selarrow   = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/cursor")
    @swaparrow  = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/cursor_swap")
    @party1arrow = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/cursor_party1")
    @party2arrow = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/cursor_party2")
    self.windowskin = nil
  end

  def dispose
    @swaparrow.dispose
    @party1arrow.dispose
    @party2arrow.dispose
    super
  end

  # Helper to access pockets directly (Bypasses 'rearrange' which causes the crash)
  def bag_pockets
    return @bag.instance_variable_get(:@pockets)
  end

  def pocket=(value)
    @pocket = value
    @item_max = (@filterlist) ? @filterlist[@pocket].length : bag_pockets[@pocket].length
    self.index = @bag.last_viewed_index(@pocket)
  end

  def page_row_max; return 7; end
  def page_item_max; return 7; end
  
  def top_item
    return (@virtualOy / 64).to_i
  end

  def item
    return nil if @filterlist && !@filterlist[@pocket][self.index]
    thispocket = bag_pockets[@pocket]
    item = (@filterlist) ? thispocket[@filterlist[@pocket][self.index]] : thispocket[self.index]
    return (item) ? item[0] : nil
  end

  def itemCount
    return (@filterlist) ? @filterlist[@pocket].length : bag_pockets[@pocket].length
  end

  def itemRect(item)
    if item < 0 || item >= @item_max || item < self.top_item ||
       item > self.top_item + 6 
      return Rect.new(0, 0, 0, 0)
    else
      cursor_width = self.width - self.borderX
      y = (item * 64) - @virtualOy 
      return Rect.new(0, y, cursor_width, 64)
    end
  end
  
  def drawCursor(index, rect)
    if self.index == index
      if @party1sel
        bmp = @party1arrow.bitmap
      elsif @party2sel
        bmp = @party2arrow.bitmap
      elsif @sorting
        bmp = @swaparrow.bitmap
      else
        bmp = @selarrow.bitmap
      end
      pbCopyBitmap(self.contents, bmp, rect.x, rect.y + 22)
    end
  end

  def drawItem(index, _count, rect)
    return if index < 0 || index >= itemCount 
    return if index < self.top_item || index >= self.top_item + 7

    btn_w = rect.width - 10
    btn_h = 58 
    gap_y = (63 - btn_h) / 2
    
    bg_bitmap = (index == self.index) ? @btn_sel : @btn_unsel
    draw_9_patch(bg_bitmap.bitmap, rect.x + 5, rect.y + gap_y, btn_w, btn_h, 12)

    thispocket = bag_pockets[@pocket]
    item = (@filterlist) ? thispocket[@filterlist[@pocket][index]][0] : thispocket[index][0]
    
    icon_path = GameData::Item.icon_filename(item)
    if icon_path
      icon_bmp = AnimatedBitmap.new(icon_path)
      self.contents.stretch_blt(
        Rect.new(rect.x + 16, rect.y + 10, 42, 42), 
        icon_bmp.bitmap, 
        Rect.new(0, 0, icon_bmp.width, icon_bmp.height)
      )
      icon_bmp.dispose 
    end

    textpos = []
    y_text = rect.y + 10
    baseColor   = self.baseColor
    shadowColor = self.shadowColor
    if index == self.index
      baseColor   = Color.new(0, 0, 0)
      shadowColor = Color.new(160, 160, 160, 0)
    end

    textpos.push([@adapter.getDisplayName(item), rect.x + 85, y_text, :left, baseColor, shadowColor])
    
    item_data = GameData::Item.get(item)
    if item_data.show_quantity?
      qty = (@filterlist) ? thispocket[@filterlist[@pocket][index]][1] : thispocket[index][1]
      qtytext = _ISPRINTF("x{1:03d}", qty)
      xQty = rect.width - 40
      textpos.push([qtytext, xQty, y_text, :right, baseColor, shadowColor])
    end

    pbDrawTextPositions(self.contents, textpos)
  end

  def refresh
    # FIXED: Removed 'self.update_cursor_rect' to prevent infinite recursion crash.
    
    @item_max = itemCount
    self.contents = pbDoEnsureBitmap(self.contents, self.width - self.borderX, self.height - self.borderY)
    self.contents.clear
    
    @item_max.times do |i|
      next if i < self.top_item
      next if i >= self.top_item + 7 
      drawItem(i, @item_max, itemRect(i))
    end
  end

  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end


class PokemonBagPartyBlankPanel < Sprite
  attr_accessor :text

  def initialize(_pokemon,index,viewport=nil)
    super(viewport)
    # --- UPDATED: Spaced out X coordinates for wider screen ---
    self.x = 114 + (index % 2) * 268
    self.y = (index / 2) * 110 + 38
    @panelbgsprite = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/ptpanel_blank")
    self.bitmap = @panelbgsprite.bitmap
    @text = nil
  end
  # ... rest of class

  def dispose
    @panelbgsprite.dispose
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

class PokemonBagPartyPanel < Sprite
  attr_reader :pokemon
  attr_reader :active
  attr_reader :selected
  attr_reader :preselected
  attr_reader :switching
  attr_reader :text

def initialize(pokemon, index, viewport=nil)
    super(viewport)
	@text          = nil
    
	return if !pokemon
    @pokemon = pokemon
    @active = (index == 0)
    @refreshing = true
    
    # --- UPDATED: Spaced out X coordinates to match BlankPanel ---
    self.x = 114 + (index % 1) * 268
    self.y = 110 * (index / 1) + 38
    
    @panelbgsprite = ChangelingSprite.new(0, 0, viewport)
    @panelbgsprite.z = self.z
    if @active   # Rounded panel
      @panelbgsprite.addBitmap("able", "Graphics/UI/Bag Screen with Party/ptpanel_round_desel")
      @panelbgsprite.addBitmap("ablesel", "Graphics/UI/Bag Screen with Party/ptpanel_round_sel")
      @panelbgsprite.addBitmap("fainted", "Graphics/UI/Bag Screen with Party/ptpanel_round_faint")
      @panelbgsprite.addBitmap("faintedsel", "Graphics/UI/Bag Screen with Party/ptpanel_round_faint_sel")
      @panelbgsprite.addBitmap("swap", "Graphics/UI/Bag Screen with Party/ptpanel_round_move")
      @panelbgsprite.addBitmap("swapsel", "Graphics/UI/Bag Screen with Party/ptpanel_round_move_sel")
      @panelbgsprite.addBitmap("swapsel2", "Graphics/UI/Bag Screen with Party/ptpanel_round_move_sel")
    else   # Rectangular panel
      @panelbgsprite.addBitmap("able", "Graphics/UI/Bag Screen with Party/ptpanel_rect_desel")
      @panelbgsprite.addBitmap("ablesel", "Graphics/UI/Bag Screen with Party/ptpanel_rect_sel")
      @panelbgsprite.addBitmap("fainted", "Graphics/UI/Bag Screen with Party/ptpanel_rect_faint")
      @panelbgsprite.addBitmap("faintedsel", "Graphics/UI/Bag Screen with Party/ptpanel_rect_faint_sel")
      @panelbgsprite.addBitmap("swap", "Graphics/UI/Bag Screen with Party/ptpanel_rect_move")
      @panelbgsprite.addBitmap("swapsel", "Graphics/UI/Bag Screen with Party/ptpanel_rect_move_sel")
      @panelbgsprite.addBitmap("swapsel2", "Graphics/UI/Bag Screen with Party/ptpanel_rect_move_sel")
    end

    @pkmnsprite = PokemonIconSprite.new(pokemon, viewport)
    @pkmnsprite.setOffset(PictureOrigin::CENTER)
    @pkmnsprite.active = @active
    @pkmnsprite.z      = self.z + 1
    @hpbgsprite = ChangelingSprite.new(0, 0, viewport)
    @hpbgsprite.z = self.z + 2
    @hpbgsprite.addBitmap("able", "Graphics/UI/Bag Screen with Party/overlay_hp_back")
    @hpbgsprite.addBitmap("cursor", "Graphics/UI/Bag Screen with Party/overlay_hp_back")
    @helditemsprite = HeldItemIconSprite.new(0, 0, @pokemon, viewport)
    @helditemsprite.z = self.z + 3
    @overlaysprite = BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    @overlaysprite.z = self.z + 20
    @hpbar    = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/overlay_hp")
    @statuses = AnimatedBitmap.new(_INTL("Graphics/UI/statuses"))
    @pokerus  = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/icon_pokerus") if BagScreenWiInParty::PKRSICON == true
    @selected      = false
    @preselected   = false
    @switching     = false
    @text          = nil
    #@refreshBitmap = true
    #@refreshing    = false
	@last_hp = @pokemon.hp
    @last_status = @pokemon.status
    @last_level = @pokemon.level
    @refreshBitmap = true
    @refreshing = false
    refresh
  end

  def dispose
    @panelbgsprite.dispose
    @hpbgsprite.dispose
    @pkmnsprite.dispose
    @helditemsprite.dispose
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
    if @text != value
      @text = value
      @refreshBitmap = true
      refresh
    end
  end

  def pokemon=(value)
    @pokemon = value
    @pkmnsprite.pokemon = value if @pkmnsprite && !@pkmnsprite.disposed?
    @helditemsprite.pokemon = value if @helditemsprite && !@helditemsprite.disposed?
    @refreshBitmap = true
    refresh
  end

  def selected=(value)
    if @selected != value
      @selected = value
      refresh
    end
  end

  def preselected=(value)
    if @preselected != value
      @preselected = value
      refresh
    end
  end

  def switching=(value)
    if @switching != value
      @switching = value
      refresh
    end
  end

  def hp; return @pokemon.hp; end

  def refresh
    return if disposed?
    return if @refreshing
    @refreshing = true
    if @panelbgsprite && !@panelbgsprite.disposed?
      if self.selected
        if self.preselected;     @panelbgsprite.changeBitmap("swapsel2")
        elsif @switching;        @panelbgsprite.changeBitmap("swapsel")
        elsif @pokemon.fainted?; @panelbgsprite.changeBitmap("faintedsel")
        else;                    @panelbgsprite.changeBitmap("ablesel")
        end
      else
        if self.preselected;     @panelbgsprite.changeBitmap("swap")
        elsif @pokemon.fainted?; @panelbgsprite.changeBitmap("fainted")
        else;                    @panelbgsprite.changeBitmap("able")
        end
      end
      @panelbgsprite.x     = self.x
      @panelbgsprite.y     = self.y
      @panelbgsprite.color = self.color
    end
    if @hpbgsprite && !@hpbgsprite.disposed?
      @hpbgsprite.visible = !@pokemon.egg?
      if @hpbgsprite.visible
        if self.preselected || (self.selected); @hpbgsprite.changeBitmap("cursor")
        else;                                   @hpbgsprite.changeBitmap("able")
        end
        @hpbgsprite.x     = self.x + 110
        @hpbgsprite.y     = self.y + 46
        @hpbgsprite.color = self.color
      end
    end
    if @pkmnsprite && !@pkmnsprite.disposed?
      @pkmnsprite.setOffset(PictureOrigin::CENTER)
      @pkmnsprite.x        = self.x + 54
      @pkmnsprite.y        = self.y + 47
      @pkmnsprite.color    = self.color
      @pkmnsprite.selected = self.selected
    end
    if @helditemsprite&.visible && !@helditemsprite.disposed?
      @helditemsprite.x     = self.x + 62
      @helditemsprite.y     = self.y + 39
      @helditemsprite.color = self.color
    end
    if @overlaysprite && !@overlaysprite.disposed?
      @overlaysprite.x     = self.x + 16
      @overlaysprite.y     = self.y
      @overlaysprite.color = self.color
    end
    if @refreshBitmap
      @refreshBitmap = false
      @overlaysprite.bitmap.clear if @overlaysprite.bitmap
      baseColor   = Color.new(0, 0, 0)
      outlineColor = Color.new(0, 0, 0, 0)
      
      # Default size for standard text (like Name)
      @overlaysprite.bitmap.font.size = 32
      @overlaysprite.bitmap.font.color = baseColor
      pbSetSystemFont(@overlaysprite.bitmap)

      textpos = []
      if !@pokemon.egg?
        if !@text || @text.length == 0
          # Draw HP numbers (Size 28)
          @overlaysprite.bitmap.font.size = 28
          textpos.push([sprintf("% 3d /% 3d", @pokemon.hp, @pokemon.totalhp), 90, 58, 0, baseColor, Color.new(40, 40, 40, 0), true, Graphics.width]) if !@text || @text.length == 0
        end
        
        # Draw HP bar
        if @pokemon.hp > 0
          w = @pokemon.hp * 246 / @pokemon.totalhp.to_f
          w = 1 if w < 1
          w = ((w / 2).round) * 2
          hpzone = 0
          hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
          hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
          hprect = Rect.new(0, hpzone * 8, w, 8)
          @overlaysprite.bitmap.blt(94, 46, @hpbar.bitmap, hprect)
        end

        # Draw gender symbol
        if @pokemon.male?
          textpos.push([_INTL("♂"), 356, 12, 0, Color.new(116, 162, 237), outlineColor, true, Graphics.width])
        elsif @pokemon.female?
          textpos.push([_INTL("♀"), 356, 12, 0, Color.new(237, 116, 140), outlineColor, true, Graphics.width])
        end

        pbDrawTextPositions(@overlaysprite.bitmap, textpos)
        
        # Draw level text (Size 28)
        if !@pokemon.egg?
          @overlaysprite.bitmap.font.size = 28
          pbDrawTextPositions(@overlaysprite.bitmap,
                              [[_INTL("Lv. {1}", @pokemon.level), 370, 58, 0, baseColor, Color.new(40, 40, 40, 0), true, Graphics.width]])
        end
    
        # Draw status
        status = -1
        if @pokemon.fainted?
          status = GameData::Status.count - 1
        elsif @pokemon.status != :NONE
          status = GameData::Status.get(@pokemon.status).icon_position
        end
        if status >= 0
          statusrect = Rect.new(0, 40 * status, 100, 40)
          @overlaysprite.bitmap.blt(344, 42, @statuses.bitmap, statusrect)
        end
        
        # Draw Pokerus icon
        if BagScreenWiInParty::PKRSICON == true
          if @pokemon.pokerusStage == 1
            @overlaysprite.bitmap.blt(64, 44, @pokerus.bitmap, Rect.new(0, 0, 0, 0))
          elsif @pokemon.pokerusStage == 2
            @overlaysprite.bitmap.blt(64, 44, @pokerus.bitmap, Rect.new(0, 0, 0, 0))
          end
        end

        # Draw shiny icon
        if @pokemon.shiny? && BagScreenWiInParty::SHINYICON == true
          pbDrawImagePositions(@overlaysprite.bitmap,
                               [["Graphics/UI/Bag Screen with Party/shiny", 84, 44, 0, 0, 0, 0]])
        end
      end

      # --- ANNOTATION TEXT (Learned/Able/Unable) ---
      if @text && @text.length > 0
        # 1. Set System Font FIRST to load the font face
        pbSetSystemFont(@overlaysprite.bitmap)
        
        # 2. Set Size to 28 AFTER (so it doesn't get reset)
        @overlaysprite.bitmap.font.size = 28 
        
        pbDrawTextPositions(@overlaysprite.bitmap,
                            [[@text, 96, 58, :left, baseColor, Color.new(40, 40, 40, 0), true, Graphics.width]])
      end
    end
    @refreshing = false
  end

  def update
    super
    return if !@pokemon # Safety check
    if @last_hp != @pokemon.hp || @last_status != @pokemon.status || @last_level != @pokemon.level
      @last_hp = @pokemon.hp
      @last_status = @pokemon.status
      @last_level = @pokemon.level
      @refreshBitmap = true
      refresh
    end
    @panelbgsprite.update if @panelbgsprite && !@panelbgsprite.disposed?
    @hpbgsprite.update if @hpbgsprite && !@hpbgsprite.disposed?
    @pkmnsprite.update if @pkmnsprite && !@pkmnsprite.disposed?
    @helditemsprite.update if @helditemsprite && !@helditemsprite.disposed?
  end
end

#===============================================================================
# Bag visuals
#===============================================================================
class PokemonBag_Scene
  ITEMLISTBASECOLOR      = Color.new(0, 0, 0)
  ITEMLISTSHADOWCOLOR    = Color.new(157, 157, 167, 0)
  ITEMTEXTBASECOLOR      = Color.new(0, 0, 0)
  ITEMTEXTSHADOWCOLOR    = ITEMLISTSHADOWCOLOR
  POCKETNAMEBASECOLOR    = Color.new(0, 0, 0)
  POCKETNAMEOUTLINECOLOR = Color.new(78, 83, 100, 0)
  ITEMSVISIBLE           = 7



  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    if @sprites["uparrow"] && @sprites["downarrow"]
      bob = (Graphics.frame_count % 30 < 15) ? 4 : 0
      @sprites["uparrow"].oy = bob
      @sprites["downarrow"].oy = -bob
    end
    if @sprites["cursor"]
      @cursor_timer += 1
      # Fast bobbing math
      cursor_offset = Math.sin(@cursor_timer * 0.2) * 8
      
      # CASE 1: Selecting Items
      if @sprites["itemlist"].active
        idx = @sprites["itemlist"].index
        rect = @sprites["itemlist"].itemRect(idx)
        
        if rect.height == 0
          @sprites["cursor"].visible = false
        else
          @sprites["cursor"].visible = true
          @sprites["cursor"].x = @sprites["itemlist"].x + rect.x - 10 + cursor_offset
          @sprites["cursor"].y = @sprites["itemlist"].y + rect.y + 46
        end

      # CASE 2: Selecting Pokemon Party
      else
        # Find which pokemon index is currently 'selected'
        selected_idx = -1
        for i in 0...6
          if @sprites["pokemon#{i}"].is_a?(PokemonBagPartyPanel) && @sprites["pokemon#{i}"].selected
            selected_idx = i
            break
          end
        end

        if selected_idx == -1
          @sprites["cursor"].visible = false
        else
          target_panel = @sprites["pokemon#{selected_idx}"]
          @sprites["cursor"].visible = true
          # Position the arrow to the left of the panel
          @sprites["cursor"].x = target_panel.x - 25 + cursor_offset
          # Center it vertically on the panel (half of the 110px panel height)
          @sprites["cursor"].y = target_panel.y + 45 
        end
      end
      
      # Ensure center handle
      @sprites["cursor"].ox = 0
      @sprites["cursor"].oy = @sprites["cursor"].bitmap.height / 2
    end
  end

  def pbStartScene(bag, party, choosing = false, filterproc = nil, resetpocket = true)
    @viewport   = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @bag        = bag
    @choosing   = choosing
    @filterproc = filterproc
    @party      = party
    
    pbRefreshFilter
    lastpocket = @bag.last_viewed_pocket
    numfilledpockets = @bag.pockets.length - 1
    if @choosing
      numfilledpockets = 0
      if @filterlist.nil?
        (1...@bag.pockets.length).each do |i|
          numfilledpockets += 1 if @bag.pockets[i].length > 0
        end
      else
        (1...@bag.pockets.length).each do |i|
          numfilledpockets += 1 if @filterlist[i].length > 0
        end
      end
      lastpocket = (resetpocket) ? 1 : @bag.last_viewed_pocket
      if (@filterlist && @filterlist[lastpocket].length == 0) ||
         (!@filterlist && @bag.pockets[lastpocket].length == 0)
        (1...@bag.pockets.length).each do |i|
          if @filterlist && @filterlist[i].length > 0
            lastpocket = i
            break
          elsif !@filterlist && @bag.pockets[i].length > 0
            lastpocket = i
            break
          end
        end
      end
    end
    @bag.last_viewed_pocket = lastpocket
    
    @sliderbitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Bag Screen with Party/icon_slider"))
    @pocketbitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Bag Screen with Party/icon_pocket"))
    
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap("Graphics/UI/Bag Screen with Party/bg")
    @sprites["gradient"] = IconSprite.new(0, 0, @viewport)
    @sprites["gradient"].setBitmap("Graphics/UI/Bag Screen with Party/grad")
    @sprites["panorama"] = IconSprite.new(0, 0, @viewport)
    @sprites["panorama"].setBitmap("Graphics/UI/Bag Screen with Party/panorama")
    
    if BagScreenWiInParty::BGSTYLE == 1 # BW Style
      if $player.female?
        @sprites["background"].color = Color.new(231, 101, 137)
        @sprites["gradient"].color = Color.new(243, 133, 169)
        @sprites["panorama"].color = Color.new(232, 62, 113)
      else
        @sprites["background"].color = Color.new(101, 230, 255)
        @sprites["gradient"].color = Color.new(37, 129, 255)
        @sprites["panorama"].color = Color.new(37, 136, 255)
      end
    elsif BagScreenWiInParty::BGSTYLE == 2 # HGSS Style
      pbPocketColor
    end
    @sprites["ui1"] = IconSprite.new(0, 0, @viewport)
    @sprites["ui1"].setBitmap("Graphics/UI/Bag Screen with Party/ui1")
    @sprites["ui2"] = IconSprite.new(0, 0, @viewport)
    @sprites["ui2"].setBitmap("Graphics/UI/Bag Screen with Party/ui2")
	
# --- ADDED: Back and Sort Buttons ---
    @sprites["btn_back"] = IconSprite.new(16, 16, @viewport)
    @sprites["btn_back"].setBitmap("Graphics/UI/back")
    @sprites["btn_back"].z = 250

    # Base Switch Button
    @sprites["btn_sort"] = IconSprite.new(16, 112, @viewport)
    @sprites["btn_sort"].setBitmap("Graphics/UI/switch")
    @sprites["btn_sort"].z = 250

    # Selected Switch Button (Overlay)
    @sprites["btn_sort_sel"] = IconSprite.new(16, 112, @viewport)
    @sprites["btn_sort_sel"].setBitmap("Graphics/UI/switch_sel")
    @sprites["btn_sort_sel"].z = 251 # Slightly higher Z to be on top
    @sprites["btn_sort_sel"].visible = false # Hidden until clicked
    # ------------------------------------
	
	# --- Create Scroll Indicators ---
    @sprites["uparrow"] = Sprite.new(@viewport)
    @sprites["uparrow"].bitmap = RPG::Cache.load_bitmap("Graphics/UI/", "uparrow")
    @sprites["uparrow"].x = 1060  # Adjust X position
    @sprites["uparrow"].y = 56  # Adjust Y position
    @sprites["uparrow"].z = 250
    @sprites["uparrow"].visible = false

    @sprites["downarrow"] = Sprite.new(@viewport)
    @sprites["downarrow"].bitmap = RPG::Cache.load_bitmap("Graphics/UI/", "downarrow")
    @sprites["downarrow"].x = 1060 # Adjust X position
    @sprites["downarrow"].y = 520 # Adjust Y position
    @sprites["downarrow"].z = 250
    @sprites["downarrow"].visible = false
	
	@sprites["cursor"] = Sprite.new(@viewport)
    @sprites["cursor"].bitmap = pbBitmap("Graphics/UI/sel_arrow")
    @sprites["cursor"].z = 999999 # Ensure it is on top
    @cursor_timer = 0
	
    
    for i in 0...Settings::MAX_PARTY_SIZE
      if @party[i] && @party[i].is_a?(Pokemon) # Check if it's a valid Pokemon object
        @sprites["pokemon#{i}"] = PokemonBagPartyPanel.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PokemonBagPartyBlankPanel.new(nil, i, @viewport)
      end
    end
    
@sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
@sprites["overlay"].z = 999999
    pbSetSystemFont(@sprites["overlay"].bitmap)
    rbvar = 0
    
    # --- CHANGED: Adjusted X coordinates for Wide Screen (854px) ---
    # Original X was 372. 512 - 372 = 140 (Right margin).
    # New X = Graphics.width - 140
    icon_x = Graphics.width - 140
    
    @sprites["pocketicon"] = BitmapSprite.new(130, 52, @viewport)
    @sprites["pocketicon"].x = icon_x
    @sprites["pocketicon"].y = 0
    @sprites["currentpocket"] = IconSprite.new(0, 0, @viewport)
    @sprites["currentpocket"].setBitmap("Graphics/UI/Bag Screen with Party/icon_pocket")
    @sprites["currentpocket"].x = icon_x
    @sprites["currentpocket"].y = 26
    @sprites["currentpocket"].src_rect = Rect.new(0, 0, 28, 28)
    
    # --- CHANGED: Adjusted Item List Window ---
    # Party takes up roughly 230px on the left.
    # We start the list at x = 240 to give a small gap.
    # Width is calculated to fill the rest of the screen minus a margin.
    list_x = 664      # 664 pixels from left
    list_y = 82       # 82 pixels from top
	list_width = 840  # 840 pixels wide
    list_height = 484
    
    @sprites["itemlist"] = Window_PokemonBag.new(@bag, @filterlist, lastpocket, list_x, list_y, list_width, list_height)
    @sprites["itemlist"].viewport    = @viewport
    @sprites["itemlist"].pocket      = lastpocket
    @sprites["itemlist"].index       = @bag.last_viewed_index(lastpocket)
    @sprites["itemlist"].baseColor   = ITEMLISTBASECOLOR
    @sprites["itemlist"].shadowColor = ITEMLISTSHADOWCOLOR
    
	idx = @sprites["itemlist"].index
    rect = @sprites["itemlist"].itemRect(idx)
    @sprites["cursor"].x = @sprites["itemlist"].x + rect.x - 10
    @sprites["cursor"].y = @sprites["itemlist"].y + rect.y + 46
    @sprites["cursor"].oy = @sprites["cursor"].bitmap.height / 2
    @sprites["cursor"].visible = true
	
    @sprites["itemicon"] = ItemIconSprite.new(298, Graphics.height - 46, nil, @viewport)
    @sprites["itemicon"].visible = false
    # Item text automatically uses Graphics.width, so this stays mostly the same,
    # but we ensure the width calculation uses the dynamic Graphics.width
    @sprites["itemtext"] = Window_UnformattedTextPokemon.newWithSize("", 680, 576, 884 , 1022, @viewport)
    @sprites["itemtext"].baseColor   = ITEMTEXTBASECOLOR
    @sprites["itemtext"].shadowColor = ITEMTEXTSHADOWCOLOR
    @sprites["itemtext"].visible     = true
    @sprites["itemtext"].windowskin  = nil
	@sprites["itemtext"].contents.font.size = 32
	
	#@sprites["itemregister"] = Sprite.new(@viewport)
    #@sprites["itemregister"].z = 350 # Ensure it's above the item bar
    #@sprites["itemregister"].visible = false
	
    @sprites["helpwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["helpwindow"].viewport = @viewport
	@sprites["helpwindow"].visible  = false
	@sprites["helpwindow"].windowskin = Bitmap.new("Graphics/Windowskins/choice 2wss")
    pbBottomLeftLines(@sprites["helpwindow"], 2)
	
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible  = false
    @sprites["msgwindow"].viewport = @viewport
    @sprites["msgwindow"].letterbyletter = true
	@sprites["msgwindow"].windowskin = Bitmap.new("Graphics/Windowskins/choice 15") #this one for items text box
    pbBottomLeftLines(@sprites["msgwindow"], 2)	
	
    pbUpdateAnnotation
    
    pbDeactivateWindows(@sprites)
    pbRefresh
    pbFadeInAndShow(@sprites)
  end

def pbUpdateDescription
    item_window = @sprites["itemlist"]
    
    # --- CHANGED: Check for empty pocket first ---
    if @bag.pockets[item_window.pocket].empty?
      description = _INTL("No items.")
    else
      item = item_window.item
      return if !item
      item_data = GameData::Item.try_get(item)
      description = (item_data) ? item_data.description : ""
    end
    # ---------------------------------------------
    
    # Clean up: Replace manual newlines with spaces to ensure smooth wrapping
    description = description.gsub("\n", " ")

    contents = @sprites["itemtext"].contents
    contents.clear
    
    # 1. SETUP FONT
    # Set System Font first to load the font face, then apply size 32
    pbSetSystemFont(contents)
    contents.font.size = 32
    
    # 2. SAFER WIDTH CALCULATION
    # Reduced max_width to 760 (was ~800).
    max_width = 760  
    
    words = description.split(" ")
    lines = []
    current_line = ""
    
    words.each do |word|
      # Test if adding the next word fits within the safety margin
      test_string = current_line + (current_line.empty? ? "" : " ") + word
      
      if contents.text_size(test_string).width <= max_width
        current_line = test_string
      else
        # If it doesn't fit, push current line and start a new one
        lines.push(current_line)
        current_line = word
      end
    end
    # Push the final line
    lines.push(current_line) if !current_line.empty?

    # 3. DRAW TEXT
    base = Color.new(0, 0, 0)
    shadow = Color.new(0, 0, 0, 0)
    line_height = 48 
    
    textpos = []
    
    # Draw each calculated line
    lines.each_with_index do |line, i|
      # x=0, y = index * 48
      textpos.push([line, 0, i * line_height, 0, base, shadow])
    end
    
    pbDrawTextPositions(contents, textpos)
  end

def pbUpdateScrollArrows
    return if !@sprites["uparrow"] || !@sprites["downarrow"]
    
    itemwindow = @sprites["itemlist"]
    num_items = itemwindow.itemCount
    
    # Check if we should even show them
    if num_items <= 7
      @sprites["uparrow"].visible = false
      @sprites["downarrow"].visible = false
      return
    end

    # Use the window's internal scroll position (top_item)
    @sprites["uparrow"].visible = (itemwindow.top_item > 0)
    @sprites["downarrow"].visible = (itemwindow.top_item + 7 < num_items)
  end

#def pbUpdateRegisterIcon
 #   return if !@sprites["itemregister"]
  #  item_window = @sprites["itemlist"]
   # item = item_window.item
    
    # 1. Hide if no item
    #if !item || item == 0
     # @sprites["itemregister"].visible = false
      #return
    #end

    # 2. Registration Data Check
   # bag_obj = $bag || $PokemonBag || ($player ? $player.bag : nil)
    #is_registered = bag_obj&.respond_to?(:pbIsRegistered?) ? bag_obj.pbIsRegistered?(item) : false

    # 3. Handle the Graphic (56x24 per state)
    #@sprites["itemregister"].bitmap = RPG::Cache.load_bitmap("Graphics/UI/Bag Screen with Party/", "icon_register")
    
    # We force the height to 24. 
    # Top half (Registered) = 0. Bottom half (Unregistered) = 24.
   # y_offset = is_registered ? 0 : 24
    #@sprites["itemregister"].src_rect.set(0, y_offset, 56, 24)

    # 4. ALIGNMENT (The "x001" style logic)
    # X: We take the right edge of the window and pull back 70 pixels 
    # (Adjust -70 to move it closer or further from the edge)
    #@sprites["itemregister"].x = item_window.x + item_window.width - 110
    
    # Y: We find the exact vertical center of the currently selected row
    # item_window.index % 7 gives the row (0-6)
    # 54 is the standard row height; 15 is the vertical nudge to center it
   # row_height = 54 
   # @sprites["itemregister"].y = item_window.y + (item_window.index % 7 * row_height) + 15
    
    # 5. Visibility: Only show for items that CAN be registered
   # is_key_item = GameData::Item.get(item).is_important?
  #  @sprites["itemregister"].visible = is_key_item
 # end

  def pbPocketColor
    case @bag.last_viewed_pocket
    when 1
      @sprites["background"].color = Color.new(233, 152, 189)
      @sprites["gradient"].color = Color.new(255, 37, 187)
      @sprites["panorama"].color = Color.new(213, 89, 141)
    when 2
      @sprites["background"].color = Color.new(233, 161, 152)
      @sprites["gradient"].color = Color.new(255, 134, 37)
      @sprites["panorama"].color = Color.new(224, 112, 56)
    when 3
      @sprites["background"].color = Color.new(233, 197, 152)
      @sprites["gradient"].color = Color.new(255, 177, 37)
      @sprites["panorama"].color = Color.new(200, 136, 32)
    when 4
      @sprites["background"].color = Color.new(216, 233, 152)
      @sprites["gradient"].color = Color.new(194, 255, 37)
      @sprites["panorama"].color = Color.new(128, 168, 32)
    when 5
      @sprites["background"].color = Color.new(175, 233, 152)
      @sprites["gradient"].color = Color.new(78, 255, 37)
      @sprites["panorama"].color = Color.new(32, 160, 72)
    when 6
      @sprites["background"].color = Color.new(152, 220, 233)
      @sprites["gradient"].color = Color.new(37, 212, 255)
      @sprites["panorama"].color = Color.new(24, 144, 176)
    when 7
      @sprites["background"].color = Color.new(152, 187, 233)
      @sprites["gradient"].color = Color.new(37, 125, 255)
      @sprites["panorama"].color = Color.new(48, 112, 224)
    when 8
      @sprites["background"].color = Color.new(178, 152, 233)
      @sprites["gradient"].color = Color.new(145, 37, 255)
      @sprites["panorama"].color = Color.new(144, 72, 216)
    end
  end
  
  def pbFadeOutScene
    @oldsprites = pbFadeOutAndHide(@sprites)
    @oldtext = []
    for i in 0...Settings::MAX_PARTY_SIZE
      @oldtext.push(@sprites["pokemon#{i}"].text)
      @sprites["pokemon#{i}"].dispose
    end
  end
  
  def pbFadeInScene
    for i in 0...Settings::MAX_PARTY_SIZE
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonBagPartyPanel.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PokemonBagPartyBlankPanel.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = @oldtext[i]
    end
    @oldtext = nil
    pbFadeInAndShow(@sprites, @oldsprites)
    @oldsprites = nil
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) if !@oldsprites
    @oldsprites = nil
    dispose
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @sliderbitmap.dispose
    @pocketbitmap.dispose
    #@viewport.dispose
  end


  #=============================================================================
  # SIMPLER TEXTBOX (Uses standard System Window)
  #=============================================================================
  def pbDisplay(message)
    # Set the style to System (usually transparent or standard window)
    $msg_style = :system
    
    # Use the game's built-in message function
    pbMessage(message)
    
    # Reset style
    $msg_style = nil
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end
  
  #=============================================================================
  # CUSTOM TEXTBOX: pbConfirm (Fixed Skipping)
  #=============================================================================
  def pbConfirm(message)
    return pbConfirmMessage(message)
  end

  def pbChooseNumber(msg, maximum, initnum = 1)
    return UIHelper.pbChooseNumber(@sprites["helpwindow"], msg, maximum, initnum) { pbUpdate }
  end

  def pbShowCommands(helptext, commands, index = 0)
    return UIHelper.pbShowCommands(@sprites["helpwindow"], helptext, commands, index) { pbUpdate }
  end

  def pbRefresh
    for i in 0...Settings::MAX_PARTY_SIZE
        @sprites["pokemon#{i}"].refresh if @sprites["pokemon#{i}"].is_a?(PokemonBagPartyPanel)
    end
    # Hide description icon
    @sprites["itemicon"].visible = false if @sprites["itemicon"]

    # Draw the pocket icons
    pocketX  = []; incrementX = 0 # Fixes pockets' X coordinates
    @bag.pockets.length.times do |i|
      break if pocketX.length == @bag.pockets.length
      pocketX.push(incrementX)
      incrementX += 2 if i.odd?
    end
    pocketAcc = @sprites["itemlist"].pocket - 1 # Current pocket
    @sprites["pocketicon"].bitmap.clear
    (1...@bag.pockets.length).each do |i|
      pocketValue = i - 1
      @sprites["pocketicon"].bitmap.blt(
        (i - 1) * 14 + pocketX[pocketValue], (i % 2) * 26, @pocketbitmap.bitmap,
        Rect.new((i - 1) * 28, 0, 28, 28)) if pocketValue != pocketAcc # Unblocked icons
    end
    if @choosing && @filterlist
      (1...@bag.pockets.length).each do |i|
        next if @filterlist[i].length > 0
        pocketValue = i - 1
        @sprites["pocketicon"].bitmap.blt(
          (i - 1) * 14 + pocketX[pocketValue], (i % 2) * 26, @pocketbitmap.bitmap,
          Rect.new((i - 1) * 28, 56, 28, 28)) # Blocked icons
      end
    end
    icon_base_x = Graphics.width - 140
    @sprites["currentpocket"].x = icon_base_x + ((pocketAcc) * 14) + pocketX[pocketAcc]
    @sprites["currentpocket"].y = 26 - (((pocketAcc) % 2) * 26)
    @sprites["currentpocket"].src_rect = Rect.new((pocketAcc) * 28, 28, 28, 28) # Current pocket icon

    # --- ERROR FIX: REMOVED FAULTY BLOCK ---
    # We removed the code block that tried to call .name on @bag.pockets.
    # The correct pocket name is already drawn inside pbRefreshIndexChanged below.

    # Refresh stuff
    @sprites["itemlist"].refresh
    pbRefreshIndexChanged
    pbRefreshParty
    pbPocketColor if BagScreenWiInParty::BGSTYLE == 2
  end
  
  def pbRefreshParty
    return if !@sprites["overlay"]
    overlay = @sprites["overlay"].bitmap
    
    # 1. Configure Font: Size 32 and Pure Black
    overlay.font.size   = 32
    overlay.font.color  = Color.new(0, 0, 0) # Black

    @party.length.times do |i|
      pokemon = @party[i]
      next if !pokemon
      
      # 2. POSITIONING PER PANEL
      # x_pos: Horizontal distance from left
      # y_start: Vertical start of the first name
      # y_gap: Vertical space between panels
      x_pos   = 182 + 42  
      y_start = 26 + 22  
      y_gap   = 110 
      
      current_y = y_start + (i * y_gap)
      
      # 3. DRAW FLAT TEXT
      # Using draw_text ensures no shadow is rendered
      # (x, y, width, height, text)
      overlay.draw_text(x_pos, current_y, 200, 40, pokemon.name)
    end
  end
  
def pbRefreshIndexChanged
    itemlist = @sprites["itemlist"]
    overlay = @sprites["overlay"].bitmap
	pbUpdateDescription
	pbUpdateScrollArrows
	#pbUpdateRegisterIcon
    overlay.clear

    
    # --- CHANGED: Dynamic Positioning ---
    # Calculate center of the item list for text and arrows
    center_x = itemlist.x + (itemlist.width / 2)
    # Calculate right edge for the scroll bar
    scroll_x = Graphics.width - 28
    
    # Draw the pocket name (Centered over the list)
    pbDrawTextPositions(
      overlay,
      [[PokemonBag.pocket_names[@bag.last_viewed_pocket - 1], center_x, 22, :center, POCKETNAMEBASECOLOR, POCKETNAMEOUTLINECOLOR, true, Graphics.width]]
    )
    
    # Draw slider arrows (Centered over the list)
    # The arrow bitmap is 36px wide, so we subtract 18 to center it
    arrow_x = center_x - 18 
    
    showslider = false
    if itemlist.top_row > 0
      overlay.blt(arrow_x, 16, @sliderbitmap.bitmap, Rect.new(0, 0, 36, 38))
      showslider = true
    end
    if itemlist.top_item + itemlist.page_item_max < itemlist.itemCount
      overlay.blt(arrow_x, 228, @sliderbitmap.bitmap, Rect.new(0, 38, 36, 38))
      showslider = true
    end
    
    # Draw slider box (Aligned to the far right)
    if showslider
      sliderheight = 174
      boxheight = (sliderheight * itemlist.page_row_max / itemlist.row_max).floor
      boxheight += [(sliderheight - boxheight) / 2, sliderheight / 6].min
      boxheight = [boxheight.floor, 38].max
      y = 80
      y += ((sliderheight - boxheight) * itemlist.top_row / (itemlist.row_max - itemlist.page_row_max)).floor
      
      # Use scroll_x calculated above
      overlay.blt(scroll_x, y, @sliderbitmap.bitmap, Rect.new(36, 0, 36, 4))
      i = 0
      while i * 16 < boxheight - 4 - 18
        height = [boxheight - 4 - 18 - (i * 16), 16].min
        overlay.blt(scroll_x, y + 4 + (i * 16), @sliderbitmap.bitmap, Rect.new(36, 4, 36, height))
        i += 1
      end
      overlay.blt(scroll_x, y + boxheight - 18, @sliderbitmap.bitmap, Rect.new(36, 20, 36, 18))
    end
    
    # Set the selected item's icon
    @sprites["itemicon"].item = itemlist.item
    # Set the selected item's description
    #@sprites["itemtext"].text =
     # (itemlist.item) ? GameData::Item.get(itemlist.item).description : _INTL("Close bag.")
  end

  def pbRefreshFilter
    @filterlist = nil
    return if !@choosing
    return if @filterproc.nil?
    @filterlist = []
    (1...@bag.pockets.length).each do |i|
      @filterlist[i] = []
      @bag.pockets[i].length.times do |j|
        @filterlist[i].push(j) if @filterproc.call(@bag.pockets[i][j][0])
      end
    end
  end

  def pbHardRefresh
    oldtext      = []
    lastselected = -1
    for i in 0...Settings::MAX_PARTY_SIZE
      oldtext.push(@sprites["pokemon#{i}"].text)
      lastselected = i if @sprites["pokemon#{i}"].selected
      @sprites["pokemon#{i}"].dispose
    end
    lastselected = @party.length - 1 if lastselected >= @party.length
    lastselected = 0 if lastselected < 0
    for i in 0...Settings::MAX_PARTY_SIZE
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonBagPartyPanel.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PokemonBagPartyBlankPanel.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = oldtext[i]
    end
    pbSelect(lastselected)
  end

  def pbRefreshSingle(i)
    sprite = @sprites["pokemon#{i}"]
    if sprite
      if sprite.is_a?(PokemonBagPartyPanel)
        sprite.pokemon = sprite.pokemon
      else
        sprite.refresh
      end
    end
  end
  
 def pbUpdateAnnotation
    itemwindow = @sprites["itemlist"]
    item = itemwindow.item
    itm = GameData::Item.get(item) if item
    
    for i in 0...Settings::MAX_PARTY_SIZE
      pokemon = @party[i]
      next if !@sprites["pokemon#{i}"].is_a?(PokemonBagPartyPanel)
      
      annotation = ""
      if item && pokemon
        if itm && itm.is_machine?
          machine = itm.move
          if pokemon.hasMove?(machine)
            annotation = _INTL("Learned")
          elsif pokemon.compatible_with_move?(machine)
            annotation = _INTL("Able")
          else
            annotation = _INTL("Unable")
          end
        end
      end
      @sprites["pokemon#{i}"].text = annotation
    end
  end
      

  # Called when the item screen wants an item to be chosen from the screen
    def pbChooseItem
    @sprites["helpwindow"].visible = false
    itemwindow = @sprites["itemlist"]
    thispocket = @bag.pockets[itemwindow.pocket]
    swapinitialpos = -1
    
    # --- MOUSE & TOUCH VARIABLES ---
    last_mx, last_my = Input.mouse_x, Input.mouse_y
    drag_start_x = 0
    drag_start_y = 0
    drag_start_index = 0
    is_dragging = false
    has_moved_significantly = false
    
    pbActivateWindow(@sprites, "itemlist") {
      loop do
        oldindex = itemwindow.index
        Graphics.update
        Input.update
        pbUpdate
        pbUpdateAnnotation
        
        # =========================================================
        # MOUSE, SCROLL WHEEL & TOUCH DRAG LOGIC
        # =========================================================
        mx, my = Input.mouse_x, Input.mouse_y
        
        # 1. SCROLL WHEEL
        if Input.scroll_v != 0
           delta = (Input.scroll_v > 0) ? -1 : 1
           new_idx = [[itemwindow.index + delta, 0].max, thispocket.length - 1].min
           if itemwindow.index != new_idx
              itemwindow.index = new_idx
           end
        end

        # 2. TOUCH START (Trigger)
        if Input.trigger?(Input::MOUSELEFT)
           # FIX: Always reset 'has_moved' on any click, anywhere
           has_moved_significantly = false
           drag_start_x = mx 
           drag_start_y = my
           
           # Only enable list dragging if clicked inside the list
           if mx >= itemwindow.x && mx < itemwindow.x + itemwindow.width &&
              my >= itemwindow.y && my < itemwindow.y + itemwindow.height
              is_dragging = true
              drag_start_index = itemwindow.index
           else
              is_dragging = false
           end
        end
        
        # 3. TOUCH DRAG (Press/Hold) - Only if started inside list
        if is_dragging && Input.press?(Input::MOUSELEFT)
           dist_y = drag_start_y - my
           dist_x = drag_start_x - mx
           
           # --- A. HORIZONTAL SWIPE (Change Pocket) ---
           if dist_x.abs > dist_y.abs && dist_x.abs > 60
              
              change_pocket = 0
              if dist_x > 0      # Swipe Left -> Next Pocket
                 change_pocket = 1 
              elsif dist_x < 0   # Swipe Right -> Previous Pocket
                 change_pocket = -1
              end
              
              if change_pocket != 0
                 newpocket = itemwindow.pocket
                 loop do
                   if change_pocket == 1
                     newpocket = (newpocket == PokemonBag.pocket_count) ? 1 : newpocket + 1
                   else
                     newpocket = (newpocket == 1) ? PokemonBag.pocket_count : newpocket - 1
                   end
                   
                   break if !@choosing || newpocket == itemwindow.pocket
                   if @filterlist
                     break if @filterlist[newpocket].length > 0
                   elsif @bag.pockets[newpocket].length > 0
                     break
                   end
                 end
                 
                 if itemwindow.pocket != newpocket
                   itemwindow.pocket = newpocket
                   @bag.last_viewed_pocket = itemwindow.pocket
                   thispocket = @bag.pockets[itemwindow.pocket]
                   pbRefresh
                   pbSEPlay("GUI bag pocket")
                   
                   shift_val = (change_pocket == 1) ? 2 : -2
                   @sprites["currentpocket"].x += shift_val
                   pbWait(0.1) {pbUpdate}
                   @sprites["currentpocket"].x -= shift_val
                 end
                 
                 is_dragging = false
                 has_moved_significantly = true
              end
              
           # --- B. VERTICAL SCROLL (Scroll List) ---
           elsif dist_y.abs > 10 
              has_moved_significantly = true
              steps = (dist_y / 40.0).to_i
              target_index = [[drag_start_index + steps, 0].max, thispocket.length - 1].min
              
              if itemwindow.index != target_index
                 itemwindow.index = target_index
              end
           end
        end
        
        # 4. TOUCH RELEASE (Click Confirmation & Buttons)
        if Input.release?(Input::MOUSELEFT)
           # Stop dragging flag
           is_dragging = false
           
           # If we released and DID NOT drag significantly, treat it as a Click
           if !has_moved_significantly
               
               # --- A. INVISIBLE BUTTONS ---
               
               # 1. LEFT POCKET BUTTON
               btn_left_x = Graphics.width - 712
               btn_left_y = 16
               if mx >= btn_left_x && mx < btn_left_x + 56 &&
                  my >= btn_left_y && my < btn_left_y + 50
                  
                  newpocket = itemwindow.pocket
                  loop do
                    newpocket = (newpocket == 1) ? PokemonBag.pocket_count : newpocket - 1
                    break if !@choosing || newpocket == itemwindow.pocket
                    if @filterlist
                      break if @filterlist[newpocket].length > 0
                    elsif @bag.pockets[newpocket].length > 0
                      break
                    end
                  end
                  if itemwindow.pocket != newpocket
                    itemwindow.pocket = newpocket
                    @bag.last_viewed_pocket = itemwindow.pocket
                    thispocket = @bag.pockets[itemwindow.pocket]
                    pbRefresh
                    pbSEPlay("GUI bag pocket")
                    @sprites["currentpocket"].x -= 2
                    pbWait(0.1) {pbUpdate}
                    @sprites["currentpocket"].x += 2
                  end
                  next 
               end

               # 2. RIGHT POCKET BUTTON
               btn_right_x = Graphics.width - 375
               btn_right_y = 16
               if mx >= btn_right_x && mx < btn_right_x + 56 &&
                  my >= btn_right_y && my < btn_right_y + 50
                  
                  newpocket = itemwindow.pocket
                  loop do
                    newpocket = (newpocket == PokemonBag.pocket_count) ? 1 : newpocket + 1
                    break if !@choosing || newpocket == itemwindow.pocket
                    if @filterlist
                      break if @filterlist[newpocket].length > 0
                    elsif @bag.pockets[newpocket].length > 0
                      break
                    end
                  end
                  if itemwindow.pocket != newpocket
                    itemwindow.pocket = newpocket
                    @bag.last_viewed_pocket = itemwindow.pocket
                    thispocket = @bag.pockets[itemwindow.pocket]
                    pbRefresh
                    pbSEPlay("GUI bag pocket")
                    @sprites["currentpocket"].x += 2
                    pbWait(0.1) {pbUpdate}
                    @sprites["currentpocket"].x -= 2
                  end
                  next
               end

               # 3. QUIT BUTTON
               btn_quit_w = 96
               btn_quit_h = 96
               btn_quit_x = 16
               btn_quit_y = 16
               if mx >= btn_quit_x && mx < btn_quit_x + btn_quit_w &&
                  my >= btn_quit_y && my < btn_quit_y + btn_quit_h
                  pbPlayCloseMenuSE
                  return nil
               end

               # 4. SORT BUTTON
               btn_sort_w = 96
               btn_sort_h = 96
               btn_sort_x = 16
               btn_sort_y = 96 + 16
               if mx >= btn_sort_x && mx < btn_sort_x + btn_sort_w &&
                  my >= btn_sort_y && my < btn_sort_y + btn_sort_h
                  
                  if !@choosing && thispocket.length > 1 && itemwindow.index < thispocket.length &&
                     !Settings::BAG_POCKET_AUTO_SORT[itemwindow.pocket - 1]
                     if itemwindow.sorting
                        itemwindow.sorting = false
                        pbPlayDecisionSE
                        pbRefresh
                     else
                        itemwindow.sorting = true
                        swapinitialpos = itemwindow.index
                        pbPlayDecisionSE
                        pbRefresh
                     end
                  end
                  next
               end
               
               # --- B. ITEM LIST CLICK ---
               # Only check if click was actually inside the list area
               if mx >= itemwindow.x && mx < itemwindow.x + itemwindow.width &&
                  my >= itemwindow.y && my < itemwindow.y + itemwindow.height
                  
                   start_i = itemwindow.top_item
                   end_i = [start_i + itemwindow.page_item_max, itemwindow.itemCount].min
                   win_x, win_y = itemwindow.x, itemwindow.y
                   
                   clicked_item = false
                   (start_i...end_i).each do |i|
                      rect = itemwindow.itemRect(i)
                      if mx >= win_x + rect.x && mx < win_x + rect.x + rect.width &&
                         my >= win_y + rect.y && my < win_y + rect.y + rect.height
                         
                         if itemwindow.index != i
                            itemwindow.index = i
                            pbPlayCursorSE
                         end
                         clicked_item = true
                         break
                      end
                   end
                   
                   if clicked_item
                      if itemwindow.sorting
                         itemwindow.sorting = false
                         pbPlayDecisionSE
                         pbRefresh
                      else
                         (itemwindow.item) ? pbPlayDecisionSE : pbPlayCloseMenuSE
                         return itemwindow.item
                      end
                   end
               end
           end
        end

        # 5. MOUSE HOVER
        if !is_dragging && !Input.press?(Input::MOUSELEFT) && (mx != last_mx || my != last_my)
           start_i = itemwindow.top_item
           end_i = [start_i + itemwindow.page_item_max, itemwindow.itemCount].min
           win_x, win_y = itemwindow.x, itemwindow.y
           
           (start_i...end_i).each do |i|
              rect = itemwindow.itemRect(i)
              if mx >= win_x + rect.x && mx < win_x + rect.x + rect.width &&
                 my >= win_y + rect.y && my < win_y + rect.y + rect.height
                 if itemwindow.index != i
                   itemwindow.index = i
                   pbPlayCursorSE
                 end
              end
           end
           last_mx, last_my = mx, my
        end
        # =========================================================

        if itemwindow.sorting && itemwindow.index >= thispocket.length
          itemwindow.index = (oldindex == thispocket.length - 1) ? 0 : thispocket.length - 1
        end
        if itemwindow.index != oldindex
          # Move the item being switched
          if itemwindow.sorting
            thispocket.insert(itemwindow.index, thispocket.delete_at(oldindex))
          end
          # Update selected item for current pocket
          @bag.set_last_viewed_index(itemwindow.pocket, itemwindow.index)
          pbRefresh
        end
        if itemwindow.sorting
          if Input.trigger?(Input::ACTION) ||
             Input.trigger?(Input::USE)
            itemwindow.sorting = false
            pbPlayDecisionSE
            pbRefresh
          elsif Input.trigger?(Input::BACK)
            thispocket.insert(swapinitialpos, thispocket.delete_at(itemwindow.index))
            itemwindow.index = swapinitialpos
            itemwindow.sorting = false
            pbPlayCancelSE
            pbRefresh
          end
        else
          # Plays SE when scrolling the item list (Keyboard Only)
          if Input.repeat?(Input::UP) && thispocket.length   > 0 || 
             Input.repeat?(Input::DOWN) && thispocket.length > 0
            pbSEPlay("GUI bag cursor") if itemwindow.index != oldindex
          end
          # Change pockets
          if Input.trigger?(Input::LEFT)
            newpocket = itemwindow.pocket
            loop do
              newpocket = (newpocket == 1) ? PokemonBag.pocket_count : newpocket - 1
              break if !@choosing || newpocket == itemwindow.pocket
              if @filterlist
                break if @filterlist[newpocket].length > 0
              elsif @bag.pockets[newpocket].length > 0
                break
              end
            end
            if itemwindow.pocket != newpocket
              itemwindow.pocket = newpocket
              @bag.last_viewed_pocket = itemwindow.pocket
              thispocket = @bag.pockets[itemwindow.pocket]
              pbRefresh
              pbSEPlay("GUI bag pocket")
              @sprites["currentpocket"].x -= 2
              pbWait(0.1) {pbUpdate}
              @sprites["currentpocket"].x += 2
            end
          elsif Input.trigger?(Input::RIGHT)
            newpocket = itemwindow.pocket
            loop do
              newpocket = (newpocket == PokemonBag.pocket_count) ? 1 : newpocket + 1
              break if !@choosing || newpocket == itemwindow.pocket
              if @filterlist
                break if @filterlist[newpocket].length > 0
              elsif @bag.pockets[newpocket].length > 0
                break
              end
            end
            if itemwindow.pocket != newpocket
              itemwindow.pocket = newpocket
              @bag.last_viewed_pocket = itemwindow.pocket
              thispocket = @bag.pockets[itemwindow.pocket]
              pbRefresh
              pbSEPlay("GUI bag pocket")
              @sprites["currentpocket"].x += 2
              pbWait(0.1) {pbUpdate}
              @sprites["currentpocket"].x -= 2
            end
          elsif Input.trigger?(Input::SPECIAL)   # Checking party
            if $player.pokemon_count == 0
              pbDisplay(_INTL("There is no Pokémon."))
            else
              pbSEPlay("GUI storage show party panel")
              itemwindow.party2sel = true
              pbRefresh
              pbDeactivateWindows(@sprites){pbChoosePoke(3, false)}
              pbRefresh
            end
          elsif Input.trigger?(Input::ACTION)   # Start switching the selected item
            if !@choosing && thispocket.length > 1 && itemwindow.index < thispocket.length &&
               !Settings::BAG_POCKET_AUTO_SORT[itemwindow.pocket - 1]
              itemwindow.sorting = true
              swapinitialpos = itemwindow.index
              pbPlayDecisionSE
              pbRefresh
            end
          elsif Input.trigger?(Input::BACK)   # Cancel the item screen
            pbPlayCloseMenuSE
            return nil
          elsif Input.trigger?(Input::USE)   # Choose selected item
            (itemwindow.item) ? pbPlayDecisionSE : pbPlayCloseMenuSE
            return itemwindow.item
          end
        end
      end
    }
  end


  def pbSetHelpText(helptext)
    helpwindow = @sprites["helpwindow"]
    pbBottomLeftLines(helpwindow, 1)
    helpwindow.text = helptext
    helpwindow.width = 512
    helpwindow.visible = true
  end

  def pbChangeSelection(key,currentsel)
    numsprites = @party.length - 1
    case key
    when Input::LEFT
      begin
        currentsel -= 1
      end while currentsel >= 0 && currentsel < @party.length && !@party[currentsel]
      if currentsel >= @party.length && currentsel < Settings::MAX_PARTY_SIZE
        currentsel = @party.length - 1
      end
      currentsel = numsprites if currentsel < 0 || currentsel > numsprites
    when Input::RIGHT
      begin
        currentsel += 1
      end while currentsel < @party.length && !@party[currentsel]
      currentsel = 0 if currentsel == @party.length
    when Input::UP
      if currentsel > numsprites
        currentsel -= 1
        while currentsel > 0 && currentsel < numsprites && !@party[currentsel]
          currentsel -= 1
        end 
      else
        begin
          currentsel -= 2
        end while currentsel > 0 && !@party[currentsel]
      end
      if currentsel > numsprites && currentsel < numsprites
        currentsel = numsprites
      end
      currentsel = numsprites if currentsel < 0
    when Input::DOWN
      if currentsel >= Settings::MAX_PARTY_SIZE - 1
        currentsel += 1
      else
        currentsel += 2
        currentsel = Settings::MAX_PARTY_SIZE if currentsel < Settings::MAX_PARTY_SIZE && !@party[currentsel]
      end
      if currentsel >= @party.length && currentsel < Settings::MAX_PARTY_SIZE
        currentsel = Settings::MAX_PARTY_SIZE
      elsif currentsel > numsprites
        currentsel = 0
      end
    end
    return currentsel
  end
  
  def pbChangeCursor(number)
    # 1 for using/giving an item to a Pokémon; 2 for exiting; 3 for interacting
    itemwindow = @sprites["itemlist"]
    if number == 1
      itemwindow.party1sel = true
    elsif number == 2
      itemwindow.party1sel = false
      itemwindow.party2sel = false
    elsif number == 3
      itemwindow.party2sel = true
    end
    pbRefresh
  end
  
  def pbChoosePoke(option, switching = false)
    # 0 to choose a Pokémon; 1 to hold an item; 2 to use an item; 3 to interact; 4 to switch party items
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].preselected = (switching && i == @activecmd)
      @sprites["pokemon#{i}"].switching   = switching
    end
    @sprites["pokemon#{@activecmd}"].selected = false if switching
    @activecmd = 0
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].selected = (i == @activecmd)
    end
    
    itemwindow = @sprites["itemlist"]
    item = itemwindow.item
    
    if option == 3 || option == 4
      pbChangeCursor(3)
    else
      pbChangeCursor(1)
    end
    
    # --- MOUSE INIT ---
    last_mx, last_my = Input.mouse_x, Input.mouse_y
    thispocket = @bag.pockets[itemwindow.pocket]
    
    loop do
      Graphics.update
      Input.update
      pbUpdate
      oldsel = @activecmd
      key = -1

      key = Input::RIGHT if Input.repeat?(Input::DOWN)
      key = Input::LEFT if Input.repeat?(Input::UP)

      if key >= 0 && @party.length > 1
        @activecmd = pbChangeSelection(key, @activecmd)
      end
      
      # =========================================================
      # MOUSE LOGIC: PARTY vs ITEM LIST
      # =========================================================
      mx, my = Input.mouse_x, Input.mouse_y
      
      # --- CHECK 1: IS MOUSE OVER ITEM LIST? ---
      is_over_list = (mx >= itemwindow.x && mx < itemwindow.x + itemwindow.width &&
                      my >= itemwindow.y && my < itemwindow.y + itemwindow.height)
      
      if is_over_list
         # A. Handle Scroll Wheel on List
         if Input.scroll_v != 0
            delta = (Input.scroll_v > 0) ? -1 : 1
            new_idx = [[itemwindow.index + delta, 0].max, thispocket.length - 1].min
            if itemwindow.index != new_idx
               itemwindow.index = new_idx
               # If scrolling, we consider this an "Interaction", so we cancel party selection
               return -1 
            end
         end

         # B. Handle Hover on List Items
         if mx != last_mx || my != last_my
             start_i = itemwindow.top_item
             end_i = [start_i + itemwindow.page_item_max, itemwindow.itemCount].min
             win_x, win_y = itemwindow.x, itemwindow.y
             
             (start_i...end_i).each do |i|
                rect = itemwindow.itemRect(i)
                if mx >= win_x + rect.x && mx < win_x + rect.x + rect.width &&
                   my >= win_y + rect.y && my < win_y + rect.y + rect.height
                   if itemwindow.index != i
                     itemwindow.index = i
                     pbPlayCursorSE
                   end
                end
             end
         end
         
         # C. Handle Click on List (Cancel Party Selection -> Return to Item Screen)
         if Input.trigger?(Input::MOUSELEFT)
            return -1
         end
         
         # D. Visuals: While hovering list, hide Party Cursor
         (0...Settings::MAX_PARTY_SIZE).each { |i| @sprites["pokemon#{i}"].selected = false }
         
      else
         # --- CHECK 2: IS MOUSE OVER PARTY? ---
         # Only update if mouse actually moved
         if mx != last_mx || my != last_my
            (0...Settings::MAX_PARTY_SIZE).each do |i|
              next if !@sprites["pokemon#{i}"] 
              s = @sprites["pokemon#{i}"]
              if mx >= s.x && mx < s.x + 260 &&
                 my >= s.y && my < s.y + 110
                 if @activecmd != i
                   @activecmd = i
                   pbPlayCursorSE
                 end
              end
            end
         end
         
         # Restore Party Selection Visuals (since we are not over list)
         (0...Settings::MAX_PARTY_SIZE).each do |i|
            @sprites["pokemon#{i}"].selected = (i == @activecmd)
         end
      end
      
      last_mx, last_my = mx, my
      # =========================================================

      if @activecmd != oldsel && !is_over_list # Only update if controlling party
        pbPlayCursorSE if key >= 0 
        numsprites = Settings::MAX_PARTY_SIZE
        for i in 0...numsprites
          @sprites["pokemon#{i}"].selected = (i == @activecmd)
        end
      end
      
      # --- DETECT PARTY CLICK ---
      clicked_party = false
      if Input.trigger?(Input::MOUSELEFT) && !is_over_list
        s = @sprites["pokemon#{@activecmd}"]
        if mx >= s.x && mx < s.x + 260 &&
           my >= s.y && my < s.y + 110
           clicked_party = true
        end
      end

      # Trigger if USE key OR Mouse Clicked on Party
      if (Input.trigger?(Input::USE) || clicked_party) && !is_over_list
        pkmn = @party[@activecmd]
        if option == 0 # Choose
          return @activecmd
        elsif option == 1 # Hold
          if @activecmd >= 0
            ret = pbGiveItemToPokemon(item, @party[@activecmd], self, @activecmd)
            pbChangeCursor(2)
            @sprites["pokemon#{@activecmd}"].selected = false
            break
          end
        elsif option == 2 # Use
          ret = pbBagUseItem(@bag, item, PokemonBagScreen, self, @activecmd)
          pbRefresh; pbUpdateAnnotation
          if !$bag.has?(item)
            @sprites["pokemon#{@activecmd}"].selected = false
            pbChangeCursor(2)
            break
          end
        elsif option == 3 # Interaction
          pbPlayDecisionSE
          loop do
            cmdSummary     = -1
            cmdTake        = -1 
            cmdMove        = -1
            commands = []
            # Generate command list
            commands[cmdSummary = commands.length]       = _INTL("Summary")
            commands[cmdTake = commands.length]          = _INTL("Take Item") if pkmn.hasItem?
            commands[cmdMove = commands.length]          = _INTL("Move Item") if pkmn.hasItem? && !GameData::Item.get(pkmn.item).is_mail?
            commands[commands.length]                    = _INTL("Cancel")
            # Show commands generated above
            if pkmn.hasItem?
              item = pkmn.item
              itemname = item.name
              article = (itemname.starts_with_vowel?) ? "an" : "a"
              command = pbShowCommands(_INTL("{1} is holding {2} {3}.", pkmn.name, article, itemname), commands)
            else
              command = pbShowCommands(_INTL("", pkmn.name), commands)
            end
            if cmdSummary >= 0 && command == cmdSummary   # Summary
              pbSummary(@activecmd)
            elsif cmdTake >= 0 && command == cmdTake && pkmn.hasItem?  # Take item
              if pbTakeItemFromPokemon(pkmn, self)
                pbRefresh
              end
              break
            elsif cmdMove >= 0 && command == cmdMove && pkmn.hasItem? && !GameData::Item.get(pkmn.item).is_mail?  # Move item
              oldpkmn = pkmn
              loop do
                pbPreSelect(oldpkmn)
                newpkmn = pbChoosePoke(4, true)
                if newpkmn < 0
                  pbClearSwitching
                  break 
                end
                newpkmn = @party[newpkmn]
                if newpkmn == oldpkmn
                  pbClearSwitching
                  break 
                end
                if newpkmn.egg?
                  pbDisplay(_INTL("Eggs can't hold items."))
                elsif !newpkmn.hasItem?
                  newpkmn.item = item
                  oldpkmn.item = nil
                  pbClearSwitching; pbRefresh
                  pbDisplay(_INTL("{1} was given the {2} to hold.", newpkmn.name, itemname))
                  break
                elsif GameData::Item.get(newpkmn.item).is_mail?
                  pbDisplay(_INTL("{1}'s mail must be removed before giving it an item.", newpkmn.name))
                else
                  newitem = newpkmn.item
                  newitemname = newitem.name
                  if newitem == :LEFTOVERS
                    pbDisplay(_INTL("{1} is already holding some {2}.\1", newpkmn.name, newitemname))
                  elsif newitemname.starts_with_vowel?
                    pbDisplay(_INTL("{1} is already holding an {2}.\1", newpkmn.name, newitemname))
                  else
                    pbDisplay(_INTL("{1} is already holding a {2}.\1", newpkmn.name, newitemname))
                  end
                  if pbConfirm(_INTL("Would you like to switch the two items?"))
                    newpkmn.item = item
                    oldpkmn.item = newitem
                    pbClearSwitching; pbRefresh
                    pbDisplay(_INTL("{1} was given the {2} to hold.", newpkmn.name, itemname))
                    pbDisplay(_INTL("{1} was given the {2} to hold.", oldpkmn.name, newitemname))
                  else
                    pbClearSwitching; pbRefresh
                  end
                  break
                end
              end
              break
            else
              break
            end
          end
        elsif option == 4 # Interaction for switching item
          return @activecmd
        end
      elsif Input.trigger?(Input::BACK) || Input.trigger?(Input::MOUSERIGHT)
        if option != 4
          pbSEPlay("GUI storage hide party panel")
          pbChangeCursor(2)
        else
          pbPlayCancelSE
        end
        if switching
          return -1
        elsif option == 0
          @sprites["pokemon#{@activecmd}"].selected = false
          return -1
        else
          @sprites["pokemon#{@activecmd}"].selected = false
          return
        end
      end
      break if ret == 2 && option == 2  # End screen
    end
  end
  
  def pbChoosePokemon(text = nil)
    # For fusing/unfusing Pokemon
    fusioncmd  = @activecmd
    @activecmd = 0
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].selected = (i == @activecmd)
    end
    @sprites["pokemon#{fusioncmd}"].selected = true
    loop do
      Graphics.update
      Input.update
      pbUpdate
      oldsel = @activecmd
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN) && @party.length > 2
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP) && @party.length > 2
      if key >= 0 && @party.length > 1
        @activecmd = pbChangeSelection(key,@activecmd)
      end
      if @activecmd != oldsel   # Changing selection
        pbPlayCursorSE
        numsprites = Settings::MAX_PARTY_SIZE
        for i in 0...numsprites
          @sprites["pokemon#{i}"].selected = (i == @activecmd)
        end
        @sprites["pokemon#{fusioncmd}"].selected = true
      end
      if Input.trigger?(Input::USE)
        @sprites["pokemon#{fusioncmd}"].selected = false if fusioncmd != @activecmd
        return @activecmd
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        @sprites["pokemon#{fusioncmd}"].selected = false if fusioncmd != @activecmd
        return -1
      end
    end
  end
  
  def pbSummary(pkmnid, inbattle=false)
    oldsprites = pbFadeOutAndHide(@sprites)
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene,inbattle)
    screen.pbStartScreen(@party,pkmnid)
    yield if block_given?
    pbFadeInAndShow(@sprites,oldsprites)
  end

  def pbSelect(item)
    @activecmd = item
    numsprites = Settings::MAX_PARTY_SIZE
    for i in 0...numsprites
      @sprites["pokemon#{i}"].selected = (i == @activecmd)
    end
  end
  
  def pbPreSelect(item)
    @othercmd = item
  end

  def pbClearSwitching
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].preselected = false
      @sprites["pokemon#{i}"].switching   = false
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
    return pbShowCommands(helptext,movenames,index)
  end
end

#===============================================================================
# Bag mechanics
#===============================================================================
#===============================================================================
# Bag mechanics
#===============================================================================
class PokemonBagScreen
  def initialize(scene, bag)
    @bag   = bag
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene(@bag, $player.party)
    item = nil
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      cmdRead     = -1
      cmdUse      = -1
      cmdRegister = -1
      cmdGive     = -1
      cmdToss     = -1
      cmdDebug    = -1
      commands = []
      # Generate command list
      commands[cmdRead = commands.length]       = _INTL("Read") if itm.is_mail?
      if ItemHandlers.hasOutHandler(item) || (itm.is_machine? && $player.party.length > 0)
        if ItemHandlers.hasUseText(item)
          commands[cmdUse = commands.length]    = ItemHandlers.getUseText(item)
        else
          commands[cmdUse = commands.length]    = _INTL("Use")
        end
      end
      commands[cmdGive = commands.length]       = _INTL("Give") if $player.pokemon_party.length > 0 && itm.can_hold?
      commands[cmdToss = commands.length]       = _INTL("Toss") if !itm.is_important? || $DEBUG
      if @bag.registered?(item)
        commands[cmdRegister = commands.length] = _INTL("Deselect")
      elsif pbCanRegisterItem?(item)
        commands[cmdRegister = commands.length] = _INTL("Register")
      end
      commands[cmdDebug = commands.length]      = _INTL("Debug") if $DEBUG
      commands[commands.length]                 = _INTL("Cancel")
      # Show commands generated above
      itemname = itm.name
      command = @scene.pbShowCommands(_INTL, commands)
      if cmdRead >= 0 && command == cmdRead   # Read mail
        pbFadeOutIn {
          pbDisplayMail(Mail.new(item, "", ""))
        }
      elsif cmdUse >= 0 && command == cmdUse   # Use item
        useType = itm.field_use
        # ret: 0 = Item wasn't used; 1 = Item used; 2 = Close Bag to use in field
        if useType == 1 # Consumables
          pbSEPlay("GUI storage show party panel")
          ret = @scene.pbChoosePoke(2, false)
        elsif useType == 3 || useType == 4 || useType == 5 # TM, HM and TR
          machine = itm.move
          movename = GameData::Move.get(machine).name
          pbSEPlay("PC access")
          pbDisplay(_INTL("You booted up {1}.", itm.name)) {@scene.pbUpdate}
          if pbConfirm(_INTL("Do you want to teach {1} to a Pokémon?", movename)) {@scene.pbUpdate}
            pbSEPlay("GUI storage show party panel")
            ret = @scene.pbChoosePoke(2, false)
          end
        else
          ret = pbUseItem(@bag, item, @scene)
        end
        break if ret == 2   # End screen
        @scene.pbRefresh
        next
      elsif cmdGive >= 0 && command == cmdGive   # Give item to Pokémon
        if $player.pokemon_count == 0
          @scene.pbDisplay(_INTL("There is no Pokémon."))
        elsif itm.is_important?
          @scene.pbDisplay(_INTL("The {1} can't be held.", itm.portion_name))
        else
          @scene.pbChoosePoke(1, false)
        end
      elsif cmdToss >= 0 && command == cmdToss   # Toss item
        qty = @bag.quantity(item)
        if qty > 1
          helptext = _INTL("") 
          qty = @scene.pbChooseNumber(helptext, qty)
        end
        if qty > 0
          itemname = (qty > 1) ? itm.portion_name_plural : itm.portion_name
          if pbConfirm(_INTL("Is it OK to throw away {1} {2}?", qty, itemname))
            qty.times { @bag.remove(item) }
            @scene.pbRefresh
          end
        end
      # --- REGISTER ITEM (HGSS SLOT SYSTEM) ---
      elsif cmdRegister >= 0 && command == cmdRegister
        if $bag.pbIsRegistered?(item)
          $bag.pbRegisterItem(item) 
          pbDisplay(_INTL("Unregistered the item."))
        else
          # HGSS Choice Menu
          msg = _INTL("Register in which slot?")
          
          # --- APPLY CUSTOM TEXTBOX STYLE ---
          $msg_style = :system
          sel = pbMessage(msg, [_INTL("Slot A"), _INTL("Slot B"), _INTL("Cancel")], 3)
          $msg_style = nil
          # ----------------------------------
          
          case sel
          when 0 # Slot A
            $bag.registered_item_2 = nil if $bag.registered_item_2 == item
            $bag.registered_item_1 = item
            pbDisplay(_INTL("Registered in Slot A."))
          when 1 # Slot B
            $bag.registered_item_1 = nil if $bag.registered_item_1 == item
            $bag.registered_item_2 = item
            pbDisplay(_INTL("Registered in Slot B."))
          end
        end
        # Correctly calls the scene to update the graphics without crashing
        @scene.pbRefresh
		
      elsif cmdDebug >= 0 && command == cmdDebug   # Debug
        command = 0
        loop do
          command = @scene.pbShowCommands(_INTL("Do what with {1}?", itemname),
                                          [_INTL("Change quantity"),
                                           _INTL("Make Mystery Gift"),
                                           _INTL("Cancel")], command)
          case command
          ### Cancel ###
          when -1, 2
            break
          ### Change quantity ###
          when 0
            qty = @bag.quantity(item)
            itemplural = itm.name_plural
            params = ChooseNumberParams.new
            params.setRange(0, Settings::BAG_MAX_PER_SLOT)
            params.setDefaultValue(qty)
            newqty = pbMessageChooseNumber(
              _INTL("Choose new quantity of {1} (max. {2}).", itemplural, Settings::BAG_MAX_PER_SLOT), params
            ) { @scene.pbUpdate }
            if newqty > qty
              @bag.add(item, newqty - qty)
            elsif newqty < qty
              @bag.remove(item, qty - newqty)
            end
            @scene.pbRefresh
            break if newqty == 0
          ### Make Mystery Gift ###
          when 1
            pbCreateMysteryGift(1, item)
          end
        end
      end
    end
    ($game_temp.fly_destination) ? @scene.dispose : @scene.pbEndScene
    return item
  end

  # =========================================================================
  # UPDATED: Passes &block to ensure sound/animation updates work
  # =========================================================================
  def pbDisplay(text, &block)
    $msg_style = :system
    @scene.pbDisplay(text, &block)
    $msg_style = nil
  end

  def pbConfirm(text, &block)
    $msg_style = :system
    ret = @scene.pbConfirm(text, &block)
    $msg_style = nil
    return ret
  end
  # =========================================================================

  # UI logic for the item screen for choosing an item.
  def pbChooseItemScreen(proc = nil)
    oldlastpocket = @bag.last_viewed_pocket
    oldchoices = @bag.last_pocket_selections.clone
    $bag.reset_last_selections if proc
    @scene.pbStartScene(@bag, $player.party, true, proc)
    item = @scene.pbChooseItem
    @scene.pbEndScene
    @bag.last_viewed_pocket = oldlastpocket
    @bag.last_pocket_selections = oldchoices
    return item
  end

  # UI logic for withdrawing an item in the item storage screen.
  def pbWithdrawItemScreen
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    @scene.pbStartScene(storage,$player.party)
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      qty = storage.quantity(item)
      if qty > 1 && !itm.is_important?
        qty = @scene.pbChooseNumber(_INTL("How many do you want to withdraw?"), qty)
      end
      next if qty <= 0
      if @bag.can_add?(item, qty)
        if !storage.remove(item, qty)
          raise "Can't delete items from storage"
        end
        if !@bag.add(item, qty)
          raise "Can't withdraw items from storage"
        end
        @scene.pbRefresh
        dispqty = (itm.is_important?) ? 1 : qty
        itemname = (dispqty > 1) ? itm.portion_name_plural : itm.portion_name
        pbDisplay(_INTL("Withdrew {1} {2}.", dispqty, itemname))
      else
        pbDisplay(_INTL("There's no more room in the Bag."))
      end
    end
    @scene.pbEndScene
  end

  # UI logic for depositing an item in the item storage screen.
  def pbDepositItemScreen
    @scene.pbStartScene(@bag,$player.party)
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      qty = @bag.quantity(item)
      if qty > 1 && !itm.is_important?
        qty = @scene.pbChooseNumber(_INTL(""), qty)
      end
      if qty > 0
        if storage.can_add?(item, qty)
          if !@bag.remove(item, qty)
            raise "Can't delete items from Bag"
          end
          if !storage.add(item, qty)
            raise "Can't deposit items to storage"
          end
          @scene.pbRefresh
          dispqty  = (itm.is_important?) ? 1 : qty
          itemname = (dispqty > 1) ? itm.portion_name_plural : itm.portion_name
          pbDisplay(_INTL("Deposited {1} {2}.", dispqty, itemname))
        else
          pbDisplay(_INTL("There's no room to store items."))
        end
      end
    end
    @scene.pbEndScene
  end

  # UI logic for tossing an item in the item storage screen.
  def pbTossItemScreen
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    @scene.pbStartScene(storage,$player.party)
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      if itm.is_important?
        @scene.pbDisplay(_INTL("That's too important to toss out!"))
        next
      end
      qty = storage.quantity(item)
      itemname       = itm.portion_name
      itemnameplural = itm.portion_name_plural
      if qty > 1
        qty = @scene.pbChooseNumber(_INTL("Toss out how many {1}?", itemnameplural), qty)
      end
      next if qty <= 0
      itemname = itemnameplural if qty > 1
      next if !pbConfirm(_INTL("Is it OK to throw away {1} {2}?", qty, itemname))
      if !storage.remove(item, qty)
        raise "Can't delete items from storage"
      end
      @scene.pbRefresh
    end
    @scene.pbEndScene
  end
end

#=============================================================================
# New function for using an item
#=============================================================================
# @return [Integer] 0 = item wasn't used; 1 = item used; 2 = close Bag to use in field
def pbBagUseItem(bag, item, scene, screen, chosen, bagscene=nil)
  itm     = GameData::Item.get(item)
  useType = itm.field_use
  found   = false
  pkmn    = $player.party[chosen]
  if itm.is_machine?    # TM, HM or TR
    if $player.pokemon_count == 0
      pbDisplay(_INTL("There is no Pokémon.")) { screen.pbUpdate }
      return 0
    end
    machine = itm.move
    return 0 if !machine
    movename = GameData::Move.get(machine).name
    move     = GameData::Move.get(machine).id
    movelist = nil; bymachine = false; oneusemachine = false
    if movelist != nil && movelist.is_a?(Array)
      for i in 0...movelist.length
        movelist[i] = GameData::Move.get(movelist[i]).id
      end
    end
    if pkmn.egg?
      pbDisplay(_INTL("Eggs can't be taught any moves.")) { screen.pbUpdate }
    elsif pkmn.shadowPokemon?
      pbDisplay(_INTL("Shadow Pokémon can't be taught any moves.")) { screen.pbUpdate }
    elsif movelist && !movelist.any? { |j| j == pkmn.species }
      pbDisplay(_INTL("{1} can't learn {2}.", pkmn.name, movename)) { screen.pbUpdate }
    elsif !pkmn.compatible_with_move?(move)
      pbDisplay(_INTL("{1} can't learn {2}.", pkmn.name, movename)) { screen.pbUpdate }
    else
      if pbLearnMove(pkmn, move, false, bymachine) { screen.pbUpdate }
        pkmn.add_first_move(move) if oneusemachine
        bag.remove(itm) if itm.consumed_after_use?
      end
    end
    screen.pbRefresh; screen.pbUpdate
    return 1
  elsif useType == 1 # Item is usable on a Pokémon
    if $player.pokemon_count == 0
      pbDisplay(_INTL("There is no Pokémon.")) { screen.pbUpdate }
      return 0
    end
    qty = 1
    ret = false
    screen.pbRefresh
    if pbCheckUseOnPokemon(item, pkmn, screen)
      ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, screen)
      if ret && useType == 1 # Usable on Pokémon, consumed
        $bag.remove(item, qty)  if itm.consumed_after_use? { screen.pbRefresh }
      end
      if !$bag.has?(item)
        screen.pbDisplay(_INTL("You used your last {1}.", itm.portion_name)) { screen.pbUpdate }
        screen.pbChangeCursor(2)
      end
      screen.pbRefresh
    end
    bagscene.pbRefresh if bagscene
    return 1
  else
    pbDisplay(_INTL("Can't use that here.")) { screen.pbUpdate }
    return 0
  end
end

#=============================================================================
# Reprogamming Sacred Ash to work with the party from the bag
#=============================================================================
ItemHandlers::UseInField.add(:SACREDASH, proc { |item|
  if $player.pokemon_count == 0
    pbDisplay(_INTL("There is no Pokémon."))
    next false
  end
  canrevive = false
  $player.pokemon_party.each do |i|
    next if !i.fainted?
    canrevive = true
    break
  end
  if !canrevive
    pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  revived = 0
  $player.party.each_with_index do |pkmn, i|
    next if !pkmn.fainted?
    revived += 1
    pkmn.heal
  end
  if revived > 1
    pbDisplay(_INTL("Your fainted Pokémon's HP were restored."))
  elsif revived == 1
    pbDisplay(_INTL("Your fainted Pokémon's HP was restored."))
  end
  next (revived > 0)
})

#=============================================================================
# Battle scene for openning the Bag screen and choosing an item to use
#=============================================================================
class Battle::Scene
  def pbItemMenu(idxBattler, _firstAction)
    # Initialize return value
    ret = -1
    
    # 1. Hide Battle Scene
    visibleSprites = pbFadeOutAndHide(@sprites)
    
    # Set Bag starting positions
    oldLastPocket = $bag.last_viewed_pocket
    oldChoices    = $bag.last_pocket_selections.clone
    if @bagLastPocket
      $bag.last_viewed_pocket     = @bagLastPocket
      $bag.last_pocket_selections = @bagChoices
    else
      $bag.reset_last_selections
    end
    
    # Setting up the party and starting the Bag screen
    partyPos = @battle.pbPartyOrder(idxBattler)
    partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
    modParty = @battle.pbPlayerDisplayParty(idxBattler)
    itemScene = PokemonBag_Scene.new
    itemScene.pbStartScene($bag, modParty, true,
                           proc { |item|
                             useType = GameData::Item.get(item).battle_use
                             next useType && useType > 0
                           }, false)
    
    # Loop while in Bag screen
    wasTargeting = false
    loop do
      # Select an item
      item = itemScene.pbChooseItem
      break if !item
      
      # Choose a command for the selected item
      item = GameData::Item.get(item)
      itemName = item.name
      useType = item.battle_use
      cmdUse = -1
      commands = []
      commands[cmdUse = commands.length] = _INTL("Use") if useType && useType != 0
      commands[commands.length]          = _INTL("Cancel")
      command = itemScene.pbShowCommands(_INTL, commands)
      next unless cmdUse >= 0 && command == cmdUse   # Use
      
      # Use types:
      # 1-3: Use on Pokemon/Move/Battler
      # 4: Use on Foe (Ball)
      # 5: No Target
      case useType
      when 1, 2, 3   # Use on Pokémon/Pokémon's move/battler
        # Auto-choose if only 1 option
        case useType
        when 1   # Use on Pokémon
          if @battle.pbTeamLengthFromBattlerIndex(idxBattler) == 1
            if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
              ret = item.id
              break
            end
          end
        when 3   # Use on battler
          if @battle.pbPlayerBattlerCount == 1
            if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
              ret = item.id
              break
            end
          end
        end
        
        # If auto-choose didn't break loop, proceed to manual selection
        break if ret > -1

        party    = @battle.pbParty(idxBattler)
        partyPos = @battle.pbPartyOrder(idxBattler)
        partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
        modParty = @battle.pbPlayerDisplayParty(idxBattler)
        idxParty = -1
        
        loop do
          pbPlayDecisionSE
          idxParty = itemScene.pbChoosePoke(0,false)
          break if idxParty < 0
          idxPartyRet = -1
          partyPos.each_with_index do |pos, i|
            next if pos != idxParty + partyStart
            idxPartyRet = i
            break
          end
          next if idxPartyRet < 0
          pkmn = party[idxPartyRet]
          next if !pkmn || pkmn.egg?
          idxMove = -1
          if useType == 2   # Use on Pokémon's move
            idxMove = itemScene.pbChooseMove(pkmn,_INTL("Restore which move?"))
            next if idxMove < 0
          end
          if yield item.id, useType, idxPartyRet, idxMove, itemScene
            ret = item.id
            break
          end
        end
        break if idxParty >= 0
        
      when 4   # Use on opposing battler (Poké Balls)
        idxTarget = -1
        
        # --- NEW: Check Opponent Count INSIDE Bag Screen ---
        if @battle.pbOpposingBattlerCount(idxBattler) > 1
           # If more than 1 opponent, show message inside Bag and restart loop
           itemScene.pbDisplay(_INTL("It's no good! It's impossible to aim when there is more than one Pokémon!"))
           next 
        end
        # ---------------------------------------------------

        if @battle.pbOpposingBattlerCount(idxBattler) == 1
          @battle.allOtherSideBattlers(idxBattler).each { |b| idxTarget = b.index }
          if yield item.id, useType, idxTarget, -1, itemScene
            ret = item.id
            break 
          end
        else
          wasTargeting = true
          itemScene.pbFadeOutScene
          tempVisibleSprites = visibleSprites.clone
          tempVisibleSprites["commandWindow"] = false
          tempVisibleSprites["targetWindow"]  = true
          idxTarget = pbChooseTarget(idxBattler, GameData::Target.get(:Foe), tempVisibleSprites)
          if idxTarget >= 0
            if yield item.id, useType, idxTarget, -1, self
              ret = item.id
              break
            end
          end
          wasTargeting = false
          pbFadeOutAndHide(@sprites)
          itemScene.pbFadeInScene
        end
        
      when 5   # Use with no target
        if yield item.id, useType, idxBattler, -1, itemScene
          ret = item.id
          break 
        end
      end
    end
    
    # Save Bag State
    @bagLastPocket = $bag.last_viewed_pocket
    @bagChoices    = $bag.last_pocket_selections.clone
    $bag.last_viewed_pocket     = oldLastPocket
    $bag.last_pocket_selections = oldChoices
    
    # 2. Close Bag and Restore Battle Scene
    itemScene.pbEndScene
    pbFadeInAndShow(@sprites, visibleSprites)
    
    return ret
  end
end