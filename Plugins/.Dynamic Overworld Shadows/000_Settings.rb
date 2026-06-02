#===============================================================================
# Dynamic Overworld Shadows
#
# Author: Zik
# Description:
# Automatic (and dynamic) shadow system for the Overworlds.
#===============================================================================

# Events can accept these keywords for custom configuration:
# (sr:'n')           The shadow radius in BASIC / STANDARD modes. 
# (sx:'n')           Move the shadow by x.
# (sy:'n')           Move the shadow by yx.
# (top)              To make both the event and the shadow stand out above all else
# (fly:'n')          It simulates height in the shadow; it will become smaller 
#                    and its opacity will be reduced.
# (stop)             This option disables the script's idle animation.
# (angle:'n')        Adjust the angle of the shadow.
# (rgb: R, G, B)     Change the color of the shadow.

# NOTE: Please be aware that regardless of the settings in MAP_OVERRIDES or 
# AUTOSIZE_FIX,if an event has these keys, they will take priority.

#===============================================================================
# CONFIGURATION MODULE
#===============================================================================
module ZBox_Shadows
  #=============================================================================
  # General Settings
  #=============================================================================
  
  # Base color of the shadow (R, G, B, Alpha).
  SHADOW_COLOR = Color.new(1, 1, 1, 80)

  # Sync reflections with shadow shape?
  # If true, the reflections in the water will have the same  
  # squash effect as the Enhanced shadow..
  SYNC_REFLECTION_SQUASH = false

  # Default shadow radius (in pixels) for BASIC/STANDARD mode.
  DEFAULT_RADIUS = 15

  # Activate automatic calculation in STANDARD mode.
  STANDARD_AUTO_SIZE = true

  # Adjust this if you feel the shadow is too close to your 
  # feet, too low, or too far to the sides.
  SHADOW_OFFSET_X = 0
  SHADOW_OFFSET_Y = -6

  # Z value for events with the tag (top).
  ALWAYS_ON_TOP_Z = 9999

  # Fade-out speed when entering/exiting restricted areas (water, etc.).
  #  15: Fast but smooth (Recommended).
  #  5: Very slow.
  #  255: Instant (Pop-up).
  TERRAIN_FADE_SPEED = 15

  #-----------------------------------------------------------------------------
  # Shape Configuration
  #-----------------------------------------------------------------------------

  # "Squashing" Factor (Height/Width Ratio).
  # 1.0 = Perfect circle.
  # 0.5 = Height is half the width (Standard isometric style).
  # 0.3 = Very squashed (thin line).
  SHADOW_HEIGHT_RATIO = 0.45

  # Shape Threshold (Corner Clipping).
  # Controls how "square" or "round" the pixelated shadow is.
  # 1.0 = Perfect mathematical ellipse.
  # 0.95 = Slightly clipped edges.
  # 0.85 = More clipped corners.
  # 0.70 = Diamond/rhombus shape.
  SHADOW_SHAPE_THRESHOLD = 0.85

  #-----------------------------------------------------------------------------
  # Animation Settings (Jumps)
  #-----------------------------------------------------------------------------
  
  # Minimum shadow scale when jumping (0.0 to 1.0).
  # 0.5 = The shadow is reduced to half its size.
  # 1.0 = The shadow does not change size when jumping.
  JUMP_MIN_SCALE = 0.5

  # Reference height (in pixels) to reach the minimum scale.
  # The higher this number, the slower the shadow will shrink.
  # 80 pixels is a good reference for standard jumps.
  JUMP_HEIGHT_THRESHOLD = 80

  #-----------------------------------------------------------------------------
  # Animation Settings (STANDARD Mode - Move)
  #-----------------------------------------------------------------------------
  
  # Step Rhythm Frequency.
  # Controls how quickly the "up/down" cycle occurs while moving.
  #  0.08: Normal pace.
  #  0.15: Very fast steps.
  #  0.04: Slow/heavy steps.
  ANIM_PULSE_FREQUENCY = 0.08

  # Effect Intensity.
  # Controls how much the shadow size changes with each step.
  #  0.06: Visible but subtle effect.
  #  0.12: Very stretchy effect (Cartoon).
  #  0.02: Almost imperceptible vibration.
  ANIM_PULSE_AMPLITUDE = 0.06

  # Speed ​​Stretch.
  # How much the base shadow widens simply by drawing quickly (not including pulse).
  #  0.02: Subtle stretch.
  #  0.05: Significant speed distortion.
  #  0.00: No base stretch.
  ANIM_VELOCITY_STRETCH = 0.02

  #-----------------------------------------------------------------------------
  # ENHANCED Mode Configuration (Real Silhouette)
  #-----------------------------------------------------------------------------
  
  # Vertical Squash Factor.
  # Controls the perspective of the projected shadow.
  #  0.5: The shadow is half the height of the character (Standard).
  #  0.3: Very long shadow/lying on the ground.
  #  0.8: Almost vertical shadow (midday).
  ENHANCED_SQUASH_Y = 0.5

  # Invert the shadow vertically.
  #  true: The shadow projects "backwards" (like a mirror on the ground).
  #  false: The shadow flattens upon itself.
  ENHANCED_FLIP_Y = true

  # Shadow angle (angle in degrees).
  # Simulates the sun's position.
  # 0: Straight, vertical shadow (Noon).
  # 20: Shadow tilted to the right (Sun to the left).
  # 20: Shadow tilted to the left (Sun to the right).
  ENHANCED_SLANT_ANGLE = 0

  # Activate idle animation.
  ENHANCED_IDLE_ANIM = true
  
  # Idle animation speed.
  #  4.0: Slow and relaxed.
  #  8.0: Hectic.
  ENHANCED_IDLE_SPEED = 4.0
  
  # Intensity (How much it widens/contracts).
  #  0.04: Subtle (3% variation).
  #  0.08: Very visible.
  ENHANCED_IDLE_INTENSITY = 0.04

  #-----------------------------------------------------------------------------
  # Clipping Settings
  #-----------------------------------------------------------------------------
  
  # Enable automatic clipping on walls.
  # If there is a solid obstacle directly below the character, the shadow will be 
  # clipped so it doesn't appear on top of the tile.
  WALL_CLIPPING = false
  
  # Clipping margin (in pixels).
  # How many pixels of the shadow we allow to overlap onto the next tile before 
  # clipping it. A value of 4 or 6 usually looks natural.
  WALL_CLIP_MARGIN = -6


  #=============================================================================
  # Blacklists (Filters)
  #=============================================================================
  
  # If true, it distinguishes between uppercase and lowercase ("Door" != "door").
  CASE_SENSITIVE = false

  # Event names that will NEVER have a shadow.
  # Check if the event name CONTAINS any of these words.
  BLACKLIST_NAMES = [
    "door", "puerta", "nurse", "enfermera", "mostrador", 
    "smashrock", "rocarompible", "strengthboulder", "piedrafuerza",
    "cuttree", "arbolcorte", "headbutttree", "arbolgolpecabeza",
    "berryplant", "plantabayas", 
    ".sl", ".noshadow", "no_shadow"
  ]

  # Terrain Tags where the shade should be eliminated.
  # For example: Deep water, puddles.
  BLACKLIST_TERRAIN_TAGS = [
     :DeepWater, :StillWater, :Water, :Waterfall, :WaterfallCrest, :Puddle
  ]

  #-----------------------------------------------------------------------------
  # CHARACTER_FIX
  #-----------------------------------------------------------------------------
  # If the file name CONTAINS the key, these rules apply.
  #
  # Available options:
  #   :disable => true                 (Without shadow)
  #   :fly     => 0-100                (Simulate height)
  #   :stop    => true                 (No idle animation)
  #   :top     => true                 (Always on Top)
  #   :off_x   => -n...n               (Offset X)
  #   :off_y   => -n...n               (Offset Y)
  #   :angle   => Degrees              (Angle of the shadow)
  #   :color   => Color.new(...)       (Shadow Color)
  
  CHARACTER_FIX = {
    # BlackList.
    "nil"      => { :disable => true },
    "door"    => { :disable => true },
    
    # Pokémon that fly or levitate.
    "Pokemon 08"  => { :fly => 40 },
    "Pokemon 09"   => { :fly => 20, :color => Color.new(100, 0, 150), :off_y   => 5 },
    
    # Objects on the floor.
    "Object ball"    => { :stop => true },
  }

  #-----------------------------------------------------------------------------
  # Auto-Size Fix
  #-----------------------------------------------------------------------------
  # Define the exact radius for certain graphics.
  # Format: "EXACT_NAME"  => n
  
  AUTOSIZE_FIX = {
    #"NPC 01" => 20,
    #"NPC 05" => 12,
    #"NPC 08" => 8,
    "NPC 10" => 16
    
  }

  #-----------------------------------------------------------------------------
  # Map Overrides Configuration
  #-----------------------------------------------------------------------------
  
  # Define special rules for specific maps using their ID. 
  # Available options:
  #   :disable => true             (Disable shadows across the entire map)
  #   :color   => Color.new(...)   (Change the base color of all shadows)
  #   :opacity => 0-255            (Change the base opacity)
  #   :angle   => Degrees          (Force a global angle/tilt)
  
  MAP_OVERRIDES = {
    # Example: Map ID 5 (Dark Cave) -> No shadows.
    # 5 => { :disable => true },

    # Example: Map ID 10 (Distortion World) -> Purple Shadows.
    # 10 => { :color => Color.new(80, 0, 120), :opacity => 180 },

    # Example: Map ID 12 (Sunset) -> Slanted Shadows.
    # 12 => { :angle => 25 }
  }

  # Helper method to read the configuration (Do not touch).
  def self.get_map_setting(key)
    return nil unless $game_map
    map_data = MAP_OVERRIDES[$game_map.map_id]
    return nil unless map_data
    return map_data[key]
  end
end

module ZBox_TileFix 
  # Define which tiles from which Tileset will become Sprites.
  # Structure: ID_TILESET => [ID_TILE_1, ID_TILE_2, ...]

  # To find the ID, you can use the IDs.png file included in the plugin folder.
  # NOTE: The image is indexed.
  TILES_TO_FIX = {
    # Example: Tileset ID 1 (Outside)
    # We converted fences, mailboxes, and the tops of houses and laboratorie.
    1 => [970, 1296, 1297, 1298, 1584, 1585, 1586, 1587, 1588,
          3078, 3079, 3098, 3099, 3100, 3101, 3102, 3103],
    }

  # Base offset of RPG Maker XP for tilesets (DO NOT MODIFY).
  ID_OFFSET = 384
  
  # Displays in console how many tiles were converted upon entering the map.
  DEBUG_LOG = false
    
end

module ZBox_Stress
  GRAPHICS_DIR = "Graphics/Characters/"
  
  # Speeds and Frequencies
  MOVE_SPEEDS = [3, 4, 4, 5, 5, 6]
  MOVE_FREQUENCIES = [4, 5, 6, 6]
  
  # Probabilities (0-100%)
  CHANCE_SHADOW_SIZE = 40  # Probability of changing size
  CHANCE_OFFSET      = 30  # Probability of having X/Y offset
  CHANCE_FLY         = 25  # Probability of flying
  CHANCE_TOP         = 10  # Probability of Always On Top
  CHANCE_STOP        = 15  # Probability of Stop Animation
  CHANCE_DISABLE     = 5   # Probability of disabling shadow (.sl)

  def self.log(message)
    should_log = defined?(ZBox_TileFix::DEBUG_LOG) ? ZBox_TileFix::DEBUG_LOG : true
    
    if should_log
      puts "#{message}\n"
    end
  end
end