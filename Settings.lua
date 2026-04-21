local addonName, ns = ...

local ANCHORS = {
    { value = "LEFT",        label = "Left of minimap"               },
    { value = "RIGHT",       label = "Right of minimap"              },
    { value = "BOTTOMLEFT",  label = "Below minimap, left-aligned"   },
    { value = "BOTTOMRIGHT", label = "Below minimap, right-aligned"  },
    { value = "TOPLEFT",     label = "Above minimap, left-aligned"   },
    { value = "TOPRIGHT",    label = "Above minimap, right-aligned"  },
}

local function labelForAnchor(value)
    for _, a in ipairs(ANCHORS) do
        if a.value == value then return a.label end
    end
    return ANCHORS[1].label
end

local panel
local anchorDropdown
local closeOutsideCheck

local function refresh()
    if not panel then return end
    local db = MinimapButtonCollectorDB
    if not (db and db.global) then return end

    if anchorDropdown then
        UIDropDownMenu_SetText(anchorDropdown, labelForAnchor(db.global.panelAnchor))
    end
    if closeOutsideCheck then
        closeOutsideCheck:SetChecked(db.global.closeOnOutsideClick == true)
    end
end

local function buildPanel()
    if panel then return panel end

    panel = CreateFrame(
        "Frame",
        "MBCSettingsFrame",
        UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil
    )
    panel:SetSize(440, 380)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetClampedToScreen(true)
    panel:Hide()

    tinsert(UISpecialFrames, "MBCSettingsFrame")

    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
    end

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Minimap Button Collector")

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetText("Settings")

    -- ========== Panel section ==========
    local panelHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    panelHeader:SetPoint("TOPLEFT", 20, -68)
    panelHeader:SetText("Panel")

    local anchorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    anchorLabel:SetPoint("TOPLEFT", panelHeader, "BOTTOMLEFT", 0, -10)
    anchorLabel:SetText("Anchor relative to the minimap")

    anchorDropdown = CreateFrame(
        "Frame",
        "MBCSettingsAnchorDropdown",
        panel,
        "UIDropDownMenuTemplate"
    )
    anchorDropdown:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(anchorDropdown, 260)

    UIDropDownMenu_Initialize(anchorDropdown, function(self, level)
        local current = MinimapButtonCollectorDB.global.panelAnchor
        for _, a in ipairs(ANCHORS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = a.label
            info.value = a.value
            info.checked = (a.value == current)
            info.func = function()
                MinimapButtonCollectorDB.global.panelAnchor = a.value
                UIDropDownMenu_SetText(anchorDropdown, a.label)
                if ns.ReapplyPanelAnchor then ns:ReapplyPanelAnchor() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- ========== Behavior section ==========
    local behaviorHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    behaviorHeader:SetPoint("TOPLEFT", anchorDropdown, "BOTTOMLEFT", 16, -20)
    behaviorHeader:SetText("Behavior")

    closeOutsideCheck = CreateFrame(
        "CheckButton",
        "MBCSettingsCloseOutsideCheck",
        panel,
        "InterfaceOptionsCheckButtonTemplate"
    )
    closeOutsideCheck:SetPoint("TOPLEFT", behaviorHeader, "BOTTOMLEFT", 0, -8)
    closeOutsideCheck.Text:SetText("Close the panel when clicking outside")
    closeOutsideCheck:SetScript("OnClick", function(self)
        MinimapButtonCollectorDB.global.closeOnOutsideClick = self:GetChecked() and true or false
    end)

    -- ========== About section ==========
    local aboutHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    aboutHeader:SetPoint("TOPLEFT", closeOutsideCheck, "BOTTOMLEFT", 0, -22)
    aboutHeader:SetText("About")

    local version = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
    if not version or version == "" or version == "@project-version@" then
        version = "dev"
    end

    local aboutText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    aboutText:SetPoint("TOPLEFT", aboutHeader, "BOTTOMLEFT", 0, -8)
    aboutText:SetWidth(400)
    aboutText:SetJustifyH("LEFT")
    aboutText:SetText(
        "Version: |cffffffff" .. version .. "|r" ..
        "|n|nAvailable on:" ..
        "|n  · |cffffffffgithub.com/mikarregui/MinimapButtonCollector|r" ..
        "|n  · |cffffffffcurseforge.com/wow/addons/minimap-button-collector|r" ..
        "|n  · |cffffffffaddons.wago.io/addons/minimapbuttoncollector|r" ..
        "|n|nTips welcome at |cffffffffko-fi.com/mikarregui|r — optional, addon stays free either way." ..
        "|n|n|cffffffff/mbc|r toggle · |cffffffff/mbc rescan|r re-detect · |cffffffff/mbc list|r inspect · |cffffffff/mbc config|r this window."
    )

    return panel
end

function ns:OpenSettingsPanel()
    buildPanel()
    refresh()
    panel:Show()
    panel:Raise()
end

-- Build the settings frame at load so /mbc config and right-click on the
-- trigger have something to open on first use.
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function(self)
    buildPanel()
    self:UnregisterAllEvents()
end)
