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

	L["ADDON_NAME"]				= base.ADDON_NAME
	L["VERSION"]				= base.ADDON_VERSION
	L["EXPANSION_NAME"]			= base.EXPANSION_NAME
	L["ADDON_AND_VERSION"] 		= sprintf("%s (v%s %s)", L["ADDON_NAME"], L["VERSION"], L["EXPANSION_NAME"] )
	L["ADDON_LOADED_MSG"]		= sprintf("%s loaded (Use /dps for help).", L["ADDON_AND_VERSION"])

	L["CLEU_MSG_FRAME"]			= "DPS_Tracker Event Log"
	L["USER_MSG_FRAME"]			= sprintf("%s %s", L["ADDON_AND_VERSION"], "Encounter Report(s)")
	L["ERROR_MSG_FRAME"]		= sprintf("%s Error Messages", L["ADDON_NAME"])

	L["SELECT_BUTTON"]		= "Select"
	L["RESET_BUTTON"]		= "Reset"
	L["RELOAD_BUTTON"]		= "Reload UI"
	L["CLEAR_BUTTON"]		= "Clear"
end

local fileName = "EnUS_DPS_Tracker.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s", L["ADDON_LOADED_MSG"]), 1.0, 1.0, 0.0)
end
