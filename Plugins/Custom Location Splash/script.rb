#===============================================================================
# Custom Cinematic Location Splash - Final Refined Animations
#===============================================================================
class LocationWindow
  def initialize(name)
    if $active_location_splash
      $active_location_splash.dispose
    end
    $active_location_splash = self

    @name = name
    @timer = 0
    # 2.5 seconds of "static" display + animation time
    @max_time = (2 * Graphics.frame_rate).to_i 
    @exiting = false
    
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    # --- Position #2: Middle Graphic (placename1) ---
    @sprites["placename1"] = IconSprite.new(0, 0, @viewport)
    @sprites["placename1"].setBitmap("Graphics/UI/placename1")
    @sprites["placename1"].ox = @sprites["placename1"].bitmap.width / 2
    @sprites["placename1"].oy = @sprites["placename1"].bitmap.height / 2
    @sprites["placename1"].x = Graphics.width / 2
    @sprites["placename1"].y = 614 + (@sprites["placename1"].bitmap.height / 2)
    @sprites["placename1"].zoom_x = 1.0 
    @sprites["placename1"].zoom_y = 0   
    @sprites["placename1"].z = 20

    # --- Position #3: Bottom Graphic (placename2) - SOFT FADE ---
    @sprites["placename2"] = IconSprite.new(0, 0, @viewport)
    @sprites["placename2"].setBitmap("Graphics/UI/placename2")
    @sprites["placename2"].ox = @sprites["placename2"].bitmap.width / 2
    @sprites["placename2"].x = Graphics.width / 2
    @sprites["placename2"].y = 614
    @sprites["placename2"].z = 10
    @sprites["placename2"].opacity = 0 # Start invisible for soft fade

    # --- Position #1: Place Name Text ---
    @sprites["text"] = BitmapSprite.new(Graphics.width, 100, @viewport)
    @sprites["text"].y = 626
    @sprites["text"].z = 30
    @sprites["text"].opacity = 0
    
    draw_text_content
  end

  def draw_text_content
    bitmap = @sprites["text"].bitmap
    bitmap.font.name = "poki"
    bitmap.font.size = 38
    bitmap.font.bold = true
    pbDrawTextPositions(bitmap, [[@name, Graphics.width / 2, 0, 2, Color.new(255,255,255), nil]])
  end

  def update
    return if disposed?
    
    if !@exiting
      @timer += 1
      # --- ENTRANCE ANIMATIONS ---
      # placename1: Vertical Stretch
      if @timer <= 12
        @sprites["placename1"].zoom_y += 0.09
        @sprites["placename1"].zoom_y = 1.0 if @sprites["placename1"].zoom_y > 1.0
      end
      # Text: Fade In
      if @timer >= 10 && @timer <= 25
        @sprites["text"].opacity += 17
      end
      # placename2: Soft Fade In
      if @timer >= 15 && @timer <= 35
        @sprites["placename2"].opacity += 13
      end
      
      # Start exit sequence after 2.5 seconds
      @exiting = true if @timer >= @max_time
    else
      # --- EXIT ANIMATIONS (REVERSED) ---
      # placename2: Soft Fade Out
      @sprites["placename2"].opacity -= 15
      
      # Text: Fade Out
      if @sprites["placename2"].opacity < 150
        @sprites["text"].opacity -= 20
      end
      
      # placename1: Vertical Shrink
      if @sprites["text"].opacity < 100
        @sprites["placename1"].zoom_y -= 0.12
      end

      # Fully dispose once everything is hidden/shrunk
      dispose if @sprites["placename1"].zoom_y <= 0 && @sprites["text"].opacity <= 0
    end
  end

  def disposed?; return @sprites.empty?; end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    $active_location_splash = nil if $active_location_splash == self
  end
end

#===============================================================================
# Animation Engine Hooks - The State Machine & Queue Fix
#===============================================================================

# Initialize our session states safely
$splash_startup_done ||= false
$splash_queued ||= false
$splash_last_map ||= 0

# 1. The Master Controller (Runs every frame)
EventHandlers.add(:on_frame_update, :master_splash_controller,
  proc {
    # Always update the animation if it is currently playing
    $active_location_splash.update if $active_location_splash

    # Safety locks: Stop here if a splash is playing, or if the map isn't fully loaded
    next if $active_location_splash
    next if !$game_map || $game_map.map_id <= 0

    # SCENARIO A: Game Start (Fires exactly once when you load a save)
    if !$splash_startup_done
      $splash_startup_done = true
      $splash_last_map = $game_map.map_id
      
      meta = GameData::MapMetadata.try_get($game_map.map_id)
      if meta && meta.announce_location
        LocationWindow.new($game_map.name)
      end
      next # Skip the rest of this frame so we don't double-fire
    end

    # SCENARIO B: Map Transfer (Fires only when a splash is in the queue)
    if $splash_queued
      $splash_queued = false # Empty the queue immediately
      $splash_last_map = $game_map.map_id
      
      meta = GameData::MapMetadata.try_get($game_map.map_id)
      if meta && meta.announce_location
        LocationWindow.new($game_map.name)
      end
    end
  }
)

# 2. The Queue Trigger (Fires only when physically walking between maps)
EventHandlers.add(:on_map_transfer, :queue_location_splash,
  proc { |old_map_id|
    # If the new map is different from the last one we showed a splash for, queue it up
    if $game_map && $game_map.map_id != $splash_last_map
      $splash_queued = true
    end
  }
)

# 3. Reset the State Machine when returning to the Title Screen
# This ensures it works correctly if you quit to the menu and load a different save
EventHandlers.add(:on_start_title, :reset_splash_state,
  proc {
    $splash_startup_done = false
    $splash_queued = false
    $splash_last_map = 0
  }
)