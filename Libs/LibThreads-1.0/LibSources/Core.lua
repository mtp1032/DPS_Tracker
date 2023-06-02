--------------------------------------------------------------------------------------
-- FILE NAME:		Core.lua
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   25 May, 2023
print("0")
local _, WoWThreads = ...
WoWThreads.Core = {} 
core = WoWThreads.Core
local L = WoWThreads.L
local sprintf = _G.string.format 

core.EMPTY_STR 		= ""
core.SUCCESS 		= true
core.FAILURE 		= false
local C				= core
print("15")
core.DEBUGGING_ENABLED           = true
core.DATA_COLLECTION_ENABLED     = false

local DEBUGGING_ENABLED           = core.DEBUGGING_ENABLED
local DATA_COLLECTION_ENABLED     = core.DATA_COLLECTION_ENABLED

local EMPTY_STR = core.EMPTY_STR
local SUCCESS	= core.SUCCESS
local FAILURE	= core.FAILURE

-- Globals preserved across reloads
core.EXPANSION_NAME 	= nil
core.EXPANSION_LEVEL	= nil

local function setExpansionName()
	core.EXPANSION_LEVEL = GetServerExpansionLevel()

	if core.EXPANSION_LEVEL == LE_EXPANSION_CLASSIC then
		core.EXPANSION_NAME = "Classic (Vanilla)"
	end
	if core.EXPANSION_LEVEL == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
		core.EXPANSION_NAME = "Classic (WotLK)"
	end
	if core.EXPANSION_LEVEL == LE_EXPANSION_DRAGONFLIGHT then
		core.EXPANSION_NAME = "Dragon Flight"
	end

	if isValid == false then
		local errMsg = sprintf("Invalid Expansion Code, %d", core.EXPANSION )
		DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s", errMsg), 1.0, 1.0, 0.0 )
	end
	return core.EXPANSION_LEVEL, core.EXPANSION_NAME
end
print("40")
core.EXPANSION_LEVEL, core.EXPANSION_NAME = setExpansionName()

local function getAddonName()
	local stackTrace = debugstack(2)
	local dirNames = nil
	local addonName = nil

	if 	core.EXPANSION_LEVEL == LE_EXPANSION_DRAGONFLIGHT then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}	end
	if core.EXPANSION_LEVEL == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}
	end
	if core.EXPANSION_LEVEL == LE_EXPANSION_CLASSIC then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}
	end

	addonName = dirNames[1][3]
	return addonName
end

core.ADDON_NAME 	= getAddonName()
core.ADDON_VERSION 	= GetAddOnMetadata( core.ADDON_NAME, "Version")

local errorMsgFrame = nil

function core:prefix( stackTrace )
	if stackTrace == nil then stackTrace = debugstack(2) end
	
	local pieces = {strsplit( ":", stackTrace, 5 )}
	local segments = {strsplit( "\\", pieces[1], 5 )}

	local fileName = segments[#segments]
	
	local strLen = string.len( fileName )
	local fileName = string.sub( fileName, 1, strLen - 2 )
	local names = strsplittable( "\/", fileName )
	local lineNumber = tonumber(pieces[2])
	local location = sprintf("[%s:%d] ", names[#names], lineNumber)
	return location
end
function core:dbgPrint( msg )
	local fileAndLine = core:prefix( debugstack(2) )
	local str = msg
	if str then
		str = sprintf("%s %s", fileAndLine, str )
	else
		str = fileAndLine
	end
	DEFAULT_CHAT_FRAME:AddMessage( str, 0.0, 1.0, 1.0 )
end	
function core:dbgPrintx( ... )
	local prefix = core:prefix( debugstack(2) )
	DEFAULT_CHAT_FRAME:AddMessage( prefix, ... , 0.0, 1.0, 1.0 )

	local str = msg
	if str then
		str = sprintf("%s %s", fileAndLine, str )
	else
		str = fileAndLine
	end
	DEFAULT_CHAT_FRAME:AddMessage( str, 0.0, 1.0, 1.0 )
end	
function core:setResult( errMsg, stackTrace )
	local result = { FAILURE, EMPTY_STR, EMPTY_STR }

	local msg = sprintf("%s %s:\n", core:prefix( stackTrace ), errMsg )
	result[2] = msg

	if stackTrace ~= nil then
		result[3] = stackTrace
	end
	return result
end
function core:postResult( result )
	if errorMsgFrame == nil then
		errorMsgFrame = frames:createErrorMsgFrame("Error Message")
	end

	if result[1] ~= FAILURE then 
		return
	end

	local resultMsg = sprintf("%s:\n%s\n", result[2], result[3])
	errorMsgFrame.Text:Insert( resultMsg )
	errorMsgFrame:Show()
end
function core:displayInfoMsg( msg )
	UIErrorsFrame:AddMessage( msg, 0.0, 1.0, 0.0, 20 ) 
end
-- RETURNS: boolean true if enabled, false otherwise
function core:dataCollectionIsEnabled()
    return DATA_COLLECTION_ENABLED
end
function core:enableDataCollection()
    DATA_COLLECTION_ENABLED = true
    DEFAULT_CHAT_FRAME:AddMessage( "Performance Data Collection is Now ENABLED", 0.0, 1.0, 1.0 )
end
function core:disableDataCollection()
    DATA_COLLECTION_ENABLED = false  
    DEFAULT_CHAT_FRAME:AddMessage( "Performance Data Collection is Now DISABLED", 0.0, 1.0, 1.0 )
end
function core:enableDebugging()
	DEBUGGING_ENABLED = true
	DEFAULT_CHAT_FRAME:AddMessage( "Debugging is Now ENABLED", 0.0, 1.0, 1.0 )
end
function core:disableDebugging()
	DEBUGGING_ENABLED = false
	DEFAULT_CHAT_FRAME:AddMessage( "Debugging is Now DISABLED", 0.0, 1.0, 1.0 )
end
function core:debuggingIsEnabled()
	return DEBUGGING_ENABLED
end
-- Rounds up to integer
function core:roundUp( num)
    return math.ceil( num )
end
local fileName = "Core.lua"
if core:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end

-- local function bottom()
-- 	local result = {SUCCESS, EMPTY_STR, EMPTY_STR }
-- 	result = core:setResult( "Failed in some way", debugstack() )
-- 	return result
-- end
-- local function middle()
-- 	local result = bottom()
-- 	return result
-- end
-- local function top()
-- 	local result = middle()
-- 	return result
-- end

-- local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
-- local result = top()
-- if not result[1] then core:postResult( result ) end
