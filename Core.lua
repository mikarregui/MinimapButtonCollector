local addonName, ns = ...

ns.collectedButtons = {}
ns.state = { isOpen = false }

local BLIZZARD_MINIMAP_BLACKLIST = {
    MinimapBackdrop = true,
    MiniMapTracking = true,
    MiniMapTrackingButton = true,
    MiniMapTrackingFrame = true,
    TimeManagerClockButton = true,
    GameTimeFrame = true,
    MiniMapWorldMapButton = true,
    MinimapZoneTextButton = true,
    MiniMapMailFrame = true,
    MiniMapBattlefieldFrame = true,
    MiniMapLFGFrame = true,
    MiniMapInstanceDifficulty = true,
    MiniMapVoiceChatFrame = true,
    MinimapCompassTexture = true,
    MinimapBorder = true,
    MinimapBorderTop = true,
    MinimapZoomIn = true,
    MinimapZoomOut = true,
    MinimapNorthTag = true,
    QueueStatusMinimapButton = true,
    QueueStatusMinimapButtonBorder = true,
}

local CONFLICTING_PARENTS = { "MoveAny", "SexyMap", "Chinchilla" }

local MIN_BUTTON_SIZE = 18
local MAX_BUTTON_SIZE = 48

local function isUsable(frame)
    if not frame then return false end
    if frame.IsForbidden and frame:IsForbidden() then return false end
    return true
end

local function isDynamicIndicatorName(name)
    return name:match("Frame%d+$") ~= nil
        or name:match("Icon%d+$") ~= nil
        or name:match("Pin%d+$") ~= nil
        or name:match("Marker%d+$") ~= nil
end

local function looksLikeAddonButton(frame)
    if frame == UIParent or frame == Minimap or frame == MinimapBackdrop then
        return false
    end

    local objType = frame:GetObjectType()
    local clickable = objType == "Button" or frame:HasScript("OnClick")
    if not clickable then return false end

    local w = frame:GetWidth() or 0
    local h = frame:GetHeight() or 0
    if w < MIN_BUTTON_SIZE or w > MAX_BUTTON_SIZE
       or h < MIN_BUTTON_SIZE or h > MAX_BUTTON_SIZE then
        return false
    end

    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            return true
        end
    end
    return false
end

local function conflictOwner(button)
    local parent = button:GetParent()
    if not parent then return nil end
    local pn = parent.GetName and parent:GetName()
    if not pn then return nil end
    for _, needle in ipairs(CONFLICTING_PARENTS) do
        if pn:find(needle, 1, true) then
            return needle
        end
    end
    return nil
end

function ns:CountButtons()
    local c = 0
    for _ in pairs(self.collectedButtons) do c = c + 1 end
    return c
end

function ns:AdoptButton(name, button, source)
    if self.collectedButtons[name] then return false end
    if not isUsable(button) then return false end

    local owner = conflictOwner(button)
    if owner then
        print("|cff5588ffMBC:|r skipping " .. name .. " (managed by " .. owner .. ")")
        return false
    end

    self.collectedButtons[name] = {
        button = button,
        originalParent = button:GetParent(),
        originalAlpha = button:GetAlpha() or 1,
        originalShow = button.Show,
        point = { button:GetPoint() },
        source = source,
        hooked = false,
    }

    -- Prevent the owning addon from re-showing the button outside our overlay.
    -- Hide() stays on the original method so we and the addon can still hide it.
    button.Show = function() end
    button:Hide()

    return true
end

function ns:ScanButtons()
    local added = 0

    local lib = LibStub and LibStub("LibDBIcon-1.0", true)
    if lib and lib.objects then
        for name, button in pairs(lib.objects) do
            if name ~= "MinimapButtonCollector" and not self.collectedButtons[name] then
                if self:AdoptButton(name, button, "libdbicon") then
                    added = added + 1
                end
            end
        end
    end

    for _, child in ipairs({ Minimap:GetChildren() }) do
        local name = child:GetName()
        if name
           and not BLIZZARD_MINIMAP_BLACKLIST[name]
           and not name:find("^LibDBIcon10_")
           and not isDynamicIndicatorName(name)
           and not self.collectedButtons[name]
           and looksLikeAddonButton(child) then
            if self:AdoptButton(name, child, "minimap-child") then
                added = added + 1
            end
        end
    end

    return added
end

-- Live capture: when any addon registers a new LibDBIcon button after our
-- post-login scan windows, adopt it immediately so /mbc rescan is usually
-- unnecessary. hooksecurefunc runs our callback AFTER the original Register
-- completes, so lib.objects[name] is already populated.
local libDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
if libDBIcon and type(libDBIcon.Register) == "function" then
    hooksecurefunc(libDBIcon, "Register", function(_, name)
        if name == "MinimapButtonCollector" then return end
        if ns.collectedButtons[name] then return end
        local button = libDBIcon.objects and libDBIcon.objects[name]
        if button then
            ns:AdoptButton(name, button, "libdbicon-live")
        end
    end)
end

-- Schema v1 → v2 migration.
-- v1 stored the trigger angle globally (MinimapButtonCollectorDB.minimap).
-- v2 moves it to a per-character DB and introduces global.* for layout
-- preferences and perChar.hiddenButtons for the future hide feature. The
-- v1 table is preserved under _legacy_v1 as a safety net.
local function migrateSavedVariables()
    MinimapButtonCollectorDB        = MinimapButtonCollectorDB or {}
    MinimapButtonCollectorPerCharDB = MinimapButtonCollectorPerCharDB or {}

    local db      = MinimapButtonCollectorDB
    local perChar = MinimapButtonCollectorPerCharDB

    local hadV1Data = db.minimap and db.minimap.minimapPos ~= nil
    local alreadyOnV2 = db.schemaVersion == 2 and perChar.schemaVersion == 2

    db.global = db.global or {}
    db.global.panelAnchor     = db.global.panelAnchor     or "BOTTOMLEFT"
    db.global.panelMaxRows    = db.global.panelMaxRows    or 8
    db.global.autoHideInCombat = db.global.autoHideInCombat == true
    db.global.hoverToOpen     = db.global.hoverToOpen     == true

    perChar.minimap       = perChar.minimap       or {}
    perChar.hiddenButtons = perChar.hiddenButtons or {}

    if hadV1Data and not perChar.minimap.minimapPos then
        perChar.minimap.minimapPos = db.minimap.minimapPos
    end

    if hadV1Data and not db._legacy_v1 then
        db._legacy_v1 = { minimap = { minimapPos = db.minimap.minimapPos } }
    end

    db.schemaVersion      = 2
    perChar.schemaVersion = 2

    return hadV1Data and not alreadyOnV2
end

local function announceV2IfFirstTime()
    local db = MinimapButtonCollectorDB
    if db.global.v2MessageShown then return end
    print("|cff55ff55MBC v2:|r the overlay is now a clean side panel next to the minimap. Your trigger position is preserved. Try |cffffffff/mbc config|r for options.")
    db.global.v2MessageShown = true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        local migrated = migrateSavedVariables()
        if migrated then announceV2IfFirstTime() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        ns:ScanButtons()
        C_Timer.After(2,  function() ns:ScanButtons() end)
        C_Timer.After(5,  function() ns:ScanButtons() end)
        C_Timer.After(10, function() ns:ScanButtons() end)
    end
end)

SLASH_MBC1 = "/mbc"
SlashCmdList["MBC"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""

    if msg == "rescan" then
        local added = ns:ScanButtons()
        print("|cff55ff55MBC:|r rescan added " .. added .. " button(s), " .. ns:CountButtons() .. " total.")
    elseif msg == "list" then
        local bySource, total = {}, 0
        for name, data in pairs(ns.collectedButtons) do
            bySource[data.source] = bySource[data.source] or {}
            table.insert(bySource[data.source], name)
            total = total + 1
        end
        for source, names in pairs(bySource) do
            table.sort(names)
            print(("|cff55ff55MBC:|r %s: %d button(s)"):format(source, #names))
            for i = 1, math.min(10, #names) do
                print("  " .. names[i])
            end
            if #names > 10 then
                print(("  ... and %d more (use /mbc list full)"):format(#names - 10))
            end
        end
        print(("|cff55ff55MBC:|r %d button(s) total."):format(total))
    elseif msg == "list full" then
        local total = 0
        for name, data in pairs(ns.collectedButtons) do
            print("  " .. name .. "  (" .. data.source .. ")")
            total = total + 1
        end
        print(("|cff55ff55MBC:|r %d button(s) total."):format(total))
    elseif msg == "config" or msg == "settings" then
        if ns.OpenSettings then ns:OpenSettings() end
    elseif msg == "" then
        if ns.ToggleOverlay then ns:ToggleOverlay() end
    else
        print("|cff55ff55MBC:|r unknown command. Try /mbc, /mbc rescan, /mbc list, /mbc config.")
    end
end
