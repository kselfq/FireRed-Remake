#===============================================================================
# Modern Text Entry - Final Version (1600x720)
# Updates:
# 1. CHARACTER ANIMATION: Subject sprite now bobs Up/Down gently.
# 2. PREVIOUS FIXES: Colors, Arrow Logic, Mouse Support, Transparency retained.
# 3. Z-INDEX FIX: Viewport Z forced to 9999999 to cover Battle Message Box.
#===============================================================================
class PokemonEntryScene_Modern < PokemonEntryScene2
  # ----------------------------------------------------------------------------
  # CONFIGURATION
  # ----------------------------------------------------------------------------
  KEY_WIDTH    = 76
  KEY_HEIGHT   = 62
  KEY_GAP      = 6
  START_Y      = 240
  
  # --- MANUAL ARROW ADJUSTMENT ---
  ARROW_OFFSET_X = -46
  ARROW_OFFSET_Y = 62
  
  # ----------------------------------------------------------------------------
  # CONSTANTS
  # ----------------------------------------------------------------------------
  KEY_SHIFT    = "\x01"
  KEY_DELETE   = "\x02"
  KEY_SPACE    = "\x03"
  KEY_EMPTY    = "\x04"
  
  MODE_UPPER   = 0
  MODE_LOWER   = 1
  MODE_OTHERS  = 2
  
  BTN_TAB1     = 100
  BTN_TAB2     = 101
  BTN_TAB3     = 102
  BTN_SPACE    = 103
  BTN_OK       = 104
  BTN_DEL_BTM  = 105
  BTN_EXIT     = 106

  # ----------------------------------------------------------------------------
  # CHARACTER MAPPINGS
  # ----------------------------------------------------------------------------
  UPPER_CHARS = [
    ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", KEY_DELETE], 
    ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}"], 
    ["A", "S", "D", "F", "G", "H", "J", "K", "L", ":", "\"", "_"],     
    [KEY_SHIFT, "Z", "X", "C", "V", "B", "N", "M", "<", ">", KEY_SHIFT] 
  ]

  LOWER_CHARS = [
    ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", KEY_DELETE], 
    ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "(", ")"], 
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "-"],
    [KEY_SHIFT, "z", "x", "c", "v", "b", "n", "m", ",", ".", KEY_SHIFT]
  ]

  OTHER_CHARS = [
    ["\"", "'", ",", ".", "?", "♀", "(", ")", ":", ";", "!", "?"], 
    ["…", "•", "~", "#", "%", "+", "-", "*", "/", "=", "♂", "$"],         
    ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "[", "]"],          
    ["<", ">", "^", "@", "&", "{", "}", "_", "|", "\\", "€", "£"]         
  ]

  # ----------------------------------------------------------------------------
  # HELPER: Drawing
  # ----------------------------------------------------------------------------
  def stroke_rect(bitmap, rect, color)
    bitmap.fill_rect(rect.x, rect.y, rect.width, 2, color) 
    bitmap.fill_rect(rect.x, rect.y + rect.height - 2, rect.width, 2, color) 
    bitmap.fill_rect(rect.x, rect.y, 2, rect.height, color) 
    bitmap.fill_rect(rect.x + rect.width - 2, rect.y, 2, rect.height, color) 
  end

  # ----------------------------------------------------------------------------
  # MAIN CLASS SETUP
  # ----------------------------------------------------------------------------
  def pbStartScene(helptext, minlength, maxlength, initialText, subject = 0, pokemon = nil)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 9999999 # <--- INCREASED Z-INDEX TO FORCIBLY COVER MESSAGE BOX
    
    @helptext = helptext
    @helper = CharacterEntryHelper.new(initialText)
    @minlength = minlength
    @maxlength = maxlength
    @mode = (@helper.text.length > 0) ? MODE_LOWER : MODE_UPPER
    
    @temp_shift = false 
    @anim_timer = 0

    center_x = Graphics.width / 2
    full_grid_width = (12 * (KEY_WIDTH + KEY_GAP)) - KEY_GAP
    @kb_start_x = center_x - (full_grid_width / 2)
    @kb_end_x   = center_x + (full_grid_width / 2)

    @bitmaps = []
    [MODE_UPPER, MODE_LOWER, MODE_OTHERS].each do |m|
      bmp = Bitmap.new(Graphics.width, Graphics.height)
      pbSetSystemFont(bmp)
      draw_tab_layout(bmp, m)
      @bitmaps[m] = bmp
    end
    
    underline = Bitmap.new(40, 4)
    underline.fill_rect(0, 0, 40, 4, Color.new(255, 255, 255)) 
    @bitmaps.push(underline)

    @sprites = {}
    
    @sprites["bg"] = IconSprite.new(0, 0, @viewport)
    if pbResolveBitmap("Graphics/UI/Naming/bg_modern")
      @sprites["bg"].setBitmap("Graphics/UI/Naming/bg_modern")
      @sprites["bg"].zoom_x = Graphics.width.to_f / @sprites["bg"].bitmap.width
      @sprites["bg"].zoom_y = Graphics.height.to_f / @sprites["bg"].bitmap.height
    end

    @blanks = []
    input_start_x = @kb_end_x - (@maxlength * 50)
    
    # --- SUBJECT SPRITES ---
    sprite_x = input_start_x - 72 
    sprite_y = 120 
    
    @sprites["subject"] = Sprite.new(@viewport)
    case subject
    when 1   # Player
      fname = ($player.female?) ? "input_female" : "input_male"
      @sprites["subject"].bitmap = Bitmap.new("Graphics/Characters/#{fname}")
    when 2   # Pokémon
      if pokemon
        @sprites["subject"] = PokemonIconSprite.new(pokemon, @viewport)
        @sprites["subject"].setOffset(PictureOrigin::CENTER)
      end
    when 3   # Rival
      @sprites["subject"].bitmap = Bitmap.new("Graphics/Characters/input_rival")
    when 4   # Storage Box
      @sprites["subject"].bitmap = Bitmap.new("Graphics/UI/Naming/icon_storage")
    end

    if @sprites["subject"].bitmap
      @sprites["subject"].x = sprite_x
      @sprites["subject"].y = sprite_y
      
      # Force Static Frame (Top-Left 64x64)
      if subject != 2 
        @sprites["subject"].src_rect.set(0, 0, 64, 64)
        @sprites["subject"].ox = 32
        @sprites["subject"].oy = 32
      end
      
      @sprites["subject"].zoom_x = 1.0
      @sprites["subject"].zoom_y = 1.0
    end

    @maxlength.times do |i|
      @sprites["blank#{i}"] = Sprite.new(@viewport)
      @sprites["blank#{i}"].bitmap = @bitmaps.last
      @sprites["blank#{i}"].x = input_start_x + (50 * i)
      @sprites["blank#{i}"].y = 132
      @sprites["blank#{i}"].opacity = 100 
      @blanks[i] = 0
    end

    @sprites["layout"] = Sprite.new(@viewport)
    @sprites["layout"].bitmap = @bitmaps[@mode]

    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbUpdateOverlay

    @sprites["cursor"] = Sprite.new(@viewport)
    @sprites["cursor"].bitmap = nil 
    @cursor_rect = Sprite.new(@viewport) 
    @cursor_rect.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    
    @sprites["sel_arrow"] = Sprite.new(@viewport)
    if pbResolveBitmap("Graphics/UI/sel_arrow")
      @sprites["sel_arrow"].bitmap = Bitmap.new("Graphics/UI/sel_arrow")
      @sprites["sel_arrow"].ox = @sprites["sel_arrow"].bitmap.width / 2
      @sprites["sel_arrow"].oy = @sprites["sel_arrow"].bitmap.height
    end
    
    @cursor_idx = 0 
    @anim_timer = 0
    update_cursor_graphic
    
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  # ----------------------------------------------------------------------------
  # DRAWING
  # ----------------------------------------------------------------------------
  def draw_tab_layout(bitmap, mode)
    # Colors
    color_std_key   = Color.new(99, 95, 177, 220)    # Dark
    color_ctrl_key  = Color.new(99, 95, 177, 220)    # Teal
    border_color    = Color.new(183, 207, 92, 220)   # Cyan
    key_text_color     = Color.new(0, 0, 0)
    control_text_color = Color.new(255, 255, 255)
    col_active_fill = Color.new(0, 200, 220)     
    col_active_text = Color.new(0, 0, 0)         

    (0..47).each do |i|
      char = get_char_at(mode, i)
      next if char == KEY_EMPTY || char.nil?
      
      rect = get_key_rect(mode, i)
      is_special = (char == KEY_SHIFT || char == KEY_DELETE)
      fill_col = is_special ? color_ctrl_key : color_std_key
      
      bitmap.fill_rect(rect, fill_col)
      bitmap.fill_rect(rect.x+2, rect.y+2, rect.width-4, rect.height-4, Color.new(0,0,0,8)) 
      stroke_rect(bitmap, rect, border_color)
      
      display_text = char
      display_text = "Shift" if char == KEY_SHIFT
      display_text = "Delete" if char == KEY_DELETE
      
      pbDrawTextPositions(bitmap, [
        [display_text, rect.x + (rect.width/2), rect.y + (rect.height/2) - 12, :center, key_text_color, nil]
      ])
    end
    
    [BTN_TAB1, BTN_TAB2, BTN_TAB3, BTN_SPACE, BTN_OK, BTN_DEL_BTM].each do |btn|
      rect = get_control_rect(mode, btn)
      next if rect.width == 0 
      
      is_active_tab = (mode == MODE_UPPER && btn == BTN_TAB1) || (mode == MODE_LOWER && btn == BTN_TAB2) || (mode == MODE_OTHERS && btn == BTN_TAB3)
      bg = is_active_tab ? border_color : color_ctrl_key
      
      bitmap.fill_rect(rect, bg)
      stroke_rect(bitmap, rect, border_color)
      
      label = ""
      case btn
      when BTN_TAB1 then label = "UPPER"
      when BTN_TAB2 then label = "lower"
      when BTN_TAB3 then label = "Others"
      when BTN_SPACE then label = "Space"
      when BTN_OK   then label = "OK"
      when BTN_DEL_BTM then label = "Delete"
      end
      
      pbDrawTextPositions(bitmap, [
        [label, rect.x + (rect.width/2), rect.y + (rect.height/2) - 12, :center, control_text_color, nil]
      ])
    end
  end

  # ----------------------------------------------------------------------------
  # RECT CALCULATION
  # ----------------------------------------------------------------------------
  def get_key_rect(mode, index)
    center_x = Graphics.width / 2
    full_grid_width = (12 * (KEY_WIDTH + KEY_GAP)) - KEY_GAP
    start_x = center_x - (full_grid_width / 2)
    row = index / 12; col = index % 12
    x = 0; y = START_Y + (row * (KEY_HEIGHT + KEY_GAP)); w = KEY_WIDTH; h = KEY_HEIGHT
    
    if mode == MODE_OTHERS
      x = start_x + (col * (KEY_WIDTH + KEY_GAP))
    else
      if row == 0
        if col < 10; x = start_x + (col * (KEY_WIDTH + KEY_GAP)); else; x = start_x + (10 * (KEY_WIDTH + KEY_GAP)); w = (KEY_WIDTH * 2) + KEY_GAP; end
      elsif row == 1 || row == 2
        x = start_x + (col * (KEY_WIDTH + KEY_GAP))
      elsif row == 3
        shift_w = (KEY_WIDTH * 1.5).to_i
        if col == 0; x = start_x; w = shift_w; elsif col >= 1 && col <= 9; x = start_x + shift_w + KEY_GAP + ((col - 1) * (KEY_WIDTH + KEY_GAP)); w = KEY_WIDTH; elsif col >= 10; middle_section_width = 9 * (KEY_WIDTH + KEY_GAP); prev_x_end = start_x + shift_w + KEY_GAP + middle_section_width - KEY_GAP; x = prev_x_end + KEY_GAP; w = (start_x + full_grid_width) - x; end
      end
    end
    return Rect.new(x, y, w, h)
  end

  def get_control_rect(mode, btn_id)
    center_x = Graphics.width / 2
    full_grid_width = (12 * (KEY_WIDTH + KEY_GAP)) - KEY_GAP
    start_x = center_x - (full_grid_width / 2)
    y = START_Y + (4 * (KEY_HEIGHT + KEY_GAP)) + 10
    tab_w = 100; gap = KEY_GAP; ok_w = 160; ok_x = start_x + full_grid_width - ok_w
    rect = Rect.new(0,0,0,0)
    case btn_id
    when BTN_TAB1; rect.set(start_x, y, tab_w, KEY_HEIGHT)
    when BTN_TAB2; rect.set(start_x + tab_w + gap, y, tab_w, KEY_HEIGHT)
    when BTN_TAB3; rect.set(start_x + (tab_w + gap)*2, y, tab_w, KEY_HEIGHT)
    when BTN_OK;   rect.set(ok_x, y, ok_w, KEY_HEIGHT)
    when BTN_DEL_BTM; if mode == MODE_OTHERS; del_w = 120; del_x = ok_x - gap - del_w; rect.set(del_x, y, del_w, KEY_HEIGHT); else; rect.set(0,0,0,0); end
    when BTN_SPACE; space_x = start_x + (tab_w + gap)*3; if mode == MODE_OTHERS; del_w = 120; del_x = ok_x - gap - del_w; space_w = del_x - gap - space_x; else; space_w = ok_x - gap - space_x; end; rect.set(space_x, y, space_w, KEY_HEIGHT)
    when BTN_EXIT; rect.set(Graphics.width - 142, Graphics.height - 46, 142, 46)
    end
    return rect
  end

  def get_char_at(mode, index)
    row = index / 12; col = index % 12; arr = []
    case mode
    when MODE_UPPER then arr = UPPER_CHARS
    when MODE_LOWER then arr = LOWER_CHARS
    when MODE_OTHERS then arr = OTHER_CHARS
    end
    if mode == MODE_OTHERS; return arr[row][col] rescue nil; end
    row_data = arr[row]; return nil if row_data.nil?
    if row == 0; if col < 10; return row_data[col]; elsif col >= 10; return row_data[10]; end
    elsif row == 1 || row == 2; return row_data[col]
    elsif row == 3; if col == 0; return row_data[0]; elsif col >= 1 && col <= 9; return row_data[col]; elsif col >= 10; return row_data[10]; end
    end
    return nil
  end

  # ----------------------------------------------------------------------------
  # MOUSE & UPDATE
  # ----------------------------------------------------------------------------
  def get_id_at_mouse
    mx, my = Input.mouse_x, Input.mouse_y
    (0..47).each do |i|; rect = get_key_rect(@mode, i); return i if rect_contains?(rect, mx, my); end
    [BTN_TAB1, BTN_TAB2, BTN_TAB3, BTN_SPACE, BTN_OK, BTN_DEL_BTM, BTN_EXIT].each do |btn|
      rect = get_control_rect(@mode, btn)
      return btn if rect_contains?(rect, mx, my)
    end
    return nil
  end

  def rect_contains?(rect, x, y)
    return x >= rect.x && x < rect.x + rect.width && y >= rect.y && y < rect.y + rect.height
  end

  def update_cursor_graphic
    @cursor_rect.bitmap.clear
    return if @cursor_idx == BTN_EXIT
    
    rect = (@cursor_idx < 100) ? get_key_rect(@mode, @cursor_idx) : get_control_rect(@mode, @cursor_idx)
    center_key = rect.x + (rect.width / 2)
    @arrow_target_x = center_key + ARROW_OFFSET_X
    @arrow_target_y = rect.y + ARROW_OFFSET_Y
    color = Color.new(241, 192, 65, 255)
    (0..2).each do |i|; r = Rect.new(rect.x-i, rect.y-i, rect.width+(i*2), rect.height+(i*2)); stroke_rect(@cursor_rect.bitmap, r, color); end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    @anim_timer += 1
    
    # 1. Selection Box Pulse
    alpha = 150 + (Math.sin(@anim_timer / 20.0).abs * 105).to_i
    @cursor_rect.opacity = alpha
    
    # 2. Arrow Bobbing
    if @sprites["sel_arrow"] && @arrow_target_x && @cursor_idx != BTN_EXIT
      bob_offset = (Math.sin(@anim_timer / 4.0) * 5).round
      @sprites["sel_arrow"].x = @arrow_target_x + bob_offset
      @sprites["sel_arrow"].y = @arrow_target_y
      @sprites["sel_arrow"].visible = true
    else
      @sprites["sel_arrow"].visible = false if @sprites["sel_arrow"]
    end
    
    # 3. Character Bobbing (Up/Down)
    if @sprites["subject"]
      # Gentle +/- 4px bob, centered at 120
      char_bob = (Math.sin(@anim_timer / 4.0) * 5).round
      @sprites["subject"].y = 120 + char_bob
    end
    
    # 4. Mouse Hover
    if Input.mouse_x != @last_mouse_x || Input.mouse_y != @last_mouse_y
      @last_mouse_x = Input.mouse_x; @last_mouse_y = Input.mouse_y
      new_idx = get_id_at_mouse
      if new_idx && new_idx != @cursor_idx && new_idx != BTN_EXIT
        if new_idx >= 100 || (get_char_at(@mode, new_idx) != KEY_EMPTY)
          @cursor_idx = new_idx
          pbPlayCursorSE
          update_cursor_graphic
        end
      end
    end
  end

  def pbEntry
    loop do
      Graphics.update
      Input.update
      pbUpdate
      # Note: Removed standard 'update' on subject to prevent frame cycling/walking
      
      if Input.trigger?(Input::MOUSELEFT)
        clicked_idx = get_id_at_mouse
        if clicked_idx
          if clicked_idx == BTN_EXIT
            pbPlayCancelSE
            @ret_value = nil 
            break
          elsif clicked_idx == @cursor_idx
            handle_input
          end
        end
      elsif Input.trigger?(Input::LEFT) || Input.repeat?(Input::LEFT); move_cursor(-1, 0); update_cursor_graphic; 
      elsif Input.trigger?(Input::RIGHT) || Input.repeat?(Input::RIGHT); move_cursor(1, 0); update_cursor_graphic; 
      elsif Input.trigger?(Input::UP) || Input.repeat?(Input::UP); move_cursor(0, -1); update_cursor_graphic; 
      elsif Input.trigger?(Input::DOWN) || Input.repeat?(Input::DOWN); move_cursor(0, 1); update_cursor_graphic; 
      elsif Input.trigger?(Input::USE); handle_input; 
      elsif Input.trigger?(Input::BACK); @helper.delete; pbPlayCancelSE; pbUpdateOverlay; 
      end
      break if @ret_value
    end
    return @ret_value
  end

  def move_cursor(x_dir, y_dir); pbPlayCursorSE; if x_dir != 0; if @cursor_idx >= 100; controls = [BTN_TAB1, BTN_TAB2, BTN_TAB3, BTN_SPACE]; controls << BTN_DEL_BTM if @mode == MODE_OTHERS; controls << BTN_OK; curr_i = controls.index(@cursor_idx); new_i = (curr_i + x_dir) % controls.length; @cursor_idx = controls[new_i]; else; curr_row = @cursor_idx / 12; curr_col = @cursor_idx % 12; loop do; curr_col = (curr_col + x_dir) % 12; @cursor_idx = (curr_row * 12) + curr_col; char = get_char_at(@mode, @cursor_idx); break if char && char != KEY_EMPTY; end; end; end; if y_dir != 0; if @cursor_idx >= 100 && y_dir < 0; @cursor_idx = 42; elsif @cursor_idx < 100 && y_dir > 0 && (@cursor_idx / 12) == 3; @cursor_idx = BTN_SPACE; elsif @cursor_idx < 100; @cursor_idx += (y_dir * 12); @cursor_idx %= 48; end; end; end

  def handle_input; char = nil; is_special = false; if @cursor_idx < 100; char = get_char_at(@mode, @cursor_idx); else; is_special = true; case @cursor_idx; when BTN_TAB1 then change_mode(MODE_UPPER); when BTN_TAB2 then change_mode(MODE_LOWER); when BTN_TAB3 then change_mode(MODE_OTHERS); when BTN_SPACE; char = " "; is_special = false; when BTN_OK; confirm_text; when BTN_DEL_BTM; delete_text; end; end; if char == KEY_SHIFT; new_m = (@mode == MODE_UPPER) ? MODE_LOWER : MODE_UPPER; change_mode(new_m); @temp_shift = !@temp_shift; return; elsif char == KEY_DELETE; delete_text; return; end; if char && !is_special; if @helper.length < @maxlength; @helper.insert(char); pbPlayDecisionSE; pbUpdateOverlay; if @helper.text.length == 1 && @mode == MODE_UPPER; change_mode(MODE_LOWER); end; if @temp_shift; revert_mode = (@mode == MODE_UPPER) ? MODE_LOWER : MODE_UPPER; change_mode(revert_mode); @temp_shift = false; end; else; pbPlayBuzzerSE; end; end; end
  
  def change_mode(new_mode); @mode = new_mode; @sprites["layout"].bitmap = @bitmaps[@mode]; pbPlayDecisionSE; if @cursor_idx == BTN_DEL_BTM && @mode != MODE_OTHERS; @cursor_idx = BTN_SPACE; end; update_cursor_graphic; end
  
  def delete_text; @helper.delete; pbPlayCancelSE; pbUpdateOverlay; if @helper.text.length == 0 && @mode != MODE_UPPER; change_mode(MODE_UPPER); end; end
  def confirm_text; if @helper.length >= @minlength; pbSEPlay("GUI naming confirm"); @ret_value = @helper.text; else; pbPlayBuzzerSE; end; end

  def pbUpdateOverlay; bgoverlay = @sprites["overlay"].bitmap; bgoverlay.clear; pbSetSystemFont(bgoverlay); textPositions = [[@helptext, @kb_start_x, 100, :left, Color.new(248, 248, 248), nil]]; chars = @helper.textChars; input_start_x = @kb_end_x - (@maxlength * 50); chars.each_with_index do |ch, i|; x = input_start_x + (50 * i) + 25; textPositions.push([ch, x, 100, :center, Color.new(248, 248, 248), nil]); end; pbDrawTextPositions(bgoverlay, textPositions); end
end