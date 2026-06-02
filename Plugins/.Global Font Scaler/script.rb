#===============================================================================
# * Global Font Scaler & Custom Size/Offset Remapper
# * For Pokémon Essentials v21.1
#===============================================================================

module FontScalerConfig
  # 1. The Font Size Mapping Dictionary
  # Format: Original_Size => New_Size
  FONT_SIZE_MAP = {
    32 => 30,  # Font Size / Narrow Font Size
    26 => 24,  # Small Font Size
    38 => 36,  # Textbox / Choices Text Font Size
    30 => 28,  # Options List Font Size
    56 => 54,  # Player Name Font Size
    28 => 26,  # Party Menu Pokemon Name / Bag Screen Font Size
    24 => 22,  # Party Menu Stats Texts / Battle Data Boxes Text Font Size
    20 => 18,  # Battle Data Boxes Text Font Size
    18 => 16   # Battle Data Boxes Text Font Size
  }

  # 2. The Y-Offset Mapping Dictionary
  # Format: Final_Font_Size => New_Y_Offset
  # Note: Uses the NEW font sizes (the ones after mapping)
  FONT_Y_OFFSET_MAP = {
    30 => -2,  # Font Size / Narrow Font Offset
    24 => -2   # Small Font Offset
  }
end

#===============================================================================
# Hijacking the core Font class to intercept size assignments
#===============================================================================
class Font
  alias_method :original_size_setter=, :size=

  def size=(new_size)
    if FontScalerConfig::FONT_SIZE_MAP.key?(new_size)
      self.original_size_setter = FontScalerConfig::FONT_SIZE_MAP[new_size]
    else
      self.original_size_setter = new_size
    end
  end
end

#===============================================================================
# Overriding RGSS Bitmap to perfectly shift Y-Coordinates universally
#===============================================================================
class Bitmap
  alias_method :original_draw_text_scaler, :draw_text

  def draw_text(*args)
    current_size = self.font.size

    # Check if the current font size has a Y-Offset rule
    if FontScalerConfig::FONT_Y_OFFSET_MAP.key?(current_size)
      y_shift = FontScalerConfig::FONT_Y_OFFSET_MAP[current_size]

      # Ruby's draw_text accepts arguments either as a Rect object, or X/Y coordinates
      if args[0].is_a?(Rect)
        rect = args[0].clone # Clone to prevent permanently altering the original Rect
        rect.y += y_shift
        args[0] = rect
      else
        # args[1] is the raw Y coordinate in a standard draw_text call
        args[1] += y_shift if args[1].is_a?(Numeric)
      end
    end

    # Proceed with the native drawing method using the shifted coordinates
    original_draw_text_scaler(*args)
  end
end