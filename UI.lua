local addonName, ns = ...

local FADE_DURATION = 0.2
local BUTTON_SIZE   = 24
local BUTTON_GAP    = 8
local PITCH         = BUTTON_SIZE + BUTTON_GAP
local PADDING       = 10
local MIN_COLS      = 3
local MAX_COLS      = 8

local function isUsable(frame)
    if not frame then return false end
    if frame.IsForbidden and frame:IsForbidden() then return false end
    return true
end

-- LibDataBroker + LibDBIcon trigger. Right-click opens the settings panel.
local ldb = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

local dataObject = ldb:NewDataObject("MinimapButtonCollector", {
    type = "launcher",
    text = "MBC",
    icon = "Interface\\Icons\\INV_Misc_Bag_10",
    OnClick = function(_, btn)
        if btn == "RightButton" and ns.OpenSettings then
            ns:OpenSettings()
        else
            ns:ToggleOverlay()
        end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("Minimap Button Collector")
        tt:AddLine("Left-click: open or close panel", 1, 1, 1)
        tt:AddLine("Right-click: settings", 1, 1, 1)
        tt:AddLine("/mbc config  ·  /mbc rescan  ·  /mbc list", 0.7, 0.7, 0.7)
    end,
})

local registerFrame = CreateFrame("Frame")
registerFrame:RegisterEvent("PLAYER_LOGIN")
registerFrame:SetScript("OnEvent", function(self)
    MinimapButtonCollectorPerCharDB = MinimapButtonCollectorPerCharDB or {}
    MinimapButtonCollectorPerCharDB.minimap = MinimapButtonCollectorPerCharDB.minimap or {}
    icon:Register("MinimapButtonCollector", dataObject, MinimapButtonCollectorPerCharDB.minimap)
    self:UnregisterAllEvents()
end)

-- Panel anchor presets: which minimap corner the panel attaches to, and how
-- the panel grows from there (down for BOTTOM*, up for TOP*).
local ANCHOR_PRESETS = {
    BOTTOMLEFT  = { panelAnchor = "TOPLEFT",     mapAnchor = "BOTTOMLEFT",  x = 0, y = -4 },
    BOTTOMRIGHT = { panelAnchor = "TOPRIGHT",    mapAnchor = "BOTTOMRIGHT", x = 0, y = -4 },
    TOPLEFT     = { panelAnchor = "BOTTOMLEFT",  mapAnchor = "TOPLEFT",     x = 0, y = 4  },
    TOPRIGHT    = { panelAnchor = "BOTTOMRIGHT", mapAnchor = "TOPRIGHT",    x = 0, y = 4  },
}

local function getAnchorConfig()
    local db = MinimapButtonCollectorDB or {}
    db.global = db.global or {}
    return ANCHOR_PRESETS[db.global.panelAnchor] or ANCHOR_PRESETS.BOTTOMLEFT
end

local sidePanel

local function buildSidePanel()
    if sidePanel then return sidePanel end

    sidePanel = CreateFrame(
        "Frame",
        "MBCSidePanel",
        UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil
    )
    sidePanel:SetFrameStrata("HIGH")

    if sidePanel.SetBackdrop then
        sidePanel:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
    end

    sidePanel:Hide()
    return sidePanel
end

local function applyPanelAnchor(panel)
    local cfg = getAnchorConfig()
    panel:ClearAllPoints()
    panel:SetPoint(cfg.panelAnchor, Minimap, cfg.mapAnchor, cfg.x, cfg.y)
end

local function computeGrid(n)
    if n <= 0 then return 0, 0 end
    local cols = math.ceil(math.sqrt(n))
    if cols < MIN_COLS then cols = MIN_COLS end
    if cols > MAX_COLS then cols = MAX_COLS end
    local rows = math.ceil(n / cols)
    return cols, rows
end

local function panelSizeFor(cols, rows)
    local w = cols * PITCH - BUTTON_GAP + 2 * PADDING
    local h = rows * PITCH - BUTTON_GAP + 2 * PADDING
    return w, h
end

-- Alpha animator (same pattern as v1.0.3: single reusable frame, per-entry
-- linear interpolation over `duration`, onDone callback fires once at t=1).
local animFrame = CreateFrame("Frame")

local function animateFade(entries, duration, onDone)
    local elapsed = 0
    animFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local t = elapsed / duration
        if t > 1 then t = 1 end
        for _, e in ipairs(entries) do
            if isUsable(e.obj) then
                e.obj:SetAlpha(e.from + (e.to - e.from) * t)
            end
        end
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            if onDone then onDone() end
        end
    end)
end

-- ESC-to-close proxy. WoW hides the topmost shown frame listed in
-- UISpecialFrames on Escape; our OnHide reroutes to the animated close.
local escHandler = CreateFrame("Frame", "MBCEscHandler", UIParent)
escHandler:Hide()
escHandler:SetScript("OnHide", function()
    if ns.state.isOpen then
        ns:CloseOverlay()
    end
end)
tinsert(UISpecialFrames, "MBCEscHandler")

local function hookAutoClose(button, data)
    if data.hooked then return end
    button:HookScript("OnClick", function()
        if ns.state.isOpen then
            C_Timer.After(0, function() ns:CloseOverlay() end)
        end
    end)
    data.hooked = true
end

local function restoreButtons()
    for _, data in pairs(ns.collectedButtons) do
        local btn = data.button
        if isUsable(btn) then
            btn:ClearAllPoints()
            if data.originalParent then
                btn:SetParent(data.originalParent)
            end
            local p = data.point
            if p and p[1] then
                pcall(btn.SetPoint, btn, p[1], p[2], p[3], p[4], p[5])
            end
            btn:SetAlpha(data.originalAlpha or 1)
            btn:Hide()
        end
    end
    if sidePanel then sidePanel:Hide() end
    escHandler:Hide()
end

function ns:OpenOverlay()
    if self.state.isOpen then return end

    local panel = buildSidePanel()

    local ordered = {}
    for name, data in pairs(self.collectedButtons) do
        if isUsable(data.button) then
            ordered[#ordered + 1] = { name = name, data = data }
        end
    end
    table.sort(ordered, function(a, b) return a.name < b.name end)

    if #ordered == 0 then
        print("|cffffcc55MBC:|r no minimap buttons collected yet. Try /mbc rescan.")
        return
    end

    self.state.isOpen = true

    local cols, rows = computeGrid(#ordered)
    local w, h = panelSizeFor(cols, rows)
    panel:SetSize(w, h)
    applyPanelAnchor(panel)

    local fadeEntries = {
        { obj = panel, from = 0, to = 1 },
    }

    for i, entry in ipairs(ordered) do
        local btn = entry.data.button
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        btn:ClearAllPoints()
        btn:SetParent(panel)
        btn:SetPoint(
            "TOPLEFT",
            panel,
            "TOPLEFT",
            PADDING + col * PITCH,
            -(PADDING + row * PITCH)
        )
        btn:SetAlpha(0)
        entry.data.originalShow(btn)

        hookAutoClose(btn, entry.data)
        fadeEntries[#fadeEntries + 1] = { obj = btn, from = 0, to = 1 }
    end

    panel:SetAlpha(0)
    panel:Show()
    escHandler:Show()
    animateFade(fadeEntries, FADE_DURATION)
end

function ns:CloseOverlay(forced)
    if not self.state.isOpen then return end
    self.state.isOpen = false

    if forced then
        animFrame:SetScript("OnUpdate", nil)
        restoreButtons()
        return
    end

    local fadeEntries = {}
    if sidePanel then
        fadeEntries[#fadeEntries + 1] = { obj = sidePanel, from = sidePanel:GetAlpha(), to = 0 }
    end
    for _, data in pairs(self.collectedButtons) do
        local btn = data.button
        if isUsable(btn) then
            fadeEntries[#fadeEntries + 1] = { obj = btn, from = btn:GetAlpha(), to = 0 }
        end
    end

    animateFade(fadeEntries, FADE_DURATION, restoreButtons)
end

function ns:ToggleOverlay()
    if self.state.isOpen then
        self:CloseOverlay()
    else
        self:OpenOverlay()
    end
end

-- Settings panel entry point. Delegates to Settings.lua if loaded.
function ns:OpenSettings()
    if ns.OpenSettingsPanel then
        ns:OpenSettingsPanel()
    else
        print("|cffffcc55MBC:|r settings panel not available.")
    end
end

-- Re-apply anchor on the fly when the user changes it from settings.
function ns:ReapplyPanelAnchor()
    if sidePanel then applyPanelAnchor(sidePanel) end
end
