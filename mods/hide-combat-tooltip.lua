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
    local shouldHide = inCombat and not API.IsShiftKeyDown()
    local alpha = GameTooltip:GetAlpha()

    if shouldHide then
      if alpha ~= 0 then GameTooltip:SetAlpha(0) end
    else
      if alpha ~= 1 then GameTooltip:SetAlpha(1) end
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

  -- Apply before the native Show call to avoid the one-frame flash.
  hooksecurefunc(GameTooltip, "Show", Apply, true)

  -- Some tooltip code paths can reset alpha while opening/updating the
  -- tooltip. Re-apply after the tooltip's own scripts, but only while that
  -- tooltip is actually shown. This is much cheaper than the original
  -- combat-long polling frame and makes Cursor Tooltip coexist correctly.
  local oldOnShow = GameTooltip:GetScript("OnShow")
  GameTooltip:SetScript("OnShow", function()
    if oldOnShow then oldOnShow() end
    Apply()
  end)

  local oldOnUpdate = GameTooltip:GetScript("OnUpdate")
  GameTooltip:SetScript("OnUpdate", function()
    if oldOnUpdate then oldOnUpdate() end
    if inCombat then Apply() end
  end)

  -- Only legacy/fallback environments need separate modifier polling.
  if not API.modifierstate then
    events.elapsed = 0
    events:SetScript("OnUpdate", function()
      if not inCombat or not GameTooltip:IsShown() then return end

      this.elapsed = this.elapsed + (arg1 or 0)
      if this.elapsed < .05 then return end
      this.elapsed = 0
      Apply()
    end)
  end

  Apply()
end
