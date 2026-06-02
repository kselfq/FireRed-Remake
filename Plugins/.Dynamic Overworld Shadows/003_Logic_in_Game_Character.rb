#===============================================================================
# FILTERING LOGIC IN GAME_CHARACTER
#===============================================================================
class Game_Character
  attr_accessor :zbox_shadow_disabled 

  # Helper to search in the configuration hash (simple cache).
  def zbox_get_fix_data
    return nil if self.character_name == ""
    # We iterate the configuration hash.
    ZBox_Shadows::CHARACTER_FIX.each do |key, data|
      if ZBox_Shadows::CASE_SENSITIVE
        return data if self.character_name.include?(key)
      else
        return data if self.character_name.downcase.include?(key.downcase)
      end
    end
  end

  # Determine if this character should cast a shadow based on the configuration.
  def zbox_should_show_shadow?
    # Quick check: If it is disabled globally or manually.
    return false if $PokemonSystem.zbox_shadow_mode == 0
    return false if @zbox_shadow_disabled
    return false if ZBox_Shadows.get_map_setting(:disable)
    fix = zbox_get_fix_data
    return false if fix && fix[:disable]
    return false if @transparent
    return false if @tile_id > 0 
    return false if self.character_name == ""

    # Blacklist check on event names.
    if self.is_a?(Game_Event)
      event_name = @event.name
      if event_name
        return false if event_name.include?(".sl") || event_name.include?(".noshadow")
        ZBox_Shadows::BLACKLIST_NAMES.each do |bad_name|
          if ZBox_Shadows::CASE_SENSITIVE
            return false if event_name.include?(bad_name)
          else
            return false if event_name.downcase.include?(bad_name.downcase)
          end
        end
      end
    end
    
    unless zbox_always_on_top?
      terrain_tag = $game_map.terrain_tag(self.x, self.y)
      if terrain_tag
        return false if ZBox_Shadows::BLACKLIST_TERRAIN_TAGS.include?(terrain_tag.id)
      end
    end

    return true
  end
  
  # --- Auxiliary methods to customize the shadow from the event name ---
  # Get a custom radius: (sr:n).
  def zbox_custom_shadow_size
    return nil unless self.is_a?(Game_Event)
    if @event.name =~ /\(sr:\s*(\d+)\)/i
      return $1.to_i
    end
    fix = zbox_get_fix_data
    return fix[:radius] if fix && fix[:radius] 
    return nil
  end

  # Get custom Offset X: (sx:n) o (sx:-n).
  def zbox_custom_shadow_offset_x
    if self.is_a?(Game_Event) && @event.name =~ /\(sx:\s*([-\d]+)\)/i
      return $1.to_i
    end
    fix = zbox_get_fix_data
    return fix[:off_x] if fix && fix[:off_x]
    return nil
  end

  # Get custom Offset Y: (sy:n) o (sy:-n).
  def zbox_custom_shadow_offset_y
    if self.is_a?(Game_Event) && @event.name =~ /\(sy:\s*([-\d]+)\)/i
      return $1.to_i
    end
    fix = zbox_get_fix_data
    return fix[:off_y] if fix && fix[:off_y]
    return nil
  end

  # Detect if the event should always be on top: (top).
  def zbox_always_on_top?
    if self.is_a?(Game_Event) && @event.name.include?("(top)")
      return true
    end
    fix = zbox_get_fix_data
    return true if fix && fix[:top]
    return false
  end

  # Detect flight altitude: (fly:n).
  # Range recommended: 20 to 40.
  def zbox_fly_height
    if self.is_a?(Game_Event) && @event.name =~ /\(fly:\s*(\d+)\)/i
      return $1.to_i
    end
    fix = zbox_get_fix_data
    return fix[:fly] if fix && fix[:fly]
    
    return 0
  end

  # Detect if the idle animation should be stopped: (stop).
  def zbox_stop_anim?
    if self.is_a?(Game_Event) && @event.name.include?("(stop)")
      return true
    end
    fix = zbox_get_fix_data
    return true if fix && fix[:stop]
    return false
  end

  # Modify the angle: (angle: Degrees).
  def zbox_shadow_angle
    if self.is_a?(Game_Event) && @event.name =~ /\(angle:\s*([-\d]+)\)/i
      return $1.to_i
    end
    fix = zbox_get_fix_data
    return fix[:angle] if fix && fix[:angle]
    return nil
  end

  # Modify the shadow color: (rgb: R, G, B).
  def zbox_shadow_color
    if self.is_a?(Game_Event) && @event.name =~ /\(rgb:\s*(\d+),\s*(\d+),\s*(\d+)\)/i
      return Color.new($1.to_i, $2.to_i, $3.to_i, 255)
    end
    fix = zbox_get_fix_data
    return fix[:color] if fix && fix[:color]
    return nil
  end
end