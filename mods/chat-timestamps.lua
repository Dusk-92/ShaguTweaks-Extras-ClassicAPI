local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local rgbhex = ShaguTweaks.rgbhex

local module = ShaguTweaks:register({
  title = T["Chat Timestamps"],
  description = T["Add timestamps to chat messages."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Chat"],
  maintainer = "@shagu (GitHub)",
  enabled = false,
  config = {
    ["chat.timestamp.bracket"] = "[]",
    ["chat.timestamp.format"] = 24,
    ["chat.timestamp.color"] = { r = .8, g = .8, b = .8, a = 1},
  }
})

module.enable = function(self)
    -- config shortcuts
    local bracket = self.config["chat.timestamp.bracket"]
    local clock = self.config["chat.timestamp.format"]
    local rgb = self.config["chat.timestamp.color"]

    -- parse config
    local left = string.sub(bracket, 1, 1) or ""
    local right = string.sub(bracket, 2, 2) or ""
    local format = clock == 24 and "%H:%M:%S" or "%I:%M:%S %p"
    local color = rgbhex({ rgb.r, rgb.g, rgb.b, rgb.a })

    local function InstallTimestampHooks()
      for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame and not frame.ShaguTweaksExtrasTimestampAddMessage then
          frame.ShaguTweaksExtrasTimestampAddMessage = frame.AddMessage
          frame.AddMessage = function(self, msg, a1, a2, a3, a4, a5)
            if not msg then return end

            msg = color .. left .. date(format) .. right .. "|r " .. msg
            self:ShaguTweaksExtrasTimestampAddMessage(msg, a1, a2, a3, a4, a5)
          end
        end
      end
    end

    -- Install after the normal ShaguTweaks module pass. Chat Tweaks in the
    -- main fork also wraps AddMessage, and its module order is intentionally
    -- unordered. Waiting for PLAYER_ENTERING_WORLD makes timestamps the outer
    -- wrapper every time, so history consistently stores the displayed time.
    local installer = CreateFrame("Frame", nil, UIParent)
    installer:RegisterEvent("PLAYER_ENTERING_WORLD")
    installer:SetScript("OnEvent", function()
      InstallTimestampHooks()
      this:UnregisterAllEvents()
      this:Hide()
    end)
end
