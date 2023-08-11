--------------------------------------------------------------------------------------
-- TrackerOptionslua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 Nov, 2019
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.TrackerOptions = {}
panel = DPS_Tracker.TrackerOptions

local L = DPS_Tracker.L
local sprintf = _G.string.format
local EMPTY_STR = base.EMPTY_STR
------------------------------------------------------------
--						SAVED GLOBALS
------------------------------------------------------------
local optionsPanel = nil

local defaultTargetHealth = UnitHealthMax("Player") * 1
DPS_TRACKER_CHECKBOX_VARS	= {}

local dmg  = 1
local heal = 2
local aura = 3
local miss = 4

local dmgScrollButton 	= nil
local healScrollButton 	= nil
local auraScrollButton 	= nil
local missScrollButton 	= nil

-- Option Menu Settings
local FRAME_WIDTH 		= 590
local FRAME_HEIGHT 		= FRAME_WIDTH
local WIDTH_TITLE_BAR 	= 500
local HEIGHT_TITLE_BAR 	= 45

local LINE_SEGMENT_LENGTH 	= 575
local X_START_POINT 		= 10
local Y_START_POINT 		= X_START_POINT

local function drawLine( yPos, f)
	local lineFrame = CreateFrame("FRAME", nil, f )
	lineFrame:SetPoint("CENTER", -10, yPos )
	lineFrame:SetSize(LINE_SEGMENT_LENGTH, LINE_SEGMENT_LENGTH)
	
	local line = lineFrame:CreateLine(1)
	line:SetColorTexture(.5, .5, .5, 1) -- Grey per https://wow.gamepedia.com/Power_colors
	line:SetThickness(2)
	line:SetStartPoint("LEFT",X_START_POINT, Y_START_POINT)
	line:SetEndPoint("RIGHT", X_START_POINT, Y_START_POINT)
	lineFrame:Show() 
end
-- CHECK BOXES
local function scrollingDamageCheckBtn( frame, xPos, yPos )	
	dmgScrollButton = CreateFrame("CheckButton", "DPSTRACKER_dmgScrollButton", frame, "ChatConfigCheckButtonTemplate" )
	dmgScrollButton:SetPoint("TOPLEFT", xPos, yPos )
	dmgScrollButton.tooltip = sprintf("Damage values (red) are scrolled across your screen. Crit values will be in a larger font.")
	dmgScrollButton.Text:SetFontObject(GameFontNormal)
	_G[dmgScrollButton:GetName().."Text"]:SetText("Check To Scroll Damage Values." )
	dmgScrollButton:SetChecked( DPS_TRACKER_CHECKBOX_VARS[dmg] )
	dmgScrollButton:SetScript("OnClick", 
		function(self)
			local isChecked = self:GetChecked() and true or false
			if isChecked then 
				cleu:enableScrollingDmg() 
			else 
				cleu:disableScrollingDmg() 
			end
			DPS_TRACKER_CHECKBOX_VARS[dmg] = isChecked
		end)
end
local function scrollingHealsCheckBtn( frame, xPos, yPos )
	healScrollButton = CreateFrame("CheckButton", "DPSTRACKER_healScrollButton", frame, "ChatConfigCheckButtonTemplate")
	healScrollButton:SetPoint("TOPLEFT", xPos, yPos )
	healScrollButton.tooltip = sprintf("Heal values (Green) are scrolled across your screen. Crit values will be in a larger font.")
	healScrollButton.Text:SetFontObject(GameFontNormal)
	_G[healScrollButton:GetName().."Text"]:SetText("Check To Scroll Heal Values." )
	healScrollButton:SetChecked( DPS_TRACKER_CHECKBOX_VARS[heal] )
	healScrollButton:SetScript("OnClick", 
		function(self)
			local isChecked = self:GetChecked() and true or false
			if isChecked then 
				cleu:enableScrollingHeals() 
			else 
				cleu:disableScrollingHeals() 
			end
			DPS_TRACKER_CHECKBOX_VARS[heal] = isChecked
		end)
end
local function scrollingAurasCheckBtn( frame, xPos, yPos )
    auraScrollButton = CreateFrame("CheckButton", "DPSTRACKER_auraScrollButton", frame, "ChatConfigCheckButtonTemplate")
	auraScrollButton:SetPoint("TOPLEFT", xPos, yPos )
	auraScrollButton.tooltip = sprintf("Auras (Buffs and Debuffs) are scrolled across your screen. WARNING: Checking this box can cause your screen to be cluttered.")
	auraScrollButton.Text:SetFontObject(GameFontNormal)
	_G[auraScrollButton:GetName().."Text"]:SetText("Check To Scroll Auras." )
	auraScrollButton:SetChecked( DPS_TRACKER_CHECKBOX_VARS[aura])
	auraScrollButton:SetScript("OnClick", 
		function(self)
			local isChecked = self:GetChecked() and true or false

			if isChecked then
				cleu:enableScrollingAuras() 
			else 
				cleu:disableScrollingAuras() 
			end
			DPS_TRACKER_CHECKBOX_VARS[aura] = isChecked
		end)
end
local function scrollingMissCheckBtn( frame, xPos, yPos )
	missScrollButton = CreateFrame("CheckButton", "DPSTRACKER_missScrollButton", frame,"ChatConfigCheckButtonTemplate")
	missScrollButton:SetPoint("TOPLEFT", xPos, yPos )
	missScrollButton.tooltip = sprintf("Miss types (e.g., RESISTS, BLOCKS, PARRIES, DODGES, etc.,) are scrolled across your screen.")
	missScrollButton.Text:SetFontObject(GameFontNormal)
	_G[missScrollButton:GetName().."Text"]:SetText("Check To Scroll Miss Types." )
	missScrollButton:SetChecked( DPS_TRACKER_CHECKBOX_VARS[miss] )
	missScrollButton:SetScript("OnClick", 
		function(self)
			local isChecked = self:GetChecked() and true or false
			if isChecked then
				cleu:enableScrollingMisses() 
			else 
				cleu:disableScrollingMisses() 
			end
			DPS_TRACKER_CHECKBOX_VARS[miss] = isChecked
		end)
end

---- DEFAULT and ACCEPT BUTTONS
local function createDefaultsButton(f, width, height) -- creates Default button

	f.hide = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.hide:SetText("Defaults")
	f.hide:SetHeight(height)	-- original value 20
	f.hide:SetWidth(width)		-- original value 80
	f.hide:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
	f.hide:SetScript("OnClick",

		function( self )
			dmgScrollButton:SetChecked( false)
 			healScrollButton:SetChecked( false )
			auraScrollButton:SetChecked( false)
			missScrollButton:SetChecked( false )
			DPS_TRACKER_CHECKBOX_VARS = {false, false, false, false }
			f:Hide()
		end)
end
local function createAcceptButton(f, width, height) -- creates Accept button
    -- -- Accept buttom, bottom right
	f.hide = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.hide:SetText("Accept")
	f.hide:SetHeight(height)	-- Original value = 20
	f.hide:SetWidth(width)		-- Original value = 80
	f.hide:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)

	f.hide:SetScript("OnClick",
		function( self )
			DPS_TRACKER_CHECKBOX_VARS[dmg]  = dmgScrollButton:GetChecked()
			print( DPS_TRACKER_CHECKBOX_VARS[dmg])
			DPS_TRACKER_CHECKBOX_VARS[heal] = healScrollButton:GetChecked()
			DPS_TRACKER_CHECKBOX_VARS[aura] = auraScrollButton:GetChecked()
			DPS_TRACKER_CHECKBOX_VARS[miss] = missScrollButton:GetChecked()
			f:Hide()
		end)
end

---- INPUT DIALOG BOX
local function createInputDialogBox(frame, title, xPos, yPos) -- creates the input Dialog box
	local str = string.upper( title )
	local DescrSubHeader = frame:CreateFontString(nil, "ARTWORK","GameFontNormal")
    DescrSubHeader:SetPoint("LEFT", xPos, yPos + 20)
	DescrSubHeader:SetText( title )
	local f = CreateFrame("EditBox", "InputEditBox", frame, "InputBoxTemplate")
	f:SetFrameStrata("DIALOG")
	f:SetSize(200,75)
	f:SetAutoFocus(false)
	f:SetPoint("LEFT", xPos, yPos)
	f:SetText( defaultTargetHealth )
	f:SetScript("OnEnterPressed", 
		function(self,button)
			local targetHealth = f:GetText()
			if targetHealth == EMPTY_STR then targetHealth = defaultTargetHealth end
			cleu:setTargetDummyHealth( targetHealth )
			ClearCursor()
			f:SetText("")
			optionsPanel:Hide()
	end)
end
-- ******************** CREATE THE OPTIONS/SETTINGS PANEL **********************
local function createOptionsPanel()
	if optionsPanel ~= nil then
		return optionsPanel
	end

	local frame = CreateFrame("Frame", "DPS_Tracer Settings", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 26,
        insets = {left = 9, right = 9, top = 9, bottom = 9},
    })
	frame:SetBackdropColor(0.0, 0.0, 0.0, 0.50)

    -- The Title Bar & Title
	frame.titleBar = frame:CreateTexture(nil, "ARTWORK")
	frame.titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	frame.titleBar:SetPoint("TOP", 0, 12)
    frame.titleBar:SetSize( WIDTH_TITLE_BAR, HEIGHT_TITLE_BAR)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, 4)
	frame.title:SetText("DPS_Tracker Options")

    -- Title text
	frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	frame.text:SetPoint("TOPLEFT", 12, -22)
	frame.text:SetWidth(frame:GetWidth() - 20)
	frame.text:SetJustifyH("LEFT")
	frame:SetHeight(frame.text:GetHeight() + 70)
	tinsert( UISpecialFrames, frame:GetName() ) 
    frame:SetSize( FRAME_WIDTH, FRAME_HEIGHT )
	local buttonWidth = 80
	local buttonHeight	= 20
	createAcceptButton(frame, buttonWidth, buttonHeight)
	createDefaultsButton(frame, buttonWidth, buttonHeight)

	-------------------- INTRO HEADER -----------------------------------------
	local subTitle = frame:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
	local msgText = frame:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
	local displayString = sprintf("%s", L["ADDON_AND_VERSION"])
	msgText:SetPoint("TOP", 0, -20)
	msgText:SetText(displayString)

    -------------------- WARNING DESCRIPTION ---------------------------------------
    local DescrSubHeader = frame:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
	local messageText = frame:CreateFontString(nil, "ARTWORK","GameFontNormal")
	messageText:SetJustifyH("LEFT")

	local str1 = "DPS_Tracker"
	local line = sprintf("                      ")
	local str2 = sprintf("    DPS_Tracker is designed to be used with target dummies, although")
	local str3 = sprintf("its use while questing or running dungeons is fully supported.")
	local str4 = sprintf("DPS_Tracker allows you to specify the health of a target dummy.")
	local str5 = sprintf("When your attacks have reduced the target's health to zero ")
	local str6 = sprintf("combat data recording will cease and you can call up a summary ")
	local str7 = sprintf("of the encounter.")
	local str8 = sprintf("    In addition to total Damage output and your DPS, DPS_Tracker")
	local str9 = sprintf("will report the following metrics:")
	local str10 = sprintf("   - Total damage and DPS per spell/attack.")
	local str11 = sprintf("   - The number of times your attacks missed, were blocked, parried, etc.")
	local messageText = frame:CreateFontString(nil, "ARTWORK","GameFontNormal")
	messageText:SetJustifyH("LEFT")
	messageText:SetPoint("TOP", 0, -70)
	messageText:SetText(sprintf("%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s", 
	str1, line, str2, str3, str4, str5, str6, str7, str8, str9, str10, str11 ))

	-- drawLine( 220, frame )
	drawLine( 50, frame )
	-- coords for line
	local xPos = 20
	local yPos = -250
	local yOffset = -20

	xPos = 40
	yPos = yPos + yOffset

	-- create and display the check boxes
	scrollingDamageCheckBtn( frame, xPos, yPos )
	yPos = yPos + yOffset

	scrollingHealsCheckBtn(   frame, xPos, yPos )
	yPos = yPos + yOffset

	scrollingAurasCheckBtn(  frame, xPos, yPos )
	yPos = yPos + yOffset

	scrollingMissCheckBtn( frame, xPos, yPos )
	yPos = yPos + yOffset

	-- create and display the input dialog box for specifying the dummy target's health
	createInputDialogBox(frame, "Press <Enter> To Set Target Dummy Health", 150, -100)

	frame:Show() 
	return frame   
end
optionsPanel = createOptionsPanel()
function panel:isVisible()
	return optionsPanel:IsVisible()
end
function panel:show()
	if not optionsPanel:IsVisible() then
		optionsPanel:Show()
	end
end
function panel:hide()
	if optionsPanel:IsVisible() then
		optionsPanel:Hide()
	end
end


local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent( "PLAYER_LOGIN")
eventFrame:SetScript("OnEvent",
function( self, event, ... )
	if event == "PLAYER_LOGIN" then
		if DPS_TRACKER_CHECKBOX_VARS == nil then
			DPS_TRACKER_CHECKBOX_VARS = {false, false, false,false }
			cleu:disableScrollingDmg()
			cleu:disableScrollingHeals()
			cleu:disableScrollingAuras()
			cleu:disableScrollingMisses()
		end
		
		if DPS_TRACKER_CHECKBOX_VARS[dmg] then
			local checked = DPS_TRACKER_CHECKBOX_VARS[dmg]
			dmgScrollButton:SetChecked( checked )
			if checked then
				cleu:enableScrollingDmg()
			else
				cleu:disableScrollingDmg()
			end
		end
		if DPS_TRACKER_CHECKBOX_VARS[heal] then
			local checked = DPS_TRACKER_CHECKBOX_VARS[heal]
			healScrollButton:SetChecked( checked )
			if checked then
				cleu:enableScrollingHeals()
			else
				cleu:disableScrollingHeals()
			end
		end
		if DPS_TRACKER_CHECKBOX_VARS[aura] then
			local checked = DPS_TRACKER_CHECKBOX_VARS[aura]
			auraScrollButton:SetChecked( checked )
			if checked then
				cleu:enableScrollingAuras()
			else
				cleu:disableScrollingAuras()
			end
		end
		if DPS_TRACKER_CHECKBOX_VARS[miss] then
			local checked = DPS_TRACKER_CHECKBOX_VARS[miss]
			missScrollButton:SetChecked( checked )
			if checked then
				cleu:enableScrollingMisses()
			else
				cleu:disableScrollingMisses()
			end
		end
	end
end)

local fileName = "TrackerOptions.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("[%s] %s loaded", base.ADDON_NAME, fileName), 1.0, 1.0, 0.0 )
end

