local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local HookScript = ShaguTweaks.HookScript

local module = ShaguTweaks:register({
  title = T["Metric Range"],
  description = T["Displays tooltip range units in metres instead of yards."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Tooltip & Items"],
  enabled = true,
})

module.enable = function(self)
  -- Avoid double processing while the old standalone addon is still enabled.
  if IsAddOnLoaded("MetricRange") then return end

  local function ConvertText(text)
    if type(text) ~= "string" then return text end

    -- Intentionally keep the original behavior: only replace the displayed
    -- unit label. Do not numerically convert the range value.
    text = string.gsub(text, " yards", " metres")
    text = string.gsub(text, " yard", " metre")
    text = string.gsub(text, " yd", " m")
    return text
  end

  local function ConvertTooltip(tooltip)
    if not tooltip or not tooltip.GetName then return end

    local name = tooltip:GetName()
    if not name then return end

    -- GameTooltip-style frames expose NumLines() in Vanilla. Only inspect the
    -- lines that actually exist instead of probing 30 left/right font strings
    -- on every tooltip show. Keep the historical 30-line ceiling as fallback.
    local lines = 30
    if tooltip.NumLines then
      lines = math.min(tooltip:NumLines() or 0, 30)
    end

    for i = 1, lines do
      local left = _G[name .. "TextLeft" .. i]
      if left then
        local old = left:GetText()
        if old then
          local new = ConvertText(old)
          if new ~= old then left:SetText(new) end
        end
      end

      local right = _G[name .. "TextRight" .. i]
      if right then
        local old = right:GetText()
        if old then
          local new = ConvertText(old)
          if new ~= old then right:SetText(new) end
        end
      end
    end
  end

  local function HookTooltip(tooltip)
    if not tooltip then return end
    HookScript(tooltip, "OnShow", function()
      ConvertTooltip(tooltip)
    end)
  end

  HookTooltip(GameTooltip)
  HookTooltip(ItemRefTooltip)
  HookTooltip(ShoppingTooltip1)
  HookTooltip(ShoppingTooltip2)
  HookTooltip(ShoppingTooltip3)

  if GameTooltip and GameTooltip:IsVisible() then ConvertTooltip(GameTooltip) end
  if ItemRefTooltip and ItemRefTooltip:IsVisible() then ConvertTooltip(ItemRefTooltip) end
end
