#===============================================================================
#  BagWindowEBDX.rb
#  Updated: Added independent X/Y positions for the 4 main pocket buttons
#===============================================================================
class BagWindowEBDX
  attr_reader :index, :ret, :finished
  attr_accessor :sprites

  #-----------------------------------------------------------------------------
  #  custom pocket positions hash
  #-----------------------------------------------------------------------------
  def pocketPositions
    @pocketPositions ||= {
      0 => {x: nil, y: nil},  # Medicine
      1 => {x: nil, y: nil},  # Poké Balls
      2 => {x: nil, y: nil},  # Berries
      3 => {x: nil, y: nil}   # Battle Items
    }
  end

  #-----------------------------------------------------------------------------
  #  inspect
  #-----------------------------------------------------------------------------
  def inspect
    str = self.to_s.chop
    str << format(' pocket: %s,', @index)
    str << format(' page: %s,', @page)
    str << format(' item: %s>', @item)
    return str
  end

  #-----------------------------------------------------------------------------
  #  hide bag UI and display scene message
  #-----------------------------------------------------------------------------
  def pbDisplayMessage(msg)
    self.visible = false
    @scene.pbDisplayMessage(msg)
    @scene.clearMessageWindow
    self.visible = true
  end
  def pbDisplay(msg); self.pbDisplayMessage(msg); end

  #-----------------------------------------------------------------------------
  #  apply metrics (unchanged)
  #-----------------------------------------------------------------------------
  def applyMetrics
    @cmdImg = "itemContainer"
    @lastImg = "last"
    @backImg = "back"
    @frameImg = "itemFrame"
    @selImg = "cmdSel"
    @shadeImg = "shade"
    @nameImg = "itemName"
    @confirmImg = "itemConfirm"
    @cancelImg = "itemCancel"
    @iconsImg = "pocketIcons"

    d1 = EliteBattle.get(:nextUI)
    d1 = d1[:BAGMENU] if !d1.nil? && d1.has_key?(:BAGMENU)
    d2 = EliteBattle.get_data(:BAGMENU, :Metrics, :METRICS)
    d7 = EliteBattle.get_map_data(:BAGMENU_METRICS)
    d6 = @battle.opponent ? EliteBattle.get_trainer_data(@battle.opponent[0].trainer_type, :BAGMENU_METRICS, @battle.opponent[0]) : nil
    d5 = !@battle.opponent ? EliteBattle.get_data(@battle.battlers[1].species, :Species, :BAGMENU_METRICS, (@battle.battlers[1].form rescue 0)) : nil

    for data in [d2, d7, d6, d5, d1]
      next if data.nil?
      @cmdImg = data[:POCKETBUTTONS] if data.has_key?(:POCKETBUTTONS) && data[:POCKETBUTTONS].is_a?(String)
      @lastImg = data[:LASTITEM] if data.has_key?(:LASTITEM) && data[:LASTITEM].is_a?(String)
      @backImg = data[:BACKBUTTON] if data.has_key?(:BACKBUTTON) && data[:BACKBUTTON].is_a?(String)
      @frameImg = data[:ITEMFRAME] if data.has_key?(:ITEMFRAME) && data[:ITEMFRAME].is_a?(String)
      @nameImg = data[:POCKETNAME] if data.has_key?(:POCKETNAME) && data[:POCKETNAME].is_a?(String)
      @confirmImg = data[:ITEMCONFIRM] if data.has_key?(:ITEMCONFIRM) && data[:ITEMCONFIRM].is_a?(String)
      @cancelImg = data[:ITEMCANCEL] if data.has_key?(:ITEMCANCEL) && data[:ITEMCANCEL].is_a?(String)
      @selImg = data[:SELECTORGRAPHIC] if data.has_key?(:SELECTORGRAPHIC) && data[:SELECTORGRAPHIC].is_a?(String)
      @shadeImg = data[:SHADE] if data.has_key?(:SHADE) && data[:SHADE].is_a?(String)
      @iconsImg = data[:POCKETICONS] if data.has_key?(:POCKETICONS) && data[:POCKETICONS].is_a?(String)
    end
  end

  #-----------------------------------------------------------------------------
  #  initialize Bag UI
  #-----------------------------------------------------------------------------
  def initialize(scene, viewport)
    @scene = scene
    @battle = scene.battle
    $lastUsed = 0 if $lastUsed.nil?; @lastUsed = $lastUsed
    @index = 0; @oldindex = -1; @item = 0; @olditem = -1
    @finished = false
    @disposed = true
    @page = -1; @selPocket = 0
    @ret = nil; @path = "Graphics/EBDX/Pictures/Bag/"
    @baseColor = Color.black
    @shadowColor = nil
    @language = pbGetSelectedLanguage
    @viewport = Viewport.new(0, 0, viewport.width, viewport.height)
    @viewport.z = viewport.z + 5

    self.applyMetrics

    @sprites = {}
    @items = {}
    @sprites["back"] = Sprite.new(viewport)
    @sprites["back"].stretch_screen(@path + @shadeImg)
    @sprites["back"].opacity = 0
    @sprites["back"].z = 99998

    @sprites["sel"] = SelectorSprite.new(@viewport, 4)
    @sprites["sel"].filename = @path + @selImg
    @sprites["sel"].z = 99999

    bmp = pbBitmap(@path + @nameImg)
    @sprites["name"] = Sprite.new(@viewport)
    @sprites["name"].bitmap = Bitmap.new(bmp.width*1.2, bmp.height)
    pbSetSystemFont(@sprites["name"].bitmap)
    @sprites["name"].x = -@sprites["name"].width - @sprites["name"].width%10
    @sprites["name"].y = @viewport.height - 56
    bmp.dispose

    pbmp = pbBitmap(@path + @cmdImg)
    ibmp2 = pbResolveBitmap(@path + @iconsImg + "_" + @language)
    ibmp = ibmp2 ? pbBitmap(ibmp2) : pbBitmap(@path + @iconsImg)

    for i in 0...4
      @sprites["pocket#{i}"] = Sprite.new(@viewport)
      @sprites["pocket#{i}"].bitmap = Bitmap.new(pbmp.width, pbmp.height/4)
      @sprites["pocket#{i}"].bitmap.blt(0, 0, pbmp, Rect.new(0, (pbmp.height/4)*i, pbmp.width, pbmp.height/4))
      @sprites["pocket#{i}"].bitmap.blt((pbmp.width - ibmp.width)/2, (pbmp.height/4 - ibmp.height/4)/2, ibmp, Rect.new(0, (ibmp.height/4)*i, ibmp.width, ibmp.height/4))
      @sprites["pocket#{i}"].center!

      # --- CUSTOM POSITIONING ---
      pos = pocketPositions[i]
      @sprites["pocket#{i}"].x = pos[:x].nil? ? ((i%2)*2 + 1)*@viewport.width/4 + ((i%2 == 0) ? -1 : 1)*(@viewport.width/2 - 8) : pos[:x]
      @sprites["pocket#{i}"].y = pos[:y].nil? ? ((i/2)*2 + 2)*@viewport.height/8 + (i%2)*42 : pos[:y]
    end

    pbmp.dispose
    ibmp.dispose

    # --- Remaining initialization for Last, Back, Confirm/Cancel buttons remains unchanged ---
    # self.refresh(true)
    # @sprites["sel"].target(@sprites["pocket#{@oldindex}"])
  end
def dispose
  return if @disposed   # <-- skip if already disposed
  keys = ["back", "sel", "name", "confirm", "cancel"]
  for i in 0..5
    keys.push("pocket#{i}")
  end
  for key in keys
    @sprites[key].dispose if @sprites[key]   # safe dispose
  end
  pbDisposeSpriteHash(@items) if @items
  @disposed = true
end
#Check this one too:

#def disposed?
#  return @disposed
#end

  #-----------------------------------------------------------------------------
  #  rest of BagWindowEBDX methods remain unchanged...
  #-----------------------------------------------------------------------------
end
