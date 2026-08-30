-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API

local module = ShaguTweaks:register({
  title = T["Movable Unit Frames Extended"],
  description = T["Party frames, minimap, buffs, weapon buffs and debuffs can be moved while Ctrl+Shift are held."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Unit Frames"],
  enabled = nil,
})

module.enable = function(self)
  ShaguTweaks_config = ShaguTweaks_config or {}
  ShaguTweaks_config["MoveUnitframesExtended"] = ShaguTweaks_config["MoveUnitframesExtended"] or {}

  local movedb = ShaguTweaks_config["MoveUnitframesExtended"]
  local unlocked = false
  local states = {}

  -- Turtle WoW places the first debuff at BuffButton32 in the layout this
  -- module targets. BuffButton16 from the original mod is intentionally not
  -- used here.
  local targets = {
    { name = "PartyMemberFrame1" },
    { name = "PartyMemberFrame2" },
    { name = "PartyMemberFrame3" },
    { name = "PartyMemberFrame4" },
    { name = "Minimap", moveParent = true },
    { name = "BuffButton0" },
    { name = "BuffButton32" },
    { name = "TempEnchant1" },
  }

  local function Resolve(target)
    local handle = _G[target.name]
    if not handle then return end

    local move = target.moveParent and handle:GetParent() or handle
    if not move then return end

    return handle, move
  end

  local function PositionKey(target, move)
    return (move.GetName and move:GetName()) or target.name
  end

  local function SavePosition(target)
    local handle, move = Resolve(target)
    if not handle or not move then return end

    local left = move:GetLeft()
    local top = move:GetTop()
    if not left or not top then return end

    movedb[PositionKey(target, move)] = { left, top }
  end

  local function RestorePosition(target)
    local handle, move = Resolve(target)
    if not handle or not move then return end

    local pos = movedb[PositionKey(target, move)]
    if not pos or not pos[1] or not pos[2] then return end

    move:SetMovable(true)
    if move.SetUserPlaced then move:SetUserPlaced(true) end
    move:ClearAllPoints()
    move:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1], pos[2])
  end

  local grid
  local function CreateGrid()
    if grid then return grid end

    grid = CreateFrame("Frame", nil, WorldFrame)
    grid:SetAllPoints(WorldFrame)
    grid:Hide()

    local size = 1
    local width = GetScreenWidth()
    local height = GetScreenHeight()
    local ratio = width / height
    local adjustedHeight = height * ratio
    local wStep = width / 64
    local hStep = adjustedHeight / 64

    for i = 0, 64 do
      local line = grid:CreateTexture(nil, i == 32 and "BORDER" or "BACKGROUND")
      if i == 32 then
        line:SetTexture(.8, .6, 0)
      else
        line:SetTexture(0, 0, 0, .2)
      end
      line:SetPoint("TOPLEFT", grid, "TOPLEFT", i * wStep - (size / 2), 0)
      line:SetPoint("BOTTOMRIGHT", grid, "BOTTOMLEFT", i * wStep + (size / 2), 0)
    end

    local rows = floor(height / hStep)
    for i = 1, rows do
      local middle = floor(rows / 2)
      local line = grid:CreateTexture(nil, i == middle and "BORDER" or "BACKGROUND")
      if i == middle then
        line:SetTexture(.8, .6, 0)
      else
        line:SetTexture(0, 0, 0, .2)
      end
      line:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(i * hStep) + (size / 2))
      line:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(i * hStep + size / 2))
    end

    return grid
  end

  local function UnlockTarget(index, target)
    local handle, move = Resolve(target)
    if not handle or not move then return end

    states[index] = states[index] or {}
    local state = states[index]
    if state.active then return end

    state.active = true
    state.handle = handle
    state.move = move
    state.onDragStart = handle:GetScript("OnDragStart")
    state.onDragStop = handle:GetScript("OnDragStop")
    if handle.IsMouseEnabled then
      state.mouseEnabled = handle:IsMouseEnabled() and true or false
    end

    move:SetMovable(true)
    if move.SetUserPlaced then move:SetUserPlaced(true) end

    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")

    handle:SetScript("OnDragStart", function()
      move:StartMoving()
    end)

    handle:SetScript("OnDragStop", function()
      move:StopMovingOrSizing()
    end)
  end

  local function LockTarget(index, target)
    local state = states[index]
    if not state or not state.active then return end

    local handle = state.handle
    local move = state.move

    if move then move:StopMovingOrSizing() end
    SavePosition(target)

    if handle then
      handle:SetScript("OnDragStart", state.onDragStart)
      handle:SetScript("OnDragStop", state.onDragStop)
      if state.mouseEnabled ~= nil then
        handle:EnableMouse(state.mouseEnabled)
      end
    end

    state.active = false
  end

  local function UnlockAll()
    if unlocked then return end
    unlocked = true

    for i, target in ipairs(targets) do
      UnlockTarget(i, target)
    end

    CreateGrid():Show()
  end

  local function LockAll()
    if not unlocked then return end

    for i, target in ipairs(targets) do
      LockTarget(i, target)
    end

    if grid then grid:Hide() end
    unlocked = false
  end

  local function UpdateLockState()
    local shouldUnlock = API.IsShiftKeyDown() and API.IsControlKeyDown()

    if shouldUnlock then
      UnlockAll()
    else
      LockAll()
    end
  end

  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")

  if API.modifierstate then
    events:RegisterEvent("MODIFIER_STATE_CHANGED")
  end

  events:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
      for _, target in ipairs(targets) do
        RestorePosition(target)
      end
    end

    UpdateLockState()
  end)

  -- ClassicAPI supplies MODIFIER_STATE_CHANGED. Only old/fallback environments
  -- use a throttled state check.
  if not API.modifierstate then
    events.elapsed = 0
    events:SetScript("OnUpdate", function()
      this.elapsed = this.elapsed + (arg1 or 0)
      if this.elapsed < .10 then return end
      this.elapsed = 0
      UpdateLockState()
    end)
  end

  for _, target in ipairs(targets) do
    RestorePosition(target)
  end

  UpdateLockState()
end
