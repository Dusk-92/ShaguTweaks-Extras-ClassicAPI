local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API

local module = ShaguTweaks:register({
  title = T["Show Micro Menu"],
  description = T["Shows micro menu buttons when using the reduced actionbar layout. Hold Ctrl+Shift to move the micro menu."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Action Bar"],
  maintainer = "@shagu (GitHub)",
  enabled = nil,
  config = {
    ["panelmicro.scale"] = 1,
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

  -- Moving the micro menu is driven by ClassicAPI modifier events and native
  -- Region:IsMouseOver state. Do not keep a permanent polling fallback here.
  if not API.modifierstate or not API.regionmouseover then return end

  local frames = {
    CharacterMicroButton, SpellbookMicroButton, TalentMicroButton,
    QuestLogMicroButton, MainMenuMicroButton, SocialsMicroButton,
    WorldMapMicroButton, HelpMicroButton
  }

  local microframe = CreateFrame("Button", "ShaguTweaksReducedActionBarMicroMenu", UIParent)
  microframe:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8, 8)
  microframe:SetWidth(225)
  microframe:SetHeight(44)
  microframe:SetScale(module.config["panelmicro.scale"])

  microframe:SetFrameStrata("MEDIUM")
  microframe:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })

  microframe:SetBackdropBorderColor(.9,.8,.5,1)
  microframe:SetBackdropColor(.4,.4,.4,1)

  microframe:SetClampedToScreen(true)
  microframe:SetMovable(true)
  microframe:EnableMouse(true)
  microframe:RegisterForDrag("LeftButton")

  microframe:SetUserPlaced(true)

  microframe:RegisterEvent("PLAYER_ENTERING_WORLD")

  local function UpdateMoveMode()
    local active = API.IsMouseOver(microframe)
      and API.IsShiftKeyDown()
      and API.IsControlKeyDown()

    if active then
      if microframe.mousedisabled then return end
      microframe.mousedisabled = true
      for _, frame in ipairs(frames) do
        frame:EnableMouse(0)
      end
    else
      if not microframe.mousedisabled then return end
      microframe.mousedisabled = false
      for _, frame in ipairs(frames) do
        frame:EnableMouse(1)
      end
    end
  end

  microframe:SetScript("OnEnter", UpdateMoveMode)
  microframe:SetScript("OnLeave", UpdateMoveMode)

  local modifier = CreateFrame("Frame", nil, microframe)
  modifier:RegisterEvent("MODIFIER_STATE_CHANGED")
  modifier:SetScript("OnEvent", UpdateMoveMode)

  microframe:SetScript("OnDragStart", function()
    local shift = API.IsShiftKeyDown()
    local control = API.IsControlKeyDown()
    if not shift or not control then return end
    this:StartMoving()
  end)

  microframe:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
  end)

  microframe:SetScript("OnEvent", function()
    if this.initialized then return end
    this.initialized = true

    ShaguTweaks.DarkenFrame(microframe)

    for id, frame in ipairs(frames) do
      local anchor = frames[id-1] or microframe
      frame:ClearAllPoints()
      frame:SetPoint("LEFT", anchor, id == 1 and "LEFT" or "RIGHT", id == 1 and 3.5 or -2, id==1 and 10 or 0)
      frame:SetParent(microframe)
      frame.Show = nil
      frame:Show()

      -- Child micro buttons normally own the mouse. Re-evaluate move mode when
      -- entering or leaving one so Ctrl+Shift already held before mouseover is
      -- handled without polling and without replacing their tooltip scripts.
      ShaguTweaks.HookScript(frame, "OnEnter", UpdateMoveMode)
      ShaguTweaks.HookScript(frame, "OnLeave", UpdateMoveMode)
    end

    UpdateMoveMode()
  end)
end
