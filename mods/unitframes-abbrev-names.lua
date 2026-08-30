-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API

local module = ShaguTweaks:register({
  title = T["Unit Frame Abbreviated Names"],
  description = T["Abbreviates long target and target-of-target names."],
  expansions = { ["vanilla"] = true, ["tbc"] = nil },
  category = T["Unit Frames"],
  enabled = nil,
})

module.enable = function(self)
  local maxLength = 15

  local function AbbrevWord(word)
    return string.sub(word, 1, 1) .. ". "
  end

  local function GetShortName(unit)
    local name = UnitName(unit)
    if not name then return end

    if strlen(name) > maxLength then
      name = string.gsub(name, "^(%S+) ", AbbrevWord)
    end

    if strlen(name) > maxLength then
      name = string.gsub(name, "(%S+) ", AbbrevWord)
    end

    return name
  end

  local function GetNameText(frame)
    if not frame then return end
    if frame.name then return frame.name end
    if frame.GetName and frame:GetName() then
      return _G[frame:GetName() .. "Name"]
    end
  end

  local function UpdateFrame(frame, unit)
    local text = GetNameText(frame)
    local name = GetShortName(unit)
    if text and name then text:SetText(name) end
  end

  local function UpdateTarget()
    UpdateFrame(TargetFrame, "target")
  end

  local function UpdateTargetTarget()
    if TargetofTargetFrame then
      UpdateFrame(TargetofTargetFrame, "targettarget")
    end
  end

  local function EventValid(name)
    return API.eventutils
      and _G.C_EventUtils
      and _G.C_EventUtils.IsEventValid
      and _G.C_EventUtils.IsEventValid(name)
  end

  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("PLAYER_TARGET_CHANGED")

  local hasUnitTarget = EventValid("UNIT_TARGET")
  local hasUnitName = EventValid("UNIT_NAME_UPDATE")

  if hasUnitTarget then events:RegisterEvent("UNIT_TARGET") end
  if hasUnitName then events:RegisterEvent("UNIT_NAME_UPDATE") end

  events:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
      UpdateTarget()
      UpdateTargetTarget()
    elseif event == "UNIT_TARGET" then
      if arg1 == "target" then UpdateTargetTarget() end
    elseif event == "UNIT_NAME_UPDATE" then
      if arg1 == "target" then
        UpdateTarget()
      elseif arg1 == "targettarget" then
        UpdateTargetTarget()
      end
    end
  end)

  -- ClassicAPI normally provides UNIT_TARGET. Keep a lightweight Vanilla
  -- fallback only when that event isn't available instead of running every
  -- rendered frame like the original module.
  if not hasUnitTarget then
    local fallback = CreateFrame("Frame")
    fallback.elapsed = 0
    fallback:SetScript("OnUpdate", function()
      this.elapsed = this.elapsed + (arg1 or 0)
      if this.elapsed < .25 then return end
      this.elapsed = 0
      if UnitName("target") then UpdateTargetTarget() end
    end)
  end

  UpdateTarget()
  UpdateTargetTarget()
end
