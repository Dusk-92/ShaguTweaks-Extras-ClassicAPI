-- Shared mouseover actionbar helper.
-- Adapted from TokensWorth/ShaguTweaks-mods (MIT, original copyright GryllsAddons).

local _G = ShaguTweaks.GetGlobalEnv()

if not ShaguTweaks.CreateMouseoverActionBar then
  ShaguTweaks.CreateMouseoverActionBar = function(bar, visibilityFlag)
    if not bar or not visibilityFlag then return end
    if bar.ShaguTweaksMouseoverController then return end

    local controller = CreateFrame("Frame", nil, UIParent)
    local hotspot = CreateFrame("Frame", nil, UIParent)

    controller.bar = bar
    controller.hotspot = hotspot
    controller.visibilityFlag = visibilityFlag
    controller.enabled = false
    controller.elapsed = 0
    controller.idle = 0

    bar.ShaguTweaksMouseoverController = controller

    -- One invisible reveal area replaces the original per-button overlay
    -- frames. It only accepts mouse input while the actionbar is hidden.
    hotspot:SetAllPoints(bar)
    hotspot:SetFrameStrata("DIALOG")
    hotspot:EnableMouse(false)
    hotspot:Hide()

    local function ReadEnabled()
      return _G[visibilityFlag] and true or false
    end

    local function StopWatching()
      controller:SetScript("OnUpdate", nil)
      controller.elapsed = 0
      controller.idle = 0
    end

    local function StartWatching()
      if not controller.enabled or not bar:IsShown() then return end

      hotspot:EnableMouse(false)
      controller.elapsed = 0
      controller.idle = 0

      controller:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + (arg1 or 0)
        if this.elapsed < .10 then return end

        local step = this.elapsed
        this.elapsed = 0

        if not this.enabled then
          StopWatching()
          hotspot:EnableMouse(false)
          hotspot:Hide()
          return
        end

        if not bar:IsShown() then
          StopWatching()
          hotspot:Show()
          hotspot:EnableMouse(true)
          return
        end

        if MouseIsOver(bar) then
          this.idle = 0
          return
        end

        this.idle = this.idle + step
        if this.idle >= 2 then
          StopWatching()
          bar:Hide()
        end
      end)
    end

    local function Sync()
      controller.enabled = ReadEnabled()

      if not controller.enabled then
        StopWatching()
        hotspot:EnableMouse(false)
        hotspot:Hide()
        return
      end

      hotspot:Show()

      if bar:IsShown() then
        StartWatching()
      else
        hotspot:EnableMouse(true)
      end
    end

    hotspot:SetScript("OnEnter", function()
      if not controller.enabled then return end

      hotspot:EnableMouse(false)
      bar:Show()
      -- The bar's OnShow script starts the watcher. Avoid a second redundant
      -- StartWatching() call here.
    end)

    -- Keep existing scripts intact while observing native/UI-addon visibility
    -- changes. These wrappers are installed once per bar.
    local oldOnShow = bar:GetScript("OnShow")
    bar:SetScript("OnShow", function()
      if oldOnShow then oldOnShow() end
      if controller.enabled then StartWatching() end
    end)

    local oldOnHide = bar:GetScript("OnHide")
    bar:SetScript("OnHide", function()
      if oldOnHide then oldOnHide() end

      StopWatching()

      if controller.enabled then
        hotspot:Show()
        hotspot:EnableMouse(true)
      else
        hotspot:EnableMouse(false)
        hotspot:Hide()
      end
    end)

    controller:RegisterEvent("PLAYER_ENTERING_WORLD")
    controller:RegisterEvent("CVAR_UPDATE")
    controller:SetScript("OnEvent", Sync)

    Sync()
  end
end
