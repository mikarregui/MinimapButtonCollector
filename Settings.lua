local addonName, ns = ...

local ANCHORS = {
    { value = "BOTTOMLEFT",  label = "Below minimap, left-aligned"  },
    { value = "BOTTOMRIGHT", label = "Below minimap, right-aligned" },
    { value = "TOPLEFT",     label = "Above minimap, left-aligned"  },
    { value = "TOPRIGHT",    label = "Above minimap, right-aligned" },
}

local function labelForAnchor(value)
    for _, a in ipairs(ANCHORS) do
        if a.value == value then return a.label end
    end
    return ANCHORS[1].label
end

local panel
local anchorDropdown

local function refresh()
    if not panel then return end
    local db = MinimapButtonCollectorDB
    if not (db and db.global) then return end

    if anchorDropdown then
        UIDropDownMenu_SetText(anchorDropdown, labelForAnchor(db.global.panelAnchor))
    end
end

local function buildPanel()
    if panel then return panel end

    panel = CreateFrame("Frame", "MBCSettingsPanel", UIParent)
    panel.name = "Minimap Button Collector"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Minimap Button Collector")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWidth(560)
    subtitle:SetText("Group your minimap addon buttons behind a single trigger.")

    -- ========== Panel section ==========
    local panelHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalMed3")
    panelHeader:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -24)
    panelHeader:SetText("Panel")

    local anchorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    anchorLabel:SetPoint("TOPLEFT", panelHeader, "BOTTOMLEFT", 0, -12)
    anchorLabel:SetText("Anchor relative to the minimap")

    anchorDropdown = CreateFrame("Frame", "MBCAnchorDropdown", panel, "UIDropDownMenuTemplate")
    anchorDropdown:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(anchorDropdown, 240)

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

    -- ========== About section ==========
    local aboutHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalMed3")
    aboutHeader:SetPoint("TOPLEFT", anchorDropdown, "BOTTOMLEFT", 16, -24)
    aboutHeader:SetText("About")

    local version = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
    if not version or version == "" or version == "@project-version@" then
        version = "dev"
    end

    local aboutText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    aboutText:SetPoint("TOPLEFT", aboutHeader, "BOTTOMLEFT", 0, -8)
    aboutText:SetWidth(560)
    aboutText:SetJustifyH("LEFT")
    aboutText:SetText(
        "Version: |cffffffff" .. version .. "|r" ..
        "|n|nAvailable on:" ..
        "|n  · |cffffffffGitHub Releases:|r github.com/mikarregui/MinimapButtonCollector" ..
        "|n  · |cffffffffCurseForge:|r curseforge.com/wow/addons/minimap-button-collector" ..
        "|n  · |cffffffffWago:|r addons.wago.io/addons/minimapbuttoncollector" ..
        "|n|nIf the addon saves you time, tips are welcome at |cffffffffko-fi.com/mikarregui|r. Completely optional — the addon stays free either way." ..
        "|n|nSlash commands: |cffffffff/mbc|r toggle · |cffffffff/mbc rescan|r re-detect · |cffffffff/mbc list|r inspect · |cffffffff/mbc config|r this panel."
    )

    panel.refresh = refresh
    panel.okay    = refresh
    panel.cancel  = refresh

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    elseif InterfaceOptionsFrame_AddCategory then
        InterfaceOptionsFrame_AddCategory(panel)
    end

    return panel
end

function ns:OpenSettingsPanel()
    buildPanel()
    refresh()

    if InterfaceOptionsFrame_OpenToCategory then
        -- Known Blizzard bug: must call twice for the category to actually select.
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    elseif Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(panel.name)
    else
        print("|cffffcc55MBC:|r settings panel API not available on this client.")
    end
end

-- Build the panel at load so it shows up in Interface → AddOns even before
-- the user opens it explicitly.
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function(self)
    buildPanel()
    self:UnregisterAllEvents()
end)
