local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local libtipscan = ShaguTweaks.libtipscan
local GetItemCount = ShaguTweaks.GetItemCount

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
  local reagent_capture = SPELL_REAGENTS.."(.+)"
  local bars = { "Action", "BonusAction", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight" }
  local scanner = libtipscan:GetScanner("reagents")

  local reagentcounter = CreateFrame("Frame", "ShaguTweaksReagentCount", UIParent)
  reagentcounter:RegisterEvent("PLAYER_ENTERING_WORLD")
  reagentcounter:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  reagentcounter:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
  reagentcounter:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
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

    -- Tooltip scans are only required when the action layout changed.
    if this.rescan then
      -- Rebuild the active reagent set so items no longer referenced by any
      -- action slot stop being counted after actionbar changes.
      reagent_counts = {}
      for slot = 1, 120 do
        reagentcounter.ScanSlot(slot)
      end
    end

    -- Bag changes only need fresh counts for reagents already discovered.
    for item in pairs(reagent_counts) do
      reagent_counts[item] = GetItemCount(item)
    end

    -- update all actionbar buttons
    for _, prefix in ipairs(bars) do
      for i = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G[prefix .. "Button" .. i]
        if button then
          local text = _G[button:GetName().."Count"]
          local slot = ActionButton_GetPagedID(button)

          if text then
            if reagent_slots[slot] then
              text:SetText(reagent_counts[reagent_slots[slot]])
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
    -- update buttons that previously had an reagent
    if reagent_slots[slot] and not HasAction(slot) then
      reagent_slots[slot] = nil
    end

    -- search for reagent requirements
    if HasAction(slot) then
      scanner:SetAction(slot)
      local _, reagents = scanner:Find(reagent_capture)
      -- remove reagent counts if existing
      reagents = reagents and string.gsub(reagents, " %((.+)%)", "")

      if reagents then
        reagent_counts[reagents] = reagent_counts[reagents] or 0
        reagent_slots[slot] = reagents
      else
        -- The slot can stay occupied while changing from a reagent spell to a
        -- normal action; clear the previous reagent instead of leaving a stale
        -- counter on the button.
        reagent_slots[slot] = nil
      end
    end
  end
end
