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
  tracker.tooltip = nil
  tracker.follow = false
  tracker:Hide()

  local function UpdatePosition()
    local tooltip = tracker.tooltip
    if not tracker.follow or not tooltip or not tooltip:IsShown() then
      tracker:Hide()
      return
    end

    -- Hide Combat Tooltip may intentionally make the tooltip transparent.
    -- Keep the tracker alive so Shift can reveal it immediately without
    -- rebuilding the anchor.
    if tooltip:GetAlpha() == 0 then return end

    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then scale = UIParent:GetScale() end
    if not scale or scale == 0 then scale = 1 end

    local x, y = GetCursorPosition()
    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 16, y / scale + 18)
  end

  tracker:SetScript("OnUpdate", UpdatePosition)

  -- GameTooltip_SetDefaultAnchor is normally called before GameTooltip:Show().
  -- The first test version started the tracker immediately, saw a hidden
  -- tooltip and stopped again. Mark it here and start tracking on Show instead.
  hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    if tooltip ~= GameTooltip then return end

    tracker.tooltip = tooltip
    tracker.follow = true

    tooltip:SetClampedToScreen(true)
    tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")

    if tooltip:IsShown() then
      tracker:Show()
      UpdatePosition()
    end
  end)

  hooksecurefunc(GameTooltip, "Show", function()
    if not tracker.follow or tracker.tooltip ~= GameTooltip then return end
    tracker:Show()
    UpdatePosition()
  end)

  hooksecurefunc(GameTooltip, "Hide", function()
    tracker:Hide()
    tracker.tooltip = nil
    tracker.follow = false
  end)
end
