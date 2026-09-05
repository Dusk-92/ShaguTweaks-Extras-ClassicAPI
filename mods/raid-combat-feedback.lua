local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Show Combat Feedback"],
  description = T["Show combat feedback numbers on health bars."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = true,
})

module.enable = function(self)
  ShaguTweaks.UnitFrame_NewComponent('combat feedback', {
    events = {
      'UNIT_COMBAT',
    },

    create = function(frame)
      -- create combat feedback text
      frame.feedback = frame.mana:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
      frame.feedback:SetFont(DAMAGE_TEXT_FONT, 12, "OUTLINE")
      frame.feedback:SetParent(frame.mana)
      frame.feedback:ClearAllPoints()
      frame.feedback:SetPoint("CENTER", frame.bar, "CENTER", 0, 0)
      frame.feedback:Hide()

      frame.feedbackFontHeight = 12
      frame.feedbackText = frame.feedback

      -- Blizzard's CombatFeedback animation lasts only 1.2 seconds. Keep the
      -- unit frame asleep while there is nothing to animate, then remove the
      -- OnUpdate again as soon as Blizzard hides the feedback text.
      frame.feedbackOnUpdate = function()
        CombatFeedback_OnUpdate(arg1)
        if not this.feedback:IsVisible() then
          this:SetScript("OnUpdate", nil)
        end
      end
    end,

    update = function(frame, event)
      if not event then return end

      if event == 'UNIT_COMBAT' then
        -- update with latest values
        if arg1 ~= frame.unitstr then return end
        CombatFeedback_OnCombatEvent(arg2, arg3, arg4, arg5)
        frame:SetScript("OnUpdate", frame.feedbackOnUpdate)
      else
        -- Raid roster/world refreshes can reassign this frame to another unit.
        -- Never carry an old animation across that reassignment.
        frame.feedback:Hide()
        frame:SetScript("OnUpdate", nil)
      end
    end
  })
end
