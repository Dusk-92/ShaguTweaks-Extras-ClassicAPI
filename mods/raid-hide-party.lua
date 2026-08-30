local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Hide Party Frames"],
  description = T["Disable default party frames while the raidframes are active."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = true,
})

module.enable = function(self)
  if not ShaguTweaks.RaidFrame_OnReady then return end

  ShaguTweaks.RaidFrame_OnReady(function(raid)
    local originals = {}
    local hidden = false

    for i = 1, MAX_PARTY_MEMBERS do
      local frame = _G["PartyMemberFrame" .. i]
      if frame then originals[frame] = frame.Show end
    end

    local function SetPartyFramesHidden(state)
      if state == hidden then return end
      hidden = state

      for i = 1, MAX_PARTY_MEMBERS do
        local frame = _G["PartyMemberFrame" .. i]
        if frame then
          if state then
            frame.Show = function() return end
            frame:Hide()
          else
            frame.Show = originals[frame]
            if GetPartyMember(i) then frame:Show() else frame:Hide() end
          end
        end
      end
    end

    local function UpdatePartyFrames()
      local active = raid:IsShown() and raid.cluster and raid.cluster:IsShown()
      SetPartyFramesHidden(active and true or false)
    end

    ShaguTweaks.HookScript(raid, "OnShow", UpdatePartyFrames)
    ShaguTweaks.HookScript(raid, "OnHide", UpdatePartyFrames)
    ShaguTweaks.HookScript(raid.cluster, "OnShow", UpdatePartyFrames)
    ShaguTweaks.HookScript(raid.cluster, "OnHide", UpdatePartyFrames)

    local watcher = CreateFrame("Frame", nil, UIParent)
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("RAID_ROSTER_UPDATE")
    watcher:RegisterEvent("PARTY_MEMBERS_CHANGED")
    watcher:SetScript("OnEvent", UpdatePartyFrames)

    UpdatePartyFrames()
  end)
end
