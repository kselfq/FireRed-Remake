#===============================================================================
# REFLECTIONS PATCH (Synchronization with ZBox Shadows)
#===============================================================================

class Sprite_Reflection
  alias zbox_shadow_update update
  def update
    return if !event 
    zbox_shadow_update
    
    # We verify that the option is active and that the internal sprite exists.
    if ZBox_Shadows::SYNC_REFLECTION_SQUASH && @sprite && !@sprite.disposed? && event
      
      return unless @parent_sprite && !@parent_sprite.disposed?
      character = @parent_sprite.character
      return unless character
      squash = ZBox_Shadows::ENHANCED_SQUASH_Y
      
      # Apply Squash.
      target_zoom_x = @parent_sprite.zoom_x
      target_zoom_y = @parent_sprite.zoom_y * squash

      # Idle Animation.
      if ZBox_Shadows::ENHANCED_IDLE_ANIM && character && !character.moving? && !character.jumping?
        
        time = System.uptime
        speed = ZBox_Shadows::ENHANCED_IDLE_SPEED
        intensity = ZBox_Shadows::ENHANCED_IDLE_INTENSITY
        wave = Math.sin(time * speed) * intensity
        
        target_zoom_x += wave
        target_zoom_y -= (wave * squash * 0.5)
      end

      # We apply the calculated zooms.
      @sprite.zoom_x = target_zoom_x
      @sprite.zoom_y = target_zoom_y
      
      # We recalculate the gap in each frame because the zoom_y changes when breathing.
      screen_height = @parent_sprite.src_rect.height * @parent_sprite.zoom_y * TilemapRenderer::ZOOM_Y
      
      # We use the current zoom of the reflection to find out how much it has actually shrunk.
      current_squash_ratio = @sprite.zoom_y / @parent_sprite.zoom_y
      
      gap = screen_height * (1.0 - current_squash_ratio)
      
      # We relocated.
      @sprite.y -= gap / 2.0
      @sprite.y -= 5 * TilemapRenderer::ZOOM_Y
    end
  end
end