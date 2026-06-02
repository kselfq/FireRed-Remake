#===============================================================================
# INTEGRATION WITH THE OPTIONS SYSTEM
#===============================================================================
class PokemonSystem
  attr_writer :zbox_shadow_mode

  def zbox_shadow_mode
    @zbox_shadow_mode = 1 if @zbox_shadow_mode.nil?
    return @zbox_shadow_mode
  end

  alias zbox_shadows_initialize initialize
  def initialize
    zbox_shadows_initialize
    # 0: OFF, 1: BASIC, 2: STANDARD, 3: ENHANCED.
    @zbox_shadow_mode = 1 
  end
end

#===============================================================================
# ZBox Options UI Extension
# Enables menu options with "Arrows" style ( < Valor > )
#===============================================================================
class ZBox_ArrowOption < EnumOption
end

class Window_PokemonOption
  alias zbox_ui_drawItem drawItem
  alias zbox_ui_update update

  def drawItem(index, _count, rect)
    if @options[index].is_a?(ZBox_ArrowOption)
      rect = drawCursor(index, rect)
      sel_index = self.index
      
      # Name.
      optionname = @options[index].name
      optionwidth = rect.width * 9 / 20
      pbDrawShadowText(self.contents, rect.x, rect.y, optionwidth, rect.height, optionname,
                       (index == sel_index) ? SEL_NAME_BASE_COLOR : self.baseColor,
                       (index == sel_index) ? SEL_NAME_SHADOW_COLOR : self.shadowColor)

      # Value Centered.
      value_text = @options[index].values[self[index]]
      x_start = rect.x + optionwidth
      width_area = rect.width - x_start
      center_x = x_start + (width_area / 2)
      
      pbDrawShadowText(self.contents, x_start, rect.y, width_area, rect.height, value_text,
                       (index == sel_index) ? SEL_VALUE_BASE_COLOR : self.baseColor,
                       (index == sel_index) ? SEL_VALUE_SHADOW_COLOR : self.shadowColor,
                       1)

      # Animated Arrows.
      if index == sel_index
        begin
          bmp_right = pbBitmap("Graphics/UI/right_arrow")
          bmp_left  = pbBitmap("Graphics/UI/left_arrow")
          
          # Frame Calculation.
          total_frames = 8
          current_frame = (System.uptime * 10).to_i % total_frames
          
          frame_height = bmp_right.height / total_frames
          frame_width  = bmp_right.width
          
          src_rect = Rect.new(0, current_frame * frame_height, frame_width, frame_height)
          
          y_pos = rect.y + (rect.height - frame_height) / 2
          arrow_padding = 70 # Adjust to taste
          
          current_val_index = self[index] # Current index (0, 1, 2...).
          max_val_index = @options[index].values.length - 1 # Last possible index.
          
          # Draw Right Arrow ONLY if we are not on the last value.
          if current_val_index < max_val_index
            self.contents.blt(center_x + arrow_padding, y_pos, bmp_right, src_rect)
          end
          
          # Draw Left Arrow ONLY if we are not on the last value.
          if current_val_index > 0
            self.contents.blt(center_x - arrow_padding - frame_width, y_pos, bmp_left, src_rect)
          end
        rescue
        end
      end
    else
      zbox_ui_drawItem(index, _count, rect)
    end
  end

  def update
    zbox_ui_update

    if @options[self.index].is_a?(ZBox_ArrowOption)
      refresh
    end
  end
end

#MenuHandlers.add(:options_menu, :zbox_shadows, {
#  "name"        => _INTL("Sombras Dinámicas"),
#  #"name"        => _INTL("Dynamic Shadows"),
#  "order"       => 125,
#  "type"        => ZBox_ArrowOption, 
#  "parameters"  => [_INTL("OFF"), _INTL("BASIC"), _INTL("STANDARD"), _INTL("ENHANCED")],
#  "description" => _INTL("Configura la calidad y el comportamiento de sombras en los personajes."),
#  #"description" => _INTL("Configure the quality and behavior of shadows on the characters."),
#  "get_proc"    => proc { next $PokemonSystem.zbox_shadow_mode },
#  "set_proc"    => proc { |value, scene|
#    old_value = $PokemonSystem.zbox_shadow_mode
#    $PokemonSystem.zbox_shadow_mode = value
    
#    if (old_value == 0 && value > 0) || (old_value > 0 && value == 0)
#     if $scene.is_a?(Scene_Map)
#        $scene.disposeSpritesets
#        $scene.createSpritesets
#      end
#    end
#  }
#})