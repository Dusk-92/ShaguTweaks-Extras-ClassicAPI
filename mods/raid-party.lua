local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Use As Party Frames"],
  description = T["Use raid frames to display party members in regular groups"],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = nil,
})

module.enable = function(self)
  local raid = ShaguTweaksRaidFrame
  if not raid then return end

  local RaidOnEvent = raid:GetScript("OnEvent")
  raid:RegisterEvent("PARTY_LEADER_CHANGED")
  raid:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
  raid:RegisterEvent("PARTY_MEMBERS_CHANGED")

  raid:SetScript("OnEvent", function()
    -- run default scripts
    RaidOnEvent()

    -- break here in normal raid scenario
    if UnitInRaid("player") then return end

    -- check for party mode
    if GetNumPartyMembers() > 0 then
      -- initialize raid frame
      local x, y = 1, 0
      for index = 1, 40 do
        -- clear current unitstr assignments
        this.cluster.frames[index].unitstr = nil
        this.cluster.frames[index]:Hide()

        if index <= 5 then
          -- determine best unitstr
          local unitstr = index == 1 and "player" or "party" .. index-1

          -- assign party to first raid group of frames
          this.cluster.frames[index].unitstr = unitstr
          this.cluster.frames[index].groupid = 1
          this.cluster.frames[index]:Show()

          -- save required raid frame size
          if UnitExists(unitstr) then
            y = math.max(y, index)
          end
        end
      end

      -- set raid frame size
      raid.cluster:SetWidth(x * (raid.cluster.config["raid.width"]+2) + 6)
      raid.cluster:SetHeight(y * (raid.cluster.config["raid.height"]+1) + 7)
      raid:Show()
    else
      raid:Hide()
    end
  end)
end
