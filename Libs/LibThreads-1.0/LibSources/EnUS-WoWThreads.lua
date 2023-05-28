----------------------------------------------------------------------------------------
-- EnUS-WoWThreads.lua
-- AUTHOR: mtpeterson1948 at gmail dot com
-- ORIGINAL DATE: 10 October, 2022
----------------------------------------------------------------------------------------
local _, WoWThreads = ...
WoWThreads.EnUS = {}

local L = setmetatable({}, { __index = function(t, k) 
	local v = tostring(k)
	rawset(t, k, v)
	return v
end })

WoWThreads.L = L 
local sprintf = _G.string.format

-- English translations

local addonName 	= core.ADDON_NAME 
local addonVersion 	= core.ADDON_VERSION
local expansionName = core.EXPANSION_NAME
local clockInterval	= 1/GetFramerate() * 1000
local msPerTick 	= sprintf("Clock interval: %0.01f milliseconds per tick.\n", clockInterval )

local LOCALE = GetLocale()      -- BLIZZ: this is case-sensitive and returns "enUS"
if LOCALE == "enUS" then

	-- WoWThreads Localizations
	L["EXPANSION"] 				= expansionName
	L["ADDON_NAME"]				= addonName
	L["VERSION"] 				= addonVersion

	L["ADDON_NAME_AND_VERSION"] = sprintf("%s %s %s", L["ADDON_NAME"], L["VERSION"],L["EXPANSION"] )
	L["ADDON_LOADED_MESSAGE"] 	= sprintf("%s loaded", L["ADDON_NAME_AND_VERSION"] )
	L["MS_PER_TICK"] 			= sprintf("Clock interval: %0.01f milliseconds per tick\n", clockInterval )

	L["LEFTCLICK_FOR_OPTIONS_MENU"]	= "Left click for options menu."
	L["RIGHTCLICK_SHOW_COMBATLOG"]	= "Right click for fun"
	L["SHIFT_LEFTCLICK_DISMISS_COMBATLOG"] = "Some other function."
	L["SHIFT_RIGHTCLICK_ERASE_TEXT"]	= "Yet another function"

--[[ 	
	local title = sprintf("%s",L["ADDON_NAME_AND_VERSION"] )
	local s1 = sprintf("  %s enable developers to incorporate multithreaded, asynchronous,\n", L["ADDON_NAME"])
	local s2 = sprintf("  and non-preemptive semantics into WoW addons. %s can\n", L["ADDON_NAME"])
	local s3 = sprintf("  increase an addon’s concurrency and reduce coding complexity\n")
	L["TITLE_WOWTHREADS"] = sprintf("              %s\n\n", title)
	L["ABOUT_WOWTHREADS"] = sprintf("%s%s%s", s1, s2, s3 )
	L["WOWTHREADS_TEST"] = sprintf("Tests: %s", L["ADDON_NAME"])
	L["RUN_BASIC_TEST1"] = sprintf("Run basic tests in file BasicTest.lua")
	
	L["PERFORMANCE_DATA_COLLECTION"] 			= "Enable thread-specific performance data collection? "
	L["TOOLTIP_PERFORMANCE_DATA_COLLECTION"] 	= "Off by default. "
 ]]	
 
 	-- Generic Error MessageS
	L["INPUT_PARM_NIL"]		= "[ERROR] Input parameter nil "
	L["INVALID_TYPE"]		= "[ERROR] Input datatype invalid . "
	L["PARAM_ILL_FORMED"]	= "[ERROR] Input paramter improperly formed. "
	L["ENTRY_NOT_FOUND"]	= "[ERROR] Entry in thread performance table not found. "

	-- Thread specific messages
	L["THREAD_HANDLE_NIL"] 				= "[ERROR] Thread handle nil. "
	L["HANDLE_ELEMENT_IS_NIL"]			= "[ERROR] Thread handle element is nil. "
	L["HANDLE_NOT_TABLE"] 				= "[ERROR] Thread handle not a table. "
	L["HANDLE_NOT_FOUND"]				= "[ERROR] handle not found in thread control block."
	L["HANDLE_INVALID_TABLE_SIZE"] 		= "[ERROR] Thread handle size invalid. "
	L["HANDLE_COROUTINE_NIL"]			= "[ERROR] Thread coroutine in handle is nil. "
	L["INVALID_COROUTINE_TYPE"]			= "[ERROR] Thread coroutine is not a thread. "
	L["INVALID_COROUTINE_STATE"]		= "[ERROR] Unknown or invalid coroutine state. "
	L["THREAD_RESUME_FAILED"]			= "[ERROR] Thread was dead. Resumption failed. "
	L["THREAD_STATE_INVALID"]			= "[ERROR] Operation failed. Thread state does not support the operation. "

	L["SIGNAL_OUT_OF_RANGE"]			= "[ERROR] Signal is invalid (out of range) "
	L["SIGNAL_ILLEGAL_OPERATION"]		= "[WARNING] Cannot signal a completed thread. "
	L["RUNNING_THREAD_NOT_FOUND"]		= "[ERROR] Failed to retrieve running thread. "
	L["THREAD_INVALID_CONTEXT"] 		= "[ERROR] Operation requires thread context. "
	L["DEBUGGING_NOT_ENABLED"]			= "[ERROR] Debugging has not been enabled. "
	L["DATA_COLLECTION_NOT_ENABLED"]	= "[ERROR] Data collection has not been enabled. "

	L["ASSERT"]	= "ASSERT FAILED: "
end

local fileName = "EnUS-WoWThreads.lua"
if core:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
