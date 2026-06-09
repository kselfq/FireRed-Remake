#===============================================================================
# * JoiPlay & PC Ultra-Touch Choices - MASTER HYBRID
#===============================================================================
module TouchChoiceConfig
  FONT_SIZE      = 38            
  ITEM_HEIGHT    = 54            
  WINDOW_PADDING = 18            
  
  # YOUR PREFERRED DYNAMIC LIMITS
  MIN_WIDTH      = 170           
  MAX_WIDTH      = 640           
  WIDTH_BUFFER   = 60            
  
  LEFT_MARGIN    = 24            
  RIGHT_MARGIN   = 24            
  
  # ASSET PATHS
  SEL_GRAPHIC    = "Graphics/Windowskins/choice sel"
  ARROW_GRAPHIC  = "Graphics/UI/arrow_choices"
end

class Window_CommandPokemon < Window_DrawableCommand
  alias master_initialize initialize
  def initialize(commands, width=nil)
    # 1. Calculate Dynamic Width
    temp_bitmap = Bitmap.new(1, 1)
    pbSetSystemFont(temp_bitmap)
    temp_bitmap.font.size = TouchChoiceConfig::FONT_SIZE
    max_text_width = 0
    commands.each { |cmd| w = temp_bitmap.text_size(cmd).width; max_text_width = w if w > max_text_width }
    temp_bitmap.dispose

    calc_width = max_text_width + TouchChoiceConfig::WIDTH_BUFFER
    final_width = [[calc_width, TouchChoiceConfig::MIN_WIDTH].max, TouchChoiceConfig::MAX_WIDTH].min
    
    master_initialize(commands, final_width)
    @cursor_timer = 0
  end

  def item_height; return TouchChoiceConfig::ITEM_HEIGHT; end

  def update
    super
    return if !self.active || @commands.length == 0
    @cursor_timer += 1
    
    # 2. Universal Coordinate Mapping (Works on PC and JoiPlay)
    m_x = defined?(Input.mouse_x) ? Input.mouse_x : 0
    m_y = defined?(Input.mouse_y) ? Input.mouse_y : 0
    
    rel_x = m_x - self.x
    rel_y = m_y - self.y
    
    # 3. Universal Hitbox & Click Logic
    if rel_x >= 0 && rel_x <= self.width && rel_y >= 0 && rel_y <= self.height
      @commands.length.times do |i|
        btn_top = TouchChoiceConfig::WINDOW_PADDING + (i * self.item_height) - (self.top_item * self.item_height)
        btn_bottom = btn_top + self.item_height
        
        if rel_y >= btn_top && rel_y <= btn_bottom
          self.index = i # Hover effect
          
          if Input.trigger?(Input::MOUSELEFT)
            pbPlayDecisionSE() if defined?(pbPlayDecisionSE)
            $mouse_choice_done = true
            self.active = false
            return
          end
        end
      end
    end
    refresh if @cursor_timer % 2 == 0
  end

  def drawItem(index, count, rect)
    real_y = (index * self.item_height) + 4
    self.contents.clear_rect(rect.x, real_y, rect.width, self.item_height)
    
    # Selection Highlight
    if index == self.index && pbResolveBitmap(TouchChoiceConfig::SEL_GRAPHIC)
      bitmap_obj = AnimatedBitmap.new(TouchChoiceConfig::SEL_GRAPHIC)
      alpha = 150 + (105 * Math.sin(@cursor_timer * 0.12)).to_i
      self.contents.stretch_blt(Rect.new(rect.x, real_y, rect.width, self.item_height), bitmap_obj.bitmap, bitmap_obj.bitmap.rect, alpha)
      bitmap_obj.dispose
    end

    pbSetSystemFont(self.contents)
    self.contents.font.size = TouchChoiceConfig::FONT_SIZE
    
    # Floating Arrow
    if index == self.index && pbResolveBitmap(TouchChoiceConfig::ARROW_GRAPHIC)
      bob_x = (Math.sin(@cursor_timer * 0.2) * 5).to_i
      pbDrawImagePositions(self.contents, [[TouchChoiceConfig::ARROW_GRAPHIC, rect.x + bob_x + 2, real_y + 10]])
    end

    # Text Rendering
    pbDrawShadowText(self.contents, rect.x + TouchChoiceConfig::LEFT_MARGIN, real_y + 2, 
                     rect.width - TouchChoiceConfig::LEFT_MARGIN - TouchChoiceConfig::RIGHT_MARGIN, 
                     self.item_height, @commands[index], self.baseColor, self.shadowColor)
  end
end

class Window_CommandPokemonEx < Window_CommandPokemon; end