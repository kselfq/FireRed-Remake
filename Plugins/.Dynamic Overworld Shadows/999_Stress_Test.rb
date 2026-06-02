#===============================================================================
# ZBox Stress Test
#
# Use: 
#  zbox_stress_test       -> Modify ALL map events.
#  zbox_stress_test(50)   -> Modify only 50 random events.
#===============================================================================

def zbox_stress_test(limit = nil)
  ZBox_Stress.log "========================================"
  ZBox_Stress.log "[ZBox Stress] STARTING STRESS TEST"
  ZBox_Stress.log "========================================"

  
  map = $game_map
  events = map.events
  
  if events.empty?
    ZBox_Stress.log "[ZBox Stress] There are no events on this map to stress about.."
    return
  end

  # We searched for all PNGs in the Characters folder
  character_files = []
  Dir.glob(ZBox_Stress::GRAPHICS_DIR + "*.png").each do |file|
    filename = File.basename(file, ".png")
    character_files.push(filename)
  end
  
  if character_files.empty?
    ZBox_Stress.log "[ZBox Stress] Error: No graphics found in #{ZBox_Stress::GRAPHICS_DIR}"
    return
  end

  
  ZBox_Stress.log "[ZBox Stress] Graphics found: #{character_files.size}" 
  
  # Iterate over all events.
  count = 0
  used_coords = {}

  # If there is a limit, we process until we reach it. If it is nil, we process all.
  target_limit = limit || events.size
  
  ZBox_Stress.log "[ZBox Stress] Objective: Modify #{target_limit} events." 
  
  events.each_value do |event|
    # We ignore the player
    next if event == $game_player
    break if count >= target_limit
    
    # We generate a base name + random tags
    base_name = "Stress_Event_#{event.id}"
    
    # We add 1 or 2 random tags
    tags = []
    # Tadius (sr: 8 a 40)
    if rand(100) < ZBox_Stress::CHANCE_SHADOW_SIZE
      val = rand(8..100)
      tags << "(sr:#{val})"
    end
    
    # Offsets (sx/sy: -20 a 20)
    if rand(100) < ZBox_Stress::CHANCE_OFFSET
      val_x = rand(-30..30)
      val_y = rand(-30..30)
      tags << "(sx:#{val_x})"
      tags << "(sy:#{val_y})"
    end
    
    # Fly? (fly: 10 a 60)
    if rand(100) < ZBox_Stress::CHANCE_FLY
      val = rand(10..60)
      tags << "(fly:#{val})"
    end
    
    tags << "(top)" if rand(100) < ZBox_Stress::CHANCE_TOP
    tags << "(stop)" if rand(100) < ZBox_Stress::CHANCE_STOP
    tags << ".sl" if rand(100) < ZBox_Stress::CHANCE_DISABLE
    
    # Build Name
    base_name = "Stress_#{event.id}"
    new_name = "#{base_name} #{tags.join(' ')}"
    
    event.instance_variable_get(:@event).name = new_name
    
    # GRAPHICS AND COLOR
    event.character_name = character_files.sample
    event.character_hue = rand(360)
    
    # CHAOTIC MOVEMENT 
    event.move_speed = ZBox_Stress::MOVE_SPEEDS.sample
    event.move_frequency = ZBox_Stress::MOVE_FREQUENCIES.sample
    event.walk_anime = true
    event.step_anime = (rand(100) < 20)
    event.through = (rand(100) < 10)
    
    # We create a random movement path
    route = RPG::MoveRoute.new
    route.repeat = true
    route.skippable = true
    
    # We added random movement commands
    list = []
    12.times do
      code = [1, 2, 3, 4, 9].sample
      
      if rand(100) < 10
        list.push(RPG::MoveCommand.new(14, [0, 0])) 
      end
      
      list.push(RPG::MoveCommand.new(code))
    end
    list.push(RPG::MoveCommand.new(0))
    route.list = list
    event.force_move_route(route)
     
    10.times do
      rx = rand(map.width)
      ry = rand(map.height)
      if map.passable?(rx, ry, 2) && !used_coords[[rx, ry]]
        event.moveto(rx, ry)
        used_coords[[rx, ry]] = true
        break
      end
    end
    
    event.refresh   
    count += 1
  end
  
  ZBox_Stress.log "[ZBox Stress] PROCESS COMPLETED."
  ZBox_Stress.log "[ZBox Stress] Modified events: #{count}"
  ZBox_Stress.log "========================================"
end