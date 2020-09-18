--------------------------------------------------------------------------------------
-- Core.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 9 October, 2019
local _, DPS_Tracker = ...
DPS_Tracker.Core = {}
core = DPS_Tracker.Core

local L = DPS_Tracker.L
local sprintf = _G.string.format

-----------------------------------------------------------------------------------------------------------
--                      The infoTable
-----------------------------------------------------------------------------------------------------------

--                      Indices into the infoTable table
local INTERFACE_VERSION = 1	-- string
local BUILD_NUMBER 		= 2		-- string
local BUILD_DATE 		= 3		-- string
local TOC_VERSION		= 4		-- number
local ADDON_C_NAME 		= 5		-- string

local infoTable = { GetBuildInfo() }			-- BLIZZ
infoTable[ADDON_C_NAME] = L["ADDON_NAME"]

--****************************************************************************************
--                      Game/Build/AddOn Info (from Blizzard's GetBuildInfo())
--****************************************************************************************
function core:getAddonName()
	return infoTable[ADDON_C_NAME]
end
function core:getReleaseVersion()
    return infoTable[INTERFACE_VERSION]
end
function core:getBuildNumber()
    return infoTable[BUILD_NUMBER]
end
function core:getBuildDate()
    return infoTable[BUILD_DATE]
end
function core:getTocVersion()
    return infoTable[TOC_VERSION]	// e.g., 90001
end

