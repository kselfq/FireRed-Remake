def pbEmergencySave
  oldscene = $scene
  $scene = nil
  pbMessage(_INTL("The script is taking too long. The game will restart."))
  return if !$player
  if SaveData.exists?
    File.open(SaveData::FILE_PATH, "rb") do |r|
      File.open(SaveData::FILE_PATH + ".bak", "wb") do |w|
        loop do
          s = r.read(4096)
          break if !s
          w.write(s)
        end
      end
    end
  end
  if Game.save
    pbDisplay("\\se[]" + _INTL("The game was saved.") + "\\me[GUI save game]\\wtnp[20]")
    pbDisplay("\\se[]" + _INTL("The previous save file has been backed up.") + "\\wtnp[20]")
  else
    pbDisplay("\\se[]" + _INTL("Save failed.") + "\\wtnp[30]")
  end
  $scene = oldscene
end

#===============================================================================
# Load Screen class for plugin compatibility
#===============================================================================
class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
    @save_data = SaveData.exists? ? SaveData.read_from_file(SaveData::FILE_PATH) : {}
  end
end

#===============================================================================
# Save Scene logic
#===============================================================================
class PokemonSave_Scene
  attr_reader :viewport
  attr_reader :sprites

  LOCATION_TEXT_BASE   = Color.new(161, 83, 34)
  LOCATION_TEXT_SHADOW = Color.new(192, 32, 40, 0)
  VALUE_TEXT_BASE      = Color.new(55, 25, 1)
  VALUE_TEXT_SHADOW    = Color.new(192, 32, 40, 0)

  def pbStartScreen
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    
    @sprites["info_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["info_overlay"].z = 100
    pbSetSystemFont(@sprites["info_overlay"].bitmap)
    @sprites["info_overlay"].bitmap.font.size = 32
    
    draw_info_text
  end

  def draw_info_text
    bitmap = @sprites["info_overlay"].bitmap
    bitmap.clear
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time_text = sprintf("%02d:%02d", hour, min)
    money_text = $player.money.to_s_formatted
    
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
    
	# X and Y positions
    left_x  = 594 + 140
    right_x = 1080 + 140
    y_pos   = 90 + 60
    line_gap = 60

    stats = [
      [map_name, left_x, y_pos + 10, 0, LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW],
      [_INTL("Name"), left_x, y_pos + 65, 0, LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW],
      [$player.name, right_x, y_pos + 65, 1, VALUE_TEXT_BASE, VALUE_TEXT_SHADOW],
      [_INTL("Money"), left_x, y_pos + 65 + line_gap, 0, LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW],
      [_INTL("${1}", money_text), right_x, y_pos + 65 + line_gap, 1, VALUE_TEXT_BASE, VALUE_TEXT_SHADOW],
      [_INTL("Play time"), left_x, y_pos + 65 + line_gap*2, 0, LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW],
      [time_text, right_x, y_pos + 65 + line_gap*2, 1, VALUE_TEXT_BASE, VALUE_TEXT_SHADOW],
      [_INTL("Badges"), left_x, y_pos + 65 + line_gap*3, 0, LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW],
      [$player.badge_count.to_s, right_x, y_pos + 65 + line_gap*3, 1, VALUE_TEXT_BASE, VALUE_TEXT_SHADOW]
    ]
    
    # --- HIDDEN POKEDEX INFO ---
    # if $player.has_pokedex
    #   stats.push([_INTL("Pokédex"), left_x, y_pos + 65 + line_gap*4, 0, LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW])
    #   stats.push([$player.pokedex.owned_count.to_s + "/" + $player.pokedex.seen_count.to_s, right_x, y_pos + 65 + line_gap*4, 1, VALUE_TEXT_BASE, VALUE_TEXT_SHADOW])
    # end
    # ---------------------------
    pbDrawTextPositions(bitmap, stats)
  end

  def pbEndScreen
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport
  end
end

#===============================================================================
# Save Screen Logic
#===============================================================================
class PokemonSaveScreen
  CURSOR_BOB_SPEED = 0.2  
  CURSOR_BOB_RANGE = 12   
  PLAYER_ANIM_SPEED = 3   

  def initialize(scene)
    @scene = scene
  end

  def pbConfirmMessage(message)
    view = @scene.viewport
    msgwindow = pbCreateMessageWindow(view, "Graphics/Windowskins/speech rs")
    msgwindow.text = "<fs=38>" + message + "</fs>"
    ret = pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 1)
    pbDisposeMessageWindow(msgwindow)
    return ret == 0
  end
  
  def pbConfirmMessageSerious(message)
    return pbConfirmMessage(message)
  end

  # =========================================================================
  # MOUSE SUPPORT HELPERS
  # =========================================================================
  def isMouseOverButton(window)
    return false if !window || window.disposed?
    mx, my = Input.mouse_x, Input.mouse_y
    return (mx >= window.x && mx < window.x + window.width &&
            my >= window.y && my < window.y + window.height)
  end
  
  def pbSaveScreen
    ret = false
    @scene.pbStartScreen
    view = @scene.viewport
	
    blur_sprite = Sprite.new(view)
    blur_sprite.bitmap = Graphics.snap_to_bitmap
    blur_sprite.z = -10 
    bm = blur_sprite.bitmap
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
    blur_sprite.color = Color.new(0, 0, 0, 80)
	
    background = Sprite.new(view)
    background.bitmap = Bitmap.new("Graphics/UI/save_bg")
    background.z = 0 
	
    player_sprite = Sprite.new(view)
    player_sprite.bitmap = Bitmap.new($player.male? ? "Graphics/Pictures/introBoy" : "Graphics/Pictures/introGirl")
    player_sprite.z = 5 
    
    frames_count = 12      
    frame_width  = player_sprite.bitmap.width / frames_count
    frame_height = player_sprite.bitmap.height
    
    pause_time    = 80                   
    play_duration = frames_count * PLAYER_ANIM_SPEED 
    total_cycle   = play_duration + pause_time	
    
    player_sprite.src_rect.set(0, 0, frame_width, frame_height)
    player_sprite.x, player_sprite.y = 120, 100 
	
    save_btn = Window_AdvancedTextPokemon.new("")
    save_btn.viewport, save_btn.width, save_btn.height = view, 720, 44
    back_btn = Window_AdvancedTextPokemon.new("")
    back_btn.viewport, back_btn.width, back_btn.height = view, 720, 44
    
    back_btn.x = (Graphics.width - back_btn.width) / 2
    back_btn.y = Graphics.height - back_btn.height - 76 
    save_btn.x = back_btn.x
    save_btn.y = back_btn.y - save_btn.height - 14 

    text_overlay = BitmapSprite.new(Graphics.width, Graphics.height, view)
    text_overlay.z = save_btn.z + 10
    pbSetSystemFont(text_overlay.bitmap)
    text_overlay.bitmap.font.size = 32
    
    def self.draw_save_buttons(overlay, s_btn, b_btn)
      overlay.bitmap.clear
      base = Color.new(0, 0, 0)
      textpos = [
         [_INTL("Save your progress"), s_btn.x + 360, s_btn.y + 4, 2, base, nil],
         [_INTL("Back to your adventure"), b_btn.x + 360, b_btn.y + 4, 2, base, nil]
      ]
      pbDrawTextPositions(overlay.bitmap, textpos)
    end
    
    self.draw_save_buttons(text_overlay, save_btn, back_btn)

    cursor = Sprite.new(view)
    cursor.bitmap = Bitmap.new("Graphics/UI/sel_arrow")
    cursor.z = 999999 

    # --- POSITIONED 16PX FROM BOTTOM ---
    msg_bg = IconSprite.new(0, 0, view)
    msg_bg.setBitmap("Graphics/Windowskins/speech2")
    msg_bg.x = (Graphics.width - 792) / 2
    msg_bg.y = Graphics.height - 142 - 16 # Exactly 16 pixels from bottom
    msg_bg.z = 1000000
    msg_bg.visible = false

    msg_text = BitmapSprite.new(792, 142, view)
    msg_text.x, msg_text.y, msg_text.z = msg_bg.x, msg_bg.y, msg_bg.z + 1
    msg_text.visible = false

    # Updated proc with auto_close functionality
    draw_save_msg = proc do |message, auto_close = false|
      msg_bg.visible = true
      msg_text.visible = true
      full_msg = message
      draw_char_index = 0
      draw_timer = 0
      hold_timer = 0
      frames_per_char = [4, 2, 1, 0][$PokemonSystem.textspeed] || 2
      
      loop do
        Graphics.update
        Input.update
        
        # --- TYPING LOGIC ---
        if draw_char_index < full_msg.length
          if frames_per_char == 0
            draw_char_index = full_msg.length
          else
            draw_timer += 1
            if draw_timer >= frames_per_char
              draw_char_index += 1
              draw_timer = 0
            end
          end
          contents = msg_text.bitmap
          contents.clear
          pbSetSystemFont(contents) 
          contents.font.size = 38
          base_c, shad_c = Color.new(0,0,0), Color.new(0,0,0,0)
          
          current_reveal = full_msg[0...draw_char_index]
          msg_lines = []
          if current_reveal.length > 50
            cut_idx = full_msg[0..50].rindex(' ') || 50
            msg_lines[0] = current_reveal[0...cut_idx].strip
            msg_lines[1] = current_reveal[cut_idx..-1].strip if current_reveal.length > cut_idx
          else
            msg_lines[0] = current_reveal
          end
          
          drawTextEx(contents, 20, 22, 728, 1, msg_lines[0], base_c, shad_c) if msg_lines[0]
          drawTextEx(contents, 20, 79, 728, 1, msg_lines[1], base_c, shad_c) if msg_lines[1]
        end
        
        # --- AUTO EXIT LOGIC (3 Seconds) ---
        if auto_close && draw_char_index >= full_msg.length
           hold_timer += 1
           # Wait 3 seconds (approx 3 * Graphics.frame_rate)
           if hold_timer >= (Graphics.frame_rate * 1)
             break
           end
           # Skip standard input checks so mouse/keys are ignored
           next 
        end
        
        # --- STANDARD INPUT LOGIC (Only if NOT auto_close) ---
        if !auto_close
          if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK) || Input.trigger?(Input::MOUSELEFT)
            if draw_char_index < full_msg.length
              draw_char_index = full_msg.length
            else
              break
            end
          end
        end
      end
      msg_bg.visible = false
      msg_text.visible = false
    end

    begin
      index, frame, bob_frame = 0, 0, 0.0
      last_mouse_x = Input.mouse_x
      last_mouse_y = Input.mouse_y
      
      loop do
        current_tick = frame % total_cycle
        anim_index = (current_tick < play_duration) ? (current_tick / PLAYER_ANIM_SPEED) : 0
        player_sprite.src_rect.x = anim_index * frame_width
        save_btn.setSkin(index == 0 ? "Graphics/Windowskins/button sel2" : "Graphics/Windowskins/button unsel")
        back_btn.setSkin(index == 1 ? "Graphics/Windowskins/button sel2" : "Graphics/Windowskins/button unsel")
        bob_frame += CURSOR_BOB_SPEED
        target_btn = (index == 0) ? save_btn : back_btn
        cursor.x = target_btn.x - 45 + (Math.sin(bob_frame) * CURSOR_BOB_RANGE).to_i
        cursor.y = target_btn.y + (target_btn.height - cursor.bitmap.height) / 2
        
        Graphics.update
        Input.update
        frame += 1
        
        # --- MOUSE HOVER LOGIC ---
        if Input.mouse_x != last_mouse_x || Input.mouse_y != last_mouse_y
           # Check Save Button (Index 0)
           if isMouseOverButton(save_btn)
             if index != 0
               index = 0
               pbPlayCursorSE
               self.draw_save_buttons(text_overlay, save_btn, back_btn)
             end
           # Check Back Button (Index 1)
           elsif isMouseOverButton(back_btn)
             if index != 1
               index = 1
               pbPlayCursorSE
               self.draw_save_buttons(text_overlay, save_btn, back_btn)
             end
           end
           last_mouse_x = Input.mouse_x
           last_mouse_y = Input.mouse_y
        end

        # --- MOUSE CLICK LOGIC ---
        if Input.trigger?(Input::MOUSELEFT)
          if isMouseOverButton(save_btn) || isMouseOverButton(back_btn)
             # Clicking essentially presses "Use" on the currently selected item
             pbPlayDecisionSE
             if index == 0
               # Perform Save
               [background, player_sprite, text_overlay, cursor, save_btn, back_btn, @scene.sprites["info_overlay"]].each { |s| s.visible = false }
               pbSEPlay("GUI save choice")
               if Game.save
                 # TRIGGER AUTO-CLOSE (True)
                 draw_save_msg.call(_INTL("{1} saved the game.", $player.name), true)
                 ret = true
                 break
               else
                 # Normal manual close (False)
                 draw_save_msg.call(_INTL("Save failed."), false)
                 [background, player_sprite, text_overlay, cursor, save_btn, back_btn, @scene.sprites["info_overlay"]].each { |s| s.visible = true }
               end
             else 
               # Perform Back
               break
             end
          end
        end

        # --- KEYBOARD LOGIC ---
        if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
          index = (index == 0) ? 1 : 0
          pbPlayCursorSE
          self.draw_save_buttons(text_overlay, save_btn, back_btn)
        elsif Input.trigger?(Input::USE)
          pbPlayDecisionSE
          if index == 0
            [background, player_sprite, text_overlay, cursor, save_btn, back_btn, @scene.sprites["info_overlay"]].each { |s| s.visible = false }
            pbSEPlay("GUI save choice")
            if Game.save
              # TRIGGER AUTO-CLOSE (True)
              draw_save_msg.call(_INTL("{1} saved the game.", $player.name), true)
              ret = true
              break
            else
              # Normal manual close (False)
              draw_save_msg.call(_INTL("Save failed."), false)
              [background, player_sprite, text_overlay, cursor, save_btn, back_btn, @scene.sprites["info_overlay"]].each { |s| s.visible = true }
            end
          else 
            break
          end
        elsif Input.trigger?(Input::BACK)
          pbPlayCancelSE
          break
        end
      end 
    ensure
      [msg_bg, msg_text, blur_sprite, background, player_sprite, text_overlay, cursor, save_btn, back_btn].each { |s| s.dispose if s && !s.disposed? }
      @scene.pbEndScreen if @scene && @scene.respond_to?(:pbEndScreen)
    end 
    return ret
  end
end # This is the extra end to close the class/module properly

def pbSaveScreen
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  ret = screen.pbSaveScreen
  return ret
end