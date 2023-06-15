--------------------------------------------------------------------------------------
-- TrackerIcon.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 November, 2019
local _, DPS_Tracker = ...
DPS_Tracker.TrackerIcon = {}
icon = DPS_Tracker.TrackerIcon

local L = DPS_Tracker.L
local E = errors

local sprintf = _G.string.format

local ICON_DPS_TRACKER = 237569	-- this is the icon's texture

-- register the addon with ACE
local addon = LibStub("AceAddon-3.0"):NewAddon(base.ADDON_NAME, "AceConsole-3.0")

local shiftLeftClick 	= (button == "LeftButton") and IsShiftKeyDown()
local shiftRightClick 	= (button == "RightButton") and IsShiftKeyDown()
local altLeftClick 		= (button == "LeftButton") and IsAltKeyDown()
local altRightClick 	= (button == "RightButton") and IsAltKeyDown()
local rightButtonClick	= (button == "RightButton")

-- The addon's icon state (e.g., position, etc.,) is kept in the DPS_TrackerDB. Therefore
--  this is set as the ##SavedVariable in the .toc file
local DPS_TrackerDB = LibStub("LibDataBroker-1.1"):NewDataObject(base.ADDON_NAME, 
	{
		type = "data source",
		text = base.ADDON_NAME,
		icon = ICON_DPS_TRACKER,
		OnTooltipShow = function( tooltip )
			tooltip:AddLine(L["ADDON_AND_VERSION"])
			tooltip:AddLine(L["Left click to toggle options menu."])
			tooltip:AddLine(L["Right click to show encounter report(s)."])
			tooltip:AddLine(L["Shift right click to clear encounter text."])
			tooltip:AddLine(L["Shift left click - NOT IMPLENTED"])
		end, 
		OnClick = function(self, button )
			-- LEFT CLICK - Display the options menu
			if button == "LeftButton" and not IsShiftKeyDown() then 
				if panel:isVisible() then
					panel:hide()
				else
					panel:show()
				end
			end
			-- RIGHT CLICK - Show the encounter reports
			if button == "RightButton" and not IsShiftKeyDown() then
				mf:eraseText()
				cleu:summarizeEncounter()
			end
			if button == "LeftButton" and IsShiftKeyDown() then
			end
			if button == "RightButton" and IsShiftKeyDown() then
				mf:eraseText()
			end
	end,
	})

-- so far so good. Now, create the actual icon	
local icon = LibStub("LibDBIcon-1.0")

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("DPS_TrackerDB", 
					{ profile = { minimap = { hide = false, }, }, }) 
	icon:Register(base.ADDON_NAME, DPS_TrackerDB, self.db.profile.minimap) 
end

local fileName = "TrackerIcon.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end

