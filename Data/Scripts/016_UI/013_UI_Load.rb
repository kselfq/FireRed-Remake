#===============================================================================
# Load Screen - 1600x720 - 1x Scale Sprites & 9-Patch Buttons
#===============================================================================
class PokemonLoadPlayerSprite < Sprite
  def initialize(trainer, viewport = nil)
    super(viewport)
    filename = (trainer.gender == 0) ? "Graphics/Pictures/introBoy" : "Graphics/Pictures/introGirl"
    @anim_bitmap = AnimatedBitmap.new(filename)
    self.bitmap = @anim_bitmap.bitmap
    @frame_count = 12
    @width = self.bitmap.width / @frame_count
    @height = self.bitmap.height
    self.src_rect.set(0, 0, @width, @height)
    
    @current_frame = 0
    @timer = 0
    @pause_duration = 80 
    @animating = true
  end

  def update
    return if !@animating
    @timer += 1
    if @current_frame < @frame_count
      if @timer % 6 == 0
        @current_frame += 1
        self.src_rect.x = @current_frame * @width if @current_frame < @frame_count
      end
    else
      if @timer >= (@frame_count * 6) + @pause_duration
        @current_frame = 0; @timer = 0; self.src_rect.x = 0
      end
    end
  end

  def dispose
    @anim_bitmap.dispose
    super
  end
end

class PokemonLoadPanel < Sprite
  attr_reader :selected

  def initialize(index, title, isContinue, trainer, stats, mapid, viewport = nil)
    super(viewport)
    @index = index
    @title = title
    @selected = (index == 0)
    @btn_width = 760   
    @btn_height = 60  
    self.bitmap = Bitmap.new(@btn_width, @btn_height)
    @refreshBitmap = true
    refresh
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    @refreshBitmap = true
    refresh
  end

  def refresh
    return if disposed?
    if @refreshBitmap
      @refreshBitmap = false
      self.bitmap.clear
      
      image_name = @selected ? "button sel" : "button unsel2"
      begin
        skin = RPG::Cache.windowskin(image_name)
      rescue
        skin = Bitmap.new(80, 80)
        skin.fill_rect(0, 0, 80, 80, Color.new(200, 200, 200))
      end
      
      #--- 9-PATCH RENDERING ---
      m = 24 
      src_w = skin.width
      src_h = skin.height
      dest_w = @btn_width
      dest_h = @btn_height

      self.bitmap.blt(0, 0, skin, Rect.new(0, 0, m, m))
      self.bitmap.blt(dest_w - m, 0, skin, Rect.new(src_w - m, 0, m, m))
      self.bitmap.blt(0, dest_h - m, skin, Rect.new(0, src_h - m, m, m))
      self.bitmap.blt(dest_w - m, dest_h - m, skin, Rect.new(src_w - m, src_h - m, m, m))
      self.bitmap.stretch_blt(Rect.new(m, 0, dest_w - (m * 2), m), skin, Rect.new(m, 0, src_w - (m * 2), m))
      self.bitmap.stretch_blt(Rect.new(m, dest_h - m, dest_w - (m * 2), m), skin, Rect.new(m, src_h - m, src_w - (m * 2), m))
      self.bitmap.stretch_blt(Rect.new(0, m, m, dest_h - (m * 2)), skin, Rect.new(0, m, m, src_h - (m * 2)))
      self.bitmap.stretch_blt(Rect.new(dest_w - m, m, m, dest_h - (m * 2)), skin, Rect.new(src_w - m, m, m, src_h - (m * 2)))
      self.bitmap.stretch_blt(Rect.new(m, m, dest_w - (m * 2), dest_h - (m * 2)), skin, Rect.new(m, m, src_w - (m * 2), src_h - (m * 2)))

      pbSetSystemFont(self.bitmap)
      self.bitmap.font.size = 32
      self.bitmap.font.bold = true
      current_text_color = @selected ? Color.new(255, 255, 255) : Color.new(0, 0, 0)
      text_y = (@btn_height - self.bitmap.font.size) / 2 - 4
      textpos = [[@title, @btn_width / 2, text_y, 2, current_text_color, Color.new(0, 0, 0, 0)]]
      pbDrawTextPositions(self.bitmap, textpos)
    end
  end
end

class PokemonLoad_Scene
  # Added 'variables' argument at the end
  def pbStartScene(commands, show_continue, trainer, stats, map_id, variables = nil)
    @commands = commands
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    addBackgroundOrColoredPlane(@sprites, "background", "Load/bg", Color.new(248, 248, 248), @viewport)

    @btn_w = 760
    @btn_h = 60
    @spacing = 16
    bottom_margin = 56
    @btn_x = (Graphics.width - @btn_w) / 2
    @total_btns_height = (commands.length * @btn_h) + ((commands.length - 1) * @spacing)
    @start_y = Graphics.height - bottom_margin - @total_btns_height

    if show_continue
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @sprites["overlay"].z = 99999
      pbSetSystemFont(@sprites["overlay"].bitmap)
      totalsec = stats&.play_time.to_i || 0
      time_val = sprintf("%02d:%02d", totalsec / 3600, (totalsec / 60) % 60)
      
      # --- FIX MAP NAME PLACEHOLDERS ---
      map_name = pbGetMapNameFromId(map_id)
      
      if map_name
        # 1. Replace \PN with Player Name
        map_name = map_name.gsub(/\\PN/, trainer.name)
        
        # 2. Replace \v[n] with Variable Value (if variables exist)
        if variables
          map_name = map_name.gsub(/\\v\[(\d+)\]/) { variables[$1.to_i] }
        end
      end
      # ---------------------------------

      lx = @btn_x - 60
      vx = lx + 200 
      text_bottom_anchor = @start_y - 64
      y4 = text_bottom_anchor - 32
      y3 = y4 - 45
      y2 = y3 - 45
      y1 = y2 - 100

      @sprites["overlay"].bitmap.font.size = 32
      @sprites["overlay"].bitmap.font.bold = true
      
      textpos = [
        [map_name, lx, y2, 0, Color.new(255,255,255), Color.new(0,0,0,0)],
        [_INTL("Pokédex:"), lx, y3, 0, Color.new(255,255,255), Color.new(0,0,0,0)],
        [_INTL("{1} Pokémon", trainer.pokedex.seen_count), vx, y3, 0, Color.new(255,255,255), Color.new(0,0,0,0)],
        [_INTL("Play time:"), lx, y4, 0, Color.new(255,255,255), Color.new(0,0,0,0)],
        [time_val, vx, y4, 0, Color.new(255,255,255), Color.new(0,0,0,0)]
      ]
      pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
      
      @sprites["overlay"].bitmap.font.size = 56
      pbDrawTextPositions(@sprites["overlay"].bitmap, [[trainer.name, lx, y1, 0, Color.new(255,255,255), Color.new(0,0,0,0)]])

      @sprites["player"] = PokemonLoadPlayerSprite.new(trainer, @viewport)
      @sprites["player"].x = Graphics.width - 780
      @sprites["player"].y = 80
      @sprites["player"].zoom_x = 1.0 
      @sprites["player"].zoom_y = 1.0
    end

    commands.length.times do |i|
      @sprites["panel#{i}"] = PokemonLoadPanel.new(i, commands[i], false, trainer, stats, map_id, @viewport)
      @sprites["panel#{i}"].x = @btn_x
      @sprites["panel#{i}"].y = @start_y + (i * (@btn_h + @spacing))
    end

    @sprites["arrow"] = Sprite.new(@viewport)
    @sprites["arrow"].bitmap = RPG::Cache.load_bitmap("Graphics/UI/", "sel_arrow")
    @sprites["arrow"].z = 100000
    @sprites["arrow"].ox = 20
    @sprites["arrow"].oy = 30
    @cursor_timer = 0
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].visible = false
  end

  def pbSetParty(trainer); end
  def pbStartScene2; pbFadeInAndShow(@sprites) { pbUpdate }; end

  def pbUpdate
    oldi = @sprites["cmdwindow"].index rescue 0
    pbUpdateSpriteHash(@sprites)
    newi = @sprites["cmdwindow"].index rescue 0
    if oldi != newi
      @sprites["panel#{oldi}"].selected = false if @sprites["panel#{oldi}"]
      @sprites["panel#{newi}"].selected = true if @sprites["panel#{newi}"]
    end
    if @sprites["arrow"]
      @cursor_timer += 1
      @sprites["arrow"].y = @start_y + (newi * (@btn_h + @spacing)) + (@btn_h / 2)
      @sprites["arrow"].x = @btn_x - 10 + (Math.sin(@cursor_timer / 6.0) * 8)
    end
    @sprites["player"].update if @sprites["player"]
  end

  # --- MOUSE HELPER ---
  def isMouseOverPanel(index)
    panel = @sprites["panel#{index}"]
    return false if !panel || panel.disposed?
    mx, my = Input.mouse_x, Input.mouse_y
    return (mx >= panel.x && mx < panel.x + panel.bitmap.width &&
            my >= panel.y && my < panel.y + panel.bitmap.height)
  end

  def pbChoose(commands)
    @sprites["cmdwindow"].commands = commands
    last_mouse_x = Input.mouse_x
    last_mouse_y = Input.mouse_y
    
    loop do
      Graphics.update; Input.update; pbUpdate
      
      # --- Mouse Hover Logic ---
      if Input.mouse_x != last_mouse_x || Input.mouse_y != last_mouse_y
        commands.length.times do |i|
          if isMouseOverPanel(i)
            # Check if index is different before updating to prevent spamming SE
            if @sprites["cmdwindow"].index != i
              old_index = @sprites["cmdwindow"].index
              @sprites["cmdwindow"].index = i
              
              # Force update graphics immediately
              if @sprites["panel#{old_index}"]
                @sprites["panel#{old_index}"].selected = false 
              end
              if @sprites["panel#{i}"]
                @sprites["panel#{i}"].selected = true 
              end
              
              pbPlayCursorSE
            end
          end
        end
        last_mouse_x = Input.mouse_x
        last_mouse_y = Input.mouse_y
      end
      
      # --- Mouse Click Logic ---
      if Input.trigger?(Input::MOUSELEFT)
        commands.length.times do |i|
          if isMouseOverPanel(i)
            return i
          end
        end
      end
      
      return @sprites["cmdwindow"].index if Input.trigger?(Input::USE)
      return -1 if Input.trigger?(Input::BACK)
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
    @save_data = SaveData.exists? ? SaveData.read_from_file(SaveData::FILE_PATH) : {}
  end

  def pbStartLoadScreen
    commands = []
    cmd_continue = cmd_new_game = cmd_options = -1
    show_continue = !@save_data.empty?
    commands[cmd_continue = commands.length] = _INTL("Continue your adventure") if show_continue
    commands[cmd_new_game = commands.length] = _INTL("Start a new game")
    commands[cmd_options = commands.length]  = _INTL("Change your options")
    map_id = show_continue ? (@save_data[:map_factory].map.map_id rescue 0) : 0
    
    # --- UPDATED CALL: Passing @save_data[:variables] ---
    @scene.pbStartScene(commands, show_continue, @save_data[:player], 
                        @save_data[:stats], map_id, @save_data[:variables])
    @scene.pbStartScene2
    loop do
      command = @scene.pbChoose(commands)
      case command
      when cmd_continue
        @scene.pbEndScene; Game.load(@save_data); return
      when cmd_new_game
        @scene.pbEndScene; Game.start_new; return
      when cmd_options
        pbFadeOutIn {
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        }
      when -1 then break
      end
    end
    @scene.pbEndScene
  end
end