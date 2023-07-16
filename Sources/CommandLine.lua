--------------------------------------------------------------------------------------
-- FILE NAME:       CommandLine.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   17 April, 2023
local _, DPS_Tracker = ...
DPS_Tracker.CommandLine = {}
cl = DPS_Tracker.CommandLine

local libName ="WoWThreads-1.0"
local thread = LibStub:GetLibrary( libName )
if not thread then 
    return 
end
local SIG_ALERT             = thread.SIG_ALERT
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING

local L = DPS_Tracker.L
local sprintf = _G.string.format

local helpFrame	= nil

local SUCCESS = base.SUCCESS
local EMPTY_STR = base.EMPTY_STR

-- **************************************************************************************
--						SLASH COMMANDS
-- **************************************************************************************

-- Command line parsing: https://wowpedia.fandom.com/wiki/Creating_a_slash_command

local function validateCmd( msg )
    local isValid = false
    
    if msg == nil then
        return isValid
    end
    if msg == EMPTY_STR then
        return isValid
    end

	if msg == sum then
		cleu:summarizeEncounter()
		isValid = true
	elseif msg == summary then
		cleu:summarizeEncounter()
		isValid = true
	elseif msg == summarize then
		cleu:summarizeEncounter()
		isValid = true
	elseif msg == all then
		cleu:printEncounters()
		isValid = true
	end
	
	return msg
end
function cleu:hideHelpFrame()
	if helpFrame == nil then
		return
	end
	if helpFrame:IsVisible() == true then
		helpFrame:Hide()
	end
end
function cleu:showHelpFrame()
	if helpFrame == nil then
		helpFrame = celd:createHelpFrame()
	end
	if helpFrame:IsVisible() == false then
		helpFrame:Show()
	end

end
function cleu:clearHelpText()
	if helpFrame == nil then
		return
	end
	helpFrame.Text:EnableMouse( false )    
	helpFrame.Text:EnableKeyboard( false )   
	helpFrame.Text:SetText("") 
	helpFrame.Text:ClearFocus()
end

local line1  = sprintf("\n%s\n", "DPS Tracker: slash commands\n")
local line2  = sprintf("  help - This message\n")
local line3  = sprintf("  show - Displays the tracker window\n")
local line4  = sprintf("  hide - Hides the tracker window\n")
local line5  = sprintf("  delete - Deletes the entries in the tracker window\n")
local line6 = sprintf("   config - Display the DPS_Tracker configuration options.\n") 
local line7 = sprintf("   config - Click the <RedX> minimap button\n")
local line8 = sprintf("   stop - immediately stops logging. Does not affect publication of combat summary.\n")
local helpMsg = line1..line2..line3..line4..line5..line6..line7..line8

local function postHelpMsg()
	if helpFrame == nil then
		helpFrame = display:createHelpFrame( sprintf("%s Help.", L["ADDON_AND_VERSION"] ))
	end
	display:showFrame( helpFrame )
	helpFrame.Text:Insert( helpMsg )
end

-- https://wowwiki-archive.fandom.com/wiki/Creating_a_slash_command
local function validateCmd( msg )
    local isValid = true
    
    if msg == nil then
        isValid = false
    end
    if msg == EMPTY_STR then
        isValid = false
    end
    return isValid
end
local function trackerCommands(cmdStr, editbox)
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    -- pattern matching that skips leading whitespace and whitespace between cmd and args
    -- any whitespace at end of args is retained
    local _, _, cmd, args = string.find(cmdStr, "%s?(%w+)%s?(.*)")
    cmd = string.lower( cmd )
    if cmd == nil then
        print("Help not implemented yet")
        return
    end

    ----------- PRINT A COMBAT / ENCOUNTER SUMMARY  ---------
    if cmd == "sum" then -- calls cleu:summarizeEncounter()
        cleu:summarizeEncounter()  
        return
    end
	if cmd == "reset" then -- calls cleu:summarizeEncounter()
        cleu:resetCombatState()  
        return
    end

    if cmd == "help" or cmd == "" then
        postHelpMsg( helpMsg )
        return
    end
        -- If not handled above, display some sort of help message
        postHelpMsg( helpMsg )
  end
  
  SLASH_DPS_TRACKER1 = "/report"
  SlashCmdList["DPS_TRACKER"] = trackerCommands  -- adds "/monitor" to the commands list

local fileName = "CommandLine.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
