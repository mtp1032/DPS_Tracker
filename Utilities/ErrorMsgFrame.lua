--------------------------------------------------------------------------------------
-- ErrorMsgFrame.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 16 April, 2023
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.ErrorMsgFrame = {}
emf = DPS_Tracker.ErrorMsgFrame

local sprintf = _G.string.format
local L = DPS_Tracker.L

local frameTitle = sprintf("%s %s", L["ADDON_AND_VERSION"], L["ERROR_MSG_FRAME_TITLE"])
local errorMsgFrame = frames:createErrorMsgFrame(frameTitle)

function emf:hideMeter()
	if errorMsgFrame == nil then
		return
	end
	if errorMsgFrame:IsVisible() == true then
		errorMsgFrame:Hide()
	end
end
function emf:showMeter()
    if errorMsgFrame == nil then
        return
	end
	if errorMsgFrame:IsVisible() == false then
		errorMsgFrame:Show()
	end
end
function emf:clearFrameText()
	if errorMsgFrame == nil then
		return
	end
	errorMsgFrame.Text:EnableMouse( false )    
	errorMsgFrame.Text:EnableKeyboard( false )   
	errorMsgFrame.Text:SetText("") 
	errorMsgFrame.Text:ClearFocus()
end
function emf:getErrorMsgFrame()
	return errorMsgFrame
end
function emf:postResult( result )
	local status = nil
	if result[1] ~= STATUS_C_FAILURE then 
		return
	end
	local topLine = sprintf("[%s] %s: %s\n", "FAILURE", result[2], result[3])
	errorMsgFrame.Text:Insert( topLine )
	emf:showMeter()
end
--*****************************************************************************
--						EMF UNIT TESTS
--*****************************************************************************
-- local result = {E:setFailure(L["PARAM_OUTOFRANGE"])}
-- emf:postResult( result )



