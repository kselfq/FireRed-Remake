module Settings
  GB_SOUNDS_SWITCH = 100 # Change this to your unused Switch ID
end

# 1. Handle the Item's "Use" effect
ItemHandlers::UseInField.add(:GBSOUNDS, proc { |item|
  pbSEPlay("Choice") 
  
  # Toggle the switch
  $game_switches[Settings::GB_SOUNDS_SWITCH] = !$game_switches[Settings::GB_SOUNDS_SWITCH]
  
  # Swap the BGM immediately BEFORE showing the text box
  if $game_system.playing_bgm
    bgm = $game_system.playing_bgm
    base_name = bgm.name.gsub(/_GB$/, "") 
    pbBGMPlay(base_name, bgm.volume, bgm.pitch)
  end
  
  # Show the message (the new music is already playing in the background!)
  if $game_switches[Settings::GB_SOUNDS_SWITCH]
    pbMessage(_INTL("The nostalgic sounds of the Game Boy filled the air!"))
  else
    pbMessage(_INTL("The modern sounds of the region returned."))
  end
  
  next 1
})

# 2. The logic to check for _GB files
alias gb_pbBGMPlay pbBGMPlay
def pbBGMPlay(bgm, volume = nil, pitch = nil)
  bgm_name = (bgm.is_a?(String)) ? bgm : (bgm.respond_to?(:name) ? bgm.name : bgm)
  
  if $game_switches && $game_switches[Settings::GB_SOUNDS_SWITCH] && bgm_name && !bgm_name.empty?
    unless bgm_name.include?("_GB")
      gb_file = bgm_name + "_GB"
      
      # Physically check the folder for the file and common audio extensions
      has_gb_file = false
      ["", ".ogg", ".mp3", ".wav", ".mid", ".midi"].each do |ext|
        if FileTest.exist?("Audio/BGM/" + gb_file + ext)
          has_gb_file = true
          break
        end
      end
      
      # Only change the track name if the file actually exists
      if has_gb_file
        bgm_name = gb_file
      end
    end
  end

  # Play the background music
  if bgm.is_a?(String)
    gb_pbBGMPlay(bgm_name, volume, pitch)
  else
    new_bgm = bgm.clone
    new_bgm.name = bgm_name
    gb_pbBGMPlay(new_bgm, volume, pitch)
  end
end
