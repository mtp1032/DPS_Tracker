----------------------------------------------------------------------------------------
-- enUS.lua
-- AUTHOR: mtpeterson1948 at gmail dot com
-- ORIGINAL DATE: 28 December, 2018
----------------------------------------------------------------------------------------

local _, DPS_Tracker = ...
DPS_Tracker.enUS = {}
en = DPS_Tracker.enus

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

	L["ADDON_NAME"]							= "DPS_Tracker"
	L["VERSION"]							= "V1.0 (ShadowLands)"
	L["ADDON_AND_VERSION"] 					= sprintf("%s %s", L["ADDON_NAME"], L["VERSION"] )
	L["ADVANCED_COMBAT_LOGGING_ENABLED"]	= sprintf("%s", "Advanced Combat Logging Enabled")
	L["ADVANCED_COMBAT_LOGGING_DISABLED"]	= sprintf("%s", "Advanced Combat Logging Disabled")

	L["ERROR_MSG_FRAME_TITLE"]			= "Error"
	L["USER_MSG_FRAME"]					= sprintf("%s %s", L["ADDON_AND_VERSION"], "User Messages")
	L["LEFT_CLICK_FOR_OPTIONS_MENU"] 	= "Left Click to display In-Game Options Menu."
	L["HELP_FRAME_TITLE"]				= sprintf("Help: %s", L["ADDON_AND_VERSION"])
	L["ADDON_LOADED_MSG"]				= sprintf("%s loaded (Use /dps for help).", L["ADDON_AND_VERSION"])
	L["PROMPT_ENABLE_LOGGING"] 			= "Enable combat logging?"
	L["ENABLE_LOGGING_TOOLTIP"] 		= "In addition to the summary, enable logging to display a record of each combat event."

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

	L["DESCR_SUBHEADER"] = "A Simple, Yet Powerful, Personal Damage Meter"

	L["LINE1"]			= sprintf("By default, %s will display only an encounter's summary.",  L["ADDON_NAME"])
	L["LINE2"] 			= "However, you may enable combat logging (see checkbox below) so that"
	L["LINE3"] 			= sprintf("%s will display a detailed combat log for every event.",  L["ADDON_NAME"])
	L["LINE4"]			= "NOTE: this is very memory intensive. But if you need to see the"
	L["LINE5"] 			= "nitty-gritty details of the fight, check the box below."

    L["ERROR_MSG"]            	= "[ERROR] %s"	
	L["INFO_MSG"]				= "[INFO] %s"
	L["UNIT_TESTS"]				= 	sprintf( "%s - %s", L["ADDON_AND_VERSION"], "Unit Tests")

	L["PARAM_NIL"]				= "Invalid Parameter - Was nil."
	L["PARAM_OUTOFRANGE"]		= "Invalid Parameter - Out-of-range."
	L["PARAM_WRONGTYPE"]		= "Invalid Parameter - Wrong type."
	L["UNEXPECTED_RETURN_VALUE"] = "Unexpected Return Value"
	
	return 
end
