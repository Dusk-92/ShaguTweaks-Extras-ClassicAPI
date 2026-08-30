local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Show Group Headers"],
  description = T["Display group headers on raid frames"],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = nil,
})

local init = false
local backdrop = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

module.enable = function(self)
  ShaguTweaks.UnitFrame_NewComponent('group header', {
    events = { },

    create = function(frame)
      if init then return end
      init = true

      local cluster = frame:GetParent()
      local header = CreateFrame("Frame", "ShaguTweaksRaidHeaders", cluster)
      header:SetFrameLevel(128)
      header:SetScale(.9)
      header:SetAllPoints(cluster)

      local function UpdateHeaders()
        if not cluster.frames then return end

        for group = 1, 8 do
          local index = (group - 1) * 5 + 1
          local anchorFrame = cluster.frames[index]

          if anchorFrame then
            if not header[group] then
              header[group] = CreateFrame("Frame", "ShaguTweaksRaidGroupHeader" .. group, header)
              header[group]:SetPoint("TOP", anchorFrame, "TOP", 0, 6)
              header[group]:SetWidth(42)
              header[group]:SetHeight(16)
              header[group]:SetBackdrop(backdrop)
              header[group]:SetBackdropBorderColor(.8, .8, .8, 1)
              header[group]:SetBackdropColor(.4, .4, .4, 1)
              ShaguTweaks.DarkenFrame(header[group])

              header[group].text = header[group]:CreateFontString(nil, "HIGH", "GameFontWhite")
              header[group].text:SetFont(STANDARD_TEXT_FONT, 7, "THINOUTLINE")
              header[group].text:SetAllPoints(header[group])
              header[group].text:SetJustifyH("CENTER")
              header[group].text:SetJustifyV("CENTER")
              header[group].text:SetText("Group " .. group)
            end

            local inRaid = RAID_SUBGROUP_LISTS
              and RAID_SUBGROUP_LISTS[group]
              and table.getn(RAID_SUBGROUP_LISTS[group]) > 0
            local inParty = group == 1
              and not UnitInRaid("player")
              and GetNumPartyMembers() > 0

            if inRaid or inParty then
              header[group]:Show()
            else
              header[group]:Hide()
            end
          end
        end
      end

      header.Update = UpdateHeaders
      header:RegisterEvent("PLAYER_ENTERING_WORLD")
      header:RegisterEvent("RAID_ROSTER_UPDATE")
      header:RegisterEvent("PARTY_MEMBERS_CHANGED")
      header:SetScript("OnEvent", UpdateHeaders)

      -- The header container is created while the first raid unit frame is
      -- still being built. Wait until all 40 anchors exist, then initialize
      -- once even if the PLAYER_ENTERING_WORLD event that created us was missed.
      header:SetScript("OnUpdate", function()
        if cluster.frames and cluster.frames[40] then
          UpdateHeaders()
          this:SetScript("OnUpdate", nil)
        end
      end)
    end,

    update = function(frame, event)
      -- noop
    end
  })
end
