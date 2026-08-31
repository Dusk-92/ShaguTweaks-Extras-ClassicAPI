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
  local inCombat = false
  local shiftDown = false
  local elapsed = 0

  local function Apply()
    local alpha = shiftDown and 1 or 0

    if GameTooltip:GetAlpha() ~= alpha then
      GameTooltip:SetAlpha(alpha)
    end
  end

  local function RefreshShift()
    shiftDown = API.IsShiftKeyDown() and true or false

    if inCombat then
      Apply()
    end
  end

  local function StartCombatGuard()
    if inCombat then
      RefreshShift()
      return
    end

    inCombat = true
    elapsed = 0
    shiftDown = API.IsShiftKeyDown() and true or false
    Apply()

    -- Vanilla/Turtle tooltip code can restore alpha internally while the
    -- cursor moves between units. Keep a small combat-only guard for that
    -- native behavior, but throttle it instead of running the full check on
    -- every rendered frame like the upstream module.
    controller:SetScript("OnUpdate", function()
      if not GameTooltip:IsShown() then return end

      elapsed = elapsed + (arg1 or 0)
      if elapsed < .05 then return end
      elapsed = 0

      Apply()
    end)
  end

  local function StopCombatGuard()
    if not inCombat then
      GameTooltip:SetAlpha(1)
      return
    end

    inCombat = false
    elapsed = 0
    controller:SetScript("OnUpdate", nil)

    if GameTooltip:GetAlpha() ~= 1 then
      GameTooltip:SetAlpha(1)
    end
  end

  controller:RegisterEvent("PLAYER_ENTERING_WORLD")
  controller:RegisterEvent("PLAYER_REGEN_DISABLED")
  controller:RegisterEvent("PLAYER_REGEN_ENABLED")

  if API.modifierstate then
    controller:RegisterEvent("MODIFIER_STATE_CHANGED")
  end

  controller:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" then
      StartCombatGuard()
    elseif event == "PLAYER_REGEN_ENABLED" then
      StopCombatGuard()
    elseif event == "MODIFIER_STATE_CHANGED" then
      RefreshShift()
    elseif event == "PLAYER_ENTERING_WORLD" then
      if UnitAffectingCombat("player") then
        StartCombatGuard()
      else
        StopCombatGuard()
      end
    end
  end)

  -- Old environments without ClassicAPI's modifier-state event still need to
  -- sample Shift while in combat. Fold that check into the same 50 ms guard
  -- rather than creating another polling frame.
  if not API.modifierstate then
    local originalStartCombatGuard = StartCombatGuard

    StartCombatGuard = function()
      originalStartCombatGuard()

      controller:SetScript("OnUpdate", function()
        if not GameTooltip:IsShown() then return end

        elapsed = elapsed + (arg1 or 0)
        if elapsed < .05 then return end
        elapsed = 0

        shiftDown = API.IsShiftKeyDown() and true or false
        Apply()
      end)
    end
  end

  if UnitAffectingCombat("player") then
    StartCombatGuard()
  else
    StopCombatGuard()
  end
end
