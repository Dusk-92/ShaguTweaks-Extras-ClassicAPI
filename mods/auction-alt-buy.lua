local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API
local hooksecurefunc = ShaguTweaks.hooksecurefunc

local module = ShaguTweaks:register({
  title = T["Auction Alt-Buy"],
  description = T["Alt-click an auction to buy it out instantly, or Alt-click your own auction to cancel it."],
  expansions = { ["vanilla"] = true },
  category = T["Merchant & Auction"],
  enabled = true,
})

module.enable = function(self)
  -- Do not double-hook when migrating from the standalone addon.
  if IsAddOnLoaded("AuctionAltBuy") then return end

  local installed

  local function AltDown()
    return API and API.IsAltKeyDown and API.IsAltKeyDown()
  end

  local function InstallHooks()
    if installed then return end
    if type(_G.BrowseButton_OnClick) ~= "function"
      or type(_G.AuctionsButton_OnClick) ~= "function" then
      return
    end

    -- Run after the native handler so the clicked row has already become the
    -- selected auction. Read the selected row itself instead of trusting a
    -- cached frame-level buyout value.
    hooksecurefunc("BrowseButton_OnClick", function()
      if not AltDown() then return end
      if not AuctionFrame or not AuctionFrame.type then return end

      local index = GetSelectedAuctionItem(AuctionFrame.type)
      if not index or index <= 0 then return end

      local _, _, _, _, _, _, _, _, buyout = GetAuctionItemInfo(AuctionFrame.type, index)
      if buyout and buyout > 0 then
        PlaceAuctionBid(AuctionFrame.type, index, buyout)
      end
    end)

    hooksecurefunc("AuctionsButton_OnClick", function()
      if not AltDown() then return end

      local index = GetSelectedAuctionItem("owner")
      if index and index > 0 then
        CancelAuction(index)
      end
    end)

    installed = true
  end

  local frame = CreateFrame("Frame", nil, UIParent)
  frame:RegisterEvent("AUCTION_HOUSE_SHOW")
  frame:SetScript("OnEvent", InstallHooks)

  -- Some 1.12 clients keep auction functions resident.
  InstallHooks()
end
