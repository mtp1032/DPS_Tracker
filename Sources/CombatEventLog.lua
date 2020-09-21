--------------------------------------------------------------------------------------
-- CombatEventLogDisplaylua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 12 January, 2019
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.CombatEventLogDisplay = {}
local L = DPS_Tracker.L
cl = DPS_Tracker.CombatEventLogDisplay
local sprintf = _G.string.format
local E = errors

local LOGGING_ENABLED = false
local combatEventLog = fm:createCombatEventLog( L["ADDON_AND_VERSION"] )

function cl:getCombatEventLogFrame()
	return combatEventLog
end
function cl:hideFrame()
    fm:hideFrame( combatEventLog )
end
function cl:showFrame()
    fm:showFrame( combatEventLog )
end
function cl:clearFrameText()
    fm:clearFrameText( combatEventLog )
end
function cl:enableCombatLogging()
	LOGGING_ENABLED = true
end
function cl:disableCombatLogging()
	LOGGING_ENABLED = false
end
function cl:isCombatLoggingEnabled()
	return LOGGING_ENABLED
end
function cl:setCombatLogging( isLogging )
	LOGGING_ENABLED = isLogging
end
function cl:postLogEntry( logEntry )
	E:where( tostring( LOGGING_ENABLED ))
	if LOGGING_ENABLED then
		combatEventLog.Text:Insert( logEntry )
	end
end
------------------------------------------------
-- cl:postLogEntry( "postLogEntry() test 1")

