-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Mouseover Right 2"],
  description = T["Hide the second right actionbar and show it on mouseover."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Action Bar"],
  enabled = nil,
})

module.enable = function(self)
  ShaguTweaks.CreateMouseoverActionBar(MultiBarLeft, "SHOW_MULTI_ACTIONBAR_4")
end
