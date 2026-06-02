#===============================================================================
#  Class to handle the construction and animation of opposing and player
#  party indicators (Fixed Position / No Bar / Left-to-Right Fill Version)
#===============================================================================
class PartyLineupEBDX
  attr_reader :loaded
  attr_accessor :toggle
  #-----------------------------------------------------------------------------
  def initialize(viewport, scene, battle, side)
    @viewport = viewport
    @scene = scene
    @sprites = @scene.sprites
    @battle = battle
    @side = side
    @num = Battle::Scene::NUM_BALLS
    @toggle = true
    @loaded = false
    @disposed = false
    
    # We only need the Balls graphic now
    @partyBalls = pbBitmap("Graphics/EBDX/Pictures/UI/partyBalls")
    
    # Track the last known state of the party to detect changes
    @last_party_state = []
    
    # Initialize the ball sprites directly
    for k in 0...@num
      @sprites["partyBall_#{@side}_#{k}"] = Sprite.new(@viewport)
      @sprites["partyBall_#{@side}_#{k}"].z = 99999
      @sprites["partyBall_#{@side}_#{k}"].visible = false 
    end

    # Show immediately in wild battles for player
    if @side == 0
      self.refresh(true)
    end
  end

  #-----------------------------------------------------------------------------
  #  refresh graphics and positions
  #-----------------------------------------------------------------------------
  def refresh(animate = true)
    @toggle = true
    pty = self.party 
    current_state = []
    
    # Define Base Positions
    if @side % 2 == 0
      # PLAYER
      base_x = 3
      base_y = 625
    else
      # FOE
      base_x = @viewport.width - 111
      base_y = 3
    end

    # Create and Position Balls
    for k in 0...@num
      sprite = @sprites["partyBall_#{@side}_#{k}"]
      sprite.visible = true
      sprite.bitmap = Bitmap.new(@partyBalls.height, @partyBalls.height)
      
      # Determine Pin Style
      if pty[k].nil?
        pin = 3 # Empty
      elsif pty[k].hp < 1 || pty[k].egg?
        pin = 2 # Fainted
      elsif EliteBattle.ShowStatusIcon(pty[k].status)
        pin = 1 # Status
      else
        pin = 0 # Normal
      end
      
      current_state.push(pty[k] ? [pty[k].species, pty[k].hp, pty[k].status] : nil)

      # Draw the ball icon
      sprite.bitmap.blt(0, 0, @partyBalls, Rect.new(@partyBalls.height*pin, 0, @partyBalls.height, @partyBalls.height))
      sprite.opacity = 255
      
      # Position with 18px gap
      sprite.x = base_x + (k * 18)
      sprite.y = base_y
    end
    
    @last_party_state = current_state
    @loaded = true
  end

  #-----------------------------------------------------------------------------
  #  update (Linked to Databox visibility)
  #-----------------------------------------------------------------------------
  def update
    return if !@loaded

    # 1. AUTO-REFRESH LOGIC
    current_check = []
    pty = self.party 
    for k in 0...@num
      current_check.push(pty[k] ? [pty[k].species, pty[k].hp, pty[k].status] : nil)
    end
    
    if @last_party_state != current_check
      self.refresh(false)
    end

    # 2. VISIBILITY LINKED TO DATABOX
    # Player side (0) checks databox 0 and 2; Foe side (1) checks 1 and 3
    indices = (@side == 0) ? [0, 2] : [1, 3]
    is_databox_showing = false
    
    indices.each do |idx|
      db_sprite = @scene.sprites["dataBox_#{idx}"]
      if db_sprite && !db_sprite.disposed?
        # Check both visibility flag and opacity
        if db_sprite.visible && db_sprite.opacity > 0
          is_databox_showing = true
          break
        end
      end
    end

    # Apply visibility to the balls for this side
    for k in 0...@num
      sprite = @sprites["partyBall_#{@side}_#{k}"]
      if sprite && !sprite.disposed?
        sprite.visible = is_databox_showing
      end
    end
  end

  #-----------------------------------------------------------------------------
  def party
    party = @battle.pbParty(@side).clone
    (@num - party.length).times { party.push(nil) }
    return party
  end

  def disposed?; return @disposed; end
  def dispose
    return if @disposed
    @partyBalls.dispose if @partyBalls
    for k in 0...@num
       @sprites["partyBall_#{@side}_#{k}"].dispose if @sprites["partyBall_#{@side}_#{k}"]
    end
    @disposed = true
  end
  
  def x; return 0; end
  def y; return 0; end
  def x=(val); end
  def y=(val); end
  def visible=(val); end
end

#===============================================================================
#  Override standard party line up
#===============================================================================
class Battle::Scene
  alias pbShowPartyLineup_ebdx pbShowPartyLineup unless self.method_defined?(:pbShowPartyLineup_ebdx)
  def pbShowPartyLineup(side, fullAnim = false)
    if side%2 == 0
      @playerLineUp.refresh
    else
      @opponentLineUp.refresh
    end
  end
end
