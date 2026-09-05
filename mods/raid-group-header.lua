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
      -- skip if already initialized
      if init then return else init = true end

      -- create shortcut to raid.cluster
      local cluster = frame:GetParent()

      -- initialize header frame on cluster
      local header = CreateFrame("Frame", "ShaguTweaksRaidHeaders", cluster)
      header:SetFrameLevel(128)
      header:SetScale(.9)
      header:SetAllPoints(cluster)
      header:RegisterEvent("PLAYER_ENTERING_WORLD")
      header:RegisterEvent("RAID_ROSTER_UPDATE")
      header:SetScript("OnEvent", function()
        for i = 1, 40 do
          if math.mod(i, 5) == 1 then
            local group = math.ceil(i/5)

            -- create header base frame
            if not header[group] then
              header[group] = header[group] or CreateFrame("Frame", "ShaguTweaksRaidGroupHeader" .. group, header)
              header[group]:SetPoint("TOP", cluster.frames[i], "TOP", 0, 6)
              header[group]:SetWidth(42)
              header[group]:SetHeight(16)
              header[group]:SetBackdrop(backdrop)
              header[group]:SetBackdropBorderColor(.8, .8, .8, 1)
              header[group]:SetBackdropColor(.4, .4, .4, 1)
              ShaguTweaks.DarkenFrame(header[group])
            end

            -- create header text
            if not header[group].text then
              header[group].text = header[group]:CreateFontString(nil, "HIGH", "GameFontWhite")
              header[group].text:SetFont(STANDARD_TEXT_FONT, 7, "THINOUTLINE")
              header[group].text:SetAllPoints(header[group])
              header[group].text:SetJustifyH("CENTER")
              header[group].text:SetJustifyV("CENTER")
              header[group].text:SetText("Group " .. group)
            end

            -- toggle visibility if needed
            if RAID_SUBGROUP_LISTS and RAID_SUBGROUP_LISTS[group] and table.getn(RAID_SUBGROUP_LISTS[group]) > 0 then
              header[group]:Show()
            else
              header[group]:Hide()
            end
          end
        end
      end)
    end,

    update = function(frame, event)
      -- noop
    end
  })
end
