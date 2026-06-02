#===============================================================================
# Ready Menu - Dropdown Style
# Fixed: Hidden Item Quantity (x99)
# Retains: Swipe, Scroll, Click, Hover, Exit Button, Custom Textbox, Debounce
#===============================================================================
class ReadyMenuButton < Sprite
  attr_reader :index   # ID of button
  attr_reader :selected
  attr_reader :side

  # CONSTANT: How many items to show at once
  VISIBLE_ITEMS = 7
  
  # CONSTANT: Starting Coordinates
  START_X = 16
  START_Y = 208

  def initialize(index, command, selected, side, viewport = nil)
    super(viewport)
    @index = index
    @command = command   # Item/move ID, name, mode (T move/F item), pkmnIndex
    @selected = selected
    @side = side
    
    # Force Left-Side Graphic
    @button = AnimatedBitmap.new("Graphics/UI/Ready Menu/icon_movebutton")

    # Create Bitmap
    @contents = Bitmap.new(@button.width, @button.height / 2)
    self.bitmap = @contents
    pbSetSystemFont(self.bitmap)
    
    if @command[2]
      @icon = PokemonIconSprite.new($player.party[@command[3]], viewport)
      @icon.setOffset(PictureOrigin::CENTER)
    else
      @icon = ItemIconSprite.new(0, 0, @command[0], viewport)
    end
    @icon.z = self.z + 1
    
    # Initially refresh to set positions
    refresh 
  end

  def dispose
    @button.dispose
    @contents.dispose
    @icon.dispose
    super
  end

  def visible=(val)
    @icon.visible = val
    super(val)
  end

  def selected=(val)
    oldsel = @selected
    @selected = val
    refresh if oldsel != val
  end

  def side=(val)
    oldsel = @side
    @side = val
    refresh if oldsel != val
  end

  #-----------------------------------------------------------------------------
  # Update Position - Dropdown Logic
  #-----------------------------------------------------------------------------
  def refresh
    # 1. Determine Window Scroll Offset
    top_index = 0
    if @selected >= VISIBLE_ITEMS
       top_index = @selected - (VISIBLE_ITEMS - 1)
    end
    
    # 2. Calculate Visual Index
    visual_index = @index - top_index
    
    # 3. Visibility Check
    if visual_index >= 0 && visual_index < VISIBLE_ITEMS
       self.visible = true
       @icon.visible = true
       
       # 4. Calculate Coordinates
       self.x = START_X
       
       # Item Height with Padding (+8)
       item_height = (@button.height / 2) + 8 
       
       self.y = START_Y + (visual_index * item_height)
       
    else
       self.visible = false
       @icon.visible = false
    end

    # --- Standard Graphic Logic ---
    # Check if this button is the selected one
    sel = (@selected == @index && (@side == 0) == @command[2])
    
    # Icon Positioning
    if @command[2]   # Pokémon
      @icon.x = self.x + 52
      @icon.y = self.y + 32
    else   # Item
      @icon.x = self.x + 48
      @icon.y = self.y + (@button.height / 4)
    end
    
    self.bitmap.clear
    
    # Draw Background (Top half = Normal, Bottom half = Selected)
    # If sel is true, use the bottom half of the source image.
    src_y = (sel) ? @button.height / 2 : 0
    rect = Rect.new(0, src_y, @button.width, @button.height / 2)
    self.bitmap.blt(0, 0, @button.bitmap, rect)
    
    # --- TEXT ALIGNMENT ---
    # X: 16px padding from Icon (Icon is at ~48, so 48+48 = 96)
    text_x_pos = 96 
    
    # Y: Vertically Center
    # Center of button height, minus 12 (half of 24px font height)
    text_y_pos = (self.bitmap.height / 2) - 12
    
    textpos = [
      [@command[1], text_x_pos, text_y_pos, :left, Color.new(0, 0, 0), Color.new(40, 40, 40, 0), :outline]
    ]
    
    # --- ITEM QUANTITY DISPLAY (COMMENTED OUT) ---
    # if !@command[2] && !GameData::Item.get(@command[0]).is_important?
    #   qty = $bag.quantity(@command[0])
    #   if qty > 99
    #     textpos.push([_INTL(">99"), 230, text_y_pos, :right,
    #                   Color.new(0, 0, 0), Color.new(40, 40, 40, 0), :outline])
    #   else
    #     textpos.push([_INTL("x{1}", qty), 230, text_y_pos, :right,
    #                   Color.new(0, 0, 0), Color.new(40, 40, 40, 0), :outline])
    #   end
    # end
    # ---------------------------------------------

    pbDrawTextPositions(self.bitmap, textpos)
  end

  def update
    @icon&.update
    super
  end
  
  # Helpers for Mouse Logic
  def width; @button.width; end
  def height; (@button.height / 2); end
end

#===============================================================================
# Scene
#===============================================================================
class PokemonReadyMenu_Scene
  attr_reader :sprites

  def pbStartScene(commands)
    @commands = commands
    @movecommands = []
    @itemcommands = []
    @commands[0].length.times do |i|
      @movecommands.push(@commands[0][i][1])
    end
    @commands[1].length.times do |i|
      @itemcommands.push(@commands[1][i][1])
    end
    @index = $bag.ready_menu_selection
    if @index[0] >= @movecommands.length && @movecommands.length > 0
      @index[0] = @movecommands.length - 1
    end
    if @index[1] >= @itemcommands.length && @itemcommands.length > 0
      @index[1] = @itemcommands.length - 1
    end
    if @index[2] == 0 && @movecommands.length == 0
      @index[2] = 1
    elsif @index[2] == 1 && @itemcommands.length == 0
      @index[2] = 0
    end
    
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    
    # --- EXIT BUTTON (X=112, Y=16) ---
    @sprites["exit_btn"] = Sprite.new(@viewport)
    if pbResolveBitmap("Graphics/UI/overworld_field_btn_sel")
      @sprites["exit_btn"].bitmap = Bitmap.new("Graphics/UI/overworld_field_btn_sel")
    else
      # Fallback Red Square
      @sprites["exit_btn"].bitmap = Bitmap.new(96, 96)
      @sprites["exit_btn"].bitmap.fill_rect(0,0,96,96, Color.new(255,0,0))
    end
    @sprites["exit_btn"].x = 1112
    @sprites["exit_btn"].y = 16
    @sprites["exit_btn"].z = 100000
    @sprites["exit_btn"].visible = true # FORCE VISIBLE ON START
    
    # --- CURSOR SPRITE ---
    @sprites["cursor"] = Sprite.new(@viewport)
    @sprites["cursor"].z = 999999 # Absolute Top
    @sprites["cursor"].mirror = true 
    
    if pbResolveBitmap("Graphics/UI/sel_arrow")
      @sprites["cursor"].bitmap = Bitmap.new("Graphics/UI/sel_arrow")
    else
      # Fallback: Cyan Triangle
      @sprites["cursor"].bitmap = Bitmap.new(32, 32)
      @sprites["cursor"].bitmap.fill_rect(0,0,32,32, Color.new(0,255,255))
    end
    
    @sprites["cursor"].visible = false

    @sprites["cmdwindow"] = Window_CommandPokemon.new((@index[2] == 0) ? @movecommands : @itemcommands)
    @sprites["cmdwindow"].height = 192
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
    
    @commands[0].length.times do |i|
      @sprites["movebutton#{i}"] = ReadyMenuButton.new(i, @commands[0][i], @index[0], @index[2], @viewport)
    end
    @commands[1].length.times do |i|
      @sprites["itembutton#{i}"] = ReadyMenuButton.new(i, @commands[1][i], @index[1], @index[2], @viewport)
    end
    pbSEPlay("GUI menu open")
    
    # Mouse tracking for sync
    @last_mx, @last_my = Input.mouse_x, Input.mouse_y
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = false
    
    # Refresh all buttons to ensure correct positioning before showing cursor
    @commands[0].length.times do |i|
      @sprites["movebutton#{i}"].refresh 
    end
    @commands[1].length.times do |i|
      @sprites["itembutton#{i}"].refresh
    end
    
    @sprites["cursor"].visible = true
    @sprites["exit_btn"].visible = true
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    @sprites["cursor"].visible = false
    @sprites["exit_btn"].visible = false
    @commands[0].length.times do |i|
      @sprites["movebutton#{i}"].visible = false
    end
    @commands[1].length.times do |i|
      @sprites["itembutton#{i}"].visible = false
    end
  end

  def pbShowCommands
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = (@index[2] == 0) ? @movecommands : @itemcommands
    cmdwindow.index    = @index[@index[2]]
    cmdwindow.visible  = false
    
    # IMPORTANT: Ensure Menu UI is shown immediately
    pbShowMenu 
    
    # --- DRAG VARIABLES ---
    drag_start_x = 0
    drag_start_y = 0
    drag_start_index = 0
    is_dragging = false
    has_moved_significantly = false
    
    # --- COOLDOWN VARIABLE (Fixes immediate close) ---
    input_cooldown = 0
    
    loop do
      pbUpdate
      
      # Increment cooldown
      input_cooldown += 1 if input_cooldown <= 12
      
      mx, my = Input.mouse_x, Input.mouse_y
      
      # -------------------------------------------------------------
      # 1. TOUCH START (Trigger)
      # -------------------------------------------------------------
      # Only allow interaction if cooldown passed
      if input_cooldown > 12
        if Input.trigger?(Input::MOUSELEFT)
          drag_start_x = mx
          drag_start_y = my
          drag_start_index = @index[@index[2]]
          is_dragging = true
          has_moved_significantly = false
        end
      end
      
      # -------------------------------------------------------------
      # 2. TOUCH DRAG (Holding)
      # -------------------------------------------------------------
      if is_dragging && Input.press?(Input::MOUSELEFT)
        dist_x = mx - drag_start_x
        dist_y = my - drag_start_y 
        
        # --- A. HORIZONTAL SWIPE (Change Tabs) ---
        if dist_x.abs > dist_y.abs && dist_x.abs > 60
          if !has_moved_significantly
             # Right Swipe -> Move Left (if available)
             if dist_x > 0 && @index[2] == 1 && @movecommands.length > 0
                @index[2] = 0
                pbChangeSide
                has_moved_significantly = true
             # Left Swipe -> Move Right (if available)
             elsif dist_x < 0 && @index[2] == 0 && @itemcommands.length > 0
                @index[2] = 1
                pbChangeSide
                has_moved_significantly = true
             end
          end
          
        # --- B. VERTICAL DRAG (Scroll List) ---
        elsif dist_y.abs > 10 # Lower threshold for responsiveness
           has_moved_significantly = true
           
           # Sensitivity: 1 item per ~56 pixels (approx button height)
           # Negative dist_y means dragging UP, which should scroll DOWN (index increases)
           steps = -(dist_y / 56.0).to_i 
           
           current_side = @index[2]
           list_len = (current_side == 0) ? @movecommands.length : @itemcommands.length
           
           target_index = [[drag_start_index + steps, 0].max, list_len - 1].min
           
           if @index[current_side] != target_index
              cmdwindow.index = target_index
              pbPlayCursorSE
              pbUpdate # Force Visual Refresh
           end
        end
      end
      
      # -------------------------------------------------------------
      # 3. TOUCH RELEASE (Confirm Click)
      # -------------------------------------------------------------
      if Input.release?(Input::MOUSELEFT)
         is_dragging = false
         
         # ONLY click if we didn't drag AND cooldown passed
         if !has_moved_significantly && input_cooldown > 12
            clicked_ret = check_click_on_release(mx, my)
            if clicked_ret
               ret = clicked_ret
               break
            end
         end
         
         # RESET MOVING FLAG (Fixes Mouse Hover stopping after drag)
         has_moved_significantly = false
      end
      
      # -------------------------------------------------------------
      # 4. MOUSE SCROLL WHEEL
      # -------------------------------------------------------------
      scroll_amt = 0
      if Input.respond_to?(:scroll_v)
         scroll_amt = Input.scroll_v
         scroll_amt = (scroll_amt > 0) ? -1 : 1 if scroll_amt != 0
      elsif Input.respond_to?(:scroll)
         scroll_amt = Input.scroll
      end

      if scroll_amt != 0
        current_side = @index[2]
        list_len = (current_side == 0) ? @movecommands.length : @itemcommands.length
        if list_len > 1
          # Scroll Up/Down
          new_idx = @index[current_side] - scroll_amt
          
          # Clamp
          if new_idx < 0
             new_idx = 0
          elsif new_idx >= list_len
             new_idx = list_len - 1
          end
          
          # Update if changed
          if @index[current_side] != new_idx
             # FIX: Update cmdwindow index only. Let pbUpdate handle the rest.
             cmdwindow.index = new_idx
             pbPlayCursorSE
             # Visual refresh happens in pbUpdate
          end
        end
      end
      
      # -------------------------------------------------------------
      # 5. HOVER ONLY (Update selection visually)
      # -------------------------------------------------------------
      # Only run hover logic if we are NOT dragging and cooldown passed
      if !is_dragging && input_cooldown > 12
         update_hover_logic(mx, my)
      end
      
      # -------------------------------------------------------------
      # 6. KEYBOARD
      # -------------------------------------------------------------
      # Allow keyboard instantly
      if Input.trigger?(Input::LEFT) && @index[2] == 1 && @movecommands.length > 0
        @index[2] = 0
        pbChangeSide
      elsif Input.trigger?(Input::RIGHT) && @index[2] == 0 && @itemcommands.length > 0
        @index[2] = 1
        pbChangeSide
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        ret = -1
        break
      elsif Input.trigger?(Input::USE)
        ret = [@index[2], cmdwindow.index]
        break
      end
    end
    return ret
  end
  
  # NEW: Handles Mouse Hover (Only visuals/selection, NO clicking)
  def update_hover_logic(mx, my)
    # Check mouse movement to prevent fighting with keyboard
    mouse_moved = (mx != @last_mx || my != @last_my)
    @last_mx, @last_my = mx, my
    return if !mouse_moved
    
    current_side = @index[2]
    list_len = (current_side == 0) ? @commands[0].length : @commands[1].length
    prefix = (current_side == 0) ? "movebutton" : "itembutton"
    
    list_len.times do |i|
      btn = @sprites["#{prefix}#{i}"]
      next if !btn || !btn.visible 
      
      # Hitbox check
      if mx >= btn.x && mx < btn.x + btn.width &&
         my >= btn.y && my < btn.y + btn.height
         
         if @sprites["cmdwindow"].index != i
            @sprites["cmdwindow"].index = i
            pbPlayCursorSE
         end
         return
      end
    end
  end
  
  # NEW: Handles Clicks only when Mouse is Released (and wasn't dragged)
  def check_click_on_release(mx, my)
    # 1. EXIT BUTTON CLICK CHECK
    exit_btn = @sprites["exit_btn"]
    if exit_btn && exit_btn.visible
      if mx >= exit_btn.x && mx < exit_btn.x + exit_btn.bitmap.width &&
         my >= exit_btn.y && my < exit_btn.y + exit_btn.bitmap.height
         pbPlayCloseMenuSE
         return -1 # Close Menu Code
      end
    end
    
    # 2. LIST ITEMS CLICK CHECK
    current_side = @index[2]
    list_len = (current_side == 0) ? @commands[0].length : @commands[1].length
    prefix = (current_side == 0) ? "movebutton" : "itembutton"
    
    list_len.times do |i|
      btn = @sprites["#{prefix}#{i}"]
      next if !btn || !btn.visible 
      
      if mx >= btn.x && mx < btn.x + btn.width &&
         my >= btn.y && my < btn.y + btn.height
         
         pbPlayDecisionSE
         return [@index[2], i]
      end
    end
    return nil
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbChangeSide
    @commands[0].length.times do |i|
      @sprites["movebutton#{i}"].side = @index[2]
    end
    @commands[1].length.times do |i|
      @sprites["itembutton#{i}"].side = @index[2]
    end
    @sprites["cmdwindow"].commands = (@index[2] == 0) ? @movecommands : @itemcommands
    @sprites["cmdwindow"].index = @index[@index[2]]
  end

  def pbRefresh; end

  def pbUpdate
    oldindex = @index[@index[2]]
    
    # Sync: Get the index from the invisible command window
    @index[@index[2]] = @sprites["cmdwindow"].index
    
    # Detect change in selection (Keyboard OR Mouse OR Scroll)
    if @index[@index[2]] != oldindex
      case @index[2]
      when 0
        @commands[0].length.times do |i|
          @sprites["movebutton#{i}"].selected = @index[@index[2]]
          # Force refresh to update scrolling graphics
          @sprites["movebutton#{i}"].refresh 
        end
      when 1
        @commands[1].length.times do |i|
          @sprites["itembutton#{i}"].selected = @index[@index[2]]
          # Force refresh to update scrolling graphics
          @sprites["itembutton#{i}"].refresh 
        end
      end
    else
      # --- CONTINUOUS REFRESH ---
      # Forces button refresh every frame to ensure "Selected" graphic stays 
      # valid even if multiple inputs happen in one frame.
      case @index[2]
      when 0
        @commands[0].length.times do |i|
          @sprites["movebutton#{i}"].refresh 
        end
      when 1
        @commands[1].length.times do |i|
          @sprites["itembutton#{i}"].refresh 
        end
      end
    end
    
    # --- UPDATE CURSOR POSITION & ANIMATION ---
    update_cursor_logic
    
    pbUpdateSpriteHash(@sprites)
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end
  
  def update_cursor_logic
    cursor = @sprites["cursor"]
    return if !cursor
    
    # 1. Identify Selected Button
    selected_idx = @index[@index[2]]
    current_side = @index[2]
    
    # Construct sprite key name
    sprite_name = (current_side == 0) ? "movebutton#{selected_idx}" : "itembutton#{selected_idx}"
    target_btn = @sprites[sprite_name]
    
    if target_btn && target_btn.visible
      cursor.visible = true
      
      # 2. Bobbing Animation (Sine Wave)
      bob_offset = (Math.sin(Graphics.frame_count / 3.0) * 6).to_i
      
      # 3. Position Cursor
      # X = Button X + Button Width + Padding + Bobbing - 26 (Shift Left)
      cursor.x = target_btn.x + target_btn.bitmap.width + 4 + bob_offset - 26
      
      # Y = Center of Button - Center of Cursor
      cursor.y = target_btn.y + (target_btn.bitmap.height / 2) - (cursor.bitmap.height / 2)
    else
      cursor.visible = false
    end
  end
end

#===============================================================================
# PokemonReadyMenu (Wrapper)
#===============================================================================
class PokemonReadyMenu
  def initialize(scene)
    @scene = scene
  end

  def pbHideMenu
    @scene.pbHideMenu
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbStartReadyMenu(moves, items)
    commands = [[], []]   # Moves, items
    moves.each do |i|
      commands[0].push([i[0], GameData::Move.get(i[0]).name, true, i[1]])
    end
    commands[0].sort! { |a, b| a[1] <=> b[1] }
    items.each do |i|
      commands[1].push([i, GameData::Item.get(i).name, false])
    end
    commands[1].sort! { |a, b| a[1] <=> b[1] }
    @scene.pbStartScene(commands)
    loop do
      command = @scene.pbShowCommands
      break if command == -1
      if command[0] == 0   # Use a move
        move = commands[0][command[1]][0]
        user = $player.party[commands[0][command[1]][3]]
        if move == :FLY
          ret = nil
          pbFadeOutInWithUpdate(99999, @scene.sprites) do
            pbHideMenu
            scene = PokemonRegionMap_Scene.new(-1, false)
            screen = PokemonRegionMapScreen.new(scene)
            ret = screen.pbStartFlyScreen
            pbShowMenu if !ret
          end
          if ret
            $game_temp.fly_destination = ret
            $game_temp.in_menu = false
            pbUseHiddenMove(user, move)
            break
          end
        else
          pbHideMenu
          
          # --- APPLY CUSTOM TEXTBOX STYLE ---
          $msg_style = :system
          conf = pbConfirmUseHiddenMove(user, move)
          $msg_style = nil
          
          if conf
            $game_temp.in_menu = false
            pbUseHiddenMove(user, move)
            break
          else
            pbShowMenu
          end
        end
      else   # Use an item
        item = commands[1][command[1]][0]
        pbHideMenu
        
        # --- APPLY CUSTOM TEXTBOX STYLE ---
        $msg_style = :system
        confirmed = ItemHandlers.triggerConfirmUseInField(item)
        $msg_style = nil
        
        if confirmed
          $game_temp.in_menu = false
          break if pbUseKeyItemInField(item)
          $game_temp.in_menu = true
        end
      end
      pbShowMenu
    end
    @scene.pbEndScene
  end
end

#===============================================================================
# Using a registered item
#===============================================================================
#===============================================================================
# Using a registered item - DISABLED to support custom Overworld UI
#===============================================================================
def pbUseKeyItem
  # This function is now empty to prevent the D key (SPECIAL) 
  # from triggering the old Ready Menu logic or errors.
  return
end
#def pbUseKeyItem
  # --- DISABLED Field Moves Logic ---
 # real_moves = []
  
  #real_items = []
  #$bag.registered_items.each do |i|
   # itm = GameData::Item.get(i).id
   # real_items.push(itm) if $bag.has?(itm)
  #end
  #if real_items.length == 0 && real_moves.length == 0
    # --- APPLY CUSTOM TEXTBOX STYLE ---
  #  $msg_style = :system
   # pbMessage(_INTL("An item in the Bag can be registered to this key for instant use."))
    #$msg_style = nil
  #else
   # $game_temp.in_menu = true
   # $game_map.update
   # sscene = PokemonReadyMenu_Scene.new
   # sscreen = PokemonReadyMenu.new(sscene)
   # sscreen.pbStartReadyMenu(real_moves, real_items)
    #$game_temp.in_menu = false
  #end
