#===============================================================================
# Dummy class to prevent NameErrors from other plugins
#===============================================================================
class Window_PokemonOption < Window_DrawableCommand
  def drawItem(index, count, rect); end
end

#===============================================================================
# PokemonSystem class
#===============================================================================
class PokemonSystem
  attr_accessor :textspeed, :battlescene, :battlestyle, :sendtoboxes
  attr_accessor :givenicknames, :frame, :textskin, :screensize
  attr_accessor :language, :runstyle, :bgmvolume, :sevolume, :textinput

  def initialize
    @textspeed     = 1
    @battlescene   = 0
    @battlestyle   = 0
    @sendtoboxes   = 0
    @givenicknames = 0
    @frame         = 0
    @textskin      = 0
    @screensize    = (Settings::SCREEN_SCALE * 2).floor - 1
    @language      = 0
    @runstyle      = 0
    @bgmvolume     = 80
    @sevolume      = 100
    @textinput     = 0
  end
end

#===============================================================================
# Option classes for logic
#===============================================================================
module PropertyMixin
  attr_reader :name
  def get; return @get_proc&.call; end
  def set(*args); @set_proc&.call(*args); end
end

class EnumOption
  include PropertyMixin
  attr_reader :values
  def initialize(name, values, get_proc, set_proc)
    @name     = name
    @values   = values.map { |val| _INTL(val) }
    @get_proc = get_proc
    @set_proc = set_proc
  end
  def next(current); index = current + 1; return (index > @values.length - 1) ? @values.length - 1 : index; end
  def prev(current); index = current - 1; return (index < 0) ? 0 : index; end
end

class SliderOption
  include PropertyMixin
  attr_reader :lowest_value, :highest_value
  def initialize(name, range, get_proc, set_proc)
    @name, @lowest_value, @highest_value, @interval = name, range[0], range[1], range[2]
    @get_proc, @set_proc = get_proc, set_proc
  end
  def next(current); val = current + @lowest_value + @interval; val = @highest_value if val > @highest_value; return val - @lowest_value; end
  def prev(current); val = current + @lowest_value - @interval; val = @lowest_value if val < @lowest_value; return val - @lowest_value; end
end

#===============================================================================
# Options main screen
#===============================================================================
class PokemonOption_Scene
  attr_reader :sprites, :in_load_screen

  def pbStartScene(in_load_screen = false)
    @in_load_screen = in_load_screen
    @options = []
    @hashes = []
    @index = 0
    @draw_char_index = 0
    @draw_timer = 0
    
    MenuHandlers.each_available(:options_menu) do |option, hash, name|
      @options.push(hash["type"].new(name, hash["parameters"], hash["get_proc"], hash["set_proc"]))
      @hashes.push(hash)
    end

    @values = Array.new(@options.length) { |i| @options[i].get || 0 }

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = Bitmap.new("Graphics/UI/settingsbg")
	
	@sprites["btn_back"] = IconSprite.new(16, 16, @viewport)
    @sprites["btn_back"].setBitmap("Graphics/UI/back")
    @sprites["btn_back"].z = 250
    
    @sprites["textbox_bg"] = IconSprite.new(0, 0, @viewport)
    @sprites["textbox_bg"].setBitmap("Graphics/Windowskins/speech2")
    @sprites["textbox_bg"].x = (Graphics.width - 792) / 2
    @sprites["textbox_bg"].y = 16
    @sprites["textbox_bg"].z = 100

    # 2. Create the Text Overlay (Canvas for the description)
    @sprites["textbox_text"] = BitmapSprite.new(792, 142, @viewport)
    @sprites["textbox_text"].x = @sprites["textbox_bg"].x
    @sprites["textbox_text"].y = @sprites["textbox_bg"].y
    @sprites["textbox_text"].z = 101 # Sits on top of the background
    pbSetSystemFont(@sprites["textbox_text"].bitmap)

    @sprites["option_canvas"] = BitmapSprite.new(Graphics.width, 4000, @viewport)
    @sprites["option_canvas"].z = 100
    pbSetSystemFont(@sprites["option_canvas"].bitmap)
    
    @sprites["cursor"] = Sprite.new(@viewport)
    @sprites["cursor"].bitmap = Bitmap.new("Graphics/UI/sel_arrow")
    @sprites["cursor"].z = 150
    
    @sprites["arrow_left"] = Sprite.new(@viewport)
    @sprites["arrow_left"].bitmap = Bitmap.new("Graphics/UI/leftarrow")
    @sprites["arrow_left"].z = 150
    
    @sprites["arrow_right"] = Sprite.new(@viewport)
    @sprites["arrow_right"].bitmap = Bitmap.new("Graphics/UI/rightarrow")
    @sprites["arrow_right"].z = 150

    @bob_frame = 0.0

    draw_options_manually
    pbChangeSelection
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def draw_options_manually
    contents = @sprites["option_canvas"].bitmap
    contents.clear
    
    button_w = 790 
    button_x = (Graphics.width - button_w) / 2
    start_y  = 174
    item_h   = 60
    btn_h    = 44
    
    @options.each_with_index do |opt, i|
      y_pos = start_y + (i * item_h)
      skin = (i == @index) ? "Graphics/Windowskins/button sel3" : "Graphics/Windowskins/button unsel3"
      pbDrawBoxInternal(contents, skin, button_x, y_pos, button_w, btn_h)

      contents.font.size = 30
      text_y = y_pos + (btn_h - contents.font.size) / 2
      
      base_color = Color.new(0, 0, 0)
      shadow_color = Color.new(0, 0, 0, 0)

      pbDrawShadowText(contents, button_x + 30, text_y, button_w / 2, contents.font.size, opt.name, 
                       base_color, shadow_color)
      
      val_x = button_x + (button_w / 2)
      case opt
      when EnumOption
        val_text = opt.values[@values[i]]
        pbDrawShadowText(contents, val_x, text_y, (button_w / 2) - 30, contents.font.size, val_text, 
                         base_color, shadow_color, 1)
      when SliderOption
        val_text = (@values[i] + opt.lowest_value).to_s
        pbDrawShadowText(contents, val_x, text_y, (button_w / 2) - 30, contents.font.size, val_text, 
                         base_color, shadow_color, 1)
      end
    end
  end

  # Optimized Horizontal 3-Slice for Rounded 44x44 graphics
  def pbDrawBoxInternal(bitmap, skin, x, y, width, height)
    skin_bitmap = AnimatedBitmap.new(skin).deanimate
    # We assume a 44x44 graphic.
    # We take 20px for the left curve, 20px for the right curve, 
    # and stretch the middle 4 pixels.
    side_w = 20 
    mid_src_w = 4
    
    # Left Curve
    bitmap.blt(x, y, skin_bitmap, Rect.new(0, 0, side_w, height))
    
    # Right Curve
    bitmap.blt(x + width - side_w, y, skin_bitmap, Rect.new(44 - side_w, 0, side_w, height))
    
    # Middle Stretch (The "body" of the button)
    bitmap.stretch_blt(Rect.new(x + side_w, y, width - (side_w * 2), height), 
                       skin_bitmap, Rect.new(side_w, 0, mid_src_w, height))
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    @bob_frame += 0.25
    bob = (Math.sin(@bob_frame) * 8).to_i
    
    btn_w = 790
    btn_x = (Graphics.width - btn_w) / 2
    value_center_x = btn_x + (btn_w * 0.75)
    center_y = 174 + (@index * 60) + (44 / 2)
    
    if @sprites["cursor"]
      @sprites["cursor"].y = center_y - (@sprites["cursor"].bitmap.height / 2)
      @sprites["cursor"].x = btn_x - 40 + bob
    end

    if @index < @options.length
      opt = @options[@index]
      val = @values[@index]
      max_val = opt.is_a?(EnumOption) ? opt.values.length - 1 : (opt.highest_value - opt.lowest_value)
      
      @sprites["arrow_left"].visible = (val > 0)
      @sprites["arrow_left"].y = center_y - (@sprites["arrow_left"].bitmap.height / 2)
      @sprites["arrow_left"].x = value_center_x - 160 - bob
      
      @sprites["arrow_right"].visible = (val < max_val)
      @sprites["arrow_right"].y = center_y - (@sprites["arrow_right"].bitmap.height / 2)
      @sprites["arrow_right"].x = value_center_x + 80 + bob
    end

    # --- Typewriter Logic ---
    if @total_len && @draw_char_index < @total_len
      frames_per_char = [4, 2, 1, 0][$PokemonSystem.textspeed] || 2
      
      if frames_per_char == 0 # Instant speed
        @draw_char_index = @total_len
        refresh_description_text
      else
        @draw_timer += 1
        if @draw_timer >= frames_per_char
          @draw_char_index += 1
          @draw_timer = 0
          refresh_description_text
        end
      end
    end
  end

  def pbChangeSelection
    hash = @hashes[@index]
    full_desc = hash["description"].is_a?(Proc) ? hash["description"].call : _INTL(hash["description"])
    
    # --- PRE-CALCULATE LINE SPLIT (No Jumping Fix) ---
    @line1_full = full_desc
    @line2_full = ""

    # Using 45 chars as a safe limit for size 32 font width
    if full_desc.length > 50
      cut_idx = full_desc[0..50].rindex(' ') || 50
      @line1_full = full_desc[0...cut_idx].strip
      @line2_full = full_desc[cut_idx..-1].strip
    end

    @total_len = @line1_full.length + @line2_full.length
    @draw_char_index = 0
    @draw_timer = 0
    
    @sprites["textbox_text"].bitmap.clear
    draw_options_manually
  end

  def refresh_description_text
    return if !@total_len
    contents = @sprites["textbox_text"].bitmap
    contents.clear
    pbSetSystemFont(contents)
    contents.font.size = 38
    
    base_color   = Color.new(0, 0, 0)
    shadow_color = Color.new(0, 0, 0, 0)

    # Draw Line 1 (Partial or Full)
    visible_1 = (@draw_char_index > @line1_full.length) ? @line1_full : @line1_full[0...@draw_char_index]
    drawTextEx(contents, 20, 22, 728, 1, visible_1, base_color, shadow_color)
    
    # Draw Line 2 (Partial)
    if @draw_char_index > @line1_full.length
      len_into_line2 = @draw_char_index - @line1_full.length
      visible_2 = @line2_full[0...len_into_line2]
      drawTextEx(contents, 20, 79, 728, 1, visible_2, base_color, shadow_color)
    end
  end

  # =========================================================================
  # MOUSE SUPPORT HELPERS
  # =========================================================================
  
  def isMouseOverRow(index)
    button_w = 790
    button_x = (Graphics.width - button_w) / 2
    start_y  = 174
    item_h   = 60
    # Hitbox covers the full row height
    y_pos = start_y + (index * item_h)
    
    mx, my = Input.mouse_x, Input.mouse_y
    return (mx >= button_x && mx < button_x + button_w &&
            my >= y_pos && my < y_pos + item_h)
  end

  def isMouseOverSprite(sprite)
    return false if !sprite || !sprite.visible || sprite.disposed?
    mx, my = Input.mouse_x, Input.mouse_y
    return (mx >= sprite.x && mx < sprite.x + sprite.bitmap.width &&
            my >= sprite.y && my < sprite.y + sprite.bitmap.height)
  end

  # =========================================================================
  # MAIN LOOP (UPDATED FOR MOUSE & EXIT BUTTON)
  # =========================================================================
  def pbOptions
    @last_mouse_x = Input.mouse_x
    @last_mouse_y = Input.mouse_y
    
    loop do
      Graphics.update
      Input.update
      pbUpdate
      
      # 1. Update selection on Mouse Hover
      if Input.mouse_x != @last_mouse_x || Input.mouse_y != @last_mouse_y
        @options.each_with_index do |_, i|
          if isMouseOverRow(i)
            if @index != i
              @index = i
              pbPlayCursorSE
              pbChangeSelection
            end
            break # Found the hovered row
          end
        end
        @last_mouse_x = Input.mouse_x
        @last_mouse_y = Input.mouse_y
      end

      # 2. Mouse Clicks
      if Input.trigger?(Input::MOUSELEFT)
        
        # A. Check Left Arrow
        if isMouseOverSprite(@sprites["arrow_left"])
          old_val = @values[@index]
          @values[@index] = @options[@index].prev(@values[@index])
          if old_val != @values[@index]
            @options[@index].set(@values[@index], self)
            pbPlayCursorSE
            draw_options_manually
          end
        
        # B. Check Right Arrow
        elsif isMouseOverSprite(@sprites["arrow_right"])
          old_val = @values[@index]
          @values[@index] = @options[@index].next(@values[@index])
          if old_val != @values[@index]
            @options[@index].set(@values[@index], self)
            pbPlayCursorSE
            draw_options_manually
          end
          
        # C. Invisible Exit Button (Bottom Right, 210x46)
        else
          exit_w = 96
          exit_h = 96
          exit_x = 16
          exit_y = 16
          
          if Input.mouse_x >= exit_x && Input.mouse_x < exit_x + exit_w &&
             Input.mouse_y >= exit_y && Input.mouse_y < exit_y + exit_h
            pbPlayCancelSE
            break
          end
        end
      end

      # 3. Standard Keyboard Inputs
      if Input.trigger?(Input::UP)
        @index = (@index <= 0) ? @options.length - 1 : @index - 1
        pbPlayCursorSE; pbChangeSelection
      elsif Input.trigger?(Input::DOWN)
        @index = (@index >= @options.length - 1) ? 0 : @index + 1
        pbPlayCursorSE; pbChangeSelection
      elsif Input.trigger?(Input::LEFT)
        old_val = @values[@index]
        @values[@index] = @options[@index].prev(@values[@index])
        if old_val != @values[@index]
          @options[@index].set(@values[@index], self)
          pbPlayCursorSE; draw_options_manually
        end
      elsif Input.trigger?(Input::RIGHT)
        old_val = @values[@index]
        @values[@index] = @options[@index].next(@values[@index])
        if old_val != @values[@index]
          @options[@index].set(@values[@index], self)
          pbPlayCursorSE; draw_options_manually
        end
      elsif Input.trigger?(Input::BACK)
        break
      end
    end
  end

  def pbEndScene
    pbPlayCloseMenuSE
    pbFadeOutAndHide(@sprites) { pbUpdate }
    # Dispose our new custom sprites
    @sprites["textbox_bg"]&.dispose
    @sprites["textbox_text"]&.dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class PokemonOptionScreen
  def initialize(scene); @scene = scene; end
  def pbStartScreen(in_load_screen = false)
    @scene.pbStartScene(in_load_screen)
    @scene.pbOptions
    @scene.pbEndScene
  end
end

#===============================================================================
# Menu Handlers
#===============================================================================
MenuHandlers.add(:options_menu, :bgm_volume, {
  "name"        => _INTL("Music Volume"),
  "order"       => 10,
  "type"        => SliderOption,
  "parameters"  => [0, 100, 5],
  "description" => _INTL("Adjust the volume of the background music."),
  "get_proc"    => proc { next $PokemonSystem.bgmvolume },
  "set_proc"    => proc { |value, scene|
    $PokemonSystem.bgmvolume = value
    next if scene.in_load_screen || $game_system.playing_bgm.nil?
    bgm = $game_system.getPlayingBGM
    $game_system.bgm_pause; $game_system.bgm_resume(bgm)
  }
})

MenuHandlers.add(:options_menu, :se_volume, {
  "name"        => _INTL("SE Volume"),
  "order"       => 20,
  "type"        => SliderOption,
  "parameters"  => [0, 100, 5],
  "description" => _INTL("Adjust the volume of sound effects."),
  "get_proc"    => proc { next $PokemonSystem.sevolume },
  "set_proc"    => proc { |value, _scene|
    $PokemonSystem.sevolume = value
  }
})

MenuHandlers.add(:options_menu, :text_speed, {
  "name"        => _INTL("Text Speed"),
  "order"       => 30,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Slow"), _INTL("Mid"), _INTL("Fast"), _INTL("Instant")],
  "description" => _INTL("Choose the speed at which text appears."),
  "get_proc"    => proc { next $PokemonSystem.textspeed },
  "set_proc"    => proc { |value, scene|
    $PokemonSystem.textspeed = value
    MessageConfig.pbSetTextSpeed(MessageConfig.pbSettingToTextSpeed(value))
  }
})

MenuHandlers.add(:options_menu, :battle_animations, {
  "name"        => _INTL("Battle Effects"),
  "order"       => 40,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Choose whether you wish to see move animations in battle."),
  "get_proc"    => proc { next $PokemonSystem.battlescene },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.battlescene = value }
})

MenuHandlers.add(:options_menu, :battle_style, {
  "name"        => _INTL("Battle Style"),
  "order"       => 50,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Switch"), _INTL("Set")],
  "description" => _INTL("Choose whether you can switch Pokémon when an opponent faints."),
  "get_proc"    => proc { next $PokemonSystem.battlestyle },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.battlestyle = value }
})

MenuHandlers.add(:options_menu, :movement_style, {
  "name"        => _INTL("Default Movement"),
  "order"       => 60,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Walking"), _INTL("Running")],
  "description" => _INTL("Choose your default movement speed."),
  "get_proc"    => proc { next $PokemonSystem.runstyle },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.runstyle = value }
})

MenuHandlers.add(:options_menu, :give_nicknames, {
  "name"        => _INTL("Give Nicknames"),
  "order"       => 70,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Give"), _INTL("Don't give")],
  "description" => _INTL("Choose whether you can nickname a Pokémon when you obtain it."),
  "get_proc"    => proc { next $PokemonSystem.givenicknames },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.givenicknames = value }
})