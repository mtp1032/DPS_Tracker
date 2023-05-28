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

local frameTitle = L["USER_MSG_FRAME"]
local msgFrame = frames:createMsgFrame( frameTitle)
local frameTitle = sprintf("%s %s", L["ADDON_AND_VERSION"], L["ERROR_MSG_FRAME_TITLE"])
local errorMsgFrame = frames:createErrorMsgFrame(frameTitle)

function mf:getMsgFrame()
	return msgFrame
end
function mf:showFrame()
	frames:showFrame( msgFrame )
end
function mf:eraseText() 
	frames:clearFrame( msgFrame )
end
function mf:hideFrame()
	frames:hideFrame( msgFrame )
end

function mf:hideMeter()
	frames:hideMeter( msgFrame )
end
function mf:showMeter()
    if errorMsgFrame == nil then
        return
	end
	if errorMsgFrame:IsVisible() == false then
		errorMsgFrame:Show()
	end
end
function mf:postMsg( msg )
	frames:showFrame( msgFrame )
	msgFrame.Text:Insert( msg )
end
function mf:postResult( result )
	local status = nil
	if result[1] ~= STATUS_C_FAILURE then 
		return
	end
	local topLine = sprintf("[%s] %s: %s\n", "FAILURE", result[2], result[3])
	errorMsgFrame.Text:Insert( topLine )
	mf:showMeter()
end
function mf:clearText()
	fm:clearFrameText()
end

local fileName = "MsgFrame.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
-- [string "@Interface/AddOns/   DPS_Tracker/LibUtils/MsgFrame.lua"]:64: in function <Interface/AddOns/DPS_Tracker/LibUtils/MsgFrame.lua:63>
-- [string "@Interface/AddOns/   DPS_Tracker/LibUtils/MsgFrame.lua"]:69: in function <Interface/AddOns/DPS_Tracker/LibUtils/MsgFrame.lua:68>
-- [string "@Interface/AddOns/   DPS_Tracker/LibUtils/MsgFrame.lua"]:79: in function `top'
-- [string "@Interface/AddOns/   DPS_Tracker/LibUtils/MsgFrame.lua"]:83: in main chunk

-- /dump strsplittable(":", "hello:world:banana")
-- > {
-- 	[1] = "hello",
-- 	[2] = "world",
-- 	[3] = "banana"
-- }
-- local fragments = {}

-- local stackTrace = debugstack(2)
-- local splitFragments = strsplittable(">", stackTrace )
-- print( type(splitFragments ), #splitFragments )
-- print( splitFragments[1] )

-- local num = #splitFragments
-- for i = 1, num do
-- 	mf:postMsg( sprintf("splits[%d] = %s\n", i, splitFragments[i]))
-- end

