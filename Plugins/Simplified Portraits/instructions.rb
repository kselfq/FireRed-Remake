#===============================================================================
# Simple Portrait System
# Author: sonataG91
# 
# A lightweight portrait manager for Pokémon Essentials v21.1+
#
# Allows simple portrait display, auto-slotting, dimming, speaker highlighting,
# and easy bulk erasing.
#
# Designed for simplicity and minimal setup.
#
#
#===============================================================================
# INITIAL SETUP
#===============================================================================
# Your portraits should be the full size of the visible game screen
# with your character positioned where you want them in the frame.
#
# Just name your portraits as:
#     <CharacterName><PortraitVersion>
# and place them inside:
#     Graphics/Pictures/Portraits
#
# Example filename: RedL1.png
#
#===============================================================================
# AVAILABLE COMMANDS
#===============================================================================
# pbShowPortrait("character","version",opacity)
#   Opacity is optional, defaults to full opacity
#   Calling pbShowPortrait("Red","L1",255) or pbShowPortrait("Red","L1")
#       will draw the portrait labeled RedL1 at full opacity.
#   Must be called again if switching to a different version of the image.
#   Drawing a new version of the character automatically erases the old version.
#
# pbSpeakingPortrait("name")
#   Calling pbSpeakingPortrait("Blue") will show the currently drawn portrait
#   with Blue as the name at max opacity of 255 and all other portraits dimmed.
#   ("name") can be set to ("none"), (nil), or be left blank to dim all images.
#   Default dimmed opacity is 150, may be changed in main.rb
#
# pbErasePortrait("name")
#   Erases the portrait for the specified character.
#
# pbEraseAllPortraits
#   Erases every currently drawn portrait. Does not affect any non-portrait
#   pictures that may be currently showing