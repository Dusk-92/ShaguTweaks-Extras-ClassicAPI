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
  if ShaguTweaks.CursorTooltipInstalled then return end
  ShaguTweaks.CursorTooltipInstalled = true

  -- Keep the native helper for non-GameTooltip callers. The feature only
  -- needs to move the normal world/UI GameTooltip and should not unexpectedly
  -- change other tooltip frames that may reuse the same helper.
  local originalDefaultAnchor = ShaguTweaks.CursorTooltipOriginalDefaultAnchor
    or _G.GameTooltip_SetDefaultAnchor

  ShaguTweaks.CursorTooltipOriginalDefaultAnchor = originalDefaultAnchor

  local cursor = CreateFrame("Frame", nil, UIParent)
  cursor:SetWidth(1)
  cursor:SetHeight(1)
  cursor:Hide()

  local following = false
  local lastX, lastY, lastScale

  local function UpdateCursor(force)
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then scale = UIParent:GetScale() end
    if not scale or scale == 0 then scale = 1 end

    local x, y = GetCursorPosition()

    -- GetCursorPosition is cheap and required for following the pointer, but
    -- avoid a frame-layout operation while the mouse is completely still.
    if not force and x == lastX and y == lastY and scale == lastScale then
      return
    end

    lastX, lastY, lastScale = x, y, scale

    -- Reusing the same CENTER anchor updates it in place; ClearAllPoints every
    -- rendered frame is unnecessary.
    cursor:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
  end

  cursor:SetScript("OnUpdate", function()
    if not following or not GameTooltip:IsShown() then
      this:Hide()
      return
    end

    UpdateCursor(false)
  end)

  function _G.GameTooltip_SetDefaultAnchor(tooltip, parent)
    if tooltip ~= GameTooltip then
      return originalDefaultAnchor(tooltip, parent)
    end

    tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")
    tooltip:ClearAllPoints()

    -- Position once before Show() so there is no first-frame jump from the
    -- cursor frame's default origin.
    UpdateCursor(true)

    tooltip:SetPoint("BOTTOMLEFT", cursor, "TOPRIGHT", 12, 12)
    tooltip:SetClampedToScreen(true)
    tooltip.default = 1

    following = true
  end

  -- Default anchoring normally happens before GameTooltip:Show(). Start the
  -- per-frame cursor tracker only once the tooltip is actually visible.
  hooksecurefunc(GameTooltip, "Show", function()
    if not following then return end

    UpdateCursor(true)
    cursor:Show()
  end)

  hooksecurefunc(GameTooltip, "Hide", function()
    following = false
    cursor:Hide()
  end)
end
