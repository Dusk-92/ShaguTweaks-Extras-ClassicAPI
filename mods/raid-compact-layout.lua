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
  if not ShaguTweaks.RaidFrame_OnReady then return end

  ShaguTweaks.RaidFrame_OnReady(function(raid)
    -- overwrite config before unit frames are created
    raid.cluster.config["raid.width"] = 64
    raid.cluster.config["raid.height"] = 12
    raid.cluster.config["raid.rows"] = 40

    -- disable mana bars
    ShaguTweaks.UnitFrame_NewComponent('compact layout', {
      events = { },
      create = function(frame)
        frame.compact = true

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
        -- compact mode is handled by the base text component
      end
    })

    local headerTitle = T["Show Group Headers"]
    local headerEnabled = ShaguTweaks_config and ShaguTweaks_config[headerTitle]
    if headerEnabled == nil then
      local headerModule = ShaguTweaks.mods and ShaguTweaks.mods[headerTitle]
      headerEnabled = headerModule and headerModule.enabled and 1 or 0
    end

    -- No header module means there is nothing to wait for or reposition.
    if headerEnabled ~= 1 then return end

    local delay = CreateFrame("Frame")
    delay:SetScript("OnUpdate", function()
      this.elapsed = (this.elapsed or 0) + (arg1 or 0)
      this.total = (this.total or 0) + (arg1 or 0)
      if this.elapsed < .10 then return end
      this.elapsed = 0

      if ShaguTweaksRaidHeaders then
        for i = 1, 8 do
          if ShaguTweaksRaidHeaders[i] then
            local _, anchor = ShaguTweaksRaidHeaders[i]:GetPoint()
            if anchor then
              ShaguTweaksRaidHeaders[i]:ClearAllPoints()
              ShaguTweaksRaidHeaders[i]:SetPoint("LEFT", anchor, "LEFT", -6, 6)
              ShaguTweaksRaidHeaders[i]:SetWidth(16)
              ShaguTweaksRaidHeaders[i]:SetHeight(16)
              ShaguTweaksRaidHeaders[i].text:SetText(i)
              ShaguTweaksRaidHeaders[i]:SetAlpha(.75)
            end
          end
        end
        this:Hide()
      elseif this.total >= 10 then
        -- Fail closed instead of polling forever if headers never materialize.
        this:Hide()
      end
    end)
  end)
end
