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

local function isUsable(frame)
    if not frame then return false end
    if frame.IsForbidden and frame:IsForbidden() then return false end
    return true
end

local function looksLikeAddonButton(frame)
    if frame == UIParent or frame == Minimap then return false end

    local objType = frame:GetObjectType()
    local clickable = objType == "Button" or frame:HasScript("OnClick")
    if not clickable then return false end

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
        point = { button:GetPoint() },
        source = source,
        hooked = false,
    }
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
           and not self.collectedButtons[name]
           and looksLikeAddonButton(child) then
            if self:AdoptButton(name, child, "minimap-child") then
                added = added + 1
            end
        end
    end

    return added
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        MinimapButtonCollectorDB = MinimapButtonCollectorDB or {}
        MinimapButtonCollectorDB.minimap = MinimapButtonCollectorDB.minimap or {}
    elseif event == "PLAYER_ENTERING_WORLD" then
        ns:ScanButtons()
        C_Timer.After(2,  function() ns:ScanButtons() end)
        C_Timer.After(5,  function() ns:ScanButtons() end)
        C_Timer.After(10, function() ns:ScanButtons() end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        if ns.state.isOpen and ns.CloseOverlay then
            ns:CloseOverlay(true)
        end
    end
end)

SLASH_MBC1 = "/mbc"
SlashCmdList["MBC"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""

    if msg == "rescan" then
        local added = ns:ScanButtons()
        print("|cff55ff55MBC:|r rescan added " .. added .. " button(s), " .. ns:CountButtons() .. " total.")
    elseif msg == "list" then
        local total = 0
        for name, data in pairs(ns.collectedButtons) do
            print("  " .. name .. "  (" .. data.source .. ")")
            total = total + 1
        end
        print("|cff55ff55MBC:|r " .. total .. " button(s) collected.")
    elseif msg == "" then
        if ns.ToggleOverlay then ns:ToggleOverlay() end
    else
        print("|cff55ff55MBC:|r unknown command. Try /mbc, /mbc rescan, /mbc list.")
    end
end
