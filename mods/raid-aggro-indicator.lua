local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API

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

-- Prebuild the unit/target token chains once. The old implementation rebuilt
-- these strings while scanning every raid frame, every second.
local observers = {}
local function AddObserver(unit)
  table.insert(observers, {
    unit,
    unit .. "target",
    unit .. "targettarget",
  })
end

AddObserver("pet")
AddObserver("player")
AddObserver("target")
AddObserver("mouseover")
for i=1,4 do AddObserver("party" .. i) end
for i=1,4 do AddObserver("partypet" .. i) end
for i=1,40 do AddObserver("raid" .. i) end
for i=1,40 do AddObserver("raidpet" .. i) end

-- Build one shared aggro snapshot per second. ClassicAPI's UnitGUID supports
-- chained target tokens, so the same target/target-of-target heuristic can be
-- evaluated once for all raid frames instead of rescanning every observer for
-- each displayed unit.
local aggrodata = {}
local nextAggroUpdate = 0

local function AddAggro(guid)
  if not guid then return end
  aggrodata[guid] = (aggrodata[guid] or 0) + 1
end

local function RefreshAggroData()
  local now = GetTime()
  if now < nextAggroUpdate then return end
  nextAggroUpdate = now + 1

  for guid in pairs(aggrodata) do
    aggrodata[guid] = nil
  end

  for _, observer in ipairs(observers) do
    local source = observer[1]
    local target = observer[2]
    local targettarget = observer[3]

    local guid = API.UnitGUID(target)
    if guid and UnitCanAttack(source, target) then
      AddAggro(guid)
    end

    guid = API.UnitGUID(targettarget)
    if guid and UnitCanAttack(target, targettarget) then
      AddAggro(guid)
    end
  end
end

local function UnitHasAggro(unit)
  if not UnitExists(unit) or not UnitIsFriend(unit, "player") then
    return 0
  end

  RefreshAggroData()

  local guid = API.UnitGUID(unit)
  return guid and (aggrodata[guid] or 0) or 0
end

module.enable = function(self)
  -- Extras is ClassicAPI-first. Without UnitGUID the optimized shared
  -- snapshot cannot preserve unit identity safely, so do not fall back to the
  -- old O(raid * observers) scanner.
  if not API.unitguid then return end

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
      frame.aggro:Hide()
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
