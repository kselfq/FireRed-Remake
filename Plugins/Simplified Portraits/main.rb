#===============================================================================
#  Settings
#===============================================================================
DIM_OPACITY = 150
#===============================================================================

def pbShowPortrait(person, pos, opacity=255)
  # Initialize storage if it doesn't exist yet
  $portrait_slots ||= {}
  
  # If this person already has a slot, reuse it.
  data = $portrait_slots[person]
  if data
    slot = data[:slot]
  else
    # Find first unused slot
    used_slots = $portrait_slots.values.map { |d| d[:slot] }
    slot = (1..100).find { |i| !used_slots.include?(i) }
    $portrait_slots[person] = { slot: slot, pos: pos }
  end

  # Store the current pose so it can be reused later
  $portrait_slots[person][:pos] = pos

  # Build filename and show the picture
  filename = "Portraits/#{person}#{pos}"
  $game_screen.pictures[slot].show(filename, 0, 0, 0, 100, 100, opacity, 0)
end

def pbErasePortrait(person)
  return unless $portrait_slots && $portrait_slots[person]
  slot = $portrait_slots[person][:slot]
  $game_screen.pictures[slot].erase
  $portrait_slots.delete(person)
end

def pbSpeakingPortrait(active_person = nil, bright_opacity = 255, dim_opacity = DIM_OPACITY)
  return if !$portrait_slots || $portrait_slots.empty?

  # If active_person is nil or "none", dim ALL portraits
  no_speaker = active_person.nil? || active_person.to_s.downcase == "none"

  $portrait_slots.each do |person, data|
    slot = data[:slot]
    pos  = data[:pos]
    next if $game_screen.pictures[slot].nil?

    filename = "Portraits/#{person}#{pos}"

    # If no speaker, everyone gets dim opacity
    opacity = no_speaker ? dim_opacity : (person == active_person ? bright_opacity : dim_opacity)

    $game_screen.pictures[slot].show(filename, 0, 0, 0, 100, 100, opacity, 0)
  end
end


def pbEraseAllPortraits
  return unless $portrait_slots
  
  # Erase every picture being tracked
  $portrait_slots.each_value do |data|
    slot = data[:slot]
    $game_screen.pictures[slot].erase
  end
  
  # Reset the tracking hash
  $portrait_slots.clear
end