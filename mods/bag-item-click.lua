local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API
local hooksecurefunc = ShaguTweaks.hooksecurefunc

local module = ShaguTweaks:register({
  title = T["Bag Item Click"],
  description = T["Send items to trade window or auction house search via right click."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  maintainer = "@shagu (GitHub)",
  enabled = true,
})

module.enable = function(self)
  -- helper functions
  local IsTrading = function()
    return TradeFrame:IsShown()
  end

  local IsAuctionBrowsing = function()
    return AuctionFrame and AuctionFrame:IsShown() and AuctionFrameBrowse and AuctionFrameBrowse:IsShown()
  end

  local IsAuctionSelling = function()
    return AuctionFrame and AuctionFrame:IsShown() and AuctionFrameAuctions and AuctionFrameAuctions:IsShown()
  end

  local function ShiftDown()
    return API.IsShiftKeyDown()
  end

  -- Interception is intentional here: the feature must be able to suppress the
  -- default item use while trade/auction actions are active.
  local pfHookUseContainerItem = _G.UseContainerItem
  function _G.UseContainerItem(bag, slot)
    if IsTrading() and not ShiftDown() then
      -- move item to trade window
      PickupContainerItem(bag, slot)
      local slot = TradeFrame_GetAvailableSlot()
      if slot then ClickTradeButton(slot) end
      if CursorHasItem() then
        ClearCursor()
      end
    elseif IsAuctionBrowsing() and not ShiftDown() then
      -- search item in auction house
      local link = API.GetContainerItemLink(bag, slot)
      local name = link and string.sub(link, string.find(link, "%[")+1, string.find(link, "%]")-1) or ""
      BrowseName:SetText(name)
      AuctionFrameBrowse_Search()
    elseif IsAuctionSelling() and not ShiftDown() then
      -- sell item to auction house
      PickupContainerItem(bag, slot)
      AuctionsItemButton:Click()
      if CursorHasItem() then
        ClearCursor()
      end
    else
      -- default action
      pfHookUseContainerItem(bag, slot)
    end
  end

  -- Append helper text after the native tooltip method instead of replacing it.
  hooksecurefunc(GameTooltip, "SetBagItem", function(self, container, slot)
    if IsTrading() or IsAuctionBrowsing() or IsAuctionSelling() then
      self:AddLine(T["Hold [Shift] to use item."], 0.50, 0.75, 1.00)
      self:Show()
    end
  end)
end
