#======================================================================================
# Dynamic Z-Ordering
# Author: Zik
#
# Description:
# Converts specific map tiles into independent sprites.
# This allows them to have a dynamic Z coordinate based on their Y position,
#=================================================================================

class Sprite_DynamicTile < Sprite

  def initialize(viewport, map, x, y)
    super(viewport)
    @map = map
    @tile_x = x
    @tile_y = y
    @priority = 0
    
    # Generate graph.
    create_composite_bitmap
    update_position_and_z
    refresh_tone
  end

  def create_composite_bitmap
    # We created a 32x32 bitmap.
    self.bitmap = Bitmap.new(32, 32)
    tileset_name = @map.tileset_name
    tileset_data = $data_tilesets[@map.tileset_id]

    max_prio = 0
    
    # We iterate ONLY the top layers (1 and 2).
    [1, 2].each do |layer|
      tile_id = @map.data[@tile_x, @tile_y, layer]
      next if tile_id.nil? || tile_id == 0
      
      # We obtain the tile graphic.
      source_bmp = RPG::Cache.tile(tileset_name, tile_id, 0)
      self.bitmap.blt(0, 0, source_bmp, source_bmp.rect)
      
      prio = tileset_data.priorities[tile_id]
      max_prio = prio if prio > max_prio
    end
    
    @priority = max_prio
    self.ox = 0
    self.oy = 0
  end

  def update_position_and_z
    real_x = @tile_x * 128
    real_y = @tile_y * 128
    self.x = ((real_x - @map.display_x) / 4.0).round
    self.y = ((real_y - @map.display_y) / 4.0).round
    self.z = (self.y + 32) + (@priority * 32)
  end

  def refresh_tone
    if $game_map.metadata&.outdoor_map
      if defined?(PBDayNight)
        tone = PBDayNight.getTone
        self.tone.set(tone.red, tone.green, tone.blue, tone.gray)
      else
        self.tone.set(0, 0, 0, 0)
      end
    else
      self.tone.set(0, 0, 0, 0)
    end
  end

  def update
    super
    update_position_and_z
    if self.viewport
      self.color = self.viewport.color
    end
  end
end

#===============================================================================
# TILES MANAGER IN SPRITESET_MAP
#===============================================================================
class Spriteset_Map
  attr_reader :zbox_hidden_coords

  alias zbox_tilefix_dispose dispose
  def dispose   
    zbox_dispose_dynamic_tiles
    zbox_tilefix_dispose
  end

  unless method_defined?(:zbox_tilefix_update)
    alias zbox_tilefix_update update
  end

  def update
    zbox_tilefix_update
    return unless @zbox_dynamic_tiles
    
    current_tone = nil
    if $game_map.metadata&.outdoor_map && defined?(PBDayNight)
      current_tone = PBDayNight.getTone
    end

    if @last_tile_tone.nil? || (current_tone && (
       @last_tile_tone.red != current_tone.red ||
       @last_tile_tone.green != current_tone.green ||
       @last_tile_tone.blue != current_tone.blue ||
       @last_tile_tone.gray != current_tone.gray))
      @last_tile_tone = current_tone ? current_tone.clone : Tone.new(0,0,0,0)
      @zbox_dynamic_tiles.each { |sprite| sprite.refresh_tone }
    end
    @zbox_dynamic_tiles.each { |sprite| sprite.update }
  end

  def zbox_create_dynamic_tiles
    @zbox_dynamic_tiles ||= []
    @zbox_hidden_coords = {}
    zbox_dispose_dynamic_tiles
    
    if ZBox_TileFix::DEBUG_LOG
      ZBox_Stress.log "[ZBox TileFix] Starting the creation of dynamic tiles..." 
    end
    
    if !@map
      ZBox_Stress.log "[ZBox TileFix] Error: @map is nil" if ZBox_TileFix::DEBUG_LOG
      return
    end

    return unless @map
    
    tileset_id = @map.tileset_id
    raw_target_ids = ZBox_TileFix::TILES_TO_FIX[tileset_id]    
    return unless raw_target_ids
    
    # Check if this tileset has a configuration.
    target_ids = raw_target_ids.map { |id| id + ZBox_TileFix::ID_OFFSET }
    
    if !target_ids
      ZBox_Stress.log "[ZBox TileFix] There is no setting for Tileset #{tileset_id}" if ZBox_TileFix::DEBUG_LOG
      return
    end
    
    ZBox_Stress.log "[ZBox TileFix] Searching for the following Tile IDs: #{target_ids.inspect}"
    
    count = 0
    viewport = Spriteset_Map.viewport

    # Scan the map (Only done once per load).
    (0...map.width).each do |x|
      (0...map.height).each do |y|
        found_target = false
        [1, 2].each do |layer|
          tid = @map.data[x, y, layer]
          if tid && tid > 0 && target_ids.include?(tid)
            found_target = true
            break
          end
        end

        if found_target
          # We create ONE single composite sprite for this coordinate.
          sprite = Sprite_DynamicTile.new(viewport, @map, x, y)
          @zbox_dynamic_tiles.push(sprite)
          
          # We mark this coordinate to hide it in the Renderer.
          @zbox_hidden_coords[[x, y]] = true
          
          count += 1
        end
      end
    end

    if $scene.is_a?(Scene_Map) && $scene.map_renderer
      $scene.map_renderer.zbox_set_hidden_coords(@zbox_hidden_coords)
      $scene.map_renderer.refresh # Force redraw to hide the old ones.
    end
    
    if ZBox_TileFix::DEBUG_LOG
      ZBox_Stress.log "[ZBox TileFix] Created #{count} composite sprites."
    end
  end

  def zbox_dispose_dynamic_tiles
    return unless @zbox_dynamic_tiles
    @zbox_dynamic_tiles.each { |sprite| sprite.dispose }
    @zbox_dynamic_tiles.clear
    if $scene.is_a?(Scene_Map) && $scene.map_renderer
      $scene.map_renderer.zbox_set_hidden_coords({})
    end
  end
end

#===============================================================================
# EVENT HOOK
#===============================================================================
EventHandlers.add(:on_new_spriteset_map, :zbox_tile_fix_create,
  proc { |spriteset, viewport|
    spriteset.zbox_create_dynamic_tiles
  }
)

#===============================================================================
# PATCH TO TILEMAPRENDERER
#===============================================================================
class TilemapRenderer
  def zbox_set_hidden_coords(coords_hash)
    @zbox_hidden_coords = coords_hash
  end

  # We intercept the moment when the graphic is assigned to a tile.
  alias zbox_tilefix_refresh_tile refresh_tile
  def refresh_tile(tile, x, y, map, layer, tile_id)
    zbox_tilefix_refresh_tile(tile, x, y, map, layer, tile_id)
    
    # If we have a list of hidden coordinates...
    if @zbox_hidden_coords && layer > 0
      
      # Calculate Scroll X in Tiles
      scroll_x = map.display_x.to_f / Game_Map::X_SUBPIXELS
      scroll_y = map.display_y.to_f / Game_Map::Y_SUBPIXELS

      real_map_x = ((tile.x + scroll_x) / TilemapRenderer::DISPLAY_TILE_WIDTH).round
      real_map_y = ((tile.y + scroll_y) / TilemapRenderer::DISPLAY_TILE_HEIGHT).round
    
      if @zbox_hidden_coords[[real_map_x, real_map_y]]
        # Ocultamos el tile original
        tile.visible = false
      end
    end
  end
end