local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API

local module = ShaguTweaks:register({
  title = T["Reagent Counter"],
  description = T["Shows a reagent counter on action buttons."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  maintainer = "@shagu (GitHub)",
  category = T["Action Bar"],
  enabled = nil,
})

module.enable = function(self)
  local reagent_slots = { }
  local reagent_counts = { }
  local bars = { "Action", "BonusAction", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight" }

  local reagentcounter = CreateFrame("Frame", "ShaguTweaksReagentCount", UIParent)
  reagentcounter:RegisterEvent("PLAYER_ENTERING_WORLD")
  reagentcounter:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  reagentcounter:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
  reagentcounter:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
  reagentcounter:RegisterEvent("UPDATE_MACROS")
  reagentcounter:RegisterEvent("BAG_UPDATE")

  -- Hidden frames still receive events, but do not execute OnUpdate.
  -- Wake for one frame only when work is pending.
  reagentcounter:Hide()
  reagentcounter:SetScript("OnEvent", function()
    this.pending = true
    if event ~= "BAG_UPDATE" then
      this.rescan = true
    end
    this:Show()
  end)

  reagentcounter:SetScript("OnUpdate", function()
    if not this.pending then
      this:Hide()
      return
    end

    -- Rebuild the action-slot -> reagent mapping only when the action layout
    -- changes. ClassicAPI resolves the spell/macro directly, so no tooltip
    -- scan or localized reagent-name parsing is required.
    if this.rescan then
      reagent_counts = {}
      for slot = 1, 120 do
        reagentcounter.ScanSlot(slot)
      end
    end

    -- Count only reagents referenced by active actions. ClassicAPI reads the
    -- inventory directly, avoiding a Lua bag scan for every reagent.
    for itemID in pairs(reagent_counts) do
      reagent_counts[itemID] = API.GetItemCount(itemID, false, false) or 0
    end

    -- update all actionbar buttons
    for _, prefix in ipairs(bars) do
      for i = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G[prefix .. "Button" .. i]
        if button then
          local text = _G[button:GetName().."Count"]
          local slot = ActionButton_GetPagedID(button)

          if text then
            local itemID = reagent_slots[slot]
            if itemID then
              text:SetText(reagent_counts[itemID] or 0)
            elseif not IsConsumableAction(slot) then
              text:SetText()
            end
          end
        end
      end
    end

    this.pending = nil
    this.rescan = nil
    this:Hide()
  end)

  reagentcounter.ScanSlot = function(slot)
    reagent_slots[slot] = nil
    if not HasAction(slot) then return end

    local actionType, actionID = API.GetActionInfo(slot)
    local spellID

    if actionType == "spell" then
      spellID = actionID
    elseif actionType == "macro" and actionID then
      local _, _, macroSpellID = API.GetMacroSpell(actionID)
      spellID = macroSpellID
    end

    if not spellID then return end

    local reagents = API.GetSpellReagents(spellID)
    local reagent = reagents and reagents[1]
    if not reagent or not reagent.itemID then return end

    -- The action button only has one count field. Preserve the historical
    -- behavior by showing the first reagent's owned stack count.
    reagent_slots[slot] = reagent.itemID
    reagent_counts[reagent.itemID] = reagent_counts[reagent.itemID] or 0
  end

  -- The stock UI clears the Count fontstring on non-consumable actions whenever
  -- ActionButton_UpdateCount() runs. Re-apply our reagent value afterwards so
  -- login/reload refreshes cannot erase it a moment later.
  ShaguTweaks.hooksecurefunc("ActionButton_UpdateCount", function()
    local button = this
    if not button or not button.GetName then return end

    local slot = ActionButton_GetPagedID(button)
    local itemID = slot and reagent_slots[slot]
    if not itemID then return end

    local text = _G[button:GetName().."Count"]
    if text then
      text:SetText(reagent_counts[itemID] or 0)
    end
  end)
end
