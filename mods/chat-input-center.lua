local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local hooksecurefunc = ShaguTweaks.hooksecurefunc

local module = ShaguTweaks:register({
  title = T["Center Text Input Box"],
  description = T["Move the chat input box to the center of the screen."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Chat"],
  maintainer = "@shagu (GitHub)",
  enabled = nil,
})

local dodge_frames = {
  MainMenuBarArtFrame, MultiBarBottomLeft, MultiBarBottomRight, PetActionBarFrame, ShapeshiftBarFrame
}

module.enable = function(self)
  ChatFrameEditBox:SetWidth(300)

  local function UpdateInputPosition()
    local top = 0
    for _, frame in ipairs(dodge_frames) do
      if frame and frame:IsVisible() and frame:GetTop() then
        top = math.max(top, frame:GetTop())
      end
    end

    ChatFrameEditBox:ClearAllPoints()
    ChatFrameEditBox:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, top)
  end

  -- Other ShaguTweaks modules also post-hook UIParent_ManageFramePositions.
  -- Module enable order is intentionally unordered, so install this layout
  -- hook at PLAYER_ENTERING_WORLD after the normal module pass. This makes
  -- the edit box position use the final actionbar/pet/stance positions.
  local installer = CreateFrame("Frame", nil, UIParent)
  installer:RegisterEvent("PLAYER_ENTERING_WORLD")
  installer:SetScript("OnEvent", function()
    hooksecurefunc("UIParent_ManageFramePositions", UpdateInputPosition)
    UpdateInputPosition()
    this:UnregisterAllEvents()
    this:Hide()
  end)
end
