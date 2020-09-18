--------------------------------------------------------------------------------------
-- OptionsMenua.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 Nov, 2019
--------------------------------------------------------------------------------------

local _, DPS_Tracker = ...
DPS_Tracker.OptionsManu = {}
opt = DPS_Tracker.OptionsMenu
local L = DPS_Tracker.L
local E = errors

local sprintf = _G.string.format

------------------------------------------------------------
--						SAVED GLOBALS
------------------------------------------------------------
local function optionsMenu_Initialize()
 
	local optionsMenuFrame = CreateFrame("FRAME","OPTIONS_MENU_MainFrame")
	optionsMenuFrame.name = "DPS_Tracker"
	
	InterfaceOptions_AddCategory(optionsMenuFrame)    -- Register the Configuration panel with LibUIDropDownMenu
	
    -- Print a header at the top of the panel
    local IntroMessageHeader = optionsMenuFrame:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
    IntroMessageHeader:SetPoint("TOPLEFT", 10, -10)
    IntroMessageHeader:SetText(L["ADDON_AND_VERSION"])

    local DescrSubHeader = optionsMenuFrame:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
    DescrSubHeader:SetPoint("TOPLEFT", 20, -50)
	DescrSubHeader:SetText(L["DESCR_SUBHEADER"])

	local str = sprintf("%s\n%s\n%s\n%s\n%s\n", L["LINE1"], L["LINE2"], L["LINE3"], L["LINE4"], L["LINE5"] )
	local messageText = optionsMenuFrame:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
	messageText:SetJustifyH("LEFT")
	messageText:SetPoint("TOPLEFT", 10, -80)
	messageText:SetText(sprintf(str))

    -- Create checkbox to enable logging AND summaries
	local enableLoggingButton = CreateFrame("CheckButton", "OPTIONS_enableLoggingButton", optionsMenuFrame, "ChatConfigCheckButtonTemplate")

    enableLoggingButton:SetPoint("TOPLEFT", 20, -180)
    enableLoggingButton.tooltip = L["ENABLE_LOGGING_TOOLTIP"]
	_G[enableLoggingButton:GetName().."Text"]:SetText(L["PROMPT_ENABLE_LOGGING"])
	enableLoggingButton:SetChecked( loggingEnabled )
	enableLoggingButton:SetScript("OnClick", 
		function(self)
			loggingEnabled = self:GetChecked() and true or false
			if loggingEnabled then
				cl:enableLogging()
			else
				cl:disableLogging()
			end
		end)

		    -- Create checkbox to disable DPS_Tracker AddOn
	local DisableAddon = CreateFrame("CheckButton", "OPTIONS_DisableAddon", optionsMenuFrame, "ChatConfigCheckButtonTemplate")

    DisableAddon:SetPoint("TOPLEFT", 350, -180)
    DisableAddon.tooltip = L["ENABLE_ADDON_TOOLTIP"]
	_G[DisableAddon:GetName().."Text"]:SetText(L["PROMPT_ENABLE_ADDON"])
	DisableAddon:SetChecked( addonEnabled )
	DisableAddon:SetScript("OnClick", 
		function(self)
			addonEnabled = self:GetChecked() and true or false
			if addonEnabled then
				eh:enableAddon()
			else
				eh:disableAddon()
			end
		end)

end

optionsMenu_Initialize()
