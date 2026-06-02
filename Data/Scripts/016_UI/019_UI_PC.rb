#===============================================================================
#
#===============================================================================
def pbDisplay(message)
  # Change "speech bw" to whichever windowskin you prefer from Graphics/Windowskins/
  msgwindow = pbCreateMessageWindow(@viewport, "Graphics/Windowskins/speech rs")
  pbMessageDisplay(msgwindow, message)
  pbDisposeMessageWindow(msgwindow)
  Input.update
end 

def pbConfirm(message, commands, scene = nil)
  view = nil
  if scene
    if scene.respond_to?(:viewport)
      view = scene.viewport
    elsif scene.instance_variable_defined?(:@viewport)
      view = scene.instance_variable_get(:@viewport)
    end
  end
  # Create the window
  msgwindow = pbCreateMessageWindow(view, "Graphics/Windowskins/speech rs")
  
  # --- POSITIONING FIX ---
  msgwindow.width  = 512
  msgwindow.height = 96 
  msgwindow.x      = (Graphics.width - msgwindow.width) / 2
  msgwindow.y      = Graphics.height - msgwindow.height - 16 # 16 pixels from bottom
  
  msgwindow.text = message
  # Show the choices
  ret = pbShowCommands(msgwindow, commands, -1)
  pbDisposeMessageWindow(msgwindow)
  return ret
end

def pbConfirmWithHelp(message, commands, help_texts, scene = nil)
  view = nil
  if scene
    if scene.respond_to?(:viewport)
      view = scene.viewport
    elsif scene.instance_variable_defined?(:@viewport)
      view = scene.instance_variable_get(:@viewport)
    end
  end
  # Create the main message window
  msgwindow = pbCreateMessageWindow(view, "Graphics/Windowskins/speech rs")
  msgwindow.width  = 512
  msgwindow.height = 96 
  msgwindow.x      = (Graphics.width - msgwindow.width) / 2
  msgwindow.y      = Graphics.height - msgwindow.height - 16 # 16 pixels from bottom
  msgwindow.text   = message if message
  
  # Show commands with the associated help window
  ret = pbShowCommandsWithHelp(msgwindow, commands, help_texts, -1)
  pbDisposeMessageWindow(msgwindow)
  return ret
end

def pbPCItemStorage
  command = 0
  loop do
    command = pbConfirmWithHelp(nil,
                                [_INTL("Withdraw Item"),
                                 _INTL("Deposit Item"),
                                 _INTL("Toss Item"),
                                 _INTL("Exit")],
                                [_INTL("Take out items from the PC."),
                                 _INTL("Store items in the PC."),
                                 _INTL("Throw away items stored in the PC."),
                                 _INTL("Go back to the previous menu.")])
    case command
    when 0   # Withdraw Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbDisplay(_INTL("There are no items."))
      else
        pbFadeOutIn do
          scene = WithdrawItemScene.new
          screen = PokemonBagScreen.new(scene, $bag)
          screen.pbWithdrawItemScreen
        end
      end
    when 1   # Deposit Item
      pbFadeOutIn do
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        screen.pbDepositItemScreen
      end
    when 2   # Toss Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbDisplay(_INTL("There are no items."))
      else
        pbFadeOutIn do
          scene = TossItemScene.new
          screen = PokemonBagScreen.new(scene, $bag)
          screen.pbTossItemScreen
        end
      end
    else
      break
    end
  end
end

#===============================================================================
#
#===============================================================================
def pbPCMailbox
  if !$PokemonGlobal.mailbox || $PokemonGlobal.mailbox.length == 0
    pbDisplay(_INTL("There's no Mail here."))
  else
    loop do
      command = 0
      commands = []
      $PokemonGlobal.mailbox.each do |mail|
        commands.push(mail.sender)
      end
      commands.push(_INTL("Cancel"))
      command = pbShowCommands(nil, commands, -1, command)
      if command >= 0 && command < $PokemonGlobal.mailbox.length
        mailIndex = command
        commandMail = pbConfirm(
          _INTL("What do you want to do with {1}'s Mail?", $PokemonGlobal.mailbox[mailIndex].sender),
          [_INTL("Read"),
           _INTL("Move to Bag"),
           _INTL("Give"),
           _INTL("Cancel")], -1
        )
        case commandMail
        when 0   # Read
          pbFadeOutIn do
            pbDisplayMail($PokemonGlobal.mailbox[mailIndex])
          end
        when 1   # Move to Bag
          if pbConfirm(_INTL("The message will be lost. Is that OK?"))
            if $bag.add($PokemonGlobal.mailbox[mailIndex].item)
              pbDisplay(_INTL("The Mail was returned to the Bag with its message erased."))
              $PokemonGlobal.mailbox.delete_at(mailIndex)
            else
              pbDisplay(_INTL("The Bag is full."))
            end
          end
        when 2   # Give
          pbFadeOutIn do
            sscene = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene, $player.party)
            sscreen.pbPokemonGiveMailScreen(mailIndex)
          end
        end
      else
        break
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
def pbTrainerPC
  # The initial boot-up message remains
  pbDisplay("\\se[PC open]" + _INTL("{1} booted up the PC.", $player.name))
  
  # DIRECTLY call Item Storage (skipping the Item Storage/Mailbox/Turn Off menu)
  pbPCItemStorage
  
  # The closing sound remains
  pbSEPlay("PC close")
end

#def pbTrainerPCMenu
#  command = 0
#  loop do
#    command = pbMessage(_INTL("What do you want to do?"),
#                        [_INTL("Item Storage"),
#                         _INTL("Mailbox"),
#                         _INTL("Turn Off")], -1, nil, command)
#    case command
#    when 0 then pbPCItemStorage
#    when 1 then pbPCMailbox
#    else        break
#    end
#  end
#end

#===============================================================================
#
#===============================================================================
def pbPokeCenterPC
  pbDisplay("\\se[PC open]" + _INTL("{1} booted up the PC.", $player.name))
  # Get all commands
  command_list = []
  commands = []
  MenuHandlers.each_available(:pc_menu) do |option, hash, name|
    command_list.push(name)
    commands.push(hash)
  end
  # Main loop
  command = 0
  loop do
    choice = pbConfirm(_INTL("Which PC should be accessed?"), command_list)
    if choice < 0
      pbPlayCloseMenuSE
      break
    end
    break if commands[choice]["effect"].call
  end
  pbSEPlay("PC close")
end

def pbGetStorageCreator
  return GameData::Metadata.get.storage_creator
end

#===============================================================================
#
#===============================================================================
MenuHandlers.add(:pc_menu, :pokemon_storage, {
  "name"      => proc {
    next ($player.seen_storage_creator) ? _INTL("{1}'s PC", pbGetStorageCreator) : _INTL("Someone's PC")
  },
  "order"     => 10,
  "effect"    => proc { |menu|
    pbDisplay("\\se[PC access]" + _INTL("The Pokémon Storage System was opened."))
    
    # DIRECTLY OPEN ORGANIZE BOXES (skipping the Withdraw/Deposit menu)
    pbFadeOutIn do
      scene = PokemonStorageScene.new
      screen = PokemonStorageScreen.new(scene, $PokemonStorage)
      screen.pbStartScreen(0) # 0 starts the screen directly in "Organize" mode
    end
    
    next false # Returns to the "Which PC?" menu after closing boxes
  }
})

MenuHandlers.add(:pc_menu, :player_pc, {
  "name"      => proc { next _INTL("{1}'s PC", $player.name) },
  "order"     => 20,
  "effect"    => proc { |menu|
    pbDisplay("\\se[PC access]" + _INTL("Accessed {1}'s PC.", $player.name))
    
    # We call pbPCItemStorage directly instead of pbTrainerPCMenu
    pbPCItemStorage 
    
    next false # Returns to the "Which PC?" menu after exiting Item Storage
  }
})

MenuHandlers.add(:pc_menu, :close, {
  "name"      => _INTL("Log off"),
  "order"     => 100,
  "effect"    => proc { |menu|
    next true
  }
})
