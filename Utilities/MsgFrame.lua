--------------------------------------------------------------------------------------
-- MsgFrame.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 16 April, 2023
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ... 
DPS_Tracker.MsgFrame = {}
mf = DPS_Tracker.MsgFrame
local sprintf = _G.string.format
local L = DPS_Tracker.L

local SUCCESS	= base.SUCCESS
local FAILURE	= base.FAILURE

local frameTitle = L["USER_MSG_FRAME"]

local errorMsgFrame 	= display:createErrorMsgFrame( L["ERROR_MSG_FRAME"])
local userMsgFrame 		= display:createMsgFrame( L["USER_MSG_FRAME"] )
local combatMsgFrame	= display:createMsgFrame( L["CLEU_MSG_FRAME"])

function mf:postMsg( msg )
	display:showFrame( userMsgFrame )
	userMsgFrame.Text:Insert( msg )
end
function mf:postLogEntry( logEntry )
	display:showFrame( combatMsgFrame )
	combatMsgFrame.Text:Insert( logEntry )
end
function mf:postResult( result )
	local status = nil
	if result[1] ~= FAILURE then 
		return
	end
	local topLine = sprintf("[%s] %s: %s\n", "FAILURE", result[2], result[3])
	errorMsgFrame.Text:Insert( topLine )
	if errorMsgFrame:IsVisible() == false then
		errorMsgFrame:Show()
	end
end

local fileName = "MsgFrame.lua"

if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end