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
  local originalHide = GameTooltip.Hide
  local combat = UnitAffectingCombat("player") and true or false
  local suppressed = false

  local function InCombat()
    -- Keep the event state, but also check the live unit state because Turtle
    -- builds/addons can differ slightly in when combat events are delivered.
    return combat or (UnitAffectingCombat("player") and true or false)
  end

  local function ShiftDown()
    return API.IsShiftKeyDown()
  end

  -- Intentional interception: unlike alpha-based hiding, blocking Show()
  -- prevents even a single rendered-frame flash and cannot be undone by
  -- tooltip anchoring/fade code.
  GameTooltip.Show = function(self)
    if InCombat() and not ShiftDown() then
      suppressed = true
      if self:IsShown() then
        originalHide(self)
      end
      return
    end

    suppressed = false
    return originalShow(self)
  end

  -- A real Hide means the mouse left the tooltip owner, so a later Shift press
  -- must not resurrect stale tooltip content.
  GameTooltip.Hide = function(self)
    suppressed = false
    return originalHide(self)
  end

  local function HideForCombat()
    if GameTooltip:IsShown() then
      suppressed = true
      -- Call the preserved method directly so our Hide wrapper does not clear
      -- the suppressed state while the mouse is still over the same owner.
      originalHide(GameTooltip)
    end
  end

  local function Refresh()
    if InCombat() then
      if ShiftDown() then
        if suppressed then
          suppressed = false
          originalShow(GameTooltip)
        end
      else
        HideForCombat()
      end
    elseif suppressed then
      suppressed = false
      originalShow(GameTooltip)
    end
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
      -- UnitAffectingCombat is checked again by InCombat(), so an early leave
      -- event cannot expose the tooltip while the player is still engaged.
      combat = false
    elseif event == "PLAYER_ENTERING_WORLD" then
      combat = UnitAffectingCombat("player") and true or false
    end

    Refresh()
  end)

  -- ClassicAPI gives us modifier events. Only old/fallback environments need
  -- a small combat-only modifier check so Shift reveal still works.
  if not API.modifierstate then
    events.elapsed = 0
    events:SetScript("OnUpdate", function()
      if not InCombat() then return end

      this.elapsed = this.elapsed + (arg1 or 0)
      if this.elapsed < .05 then return end
      this.elapsed = 0
      Refresh()
    end)
  end

  Refresh()
end
