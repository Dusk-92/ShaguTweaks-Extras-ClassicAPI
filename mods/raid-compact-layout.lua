local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Use Compact Layout"],
  description = T["Reduces the raid frame size and the displayed elements. As a healer, you should never use this layout."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = nil,
})

module.enable = function(self)
  -- overwrite config
  ShaguTweaksRaidCluster.config["raid.width"] = 64
  ShaguTweaksRaidCluster.config["raid.height"] = 12
  ShaguTweaksRaidCluster.config["raid.rows"] = 40

  -- disable mana bars
  ShaguTweaks.UnitFrame_NewComponent('compact layout', {
    events = { },
    create = function(frame)
      -- hide mana bar
      frame.mana:Hide()

      -- move player text to healthbar
      frame.text:SetParent(frame.bar)
      frame.icon:SetParent(frame.bar)
      -- move raid icon
      frame.icon:ClearAllPoints()
      frame.icon:SetPoint("LEFT", frame.bar, "LEFT", 0, 0)

    end,
    update = function(frame, event)
      -- disable all second lines
      frame.info = nil
    end
  })

  -- wait for the game to be loaded
  local delay = CreateFrame("Frame")
  delay:SetScript("OnUpdate", function()
      if ShaguTweaksRaidHeaders then
        -- modify group headers
        for i=1, 8 do
          if ShaguTweaksRaidHeaders[i] then
            -- read raid anchor per group header
            local _, anchor = ShaguTweaksRaidHeaders[i]:GetPoint()

            -- remove background and move to the left
            --ShaguTweaksRaidHeaders[i]:SetBackdrop(nil)
            ShaguTweaksRaidHeaders[i]:ClearAllPoints()
            ShaguTweaksRaidHeaders[i]:SetPoint("LEFT", anchor, "LEFT", -6, 6)
            ShaguTweaksRaidHeaders[i]:SetWidth(16)
            ShaguTweaksRaidHeaders[i]:SetHeight(16)
            --ShaguTweaksRaidHeaders[i].text:SetTextColor(.5,.5,.5,1)
            ShaguTweaksRaidHeaders[i].text:SetText(i)
            ShaguTweaksRaidHeaders[i]:SetAlpha(.75)
          end
        end
      end

      -- disable delay
      this:Hide()
  end)

end
