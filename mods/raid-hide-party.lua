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
  local show = _G['PartyMemberFrame1'].Show
  local hide = function() return end

  local scanner = CreateFrame("Frame", nil, UIParent)
  scanner:SetScript("OnUpdate", function()
    if ShaguTweaksRaidFrame and ShaguTweaksRaidFrame:IsShown() then
      if not this.disable then
        -- disable all party frames
        for i = 1, MAX_PARTY_MEMBERS do
          local frame = _G['PartyMemberFrame' .. i]
          if frame then
            frame.Show = hide
            frame:Hide()
          end
        end

        this.disable = true
      end
    else
      if this.disable then
        -- enable all party frames
        for i = 1, MAX_PARTY_MEMBERS do
          for i = 1, MAX_PARTY_MEMBERS do
            local frame = _G['PartyMemberFrame' .. i]
            if frame then
              frame.Show = show
              if GetPartyMember(i) then
                frame:Show()
              end
            end
          end
        end

        this.disable = nil
      end
    end
  end)
end
