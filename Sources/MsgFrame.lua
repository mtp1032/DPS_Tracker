--------------------------------------------------------------------------------------
-- MsgFrame.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 12 January, 2019
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.MsgFrame = {}
mf = DPS_Tracker.MsgFrame
local sprintf = _G.string.format
local L = DPS_Tracker.L
local E = errors

local frameTitle = L["USER_MSG_FRAME"]
local msgFrame = fm:createMsgFrame( frameTitle)

function mf:getMsgFrame()
	return msgFrame
end

function mf:showFrame()
	fm:showFrame( msgFrame )
end
function mf:hideMeter()
	fm:hideMeter( msgFrame )
end
function mf:postMsg( msg )
	fm:showFrame( msgFrame )
	msgFrame.Text:Insert( msg )
end
