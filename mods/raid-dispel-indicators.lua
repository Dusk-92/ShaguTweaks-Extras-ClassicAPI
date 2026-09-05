local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Show Dispel Indicators"],
  description = T["Show indicators for units affected by curse, magic, poison or diseases based on your class."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = true,
})

local debuffs = {
  ["Magic"]   = { 0, 1, 1, 1 },
  ["Poison"]  = { 0, 1, 0, 1 },
  ["Curse"]   = { 1, 0, 1, 1 },
  ["Disease"] = { 1, 1, 0, 1 },
}

local backdrop = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

module.enable = function(self)
  -- show only class specific debuffs
  local _, class = UnitClass("player")
  debuffs["Magic"] = (class == "PALADIN" or class == "PRIEST" or class == "WARLOCK") and debuffs["Magic"] or nil
  debuffs["Poison"] = (class == "DRUID" or class == "PALADIN" or class == "SHAMAN") and debuffs["Poison"] or nil
  debuffs["Disease"] = (class == "PRIEST" or class == "PALADIN" or class == "SHAMAN") and debuffs["Disease"] or nil
  debuffs["Curse"] = (class == "DRUID" or class == "MAGE") and debuffs["Curse"] or nil

  ShaguTweaks.UnitFrame_NewComponent('dispel indicator', {
    events = {
      'UNIT_AURA',
      'UNIT_AURASTATE',
    },

    create = function(frame)
      -- create dispel icons
      frame.dispel = CreateFrame("Frame", nil, frame.bar)
      frame.dispel:SetFrameLevel(160)
      frame.dispel:SetAllPoints()

      for dtype, color in pairs(debuffs) do
        frame.dispel[dtype] = CreateFrame("Frame", nil, frame.dispel)
        frame.dispel[dtype]:SetWidth(12)
        frame.dispel[dtype]:SetHeight(10)
        frame.dispel[dtype]:SetBackdrop(backdrop)
        ShaguTweaks.DarkenFrame(frame.dispel[dtype])

        frame.dispel[dtype].tex = frame.dispel[dtype]:CreateTexture(nil, 'BACKGROUND')
        frame.dispel[dtype].tex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
        frame.dispel[dtype].tex:SetVertexColor(unpack(color))
        frame.dispel[dtype].tex:SetPoint("TOPLEFT", frame.dispel[dtype], "TOPLEFT", 2, -2)
        frame.dispel[dtype].tex:SetPoint("BOTTOMRIGHT", frame.dispel[dtype], "BOTTOMRIGHT", -2, 2)
      end
    end,

    update = function(frame, event)
      -- ignore empty or unrelated events
      if not event then return end
      if arg1 and this.unitstr ~= arg1 then return end

      -- affected debuffs
      frame.affected = frame.affected or {}
      for dtype in pairs(debuffs) do frame.affected[dtype] = nil end

      for i = 1, 16 do
        local _, _, dtype = UnitDebuff(frame.unitstr, i)
        if dtype then frame.affected[dtype] = true end
      end

      local id = 0
      for dtype in pairs(debuffs) do
        if frame.affected[dtype] then
          frame.dispel[dtype]:Show()
          frame.dispel[dtype]:SetPoint("TOPLEFT", frame.dispel, "TOPLEFT", id * 12, 0)

          id = id + 1
          frame.dispel:SetWidth(id*(12) + 6)
        else
          frame.dispel[dtype]:Hide()
        end
      end
    end
  })
end
