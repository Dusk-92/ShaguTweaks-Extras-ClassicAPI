-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local T = ShaguTweaks.T
local hooksecurefunc = ShaguTweaks.hooksecurefunc

local module = ShaguTweaks:register({
  title = T["Cursor Tooltip"],
  description = T["Attaches default tooltips to the cursor."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Tooltip & Items"],
  enabled = nil,
})

module.enable = function(self)
  local tracker = CreateFrame("Frame", nil, UIParent)
  tracker:Hide()

  local function UpdatePosition()
    local tooltip = tracker.tooltip
    if not tooltip or not tooltip:IsShown() then
      tracker:Hide()
      return
    end

    -- Hide Combat Tooltip may intentionally set alpha to zero. No need to do
    -- cursor work until the tooltip is visible again.
    if tooltip:GetAlpha() == 0 then return end

    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then scale = UIParent:GetScale() end
    if not scale or scale == 0 then scale = 1 end

    local x, y = GetCursorPosition()
    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 16, y / scale + 18)
  end

  tracker:SetScript("OnUpdate", UpdatePosition)

  -- Keep the original default-anchor function intact and only reposition
  -- afterwards. The tracker exists only while a tooltip using that default
  -- anchor is shown.
  hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    if tooltip ~= GameTooltip then return end

    tracker.tooltip = tooltip
    tooltip:SetClampedToScreen(true)
    tracker:Show()
    UpdatePosition()
  end)

  hooksecurefunc(GameTooltip, "Hide", function()
    tracker:Hide()
    tracker.tooltip = nil
  end)
end
