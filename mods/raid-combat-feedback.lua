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
      frame.feedback = frame.mana:CreateFontString("feedback"..GetTime(), "OVERLAY", "NumberFontNormalHuge")
      frame.feedback:SetFont(DAMAGE_TEXT_FONT, 12, "OUTLINE")
      frame.feedback:SetParent(frame.mana)
      frame.feedback:ClearAllPoints(frame.bar)
      frame.feedback:SetPoint("CENTER", frame.bar, "CENTER", 0, 0)

      frame.feedbackFontHeight = 12
      frame.feedbackStartTime = GetTime()
      frame.feedbackText = frame.feedback
    end,

    update = function(frame, event)
      if event and event == 'UNIT_COMBAT' then
        -- update with latest values
        if arg1 ~= this.unitstr then return end
        CombatFeedback_OnCombatEvent(arg2, arg3, arg4, arg5)
      else
        -- animate combat text
        CombatFeedback_OnUpdate(arg1)
      end
    end
  })
end
