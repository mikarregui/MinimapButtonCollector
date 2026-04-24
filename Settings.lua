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

local ROW_HEIGHT    = 24
local SCROLL_WIDTH  = 380
local SCROLL_HEIGHT = 180

local panel
local anchorDropdown
local closeOutsideCheck
local buttonsScrollContent
local rebuildButtonList

local rowPool, activeRows = {}, {}

local function releaseRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        rowPool[#rowPool + 1] = row
    end
    activeRows = {}
end

local function makeArrowButton(parent, direction)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)
    local up, down, disabled
    if direction == "up" then
        up       = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"
        down     = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down"
        disabled = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled"
    else
        up       = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"
        down     = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down"
        disabled = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled"
    end
    btn:SetNormalTexture(up)
    btn:SetPushedTexture(down)
    btn:SetDisabledTexture(disabled)
    btn:SetHighlightTexture(up, "ADD")
    return btn
end

local function acquireRow(parent)
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetSize(SCROLL_WIDTH - 24, ROW_HEIGHT)

        row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.check:SetSize(22, 22)
        row.check:SetPoint("LEFT", row, "LEFT", 0, 0)

        row.upBtn   = makeArrowButton(row, "up")
        row.upBtn:SetPoint("LEFT", row.check, "RIGHT", 4, 0)

        row.downBtn = makeArrowButton(row, "down")
        row.downBtn:SetPoint("LEFT", row.upBtn, "RIGHT", 2, 0)

        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("LEFT", row.downBtn, "RIGHT", 12, 0)
        row.label:SetJustifyH("LEFT")
    end
    row:SetParent(parent)
    row:Show()
    activeRows[#activeRows + 1] = row
    return row
end

rebuildButtonList = function()
    if not buttonsScrollContent then return end
    releaseRows()

    local ordered     = ns.GetOrderedButtons and ns:GetOrderedButtons() or {}
    local perChar     = MinimapButtonCollectorPerCharDB
    local excludedMap = (perChar and perChar.excludedButtons) or {}
    local order       = (perChar and perChar.buttonOrder)     or {}

    local rows = {}
    for _, entry in ipairs(ordered) do
        rows[#rows + 1] = { name = entry.name, state = "collected" }
    end

    local excludedList = {}
    for name in pairs(excludedMap) do excludedList[#excludedList + 1] = name end
    table.sort(excludedList)
    for _, name in ipairs(excludedList) do
        rows[#rows + 1] = { name = name, state = "excluded" }
    end

    for i, info in ipairs(rows) do
        local row = acquireRow(buttonsScrollContent)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        local name = info.name
        local isCollected = info.state == "collected"

        row.label:SetText(name)
        row.check:SetChecked(isCollected)
        row.check:SetScript("OnClick", function(self)
            if self:GetChecked() then
                if ns.IncludeButton then ns:IncludeButton(name) end
            else
                if ns.ExcludeButton then ns:ExcludeButton(name) end
            end
            rebuildButtonList()
        end)

        if isCollected then
            row.upBtn:Show(); row.downBtn:Show()

            local myIdx
            for idx, n in ipairs(order) do if n == name then myIdx = idx; break end end

            local canUp, canDown = false, false
            if myIdx then
                for idx = myIdx - 1, 1, -1 do
                    if ns.collectedButtons[order[idx]] then canUp = true; break end
                end
                for idx = myIdx + 1, #order do
                    if ns.collectedButtons[order[idx]] then canDown = true; break end
                end
            end
            if canUp then row.upBtn:Enable() else row.upBtn:Disable() end
            if canDown then row.downBtn:Enable() else row.downBtn:Disable() end

            row.upBtn:SetScript("OnClick", function()
                if ns.MoveButtonUp and ns:MoveButtonUp(name) then rebuildButtonList() end
            end)
            row.downBtn:SetScript("OnClick", function()
                if ns.MoveButtonDown and ns:MoveButtonDown(name) then rebuildButtonList() end
            end)
        else
            row.upBtn:Hide(); row.downBtn:Hide()
        end
    end

    buttonsScrollContent:SetHeight(math.max(1, #rows * ROW_HEIGHT))
end

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
    rebuildButtonList()
end

local function buildPanel()
    if panel then return panel end

    panel = CreateFrame(
        "Frame",
        "MBCSettingsFrame",
        UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil
    )
    panel:SetSize(440, 640)
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

    -- ========== Collected buttons section ==========
    local buttonsHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    buttonsHeader:SetPoint("TOPLEFT", closeOutsideCheck, "BOTTOMLEFT", 0, -22)
    buttonsHeader:SetText("Collected buttons")

    local buttonsHelp = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    buttonsHelp:SetPoint("TOPLEFT", buttonsHeader, "BOTTOMLEFT", 0, -4)
    buttonsHelp:SetText("Uncheck to keep a button on the minimap. Arrows reorder inside the panel.")

    local scroll = CreateFrame(
        "ScrollFrame",
        "MBCSettingsButtonsScroll",
        panel,
        "UIPanelScrollFrameTemplate"
    )
    scroll:SetSize(SCROLL_WIDTH, SCROLL_HEIGHT)
    scroll:SetPoint("TOPLEFT", buttonsHelp, "BOTTOMLEFT", 0, -8)

    buttonsScrollContent = CreateFrame("Frame", nil, scroll)
    buttonsScrollContent:SetSize(SCROLL_WIDTH, ROW_HEIGHT)
    scroll:SetScrollChild(buttonsScrollContent)

    -- ========== About section ==========
    local aboutHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    aboutHeader:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -16)
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

-- Called from Core.lua when exclude/include/reorder happens outside the
-- panel (e.g. slash commands while the panel is open) so the UI stays in
-- sync without the user reopening it.
function ns:RefreshSettings()
    if panel and panel:IsShown() then refresh() end
end

-- Build the settings frame at load so /mbc config and right-click on the
-- trigger have something to open on first use.
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function(self)
    buildPanel()
    self:UnregisterAllEvents()
end)
