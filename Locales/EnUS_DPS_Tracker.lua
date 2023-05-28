----------------------------------------------------------------------------------------
-- EnUS_DPS_Tracker.lua
-- AUTHOR: mtpeterson1948 at gmail dot com
-- ORIGINAL DATE: 28 December, 2018
----------------------------------------------------------------------------------------

local _, DPS_Tracker = ...
DPS_Tracker.EnUS_DPS_Tracker = {}

local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end })

DPS_Tracker.L = L
local sprintf = _G.string.format

-- English translations
local LOCALE = GetLocale()      -- BLIZZ
if LOCALE == "enUS" then

	L["ADDON_NAME"]							= base.ADDON_NAME
	L["VERSION"]							= base.ADDON_VERSION
	L["EXPANSION_NAME"]						= base.EXPANSION_NAME
	L["ADDON_AND_VERSION"] 					= sprintf("%s (v%s %s)", L["ADDON_NAME"], L["VERSION"], L["EXPANSION_NAME"] )

	L["ERROR_MSG_FRAME_TITLE"]			= "Error"
	L["USER_MSG_FRAME"]					= sprintf("%s %s", L["ADDON_AND_VERSION"], "Encounter Report(s)")
	L["LEFT_CLICK_FOR_OPTIONS_MENU"] 	= "Left Click to display In-Game Options Menu."
	L["HELP_FRAME_TITLE"]				= sprintf("Help: %s", L["ADDON_AND_VERSION"])
	L["ADDON_LOADED_MSG"]				= sprintf("%s loaded (Use /dps for help).", L["ADDON_AND_VERSION"])
	L["PROMPT_ENABLE_LOGGING"] 			= "Check to enable combat logging?"
	L["ENABLE_LOGGING_TOOLTIP"] 		= sprintf("If checked %s will produce a real-time combat log. ", base.ADDON_NAME )

	-- DPS_Tracker Specific
	L["ADVANCED_COMBAT_LOGGING_ENABLED"]	= sprintf("%s", "Advanced Combat Logging Enabled")
	L["ADVANCED_COMBAT_LOGGING_DISABLED"]	= sprintf("%s", "Advanced Combat Logging Disabled")
	L["LEFTCLICK_FOR_OPTIONS_MENU"]			= sprintf( "Left click to display the %s Options Menu.", L["ADDON_NAME"] )
	L["RIGHTCLICK_SHOW_COMBATLOG"]			= "Right click to display the combat log window."
	L["SHIFT_LEFTCLICK_DISMISS_COMBATLOG"]	= "Shift-Left click to dismiss the combat log window."
	L["SHIFT_RIGHTCLICK_ERASE_TEXT"]		= "Shift-Right click to erase the text in the combat log window."

	L["SELECT_BUTTON_TEXT"]					= "Select"
	L["RESET_BUTTON_TEXT"]					= "Reset"
	L["RELOAD_BUTTON_TEXT"]					= "Reload"
	L["CLEAR_BUTTON_TEXT"]					= "Clear"

	L["PROMPT_ENABLE_ADDON"] = sprintf("Disable %s", L["ADDON_NAME"])
	L["ENABLE_ADDON_TOOLTIP"] = sprintf("Checking this box disables %s.", L["ADDON_NAME"])

	L["DSCR_SUBHEADER"] = "A Simple, Yet Powerful, Personal Damage Meter"

	L["LINE1"]			= sprintf("By default, %s will display only an encounter's summary.",  L["ADDON_NAME"])
	L["LINE2"] 			= "However, you may enable combat logging (see checkbox below) so that"
	L["LINE3"] 			= sprintf("%s will display a detailed combat log for every event.",  L["ADDON_NAME"])
	L["LINE4"]			= "NOTE: this is very memory intensive. But if you need to see the"
	L["LINE5"] 			= "nitty-gritty details of the fight, check the box below."

    L["ERROR_MSG"]            	= "[ERROR] %s"	
	L["INFO_MSG"]				= "[INFO] %s"

	L["PARAM_NIL"]				= "Invalid Parameter - Was nil."
	L["PARAM_OUTOFRANGE"]		= "Invalid Parameter - Out-of-range."
	L["PARAM_WRONGTYPE"]		= "Invalid Parameter - Wrong type."
	L["PARAM_ILL_FORMED"]	= "[ERROR] Input paramter improperly formed. "

	-- WoWThreads Localizations
	local clockInterval	= 1/GetFramerate() * 1000
	L["MS_PER_TICK"] 			= sprintf("Clock interval: %0.01f milliseconds per tick\n", clockInterval )
	L["LEFTCLICK_FOR_OPTIONS_MENU"]	= "Left click for options menu."
	L["RIGHTCLICK_SHOW_COMBATLOG"]	= "Right click for fun"
	L["SHIFT_LEFTCLICK_DISMISS_COMBATLOG"] = "Some other function."
	L["SHIFT_RIGHTCLICK_ERASE_TEXT"]	= "Yet another function"
	
	L["PERFORMANCE_DATA_COLLECTION"] 			= "Enable thread-specific performance data collection? "
	L["TOOLTIP_PERFORMANCE_DATA_COLLECTION"] 	= "Off by default. "

	-- Thread specific messages
	L["THREAD_HANDLE_NIL"] 				= "[ERROR] Thread handle nil. "
	L["HANDLE_ELEMENT_IS_NIL"]		= "[ERROR] Thread handle element is nil. "
	L["HANDLE_NOT_TABLE"] 			= "[ERROR] Thread handle not a table. "
	L["HANDLE_NOT_FOUND"]			= "[ERROR] handle not found in thread control block."
	L["HANDLE_INVALID_TABLE_SIZE"] 	= "[ERROR] Thread handle size invalid. "
	L["HANDLE_COROUTINE_NIL"]		= "[ERROR] Thread coroutine in handle is nil. "
	L["INVALID_COROUTINE_TYPE"]		= "[ERROR] Thread coroutine is not a thread. "
	L["INVALID_COROUTINE_STATE"]	= "[ERROR] Unknown or invalid coroutine state. "
	L["THREAD_RESUME_FAILED"]		= "[ERROR] Thread was dead. Resumption failed. "
	L["THREAD_STATE_INVALID"]		= "[ERROR] Operation failed. Thread state does not support the operation. "

	L["SIGNAL_OUT_OF_RANGE"]		= "[ERROR] Signal is invalid (out of range) "
	L["SIGNAL_ILLEGAL_OPERATION"]	= "[WARNING] Cannot signal a completed thread. "
	L["RUNNING_THREAD_NOT_FOUND"]	= "[ERROR] Failed to retrieve running thread. "
	L["THREAD_INVALID_CONTEXT"] 	= "[ERROR] Operation requires thread context. "
	L["DEBUGGING_NOT_ENABLED"]		= "[ERROR] Debugging has not been enabled. "
	L["DATA_COLLECTION_NOT_ENABLED"]	= "[ERROR] Data collection has not been enabled. "
end

local fileName = "EnUS_DPS_Tracker.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s", L["ADDON_LOADED_MSG"]), 1.0, 1.0, 0.0)
end
