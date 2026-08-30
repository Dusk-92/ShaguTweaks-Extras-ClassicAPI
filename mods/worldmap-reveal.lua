local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local API = ShaguTweaks.API
local hooksecurefunc = ShaguTweaks.hooksecurefunc

local module = ShaguTweaks:register({
  title = T["Reveal World Map"],
  description = T["Reveals unexplored world map areas and shows exploration hints."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["World Map"],
  maintainer = "@shagu (GitHub)",
  enabled = true,
  config = {
    ["map.reveal.marker"] = "on",
  }
})

module.enable = function(self)
  -- do not load if another map addon is controlling the world map
  if Cartographer then return end
  if METAMAP_TITLE then return end

  local enabled = true
  local overlayTextures = {}
  local exploreFrames = {}

  local mapreveal = {}
  mapreveal.onmap = CreateFrame("CheckButton", "shagutweaks_mapreveal_onmap", WorldMapFrame, "UICheckButtonTemplate")
  mapreveal.onmap.text = _G["shagutweaks_mapreveal_onmapText"]
  mapreveal.onmap:SetWidth(14)
  mapreveal.onmap:SetHeight(14)
  mapreveal.onmap:SetPoint("TOPLEFT", WorldMapButton, "TOPLEFT", 1, 19)
  mapreveal.onmap.text:SetPoint("LEFT", mapreveal.onmap, "RIGHT", 2, 0)
  mapreveal.onmap.text:SetText(T["Reveal Unexplored"])

  mapreveal.onmap:SetScript("OnShow", function()
    this:SetChecked(enabled)
  end)

  mapreveal.onmap:SetScript("OnClick", function()
    enabled = this:GetChecked() and true or false
    WorldMapFrame_Update()
  end)

  local function HideRevealLayer()
    for _, texture in ipairs(overlayTextures) do
      texture:Hide()
    end

    for _, frame in ipairs(exploreFrames) do
      frame:Hide()
    end
  end

  local function ExploreEnter()
    WorldMapTooltip:ClearLines()
    WorldMapTooltip:SetOwner(this, "ANCHOR_TOP")
    WorldMapTooltip:AddLine(T["Exploration Point"]..":", .3, 1, .8)
    WorldMapTooltip:AddLine(this.name or "?", 1, 1, 1)
    WorldMapTooltip:Show()
  end

  local function ExploreLeave()
    WorldMapTooltip:Hide()
  end

  local function GetExploreCenter(overlay)
    if overlay.hitRectLeft and overlay.hitRectRight
      and overlay.hitRectTop and overlay.hitRectBottom then
      return (overlay.hitRectLeft + overlay.hitRectRight) / 2,
        (overlay.hitRectTop + overlay.hitRectBottom) / 2
    end

    if overlay.offsetX and overlay.offsetY
      and overlay.textureWidth and overlay.textureHeight then
      return overlay.offsetX + overlay.textureWidth / 2,
        overlay.offsetY + overlay.textureHeight / 2
    end
  end

  local function UpdateRevealLayer()
    HideRevealLayer()
    if not enabled then return end

    -- ClassicAPI reads WorldMapOverlay.dbc directly from the active client,
    -- including custom Turtle-like zones and their real tile layout.
    local overlays = API.GetUnexploredMapTextures()
    if not overlays then return end

    local textureIndex = 0
    local exploreIndex = 0

    for _, overlay in ipairs(overlays) do
      if overlay.tiles then
        for _, tile in ipairs(overlay.tiles) do
          if tile.file and tile.width and tile.height
            and tile.offsetX and tile.offsetY then
            textureIndex = textureIndex + 1

            local texture = overlayTextures[textureIndex]
            if not texture then
              texture = WorldMapDetailFrame:CreateTexture(nil, "ARTWORK")
              overlayTextures[textureIndex] = texture
            end

            texture:ClearAllPoints()
            texture:SetWidth(tile.width)
            texture:SetHeight(tile.height)
            texture:SetTexCoord(0, tile.texCoordX or 1, 0, tile.texCoordY or 1)
            texture:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", tile.offsetX, -tile.offsetY)
            texture:SetTexture(tile.file)
            texture:SetVertexColor(.4, .4, .4, 1)
            texture:Show()
          end
        end
      end

      if self.config["map.reveal.marker"] == "on" then
        local x, y = GetExploreCenter(overlay)
        if x and y then
          exploreIndex = exploreIndex + 1

          local explore = exploreFrames[exploreIndex]
          if not explore then
            explore = CreateFrame("Frame", nil, WorldMapDetailFrame)
            explore:SetWidth(16)
            explore:SetHeight(16)
            explore:EnableMouse(true)
            explore:SetFrameLevel(255)
            explore:SetScript("OnEnter", ExploreEnter)
            explore:SetScript("OnLeave", ExploreLeave)

            explore.tex = explore:CreateTexture(nil, "OVERLAY")
            explore.tex:SetTexture("Interface\\WorldMap\\WorldMap-MagnifyingGlass")
            explore.tex:SetBlendMode("ADD")
            explore.tex:SetTexCoord(.08, .92, .08, .92)
            explore.tex:SetAllPoints()

            exploreFrames[exploreIndex] = explore
          end

          explore:ClearAllPoints()
          explore:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", x, -y)
          explore.name = API.GetAreaInfo(overlay.areaID)
            or overlay.textureName
            or "?"
          explore:Show()
        end
      end
    end
  end

  -- Keep Blizzard's normal explored-map rendering untouched and append only
  -- ClassicAPI's unexplored overlays after the native update.
  hooksecurefunc("WorldMapFrame_Update", UpdateRevealLayer)

  if WorldMapFrame:IsShown() then
    UpdateRevealLayer()
  end
end
