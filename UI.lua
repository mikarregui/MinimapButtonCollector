local addonName, ns = ...

local FADE_DURATION         = 0.2
local MINIMAP_DIMMED_ALPHA  = 0.4
local BUTTON_SIZE           = 24
local BUTTON_GAP            = 8
local HEX_DX                = BUTTON_SIZE + BUTTON_GAP
local HEX_DY                = BUTTON_SIZE + BUTTON_GAP

local function isUsable(frame)
    if not frame then return false end
    if frame.IsForbidden and frame:IsForbidden() then return false end
    return true
end

local ldb = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

local dataObject = ldb:NewDataObject("MinimapButtonCollector", {
    type = "launcher",
    text = "MBC",
    icon = "Interface\\Icons\\INV_Misc_Bag_10",
    OnClick = function() ns:ToggleOverlay() end,
    OnTooltipShow = function(tt)
        tt:AddLine("Minimap Button Collector")
        tt:AddLine("Click to open or close the overlay.", 1, 1, 1)
        tt:AddLine("/mbc rescan to re-detect buttons.", 0.7, 0.7, 0.7)
    end,
})

local registerFrame = CreateFrame("Frame")
registerFrame:RegisterEvent("PLAYER_LOGIN")
registerFrame:SetScript("OnEvent", function(self)
    MinimapButtonCollectorDB = MinimapButtonCollectorDB or {}
    MinimapButtonCollectorDB.minimap = MinimapButtonCollectorDB.minimap or {}
    icon:Register("MinimapButtonCollector", dataObject, MinimapButtonCollectorDB.minimap)
    self:UnregisterAllEvents()
end)

local function computeHexPositions(n)
    if n <= 0 then return {} end

    local cols = math.ceil(math.sqrt(n))
    local rows = math.ceil(n / cols)

    local hasOddRow = rows > 1
    local totalWidth  = (cols - 1) * HEX_DX + (hasOddRow and HEX_DX / 2 or 0)
    local totalHeight = (rows - 1) * HEX_DY
    local x0 = -totalWidth / 2
    local y0 =  totalHeight / 2

    local positions, i = {}, 0
    for row = 0, rows - 1 do
        local offset = (row % 2 == 1) and (HEX_DX / 2) or 0
        for col = 0, cols - 1 do
            i = i + 1
            if i > n then break end
            positions[i] = {
                x = x0 + col * HEX_DX + offset,
                y = y0 - row * HEX_DY,
            }
        end
    end
    return positions
end

local animFrame = CreateFrame("Frame")

local overlayHost = CreateFrame("Frame", "MBCOverlayHost", UIParent)
overlayHost:SetAllPoints(Minimap)
overlayHost:SetFrameStrata("HIGH")
overlayHost:Hide()

-- ESC-to-close, the standard WoW way. WoW hides the topmost shown frame
-- listed in UISpecialFrames when the user presses Escape. We use a tiny
-- proxy instead of overlayHost itself so we can run an animated close via
-- our OnHide handler and keep overlayHost fully under our control.
local escHandler = CreateFrame("Frame", "MBCEscHandler", UIParent)
escHandler:Hide()
escHandler:SetScript("OnHide", function()
    if ns.state.isOpen then
        ns:CloseOverlay()
    end
end)
tinsert(UISpecialFrames, "MBCEscHandler")

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
    Minimap:SetAlpha(1)
    overlayHost:Hide()
    escHandler:Hide()
end

function ns:OpenOverlay()
    if self.state.isOpen then return end

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

    local positions = computeHexPositions(#ordered)
    local fadeEntries = {
        { obj = Minimap, from = Minimap:GetAlpha(), to = MINIMAP_DIMMED_ALPHA },
    }

    for i, entry in ipairs(ordered) do
        local btn = entry.data.button
        local pos = positions[i]

        btn:ClearAllPoints()
        btn:SetParent(overlayHost)
        btn:SetPoint("CENTER", overlayHost, "CENTER", pos.x, pos.y)
        btn:SetAlpha(0)
        entry.data.originalShow(btn)

        hookAutoClose(btn, entry.data)
        fadeEntries[#fadeEntries + 1] = { obj = btn, from = 0, to = 1 }
    end

    overlayHost:Show()
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

    local fadeEntries = {
        { obj = Minimap, from = Minimap:GetAlpha(), to = 1 },
    }
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
