--------------------------------------------------------------------------------------
-- Frames.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 16 April, 2023
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.Frames = {}
frames = DPS_Tracker.Frames
local sprintf = _G.string.format
local L = DPS_Tracker.L

-- https://us.forums.blizzard.com/en/wow/t/addons-now-usable-in-shadowlands-beta/586355/16
-- https://wow.gamepedia.com/API_Frame_SetBackdrop
-- https://wow.gamepedia.com/EdgeFiles

local DEFAULT_FRAME_WIDTH = 600
local DEFAULT_FRAME_HEIGHT = 400

--------------------------------------------------------------------------
--                         CREATE THE VARIOUS BUTTONS
--------------------------------------------------------------------------
local function createResizeButton( f )
	f:SetResizable( true )
	local resizeButton = CreateFrame("Button", nil, f)
	resizeButton:SetSize(16, 16)
	resizeButton:SetPoint("BOTTOMRIGHT")
	resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	resizeButton:SetScript("OnMouseDown", function(self, button)
    	f:StartSizing("BOTTOMRIGHT")
    	f:SetUserPlaced(true)
	end)
 
	resizeButton:SetScript("OnMouseUp", function(self, button)
		f:StopMovingOrSizing()
		frameWidth, frameHeight= f:GetSize()
	end)
end
local function createClearButton( f, placement, offX, offY )
    local clearButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearButton:SetPoint(placement, f, 5, 5)
    clearButton:SetHeight(25)
    clearButton:SetWidth(70)
    clearButton:SetText(L["CLEAR_BUTTON_TEXT"])
    clearButton:SetScript("OnClick", 
        function(self)
            self:GetParent().Text:EnableMouse( false )    
            self:GetParent().Text:EnableKeyboard( false )   
            self:GetParent().Text:SetText("") 
            self:GetParent().Text:ClearFocus()
        end)
    f.clearButton = clearButton
end
local function createReloadButton( f, placement, offX, offY )
    local reloadButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	reloadButton:SetPoint(placement, f, 5, 5) -- was -175, 10
    reloadButton:SetHeight(25)
    reloadButton:SetWidth(70)
    reloadButton:SetText(L["RELOAD_BUTTON_TEXT"])
    reloadButton:SetScript("OnClick", 
        function(self)
            ReloadUI()
        end)
    f.reloadButton = reloadButton
end
local function createSelectButton( f, placement, offX, offY )
    local selectButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    selectButton:SetPoint(placement, f, -5, 5)

    selectButton:SetHeight(25)
    selectButton:SetWidth(70)
    selectButton:SetText(L["SELECT_BUTTON_TEXT"])
    selectButton:SetScript("OnClick", 
        function(self)
            self:GetParent().Text:EnableMouse( true )    
            self:GetParent().Text:EnableKeyboard( true )   
            self:GetParent().Text:HighlightText()
            self:GetParent().Text:SetFocus()
        end)
    f.selectButton = selectButton
end
local function createResetButton( f, placement, offX, offY )
    local resetButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetButton:SetPoint(placement, f, 5, 5)
    resetButton:SetHeight(25)
    resetButton:SetWidth(70)
    resetButton:SetText(L["RESET_BUTTON_TEXT"])
    resetButton:SetScript("OnClick", 
        function(self)
            self:GetParent().Text:EnableMouse( false )    
            self:GetParent().Text:EnableKeyboard( false )   
            self:GetParent().Text:SetText("") 
            self:GetParent().Text:ClearFocus()
           end)
    f.resetButton = resetButton
end
--------------------------------------------------------------------------
--                         CREATE THE FRAMES
--------------------------------------------------------------------------
local function createTopFrame( frameName, width, height, red, blue, green )
	local f = CreateFrame( "Frame", frameName, UIParent, "BasicFrameTemplateWithInset" )
	if width == nil then
		width = DEFAULT_FRAME_WIDTH
	end
	if height == nil then
		height = DEFAULT_FRAME_HEIGHT
	end
	f:SetSize( width, height )
	return f
end
local function createTextDisplay(f)
    f.SF = CreateFrame("ScrollFrame", "$parent_DF", f, "UIPanelScrollFrameTemplate")
    f.SF:SetPoint("TOPLEFT", f, 12, -30)
    f.SF:SetPoint("BOTTOMRIGHT", f, -30, 40)

    --                  Now create the EditBox
    f.Text = CreateFrame("EditBox", nil, f)
    f.Text:SetMultiLine(true)
    f.Text:SetSize(DEFAULT_FRAME_WIDTH - 20, DEFAULT_FRAME_HEIGHT )
    f.Text:SetPoint("TOPLEFT", f.SF)    -- ORIGINALLY TOPLEFT
    f.Text:SetPoint("BOTTOMRIGHT", f.SF) -- ORIGINALLY BOTTOMRIGHT
    f.Text:SetMaxLetters(99999)
    f.Text:SetFontObject(GameFontNormal) -- Color this R 99, G 14, B 55
    f.Text:SetHyperlinksEnabled( true )
    f.Text:SetTextInsets(5, 5, 5, 5, 5)
    f.Text:SetAutoFocus(false)
    f.Text:EnableMouse( false )
    f.Text:EnableKeyboard( false )
    f.Text:SetScript("OnEscapePressed", 
        function(self) 
            self:ClearFocus() 
        end) 
    f.SF:SetScrollChild(f.Text)
end
function frames:createHelpFrame( title )
	local f = createTopFrame("HelpFrame", 700, 225, 0, 0, 0 )
	f:SetPoint("CENTER", 0, 200)
    f:SetFrameStrata("BACKGROUND")
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:SetMovable(true)
    f:Hide()
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f.title = f:CreateFontString(nil, "OVERLAY")
	f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 5, 0)
	f.title:SetText( title)
	
	createTextDisplay(f)
	createSelectButton(f, "BOTTOMRIGHT", 5, 5)
	createClearButton(f,"BOTTOMLEFT", 5,5 )
    return f
end
--------------------------------------------------------------------------
--                   THESE ARE THE APPLICATION FRAMES
--------------------------------------------------------------------------
--  Create the frame where the events are logged
function frames:createCombatEventLog( title )
	local f = createTopFrame("CombatEventLogFrame", 700, 225, 0, 0, 0 )
	f:SetResizable( true )
	if center then
		f:SetPoint("CENTER", 10, 300 )
	else
		f:SetPoint("TOPLEFT", 10, -40 )
	end
	f:SetFrameStrata("BACKGROUND")
	f:SetAlpha(1)
	f:EnableMouse(true)
	f:EnableMouseWheel(true)
	f:SetMovable(true)
	f:Hide()
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
	f.title = f:CreateFontString(nil, "OVERLAY")
	f.title:SetFontObject("GameFontHighlight")
	f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 5, 0)
	f.title:SetText( title )

	-- Create/Add the buttons
	createResizeButton(f)
	createSelectButton(f,"BOTTOMRIGHT", 5,5)
	createClearButton(f,"BOTTOMLEFT", 5,5)
	createTextDisplay(f)
    return f
end
--  Create the frame where error messages are posted
function frames:createErrorMsgFrame(title)
    local f = createTopFrame( "ErrorMsgFrame",600, 200, 0, 0 )
    f:SetPoint("CENTER", 0, 200)
    f:SetFrameStrata("BACKGROUND")
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:SetMovable(true)
    f:Hide()
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f.title = f:CreateFontString(nil, "OVERLAY")
	f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 5, 0)
	f.title:SetText( title)
	
    createResizeButton(f)
    createTextDisplay(f)
    createReloadButton(f, "BOTTOMLEFT",f, 5, 5)
    createSelectButton(f, "BOTTOMRIGHT",f, 5, 5)
    createClearButton(f, "BOTTOM",f, 5, 5)
    return f
end
function frames:printErrorMsg( msg )
        UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0, nil, true ) 
end
function frames:printInfoMsg( msg )
    UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0, nil, 10 ) 
end
--  Create the frame where info messages are posted
function frames:createMsgFrame( title )
    local f = createTopFrame("MsgFrame", 800, 600, 0, 0, 0 )
    f:SetResizable( true )
    f:SetPoint("TOPRIGHT", -100, -200)
    f:SetFrameStrata("BACKGROUND")
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:SetMovable(true)
    f:Hide()
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f.title = f:CreateFontString(nil, "OVERLAY");
	f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 5, 0);
    f.title:SetText(title);

	createResizeButton(f)
	createTextDisplay(f)
	createSelectButton(f,"BOTTOMRIGHT", 5,5 )
    createClearButton(f, "BOTTOMLEFT", 5, 5)
    return f
end
-------------------------------------------------------------------------
--                          UTILITY FUNCTIONS
-------------------------------------------------------------------------
function frames:hideFrame( f )
	if f == nil then
		return
	end
	if f:IsVisible() == true then
		f:Hide()
	end
end
function frames:showFrame(f)
    if f == nil then
        return
	end
	if f:IsVisible() == false then
		f:Show()
	end
end
function frames:clearFrame(f) -- erases the text in the edit box
	if f == nil then
		return
	end
	f.Text:EnableMouse( false )    
	f.Text:EnableKeyboard( false )   
	f.Text:SetText("") 
	f.Text:ClearFocus()
end

local fileName = "Frames.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end





