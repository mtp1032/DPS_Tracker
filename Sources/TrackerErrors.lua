--------------------------------------------------------------------------------------
-- TrackerErrors.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 November, 2018	(Formerly DbgInfo.lua prior to this date)
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.Errors = {}	
errors = DPS_Tracker.Errors	
local sprintf = _G.string.format

local L = DPS_Tracker.L
--                      Error messages associated with function parameters
STATUS_SUCCESS 	=  1
STATUS_FAILURE	= -1

--                      The Result Table
SUCCESSFUL_RESULT   = { STATUS_SUCCESS, nil, nil }
DEFAULT_RESULT      = { STATUS_SUCCESS, nil, nil }
FAILED_RESULT       = { STATUS_FAILURE, nil, nil }

local DISPLAY_TIME = 20

---------------------------------------------------------------------------------------------------
--                      LOCAL FUNCTIONS
----------------------------------------------------------------------------------------------------
local function simplifyStackTrace( stackTrace )
	local startPos, endPos = string.find( stackTrace, '\'' )
	stackTrace = string.sub( stackTrace, 1, startPos )
	stackTrace = string.gsub( stackTrace, "Interface\\AddOns\\", "")
	
	stackTrace = string.gsub( stackTrace, "`", "<")
	stackTrace = string.gsub( stackTrace, "'", ">")
		
	stackTrace = string.gsub( stackTrace, ": in function ", "")        
	local stackFrames = { strsplit( "/\n", stackTrace )}
			
	local numFrames = #(stackFrames)
	for i = 1, numFrames do
		stackFrames[i] = strtrim( stackFrames[i] )
	end
	
	for i = 1, numFrames do
		startPos = strfind( stackFrames[i], "<")
		stackFrames[i] = string.sub( stackFrames[i], 1, startPos-1)
	end
	
	local simplifiedStackTrace = stackFrames[1]
	for i = 2, numFrames do
		simplifiedStackTrace = strjoin( "\n", simplifiedStackTrace, stackFrames[i])
		simplifiedStackTrace = strtrim( simplifiedStackTrace )
	end
	return simplifiedStackTrace
end	
local function getFileAndLineNo( stackTrace )
	local pieces = {strsplit( ":", stackTrace, 5 )}
	local segment = {strsplit( "\\", pieces[1], 5 )}
	local i = 1
	local fileName = segment[i]
	while segment[i] ~= nil do
		index = tostring(i)
		fileName = segment[i]
		i = i+1 
	end

	-- [EventHandler.lua"]	-- need to remove the " character - the 18th character in the string"
	local strLen = string.len( fileName )
	local fileName = string.sub( fileName, 1, strLen - 2 )
	local lineNumber = tonumber(pieces[2])
	lineNumber = lineNumber
	FileAndLine = sprintf("[%s:%d]", fileName, lineNumber )

	return FileAndLine
end
---------------------------------------------------------------------------------------------------
--                      PUBLIC/EXPORTED FUNCTIONS
----------------------------------------------------------------------------------------------------
function errors:setFailure( errMsg )
	-- Example Usage:
	-- 		local result = {errors:setFailure(L["PARAM_OUTOFRANGE"])}
	local errorLoc = getFileAndLineNo( debugstack(2) )
	return STATUS_C_FAILURE, errMsg, errorLoc
end
function errors:printErrorResult( result )
	local status = nil
	if result[1] == STATUS_C_SUCCESS then
		status = "SUCCESS"
	else
		status = "FAILURE"
	end
	local reason = result[2]
	local errorLocation = result[3]
	local str = sprintf("[%s] %s %s\n", status, reason, errorLocation  )
	UIErrorsFrame:SetTimeVisible(DISPLAY_TIME)
	UIErrorsFrame:AddMessage( str, 1.0, 0.0, 0.0 )
end
function errors:printMsg( msg )
	DEFAULT_CHAT_FRAME:AddMessage( msg, 1.0, 1.0, 0.0 )
end
function errors:where( msg )
	local fn = getFileAndLineNo( debugstack(2) )
	local str = nil
	if msg then
		str = sprintf("%s %s", fn, msg )
	else
		str = fn
	end
	DEFAULT_CHAT_FRAME:AddMessage( str, 1.0, 1.0, 0.0 )
	return( str )
end
function errors:printErrorMsg( msg )
	-- UIErrorsFrame:SetTimeVisible(8)
	UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0, 8 ) 
end
function errors:printInfoMsg( msg )
	DEFAULT_CHAT_FRAME:AddMessage( msg, 1.0, 1.0, 0.0 )
end
