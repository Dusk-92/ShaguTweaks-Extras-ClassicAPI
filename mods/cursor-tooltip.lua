-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local _G = ShaguTweaks.GetGlobalEnv()
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
  -- This feature intentionally replaces the default-anchor helper. A post-hook
  -- is not enough on Vanilla/Turtle because the native helper marks the
  -- tooltip as default and later layout code can restore the bottom-right
  -- position. Replacing only this helper keeps non-default tooltip anchors
  -- untouched.
  if not ShaguTweaks.CursorTooltipOriginalDefaultAnchor then
    ShaguTweaks.CursorTooltipOriginalDefaultAnchor = _G.GameTooltip_SetDefaultAnchor
  end

  local cursor = CreateFrame("Frame", nil, UIParent)
  cursor:SetWidth(20)
  cursor:SetHeight(20)
  cursor:Hide()

  cursor:SetScript("OnUpdate", function()
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then scale = UIParent:GetScale() end
    if not scale or scale == 0 then scale = 1 end

    local x, y = GetCursorPosition()
    this:ClearAllPoints()
    this:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
  end)

  function _G.GameTooltip_SetDefaultAnchor(tooltip, parent)
    tooltip:SetOwner(parent, "ANCHOR_NONE")
    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", cursor, "TOPRIGHT", 12, 12)
    tooltip.default = 1

    cursor:Show()
  end

  hooksecurefunc(GameTooltip, "Hide", function()
    cursor:Hide()
  end)
end
