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

local LOGGIN_ENABLED = false
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
function cl:enableLogging()
	LOGGING_ENABLED = true
end
function cl:disableLogging()
	LOGGING_ENABLED = false
end
function cl:postLogEntry( logEntry )
	if LOGGING_ENABLED then
		combatEventLog.Text:Insert( logEntry )
	end
end
------------------------------------------------
-- cl:postLogEntry( "postLogEntry() test 1")

