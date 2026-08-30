local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API or {}

local module = ShaguTweaks:register({
  title = T["Macro Tweaks"],
  description = T["Add /equip, /use and modern ClassicAPI macro commands, remove #showtooltip from chat and hide macro commands from history."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  maintainer = "@shagu (GitHub)",
  category = T["Macro"],
  enabled = true,
})

module.enable = function(self)
  -- This interception is intentional: #showtooltip is macro metadata and must
  -- not be sent as chat text by the Vanilla macro parser.
  local hookSendChatMessage = _G.SendChatMessage
  function _G.SendChatMessage(msg, a1, a2, a3, a4, a5, a6, a7, a8)
    if msg and string.find(msg, "^#showtooltip%s") then return end
    return hookSendChatMessage(msg, a1, a2, a3, a4, a5, a6, a7, a8)
  end

  -- do not write executed macro commands into chat input history
  if not ChatFrameEditBox._AddHistoryLine then
    local userinput

    ChatFrameEditBox._AddHistoryLine = ChatFrameEditBox.AddHistoryLine
    ChatFrameEditBox.AddHistoryLine = function(self, text)
      if not userinput and text then
        if string.find(text, "^/run%s*") then return end
        if string.find(text, "^/script%s*") then return end
        if string.find(text, "^/cast%s*") then return end
        if string.find(text, "^/startattack%s*") then return end
        if string.find(text, "^/stopattack%s*") then return end
        if string.find(text, "^/focus%s*") then return end
        if string.find(text, "^/clearfocus%s*") then return end
      end
      ChatFrameEditBox._AddHistoryLine(self, text)
    end

    local OnEnter = ChatFrameEditBox:GetScript("OnEnterPressed")
    ChatFrameEditBox:SetScript("OnEnterPressed", function(a1,a2,a3,a4)
      userinput = true
      if OnEnter then OnEnter(a1,a2,a3,a4) end
      userinput = nil
    end)
  end

  local function GetBagItemName(bag, slot)
    if API.GetContainerItemID and API.GetItemNameByID then
      local itemID = API.GetContainerItemID(bag, slot)
      local name = itemID and API.GetItemNameByID(itemID)
      if name then return name end
    end

    local itemLink = GetContainerItemLink(bag, slot)
    if not itemLink then return end
    local _, _, itemID = string.find(itemLink, "item:(%d+)")
    return itemID and GetItemInfo(itemID) or nil
  end

  local function FindItem(item)
    local wanted = string.lower(item or "")
    for bag = 4, 0, -1 do
      for slot = 1, GetContainerNumSlots(bag) do
        local query = GetBagItemName(bag, slot)
        if query and string.lower(query) == wanted then
          return bag, slot
        end
      end
    end
  end

  -- ClassicAPI exposes several modern macro primitives as Lua functions but
  -- Vanilla does not register their familiar slash-command equivalents.
  -- Add only the small set that maps cleanly to modern macro syntax, and leave
  -- any command already registered by another addon untouched.
  local function TrimUnit(msg)
    if not msg then return nil end
    local _, _, unit = string.find(msg, "^%s*(.-)%s*$")
    return unit ~= "" and unit or nil
  end

  if not _G.SlashCmdList.STARTATTACK then
    _G.SLASH_STARTATTACK1 = "/startattack"
    _G.SlashCmdList.STARTATTACK = function(msg)
      if type(_G.StartAttack) == "function" then
        _G.StartAttack(TrimUnit(msg))
      end
    end
  end

  if not _G.SlashCmdList.STOPATTACK then
    _G.SLASH_STOPATTACK1 = "/stopattack"
    _G.SlashCmdList.STOPATTACK = function()
      if type(_G.StopAttack) == "function" then
        _G.StopAttack()
      end
    end
  end

  if not _G.SlashCmdList.FOCUS then
    _G.SLASH_FOCUS1 = "/focus"
    _G.SlashCmdList.FOCUS = function(msg)
      if type(_G.FocusUnit) == "function" then
        _G.FocusUnit(TrimUnit(msg))
      end
    end
  end

  if not _G.SlashCmdList.CLEARFOCUS then
    _G.SLASH_CLEARFOCUS1 = "/clearfocus"
    _G.SlashCmdList.CLEARFOCUS = function()
      if type(_G.ClearFocus) == "function" then
        _G.ClearFocus()
      end
    end
  end

  _G.SLASH_EQUIP1 = "/equip"
  _G.SLASH_EQUIP2 = "/use"
  _G.SlashCmdList.EQUIP = function(msg)
    if not msg or msg == "" then return end

    local bag, slot
    local _, _, parsedBag, parsedSlot = string.find(msg, "^(%d+)%s+(%d+)$")
    if parsedBag and parsedSlot then
      bag, slot = parsedBag, parsedSlot
    else
      local _, _, inventorySlot = string.find(msg, "^(%d+)$")
      if inventorySlot then
        slot = inventorySlot
      else
        bag, slot = FindItem(msg)
      end
    end

    bag = bag and tonumber(bag) or nil
    slot = slot and tonumber(slot) or nil

    if bag and slot then
      UseContainerItem(bag, slot)
    elseif slot then
      UseInventoryItem(slot)
    end
  end
end
