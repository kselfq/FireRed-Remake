#===============================================================================
#  EBDX Ability Messages override (manual position offsets)
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  #  Configurable offsets
  #-----------------------------------------------------------------------------
  PLAYER_SLIDE_OFFSET_X = 0   # adjust left/right
  PLAYER_SLIDE_OFFSET_Y = -200   # adjust up/down
  FOE_SLIDE_OFFSET_X = 0      # adjust left/right
  FOE_SLIDE_OFFSET_Y = 200     # adjust up/down
  #-----------------------------------------------------------------------------
  #  Show ability splash message
  #-----------------------------------------------------------------------------
  def pbShowAbilitySplash(battler = nil, ability = nil)
    return if battler.nil? || !Battle::Scene::USE_ABILITY_SPLASH

    effect = (ability.is_a?(String)) ? ability : GameData::Ability.get(battler.ability).name
    bitmap = pbBitmap("Graphics/EBDX/Pictures/UI/abilityMessage")
    rect = playerBattler?(battler) ? Rect.new(0, bitmap.height / 2, bitmap.width, bitmap.height / 2) : Rect.new(0, 0, bitmap.width, bitmap.height / 2)
    @sprites["abilityMessage"].bitmap.clear
    @sprites["abilityMessage"].bitmap.blt(0, bitmap.height / 2, bitmap, rect)
    bitmap = @sprites["abilityMessage"].bitmap

    # Draw text
    if playerBattler?(battler)
      pbDrawOutlineText(bitmap, 28, 4, bitmap.width - 38, bitmap.font.size, _INTL("{1}'s", battler.name), Color.white, Color.new(0, 0, 0, 30), 0)
      pbDrawOutlineText(bitmap, 0, bitmap.height / 2 + 4, bitmap.width - 28, bitmap.font.size, "#{effect}", Color.white, Color.new(0, 0, 0, 30), 2)
    else
      pbDrawOutlineText(bitmap, 0, 4, bitmap.width - 28, bitmap.font.size, _INTL("{1}'s", battler.name), Color.white, Color.new(0, 0, 0, 30), 2)
      pbDrawOutlineText(bitmap, 28, bitmap.height / 2 + 4, bitmap.width - 38, bitmap.font.size, "#{effect}", Color.white, Color.new(0, 0, 0, 30), 0)
    end

    width = bitmap.width
    # Set initial X based on side
    @sprites["abilityMessage"].x = playerBattler?(battler) ? -width + PLAYER_SLIDE_OFFSET_X : Graphics.width + FOE_SLIDE_OFFSET_X
    # Set Y based on databox + offset
    @sprites["abilityMessage"].y = @sprites["dataBox_#{battler.index}"].y + (playerBattler?(battler) ? PLAYER_SLIDE_OFFSET_Y : FOE_SLIDE_OFFSET_Y)

    pbSEPlay("EBDX/Ability Message")

    # Slide animation
    target_x = playerBattler?(battler) ? 0 + PLAYER_SLIDE_OFFSET_X : Graphics.width - width + FOE_SLIDE_OFFSET_X
    steps = 10
    dx = (target_x - @sprites["abilityMessage"].x) / steps.to_f
    @sprites["abilityMessage"].zoom_y = 0
    steps.times do
      @sprites["abilityMessage"].x += dx
      @sprites["abilityMessage"].zoom_y += 0.1
      self.wait(1, true)
    end
    @sprites["abilityMessage"].x = target_x

    # Flash effect
    @sprites["abilityMessage"].tone = Tone.new(255, 255, 255)
    16.times do
      @sprites["abilityMessage"].tone.all -= 16 if @sprites["abilityMessage"].tone.all > 0
      self.wait(1, true)
    end
  end
  #-----------------------------------------------------------------------------
  #  Hide ability splash
  #-----------------------------------------------------------------------------
  def pbHideAbilitySplash(battler = nil)
    return if battler.nil? || !Battle::Scene::USE_ABILITY_SPLASH
    width = @sprites["abilityMessage"].bitmap.width
    @sprites["abilityMessage"].zoom_y = 0
    @sprites["abilityMessage"].x = playerBattler?(battler) ? -width + PLAYER_SLIDE_OFFSET_X : Graphics.width + FOE_SLIDE_OFFSET_X
  end
  #-----------------------------------------------------------------------------
  #  Replace message splash
  #-----------------------------------------------------------------------------
  def pbReplaceAbilitySplash(battler)
    return if battler.nil? || !Battle::Scene::USE_ABILITY_SPLASH
    pbShowAbilitySplash(battler)
  end
end
