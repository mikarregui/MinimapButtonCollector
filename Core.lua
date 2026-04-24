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

    local perChar = MinimapButtonCollectorPerCharDB
    if perChar and perChar.excludedButtons and perChar.excludedButtons[name] then
        return false
    end

    local owner = conflictOwner(button)
    if owner then
        print("|cff5588ffMBC:|r skipping " .. name .. " (managed by " .. owner .. ")")
        return false
    end

    local data = {
        button = button,
        originalParent = button:GetParent(),
        originalAlpha = button:GetAlpha() or 1,
        originalShow = button.Show,
        point = { button:GetPoint() },
        source = source,
        hooked = false,
    }
    self.collectedButtons[name] = data

    -- Preserve the button's natural minimap-button look inside our panel:
    -- LibDBIcon's tracking border ring and minimap-background disc are part
    -- of what makes the icon read as "a button" — hiding them left the icon
    -- floating with no visual framing. Instead, keep the decorations and let
    -- the grid pitch in UI.lua give them room to breathe (same approach the
    -- dominant addons in this category use).
    --
    -- Re-show anything a previous MBC version may have hidden, so users
    -- upgrading from v2.0.0-dev iterations get a clean state without needing
    -- a full game restart.
    if type(button.border) == "table" and button.border.Show then
        button.border:Show()
    end
    for _, region in ipairs({ button:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then
            local layer = region.GetDrawLayer and region:GetDrawLayer()
            if (layer == "OVERLAY" or layer == "BACKGROUND") and region.Show then
                region:Show()
            end
        end
    end

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

-- Inverse of AdoptButton: returns a previously-collected button to its
-- native state on the minimap edge. LibDBIcon buttons are restored via the
-- lib's own Show() so it re-anchors at the saved minimapPos; legacy
-- minimap-child buttons get their parent, point and strata put back.
function ns:ReleaseButton(name)
    local data = self.collectedButtons[name]
    if not data then return false end

    local btn = data.button

    if data.originalShow and isUsable(btn) then
        btn.Show = data.originalShow
    end

    if isUsable(btn) then
        if data.source == "libdbicon" or data.source == "libdbicon-live" then
            if data.originalParent and btn.SetParent then
                btn:SetParent(data.originalParent)
            end
            local lib = LibStub and LibStub("LibDBIcon-1.0", true)
            if lib and lib.Show then
                pcall(lib.Show, lib, name)
            else
                btn:Show()
            end
        else
            if data.originalParent and btn.SetParent then
                btn:SetParent(data.originalParent)
            end
            if btn.ClearAllPoints then btn:ClearAllPoints() end
            if data.point and data.point[1] and btn.SetPoint then
                pcall(btn.SetPoint, btn, unpack(data.point))
            end
            if btn.SetFrameStrata then btn:SetFrameStrata("MEDIUM") end
            btn:Show()
        end
    end

    self.collectedButtons[name] = nil
    return true
end

function ns:IsExcluded(name)
    local perChar = MinimapButtonCollectorPerCharDB
    return perChar and perChar.excludedButtons and perChar.excludedButtons[name] == true
end

function ns:ExcludeButton(name)
    MinimapButtonCollectorPerCharDB.excludedButtons = MinimapButtonCollectorPerCharDB.excludedButtons or {}
    MinimapButtonCollectorPerCharDB.excludedButtons[name] = true
    return self:ReleaseButton(name)
end

function ns:IncludeButton(name)
    MinimapButtonCollectorPerCharDB.excludedButtons = MinimapButtonCollectorPerCharDB.excludedButtons or {}
    MinimapButtonCollectorPerCharDB.excludedButtons[name] = nil
    self:ScanButtons()
end

-- Single source of truth for panel ordering. Returns { name, data } entries
-- in render order: first the names in perChar.buttonOrder (skipping any
-- that aren't currently collected, but leaving them in the array so that
-- re-including a previously-excluded button restores its prior slot), then
-- any currently-collected names not yet in buttonOrder, alphabetically,
-- auto-appended to buttonOrder for stable ordering next time.
function ns:GetOrderedButtons()
    local perChar = MinimapButtonCollectorPerCharDB
    perChar.buttonOrder = perChar.buttonOrder or {}
    local order = perChar.buttonOrder

    local seen, result = {}, {}
    for _, name in ipairs(order) do
        seen[name] = true
        if self.collectedButtons[name] then
            result[#result + 1] = { name = name, data = self.collectedButtons[name] }
        end
    end

    local fresh = {}
    for name in pairs(self.collectedButtons) do
        if not seen[name] then fresh[#fresh + 1] = name end
    end
    table.sort(fresh)
    for _, name in ipairs(fresh) do
        order[#order + 1] = name
        result[#result + 1] = { name = name, data = self.collectedButtons[name] }
    end

    return result
end

-- Swap `name` with the nearest *currently-collected* neighbour above/below
-- in buttonOrder. Non-collected names (ghosts from uninstalled addons, or
-- currently-excluded entries holding a slot) are skipped so the user's
-- click always produces a visible move in the panel.
function ns:MoveButtonUp(name)
    local order = MinimapButtonCollectorPerCharDB and MinimapButtonCollectorPerCharDB.buttonOrder
    if not order then return false end
    local myIdx
    for i, n in ipairs(order) do if n == name then myIdx = i; break end end
    if not myIdx then return false end
    for i = myIdx - 1, 1, -1 do
        if self.collectedButtons[order[i]] then
            order[i], order[myIdx] = order[myIdx], order[i]
            return true
        end
    end
    return false
end

function ns:MoveButtonDown(name)
    local order = MinimapButtonCollectorPerCharDB and MinimapButtonCollectorPerCharDB.buttonOrder
    if not order then return false end
    local myIdx
    for i, n in ipairs(order) do if n == name then myIdx = i; break end end
    if not myIdx then return false end
    for i = myIdx + 1, #order do
        if self.collectedButtons[order[i]] then
            order[i], order[myIdx] = order[myIdx], order[i]
            return true
        end
    end
    return false
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
-- preferences, perChar.excludedButtons for per-button "keep on minimap",
-- and perChar.buttonOrder for per-character panel ordering. The v1 table
-- is preserved under _legacy_v1 as a safety net.
local function migrateSavedVariables()
    MinimapButtonCollectorDB        = MinimapButtonCollectorDB or {}
    MinimapButtonCollectorPerCharDB = MinimapButtonCollectorPerCharDB or {}

    local db      = MinimapButtonCollectorDB
    local perChar = MinimapButtonCollectorPerCharDB

    local hadV1Data = db.minimap and db.minimap.minimapPos ~= nil
    local alreadyOnV2 = db.schemaVersion == 2 and perChar.schemaVersion == 2

    db.global = db.global or {}
    db.global.panelAnchor     = db.global.panelAnchor     or "LEFT"
    db.global.panelMaxRows    = db.global.panelMaxRows    or 8
    db.global.autoHideInCombat = db.global.autoHideInCombat == true
    db.global.hoverToOpen     = db.global.hoverToOpen     == true
    if db.global.closeOnOutsideClick == nil then
        db.global.closeOnOutsideClick = true
    end

    perChar.minimap         = perChar.minimap         or {}
    perChar.excludedButtons = perChar.excludedButtons or {}
    perChar.buttonOrder     = perChar.buttonOrder     or {}

    -- v2.0.0 shipped with an always-empty `hiddenButtons` field intended for
    -- a "hide from panel" feature; v2.1.0 pivoted to the "keep on minimap"
    -- primitive (excludedButtons above), so drop the unused stub.
    perChar.hiddenButtons = nil

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
    -- Preserve the raw (case-sensitive) argument while dispatching on the
    -- lowercased command — some subcommands (debug) need the original case
    -- because collectedButtons keys are case-sensitive (e.g. "Gargul").
    local raw   = (msg or ""):match("^%s*(.-)%s*$") or ""
    local lower = raw:lower()

    if lower == "rescan" then
        local added = ns:ScanButtons()
        print("|cff55ff55MBC:|r rescan added " .. added .. " button(s), " .. ns:CountButtons() .. " total.")
    elseif lower == "list" then
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
    elseif lower == "list full" then
        local total = 0
        for name, data in pairs(ns.collectedButtons) do
            print("  " .. name .. "  (" .. data.source .. ")")
            total = total + 1
        end
        print(("|cff55ff55MBC:|r %d button(s) total."):format(total))
    elseif lower == "config" or lower == "settings" then
        if ns.OpenSettings then ns:OpenSettings() end
    elseif lower == "exclude" or lower:match("^exclude%s") then
        local target = raw:match("^%S+%s+(.+)$")
        if not target or target == "" then
            print("|cffffcc55MBC:|r usage: /mbc exclude <ButtonName> — case-sensitive, use /mbc list to see exact names.")
            return
        end
        ns:ExcludeButton(target)
        if ns.RefreshSettings then ns:RefreshSettings() end
        print("|cff55ff55MBC:|r excluded " .. target .. " — it will stay on the minimap.")
    elseif lower == "include" or lower:match("^include%s") then
        local target = raw:match("^%S+%s+(.+)$")
        if not target or target == "" then
            print("|cffffcc55MBC:|r usage: /mbc include <ButtonName>.")
            return
        end
        ns:IncludeButton(target)
        if ns.RefreshSettings then ns:RefreshSettings() end
        print("|cff55ff55MBC:|r re-including " .. target .. " in the panel.")
    elseif lower:match("^debug") then
        local target = raw:match("^%S+%s+(.+)$")
        if not target or target == "" then
            print("|cffffcc55MBC:|r usage: /mbc debug <ButtonName> — case-sensitive, use /mbc list to see exact names.")
            return
        end
        local data = ns.collectedButtons[target]
        if not data then
            print("|cffff5555MBC:|r no collected button named '" .. target .. "'. Try /mbc list (names are case-sensitive).")
        else
            local btn = data.button
            print(("|cff55ff55MBC debug:|r %s  size=%.0fx%.0f  alpha=%.2f  shown=%s  source=%s")
                :format(target, btn:GetWidth() or 0, btn:GetHeight() or 0,
                        btn:GetAlpha() or 0, tostring(btn:IsShown()), data.source))
            for i, region in ipairs({ btn:GetRegions() }) do
                if region.GetObjectType and region:GetObjectType() == "Texture" then
                    local tex = region.GetTexture and region:GetTexture()
                    local r, g, b, a = 1, 1, 1, 1
                    if region.GetVertexColor then
                        r, g, b, a = region:GetVertexColor()
                    end
                    local alpha = region.GetAlpha and region:GetAlpha() or 1
                    print(("  [%d] %s  layer=%s  size=%.0fx%.0f  shown=%s  alpha=%.2f  vc=%.2f,%.2f,%.2f,%.2f  tex=%s")
                        :format(i, region:GetObjectType(),
                                tostring(region:GetDrawLayer()),
                                region:GetWidth() or 0, region:GetHeight() or 0,
                                tostring(region:IsShown()), alpha,
                                r or 1, g or 1, b or 1, a or 1,
                                tostring(tex)))
                end
            end
        end
    elseif lower == "" then
        if ns.ToggleOverlay then ns:ToggleOverlay() end
    else
        print("|cff55ff55MBC:|r unknown command. Try /mbc, /mbc rescan, /mbc list, /mbc config, /mbc exclude <name>, /mbc include <name>, /mbc debug <ButtonName>.")
    end
end
