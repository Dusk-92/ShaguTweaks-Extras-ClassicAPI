-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local T = ShaguTweaks.T
local API = ShaguTweaks.API

local module = ShaguTweaks:register({
  title = T["Hide Combat Tooltip"],
  description = T["Hides the tooltip in combat. Hold Shift to show it temporarily."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Tooltip & Items"],
  enabled = nil,
})

module.enable = function(self)
  if ShaguTweaks.HideCombatTooltipInstalled then return end
  ShaguTweaks.HideCombatTooltipInstalled = true

  local controller = CreateFrame("Frame", nil, UIParent)
  local inCombat = UnitAffectingCombat("player") and true or false
  local shiftDown = API.IsShiftKeyDown() and true or false
  local guardActive = false
  local elapsed = 0

  local function Apply()
    if not inCombat then
      if GameTooltip:GetAlpha() ~= 1 then
        GameTooltip:SetAlpha(1)
      end
      return
    end

    local alpha = shiftDown and 1 or 0
    if GameTooltip:GetAlpha() ~= alpha then
      GameTooltip:SetAlpha(alpha)
    end
  end

  local function GuardTick()
    elapsed = elapsed + (arg1 or 0)
    if elapsed < .05 then return end
    elapsed = 0

    -- ClassicAPI provides modifier events, so normal clients don't need to
    -- query Shift here. This fallback is only for old environments.
    if not API.modifierstate then
      shiftDown = API.IsShiftKeyDown() and true or false
    end

    Apply()
  end

  local function StartGuard()
    if guardActive or not inCombat or not GameTooltip:IsShown() then return end

    guardActive = true
    elapsed = 0
    controller:SetScript("OnUpdate", GuardTick)
  end

  local function StopGuard()
    if not guardActive then return end

    guardActive = false
    elapsed = 0
    controller:SetScript("OnUpdate", nil)
  end

  local function RefreshShift()
    shiftDown = API.IsShiftKeyDown() and true or false

    if inCombat and GameTooltip:IsShown() then
      Apply()
      StartGuard()
    end
  end

  local function EnterCombat()
    inCombat = true
    shiftDown = API.IsShiftKeyDown() and true or false

    if GameTooltip:IsShown() then
      Apply()
      StartGuard()
    end
  end

  local function LeaveCombat()
    inCombat = false
    StopGuard()
    Apply()
  end

  -- Vanilla/Turtle can restore GameTooltip alpha internally while updating a
  -- visible unit tooltip. A purely event-driven implementation therefore does
  -- not stay hidden reliably. The guard below exists only while BOTH combat
  -- and an actual GameTooltip are active, and is throttled to 20 Hz instead of
  -- running the full upstream logic every rendered frame.
  local oldOnShow = GameTooltip:GetScript("OnShow")
  GameTooltip:SetScript("OnShow", function()
    if oldOnShow then oldOnShow() end

    if inCombat then
      shiftDown = API.IsShiftKeyDown() and true or false
      Apply()
      StartGuard()
    else
      Apply()
    end
  end)

  local oldOnHide = GameTooltip:GetScript("OnHide")
  GameTooltip:SetScript("OnHide", function()
    if oldOnHide then oldOnHide() end
    StopGuard()
  end)

  controller:RegisterEvent("PLAYER_ENTERING_WORLD")
  controller:RegisterEvent("PLAYER_REGEN_DISABLED")
  controller:RegisterEvent("PLAYER_REGEN_ENABLED")

  if API.modifierstate then
    controller:RegisterEvent("MODIFIER_STATE_CHANGED")
  end

  controller:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" then
      EnterCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then
      LeaveCombat()
    elseif event == "MODIFIER_STATE_CHANGED" then
      RefreshShift()
    elseif event == "PLAYER_ENTERING_WORLD" then
      if UnitAffectingCombat("player") then
        EnterCombat()
      else
        LeaveCombat()
      end
    end
  end)

  if inCombat then
    EnterCombat()
  else
    LeaveCombat()
  end
end
