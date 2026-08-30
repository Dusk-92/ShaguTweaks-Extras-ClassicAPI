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
    controller.elapsed = 0
    controller.hideAt = 0

    bar.ShaguTweaksMouseoverController = controller

    -- One invisible reveal area replaces the original per-button overlay
    -- frames. It only accepts mouse input while the actionbar is hidden.
    hotspot:SetAllPoints(bar)
    hotspot:SetFrameStrata("DIALOG")
    hotspot:EnableMouse(false)
    hotspot:Show()

    local function IsEnabled()
      return _G[visibilityFlag] and true or false
    end

    local function StopWatching()
      controller:SetScript("OnUpdate", nil)
      controller.elapsed = 0
    end

    local function StartWatching()
      if not IsEnabled() or not bar:IsShown() then return end

      hotspot:EnableMouse(false)
      controller.hideAt = GetTime() + 2
      controller.elapsed = 0

      controller:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + (arg1 or 0)
        if this.elapsed < .10 then return end
        this.elapsed = 0

        if not IsEnabled() then
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
          this.hideAt = GetTime() + 2
          return
        end

        if GetTime() >= this.hideAt then
          StopWatching()
          bar:Hide()
        end
      end)
    end

    local function Sync()
      if not IsEnabled() then
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
      if not IsEnabled() then return end
      hotspot:EnableMouse(false)
      bar:Show()
      StartWatching()
    end)

    -- Keep the helper in sync when the default UI or another addon changes
    -- the bar visibility. Existing scripts are preserved.
    local oldOnShow = bar:GetScript("OnShow")
    bar:SetScript("OnShow", function()
      if oldOnShow then oldOnShow() end
      if IsEnabled() then StartWatching() end
    end)

    local oldOnHide = bar:GetScript("OnHide")
    bar:SetScript("OnHide", function()
      if oldOnHide then oldOnHide() end
      StopWatching()
      if IsEnabled() then
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
