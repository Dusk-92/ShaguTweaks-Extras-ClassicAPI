local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Show Healing Predictions"],
  description = T["Show healing predictions that are received in a healcomm compatible protocol."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = true,
})

module.enable = function(self)
  ShaguTweaks.UnitFrame_NewComponent('healing predictions', {
    events = {
      'FRAME_TICK_250',
    },

    create = function(frame)
      -- create green prediction healthbar
      frame.predict = frame.bar:CreateTexture(nil, "BORDER")
      frame.predict:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
      frame.predict:SetVertexColor(0, 1, 0, 1)
      frame.predict:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", 0, 0)
      frame.predict:SetPoint("BOTTOMLEFT", frame.bar, "BOTTOMLEFT", 0, 0)
      frame.predict:Hide()
    end,

    update = function(frame, event)
      -- read predictions
      local heal = ShaguTweaks.libpredict:UnitGetIncomingHeals(frame.unitstr)
      local res = ShaguTweaks.libpredict:UnitHasIncomingResurrection(frame.unitstr)

      -- Health can change while the incoming-heal amount stays constant, so
      -- recalculate the projected width on every 250ms prediction tick.
      if heal and heal > 0 then
        local health, maxHealth = UnitHealth(frame.unitstr), UnitHealthMax(frame.unitstr)
        local barWidth = frame.bar:GetWidth()
        local healthWidth = maxHealth > 0 and barWidth * health / maxHealth or 0
        local incWidth = maxHealth > 0 and barWidth * heal / maxHealth or 0
        frame.predict:SetWidth(math.min(barWidth, healthWidth + incWidth))
        frame.predict:Show()
      else
        frame.predict:Hide()
      end

      frame.predict_lastval = heal

      -- update healing state
      if heal and heal > 0 then
        frame.info = "|cff22ff22+" .. heal .. "|r"
      end

      -- update resurrection state
      if res then
        frame.info = "|cffffff55Resurrecting"
      end
    end
  })
end
