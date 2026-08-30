-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local T = ShaguTweaks.T
local API = ShaguTweaks.API
local hooksecurefunc = ShaguTweaks.hooksecurefunc

local module = ShaguTweaks:register({
  title = T["Hide Combat Tooltip"],
  description = T["Hides the tooltip in combat. Hold Shift to show it temporarily."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Tooltip & Items"],
  enabled = nil,
})

module.enable = function(self)
  local inCombat = UnitAffectingCombat("player") and true or false

  local function Apply()
    if inCombat and not API.IsShiftKeyDown() then
      GameTooltip:SetAlpha(0)
    else
      GameTooltip:SetAlpha(1)
    end
  end

  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("PLAYER_REGEN_DISABLED")
  events:RegisterEvent("PLAYER_REGEN_ENABLED")

  if API.modifierstate then
    events:RegisterEvent("MODIFIER_STATE_CHANGED")
  end

  events:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" then
      inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
      inCombat = false
    elseif event == "PLAYER_ENTERING_WORLD" then
      inCombat = UnitAffectingCombat("player") and true or false
    end

    Apply()
  end)

  -- If a tooltip is opened after combat started, enforce the current state
  -- immediately without a permanent OnUpdate.
  hooksecurefunc(GameTooltip, "Show", Apply)

  -- Only legacy/fallback environments poll the modifier, and only in combat.
  if not API.modifierstate then
    events.elapsed = 0
    events:SetScript("OnUpdate", function()
      if not inCombat then return end

      this.elapsed = this.elapsed + (arg1 or 0)
      if this.elapsed < .05 then return end
      this.elapsed = 0
      Apply()
    end)
  end

  Apply()
end
