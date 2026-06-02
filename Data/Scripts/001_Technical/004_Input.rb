module Input
  USE      = C
  BACK     = B
  ACTION   = A
  JUMPUP   = X
  JUMPDOWN = Y
  SPECIAL  = Z
  AUX1     = L
  AUX2     = R

  unless defined?(update_KGC_ScreenCapture)
    class << Input
      alias update_KGC_ScreenCapture update
    end
  end

  def self.update
    update_KGC_ScreenCapture
    pbScreenCapture if trigger?(Input::F8)
  end
end

module Mouse
  module_function

  # Returns the position of the mouse relative to the game window.
  def getMousePos(catch_anywhere = false)
    return nil unless Input.mouse_in_window || catch_anywhere
    return Input.mouse_x, Input.mouse_y
  end
end


module Input
  # Check if the method exists; if not, we define a dummy version
  if !self.respond_to?(:mouse_in_window)
    def self.mouse_in_window
      return false # JoiPlay doesn't always track this properly
    end
  end

  # Patching getMousePos if it's failing inside 004_Input.rb
  if self.respond_to?(:getMousePos)
    class << self
      alias :getMousePos_original :getMousePos
      def getMousePos(*args)
        return nil if !self.respond_to?(:mouse_in_window) || !self.mouse_in_window
        return getMousePos_original(*args)
      rescue
        return nil
      end
    end
  end
end