local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Show Aggro Indicators"],
  description = T["Show indicators on raid members that are currently attacked by other units. (This only works if the unit is a target of a raid member)"],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = true,
})


local backdrop = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

-- basic unitstrings
unitstrings = {
  ["pet"] = true, ["player"] = true, ["target"] = true, ["mouseover"] = true
}

-- group and raid units
for i=1,4 do unitstrings["party" .. i] = true end
for i=1,4 do unitstrings["partypet" .. i] = true end
for i=1,40 do unitstrings["raid" .. i] = true end
for i=1,40 do unitstrings["raidpet" .. i] = true end

-- cached aggro detection function
local aggrodata = { }
local function UnitHasAggro(unit)
  if aggrodata[unit] and GetTime() < aggrodata[unit].check + 1 then
    return aggrodata[unit].state
  end

  aggrodata[unit] = aggrodata[unit] or { }
  aggrodata[unit].check = GetTime()
  aggrodata[unit].state = 0

  if UnitExists(unit) and UnitIsFriend(unit, "player") then
    for u in pairs(unitstrings) do
      local t = u .. "target"
      local tt = t .. "target"

      if UnitExists(t) and UnitIsUnit(t, unit) and UnitCanAttack(u, unit) then
        aggrodata[unit].state = aggrodata[unit].state + 1
      end

      if UnitExists(tt) and UnitIsUnit(tt, unit) and UnitCanAttack(t, unit) then
        aggrodata[unit].state = aggrodata[unit].state + 1
      end
    end
  end

  return aggrodata[unit].state
end

module.enable = function(self)
  ShaguTweaks.UnitFrame_NewComponent('aggro indicator', {
    events = {
      'FRAME_TICK_250',
    },

    create = function(frame)
      -- create aggro icon
      frame.aggro = CreateFrame("Frame", nil, frame.bar)
      frame.aggro:SetPoint("TOPRIGHT", frame.bar, "TOPRIGHT", 0, 0)

      frame.aggro:SetWidth(12)
      frame.aggro:SetHeight(10)
      frame.aggro:SetBackdrop(backdrop)
      ShaguTweaks.DarkenFrame(frame.aggro)

      frame.aggro.tex = frame.aggro:CreateTexture(nil, 'BACKGROUND')
      frame.aggro.tex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
      frame.aggro.tex:SetVertexColor(1, 0, 0, 1)
      frame.aggro.tex:SetPoint("TOPLEFT", frame.aggro, "TOPLEFT", 2, -2)
      frame.aggro.tex:SetPoint("BOTTOMRIGHT", frame.aggro, "BOTTOMRIGHT", -2, 2)
    end,

    update = function(frame, event)
      if not event then return end

      if UnitHasAggro(frame.unitstr) > 0 then
        frame.aggro:Show()
      else
        frame.aggro:Hide()
      end
    end
  })
end
