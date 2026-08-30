local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API
local HookScript = ShaguTweaks.HookScript
local floor = math.floor
local ceil = math.ceil
local min = math.min
local mod = math.mod or mod

STBuyEmAll = STBuyEmAll or {}
local Buy = STBuyEmAll

local strings = {
  enUS = {
    ["Max"] = "Max",
    ["Stack"] = "Stack",
    ["Are you sure you want to buy\n %d × %s?"] = "Are you sure you want to buy\n %d × %s?",
    ["Stack purchase"] = "Stack purchase",
    ["Stack size"] = "Stack size",
    ["Partial stack"] = "Partial stack",
    ["Maximum purchase"] = "Maximum purchase",
    ["You can fit"] = "You can fit",
    ["You can afford"] = "You can afford",
    ["Vendor has"] = "Vendor has",
  },
  deDE = {
    ["Are you sure you want to buy\n %d × %s?"] = "Bist du sicher das du\n %d × %s kaufen willst?",
    ["Stack size"] = "Stack größe",
    ["Maximum purchase"] = "Größt möglicher Einkauf",
    ["You can fit"] = "Du hast Platz für",
    ["You can afford"] = "Du kannst dir leisten",
    ["Vendor has"] = "Der Verkäufer hat",
  },
  frFR = {
    ["Stack"] = "Pile",
    ["Are you sure you want to buy\n %d × %s?"] = "Voulez-vous vraiment acheter\n %d × %s?",
    ["Stack size"] = "Taille de pile",
    ["Maximum purchase"] = "Achat maximum",
    ["You can fit"] = "Vous pouvez transporter",
    ["You can afford"] = "Vous pouvez payer",
    ["Vendor has"] = "Le marchand a",
  },
}

local locale = strings[GetLocale()] or strings.enUS
local function L(key)
  return locale[key] or strings.enUS[key] or key
end

BUYEMALL_MAX = L("Max")
BUYEMALL_STACK = L("Stack")

local module = ShaguTweaks:register({
  title = T["Buy Em All"],
  description = T["Shift-click vendor items to choose stack, maximum, or a custom purchase amount."],
  expansions = { ["vanilla"] = true },
  category = T["Merchant & Auction"],
  enabled = true,
})

local function FamilyMatches(itemFamily, bagFamily)
  bagFamily = tonumber(bagFamily) or 0
  itemFamily = tonumber(itemFamily) or 0

  if bagFamily == 0 then return true end
  if itemFamily == 0 then return false end

  -- Bag families are power-of-two bit flags. Avoid requiring an external bit
  -- library on 1.12 while still supporting Turtle custom specialty families.
  return mod(floor(itemFamily / bagFamily), 2) == 1
end

function Buy:CountPurchaseItem()
  if not self.purchaseItemID then return nil end
  if API and API.GetItemCount then
    return API.GetItemCount(self.purchaseItemID, false, false)
  end
  return nil
end

function Buy:StopPurchaseQueue()
  if self.purchaseFrame then self.purchaseFrame:Hide() end
  self.purchaseItemIndex = nil
  self.purchaseItemID = nil
  self.purchasePreset = 1
  self.purchaseLoops = 0
  self.purchaseAmount = 0
  self.purchaseLeftover = 0
  self.purchaseElapsed = 0
  self.purchaseWaiting = nil
  self.purchaseExpectedCount = nil
  self.purchasePendingKind = nil
end

function Buy:AbortPurchaseQueue()
  self:StopPurchaseQueue()
  DEFAULT_CHAT_FRAME:AddMessage("Buy Em All: purchase queue stopped because the previous stack was not confirmed. No further stacks were sent.")
end

function Buy:ConfirmPendingPurchase()
  if not self.purchaseWaiting or not self.purchaseExpectedCount then return false end

  local count = self:CountPurchaseItem()
  if count == nil or count < self.purchaseExpectedCount then return false end

  if self.purchasePendingKind == "loop" then
    self.purchaseLoops = self.purchaseLoops - 1
  elseif self.purchasePendingKind == "leftover" then
    self.purchaseLeftover = 0
  end

  self.purchaseWaiting = nil
  self.purchaseExpectedCount = nil
  self.purchasePendingKind = nil
  self.purchaseElapsed = 0
  return true
end

function Buy:Purchase_OnEvent()
  self:ConfirmPendingPurchase()
end

function Buy:SendPurchase(quantity, kind)
  local before = self:CountPurchaseItem()
  if before == nil then
    self:AbortPurchaseQueue()
    return
  end

  self.purchaseWaiting = true
  self.purchasePendingKind = kind
  self.purchaseExpectedCount = before + quantity * (self.purchasePreset or 1)
  self.purchaseElapsed = 0
  BuyMerchantItem(self.purchaseItemIndex, quantity)
end

function Buy:Purchase_OnUpdate(elapsed)
  self.purchaseElapsed = (self.purchaseElapsed or 0) + (elapsed or 0)

  if self.purchaseWaiting then
    if self.purchaseElapsed >= self.purchaseTimeout then
      if not self:ConfirmPendingPurchase() then self:AbortPurchaseQueue() end
    end
    return
  end

  if self.purchaseElapsed < self.purchaseDelay then return end
  self.purchaseElapsed = 0

  if self.purchaseLoops and self.purchaseLoops > 0 then
    self:SendPurchase(self.purchaseAmount, "loop")
    return
  end

  if self.purchaseLeftover and self.purchaseLeftover > 0 then
    self:SendPurchase(self.purchaseLeftover, "leftover")
    return
  end

  self:StopPurchaseQueue()
end

function Buy:DoPurchase(amount)
  if not amount or amount <= 0 or not self.itemIndex or not self.preset or not self.stack then return end
  if STBuyEmAllFrame then STBuyEmAllFrame:Hide() end

  local numLoops, purchaseAmount, leftover
  if self.preset > 1 then
    numLoops = floor(amount / self.preset)
    purchaseAmount = 1
    leftover = 0
  else
    numLoops = floor(amount / self.stack)
    purchaseAmount = self.stack
    leftover = mod(amount, self.stack)
  end

  self:StopPurchaseQueue()
  self.purchaseItemIndex = self.itemIndex
  self.purchaseItemID = self.itemID
  self.purchasePreset = self.preset
  self.purchaseLoops = numLoops
  self.purchaseAmount = purchaseAmount
  self.purchaseLeftover = leftover
  self.purchaseElapsed = self.purchaseDelay

  if self.purchaseLoops > 0 or self.purchaseLeftover > 0 then
    self.purchaseFrame:Show()
  end
end

function Buy:DoConfirmation(amount)
  self.confirmAmount = amount
  local dialog = StaticPopup_Show("STBUYEMALL_CONFIRM", amount, self.itemName)
  if dialog then dialog.data = amount end
end

function Buy:VerifyPurchase(amount)
  amount = amount or self.split
  if not amount or amount <= 0 or not self.preset or self.preset <= 0 then return end

  amount = ceil(amount / self.preset) * self.preset
  if amount > self.max then amount = self.max end

  if amount > self.stack and amount > self.defaultStack then
    self:DoConfirmation(amount)
  else
    self:DoPurchase(amount)
  end
end

function Buy:SetStackClick()
  if not self.stack or self.stack <= 0 then
    self.stackClick = self.max or self.split or 1
    return
  end

  local targetRemainder = self.partialFit or 0
  if targetRemainder == 0 then targetRemainder = self.stack end

  local currentRemainder = mod(self.split, self.stack)
  local increase = targetRemainder - currentRemainder
  if increase <= 0 then increase = increase + self.stack end

  self.stackClick = self.split + increase
end

function Buy:UpdateDisplay(amount)
  if not self.preset or not self.price or not self.split then return end

  local purchase = ceil((amount or self.split) / self.preset)
  local cost = purchase * self.price
  if STBuyEmAllMoneyFrame then
    MoneyFrame_Update("STBuyEmAllMoneyFrame", cost)
  end

  if not amount and not self.isUpdating then
    self.isUpdating = true

    STBuyEmAllText:SetText(self.split)
    STBuyEmAllLeftButton:Enable()
    STBuyEmAllRightButton:Enable()

    if self.split >= self.max then
      STBuyEmAllRightButton:Disable()
    elseif self.split <= self.preset then
      STBuyEmAllLeftButton:Disable()
    end

    self:SetStackClick()
    STBuyEmAllStackButton:Enable()
    if not self.stackClick or self.max < self.stackClick then
      STBuyEmAllStackButton:Disable()
    end

    self.isUpdating = nil
  end
end

function Buy:Show(anchor)
  self.typing = 0
  STBuyEmAllLeftButton:Disable()
  STBuyEmAllRightButton:Enable()

  self:SetStackClick()
  STBuyEmAllStackButton:Enable()
  if not self.stackClick or self.max < self.stackClick then STBuyEmAllStackButton:Disable() end

  STBuyEmAllFrame:ClearAllPoints()
  STBuyEmAllFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
  STBuyEmAllFrame:Show()
  self:UpdateDisplay()
end

function Buy:OnClick()
  if this == STBuyEmAllOkayButton then
    self:VerifyPurchase()
  elseif this == STBuyEmAllCancelButton then
    STBuyEmAllFrame:Hide()
  elseif this == STBuyEmAllStackButton then
    if self.stackClick and self.stackClick <= self.max then
      self.split = self.stackClick
      self:UpdateDisplay()
      if this:IsEnabled() == 1 then self:OnEnter() else GameTooltip:Hide() end
    end
  elseif this == STBuyEmAllMaxButton then
    self.split = self.max
    self:UpdateDisplay()
  end
end

function Buy:OnChar()
  local digit = tonumber(arg1)
  if digit == nil then return end

  if self.typing == 0 then
    self.typing = 1
    self.split = 0
  end

  local split = (self.split * 10) + digit
  if split <= self.max then
    self.split = split
  end

  if self.split <= 0 then self.split = 1 end
  self:UpdateDisplay()
end

function Buy:OnKeyDown()
  if arg1 == "BACKSPACE" or arg1 == "DELETE" then
    if self.typing == 0 or self.split == 1 then return end

    self.split = floor(self.split / 10)
    if self.split <= 1 then
      self.split = 1
      self.typing = 0
    end
    self:UpdateDisplay()
  elseif arg1 == "ENTER" then
    self:VerifyPurchase()
  elseif arg1 == "ESCAPE" then
    STBuyEmAllFrame:Hide()
  elseif arg1 == "LEFT" or arg1 == "DOWN" then
    self:Left_Click()
  elseif arg1 == "RIGHT" or arg1 == "UP" then
    self:Right_Click()
  end
end

function Buy:Left_Click()
  if self.split <= self.preset then return end

  local decrease = mod(self.split, self.preset)
  decrease = decrease == 0 and self.preset or decrease
  self.split = self.split - decrease
  self:UpdateDisplay()
end

function Buy:Right_Click()
  local increase = self.preset - mod(self.split, self.preset)
  if self.split + increase > self.max then return end

  self.split = self.split + increase
  self:UpdateDisplay()
end

Buy.lines = {
  stack = {
    label = L("Stack purchase"),
    field = "stackClick",
    { label = L("Stack size"), field = "stack" },
    { label = L("Partial stack"), field = "partialFit" },
  },
  max = {
    label = L("Maximum purchase"),
    field = "max",
    { label = L("You can fit"), field = "fit" },
    { label = L("You can afford"), field = "afford" },
    {
      label = L("Vendor has"),
      field = "available",
      Hide = function()
        return not Buy.available or Buy.available <= 1
      end,
    },
  },
}

function Buy:CreateTooltip(lines)
  GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
  GameTooltip:SetText(lines.label .. "|cFFFFFFFF - |r" .. GREEN_FONT_COLOR_CODE .. (lines.amount or 0) .. "|r")

  for _, line in ipairs(lines) do
    if not (line.Hide and line.Hide()) then
      local color = line.amount == lines.amount and GREEN_FONT_COLOR or HIGHLIGHT_FONT_COLOR
      GameTooltip:AddDoubleLine(line.label, line.amount or 0, 1, 1, 1, color.r, color.g, color.b)
    end
  end

  GameTooltip:Show()
end

function Buy:OnEnter()
  local lines = self.lines[this == STBuyEmAllMaxButton and "max" or "stack"]
  lines.amount = self[lines.field]
  for _, line in ipairs(lines) do line.amount = self[line.field] end

  self:CreateTooltip(lines)
  self:UpdateDisplay(lines.amount)
end

function Buy:OnLeave()
  self:UpdateDisplay()
  GameTooltip:Hide()
end

function Buy:OnHide()
  StaticPopup_Hide("STBUYEMALL_CONFIRM")
end

function Buy:FreeBagSpace(itemID)
  if not itemID then return 0, 1 end

  local stackSize = API.GetItemMaxStackSizeByID(itemID) or 1
  if stackSize < 1 then stackSize = 1 end

  local itemFamily = API.GetItemFamily(itemID) or 0
  local capacity = 0

  for bag = 0, 4 do
    local freeSlots, bagFamily = API.GetContainerNumFreeSlots(bag)
    if FamilyMatches(itemFamily, bagFamily) then
      capacity = capacity + (freeSlots or 0) * stackSize
    end

    local numSlots = GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      local bagItemID = API.GetContainerItemID(bag, slot)
      if bagItemID == itemID then
        local itemCount = API.GetContainerItemStackCount(bag, slot) or 0
        if itemCount < stackSize then
          capacity = capacity + stackSize - itemCount
        end
      end
    end
  end

  return capacity, stackSize
end

function Buy:GetMerchantData(index)
  local info = API.GetMerchantItemInfo and API.GetMerchantItemInfo(index)
  if info and info.itemID then
    local name = API.GetItemNameByID(info.itemID)
    if not name then
      name = GetMerchantItemInfo(index)
    end

    return name, info.itemID, info.price or 0, info.stackCount or 1,
      info.numAvailable or -1
  end

  local name, _, price, quantity, numAvailable = GetMerchantItemInfo(index)
  local itemID = API.GetMerchantItemID and API.GetMerchantItemID(index)
  return name, itemID, price, quantity, numAvailable
end

function Buy:HandleMerchantClick(anchor, button, ignoreModifiers)
  if not anchor or not anchor.GetID then return false end

  if MerchantFrame.selectedTab ~= 1
    or not API.IsShiftKeyDown()
    or API.IsControlKeyDown()
    or ignoreModifiers
    or (ChatFrameEditBox:IsVisible() and button == "LeftButton") then
    return false
  end

  self.itemIndex = anchor:GetID()
  local name, itemID, price, quantity, numAvailable = self:GetMerchantData(self.itemIndex)
  if not name or not itemID or not price or not quantity or quantity < 1 then return false end

  self.preset = quantity
  self.price = price
  self.itemName = name
  self.itemID = itemID
  self.available = numAvailable

  local bagCapacity, stack = self:FreeBagSpace(itemID)
  self.stack = stack
  self.fit = floor(bagCapacity / quantity) * quantity

  if price > 0 then
    self.afford = floor(GetMoney() / price) * quantity
  else
    self.afford = self.fit
  end

  self.max = min(self.fit, self.afford)
  if numAvailable and numAvailable > -1 then
    self.max = min(self.max, numAvailable * quantity)
  end

  if self.max <= 0 then return true end
  if self.max == 1 then
    if self.originalMerchantItemButton_OnClick then
      self.originalMerchantItemButton_OnClick("LeftButton", 1)
    end
    return true
  end

  self.defaultStack = quantity
  if self.defaultStack > self.max then self.defaultStack = self.max end

  self.split = self.defaultStack
  self.partialFit = mod(self.fit, stack)
  self:SetStackClick()
  self:Show(anchor)
  return true
end

function Buy:CreateUI()
  if STBuyEmAllFrame then return end

  local frame = CreateFrame("Frame", "STBuyEmAllFrame", MerchantFrame)
  frame:SetWidth(210)
  frame:SetHeight(110)
  frame:SetFrameStrata("DIALOG")
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, .9)
  frame:EnableKeyboard(true)
  frame:SetScript("OnChar", function() Buy:OnChar() end)
  frame:SetScript("OnKeyDown", function() Buy:OnKeyDown() end)
  frame:SetScript("OnHide", function() Buy:OnHide() end)
  frame:Hide()

  local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  title:SetPoint("TOP", frame, "TOP", 0, -10)
  title:SetText(T["Buy Em All"])

  local amount = frame:CreateFontString("STBuyEmAllText", "ARTWORK", "GameFontHighlight")
  amount:SetWidth(50)
  amount:SetPoint("TOP", frame, "TOP", 0, -29)
  amount:SetText("1")

  local left = CreateFrame("Button", "STBuyEmAllLeftButton", frame, "UIPanelButtonTemplate")
  left:SetWidth(28)
  left:SetHeight(22)
  left:SetPoint("RIGHT", amount, "LEFT", -4, 0)
  left:SetText("-")
  left:SetScript("OnClick", function() Buy:Left_Click() end)

  local right = CreateFrame("Button", "STBuyEmAllRightButton", frame, "UIPanelButtonTemplate")
  right:SetWidth(28)
  right:SetHeight(22)
  right:SetPoint("LEFT", amount, "RIGHT", 4, 0)
  right:SetText("+")
  right:SetScript("OnClick", function() Buy:Right_Click() end)

  local stack = CreateFrame("Button", "STBuyEmAllStackButton", frame, "UIPanelButtonTemplate")
  stack:SetWidth(58)
  stack:SetHeight(22)
  stack:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -50)
  stack:SetText(BUYEMALL_STACK)
  stack:SetScript("OnClick", function() Buy:OnClick() end)
  stack:SetScript("OnEnter", function() Buy:OnEnter() end)
  stack:SetScript("OnLeave", function() Buy:OnLeave() end)

  local maxButton = CreateFrame("Button", "STBuyEmAllMaxButton", frame, "UIPanelButtonTemplate")
  maxButton:SetWidth(58)
  maxButton:SetHeight(22)
  maxButton:SetPoint("LEFT", stack, "RIGHT", 4, 0)
  maxButton:SetText(BUYEMALL_MAX)
  maxButton:SetScript("OnClick", function() Buy:OnClick() end)
  maxButton:SetScript("OnEnter", function() Buy:OnEnter() end)
  maxButton:SetScript("OnLeave", function() Buy:OnLeave() end)

  local okay = CreateFrame("Button", "STBuyEmAllOkayButton", frame, "UIPanelButtonTemplate")
  okay:SetWidth(58)
  okay:SetHeight(22)
  okay:SetPoint("LEFT", maxButton, "RIGHT", 4, 0)
  okay:SetText(OKAY)
  okay:SetScript("OnClick", function() Buy:OnClick() end)

  local cancel = CreateFrame("Button", "STBuyEmAllCancelButton", frame, "UIPanelButtonTemplate")
  cancel:SetWidth(58)
  cancel:SetHeight(22)
  cancel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -78)
  cancel:SetText(CANCEL)
  cancel:SetScript("OnClick", function() Buy:OnClick() end)

  local money = CreateFrame("Frame", "STBuyEmAllMoneyFrame", frame, "SmallMoneyFrameTemplate")
  money:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 11)

  MoneyTypeInfo["STBUYEMALL"] = {
    UpdateFunc = function() return 0 end,
    showSmallerCoins = "Backpack",
    fixedWidth = 1,
    collapse = 1,
  }
  money.info = MoneyTypeInfo["STBUYEMALL"]
  money.moneyType = "STBUYEMALL"
  money.small = 1
end

module.enable = function(self)
  if IsAddOnLoaded("BuyEmAll") then return end

  local required = {
    "GetItemCount", "GetItemMaxStackSizeByID", "GetItemFamily",
    "GetContainerNumFreeSlots", "GetContainerItemID",
    "GetContainerItemStackCount", "GetMerchantItemInfo",
    "GetMerchantItemID", "IsShiftKeyDown", "IsControlKeyDown",
  }
  for _, name in ipairs(required) do
    if not API or type(API[name]) ~= "function" then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff5555ShaguTweaks Extras:|r Buy Em All requires the current ShaguTweaks-ClassicAPI.")
      return
    end
  end

  Buy:CreateUI()

  Buy.purchaseDelay = 0.05
  Buy.purchaseTimeout = 3.0
  Buy.purchaseFrame = Buy.purchaseFrame or CreateFrame("Frame", "STBuyEmAllPurchaseQueue", UIParent)
  Buy.purchaseFrame:Hide()
  Buy.purchaseFrame:RegisterEvent("BAG_UPDATE")
  Buy.purchaseFrame:RegisterEvent("MERCHANT_UPDATE")
  Buy.purchaseFrame:SetScript("OnEvent", function()
    Buy:Purchase_OnEvent()
  end)
  Buy.purchaseFrame:SetScript("OnUpdate", function()
    Buy:Purchase_OnUpdate(arg1)
  end)

  StaticPopupDialogs["STBUYEMALL_CONFIRM"] = {
    text = L("Are you sure you want to buy\n %d × %s?"),
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      Buy:DoPurchase(Buy.confirmAmount)
    end,
    timeout = 0,
    hideOnEscape = true,
  }

  HookScript(MerchantFrame, "OnHide", function()
    STBuyEmAllFrame:Hide()
    Buy:StopPurchaseQueue()
  end)

  local function MerchantItemButton_OnClick_Wrapper(button, ignoreModifiers)
    local anchor = this
    if Buy:HandleMerchantClick(anchor, button, ignoreModifiers) then return end
    if Buy.originalMerchantItemButton_OnClick then
      return Buy.originalMerchantItemButton_OnClick(button, ignoreModifiers)
    end
  end

  local function InstallHook()
    local current = _G.MerchantItemButton_OnClick
    if type(current) ~= "function" then return end
    if current == MerchantItemButton_OnClick_Wrapper then return end

    Buy.originalMerchantItemButton_OnClick = current
    _G.MerchantItemButton_OnClick = MerchantItemButton_OnClick_Wrapper
  end

  InstallHook()

  local frame = CreateFrame("Frame", nil, UIParent)
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("MERCHANT_SHOW")
  frame:SetScript("OnEvent", InstallHook)
end
