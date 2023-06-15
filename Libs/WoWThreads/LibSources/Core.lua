--------------------------------------------------------------------------------------
-- FILE NAME:		Core.lua
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   25 May, 2023
local _, WoWThreads = ...
WoWThreads.Core = {} 
libcore = WoWThreads.Core

local L = WoWThreads.L
local sprintf = _G.string.format 

libcore.EMPTY_STR 		= ""
libcore.SUCCESS 		= true
libcore.FAILURE 		= false
libcore.DEBUGGING_ENABLED           = true
libcore.DATA_COLLECTION_ENABLED     = false

local DEBUGGING_ENABLED           = libcore.DEBUGGING_ENABLED
local DATA_COLLECTION_ENABLED     = libcore.DATA_COLLECTION_ENABLED

local EMPTY_STR = libcore.EMPTY_STR
local SUCCESS	= libcore.SUCCESS
local FAILURE	= libcore.FAILURE

-- Globals preserved across reloads
libcore.EXPANSION_NAME 	= nil
libcore.EXPANSION_LEVEL	= nil

local function setExpansionName()
	libcore.EXPANSION_LEVEL = GetServerExpansionLevel()

	if libcore.EXPANSION_LEVEL == LE_EXPANSION_CLASSIC then
		libcore.EXPANSION_NAME = "Classic (Vanilla)"
	end
	if libcore.EXPANSION_LEVEL == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
		libcore.EXPANSION_NAME = "Classic (WotLK)"
	end
	if libcore.EXPANSION_LEVEL == LE_EXPANSION_DRAGONFLIGHT then
		libcore.EXPANSION_NAME = "Dragon Flight"
	end

	if isValid == false then
		local errMsg = sprintf("Invalid Expansion Code, %d", libcore.EXPANSION )
		DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s", errMsg), 1.0, 1.0, 0.0 )
	end
	return libcore.EXPANSION_LEVEL, libcore.EXPANSION_NAME
end
libcore.EXPANSION_LEVEL, libcore.EXPANSION_NAME = setExpansionName()

local function getAddonName()
	local stackTrace = debugstack(2)
	local dirNames = nil
	local addonName = nil

	if 	libcore.EXPANSION_LEVEL == LE_EXPANSION_DRAGONFLIGHT then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}	end
	if libcore.EXPANSION_LEVEL == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}
	end
	if libcore.EXPANSION_LEVEL == LE_EXPANSION_CLASSIC then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}
	end

	addonName = dirNames[1][3]
	return addonName
end

libcore.ADDON_NAME 	= getAddonName()
libcore.ADDON_VERSION 	= GetAddOnMetadata( libcore.ADDON_NAME, "Version")

local errorMsgFrame = nil

function libcore:dbgPrefix( stackTrace )
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
function libcore:dbgPrint( msg )
	local fileAndLine = libcore:dbgPrefix( debugstack(2) )
	local str = msg
	if str then
		str = sprintf("%s %s", fileAndLine, str )
	else
		str = fileAndLine
	end
	DEFAULT_CHAT_FRAME:AddMessage( str, 0.0, 1.0, 1.0 )
end	
function libcore:dbgPrintx( ... )
	local prefix = libcore:dbgPrefix( debugstack(2) )
	DEFAULT_CHAT_FRAME:AddMessage( prefix, ... , 0.0, 1.0, 1.0 )

	local str = msg
	if str then
		str = sprintf("%s %s", fileAndLine, str )
	else
		str = fileAndLine
	end
	DEFAULT_CHAT_FRAME:AddMessage( str, 0.0, 1.0, 1.0 )
end	
function libcore:setResult( errMsg, stackTrace )
	local result = { FAILURE, EMPTY_STR, EMPTY_STR }

	local msg = sprintf("%s %s:\n", libcore:dbgPrefix( stackTrace ), errMsg )
	result[2] = msg

	if stackTrace ~= nil then
		result[3] = stackTrace
	end
	return result
end
function libcore:postResult( result )
	if errorMsgFrame == nil then
		errorMsgFrame = threadframes:createErrorMsgFrame("Error Message")
	end

	if result[1] ~= FAILURE then 
		return
	end

	local resultMsg = sprintf("%s:\n%s\n", result[2], result[3])
	errorMsgFrame.Text:Insert( resultMsg )
	errorMsgFrame:Show()
end
function libcore:displayInfoMsg( msg )
	UIErrorsFrame:AddMessage( msg, 0.0, 1.0, 0.0, 20 ) 
end
-- RETURNS: boolean true if enabled, false otherwise
function libcore:dataCollectionIsEnabled()
    return DATA_COLLECTION_ENABLED
end
function libcore:enableDataCollection()
    DATA_COLLECTION_ENABLED = true
    DEFAULT_CHAT_FRAME:AddMessage( "Performance Data Collection is Now ENABLED", 0.0, 1.0, 1.0 )
end
function libcore:disableDataCollection()
    DATA_COLLECTION_ENABLED = false  
    DEFAULT_CHAT_FRAME:AddMessage( "Performance Data Collection is Now DISABLED", 0.0, 1.0, 1.0 )
end
function libcore:enableDebugging()
	DEBUGGING_ENABLED = true
	DEFAULT_CHAT_FRAME:AddMessage( "Debugging is Now ENABLED", 0.0, 1.0, 1.0 )
end
function libcore:disableDebugging()
	DEBUGGING_ENABLED = false
	DEFAULT_CHAT_FRAME:AddMessage( "Debugging is Now DISABLED", 0.0, 1.0, 1.0 )
end
function libcore:debuggingIsEnabled()
	return DEBUGGING_ENABLED
end
-- Rounds up to integer
function libcore:roundUp( num)
    return math.ceil( num )
end
local fileName = "Core.lua"
if libcore:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
