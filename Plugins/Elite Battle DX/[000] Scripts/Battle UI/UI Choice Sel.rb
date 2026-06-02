#===============================================================================
#  Command Choices - UI Overhaul (Direct Input Confirmation)
#===============================================================================
class ChoiceWindowEBDX
  attr_accessor :index, :over
  def initialize(viewport,commands,scene)
    $ebd_choice_active = true
    @commands = commands; @scene = scene; @index = 0; @path = "Graphics/EBDX/Pictures/UI/"; @viewport = viewport
    @viewport.z = 999999 if @viewport
    @sprites = {}; self.applyMetrics; @global_offset_x = 0; @global_offset_y = 0; @arrow_x_offset = -102
    @sprites["sel"] = Sprite.new(@viewport)
    @sprites["sel"].bitmap = pbBitmap(@path + "arrow")
    @sprites["sel"].ox = @sprites["sel"].bitmap.width / 2; @sprites["sel"].oy = @sprites["sel"].bitmap.height / 2
    @sprites["sel"].z = 999999; @sprites["sel"].visible = false
    @sel_dir = 1; @sel_speed = 1; @sel_max = 4; @sel_offset = 0
    base_bmp = pbBitmap(@path + @btnImg)
    button_height = base_bmp.height; button_spacing = 4
    total_height = @commands.length * (button_height + button_spacing) - button_spacing
    start_y = Graphics.height - 16 - total_height + button_height / 2
    for i in 0...@commands.length
      @sprites["choice#{i}"] = Sprite.new(@viewport)
      @sprites["choice#{i}"].x = Graphics.width - base_bmp.width - 16 + base_bmp.width / 2 + @global_offset_x
      @sprites["choice#{i}"].y = start_y + i * (button_height + button_spacing) + @global_offset_y
      @sprites["choice#{i}"].z = 999998; @sprites["choice#{i}"].bitmap = Bitmap.new(base_bmp.width, button_height)
      @sprites["choice#{i}"].center!; @sprites["choice#{i}"].opacity = 0
    end
    base_bmp.dispose; refresh_all_buttons
  end

  def applyMetrics
    @btnImg = "btnEmpty"; d1 = EliteBattle.get(:nextUI)
    d1 = d1[:CHOICE_MENU] if !d1.nil? && d1.has_key?(:CHOICE_MENU)
    d2 = EliteBattle.get_data(:CHOICE_MENU, :Metrics, :METRICS)
    for data in [d2, d1]
      next if data.nil?
      @btnImg = data[:BUTTONS] if data.has_key?(:BUTTONS) && data[:BUTTONS].is_a?(String)
    end
  end

  def refresh_button(i)
    return if !@sprites["choice#{i}"] || @sprites["choice#{i}"].disposed?
    @sprites["choice#{i}"].bitmap.clear
    bmp = pbBitmap(@path + (i == @index ? "btnChoose" : "btnEmpty"))
    @sprites["choice#{i}"].bitmap.blt(0, 0, bmp, bmp.rect); bmp.dispose
    pbSetSystemFont(@sprites["choice#{i}"].bitmap)
    pbDrawOutlineText(@sprites["choice#{i}"].bitmap, 0, 8, @sprites["choice#{i}"].bitmap.width, @sprites["choice#{i}"].bitmap.height, @commands[i], Color.black, Color.new(0,0,0,0), 1)
  end

  def refresh_all_buttons; for i in 0...@commands.length; refresh_button(i); end; end

  def update
    oldIndex = @index
    mouse_over_any_button = false
    for i in 0...@commands.length
      sprite = @sprites["choice#{i}"]; next if !sprite || sprite.disposed?
      x = sprite.x - sprite.ox; y = sprite.y - sprite.oy
      if Input.mouse_x >= x && Input.mouse_x < x + sprite.bitmap.width &&
         Input.mouse_y >= y && Input.mouse_y < y + sprite.bitmap.height
        mouse_over_any_button = true
        if @index != i; pbSEPlay("EBDX/SE_Select1"); @index = i; end
        
        if Input.triggerex?(0x01) # Physical Click
          pbSEPlay("EBDX/SE_Select1")
          @over = true 
          $ebd_choice_confirmed = true 
          return @index
        end
      end
    end
    unless mouse_over_any_button
      if Input.trigger?(Input::UP); pbSEPlay("EBDX/SE_Select1"); @index = (@index - 1) % @commands.length
      elsif Input.trigger?(Input::DOWN); pbSEPlay("EBDX/SE_Select1"); @index = (@index + 1) % @commands.length; end
    end
    if oldIndex != @index; refresh_button(oldIndex); refresh_button(@index); end
    @sprites["sel"].y = @sprites["choice#{@index}"].y - 2
    @sel_offset += @sel_speed * @sel_dir; @sel_dir *= -1 if @sel_offset.abs >= @sel_max
    @sprites["sel"].x = @sprites["choice#{@index}"].x + @sel_offset + @arrow_x_offset; @sprites["sel"].visible = true
    for i in 0...@commands.length; @sprites["choice#{i}"].opacity += 128 if @sprites["choice#{i}"].opacity < 255; end
  end

  def dispose(scene)
    $ebd_choice_active = false
    pbDisposeSpriteHash(@sprites)
  end
end