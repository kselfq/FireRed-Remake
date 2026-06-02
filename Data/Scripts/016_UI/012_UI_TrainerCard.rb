#===============================================================================
# Adapted for 1600x720 Resolution - Custom Grid, Text, and Specific Sprite Pos
#===============================================================================
class PokemonTrainerCard_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    
	@sprites["btn_back"] = IconSprite.new(16, 16, @viewport)
    @sprites["btn_back"].setBitmap("Graphics/UI/back")
    @sprites["btn_back"].z = 250
	
    # Background logic
    background = pbResolveBitmap("Graphics/UI/Trainer Card/bg_f")
    if $player.female? && background
      addBackgroundPlane(@sprites, "bg", "Trainer Card/bg_f", @viewport)
    else
      addBackgroundPlane(@sprites, "bg", "Trainer Card/bg", @viewport)
    end
    
    # Card logic
    cardexists = pbResolveBitmap(_INTL("Graphics/UI/Trainer Card/card_f"))
    @sprites["card"] = IconSprite.new(0, 0, @viewport)
    if $player.female? && cardexists
      @sprites["card"].setBitmap(_INTL("Graphics/UI/Trainer Card/card_f"))
    else
      @sprites["card"].setBitmap(_INTL("Graphics/UI/Trainer Card/card"))
    end
    
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlay"].bitmap.font.size = 32
    
    # --- Custom Trainer Sprite Logic (Aligned to x=772, y=252) ---
    @sprites["trainer"] = IconSprite.new(772, 252, @viewport)
    if $player.female?
      @sprites["trainer"].setBitmap("Graphics/UI/Trainer Card/female_sprite")
    else
      @sprites["trainer"].setBitmap("Graphics/UI/Trainer Card/male_sprite")
    end
    @sprites["trainer"].z = 2
    
    pbDrawTrainerCardFront
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbDrawTrainerCardFront
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor   = Color.new(72, 72, 72)
    shadowColor = Color.new(192, 32, 40, 0)
    
    # Logic for 00:00 Time Format
    totalsec = $stats.play_time.to_i
    hour = totalsec / 3600
    min = (totalsec / 60) % 60
    time_formatted = sprintf("%02d:%02d", hour, min)
    
    $PokemonGlobal.startTime = Time.now if !$PokemonGlobal.startTime
    starttime = _INTL("{1} {2}, {3}",
                      pbGetAbbrevMonthName($PokemonGlobal.startTime.mon),
                      $PokemonGlobal.startTime.day,
                      $PokemonGlobal.startTime.year)
    
    # Text positions as per your layout
    textPositions = [
      [_INTL("Name"), 246, 184, :left, baseColor, shadowColor],
      [$player.name, 726, 184, :right, baseColor, shadowColor],
      
      [_INTL("ID No."), 792, 184, :left, baseColor, shadowColor],
      [sprintf("%05d", $player.public_ID), 1022, 184, :right, baseColor, shadowColor],
      
      [_INTL("Money"), 246, 274, :left, baseColor, shadowColor],
      [_INTL("${1}", $player.money.to_s_formatted), 726, 274, :right, baseColor, shadowColor],
      
      [_INTL("Pokédex"), 246, 364, :left, baseColor, shadowColor],
      [_INTL("{1} Pokémon", $player.pokedex.owned_count), 726, 364, :right, baseColor, shadowColor],
      
      [_INTL("Time played"), 246, 454, :left, baseColor, shadowColor],
      [time_formatted, 726, 454, :right, baseColor, shadowColor],
      
      [_INTL("Started"), 246, 544, :left, baseColor, shadowColor],
      [starttime, 726, 544, :right, baseColor, shadowColor]
    ]
    pbDrawTextPositions(overlay, textPositions)

    region = pbGetCurrentRegion(0)
    # --- Badge Grid Config ---
    start_x = 1121 
    start_y = 48 
    cols = 2
    badge_size = 140
    spacing_x = 161
    spacing_y = 161

    badge_bitmap = Bitmap.new("Graphics/UI/Trainer Card/icon_badges")
    8.times do |i|
      next if !$player.badges[i + (region * 8)]
      col = i % cols
      row = i / cols
      x = start_x + (col * spacing_x)
      y = start_y + (row * spacing_y)
      src_rect = Rect.new(i * badge_size, region * badge_size, badge_size, badge_size)
      overlay.blt(x, y, badge_bitmap, src_rect)
    end
    badge_bitmap.dispose
  end

  def pbTrainerCard
    pbSEPlay("GUI trainer card open")
    loop do
      Graphics.update; Input.update; pbUpdate
      
      # --- INVISIBLE EXIT BUTTON LOGIC ---
      if Input.trigger?(Input::MOUSELEFT)
        exit_w = 96
        exit_h = 96
        exit_x = 16
        exit_y = 16
        
        if Input.mouse_x >= exit_x && Input.mouse_x < exit_x + exit_w &&
           Input.mouse_y >= exit_y && Input.mouse_y < exit_y + exit_h
           pbPlayCloseMenuSE
           break
        end
      end

      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class PokemonTrainerCardScreen
  def initialize(scene); @scene = scene; end
  def pbStartScreen
    @scene.pbStartScene
    @scene.pbTrainerCard
    @scene.pbEndScene
  end
end