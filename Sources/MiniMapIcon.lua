--------------------------------------------------------------------------------------
-- MiniMapIcon.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 November, 2019
local _, DPS_Tracker = ...
DPS_Tracker.MiniMapIcon = {}
icon = DPS_Tracker.MiniMapIcon

local L = DPS_Tracker.L
local E = errors

local sprintf = _G.string.format

local ICON_DPS_TRACKER = 136813	-- this is the icon's texture

-- register the addon with ACE
local addon = LibStub("AceAddon-3.0"):NewAddon("DPS_Tracker", "AceConsole-3.0")

local shiftLeftClick = (button == "LeftButton") and IsShiftKeyDown()
local shiftRightClick = (button == "RightButton") and IsShiftKeyDown()
local altLeftClick = (button == "LeftButton") and IsAltKeyDown()
local altRightClick = (button == "RightButton") and IsAltKeyDown()
local rightButtonClick = (button == "RightButton")

-- The addon's icon state (e.g., position, etc.,) is kept in the DPS_TrackerDB. Therefore
--  this is set as the ##SavedVariable in the .toc file
local DPS_TrackerDB = LibStub("LibDataBroker-1.1"):NewDataObject("DPS_Tracker", 
	{
		type = "data source",
		text = "DPS_Tracker",
		icon = ICON_DPS_TRACKER,
		OnTooltipShow = function( tooltip )
			tooltip:AddLine(L["ADDON_AND_VERSION"])
			tooltip:AddLine(L["LEFTCLICK_FOR_OPTIONS_MENU"])
			tooltip:AddLine(L["RIGHTCLICK_SHOW_COMBATLOG"])
			tooltip:AddLine(L["SHIFT_LEFTCLICK_DISMISS_COMBATLOG"])
			tooltip:AddLine(L["SHIFT_RIGHTCLICK_ERASE_TEXT"])
		end,
		OnClick = function(self, button )
			-- LEFT CLICK - Display the options menu
			if button == "LeftButton" and not IsShiftKeyDown() then 
				InterfaceOptionsFrame_OpenToCategory("DPS_Tracker")
				InterfaceOptionsFrame_OpenToCategory("DPS_Tracker")
			end
			-- RIGHT CLICK - Show the Combat Log Display
			if button == "RightButton" and not IsShiftKeyDown() then
				cl:showFrame()
			end
			-- SHIFT-LEFT BUTTON - Dismiss the Combat Log window
			if button == "LeftButton" and IsShiftKeyDown() then
				cl:hideFrame()
			end
			-- SHIFT-RIGHT BUTTON -- Erase the text
			if button == "RightButton" and IsShiftKeyDown() then
				cl:clearFrameText()
			end
	end,
	})

-- so far so good. Now, create the actual icon	
local icon = LibStub("LibDBIcon-1.0")

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("DPS_TrackerDB", 
					{ profile = { minimap = { hide = false, }, }, }) 
	icon:Register("DPS_Tracker", DPS_TrackerDB, self.db.profile.minimap) 
end

-- What to do when the player clicks the minimap icon
local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent( "ADDON_LOADED")
eventFrame:SetScript("OnEvent", 
function( self, event, ... )
	local arg1, arg2, arg3 = ...

	if event == "ADDON_lOADED" and arg1 == L["ADDON_NAME"] then
		addon:OnInitialize()
	end
end)
