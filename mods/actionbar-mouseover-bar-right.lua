-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Mouseover Right"],
  description = T["Hide the right actionbar and show it on mouseover."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Action Bar"],
  enabled = nil,
})

module.enable = function(self)
  ShaguTweaks.CreateMouseoverActionBar(MultiBarRight, "SHOW_MULTI_ACTIONBAR_3")
end
