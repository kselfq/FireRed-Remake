#===============================================================================
# SPRITE_ZBOXSHADOW
#===============================================================================
class Sprite_ZBoxShadow < Sprite
  #-----------------------------------------------------------------------------
  # --- CACHE SYSTEM FOR BASIC AND STANDARD ---
  #-----------------------------------------------------------------------------
  @@bitmap_cache = {}
  
  # Maximum number of shadows in memory before purging.
  CACHE_LIMIT = 100 

  def self.clear_cache
    @@bitmap_cache.each_value { |b| b.dispose if b && !b.disposed? }
    @@bitmap_cache.clear
  end

  def self.get_shadow_bitmap(radius)
    self.clear_cache if @@bitmap_cache.size > CACHE_LIMIT

    ratio = ZBox_Shadows::SHADOW_HEIGHT_RATIO
    threshold = ZBox_Shadows::SHADOW_SHAPE_THRESHOLD
    key = [radius, ratio, threshold]
    return @@bitmap_cache[key] if @@bitmap_cache[key] && !@@bitmap_cache[key].disposed?
    
    bmp = self.create_procedural_bitmap(radius, ratio, threshold)
    @@bitmap_cache[key] = bmp
    return bmp
  end

  def self.create_procedural_bitmap(radius, ratio, threshold)
    width = radius * 2
    height = (width * ratio).to_i
    height = 2 if height < 2
    width += 1 if width.odd?
    height += 1 if height.odd?
    
    bitmap = Bitmap.new(width, height)
    center_x = (width / 2.0) - 0.5
    center_y = (height / 2.0) - 0.5
    color = ZBox_Shadows::SHADOW_COLOR.clone
    color.alpha = 255
    
    (0...width).each do |x|
      (0...height).each do |y|
        dx = (x - center_x) / (width / 2.0)
        dy = (y - center_y) / (height / 2.0)
        distance_sq = dx*dx + dy*dy
        
        if distance_sq <= threshold
          bitmap.set_pixel(x, y, color)
        end
      end
    end
    return bitmap
  end

  #-----------------------------------------------------------------------------
  # --- INITIATORS ---
  #-----------------------------------------------------------------------------
  def initialize(viewport, character, sprite_character)
    super(viewport)
    @character = character
    @sprite_character = sprite_character
    @mode = $PokemonSystem.zbox_shadow_mode
    @disposed = false
    
    # Counter for step animation.
    @anim_counter = 0.0

    # Visual Initialization.
    self.visible = false

    # Always under the character.
    self.z = @sprite_character.z - 1 

    # If the event should NOT have a shadow (Blacklist, water, etc.), 
    # it is born invisible.
    if !@character.zbox_should_show_shadow?
      self.opacity = 0
    else
      base_alpha = ZBox_Shadows::SHADOW_COLOR.alpha
      # If it flies, it's born more transparent.
      fly_height = @character.zbox_fly_height
      if fly_height > 0
        base_alpha = [base_alpha - fly_height, 20].max
      end
      self.opacity = base_alpha
    end

    refresh_bitmap
  end

  def dispose
    return if @disposed
    super
    @disposed = true
  end  

  # Helper to check if the event is near the screen.
  def on_screen?
    # 64 pixel margin around the screen.
    margin = 64
    sx = @character.screen_x
    sy = @character.screen_y
    
    return false if sx < -margin || sx > Graphics.width + margin
    return false if sy < -margin || sy > Graphics.height + margin
    return true
  end 
  
  @@real_width_cache = {}
  # Calculate actual width.
  def self.get_real_char_width(bitmap, char_name, char_hue)
    key = [char_name, char_hue]
    
    return @@real_width_cache[key] if @@real_width_cache[key]
    return 32 if !bitmap || bitmap.disposed?

    frame_width = bitmap.width / 4
    frame_height = bitmap.height / 4
    
    min_x = frame_width
    max_x = 0
    found_pixel = false
    (0...frame_width).each do |x|
      has_pixel = false
      (0...frame_height).each do |y|
        if bitmap.get_pixel(x, y).alpha > 10
          has_pixel = true
          break
        end
      end
      
      if has_pixel
        min_x = x
        found_pixel = true
        break
      end
    end
    
    unless found_pixel
      @@real_width_cache[key] = 32
      return 32
    end

    (frame_width - 1).downto(0) do |x|
      has_pixel = false
      (0...frame_height).each do |y|
        if bitmap.get_pixel(x, y).alpha > 10
          has_pixel = true
          break
        end
      end
      
      if has_pixel
        max_x = x
        break
      end
    end
    
    real_width = (max_x - min_x) + 1
    @@real_width_cache[key] = real_width
    return real_width
  end

  # Generate the graph procedurally.
  def refresh_bitmap
    # Only applies to Basic/Standard modes.
    if $PokemonSystem.zbox_shadow_mode != 3
      
      radius = 0     
      # Priority: Tag Manual.
      custom_size = @character.zbox_custom_shadow_size

      # Auto Size.
      # We try to obtain the actual width of the sprite.
      if custom_size
        radius = custom_size
      else
        # Logic by Mode
        is_standard_mode = ($PokemonSystem.zbox_shadow_mode == 2)
        use_auto_size = is_standard_mode && ZBox_Shadows::STANDARD_AUTO_SIZE
        
        if use_auto_size
          char_name = @character.character_name
          fixed_radius = nil
          
          ZBox_Shadows::AUTOSIZE_FIX.each do |key, val|
            if ZBox_Shadows::CASE_SENSITIVE
              if char_name.include?(key)
                fixed_radius = val
                break
              end
            else
              if char_name.downcase.include?(key.downcase)
                fixed_radius = val
                break
              end
            end
          end
          
          if fixed_radius
            radius = fixed_radius
          else
            char_width = 32
            if @sprite_character.bitmap && !@sprite_character.bitmap.disposed?
              char_width = Sprite_ZBoxShadow.get_real_char_width(
                @sprite_character.bitmap, 
                @character.character_name, 
                @character.character_hue
              )
            end
            radius = (char_width * 0.45).to_i.clamp(6, 64)
          end
        else
          radius = ZBox_Shadows::DEFAULT_RADIUS
        end
      end
      
      self.bitmap = Sprite_ZBoxShadow.get_shadow_bitmap(radius)
      self.ox = self.bitmap.width / 2
      self.oy = self.bitmap.height / 2
      self.color.set(0, 0, 0, 0)
      self.src_rect.set(0, 0, self.bitmap.width, self.bitmap.height)
    end
  end

  def update
    return if @disposed
    
    # --- SAFETY CHECK ---
    if $PokemonSystem.zbox_shadow_mode != 3 && (!self.bitmap || self.bitmap.disposed?)
      refresh_bitmap
    end
    
    super

    # --- CULLING ---
    unless on_screen?
      self.visible = false
      return
    end

    # If the system is globally shut down (OFF).
    if $PokemonSystem.zbox_shadow_mode == 0
      self.visible = false
      return
    end

    # Update Position and Shape.
    if $PokemonSystem.zbox_shadow_mode == 3 # ENHANCED
      update_enhanced_shadow
    else
      update_procedural_shadow
    end

    # Update Opacity Transition (Fade).
    update_opacity_transition
  end 

  #=============================================================================
  # ENHANCED LOGIC (Real Silhouette)
  #=============================================================================
  def update_enhanced_shadow
    @last_mode = 3 
    if @sprite_character.bitmap && !@sprite_character.bitmap.disposed?
      if self.bitmap != @sprite_character.bitmap
        self.bitmap = @sprite_character.bitmap
      end
    end
    return unless self.bitmap

    # Custom Color.
    custom_color = @character.zbox_shadow_color
    if !custom_color
      map_color = ZBox_Shadows.get_map_setting(:color)
      custom_color = map_color if map_color
    end

    if custom_color
      # We use the custom color (R, G, B, 255).
      self.color.set(custom_color.red, custom_color.green, custom_color.blue, 255)
    else
      # Default: Solid Black.
      self.color.set(0, 0, 0, 255)
    end

    self.src_rect = @sprite_character.src_rect
    self.ox = @sprite_character.ox
    self.oy = @sprite_character.oy
    self.mirror = @sprite_character.mirror

    # Bush Fix (Origen).
    bush_depth = @character.bush_depth
    self.oy -= bush_depth if bush_depth > 0

    off_x = @character.zbox_custom_shadow_offset_x || ZBox_Shadows::SHADOW_OFFSET_X
    off_y = @character.zbox_custom_shadow_offset_y || ZBox_Shadows::SHADOW_OFFSET_Y    
    self.x = @sprite_character.x + off_x

    base_y = @character.jumping? ? @character.screen_y_ground : @sprite_character.y
    base_y -= bush_depth if bush_depth > 0
    self.y = base_y + off_y
    
    # Z Ordering.
    if @character.zbox_always_on_top?
      self.z = ZBox_Shadows::ALWAYS_ON_TOP_Z - 1
    else
      self.z = @sprite_character.z - 1
    end

    # Transformation.
    squash = ZBox_Shadows::ENHANCED_SQUASH_Y
    flip_factor = ZBox_Shadows::ENHANCED_FLIP_Y ? -1 : 1
    
    # Custom Angle
    custom_angle = @character.zbox_shadow_angle
    if !custom_angle
      custom_angle = ZBox_Shadows.get_map_setting(:angle)
    end

    if custom_angle
      self.angle = custom_angle
    else
      self.angle = ZBox_Shadows::ENHANCED_SLANT_ANGLE
    end

    # Fly Calc.
    fly_height = @character.zbox_fly_height
    fly_zoom_factor = 1.0
    if fly_height > 0
      base_factor = [1.0 - (fly_height * 0.01), 0.2].max
      
      # Hover Effect.
      if !@character.jumping?
        hover_wave = Math.sin(System.uptime * 3.0) * 0.05
        fly_zoom_factor = base_factor + hover_wave
      else
        fly_zoom_factor = base_factor
      end
    end

    # Wall Clipping.
    if ZBox_Shadows::WALL_CLIPPING && !@character.jumping?
      if should_clip_shadow?
        shadow_height = self.src_rect.height * squash * fly_zoom_factor
        dist_to_edge = 16 + ZBox_Shadows::WALL_CLIP_MARGIN
        if shadow_height > dist_to_edge
          pixels_to_keep = (dist_to_edge / (squash * fly_zoom_factor)).to_i
          cut_amount = self.src_rect.height - pixels_to_keep
          cut_amount = cut_amount.clamp(0, self.src_rect.height)
          if cut_amount > 0
            self.src_rect.y += cut_amount
            self.src_rect.height -= cut_amount
            self.oy -= cut_amount
          end
        end
      end
    end
    
    if @character.jumping?
      # Jump.
      self.y = @character.screen_y_ground + off_y
      dist = (@sprite_character.y - @character.screen_y_ground).abs
      progress = (dist.to_f / ZBox_Shadows::JUMP_HEIGHT_THRESHOLD).clamp(0.0, 1.0)
      scale_jump = 1.0 - (progress * 0.5)
      final_scale = scale_jump * fly_zoom_factor
      self.zoom_x = scale_jump
      self.zoom_y = squash * flip_factor * scale_jump
    else
      base_zoom_x = 1.0 * fly_zoom_factor
      base_zoom_y = squash * flip_factor

      if bush_depth > 0
        # Empirical factor: Stretch a little to compensate for the rise.
        bush_stretch = 1.0 + (bush_depth * 0.04)
        base_zoom_y *= bush_stretch
        self.y += ZBox_Shadows::SHADOW_OFFSET_Y + 12
      end
       
      # Idle Animation.
      if ZBox_Shadows::ENHANCED_IDLE_ANIM && !@character.moving? && !@character.zbox_stop_anim? && !$game_temp.in_menu 
         
        time = System.uptime
        speed = ZBox_Shadows::ENHANCED_IDLE_SPEED
        intensity = ZBox_Shadows::ENHANCED_IDLE_INTENSITY
         
        wave = Math.sin(time * speed) * intensity
         
        # Zoom X: Widens and narrows (1.0 +/- wavelength).
        self.zoom_x = base_zoom_x + wave
         
        # Zoom Y: Volume compensation.
        # If it widens (X goes up), it flattens (Y goes down).
        # We multiply by the flip factor to maintain the inversion.
        # The 0.5 softens the effect on Y so it's not so exaggerated.
        self.zoom_y = base_zoom_y - (wave * squash * flip_factor * 0.5)
         
      else
        self.zoom_x = base_zoom_x
        self.zoom_y = base_zoom_y
      end
    end

    self.visible = @sprite_character.visible
  end

  #=============================================================================
  # --- PROCEDURAL LOGIC FOR BASIC / STANDARD ---
  #=============================================================================
  def update_procedural_shadow
    has_wrong_bitmap = (@sprite_character.bitmap && self.bitmap == @sprite_character.bitmap)
    if @last_mode != $PokemonSystem.zbox_shadow_mode
      refresh_bitmap
      @last_mode = $PokemonSystem.zbox_shadow_mode
    end

    # Custom Color.
    custom_color = @character.zbox_shadow_color
    if !custom_color
      map_color = ZBox_Shadows.get_map_setting(:color)
      custom_color = map_color if map_color
    end

    if custom_color
      # We use the custom color (R, G, B, 255).
      self.color.set(custom_color.red, custom_color.green, custom_color.blue, 255)
    else
      # Default: Solid Black.
      self.color.set(0, 0, 0, 255)
    end
    
    # Position.
    final_off_x = ZBox_Shadows::SHADOW_OFFSET_X
    final_off_y = ZBox_Shadows::SHADOW_OFFSET_Y

    tag_x = @character.zbox_custom_shadow_offset_x
    tag_y = @character.zbox_custom_shadow_offset_y
    
    final_off_x = tag_x if tag_x
    final_off_y = tag_y if tag_y

    tag_x = @character.zbox_custom_shadow_offset_x
    tag_y = @character.zbox_custom_shadow_offset_y
    
    final_off_x = tag_x if tag_x
    final_off_y = tag_y if tag_y
    
    self.x = @sprite_character.x + final_off_x
    
    # Bush Fix.
    bush_depth = @character.bush_depth
    base_y = @character.jumping? ? @character.screen_y_ground : @sprite_character.y
    base_y -= bush_depth if bush_depth > 0
    self.y = base_y + final_off_y
    
    # Z Ordering.
    if @character.zbox_always_on_top?
      self.z = ZBox_Shadows::ALWAYS_ON_TOP_Z - 1
    else
      self.z = @sprite_character.z - 1
    end
    
    self.visible = @sprite_character.visible
    self.mirror = false

    # Custom Angle.
    custom_angle = @character.zbox_shadow_angle
    if !custom_angle
      custom_angle = ZBox_Shadows.get_map_setting(:angle)
    end

    self.angle = custom_angle ? custom_angle : 0
    
    # Animation (Standard) + Fly Logic.
    update_animation_procedural
  end
  
  def update_animation_procedural
    # Static Fly Calc
    fly_height = @character.zbox_fly_height
    base_fly_factor = (fly_height > 0) ? [1.0 - (fly_height * 0.01), 0.2].max : 1.0

    # Jump
    if @character.jumping?
      self.y = @character.screen_y_ground + (@character.zbox_custom_shadow_offset_y || ZBox_Shadows::SHADOW_OFFSET_Y)
      dist = (@sprite_character.y - @character.screen_y_ground).abs
      progress = (dist.to_f / ZBox_Shadows::JUMP_HEIGHT_THRESHOLD).clamp(0.0, 1.0)
      target_scale = 1.0 - (progress * (1.0 - ZBox_Shadows::JUMP_MIN_SCALE))
      
      final_scale = target_scale * base_fly_factor
      self.zoom_x = final_scale
      self.zoom_y = final_scale
      @anim_counter = 0.0 
      return 
    end

    case $PokemonSystem.zbox_shadow_mode
    when 1 # BASIC (Static).
      self.zoom_x = 1.0 * base_fly_factor
      self.zoom_y = 1.0 * base_fly_factor

    when 2 # STANDARD (Basic Dynamic).
      current_fly_factor = base_fly_factor
      if fly_height > 0
        hover_wave = Math.sin(System.uptime * 3.0) * 0.05
        current_fly_factor += hover_wave
      end

      if $game_temp.in_menu 
      elsif @character.moving?
        speed = @character.move_speed
        @anim_counter += speed * ZBox_Shadows::ANIM_PULSE_FREQUENCY
        pulse = Math.sin(@anim_counter) * ZBox_Shadows::ANIM_PULSE_AMPLITUDE
        base_stretch = speed * ZBox_Shadows::ANIM_VELOCITY_STRETCH
        
        # We applied Fly Factor to the base.
        target_zoom_x = (1.0 + base_stretch + pulse) * current_fly_factor
        target_zoom_y = (1.0 - (base_stretch * 0.5) + pulse) * current_fly_factor
        
        self.zoom_x = (self.zoom_x * 0.7) + (target_zoom_x * 0.3)
        self.zoom_y = (self.zoom_y * 0.7) + (target_zoom_y * 0.3)
      else
        # IDLE.
        @anim_counter = 0.0
        base_zoom = 1.0 * current_fly_factor
        
        # We use the same settings as Enhanced for consistency.
        if ZBox_Shadows::ENHANCED_IDLE_ANIM && !@character.zbox_stop_anim?
           time = System.uptime
           speed = ZBox_Shadows::ENHANCED_IDLE_SPEED
           intensity = ZBox_Shadows::ENHANCED_IDLE_INTENSITY

           current_width = (self.bitmap ? self.bitmap.width : 32) * base_zoom
           
           if current_width < 32
             boost = (32.0 / [current_width, 1].max).clamp(1.0, 3.0)
             intensity *= boost
           end

           wave = Math.sin(time * speed) * intensity
           
           self.zoom_x = base_zoom + wave
           # Volume compensation: If X increases, Y decreases slightly.
           self.zoom_y = base_zoom - (wave * 0.5)
        else
           self.zoom_x = base_zoom
           self.zoom_y = base_zoom
        end
      end
    else 
      self.zoom_x = 1.0
      self.zoom_y = 1.0
    end
  end 

  # Transition Management.
  def update_opacity_transition
    # Determine Target Opacity.
    target_opacity = 0
    
    # If the character should cast a shadow (according to terrain, name, etc.).
    if @character.zbox_should_show_shadow?

      base_alpha = ZBox_Shadows::SHADOW_COLOR.alpha

      # Fly Calc.
      fly_height = @character.zbox_fly_height
      if fly_height > 0
        # Reduce opacity based on height. 
        # At: Height 10 -> Subtract 20 from opacity.
        base_alpha = [base_alpha - (fly_height * 2), 0].max
      end

      target_opacity = (@sprite_character.opacity * base_alpha) / 255.0
    else
      target_opacity = 0
    end

    speed = ZBox_Shadows::TERRAIN_FADE_SPEED
    
    if self.opacity < target_opacity
      # Fade In.
      self.opacity = [self.opacity + speed, target_opacity].min
    elsif self.opacity > target_opacity
      # Fade Out.
      self.opacity = [self.opacity - speed, target_opacity].max
    end

    # We are only visible if we have some opacity. And the father is visible.
    self.visible = (self.opacity > 0) && @sprite_character.visible
  end

  def should_clip_shadow?
    x = @character.x
    # We look at the tile BELOW.
    y = @character.y + 1 
    
    return false unless $game_map.valid?(x, y)

    # Review Tiles (Layers 2, 1, 0).
    [2, 1, 0].each do |i|
      tile_id = $game_map.data[x, y, i]
      next if tile_id == 0
      
      tileset = $data_tilesets[$game_map.tileset_id]
      priority = tileset.priorities[tile_id]
      passage = tileset.passages[tile_id]
      
      next if priority > 0
      
      if (passage & 0x0F) == 0x0F
        return true
      end
    end
    
    # Revisar Eventos Sólidos (Opcional, para rocas movibles, etc).
    $game_map.events.each_value do |event|
      next if event.x != x || event.y != y
      next if event.through # If it's a ghost, it doesn't count.
      next if event.character_name == "" # If it's invisible, it doesn't count.
      
      # If the event is solid and has no priority (it's on the ground).
      # We crop the shadow so it doesn't fall on top of it.
      return true if event.priority_type == 0
    end

    return false
  end  
end

#===============================================================================
# SPRITE_CHARACTER
#===============================================================================
class Sprite_Character
  attr_reader :zbox_shadow_sprite

  alias zbox_shadow_initialize initialize
  def initialize(viewport, character = nil)
    zbox_shadow_initialize(viewport, character)
    @zbox_shadow_sprite = nil
    
    # Create the shadow if there is a character and the system is active.
    if character && $PokemonSystem.zbox_shadow_mode > 0
      @zbox_shadow_sprite = Sprite_ZBoxShadow.new(viewport, character, self)
    end
  end

  alias zbox_shadow_dispose dispose
  def dispose
    @zbox_shadow_sprite.dispose if @zbox_shadow_sprite
    zbox_shadow_dispose
  end

  alias zbox_shadow_update update
  def update
    return if !@character
    zbox_shadow_update
    if @zbox_shadow_sprite
      if $PokemonSystem.zbox_shadow_mode == 0
        @zbox_shadow_sprite.visible = false
      else
        @zbox_shadow_sprite.update
      end
    elsif @character && $PokemonSystem.zbox_shadow_mode > 0
      @zbox_shadow_sprite = Sprite_ZBoxShadow.new(self.viewport, @character, self)
    end

    if @character && @character.zbox_always_on_top?
      self.z = ZBox_Shadows::ALWAYS_ON_TOP_Z
    end
  end

  alias zbox_safety_refresh_graphic refresh_graphic
  def refresh_graphic
    return if !@character
    zbox_safety_refresh_graphic
  end
end