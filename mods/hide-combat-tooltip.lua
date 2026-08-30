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
  local combat = UnitAffectingCombat("player") and true or false

  local function InCombat()
    return combat or (UnitAffectingCombat("player") and true or false)
  end

  local function ShiftDown()
    return API.IsShiftKeyDown()
  end

  local function Apply()
    if InCombat() and not ShiftDown() then
      if GameTooltip:GetAlpha() ~= 0 then
        GameTooltip:SetAlpha(0)
      end
    else
      if GameTooltip:GetAlpha() ~= 1 then
        GameTooltip:SetAlpha(1)
      end
    end
  end

  -- Keep the tooltip logically shown while suppressing it visually.
  -- This preserves its current owner/content, so pressing Shift while the
  -- mouse is already over a target reveals the existing tooltip immediately.
  --
  -- Alpha is forced before and after the native Show call so there is no
  -- rendered-frame flash even if Show internally resets alpha.
  GameTooltip.Show = function(self)
    if InCombat() and not ShiftDown() then
      self:SetAlpha(0)
      local result = originalShow(self)
      self:SetAlpha(0)
      return result
    end

    self:SetAlpha(1)
    return originalShow(self)
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

    Apply()
  end)

  -- Some tooltip code paths can change alpha after Show. Reassert only while
  -- the tooltip itself is visible; there is no separate permanent polling
  -- frame in ClassicAPI environments.
  local oldOnUpdate = GameTooltip:GetScript("OnUpdate")
  GameTooltip:SetScript("OnUpdate", function()
    if oldOnUpdate then oldOnUpdate() end
    Apply()
  end)

  -- Legacy fallback: ClassicAPI normally gives MODIFIER_STATE_CHANGED, but
  -- older environments still need a light modifier refresh while in combat.
  if not API.modifierstate then
    events.elapsed = 0
    events:SetScript("OnUpdate", function()
      if not InCombat() or not GameTooltip:IsShown() then return end

      this.elapsed = this.elapsed + (arg1 or 0)
      if this.elapsed < .05 then return end
      this.elapsed = 0
      Apply()
    end)
  end

  Apply()
end
