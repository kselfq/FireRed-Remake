#===============================================================================
# Standalone Name Tag Plugin for Pokémon Essentials v21.1
#===============================================================================

module CustomNameTag
  # Path to the graphic windowskin (under Graphics/Windowskins/)
  WINDOWSKIN_PATH = "Graphics/Windowskins/choice 3 dark"
  
  # Font Settings (Inherits global game font automatically, size set to 30)
  FONT_SIZE = 30
  
  # Positioning relative to the main message box
  OFFSET_X = 32
  OFFSET_Y = -68
  Z_OFFSET = -1
  
  # Padding inside the name tag window
  PADDING_X = 16
  PADDING_Y = 4
  
  # Text position offsets INSIDE the graphic box (in pixels)
  # Positive values move text RIGHT / DOWN; negative values move text LEFT / UP
  TEXT_OFFSET_X = 0
  TEXT_OFFSET_Y = -4
end

#===============================================================================
#===============================================================================
# Name Tag Window Sprite
#===============================================================================
class Window_CustomNameTag < SpriteWindow_Base
  def initialize(name, msg_window)
    @msg_window = msg_window
    super(0, 0, 0, 0)
    
    if pbResolveBitmap(CustomNameTag::WINDOWSKIN_PATH)
      self.windowskin = Bitmap.new(CustomNameTag::WINDOWSKIN_PATH)
    else
      self.windowskin = msg_window.windowskin
    end
    
    self.viewport = msg_window.viewport
    self.z = msg_window.z + CustomNameTag::Z_OFFSET
    
    refresh(name)
  end

  def refresh(name)
    return if !name || name.empty?

    dummy_bmp = Bitmap.new(1, 1)
    if @msg_window.respond_to?(:contents) && @msg_window.contents && @msg_window.contents.font
      dummy_bmp.font.name = @msg_window.contents.font.name
    elsif @msg_window.respond_to?(:font) && @msg_window.font
      dummy_bmp.font.name = @msg_window.font.name
    end
    dummy_bmp.font.size = CustomNameTag::FONT_SIZE
    
    text_size = dummy_bmp.text_size(name)
    dummy_bmp.dispose

    win_width = text_size.width + (CustomNameTag::PADDING_X * 2) + self.borderX
    win_height = text_size.height + (CustomNameTag::PADDING_Y * 2) + self.borderY

    self.width = win_width
    self.height = win_height

    self.x = @msg_window.x + CustomNameTag::OFFSET_X
    self.y = @msg_window.y + CustomNameTag::OFFSET_Y

    self.contents.dispose if self.contents
    self.contents = Bitmap.new(self.width - self.borderX, self.height - self.borderY)
    
    if @msg_window.respond_to?(:contents) && @msg_window.contents && @msg_window.contents.font
      self.contents.font.name = @msg_window.contents.font.name
    elsif @msg_window.respond_to?(:font) && @msg_window.font
      self.contents.font.name = @msg_window.font.name
    end
    self.contents.font.size = CustomNameTag::FONT_SIZE
    self.contents.font.color = Color.new(255, 255, 255) # Pure White

    rect = Rect.new(
      CustomNameTag::TEXT_OFFSET_X, 
      CustomNameTag::TEXT_OFFSET_Y, 
      self.contents.width, 
      self.contents.height
    )
    self.contents.draw_text(rect, name, 1) # Center aligned
  end
end

#===============================================================================
# Core Message Display Hook (\xn, \ws, \tc, \op)
#===============================================================================
alias old_standalone_pbMessageDisplay pbMessageDisplay

def pbMessageDisplay(msgwindow, message, letterbyletter = true, commandProc = nil, &block)
  name_window = nil
  old_skin = nil
  old_opacity = nil

  # Save default state
  if msgwindow
    old_skin = msgwindow.windowskin if msgwindow.respond_to?(:windowskin)
    old_opacity = msgwindow.opacity if msgwindow.respond_to?(:opacity)
  end

  if message && message.is_a?(String)
    # 1. Resolve game variables (\v[12]) first
    message = message.gsub(/\\[vV]\[([0-9]+)\]/) { $game_variables[$1.to_i].to_s }

    # 2. Extract and process custom windowskin tag \ws[filename]
    if message.sub!(/\\[wW][sS]\[([^\]]+)\]/, "")
      skin_name = $1
      path = "Graphics/Windowskins/" + skin_name
      if msgwindow && msgwindow.respond_to?(:windowskin=)
        if pbResolveBitmap(path)
          msgwindow.windowskin = Bitmap.new(path)
        end
      end
    end

    # 3. Extract and process textbox opacity tag \op[0-255]
    if message.sub!(/\\[oO][pP]\[([0-9]+)\]/, "")
      target_opacity = $1.to_i
      if msgwindow && msgwindow.respond_to?(:opacity=)
        msgwindow.opacity = target_opacity
      end
    end

    # 4. Process text color tag \tc[N] (Converts \tc[1] to \c[1], etc.)
    message.gsub!(/\\[tT][cC]\[([0-9]+)\]/, '\\c[\1]')

    # 5. Extract and process name tag \xn[Name]
    if message.sub!(/\\[xX][nN]\[([^\]]+)\]/, "")
      character_name = $1
      name_window = Window_CustomNameTag.new(character_name, msgwindow)
    end
  end

  # Display the message
  ret = old_standalone_pbMessageDisplay(msgwindow, message, letterbyletter, commandProc, &block)

  # Cleanup name window
  name_window.dispose if name_window && !name_window.disposed?

  # Restore default properties
  if msgwindow && !msgwindow.disposed?
    msgwindow.windowskin = old_skin if old_skin && msgwindow.respond_to?(:windowskin=)
    msgwindow.opacity = old_opacity if old_opacity && msgwindow.respond_to?(:opacity=)
  end

  return ret
end