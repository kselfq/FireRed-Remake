#===============================================================================
# Simple Mouse Support (Global Touch Screen Mode)
# Place in: Data/Scripts/999_Mouse_Support.rb
#===============================================================================

module Input
  # Define Mouse Buttons (0 = Left, 1 = Right)
  MOUSE_LEFT = 0 unless defined?(MOUSE_LEFT)

  class << self
    # Create an alias for the original input check so we don't break keyboards
    unless method_defined?(:touch_screen_trigger?)
      alias touch_screen_trigger? trigger?
    end
  end

  def self.trigger?(button)
    # 1. Check the REAL Keyboard/Controller first
    # If you press Enter/C on your keyboard, it always works.
    return true if touch_screen_trigger?(button)

    # 2. Check for "Virtual" Mouse Click
    # We only care if the game is checking for the "USE/OK" button (Enter/C)
    if button == Input::USE || button == Input::C
      
      # SAFE MOUSE CHECK:
      # We use a rescue block to prevent crashing if mouse is missing
      begin
        # Check if Left Mouse Button is being clicked (Trigger) or Held (Press)
        # Checking both ensures it works on Steam Deck/Linux touchpads.
        is_clicking = Input.trigger?(0) || Input.press?(0) || 
                      Input.trigger?(1) || Input.press?(1)
        
        if is_clicking
          # Get Coordinates
          mx = Input.mouse_x
          my = Input.mouse_y
          
          # --- ZONE DETECTION ---
          # Instead of looking for a specific button graphic, we check the "Zone".
          # The Text Box is always at the bottom of the screen.
          # If the mouse is in the bottom 160 pixels, we count it as a click.
          screen_bottom = Graphics.height - 160
          
          if my > screen_bottom
            
            # --- SAFETY CHECK ---
            # We don't want to click if we are just walking on the map.
            # We look for ANY visible text window in memory.
            # This works even if plugins like EBDX hide the global flags.
            
            any_text_visible = false
            
            # Check for Standard Text Windows
            if defined?(Window_AdvancedTextPokemon)
              ObjectSpace.each_object(Window_AdvancedTextPokemon) do |w|
                if !w.disposed? && w.visible && (w.opacity > 0 || (w.contents_opacity > 0 rescue false))
                  any_text_visible = true
                  break
                end
              end
            end
            
            # Check for Speech Windows (Your custom class)
            if !any_text_visible && defined?(Window_Speech)
              ObjectSpace.each_object(Window_Speech) do |w|
                if !w.disposed? && w.visible
                   any_text_visible = true
                   break
                end
              end
            end
            
            # Check for Choice Windows (Yes/No)
            if !any_text_visible && defined?(Window_CommandPokemon)
              ObjectSpace.each_object(Window_CommandPokemon) do |w|
                if !w.disposed? && w.visible && w.active
                   any_text_visible = true
                   break
                end
              end
            end

            # FINAL DECISION:
            # If we clicked the bottom zone AND a text box is visible...
            # RETURN TRUE (Act exactly like the Enter key)
            if any_text_visible
              return true 
            end
            
          end
        end
      rescue
        # If anything goes wrong with mouse detection, just return false
        return false
      end
    end
    
    return false
  end
end

#===============================================================================
# Optional: Keep the Choice Hover Logic
# This makes the cursor follow your mouse in menus
#===============================================================================
if defined?(Window_CommandPokemon)
  class Window_CommandPokemon
    alias mouse_hover_update update
    
    def update
      mouse_hover_update
      return if !self.visible || !self.active
      
      begin
        mx = Input.mouse_x
        my = Input.mouse_y
        
        # Only update cursor if mouse is strictly inside the window
        if mx >= self.x && mx <= self.x + self.width &&
           my >= self.y && my <= self.y + self.height
           
          pad_top = (self.respond_to?(:padding)) ? self.padding : 16
          item_h  = (self.respond_to?(:item_height)) ? self.item_height : 32
          
          relative_y = my - self.y - pad_top + self.oy
          item_index = relative_y / item_h
          
          if item_index >= 0 && item_index < @item_max
            if self.index != item_index
              self.index = item_index
              pbPlayCursorSE rescue nil
            end
          end
        end
      rescue
      end
    end
  end
end