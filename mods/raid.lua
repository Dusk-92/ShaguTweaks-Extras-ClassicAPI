local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local rgbhex = ShaguTweaks.rgbhex

local module = ShaguTweaks:register({
  title = T["Enable Raid Frames"],
  description = T["Very simple raid frames with only the most basic features."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Raid Frames"],
  maintainer = "@shagu (GitHub)",
  enabled = true,
  config = {
    ["raid.width"] = 64,
    ["raid.height"] = 32,
    ["raid.rows"] = 10,
    ["raid.scale"] = 1,
  }
})

local components = {}

local backdrop = {
  border = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  },
  background = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  }
}

-- Helper Functions
local GetFramePosition = function(i, rows)
  local left = math.ceil(i/rows)

  local top = math.mod(i, rows)
  top = top == 0 and rows or top

  return left, top
end

local UnitInRange = function(unitstr)
  if SUPERWOW_VERSION then
    -- 40y range check
    local x1, y1, z1 = UnitPosition("player")
    local x2, y2, z2 = UnitPosition(this.unitstr)

    -- only continue if we got position values
    if x1 and y1 and z1 and x2 and y2 and z2 then
      local distance = ((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)^.5
      if distance < 40 then return true end
    end
  else
    -- 28y range check
    if CheckInteractDistance(this.unitstr, 4) then return true end
  end

  return false
end

-- Unit Frames
local UnitFrame_NewComponent = function(name, object)
  object.name = name
  table.insert(components, object)
end

local UnitFrame_OnEnter = function()
  if not this.unitstr then return end

  GameTooltip_SetDefaultAnchor(GameTooltip, this)
  GameTooltip:SetUnit(this.unitstr)
  GameTooltip:Show()
end

local UnitFrame_OnLeave = function()
  if not this.unitstr then return end

  GameTooltip:Hide()
end

local UnitFrame_OnUpdate = function()
  -- abort on invalid unit frames
  if not this.unitstr or not UnitName(this.unitstr) then
    this:Hide()
    return
  end

  -- run update functions of all components
  for component in pairs(this.update) do
    component.update(this)
  end

  -- run 250ms tick pseudo events
  this.tick250 = this.tick250 or 0
  if this.events['FRAME_TICK_250'] and this.tick250 < GetTime() then
    -- set next tick time
    this.tick250 = GetTime() + .250

    -- run update functions for each frame
    for id, component in pairs(this.events['FRAME_TICK_250']) do
      component.update(this, 'FRAME_TICK_250')
    end
  end
end

local UnitFrame_OnClick = function()
  if not this.unitstr then return end
  local button = arg1

  -- handle special cases
  if SpellIsTargeting() then
    if button == "LeftButton" then
      SpellTargetUnit(this.unitstr)
      return
    elseif button == "RightButton" then
      SpellStopTargeting()
      return
    end
  elseif CursorHasItem() then
    DropItemOnUnit(this.unitstr)
    return
  end

  -- hide previous menus
  HideDropDownMenu(1)

  -- default click actions
  if button == "LeftButton" then
    TargetUnit(this.unitstr)
  elseif button == "RightButton" then
    local unitstr = this.unitstr
    local name = UnitName(this.unitstr)
    FriendsDropDown.displayMode = "MENU"
    FriendsDropDown.initialize = function()
      UnitPopup_ShowMenu(_G[UIDROPDOWNMENU_OPEN_MENU], "PARTY", unitstr, name)
    end
    ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
  end
end

local UnitFrame_OnEvent = function()
  -- break on empty units or empty events
  if not this.unitstr then return end
  if not this.events[event] then return end

  -- run update functions for each frame
  for id, component in pairs(this.events[event]) do
    component.update(this, event)
  end
end

local CreateUnitFrame = function(parent, i)
  local frame = parent.frames[i] or CreateFrame("Button", "ShaguTweaksRaidUnitFrame"..i, parent)
  local left, top = GetFramePosition(i, parent.config["raid.rows"])

  frame:SetPoint("TOPLEFT", (left-1)*(parent.config["raid.width"]+2) + 4, -(top-1)*(parent.config["raid.height"] + 1) - 4)
  frame:SetWidth(parent.config["raid.width"])
  frame:SetHeight(parent.config["raid.height"])

  frame.unitstr = "raid"..i
  frame.left = left
  frame.top = top
  frame.events = {
    ['RAID_ROSTER_UPDATE'] = { },
    ['PARTY_MEMBERS_CHANGED'] = { },
    ['PLAYER_ENTERING_WORLD'] = { },
  }

  frame.update = {}

  -- assign required events and scripts
  frame:SetScript("OnEvent", UnitFrame_OnEvent)
  frame:SetScript("OnClick", UnitFrame_OnClick)
  frame:SetScript("OnEnter", UnitFrame_OnEnter)
  frame:SetScript("OnLeave", UnitFrame_OnLeave)
  frame:SetScript("OnUpdate", UnitFrame_OnUpdate)
  frame:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

  -- base events
  frame:RegisterEvent("RAID_ROSTER_UPDATE")
  frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")

  for id, object in pairs(components) do
    -- create component frames
    object.create(frame)

    -- register component update events
    for _, event in pairs(object.events) do
      frame:RegisterEvent(event)
      frame.events[event] = frame.events[event] or {}
      table.insert(frame.events[event], object)
    end

    -- register components to base events
    table.insert(frame.events['RAID_ROSTER_UPDATE'], object)
    table.insert(frame.events['PARTY_MEMBERS_CHANGED'], object)
    table.insert(frame.events['PLAYER_ENTERING_WORLD'], object)

    -- register update function
    frame.update[object] = true
  end

  -- save frame to parent
  parent.frames[i] = frame
end

-- Components
UnitFrame_NewComponent('health', {
  events = {
    'UNIT_HEALTH',
    'UNIT_MAXHEALTH',
  },

  create = function(frame)
    -- create health bar
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(1, .8, .2, 1)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetTexture(0, 0, 0, 1)
    bar.bg:SetAllPoints()
    frame.bar = bar
  end,

  update = function(frame, event)
    -- ignore empty or unrelated events
    if not event then return end
    if arg1 and this.unitstr ~= arg1 then return end

    -- update statusbar values
    frame.bar:SetMinMaxValues(0, UnitHealthMax(frame.unitstr))
    frame.bar:SetValue(UnitHealth(frame.unitstr))

    -- update health bar color
    local r, g, b = .8, .8, .8
    local _, class = UnitClass(frame.unitstr)
    if class and RAID_CLASS_COLORS[class] then
      r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
    end
    frame.bar:SetStatusBarColor(r, g, b, a)
  end
})

UnitFrame_NewComponent('mana', {
  events = {
    'UNIT_MANA',
    'UNIT_MAXMANA',
    'UNIT_ENERGY',
    'UNIT_MAXENERGY',
    'UNIT_RAGE',
    'UNIT_MAXRAGE',
    'UNIT_DISPLAYPOWER',
  },

  create = function(frame)
    -- create mana bar
    local height = frame:GetHeight()
    frame.mana = CreateFrame("StatusBar", nil, frame.bar)
    frame.mana:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.mana:SetStatusBarColor(.2, .2, 1, 1)
    frame.mana:SetPoint("TOPLEFT", 0, -height+5)
    frame.mana:SetPoint("BOTTOMRIGHT", 0, 0)

    frame.mana.bg = frame.mana:CreateTexture(nil, "BACKGROUND")
    frame.mana.bg:SetTexture(0, 0, 0, 1)
    frame.mana.bg:SetAllPoints()
  end,

  update = function(frame, event)
    -- ignore empty or unrelated events
    if not event then return end
    if arg1 and this.unitstr ~= arg1 then return end

    -- update mana bar values
    frame.mana:SetMinMaxValues(0, UnitManaMax(frame.unitstr))
    frame.mana:SetValue(UnitMana(frame.unitstr))

    -- update mana bar colors
    local color = ManaBarColor[UnitPowerType(frame.unitstr)]
    frame.mana:SetStatusBarColor(color.r, color.g, color.b, 1)
  end
})

UnitFrame_NewComponent('text', {
  events = { },

  create = function(frame)
    -- create caption text
    local text = frame.mana:CreateFontString(nil, "HIGH", "GameFontWhite")
    text:SetAllPoints(frame.bar)
    text:SetFont(UNIT_NAME_FONT, 8, "THINOUTLINE")
    text:SetJustifyH("CENTER")
    frame.text = text
  end,

  update = function(frame, event)
    -- update caption text
    local name = UnitName(frame.unitstr) or ""
    local info = frame.info and "\n"..frame.info or ""
    frame.text:SetText(name .. info)
    frame.info = nil

    -- update info states
    if not UnitIsConnected(frame.unitstr) then
      frame.info = "|cffaaaaaaOffline|r"
    end

    if UnitIsDead(frame.unitstr) then
      frame.info = "|cffaaaaaaDead|r"
    end

    if UnitIsDeadOrGhost(frame.unitstr) and UnitHealth(frame.unitstr) == 1 then
      frame.info = "|cffaaaaaaGhost|r"
    end
  end
})

UnitFrame_NewComponent('border', {
  events = { },

  create = function(frame)
    -- create border
    local border = CreateFrame("Frame", nil, frame)
    border:SetBackdrop(backdrop.border)
    border:SetBackdropBorderColor(.8, .8, .8, 1)
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", -2,2)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2,-2)
    border:SetFrameLevel(32)
    ShaguTweaks.DarkenFrame(border)
    frame.border = border
  end,

  update = function(frame, event)
  end
})

UnitFrame_NewComponent('highlight', {
  events = {
    'FRAME_TICK_250',
   },

  create = function(frame)
    -- create highlight border
    local highlight = CreateFrame("Frame", nil, frame)
    highlight:SetFrameLevel(128)
    highlight:SetBackdrop(backdrop.border)
    highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", -1.5,1.5)
    highlight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1.5,-1.5)
    frame.highlight = highlight
  end,

  update = function(frame, event)
    if not event then return end

    -- update health bar border
    if UnitAffectingCombat(frame.unitstr) then
      frame.highlight:SetBackdropBorderColor(.9, .1, .1, .5)
      frame.highlight:Show()
    else
      frame.highlight:Hide()
    end
  end
})

UnitFrame_NewComponent('target', {
  events = {
    "PLAYER_TARGET_CHANGED",
   },

  create = function(frame)
    -- create target marker
    local target = CreateFrame("Frame", nil, frame.bar)
    target:SetAllPoints()

    local left = target:CreateTexture(nil, 'OVERLAY')
    left:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    left:SetPoint("LEFT", target, "LEFT", 0, 0)
    left:SetTexCoord(.3, .7, .3, .7)
    left:SetDesaturated(true)
    left:SetWidth(8)
    left:SetHeight(8)
    left:SetBlendMode('ADD')

    local right = target:CreateTexture(nil, 'OVERLAY')
    right:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    right:SetPoint("RIGHT", target, "RIGHT", 1, 0)
    right:SetTexCoord(.3, .7, .3, .7)
    right:SetDesaturated(true)
    right:SetWidth(8)
    right:SetHeight(8)
    right:SetBlendMode('ADD')

    frame.target = target
  end,

  update = function(frame, event)
    if not event then return end

    -- update health bar border
    if UnitIsUnit("target", frame.unitstr) then
      frame.target:Show()
      frame.target:SetAlpha(1)
    else
      frame.target:Hide()
    end
  end
})

UnitFrame_NewComponent('icon', {
  events = {
    "RAID_TARGET_UPDATE",
  },

  create = function(frame)
    -- create raid icon textures
    frame.icon = frame.mana:CreateTexture(nil, "NORMAL")
    frame.icon:SetWidth(12)
    frame.icon:SetHeight(12)
    frame.icon:SetPoint("BOTTOM", frame, "BOTTOM", 0, 1)
    frame.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    frame.icon:Hide()
  end,

  update = function(frame, event)
    if not event then return end

    -- show raid icon if existing
    if UnitName(frame.unitstr) and GetRaidTargetIndex(frame.unitstr) then
      SetRaidTargetIconTexture(frame.icon, GetRaidTargetIndex(frame.unitstr))
      frame.icon:Show()
    else
      frame.icon:Hide()
    end
  end
})

UnitFrame_NewComponent('range', {
  events = {
    'FRAME_TICK_250',
  },

  create = function(frame)
    -- noop
  end,

  update = function(frame, event)
    if not event then return end

    -- range indicator
    if UnitInRange(frame.unitstr) then
      frame:SetAlpha(1)
    else
      frame:SetAlpha(.25)
    end
  end
})

ShaguTweaks.UnitFrame_NewComponent = UnitFrame_NewComponent

-- Bring everything to life
module.enable = function(self)
  local raid = CreateFrame("Frame", "ShaguTweaksRaidFrame", UIParent)
  raid:RegisterEvent("RAID_ROSTER_UPDATE")
  raid:RegisterEvent("PLAYER_ENTERING_WORLD")
  raid:SetScript("OnEvent", function()
    -- create all raid frames
    if not raid.cluster.frames then
      raid.cluster.frames = {}
      for id = 1, 40 do CreateUnitFrame(raid.cluster, id) end
    end

    -- check for raid and setup frames
    if UnitInRaid("player") then
      for index = 1, 40 do
        this.cluster.frames[index].unitstr = nil
        this.cluster.frames[index]:Hide()
      end

      -- initialize raid frame
      local x, y = 0, 0
      for group = 1, 8 do
        if RAID_SUBGROUP_LISTS and RAID_SUBGROUP_LISTS[group] then
          for id, unit in pairs(RAID_SUBGROUP_LISTS[group]) do
            -- assign proper unitstrs to frames
            local index = (group - 1) * 5 + id
            local frame = this.cluster.frames[index]
            frame.unitstr = 'raid' .. unit
            frame.groupid = group
            frame:Show()

            -- save required raid frame size
            x = math.max(x, frame.left)
            y = math.max(y, frame.top)
          end
        end
      end

      -- set raid frame size
      raid.cluster:SetWidth(x * (raid.cluster.config["raid.width"]+2) + 6)
      raid.cluster:SetHeight(y * (raid.cluster.config["raid.height"]+1) + 7)
      raid:Show()
    else
      raid:Hide()
    end
  end)

  -- assign defaul scale
  raid:SetScale(module.config["raid.scale"])

  do -- toggle button
    -- create toggle button
    raid.toggle = CreateFrame("Button", "ShaguTweaksRaidToggle", raid)
    raid.toggle:SetPoint("LEFT", UIParent, "LEFT", -8, 64)
    raid.toggle:SetWidth(16)
    raid.toggle:SetHeight(64)
    raid.toggle:SetBackdrop(backdrop.background)
    raid.toggle:SetBackdropColor(.2,.2,.2,1)
    raid.toggle:SetBackdropBorderColor(.8,.8,.8,1)
    ShaguTweaks.DarkenFrame(raid.toggle)

    -- make button movable
    raid.toggle:EnableMouse(true)
    raid.toggle:SetMovable(true)
    raid.toggle:SetUserPlaced(true)

    raid.toggle:SetScript("OnEnter", function()
      GameTooltip_SetDefaultAnchor(GameTooltip, this)
      GameTooltip:ClearLines()
      GameTooltip:AddLine(T["Raid Frames"], 1, 1, 1)
      GameTooltip:AddDoubleLine(T["Click"], T["Toggle Raid Frames"])
      GameTooltip:AddDoubleLine(T["Shift-Drag"], T["Move Raid Frames"])
      GameTooltip:Show()
    end)

    raid.toggle:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    -- show icon on toggle button
    raid.toggle.icon = raid.toggle:CreateTexture(nil, 'OVERLAY')
    raid.toggle.icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    raid.toggle.icon:SetPoint("CENTER", raid.toggle, "CENTER", 2, 0)
    raid.toggle.icon:SetTexCoord(.3, .7, .3, .7)
    raid.toggle.icon:SetWidth(8)
    raid.toggle.icon:SetHeight(8)
    raid.toggle.icon:SetBlendMode('ADD')

    -- texture mouse hover effect
    raid.toggle:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    local pushed = raid.toggle:GetHighlightTexture()
    pushed:ClearAllPoints()
    pushed:SetPoint("CENTER", raid.toggle, "CENTER", 0, -2)
    pushed:SetWidth(20)
    pushed:SetHeight(110)
    pushed:SetAlpha(.5)

    raid.toggle:SetScript("OnMouseDown", function()
      if IsShiftKeyDown() then
        this.dragging = true

        local px, py = GetCursorPosition()
        local scale = this:GetEffectiveScale()
        px, py = px / scale, py / scale
        raid.toggle:ClearAllPoints()
        raid.toggle:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -8, py-32)
      else
        if raid.cluster:IsShown() then
          raid.toggle.icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
          raid.cluster:Hide()
        else
          raid.toggle.icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
          raid.cluster:Show()
        end
      end
    end)

    raid.toggle:SetScript("OnMouseUp", function()
      this.dragging = false
    end)

    raid.toggle:SetScript("OnUpdate", function()
      if not this.dragging then return end

      local px, py = GetCursorPosition()
      local scale = this:GetEffectiveScale()
      px, py = px / scale, py / scale
      raid.toggle:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -8, py-32)
    end)
  end

  do -- cluster
    -- create raid cluster
    raid.cluster = CreateFrame("Frame", "ShaguTweaksRaidCluster", raid)
    raid.cluster:SetBackdrop(backdrop.background)
    raid.cluster:SetBackdropColor(.2,.2,.2,1)
    raid.cluster:SetBackdropBorderColor(.8,.8,.8,1)
    raid.cluster:SetPoint("LEFT", raid.toggle, "RIGHT", -2, 0)
    raid.cluster:SetClampedToScreen(true)
    ShaguTweaks.DarkenFrame(raid.cluster)

    -- assign default config
    raid.cluster.config = module.config
  end
end
