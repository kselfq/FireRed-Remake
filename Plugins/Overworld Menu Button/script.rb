#===============================================================================
# Overworld UI Plugin: Menu, Slots, Autorun & Touch Controls
# v21.1 Compatible - Final Key Binding Fix (D & F Keys)
#===============================================================================

# Ensure the native Ready Menu doesn't try to open
class Player
  def has_menu_binds?; return false; end
end

class Scene_Map
  alias :ui_plugin_update :update
  def update
    # 1. Catch shortcuts before the rest of the map logic runs
    update_keyboard_shortcuts 
    # 2. Run the original map update
    ui_plugin_update
    # 3. Update the visual UI elements
    update_ui_plugin
  end

  alias :ui_plugin_dispose :dispose
  def dispose
    dispose_ui_plugin
    ui_plugin_dispose
  end

  def init_ui_plugin
    @ui_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @ui_viewport.z = 100 

    # --- 1. MENU BUTTON (Center Origin & Offset Position) ---
    @btn_menu = Sprite.new(@ui_viewport)
    @menu_base_x, @menu_base_y = 16, 16
    @btn_menu.bitmap = pbResolveBitmap("Graphics/UI/overworld_menu_btn") ? Bitmap.new("Graphics/UI/overworld_menu_btn") : Bitmap.new(96,96)
    @btn_menu.ox = @btn_menu.bitmap.width / 2
    @btn_menu.oy = @btn_menu.bitmap.height / 2
    @btn_menu.x = @menu_base_x + @btn_menu.ox
    @btn_menu.y = @menu_base_y + @btn_menu.oy

    # --- 2. SLOT A BUTTON & ICON ---
    @btn_slot_a = Sprite.new(@ui_viewport)
    @bmp_slot_norm = pbResolveBitmap("Graphics/UI/overworld_field_btn") ? Bitmap.new("Graphics/UI/overworld_field_btn") : Bitmap.new(96,96)
    @bmp_slot_sel  = pbResolveBitmap("Graphics/UI/overworld_field_btn_sel") ? Bitmap.new("Graphics/UI/overworld_field_btn_sel") : @bmp_slot_norm
    @btn_slot_a.bitmap = @bmp_slot_norm
    @btn_slot_a.ox = @btn_slot_a.bitmap.width / 2
    @btn_slot_a.oy = @btn_slot_a.bitmap.height / 2

    @icon_slot_a = Sprite.new(@ui_viewport)
    @icon_slot_a.z = @btn_slot_a.z + 1

    # --- 3. SLOT B BUTTON & ICON ---
    @btn_slot_b = Sprite.new(@ui_viewport)
    @btn_slot_b.bitmap = @bmp_slot_norm
    @btn_slot_b.ox = @btn_slot_b.bitmap.width / 2
    @btn_slot_b.oy = @btn_slot_b.bitmap.height / 2

    @icon_slot_b = Sprite.new(@ui_viewport)
    @icon_slot_b.z = @btn_slot_b.z + 1

    # --- 4. RUN BUTTON (Center Origin & Offset Position) ---
    @btn_run = Sprite.new(@ui_viewport)
    @run_base_x, @run_base_y = 112, 16 
    if pbResolveBitmap("Graphics/UI/overworld_run_btn")
      @bmp_run_norm = Bitmap.new("Graphics/UI/overworld_run_btn")
      @bmp_run_sel  = pbResolveBitmap("Graphics/UI/overworld_run_btn_sel") ? Bitmap.new("Graphics/UI/overworld_run_btn_sel") : @bmp_run_norm
    else
      @bmp_run_norm = Bitmap.new(96, 96)
      @bmp_run_sel  = Bitmap.new(96, 96)
    end
    @btn_run.bitmap = @bmp_run_norm
    @btn_run.ox = @btn_run.bitmap.width / 2
    @btn_run.oy = @btn_run.bitmap.height / 2
    @btn_run.x = @run_base_x + @btn_run.ox
    @btn_run.y = @run_base_y + @btn_run.oy

    @dpad_active = false
    @was_dragging = false
  end

  def dispose_ui_plugin
    [@btn_menu, @btn_slot_a, @btn_slot_b, @btn_run, @icon_slot_a, @icon_slot_b].each { |s| s.dispose if s }
    @ui_viewport.dispose if @ui_viewport
  end

  # Keyboard Shortcut Logic
  def update_keyboard_shortcuts
    # Don't use items if a message or event is running
    return if $game_temp.message_window_showing || $game_system.menu_disabled || 
              ($game_system.respond_to?(:map_interpreter) && $game_system.map_interpreter.running?)
    
    # D Key (Input::SPECIAL) -> Slot 1
    if Input.trigger?(Input::SPECIAL)
      if $bag.registered_item_1
        pbUseKeyItemInField($bag.registered_item_1)
      end
    end

    # F Key (Input::AUX1) -> Slot 2
    if Input.trigger?(Input::AUX1)
      if $bag.registered_item_2
        pbUseKeyItemInField($bag.registered_item_2)
      end
    end
  end

  def update_ui_plugin
    init_ui_plugin if !@btn_menu || @btn_menu.disposed?

    # --- AUTO-SHIFT LOGIC ---
    if $bag.registered_item_1 && $bag.quantity($bag.registered_item_1) <= 0
       $bag.registered_item_1 = $bag.registered_item_2
       $bag.registered_item_2 = nil
    end
    if $bag.registered_item_2 && $bag.quantity($bag.registered_item_2) <= 0
       $bag.registered_item_2 = nil
    end

    is_busy = $scene != self || $game_temp.message_window_showing || $game_system.menu_disabled || 
              ($game_system.respond_to?(:map_interpreter) && $game_system.map_interpreter.running?)

    if is_busy
      [@btn_menu, @btn_slot_a, @btn_slot_b, @btn_run, @icon_slot_a, @icon_slot_b].each { |s| s.visible = false }
      return
    end

    @btn_menu.visible = true
    @btn_run.visible = $player.has_running_shoes
    @btn_run.bitmap = ($PokemonSystem.runstyle == 1) ? @bmp_run_sel : @bmp_run_norm

    has_a = !$bag.registered_item_1.nil?
    has_b = !$bag.registered_item_2.nil?

    @btn_slot_a.visible = has_a
    @icon_slot_a.visible = has_a
    @btn_slot_b.visible = has_b
    @icon_slot_b.visible = has_b

    if has_a && has_b
      update_slot_display(@btn_slot_a, @icon_slot_a, 16, 112, $bag.registered_item_1)
      update_slot_display(@btn_slot_b, @icon_slot_b, 16, 208, $bag.registered_item_2)
    elsif has_a
      update_slot_display(@btn_slot_a, @icon_slot_a, 16, 112, $bag.registered_item_1)
    elsif has_b
      update_slot_display(@btn_slot_b, @icon_slot_b, 16, 112, $bag.registered_item_2)
    end

    return if update_buttons_interaction
    update_touch_controls
  end

  def update_slot_display(btn, icon_sprite, base_x, base_y, item_id)
    btn.x = base_x + btn.ox
    btn.y = base_y + btn.oy
    icon_sprite.x = base_x + (btn.bitmap.width / 2) - 24 
    icon_sprite.y = base_y + (btn.bitmap.height / 2) - 24
    
    icon_path = GameData::Item.icon_filename(item_id)
    if icon_path
      icon_sprite.bitmap = Bitmap.new(icon_path)
    else
      icon_sprite.bitmap = nil
    end
  end

  def update_buttons_interaction
    mx, my = Input.mouse_x, Input.mouse_y
    
    check_btn = proc do |btn, base_x, base_y, action_proc|
      next false if !btn || !btn.visible
      # Check bounds based on top-left layout coordinates (base_x, base_y)
      if mx >= base_x && mx < base_x + btn.bitmap.width && my >= base_y && my < base_y + btn.bitmap.height
         if Input.trigger?(Input::MOUSELEFT)
           # --- 0.7 SCALE SHRINK & RETURN ANIMATION ---
           4.times do |i|
             scale = 1.0 - ((i + 1) * 0.075) # Shrinks down to 0.7
             btn.zoom_x = scale
             btn.zoom_y = scale
             Graphics.update
             Input.update
           end
           4.times do |i|
             scale = 0.7 + ((i + 1) * 0.075) # Returns back to 1.0
             btn.zoom_x = scale
             btn.zoom_y = scale
             Graphics.update
             Input.update
           end
           # -------------------------------------------
           
           pbPlayDecisionSE
           action_proc.call
           return true
         end
         return true
      end
      false
    end

    return true if check_btn.call(@btn_menu, 16, 16, proc { call_menu })
    
    if check_btn.call(@btn_slot_a, 16, 112, proc { pbUseKeyItemInField($bag.registered_item_1) })
       return true
    else
       @btn_slot_a.bitmap = @bmp_slot_norm
    end

    if check_btn.call(@btn_slot_b, 16, 208, proc { pbUseKeyItemInField($bag.registered_item_2) })
       return true
    else
       @btn_slot_b.bitmap = @bmp_slot_norm
    end

    if check_btn.call(@btn_run, 112, 16, proc { 
         $PokemonSystem.runstyle = ($PokemonSystem.runstyle == 1) ? 0 : 1 
         $game_player.refresh if $game_player
       })
       return true
    end
    return false
  end

  def update_touch_controls
    mx, my = Input.mouse_x, Input.mouse_y
    if Input.trigger?(Input::MOUSELEFT)
      @dpad_active = true
      @was_dragging = false
      @touch_start_x = mx
      @touch_start_y = my
    end
    
    if @dpad_active && Input.press?(Input::MOUSELEFT)
      diff_x = mx - @touch_start_x
      diff_y = my - @touch_start_y
      if diff_x.abs > 24 || diff_y.abs > 24
        if @touch_start_x < Graphics.width / 2
          @was_dragging = true
          dir = (diff_x.abs > diff_y.abs) ? (diff_x > 0 ? 6 : 4) : (diff_y > 0 ? 2 : 8)
          if !$game_player.moving?
             case dir
             when 2 then $game_player.move_down
             when 4 then $game_player.move_left
             when 6 then $game_player.move_right
             when 8 then $game_player.move_up
             end
          end
        else
          @was_dragging = true 
        end
      end
    end
    
    if Input.release?(Input::MOUSELEFT)
      if @dpad_active && !@was_dragging
        if !$game_player.check_event_trigger_there([0,1,2])
           $game_player.check_event_trigger_here([0])
        end
      end
      @dpad_active = false
      @was_dragging = false
    end
  end
end
