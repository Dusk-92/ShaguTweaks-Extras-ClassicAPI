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

  -- Vanilla/Turtle's tooltip fade/hover code can change GameTooltip alpha
  -- internally without going through Lua wrappers. Event-only SetAlpha calls
  -- therefore aren't sufficient: repeated unit mouseovers can make the
  -- tooltip visible again.
  --
  -- Keep one tiny controller active ONLY during combat. This mirrors the
  -- reliable behavior of the upstream mod, while avoiding any permanent
  -- out-of-combat OnUpdate cost.
  local controller = CreateFrame("Frame", nil, UIParent)

  local function Apply()
    local alpha = API.IsShiftKeyDown() and 1 or 0
    if GameTooltip:GetAlpha() ~= alpha then
      GameTooltip:SetAlpha(alpha)
    end
  end

  local function StartCombatGuard()
    controller:SetScript("OnUpdate", function()
      -- Use the live combat state as a safety net for event timing.
      if not UnitAffectingCombat("player") then
        this:SetScript("OnUpdate", nil)
        GameTooltip:SetAlpha(1)
        return
      end

      Apply()
    end)

    -- Apply immediately so the current tooltip cannot survive the transition
    -- into combat for one rendered frame.
    Apply()
  end

  local function StopCombatGuard()
    controller:SetScript("OnUpdate", nil)
    GameTooltip:SetAlpha(1)
  end

  controller:RegisterEvent("PLAYER_ENTERING_WORLD")
  controller:RegisterEvent("PLAYER_REGEN_DISABLED")
  controller:RegisterEvent("PLAYER_REGEN_ENABLED")
  controller:RegisterEvent("PLAYER_ENTER_COMBAT")
  controller:RegisterEvent("PLAYER_LEAVE_COMBAT")

  controller:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTER_COMBAT" then
      StartCombatGuard()
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_LEAVE_COMBAT" then
      if UnitAffectingCombat("player") then
        StartCombatGuard()
      else
        StopCombatGuard()
      end
    elseif event == "PLAYER_ENTERING_WORLD" then
      if UnitAffectingCombat("player") then
        StartCombatGuard()
      else
        StopCombatGuard()
      end
    end
  end)

  if UnitAffectingCombat("player") then
    StartCombatGuard()
  else
    StopCombatGuard()
  end
end
