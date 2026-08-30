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

  local originalShow = GameTooltip.Show
  local originalSetAlpha = GameTooltip.SetAlpha
  local originalSetOwner = GameTooltip.SetOwner
  local originalSetUnit = GameTooltip.SetUnit

  local combat = UnitAffectingCombat("player") and true or false

  local function InCombat()
    return combat or (UnitAffectingCombat("player") and true or false)
  end

  local function ShiftDown()
    return API.IsShiftKeyDown()
  end

  local function ShouldHide()
    return InCombat() and not ShiftDown()
  end

  local function ForceState()
    originalSetAlpha(GameTooltip, ShouldHide() and 0 or 1)
  end

  -- Clamp every Lua-side alpha change while the combat guard is active.
  -- Tooltip fade/layout code may try to restore alpha while repeatedly
  -- mousing over a unit; it can no longer make the tooltip visible until
  -- Shift is held.
  GameTooltip.SetAlpha = function(self, alpha)
    if self == GameTooltip and ShouldHide() then
      alpha = 0
    end
    return originalSetAlpha(self, alpha)
  end

  -- Keep the tooltip logically shown (alpha 0) so pressing Shift while the
  -- mouse is already over a target reveals the existing content immediately.
  -- Alpha is enforced both before and after Show to prevent a one-frame flash.
  GameTooltip.Show = function(self)
    if ShouldHide() then
      originalSetAlpha(self, 0)
    end

    local result = originalShow(self)

    if self == GameTooltip then
      originalSetAlpha(self, ShouldHide() and 0 or 1)
    end

    return result
  end

  -- SetOwner and SetUnit are the two paths used by unit mouseover tooltips.
  -- Some Vanilla/Turtle UI code can reset tooltip visual state from these
  -- calls, so enforce the combat state immediately after them as well.
  GameTooltip.SetOwner = function(self, owner, anchor, x, y)
    local r1, r2, r3, r4 = originalSetOwner(self, owner, anchor, x, y)
    if self == GameTooltip and ShouldHide() then
      originalSetAlpha(self, 0)
    end
    return r1, r2, r3, r4
  end

  GameTooltip.SetUnit = function(self, unit)
    local r1, r2, r3, r4 = originalSetUnit(self, unit)
    if self == GameTooltip and ShouldHide() then
      originalSetAlpha(self, 0)
    end
    return r1, r2, r3, r4
  end

  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("PLAYER_REGEN_DISABLED")
  events:RegisterEvent("PLAYER_REGEN_ENABLED")
  events:RegisterEvent("PLAYER_ENTER_COMBAT")
  events:RegisterEvent("PLAYER_LEAVE_COMBAT")

  if API.modifierstate then
    events:RegisterEvent("MODIFIER_STATE_CHANGED")
  end

  events:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTER_COMBAT" then
      combat = true
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_LEAVE_COMBAT" then
      combat = false
    elseif event == "PLAYER_ENTERING_WORLD" then
      combat = UnitAffectingCombat("player") and true or false
    end

    ForceState()
  end)

  -- ClassicAPI normally supplies MODIFIER_STATE_CHANGED. The fallback is only
  -- needed for old environments and only while the tooltip is actually shown.
  if not API.modifierstate then
    events.elapsed = 0
    events:SetScript("OnUpdate", function()
      if not GameTooltip:IsShown() then return end

      this.elapsed = this.elapsed + (arg1 or 0)
      if this.elapsed < .05 then return end
      this.elapsed = 0
      ForceState()
    end)
  end

  ForceState()
end
