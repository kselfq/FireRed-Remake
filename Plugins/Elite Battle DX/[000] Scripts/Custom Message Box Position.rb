#===============================================================================
# Custom Message Box Position – Namespace-Aware Clicker (Restoration Point)
#===============================================================================

module CustomMessageBoxPosition
  def pbSetMessageMode(mode, light = false)
    @last_msg_mode = mode
    @last_msg_light = light
    super(mode, light) if defined?(super)
    
    box  = @sprites["messageBox"]; text = @sprites["messageWindow"]
    return if !box || !text
    vw = @viewport ? @viewport.width : Graphics.width
    vh = @viewport ? @viewport.height : Graphics.height
    @messageSkin = light ? :skin2 : :skin1

    # 1. POSITIONING
    if @messageSkin == :skin1
      skin_file = "Graphics/EBDX/Pictures/UI/skin1"
      box_w = 980
      if pbResolveBitmap(skin_file)
        bmp = Bitmap.new(skin_file); box.bitmap = bmp; box_w = bmp.width > 0 ? bmp.width : 980
        box.src_rect.set(0, 0, box_w, bmp.height)
      end
      box.x = 0; box.y = vh - (box.bitmap ? box.bitmap.height : 136)
    else
      sys_skin = "Graphics/Windowskins/speech"
      if pbResolveBitmap(sys_skin)
        box.bitmap = Bitmap.smartWindow(Rect.new(16,16,16,16), Rect.new(0, 0, 792, 142), sys_skin)
        box.src_rect.set(0, 0, 792, 142)
      end
      box.x = (vw - 792) / 2; box.y = vh - 142 - 16 
    end
    box.z = 99900; text.z = box.z + 1

    # 2. TEXT & FONT
    if @messageSkin == :skin1
      text.width = 980 - 32; text.x = box.x - 16; text.y = box.y + 10    
      @arrow_base_x = box.x; @arrow_base_y = box.y; @arrow_offset_x = 920   
    else
      text.width = 792 - 40; text.x = box.x - 12; text.y = box.y + 6    
      @arrow_base_x = box.x; @arrow_base_y = box.y; @arrow_offset_x = 720   
    end
    text.opacity = 0; text.back_opacity = 0; text.contents_opacity = 255 
    text.baseColor = Color.new(0, 0, 0); text.shadowColor = Color.new(10, 10, 10, 0)

    # 3. WARPER ENGINE
    if !text.respond_to?(:ebdx_protection_applied)
      class << text
        def ebdx_protection_applied; true; end
        alias lock_height height=
        def height=(val); lock_height(300); end
        alias lock_contents contents=
        def contents=(bmp)
          lock_contents(bmp)
          if bmp && !bmp.respond_to?(:ebdx_shifter_applied)
            class << bmp
              def ebdx_shifter_applied; true; end
              def get_shifted_y(y)
                shift_amount = 22   
                return y + (shift_amount * 2) if y >= 60   
                return y + shift_amount       if y >= 20   
                return y                                   
              end
              alias orig_blt blt
              def blt(x, y, src_bitmap, src_rect, opacity = 255); orig_blt(x, get_shifted_y(y), src_bitmap, src_rect, opacity); end
              alias orig_draw_text draw_text
              def draw_text(*args)
                if args[0].is_a?(Rect); args[0] = Rect.new(args[0].x, get_shifted_y(args[0].y), args[0].width, args[0].height)
                else; args[1] = get_shifted_y(args[1]); end
                orig_draw_text(*args)
              end
            end
          end
        end
      end
      text.height = 300 
      if text.contents
        old_bmp = text.contents; text.contents = Bitmap.new(text.width - 38, 300 - 38)
        pbSetSystemFont(text.contents); text.contents.font.size = 38; old_bmp.dispose
      end
    end
    arrow = text.instance_variable_get(:@cursorSprite) || text.instance_variable_get(:@pauseSprite)
    if arrow; arrow.x = @arrow_base_x + @arrow_offset_x; arrow.y = @arrow_base_y + 100; arrow.z = box.z + 2; end
  end

  def pbShowWindow(*args)
    super(*args) if defined?(super)
    mem_mode = @last_msg_mode.nil? ? 0 : @last_msg_mode
    mem_light = @last_msg_light.nil? ? false : @last_msg_light
    pbSetMessageMode(mem_mode, mem_light)
  end
end

class Battle::Scene; prepend CustomMessageBoxPosition; end

# ==============================================================================
# 5. INPUT REDIRECTOR (Namespace-Based UI Blocker)
# ==============================================================================
module Input
  class << self
    alias ebdx_atomic_trigger? trigger?
    def trigger?(key)
      if (key == Input::USE || key == Input::C)
        if $ebd_choice_confirmed
          $ebd_choice_confirmed = false
          return true
        end
        
        # Ensures target mouse clicks act exactly like hitting "Enter"
        if $ebd_target_clicked
          $ebd_target_clicked = false
          return true
        end
        
        if $game_temp.in_battle && ebdx_atomic_trigger?(Input::MOUSELEFT)
          return false if $ebd_choice_active
          return false if $ebd_target_active # Safely timed directly to the Target loop
          
          stack = caller.join("\n")
          return false if stack.include?("Bag") || stack.include?("Party") || stack.include?("Summary")
          
          return true
        end
      end
      return ebdx_atomic_trigger?(key)
    end
  end
end