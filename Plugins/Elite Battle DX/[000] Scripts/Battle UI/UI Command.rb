#===============================================================================
#  Command Menu functionality part
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  #  command menu override
  #-----------------------------------------------------------------------------
  alias pbCommandMenu_ebdx pbCommandMenu unless self.method_defined?(:pbCommandMenu_ebdx)
  def pbCommandMenu(*args)
    @orgPos = [@vector.x, @vector.y, @vector.angle, @vector.scale, @vector.zoom1] if @orgPos.nil?
    @idleTimer = 0 if @idleTimer < 0
    return pbCommandMenu_ebdx(*args)
  end
  #-----------------------------------------------------------------------------
  #  main command menu function
  #-----------------------------------------------------------------------------
  alias pbCommandMenuEx_ebdx pbCommandMenuEx unless self.method_defined?(:pbCommandMenuEx_ebdx)
  def pbCommandMenuEx(idxBattler, texts, mode = 0)
    self.clearMessageWindow
    # set starting variables
    @ret = 0; @vector.reset; @inCMx = true
    @commandWindow.refreshCommands(idxBattler)
    # show command window
    pbSEPlay("EBDX/SE_Zoom4", 50)
    @commandWindow.showPlay
    @sprites["dataBox_#{idxBattler}"].selected = true
    
    # Init last mouse position (Consistency with script.rb)
    @last_mouse_x = Input.mouse_x
    @last_mouse_y = Input.mouse_y

    loop do
      oldIndex = @commandWindow.index
      # main update
      self.updateWindow(@commandWindow)
      
      # --- MOUSE HOVER LOGIC ---
      # Only update selection if the mouse actually moved
      current_mouse_x = Input.mouse_x
      current_mouse_y = Input.mouse_y

      if current_mouse_x != @last_mouse_x || current_mouse_y != @last_mouse_y
        mouse_idx = @commandWindow.getMouseIndex
        if mouse_idx >= 0 && mouse_idx != @commandWindow.index
          @commandWindow.index = mouse_idx
          pbSEPlay("EBDX/SE_Select1")
        end
        @last_mouse_x = current_mouse_x
        @last_mouse_y = current_mouse_y
      end
      # -----------------------------------------------------

      # Update selected command (Keyboard - Switched to LEFT/RIGHT)
      if Input.trigger?(Input::LEFT)
        @commandWindow.index = (@commandWindow.index > 0) ? (@commandWindow.index - 1) : (@commandWindow.indexes.length - 1)
      elsif Input.trigger?(Input::RIGHT)
        @commandWindow.index = (@commandWindow.index < @commandWindow.indexes.length - 1) ? (@commandWindow.index + 1) : 0
      end
      
      # play SE
      pbSEPlay("EBDX/SE_Select1") if @commandWindow.index != oldIndex
      
      # Confirm choice
      # 1. Keyboard 'C'
      # 2. Mouse Left Click (Verified via getMouseIndex)
      if Input.trigger?(Input::C) || Input.trigger?(Input::MOUSELEFT)
        
        # If Mouse Click, verify we are clicking a valid button
        if Input.trigger?(Input::MOUSELEFT)
          clicked_index = @commandWindow.getMouseIndex
          if clicked_index >= 0
            # If we clicked a button different from current selection, update it first
            if @commandWindow.index != clicked_index
              @commandWindow.index = clicked_index
              pbSEPlay("EBDX/SE_Select1")
            end
            # Proceed to confirm
          else
            # Clicked nothing, skip confirmation
            next 
          end
        end

        if @commandWindow.index == 4 && $DEBUG
          ebsDebugMenu
        else
          pbSEPlay("EBDX/SE_Select2")
          @ret = @commandWindow.indexes[@commandWindow.index]
          @inCMx = false if @battle.doublebattle? && @ret > 0
          @lastcmd[idxBattler] = @ret
          break
        end
      elsif Input.trigger?(Input::B) && idxBattler > 0 && @lastcmd[0] != 2      # Cancel
        pbSEPlay("EBDX/SE_Select2")
        @ret = -1
        break
      elsif Input.trigger?(Input::F9) && $DEBUG                                 # Debug menu
        pbPlayDecisionSE
        ret = -2
        break
      end
    end
    # hide command window
    @commandWindow.hidePlay
    # reset vector
    if @ret > 0
      @vector.set(EliteBattle.get_vector(:MAIN, @battle))
      @vector.inc = 0.2
    end
    # unselect databoxes
    self.pbDeselectAll
    # return output
    return @ret
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Command Menu (Next Generation)
#  Horizontal Layout Overhaul (Custom Order & Adjusted Cursor)
#===============================================================================
class CommandWindowEBDX
  attr_accessor :index
  attr_accessor :overlay
  attr_accessor :backdrop
  attr_accessor :coolDown
  attr_reader :indexes
  #-----------------------------------------------------------------------------
  #  class inspector
  #-----------------------------------------------------------------------------
  def inspect
    str = self.to_s.chop
    str << format(' index: %s>', @index)
    return str
  end
  #-----------------------------------------------------------------------------
  #  constructor
  #-----------------------------------------------------------------------------
  def initialize(viewport = nil, battle = nil, scene = nil, safari = false)
    @viewport = viewport
    @battle = battle
    @scene = scene
    @safaribattle = safari
    @index = 0
    @oldindex = 0
    @coolDown = 0
    @over = false
    @path = "Graphics/EBDX/Pictures/UI/"
    @sprites = {}
    @indexes = []

    self.applyMetrics

    # --- ARROW BOBBING CURSOR (Left Center, No Rotation) ---
    @sprites["sel"] = SpriteSheet.new(@viewport)
    @sprites["sel"].bitmap = pbBitmap(@path + "arrow")
    @sprites["sel"].speed = 6
    @sprites["sel"].ox = @sprites["sel"].src_rect.width / 2
    @sprites["sel"].oy = @sprites["sel"].src_rect.height / 2
    @sprites["sel"].z = 101
    @sprites["sel"].visible = false
    
    # Cursor animation variables
    @sel_dir = 1
    @sel_speed = 1
    @sel_max = 4
    @sel_offset = 0
    
    # Background Box (if used)
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].create_rect(@viewport.width,44,Color.new(32,32,32,0))
    @sprites["bg"].bitmap = pbBitmap(@path+@barImg) if !@barImg.nil?
    @sprites["bg"].y = @viewport.height
    self.update
  end
  #-----------------------------------------------------------------------------
  #  PBS data
  #-----------------------------------------------------------------------------
  def applyMetrics
    @barImg = nil
    d1 = EliteBattle.get(:nextUI)
    d1 = d1[:COMMANDMENU] if !d1.nil? && d1.has_key?(:COMMANDMENU)
    d2 = EliteBattle.get_data(:COMMANDMENU, :Metrics, :METRICS)
    d7 = EliteBattle.get_map_data(:COMMANDMENU_METRICS)
    d6 = @battle.opponent ? EliteBattle.get_trainer_data(@battle.opponent[0].trainer_type, :COMMANDMENU_METRICS, @battle.opponent[0]) : nil
    d5 = !@battle.opponent ? EliteBattle.get_data(@battle.battlers[1].species, :Species, :COMMANDMENU_METRICS, (@battle.battlers[1].form rescue 0)) : nil
    for data in [d2, d7, d6, d5, d1]
      if !data.nil?
        @barImg = data[:BARGRAPHIC] if data.has_key?(:BARGRAPHIC) && data[:BARGRAPHIC].is_a?(String)
      end
    end
  end
  #-----------------------------------------------------------------------------
  #  re-draw command menu
  #-----------------------------------------------------------------------------
  def refreshCommands(index)
    poke = @battle.battlers[index]
    cmds = self.compileCommands(index)
    
    # --- DIMENSIONS & CONFIG ---
    btn_width = 132
    btn_height = 132
    spacing = 8       # Space between buttons
    margin_bottom = 8 # Distance from bottom screen edge
    margin_right = 16 # Distance from right screen edge
    
    # --- DEFINE GRAPHIC FILENAMES ---
    if @safaribattle
      graphics = ["ball", "bait", "rock", "run"]
    else
      # 0 = Fight, 1 = Bag, 2 = Party, 3 = Run
      graphics = ["fight", "bag", "party", "run"]
    end
    
    # Calculate Anchors for the Horizontal Grid
    total_width = (cmds.length * btn_width) + ((cmds.length - 1) * spacing)
    start_x = @viewport.width - margin_right - total_width + (btn_width / 2)
    final_y = @viewport.height - margin_bottom - (btn_height / 2)

    for i in 0...cmds.length
      @sprites["b#{i}"] = Sprite.new(@viewport)
      
      # 1. LOAD SPECIFIC GRAPHIC (Dynamically loads based on logical index mapping)
      cmd_id = @indexes[i]
      bmp_name = @path + graphics[cmd_id]
      
      if pbResolveBitmap(bmp_name)
        @sprites["b#{i}"].bitmap = pbBitmap(bmp_name)
      else
        @sprites["b#{i}"].bitmap = Bitmap.new(btn_width, btn_height) # Invisible fallback
      end
      
      # 2. SET ANCHOR POINTS
      @sprites["b#{i}"].ox = btn_width / 2
      @sprites["b#{i}"].oy = btn_height / 2

      # 3. POSITIONING
      @sprites["b#{i}"].x = start_x + (i * (btn_width + spacing))
      @sprites["b#{i}"].y = final_y + 160 # Start 160px lower to allow slide-up animation
      @sprites["b#{i}"].z = 100
    end
    
    @sprites["bg"].y = @viewport.height + 40
  end
  #-----------------------------------------------------------------------------
  #  compile command menu (Controls the visual and logical layout of buttons)
  #-----------------------------------------------------------------------------
  def compileCommands(index)
    cmd = []
    @indexes = []
    poke = @battle.battlers[index]
    
    # returns indexes and commands for Safari Battles
    if @safaribattle
      @indexes = [0, 1, 2, 3] # Ball, Bait, Rock, Run
      return [_INTL("BALL"), _INTL("BAIT"), _INTL("ROCK"), _INTL("RUN")]
    end
    
    # --- CUSTOM BUTTON ORDER ---
    # 0 = Fight
    # 1 = Bag
    # 2 = Party
    # 3 = Run
    # By defining them in this exact order, the visual layout updates to match!
    button_order = [0, 2, 1, 3] # Now structured as Fight -> Party -> Bag -> Run
    button_order.push(4) if $DEBUG && EliteBattle::SHOW_DEBUG_FEATURES
    
    for id in button_order
      val = _INTL("") # Text is hidden, so string is empty
      val = _INTL("CALL") if id == 3 && (poke.shadowPokemon? && poke.inHyperMode?)
      cmd.push(val)
      @indexes.push(id) # Assigns the correct engine ID to the button slot
    end
    
    return cmd
  end
  #-----------------------------------------------------------------------------
  #  visibility functions
  #-----------------------------------------------------------------------------
  def visible; end; def visible=(val); end
  def disposed?; end
  def dispose
    pbDisposeSpriteHash(@sprites)
  end
  def color; end; def color=(val); end
  def shiftMode=(val); end
  #-----------------------------------------------------------------------------
  #  show command menu animation
  #-----------------------------------------------------------------------------
  def show
    @sprites["sel"].visible = false
    @sprites["bg"].y -= @sprites["bg"].bitmap.height/1 if @sprites["bg"] && @sprites["bg"].bitmap
    for i in 0...@indexes.length
      next if !@sprites["b#{i}"]
      @sprites["b#{i}"].y -= 20 # 8 frames * 20 = 160px total distance
    end
  end
  def showPlay
    8.times do
      self.show; @scene.wait(1, true)
    end
  end
  #-----------------------------------------------------------------------------
  #  hide command menu animation
  #-----------------------------------------------------------------------------
  def hide(skip = false)
    return if skip
    @sprites["sel"].visible = false
    @sprites["bg"].y += @sprites["bg"].bitmap.height/4 if @sprites["bg"] && @sprites["bg"].bitmap
    for i in 0...@indexes.length
      next if !@sprites["b#{i}"]
      @sprites["b#{i}"].y += 10
    end
  end
  def hidePlay
    @sprites["sel"].visible = false
    # Fade out buttons and background over 8 frames
    8.times do
      @sprites["bg"].opacity -= 32 if @sprites["bg"]
      for i in 0...@indexes.length
        next if !@sprites["b#{i}"]
        @sprites["b#{i}"].opacity -= 32
      end
      @scene.wait(1, true)
    end
    # Ensure fully hidden at the end
    @sprites["bg"].opacity = 0 if @sprites["bg"]
    for i in 0...@indexes.length
      next if !@sprites["b#{i}"]
      @sprites["b#{i}"].opacity = 0
    end
  end
  
  #-----------------------------------------------------------------------------
  #  helper: get mouse index
  #-----------------------------------------------------------------------------
  def getMouseIndex
    return -1 if !defined?(Input.mouse_x)
    
    mx, my = Input.mouse_x, Input.mouse_y
    for i in 0...@indexes.length
      sprite = @sprites["b#{i}"]
      next if !sprite || sprite.disposed? || !sprite.visible
      
      # Calculate bounds (accounting for centered origin ox/oy)
      s_width = sprite.bitmap.width
      s_height = sprite.bitmap.height
      s_left = sprite.x - sprite.ox
      s_top = sprite.y - sprite.oy
      
      if mx >= s_left && mx < s_left + s_width && my >= s_top && my < s_top + s_height
        return i
      end
    end
    return -1
  end

  #-----------------------------------------------------------------------------
  #  update command menu
  #-----------------------------------------------------------------------------
  def update
    return if !@sprites["b#{@index}"]
    
    # --- ARROW BOBBING ANIMATION ---
    @sel_offset += @sel_speed * @sel_dir
    @sel_dir *= -1 if @sel_offset.abs >= @sel_max
    
    # Position the selector arrow directly to the left of the active button
    @sprites["sel"].visible = true
    
    # >>> ARROW POSITION ADJUSTMENT <<<
    # Change the "- 4" below to move the arrow left or right.
    # Higher negative numbers (e.g. - 16) push it further left. 
    # Lower negative numbers (e.g. - 0) push it further right (closer to button).
    @sprites["sel"].x = @sprites["b#{@index}"].x - (@sprites["b#{@index}"].bitmap.width / 2) - 4 + @sel_offset
    
    # Center it vertically with the button
    @sprites["sel"].y = @sprites["b#{@index}"].y
  end
end