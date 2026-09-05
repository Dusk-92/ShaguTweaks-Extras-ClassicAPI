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
    events = { },

    create = function(frame)
      -- create green prediction healthbar
      frame.predict = frame.bar:CreateTexture(nil, "BORDER")
      frame.predict:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
      frame.predict:SetVertexColor(0, 1, 0, 1)
      frame.predict:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", 0, 0)
      frame.predict:SetPoint("BOTTOMLEFT", frame.bar, "BOTTOMLEFT", 0, 0)
    end,

    update = function(frame, event)
      -- read predictions
      local heal = ShaguTweaks.libpredict:UnitGetIncomingHeals(frame.unitstr)
      local res = ShaguTweaks.libpredict:UnitHasIncomingResurrection(frame.unitstr)

      -- update bar size if required
      if heal ~= this.predict_lastval then
        if heal and heal > 0 then
          local health, maxHealth = UnitHealth(frame.unitstr), UnitHealthMax(frame.unitstr)
          local healthWidth = 62 * health / maxHealth
          local incWidth = 62 * heal / maxHealth
          local width = math.min(62, healthWidth + incWidth)
          frame.predict:SetWidth(width)
        else
          frame.predict:SetWidth(-1)
        end

        this.predict_lastval = heal
      end

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
