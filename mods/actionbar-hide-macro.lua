-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Hide Macro Text"],
  description = T["Hides macro names on action buttons."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Action Bar"],
  enabled = nil,
})

module.enable = function(self)
  local function HideMacroText(button)
    if not button or not button.GetName then return end

    local name = button:GetName()
    local text = name and _G[name .. "Name"]
    if text then text:SetAlpha(0) end
  end

  for i = 1, 24 do
    HideMacroText(_G["BonusActionButton" .. i])
  end

  for i = 1, 12 do
    HideMacroText(_G["ActionButton" .. i])
    HideMacroText(_G["MultiBarRightButton" .. i])
    HideMacroText(_G["MultiBarLeftButton" .. i])
    HideMacroText(_G["MultiBarBottomLeftButton" .. i])
    HideMacroText(_G["MultiBarBottomRightButton" .. i])
  end
end
