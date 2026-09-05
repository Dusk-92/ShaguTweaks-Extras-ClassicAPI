local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API

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
  -- The ShaguTweaks loader initializes module config while iterating an
  -- unordered table. On a fresh install the Reduced Actionbar key may not have
  -- been visited yet, so fall back to that module's declared default.
  local reducedTitle = T["Reduced Actionbar Size"]
  local reducedEnabled = ShaguTweaks_config and ShaguTweaks_config[reducedTitle]
  if reducedEnabled == nil then
    local reducedModule = ShaguTweaks.mods and ShaguTweaks.mods[reducedTitle]
    reducedEnabled = reducedModule and reducedModule.enabled and 1 or 0
  end
  if reducedEnabled ~= 1 then return end

  -- Moving the bag bar is driven by ClassicAPI modifier events and native
  -- Region:IsMouseOver state. Do not keep a permanent polling fallback here.
  if not API.modifierstate or not API.regionmouseover then return end

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

  local function UpdateMoveMode()
    local active = API.IsMouseOver(bagframe)
      and API.IsShiftKeyDown()
      and API.IsControlKeyDown()

    if active then
      if bagframe.mousedisabled then return end
      bagframe.mousedisabled = true
      for _, frame in ipairs(frames) do
        frame:EnableMouse(0)
      end
    else
      if not bagframe.mousedisabled then return end
      bagframe.mousedisabled = false
      for _, frame in ipairs(frames) do
        frame:EnableMouse(1)
      end
    end
  end

  bagframe:SetScript("OnEnter", UpdateMoveMode)
  bagframe:SetScript("OnLeave", UpdateMoveMode)

  local modifier = CreateFrame("Frame", nil, bagframe)
  modifier:RegisterEvent("MODIFIER_STATE_CHANGED")
  modifier:SetScript("OnEvent", UpdateMoveMode)

  bagframe:SetScript("OnDragStart", function()
    local shift = API.IsShiftKeyDown()
    local control = API.IsControlKeyDown()
    if not shift or not control then return end
    this:StartMoving()
  end)

  bagframe:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
  end)

  bagframe:SetScript("OnEvent", function()
    if this.initialized then return end
    this.initialized = true

    ShaguTweaks.DarkenFrame(bagframe)

    for id, frame in ipairs(frames) do
      local anchor = frames[id-1] or bagframe
      frame:ClearAllPoints()
      frame:SetPoint("LEFT", anchor, id == 1 and "LEFT" or "RIGHT", id == 1 and 5 or 2, 0)
      frame:SetParent(bagframe)
      frame:SetScale(.8)
      frame.Show = nil
      frame:Show()

      -- Child bag buttons normally own the mouse. Re-evaluate move mode when
      -- entering or leaving one so Ctrl+Shift already held before mouseover is
      -- handled without polling and without replacing their tooltip scripts.
      ShaguTweaks.HookScript(frame, "OnEnter", UpdateMoveMode)
      ShaguTweaks.HookScript(frame, "OnLeave", UpdateMoveMode)
    end

    UpdateMoveMode()
  end)
end
