local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API or {}
local libspell = ShaguTweaks.libspell

local module = ShaguTweaks:register({
  title = T["Macro Icons"],
  description = T["Detect showtooltip and spells in macros to use them on action buttons."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  maintainer = "@shagu (GitHub)",
  category = T["Macro"],
  enabled = true,
})

module.enable = function(self)
  local gfind = string.gmatch or string.gfind

  local function BuildMacroCache()
    local cache = {}
    for macroSlot = 1, 36 do
      local name, _, body = GetMacroInfo(macroSlot)
      if name and body then
        cache[name] = { id = macroSlot, body = body }
      end
    end
    return cache
  end

  local function GetMacroBody(actionSlot, cache)
    if API.GetActionInfo then
      local actionType, id = API.GetActionInfo(actionSlot)
      if actionType == "macro" and id then
        local _, _, body = GetMacroInfo(id)
        if body then return body end
      end
    end

    local macroName = GetActionText(actionSlot)
    local entry = macroName and cache[macroName]
    return entry and entry.body or nil
  end

  local function ResolveSpell(body)
    if not body then return end

    local fallback
    for line in gfind(body, "[^%\n]+") do
      local _, _, match = string.find(line, "^#showtooltip%s+(.+)")
      if match then return match end

      if not fallback then
        _, _, fallback = string.find(line, "%-%-showtooltip%s+(.+)")
      end
      if not fallback then
        _, _, fallback = string.find(line, "^/cast%s+(.+)")
      end
      if not fallback then
        _, _, fallback = string.find(line, "^/pfcast%s+(.+)")
      end
      if not fallback then
        _, _, fallback = string.find(line, "CastSpellByName%(%\"(.+)%\"%)")
      end
    end

    return fallback
  end

  local function ButtonMacroScan(bar, macroCache)
    if not bar:IsVisible() then return end

    local prefix = bar:GetName()
    prefix = bar == MainMenuBar and "Action" or prefix
    prefix = bar == BonusActionBarFrame and "BonusAction" or prefix

    for index = 1, 12 do
      local button = _G[prefix.."Button"..index]
      local icon = _G[prefix.."Button"..index.."Icon"]
      if not button then break end

      local actionSlot = ActionButton_GetPagedID(button)
      local texture = GetActionTexture(actionSlot)
      button.spellslot, button.booktype = nil, nil

      local body = GetMacroBody(actionSlot, macroCache)
      local match = ResolveSpell(body)
      if match then
        local _, _, spell, rank = string.find(match, "(.+)%((.+)%)")
        spell = spell or match
        button.spellslot, button.booktype = libspell.GetSpellIndex(spell, rank)

        if button.spellslot and button.booktype then
          texture = GetSpellTexture(button.spellslot, button.booktype) or texture
        end
      end

      if icon and texture and texture ~= icon:GetTexture() then
        icon:SetTexture(texture)
      end
    end
  end

  local bars = {
    MainMenuBar, BonusActionBarFrame, MultiBarRight, MultiBarLeft,
    MultiBarBottomRight, MultiBarBottomLeft
  }

  local macroicons = CreateFrame("Frame", "ShaguTweaksMacroIcons", UIParent)
  macroicons:RegisterEvent("PLAYER_ENTERING_WORLD")
  macroicons:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  macroicons:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
  macroicons:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
  macroicons:RegisterEvent("ACTIONBAR_SHOWGRID")
  macroicons:SetScript("OnEvent", function()
    local macroCache = BuildMacroCache()
    for _, bar in pairs(bars) do
      ButtonMacroScan(bar, macroCache)
    end
  end)
end
