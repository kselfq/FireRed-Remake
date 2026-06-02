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

    # --- 1. MENU BUTTON ---
    @btn_menu = Sprite.new(@ui_viewport)
    @btn_menu.x, @btn_menu.y = 16, 16
    @btn_menu.bitmap = pbResolveBitmap("Graphics/UI/overworld_menu_btn") ? Bitmap.new("Graphics/UI/overworld_menu_btn") : Bitmap.new(96,96)

    # --- 2. SLOT A BUTTON & ICON ---
    @btn_slot_a = Sprite.new(@ui_viewport)
    @bmp_slot_norm = pbResolveBitmap("Graphics/UI/overworld_field_btn") ? Bitmap.new("Graphics/UI/overworld_field_btn") : Bitmap.new(96,96)
    @bmp_slot_sel  = pbResolveBitmap("Graphics/UI/overworld_field_btn_sel") ? Bitmap.new("Graphics/UI/overworld_field_btn_sel") : @bmp_slot_norm
    @btn_slot_a.bitmap = @bmp_slot_norm

    @icon_slot_a = Sprite.new(@ui_viewport)
    @icon_slot_a.z = @btn_slot_a.z + 1

    # --- 3. SLOT B BUTTON & ICON ---
    @btn_slot_b = Sprite.new(@ui_viewport)
    @btn_slot_b.bitmap = @bmp_slot_norm

    @icon_slot_b = Sprite.new(@ui_viewport)
    @icon_slot_b.z = @btn_slot_b.z + 1

    # --- 4. RUN BUTTON ---
    @btn_run = Sprite.new(@ui_viewport)
    @btn_run.x, @btn_run.y = 112, 16 
    if pbResolveBitmap("Graphics/UI/overworld_run_btn")
      @bmp_run_norm = Bitmap.new("Graphics/UI/overworld_run_btn")
      @bmp_run_sel  = pbResolveBitmap("Graphics/UI/overworld_run_btn_sel") ? Bitmap.new("Graphics/UI/overworld_run_btn_sel") : @bmp_run_norm
    else
      @bmp_run_norm = Bitmap.new(96, 96)
      @bmp_run_sel  = Bitmap.new(96, 96)
    end
    @btn_run.bitmap = @bmp_run_norm

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

  def update_slot_display(btn, icon_sprite, x_pos, y_pos, item_id)
    btn.x, btn.y = x_pos, y_pos
    icon_sprite.x = x_pos + (btn.bitmap.width / 2) - 24 
    icon_sprite.y = y_pos + (btn.bitmap.height / 2) - 24
    
    icon_path = GameData::Item.icon_filename(item_id)
    if icon_path
      icon_sprite.bitmap = Bitmap.new(icon_path)
    else
      icon_sprite.bitmap = nil
    end
  end

  def update_buttons_interaction
    mx, my = Input.mouse_x, Input.mouse_y
    
    check_btn = proc do |btn, action_proc|
      next false if !btn || !btn.visible
      if mx >= btn.x && mx < btn.x + btn.bitmap.width && my >= btn.y && my < btn.y + btn.bitmap.height
         if Input.trigger?(Input::MOUSELEFT)
           pbPlayDecisionSE
           action_proc.call
           return true
         end
         return true
      end
      false
    end

    return true if check_btn.call(@btn_menu, proc { call_menu })
    
    if check_btn.call(@btn_slot_a, proc { pbUseKeyItemInField($bag.registered_item_1) })
       @btn_slot_a.bitmap = Input.press?(Input::MOUSELEFT) ? @bmp_slot_sel : @bmp_slot_norm
       return true
    else
       @btn_slot_a.bitmap = @bmp_slot_norm
    end

    if check_btn.call(@btn_slot_b, proc { pbUseKeyItemInField($bag.registered_item_2) })
       @btn_slot_b.bitmap = Input.press?(Input::MOUSELEFT) ? @bmp_slot_sel : @bmp_slot_norm
       return true
    else
       @btn_slot_b.bitmap = @bmp_slot_norm
    end

    if check_btn.call(@btn_run, proc { 
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