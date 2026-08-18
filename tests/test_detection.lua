-- Runnable check for the minimap-button detection in Core.lua.
--
--   lua tests/test_detection.lua        (from the repo root)
--
-- Stubs just enough of the WoW API to load Core.lua and drive ns:ScanButtons()
-- against fake minimap children. It exists because the detection is all branches
-- and none of them are observable in-game without installing the addon that
-- trips them: the Method Raid Tools case below is the exact bug reported on
-- CurseForge, and it would silently come back the moment someone "tidies up"
-- the LibDBIcon filter into a name check again.

local failures = 0
local function check(label, ok)
    if ok then
        print("  ok   " .. label)
    else
        print("  FAIL " .. label)
        failures = failures + 1
    end
end

--------------------------------------------------------------------------------
-- WoW API stubs
--------------------------------------------------------------------------------

local function newTexture(layer)
    return {
        GetObjectType = function() return "Texture" end,
        GetDrawLayer  = function() return layer or "ARTWORK" end,
        Show          = function() end,
    }
end

-- HasScript answers by widget type (does this widget kind support the script),
-- GetScript by assigned handler. Buttons support OnClick, plain Frames do not.
local SUPPORTED = {
    Button = { OnClick = true, OnMouseUp = true, OnMouseDown = true },
    Frame  = { OnMouseUp = true, OnMouseDown = true },
}

local function newFrame(opts)
    opts = opts or {}
    local f = {
        _name     = opts.name,
        _type     = opts.objType or "Button",
        _w        = opts.w or 32,
        _h        = opts.h or 32,
        _shown    = opts.shown ~= false,
        _scripts  = opts.scripts or {},
        _regions  = opts.regions or { newTexture("ARTWORK") },
        _children = {},
        _parent   = opts.parent,
    }

    function f:GetName()       return self._name end
    function f:GetObjectType() return self._type end
    function f:GetWidth()      return self._w end
    function f:GetHeight()     return self._h end
    function f:GetAlpha()      return 1 end
    function f:IsShown()       return self._shown end
    function f:IsForbidden()   return false end
    function f:GetParent()     return self._parent end
    function f:GetRegions()    return table.unpack(self._regions) end
    function f:GetChildren()   return table.unpack(self._children) end
    function f:GetPoint()      return "CENTER", nil, "CENTER", 0, 0 end
    function f:HasScript(s)    return SUPPORTED[self._type][s] == true end
    function f:GetScript(s)    return self._scripts[s] end
    function f:Show()          self._shown = true end
    function f:Hide()          self._shown = false end

    if opts.parent then table.insert(opts.parent._children, f) end
    return f
end

UIParent        = newFrame({ name = "UIParent" })
Minimap         = newFrame({ name = "Minimap" })
MinimapBackdrop = newFrame({ name = "MinimapBackdrop" })

local click = { OnClick = function() end }
local mouse = { OnMouseUp = function() end }

-- The reported bug. MRT names its button after LibDBIcon's convention so that
-- name-scanning collectors pick it up, but never registers with the library:
-- it is absent from lib.objects AND was being skipped by the name filter.
local mrt = newFrame({ name = "LibDBIcon10_MethodRaidTools", parent = Minimap, scripts = mouse })

-- A genuine LibDBIcon button: the registry pass owns it, the frame walk must not
-- adopt it a second time under its frame name.
local gargul = newFrame({ name = "LibDBIcon10_Gargul", parent = Minimap, scripts = click })

local handmade  = newFrame({ name = "ZygorMinimapButton", parent = MinimapBackdrop, objType = "Frame", scripts = mouse })
local blizzard  = newFrame({ name = "MiniMapTracking", parent = MinimapBackdrop, scripts = click })
local hidden    = newFrame({ name = "HiddenAddonButton", parent = Minimap, scripts = click, shown = false })
local toosmall  = newFrame({ name = "TinyAddonButton", parent = Minimap, scripts = click, w = 8, h = 8 })
local textureless = newFrame({ name = "BareAddonButton", parent = Minimap, scripts = click, regions = {} })
local anonymous = newFrame({ name = nil, parent = Minimap, scripts = click })

local libObjects = { Gargul = gargul }
function LibStub(_, _) return { objects = libObjects } end
function hooksecurefunc() end
function CreateFrame() return { RegisterEvent = function() end, SetScript = function() end } end
SlashCmdList = {}

--------------------------------------------------------------------------------
-- Load Core.lua with our own namespace table and run one scan
--------------------------------------------------------------------------------

local ns = {}
assert(loadfile("Core.lua"))("MinimapButtonCollector", ns)
ns:ScanButtons()

local collected = ns.collectedButtons
local function got(name) return collected[name] ~= nil end

print("detection:")
check("Method Raid Tools is collected (LibDBIcon-named but unregistered)", got("LibDBIcon10_MethodRaidTools"))
check("...as a minimap child, so ReleaseButton restores it by point",
      got("LibDBIcon10_MethodRaidTools") and collected["LibDBIcon10_MethodRaidTools"].source == "minimap-child")
check("registered LibDBIcon button is collected under its registry key", got("Gargul"))
check("...and not a second time under its frame name", not got("LibDBIcon10_Gargul"))
check("Frame-based button on MinimapBackdrop is collected", got("ZygorMinimapButton"))
check("Blizzard frame is skipped", not got("MiniMapTracking"))
check("button hidden by its own addon is skipped", not got("HiddenAddonButton"))
check("undersized frame is skipped", not got("TinyAddonButton"))
check("frame with no texture is skipped", not got("BareAddonButton"))
check("nothing else slipped through (MRT + Gargul + Zygor)", ns:CountButtons() == 3)

--------------------------------------------------------------------------------
-- The scan-debug callback must see every frame examined, with a reason
--------------------------------------------------------------------------------

local seen = {}
ns:ScanButtons(function(parentName, frame, name, reason)
    seen[#seen + 1] = { parent = parentName, name = name, reason = reason }
end)

local byName = {}
for _, e in ipairs(seen) do byName[e.name or "<unnamed>"] = e end

print("scan-debug:")
check("reports every child of both parents", #seen == 8)
check("names the parent it was found under", byName["ZygorMinimapButton"].parent == "MinimapBackdrop")
check("gives a reason for a rejected frame", byName["TinyAddonButton"].reason ~= nil)
check("reports an already-collected button as such", byName["LibDBIcon10_MethodRaidTools"].reason == "already collected")
check("reports the unnamed frame without erroring", byName["<unnamed>"].reason == "no global name")

print(failures == 0 and "\nall checks passed" or ("\n" .. failures .. " check(s) failed"))
os.exit(failures == 0 and 0 or 1)
