#===============================================================================
# Pokédex Regional Dexes list menu screen
# * For choosing which region list to view. Only appears when there is more
#   than one accessible region list to choose from, and if
#   Settings::USE_CURRENT_REGION_DEX is false.
#===============================================================================
class Window_DexesList < Window_CommandPokemon
  def initialize(commands, commands2, width)
    @commands2 = commands2
    super(commands, width)
    @selarrow = AnimatedBitmap.new("Graphics/UI/sel_arrow_white")
    self.baseColor   = Color.new(248, 248, 248)
    self.shadowColor = Color.black
    self.windowskin  = nil
  end

  def drawItem(index, count, rect)
    super(index, count, rect)
    if index >= 0 && index < @commands2.length
      pbDrawShadowText(self.contents, rect.x + 254, rect.y + (self.contents.text_offset_y || 0),
                       64, rect.height, @commands2[index][0].to_s, self.baseColor, self.shadowColor, 1)
      pbDrawShadowText(self.contents, rect.x + 350, rect.y + (self.contents.text_offset_y || 0),
                       64, rect.height, @commands2[index][1].to_s, self.baseColor, self.shadowColor, 1)
      allseen = (@commands2[index][0] >= @commands2[index][2])
      allown  = (@commands2[index][1] >= @commands2[index][2])
      pbDrawImagePositions(
        self.contents,
        [["Graphics/UI/Pokedex/icon_menuseenown", rect.x + 236, rect.y + 6, (allseen) ? 24 : 0, 0, 24, 24],
         ["Graphics/UI/Pokedex/icon_menuseenown", rect.x + 332, rect.y + 6, (allown) ? 24 : 0, 24, 24, 24]]
      )
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokedexMenu_Scene
  SEEN_OBTAINED_TEXT_BASE   = Color.new(248, 248, 248)
  SEEN_OBTAINED_TEXT_SHADOW = Color.new(192, 32, 40)

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands, commands2)
    @commands = commands
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    
    # --- BACK BUTTON (Center Origin & Position) ---
    back_x, back_y = 16, 16
    @sprites["btn_back"] = IconSprite.new(back_x + 48, back_y + 48, @viewport)
    @sprites["btn_back"].setBitmap("Graphics/UI/back")
    @sprites["btn_back"].ox = 48
    @sprites["btn_back"].oy = 48
    @sprites["btn_back"].z = 250

    addBackgroundPlane(@sprites, "base_bg", "Pokedex/bg", @viewport)
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_menu"))
    text_tag = shadowc3tag(SEEN_OBTAINED_TEXT_BASE, SEEN_OBTAINED_TEXT_SHADOW)
    @sprites["headings"] = Window_AdvancedTextPokemon.newWithSize(
      text_tag + _INTL("SEEN") + "<r>" + _INTL("OBTAINED") + "</c3>", 286, 136, 208, 64, @viewport
    )
    @sprites["headings"].windowskin = nil
    @sprites["commands"] = Window_DexesList.new(commands, commands2, Graphics.width - 84)
    @sprites["commands"].x      = 40
    @sprites["commands"].y      = 192
    @sprites["commands"].height = 192
    @sprites["commands"].viewport = @viewport
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    ret = -1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      
      # --- BACK BUTTON CLICK & 0.7 SHRINK ANIMATION LOGIC ---
      if Input.trigger?(Input::MOUSELEFT)
        exit_x = 16
        exit_y = 16
        exit_w = 96
        exit_h = 96
        
        if Input.mouse_x >= exit_x && Input.mouse_x < exit_x + exit_w &&
           Input.mouse_y >= exit_y && Input.mouse_y < exit_y + exit_h
           
           4.times do |i|
             scale = 1.0 - ((i + 1) * 0.075)
             @sprites["btn_back"].zoom_x = scale
             @sprites["btn_back"].zoom_y = scale
             Graphics.update
             Input.update
           end
           4.times do |i|
             scale = 0.7 + ((i + 1) * 0.075)
             @sprites["btn_back"].zoom_x = scale
             @sprites["btn_back"].zoom_y = scale
             Graphics.update
             Input.update
           end

           pbPlayCloseMenuSE
           break
        end
      end

      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        ret = @sprites["commands"].index
        (ret == @commands.length - 1) ? pbPlayCloseMenuSE : pbSEPlay("GUI pokedex open")
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokedexMenuScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    commands  = []
    commands2 = []
    dexnames = Settings.pokedex_names
    $player.pokedex.accessible_dexes.each do |dex|
      if dexnames[dex].nil?
        commands.push(_INTL("Pokédex"))
      elsif dexnames[dex].is_a?(Array)
        commands.push(dexnames[dex][0])
      else
        commands.push(dexnames[dex])
      end
      commands2.push([$player.pokedex.seen_count(dex),
                      $player.pokedex.owned_count(dex),
                      pbGetRegionalDexLength(dex)])
    end
    commands.push(_INTL("Exit"))
    @scene.pbStartScene(commands, commands2)
    loop do
      cmd = @scene.pbScene
      break if cmd < 0 || cmd >= commands2.length   # Cancel/Exit
      $PokemonGlobal.pokedexDex = $player.pokedex.accessible_dexes[cmd]
      pbFadeOutIn do
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
      end
    end
    @scene.pbEndScene
  end
end
