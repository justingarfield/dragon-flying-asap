---------------------------------------------------------
-- Debugging
---------------------------------------------------------
local showDebugStatements = true
local showDebugVals = true
local showEventStatements = false

local _, namespace = ...

function namespace:debugIt(...)
    if showDebugStatements then
        DragonFlyingASAP:Print(...)
    end
end

function namespace:debugVals(...)
    if showDebugVals then
        DragonFlyingASAP:Print(...)
    end
end

function namespace:eventIt(...)
    if showEventStatements then
        DragonFlyingASAP:Print(...)
    end
end
