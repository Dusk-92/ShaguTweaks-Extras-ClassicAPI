local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API

local selfcastTitle = T["Alt Self-Cast"]

local selfcast = ShaguTweaks:register({
  title = selfcastTitle,
  description = T["When Key-Down Casting is enabled, hold Alt to cast eligible actions on yourself."],
  expansions = { ["vanilla"] = true },
  category = T["Action Bar"],
  enabled = nil,
})

selfcast.enable = function(self)
  -- Runtime behavior is handled by Key-Down Casting below.
end

local module = ShaguTweaks:register({
  title = T["Key-Down Casting"],
  description = T["Activates action-bar and pet actions when the key is pressed instead of when it is released."],
  expansions = { ["vanilla"] = true },
  category = T["Action Bar"],
  enabled = true,
})

module.enable = function(self)
  -- Keep this feature independent from No Toggle Auto-Attack.
  if IsAddOnLoaded("ClassicSnowFall") or IsAddOnLoaded("ClassicSnowfall") then return end

  local function SelfCast()
    if ShaguTweaks_config and ShaguTweaks_config[selfcastTitle] == 1 then
      return API.IsAltKeyDown() and 1 or 0
    end
    return 0
  end

  -- Preserve the original slash command while using a unique registry key.
  SLASH_STCLASSICSNOWFALLSELFCAST1 = "/csselfcast"
  SlashCmdList["STCLASSICSNOWFALLSELFCAST"] = function()
    ShaguTweaks_config = ShaguTweaks_config or {}
    if ShaguTweaks_config[selfcastTitle] == 1 then
      ShaguTweaks_config[selfcastTitle] = 0
      DEFAULT_CHAT_FRAME:AddMessage("Classic Snowfall ALT SelfCast now disabled.")
    else
      ShaguTweaks_config[selfcastTitle] = 1
      DEFAULT_CHAT_FRAME:AddMessage("Classic Snowfall ALT SelfCast now enabled.")
    end
  end

  local function IsBongosReady()
    return _G.BActionButton and type(_G.BActionButton.GetPagedID) == "function"
  end

  local function ST_ActionButtonDown(id)
    local button, pagedID

    if IsBongosReady() then
      button = _G["BActionButton" .. id]
      pagedID = _G.BActionButton.GetPagedID(id)
      if button and button:GetButtonState() == "NORMAL" then
        button:SetButtonState("PUSHED")
      end
      if pagedID then UseAction(pagedID, 0, SelfCast()) end
      return
    end

    if BonusActionBarFrame and BonusActionBarFrame:IsShown() then
      button = _G["BonusActionButton" .. id]
    else
      button = _G["ActionButton" .. id]
    end

    if button and button:GetButtonState() == "NORMAL" then
      button:SetButtonState("PUSHED")
      UseAction(ActionButton_GetPagedID(button), 0, SelfCast())
    end
  end

  local function ST_ActionButtonUp(id)
    local button, pagedID

    if IsBongosReady() then
      button = _G["BActionButton" .. id]
      pagedID = _G.BActionButton.GetPagedID(id)
      if button and button:GetButtonState() == "PUSHED" then
        button:SetButtonState("NORMAL")
        if MacroFrame_SaveMacro then MacroFrame_SaveMacro() end
        if pagedID and IsCurrentAction(pagedID) then
          button:SetChecked(1)
        else
          button:SetChecked(0)
        end
      end
      return
    end

    if BonusActionBarFrame and BonusActionBarFrame:IsShown() then
      button = _G["BonusActionButton" .. id]
    else
      button = _G["ActionButton" .. id]
    end

    if button and button:GetButtonState() == "PUSHED" then
      button:SetButtonState("NORMAL")
      if MacroFrame_SaveMacro then MacroFrame_SaveMacro() end
      if IsCurrentAction(ActionButton_GetPagedID(button)) then
        button:SetChecked(1)
      else
        button:SetChecked(0)
      end
    end
  end

  local function ST_MultiActionButtonDown(bar, id)
    local button = _G[bar .. "Button" .. id]
    if button and button:GetButtonState() == "NORMAL" then
      button:SetButtonState("PUSHED")
      UseAction(ActionButton_GetPagedID(button), 0, SelfCast())
    end
  end

  local function ST_MultiActionButtonUp(bar, id)
    local button = _G[bar .. "Button" .. id]
    if button and button:GetButtonState() == "PUSHED" then
      button:SetButtonState("NORMAL")
      if MacroFrame_SaveMacro then MacroFrame_SaveMacro() end
      if IsCurrentAction(ActionButton_GetPagedID(button)) then
        button:SetChecked(1)
      else
        button:SetChecked(0)
      end
    end
  end

  local function ST_PetActionButtonDown(id)
    local button = _G["PetActionButton" .. id]
    if button and button:GetButtonState() == "NORMAL" then
      button:SetButtonState("PUSHED")
      CastPetAction(id)
    end
  end

  local function ST_PetActionButtonUp(id)
    local button = _G["PetActionButton" .. id]
    if button and button:GetButtonState() == "PUSHED" then
      button:SetButtonState("NORMAL")
    end
  end

  -- Vanilla's BONUSACTIONBUTTON bindings are aliases for the pet-action
  -- handlers. Keep the same relationship while moving the cast to key-down.
  local function ST_BonusActionButtonDown(id)
    ST_PetActionButtonDown(id)
  end

  local function ST_BonusActionButtonUp(id)
    ST_PetActionButtonUp(id)
  end

  local function Install()
    _G.ActionButtonDown = ST_ActionButtonDown
    _G.ActionButtonUp = ST_ActionButtonUp
    _G.MultiActionButtonDown = ST_MultiActionButtonDown
    _G.MultiActionButtonUp = ST_MultiActionButtonUp
    _G.PetActionButtonDown = ST_PetActionButtonDown
    _G.PetActionButtonUp = ST_PetActionButtonUp

    if type(_G.BonusActionButtonDown) == "function" then
      _G.BonusActionButtonDown = ST_BonusActionButtonDown
    end
    if type(_G.BonusActionButtonUp) == "function" then
      _G.BonusActionButtonUp = ST_BonusActionButtonUp
    end
  end

  local function HandlersAreInstalled()
    return _G.ActionButtonDown == ST_ActionButtonDown
      and _G.ActionButtonUp == ST_ActionButtonUp
      and _G.MultiActionButtonDown == ST_MultiActionButtonDown
      and _G.MultiActionButtonUp == ST_MultiActionButtonUp
      and _G.PetActionButtonDown == ST_PetActionButtonDown
      and _G.PetActionButtonUp == ST_PetActionButtonUp
  end

  -- Modified bindings (SHIFT-*, CTRL-*, ALT-*) are routed through ClassicAPI's
  -- normalized override-binding layer. Vanilla's runOnUp binding path is not
  -- reliable for every modified-key combination on custom 1.12 clients.
  -- Normal unmodified keys continue through the original ClassicSnowfall-style
  -- global handlers above.
  local bindingOwner = CreateFrame("Frame", "ShaguTweaksKeyDownBindingOwner", UIParent)
  local proxies = {}
  local specs = {}

  local function AddSpec(command, kind, a, b)
    table.insert(specs, { command = command, kind = kind, a = a, b = b })
  end

  for i = 1, 12 do
    AddSpec("ACTIONBUTTON" .. i, "action", i)
    AddSpec("MULTIACTIONBAR1BUTTON" .. i, "multi", "MultiBarBottomLeft", i)
    AddSpec("MULTIACTIONBAR2BUTTON" .. i, "multi", "MultiBarBottomRight", i)
    AddSpec("MULTIACTIONBAR3BUTTON" .. i, "multi", "MultiBarRight", i)
    AddSpec("MULTIACTIONBAR4BUTTON" .. i, "multi", "MultiBarLeft", i)
    AddSpec("BONUSACTIONBUTTON" .. i, "bonus", i)
  end

  local function IsModifiedKey(key)
    if type(key) ~= "string" then return false end
    local upper = string.upper(key)
    return string.find(upper, "SHIFT-", 1, true)
      or string.find(upper, "CTRL-", 1, true)
      or string.find(upper, "ALT-", 1, true)
  end

  local function GetProxy(spec, index)
    local name = "ShaguTweaksKeyDownProxy" .. index
    if proxies[index] then return proxies[index] end

    local button = CreateFrame("Button", name, bindingOwner)
    button.spec = spec
    button:SetScript("OnClick", function()
      local s = this.spec
      if s.kind == "action" then
        ST_ActionButtonDown(s.a)
        ST_ActionButtonUp(s.a)
      elseif s.kind == "multi" then
        ST_MultiActionButtonDown(s.a, s.b)
        ST_MultiActionButtonUp(s.a, s.b)
      elseif s.kind == "bonus" then
        ST_BonusActionButtonDown(s.a)
        ST_BonusActionButtonUp(s.a)
      end
    end)
    proxies[index] = button
    return button
  end

  local refreshingBindings
  local function RefreshModifiedBindings()
    if refreshingBindings then return end
    if not API or not API.overridebindings then return end

    refreshingBindings = true
    API.ClearOverrideBindings(bindingOwner)

    for index, spec in ipairs(specs) do
      local key1, key2 = GetBindingKey(spec.command)
      local proxy = GetProxy(spec, index)

      if IsModifiedKey(key1) then
        API.SetOverrideBindingClick(bindingOwner, true, key1, proxy:GetName())
      end
      if IsModifiedKey(key2) then
        API.SetOverrideBindingClick(bindingOwner, true, key2, proxy:GetName())
      end
    end

    refreshingBindings = nil
  end

  Install()
  RefreshModifiedBindings()

  local frame = CreateFrame("Frame", nil, UIParent)
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("UPDATE_BINDINGS")
  frame.elapsed = 0
  frame.guardUntil = 0

  local function GuardOnUpdate()
    if not frame.guardUntil or frame.guardUntil <= GetTime() then
      frame:SetScript("OnUpdate", nil)
      return
    end

    frame.elapsed = frame.elapsed + (arg1 or 0)
    if frame.elapsed < 0.25 then return end
    frame.elapsed = 0

    if not HandlersAreInstalled() then Install() end
  end

  frame:SetScript("OnEvent", function()
    Install()
    RefreshModifiedBindings()

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
      frame.guardUntil = GetTime() + 8
      frame.elapsed = 0
      frame:SetScript("OnUpdate", GuardOnUpdate)
    end
  end)
end
