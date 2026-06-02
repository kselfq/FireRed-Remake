#===============================================================================
# Pokemon Essentials 21.1 - Custom Pause Menu (1600x720 Scale + Animated Cursor)
# Updated: English Labels, Map Location, stacked Time/Period
#===============================================================================

class Scene_Map
  alias :original_call_menu :call_menu
  def call_menu
    $game_temp.menu_calling = false
    $game_player.straighten
    $game_map.update
    pbCallMenu2
  end
end

class Menu2
  attr_reader :item_to_use 
  attr_reader :hidden_move_to_use 

  # --- ANIMATION SETTINGS ---
  CURSOR_BOB_SPEED = 0.2  
  CURSOR_BOB_RANGE = 12   

  # --- VERTICAL POSITION ADJUSTMENT ---
  Y_ADJUSTMENT = 168 
  
  # --- CUSTOMIZABLE TEXT COLORS ---
  ICON_TEXT_COLOR = Color.new(255, 255, 255)
  TIME_TEXT_COLOR = Color.new(255, 255, 255)
  PERIOD_TEXT_COLOR = Color.new(255, 255, 255)
  LOCATION_TEXT_COLOR = Color.new(255, 255, 255)
  DEFAULT_TEXT_COLOR = Color.new(255, 255, 255)	

  # --- CUSTOMIZABLE FONTS ---
  ICON_FONT_NAME    = "poki"	
  TIME_FONT_NAME    = "poki"	
  PERIOD_FONT_NAME  = "poki"	
  LOCATION_FONT_NAME = "poki"
  DEFAULT_FONT_NAME = "poki"	
  
  # --- GLOBAL FONT SIZE ---
  GLOBAL_FONT_SIZE  = 32

  def initialize
    @selected_item = 0
    @items = []
    @item_to_use = nil
    @hidden_move_to_use = nil

    # EXACT ORDER: Pokedex(0), Bag(1), Party(2), Trainer(3), Save(4), Options(5)
    @PokedexCmd = addCmd(["pokedex", "Pokédex", "openPokedex"])
    @bagCmd     = addCmd(["bag",     "Bag",     "openBag"])       
    @partyCmd   = addCmd(["pokeball", "Party",   "openParty"])     
    @trainerCmd = addCmd(["trainer", "Trainer", "openTrainerCard"])
    @saveCmd    = addCmd(["save",    "Save",    "openSave"])
    @optionsCmd = addCmd(["options", "Options", "openOptions"])

    # --- DIMENSIONS ---
    @icon_width        = 124
    @icon_height       = 124
    @text_label_height = 38
    @n_icons           = 6	
    @spacing_x         = 75
    @spacing_y         = 38

    @menu_width = @n_icons * (@icon_width + @spacing_x) - @spacing_x
    @vertical_pitch = @icon_height + @text_label_height + @spacing_y	
    @menu_height = (@items.length / @n_icons.to_f).ceil * @vertical_pitch - @spacing_y

    @x_margin = (Graphics.width - @menu_width) / 2	
    @y_margin = (Graphics.height - @menu_height) / 2 + Y_ADJUSTMENT	

    @exit = false
    @last_time_string = ""
    @last_period_icon = nil
    @bob_frame = 0
    @selector_base_x = 0
    @last_mouse_x = 0
    @last_mouse_y = 0
  end

  #=============================================================================
  # CUSTOM TEXTBOX: pbDisplay (Restored)
  #=============================================================================
  def pbDisplay(message)
    # 1. Create a separate viewport on top of the menu
    msg_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    msg_viewport.z = 999999

    # 2. Setup Background (Uses 'speech2' graphic)
    msg_bg = IconSprite.new(0, 0, msg_viewport)
    msg_bg.setBitmap("Graphics/Windowskins/speech2")
    msg_bg.x = (Graphics.width - 792) / 2
    msg_bg.y = Graphics.height - 142 - 16

    # 3. Setup Text Layer
    msg_text = BitmapSprite.new(792, 142, msg_viewport)
    msg_text.x, msg_text.y = msg_bg.x, msg_bg.y
    
    # 4. Pre-Calculate Lines (No-Jumping Fix)
    line1 = message
    line2 = ""
    
    if message.length > 45
      cut_idx = message[0..45].rindex(' ') || 45
      line1 = message[0...cut_idx].strip
      line2 = message[cut_idx..-1].strip
    end
    
    total_len = line1.length + line2.length
    idx = 0
    timer = 0
    spd = [4, 2, 1, 0][$PokemonSystem.textspeed] || 2
    
    # 5. Typewriter Loop
    loop do
      Graphics.update
      Input.update
      
      if idx < total_len
        timer += 1
        if timer >= spd || spd == 0
          idx = (spd == 0) ? total_len : idx + 1
          timer = 0
          
          contents = msg_text.bitmap
          contents.clear
          pbSetSystemFont(contents)
          contents.font.size = 32
          
          # Draw Line 1
          visible_1 = (idx > line1.length) ? line1 : line1[0...idx]
          drawTextEx(contents, 32, 24, 728, 1, visible_1, Color.new(0,0,0), Color.new(0,0,0,0))
          
          # Draw Line 2
          if idx > line1.length
            visible_2 = line2[0...(idx - line1.length)]
            drawTextEx(contents, 32, 74, 728, 1, visible_2, Color.new(0,0,0), Color.new(0,0,0,0))
          end
        end
      end
      
      # Input Handling
      if Input.trigger?(Input::USE)
        if idx < total_len
          idx = total_len
        else
          pbSEPlay("GUI menu selection")
          break
        end
      elsif Input.trigger?(Input::BACK)
        if idx == total_len
          break
        end
      end
    end
    
    # 6. Cleanup
    msg_bg.dispose
    msg_text.dispose
    msg_viewport.dispose

    # 7. Ghost Input Fix (Prevents menu from reacting to the 'Enter' press immediately)
    (Graphics.frame_rate / 10).times do
      Graphics.update
      Input.update
    end
  end 

  def openPokedex
    if $player.has_pokedex
      scene = PokemonPokedex_Scene.new
      screen = PokemonPokedexScreen.new(scene)
      pbFadeOutIn { screen.pbStartScreen }
    else
      pbDisplay(_INTL("You don't have a Pokédex yet."))
    end
  end

  def openBag
    scene = PokemonBag_Scene.new
    screen = PokemonBagScreen.new(scene, $bag)
    item = nil
    pbFadeOutIn { item = screen.pbStartScreen }
    if item && item != 0; @item_to_use = item; @exit = true; end
  end

  def openParty
    if $player.party_count == 0
      pbDisplay(_INTL("You don't have any Pokémon."))
    else
      hidden_move = nil
      pbFadeOutIn do
        sscene = PokemonParty_Scene.new
        sscreen = PokemonPartyScreen.new(sscene, $player.party)
        hidden_move = sscreen.pbPokemonScreen
      end
      if hidden_move; @hidden_move_to_use = hidden_move; @exit = true; end
    end
  end

  def openTrainerCard
    scene = PokemonTrainerCard_Scene.new
    screen = PokemonTrainerCardScreen.new(scene)
    pbFadeOutIn { screen.pbStartScreen }
  end

  def openSave
    scene = PokemonSave_Scene.new
    screen = PokemonSaveScreen.new(scene)
    if screen.pbSaveScreen; @exit = true; end
  end

  def openOptions
    scene = PokemonOption_Scene.new
    screen = PokemonOptionScreen.new(scene)
    pbFadeOutIn { screen.pbStartScreen }
  end

  # ===========================================================================
  # SCENE DRAWING & LOGIC
  # ===========================================================================

  def getTimePeriodData
    current_hour = Time.now.hour
    if current_hour >= 5 && current_hour < 12
      return ["daytime_morning", "Morning"]
    elsif current_hour >= 12 && current_hour < 17
      return ["daytime_afternoon", "Afternoon"]
    elsif current_hour >= 17 && current_hour < 20
      return ["daytime_evening", "Evening"]
    else
      return ["daytime_night", "Night"]
    end
  end
  
  def clearTimeArea
    @sprites["time_overlay"].bitmap.clear
  end

  def drawIconLabels
    # Label order: Bag is index 1, Party is index 2
    text_labels = ["Pokédex", "Bag", "Party", "Trainer", "Save", "Options"]
    text_box_width = 188
    box_offset = (text_box_width - @icon_width) / 2	

    # Condition Order: Pokedex, Bag, Party, Trainer, Save, Options
    conditions = [
      $player.has_pokedex,                            
      ($bag && $bag.pockets.any?{|p| p.length > 0}), 
      $player.party_count > 0,                        
      true,                                           
      true,                                           
      true                                            
    ]

    @items.each_with_index do |item, counter|
      icon_x = @x_margin + ((@icon_width + @spacing_x) * (counter % @n_icons))
      icon_y = @y_margin + (@vertical_pitch * (counter / @n_icons))

      @sprites["item_#{counter}"] = Sprite.new(@viewport)
      @sprites["item_#{counter}"].bitmap = RPG::Cache.ui("Menu Custom/#{item[0]}")
      @sprites["item_#{counter}"].x = icon_x
      @sprites["item_#{counter}"].y = icon_y
      @sprites["item_#{counter}"].z = 101
      
      enabled = conditions[counter]
      item[3] = enabled 
      
      if !enabled
        @sprites["item_#{counter}"].tone = Tone.new(0, 0, 0, 255)
        @sprites["item_#{counter}"].opacity = 160
      end

      text_x = icon_x - box_offset
      case counter
      when 0; text_x -= 46
      when 1; text_x -= 72 # Bag offset
      when 2; text_x -= 62 # Party offset
      when 3; text_x -= 54
      when 4; text_x -= 64
      when 5; text_x -= 48
      end

      text_y = icon_y + @icon_height + 4
      @sprites["bg"].bitmap.font.name = ICON_FONT_NAME	    
      @sprites["bg"].bitmap.font.size = GLOBAL_FONT_SIZE
      @sprites["bg"].bitmap.font.color = enabled ? ICON_TEXT_COLOR : Color.new(150, 150, 150)
      @sprites["bg"].bitmap.draw_text(text_x, text_y, text_box_width, @text_label_height, text_labels[counter], 2)
    end
  end

  def drawTimeData
    overlay_bitmap = @sprites["time_overlay"].bitmap
    time_string = Time.now.strftime("%l:%M %p").strip	
    
    # --- FIX MAP NAME PLACEHOLDERS ---
    # We grab the current map name and replace the placeholders manually
    map_name = $game_map.name
    if map_name
      # 1. Replace \PN with Player Name
      map_name = map_name.gsub(/\\PN/, $player.name)
      
      # 2. Replace \v[n] with Variable Value
      map_name = map_name.gsub(/\\v\[(\d+)\]/) { $game_variables[$1.to_i] }
    end
    # ---------------------------------
    
    # Map Location text on the left
    overlay_bitmap.font.name = LOCATION_FONT_NAME
    overlay_bitmap.font.size = GLOBAL_FONT_SIZE
    overlay_bitmap.font.color = LOCATION_TEXT_COLOR
    overlay_bitmap.draw_text(120, 36, 600, 45, map_name, 0)
    
    icon_name, period_text = getTimePeriodData
    icon_x = Graphics.width - 100 

    # Vertical Stack: Time over Period text on the right
    overlay_bitmap.font.name = TIME_FONT_NAME	     
    overlay_bitmap.font.size = GLOBAL_FONT_SIZE
    overlay_bitmap.font.color = TIME_TEXT_COLOR
    overlay_bitmap.draw_text(icon_x - 300, 20, 270, 45, time_string, 2)
    
    overlay_bitmap.font.name = PERIOD_FONT_NAME	   
    overlay_bitmap.font.color = PERIOD_TEXT_COLOR
    overlay_bitmap.draw_text(icon_x - 300, 56, 270, 45, period_text, 2)
    
    @last_time_string = time_string
  end

  def updatePeriodIcon(icon_name)
    @sprites["period_icon"].x = Graphics.width - 100
    @sprites["period_icon"].y = 20
    if icon_name != @last_period_icon
      @sprites["period_icon"].bitmap = RPG::Cache.ui("Menu Custom/#{icon_name}")
      @last_period_icon = icon_name
    end
  end

  def isMouseOverIcon(index)
    sprite = @sprites["item_#{index}"]
    return false if !sprite
    mouse_x = Input.mouse_x
    mouse_y = Input.mouse_y
    return (mouse_x >= sprite.x && mouse_x < sprite.x + sprite.width && 
            mouse_y >= sprite.y && mouse_y < sprite.y + sprite.height)
  end

  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    @sprites["map_blur"] = Sprite.new(@viewport)
    @sprites["map_blur"].bitmap = Graphics.snap_to_bitmap
    @sprites["map_blur"].z = 99 
    
    bm = @sprites["map_blur"].bitmap
    small_bm = Bitmap.new(bm.width / 3, bm.height / 3)
    small_bm.stretch_blt(small_bm.rect, bm, bm.rect)
    4.times do
      temp_bm = small_bm.clone
      opacity = 128 
      small_bm.blt(2, 0, temp_bm, temp_bm.rect, opacity)
      small_bm.blt(-2, 0, temp_bm, temp_bm.rect, opacity)
      small_bm.blt(0, 2, temp_bm, temp_bm.rect, opacity)
      small_bm.blt(0, -2, temp_bm, temp_bm.rect, opacity)
      temp_bm.dispose
    end
    bm.clear
    bm.stretch_blt(bm.rect, small_bm, small_bm.rect)
    small_bm.dispose
    @sprites["map_blur"].color = Color.new(0, 0, 0, 80) 
	
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = RPG::Cache.ui("Menu Custom/menubg")
    @sprites["bg"].z = 100 
    
	@sprites["btn_back"] = IconSprite.new(16, 8, @viewport)
    @sprites["btn_back"].setBitmap("Graphics/UI/back")
    @sprites["btn_back"].z = 105
	
    @sprites["time_overlay"] = Sprite.new(@viewport)
    @sprites["time_overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["time_overlay"].z = 102 
    
    @sprites["period_icon"] = Sprite.new(@viewport)
    @sprites["period_icon"].z = 104

    drawIconLabels
    
    icon_name, _ = getTimePeriodData
    drawTimeData
    updatePeriodIcon(icon_name)

    @sprites["selector"] = Sprite.new(@viewport)
    @sprites["selector"].bitmap = RPG::Cache.ui("Menu Custom/menu_selection")
    
    # --- AUTO-SELECT FIRST ENABLED ICON ---
    # Scans @items (which now has the [3] enabled/disabled flag from drawIconLabels)
    @selected_item = 0
    @items.each_with_index do |item, i|
      if item[3] # If this item is enabled
        @selected_item = i
        break
      end
    end

    redrawSelector
    @sprites["selector"].z = 99999
    
    @last_mouse_x = Input.mouse_x
    @last_mouse_y = Input.mouse_y
    
    pbSEPlay("GUI menu open")
  end

  def pbRefresh
    current_time_string = Time.now.strftime("%l:%M %p").strip
    icon_name, _ = getTimePeriodData
    if current_time_string != @last_time_string || icon_name != @last_period_icon
      clearTimeArea
      drawTimeData
      updatePeriodIcon(icon_name)
    end
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport
  end

  def redrawSelector
    icon_base_x = @x_margin + ((@icon_width + @spacing_x) * (@selected_item % @n_icons))
    @selector_base_x = icon_base_x - 32
    @sprites["selector"].x = @selector_base_x
    @sprites["selector"].y = @y_margin + (@vertical_pitch * (@selected_item / @n_icons))
  end

  def addCmd(item)
    @items.push(item).length - 1
  end

  def pbUpdate
    Input.update 
    loop do
      pbRefresh
      moved = false
      current_mouse_x, current_mouse_y = Input.mouse_x, Input.mouse_y
      
      if current_mouse_x != @last_mouse_x || current_mouse_y != @last_mouse_y
        @items.each_with_index do |item, i|
          if isMouseOverIcon(i) && item[3] # Only hover if enabled
            if @selected_item != i
              @selected_item = i
              pbSEPlay("GUI sel cursor")
              redrawSelector
            end
            break 
          end
        end
        @last_mouse_x, @last_mouse_y = current_mouse_x, current_mouse_y
      end

      @bob_frame += CURSOR_BOB_SPEED
      @sprites["selector"].x = @selector_base_x + (Math.sin(@bob_frame) * CURSOR_BOB_RANGE).to_i

      if Input.trigger?(Input::RIGHT)
        old_sel = @selected_item
        loop do
          @selected_item = (@selected_item + 1) % @items.length
          break if @items[@selected_item][3] || @selected_item == old_sel
        end
        moved = true if @selected_item != old_sel
      elsif Input.trigger?(Input::LEFT)
        old_sel = @selected_item
        loop do
          @selected_item = (@selected_item - 1 + @items.length) % @items.length
          break if @items[@selected_item][3] || @selected_item == old_sel
        end
        moved = true if @selected_item != old_sel
      end
      
      if moved
        pbSEPlay("GUI sel cursor")
        redrawSelector
      end

      if Input.trigger?(Input::C)
        if @items[@selected_item][3]
          pbSEPlay("GUI sel decision")
          send(@items[@selected_item][2]) # Now calls openTrainerCard correctly
        else
          pbSEPlay("GUI sel buzzer")
        end
      end

      if Input.trigger?(Input::MOUSELEFT)
        clicked_index = -1
        @items.each_with_index { |item, i| (clicked_index = i; break) if isMouseOverIcon(i) && item[3] }
        
        if clicked_index >= 0
           @selected_item = clicked_index
           redrawSelector
           pbSEPlay("GUI sel decision")
           send(@items[@selected_item][2])
        # --- UPDATED: Back Button Click (16,16 Size 96x96) ---
        elsif Input.mouse_x >= 16 && Input.mouse_x <= 112 &&
              Input.mouse_y >= 8 && Input.mouse_y <= 112
           pbSEPlay("GUI sel cancel")
           @exit = true
           break
        # -----------------------------------------------------
        elsif Input.mouse_x > Graphics.width - 150 && Input.mouse_y > Graphics.height - 50
           pbSEPlay("GUI sel cancel"); break 
        end
      end

      break if Input.trigger?(Input::B) || @exit
      Graphics.update
      Input.update 
    end
  end
end

def pbCallMenu2
  scene = Menu2.new
  scene.pbStartScene
  scene.pbUpdate
  item = scene.item_to_use 
  h_move = scene.hidden_move_to_use
  scene.pbEndScene
  if item && item != 0
    $game_temp.in_menu = false 
    if ItemHandlers.hasOutHandler(item) || ItemHandlers.hasUseInFieldHandler(item)
      ItemHandlers.triggerUseInField(item)
    else
      pbUseItem($bag, item)
    end
  elsif h_move
    $game_temp.in_menu = false 
    pbUseHiddenMove(h_move[0], h_move[1])
  end
end