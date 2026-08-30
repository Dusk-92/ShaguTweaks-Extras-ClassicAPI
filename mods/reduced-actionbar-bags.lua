local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API or {}

local module = ShaguTweaks:register({
  title = T["Show Bags"],
  description = T["Shows bag and keyring buttons when using the reduced actionbar layout. Hold Ctrl+Shift to move the bag bar."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Action Bar"],
  maintainer = "@shagu (GitHub)",
  enabled = nil,
  config = {
    ["panelbag.scale"] = 1,
  }
})

module.enable = function(self)
  -- only run if reduced actionbar is enabled
  if ShaguTweaks_config[T["Reduced Actionbar Size"]] == 0 then return end

  local frames = {
    KeyRingButton, CharacterBag3Slot, CharacterBag2Slot, CharacterBag1Slot,
    CharacterBag0Slot, MainMenuBarBackpackButton,
  }

  local bagframe = CreateFrame("Button", "ShaguTweaksReducedActionBarBags", UIParent)
  bagframe:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8, 48)
  bagframe:SetWidth(180)
  bagframe:SetHeight(42)
  bagframe:SetScale(module.config["panelbag.scale"])

  bagframe:SetFrameStrata("MEDIUM")
  bagframe:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })

  bagframe:SetBackdropBorderColor(.9,.8,.5,1)
  bagframe:SetBackdropColor(.4,.4,.4,1)

  bagframe:SetClampedToScreen(true)
  bagframe:SetMovable(true)
  bagframe:EnableMouse(true)
  bagframe:RegisterForDrag("LeftButton")

  bagframe:SetUserPlaced(true)

  bagframe:RegisterEvent("PLAYER_ENTERING_WORLD")

  bagframe:SetScript("OnDragStart", function()
    local shift = API.IsShiftKeyDown and API.IsShiftKeyDown() or IsShiftKeyDown()
    local control = API.IsControlKeyDown and API.IsControlKeyDown() or IsControlKeyDown()
    if not shift or not control then return end
    this:StartMoving()
  end)

  bagframe:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
  end)

  bagframe:SetScript("OnUpdate", function()
    this.modifierTimer = (this.modifierTimer or 0) + arg1
    if this.modifierTimer < .05 then return end
    this.modifierTimer = 0

    local shift = API.IsShiftKeyDown and API.IsShiftKeyDown() or IsShiftKeyDown()
    local control = API.IsControlKeyDown and API.IsControlKeyDown() or IsControlKeyDown()
    if MouseIsOver(this) and shift and control then
      if not this.mousedisabled then
        -- disable mouse events on all frames
        this.mousedisabled = true
        for _, frame in pairs(frames) do
          frame:EnableMouse(0)
        end
      end
    else
      if this.mousedisabled then
        -- enable all mouse events again
        this.mousedisabled = false
        for _, frame in pairs(frames) do
          frame:EnableMouse(1)
        end
      end
    end
  end)

  bagframe:SetScript("OnEvent", function()
    if this.initialized then return end
    this.initialized = true

    ShaguTweaks.DarkenFrame(bagframe)

    for id, frame in pairs(frames) do
      local anchor = frames[id-1] or bagframe
      frame:ClearAllPoints()
      frame:SetPoint("LEFT", anchor, id == 1 and "LEFT" or "RIGHT", id == 1 and 5 or 2, 0)
      frame:SetParent(bagframe)
      frame:SetScale(.8)
      frame.Show = nil
      frame:Show()
    end
  end)
end
