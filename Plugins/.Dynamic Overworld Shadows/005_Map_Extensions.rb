#===============================================================================
# GAME_MAP EXTENSION (For priority support)
#===============================================================================
class Game_Map
  # Auxiliary method to safely obtain the priority of a tile.
  def priority(x, y)
    return 0 if !@map || !@tileset || !valid?(x, y)
    # We check from the top layer down.
    [2, 1, 0].each do |i|
      tile_id = @map.data[x, y, i]
      next if tile_id.nil? || tile_id == 0
      prio = @tileset.priorities[tile_id]
      return prio if prio > 0
    end
    return 0
  end
end

#===============================================================================
# SCENE_MAP EXTENSION (For priority support)
#===============================================================================
class Scene_Map
  alias zbox_shadows_dispose_spritesets disposeSpritesets
  def disposeSpritesets
    zbox_shadows_dispose_spritesets
  end

  alias zbox_shadows_update update
  def update
    zbox_shadows_update
  end
end

class Scene_DebugIntro
  alias zbox_shadows_debugmain main
  def main
    Sprite_ZBoxShadow.clear_cache
    zbox_shadows_debugmain
  end
end

class Scene_Intro
  alias zbox_shadows_intromain main
  def main
    Sprite_ZBoxShadow.clear_cache
    zbox_shadows_intromain
  end
end