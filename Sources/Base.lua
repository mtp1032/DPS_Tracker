--------------------------------------------------------------------------------------
-- Base.lua
-- AUTHOR: Michael Peterson 
-- ORIGINAL DATE: 9 October, 2019
local _, DPS_Tracker = ...
DPS_Tracker.Base = {}
base = DPS_Tracker.Base

--******************** DEV NOTES/LINKS *****************************************
--
--  https://wow.gamepedia.com/World_of_Warcraft_API#Units
--  https://wow.gamepedia.com/API_UnitAffectingCombat
--  https://wow.gamepedia.com/API_UnitGUID
--  https://wow.gamepedia.com/API_UnitHealth (Use b4 entering combat to get max health of target)
--  https://wow.gamepedia.com/API_UnitHealthMax (Doesn't work on enemies in Classic)
--  https://wow.gamepedia.com/API_UnitLevel
--  https://wow.gamepedia.com/API_UnitPower
--  https://wow.gamepedia.com/API_UnitStat
--  https://wowwiki.fandom.com/wiki/Events/Unit_Info (e.g., UNIT_COMBAT, UNIT_HEALTH)
--	https://us.forums.blizzard.com/en/wow/t/api-getparrychance-and-getblockchance-yield-same-value-classic/386439/2
--
--  https://wowwiki.fandom.com/wiki/API_InCombatLockdown
--  Event: UNIT_COMBAT
-- 		arg1 - the UnitID of the entity
-- 		arg2 - Action,Damage,etc (e.g. HEAL, DODGE, BLOCK, WOUND, MISS, PARRY, RESIST, ...)
-- 		arg3 - Critical/Glancing indicator (e.g. CRITICAL, CRUSHING, GLANCING)
-- 		arg4 - The numeric damage
-- 		arg5 = Damage type in numeric value (1 - physical; 2 - holy; 4 - fire; 8 - nature; 16 - frost; 32 - shadow; 64 - arcane)
--
-- GetParryChance(), GetDodgeChance(), ..., etc., returns the chance the effect
--	will be applied and depends on class, level, stats, etc.
--******************************************************************************


local sprintf = _G.string.format

base.EXPANSION_NAME 	= nil 
base.EXPANSION_LEVEL	= nil
base.SUCCESS 	        = true
base.FAILURE 	        = false
base.EMPTY_STR 	        = ""
base.DEBUGGING_ENABLED	= false

base.DAMAGE_EVENT	= 1
base.HEALING_EVENT	= 2
base.AURA_EVENT		= 3
base.MISS_EVENT		= 4

local EMPTY_STR 		= base.EMPTY_STR
local SUCCESS			= base.SUCCESS
local FAILURE			= base.FAILURE

base.combatLoggingEnabled 	= false
base.dpsTrackerDisabled 	= false
local combatLoggingEnabled	= base.combatLoggingEnabled
local dpsTrackerDisabled 	= base.dpsTrackerDisabled

base.EXPANSION_LEVEL = GetServerExpansionLevel()

if base.EXPANSION_LEVEL == LE_EXPANSION_CLASSIC then
	base.EXPANSION_NAME = "Classic (Vanilla)"
end 
if base.EXPANSION_LEVEL == LE_EXPANSION_WRATH_OF_THE_LICH_KING then 
	base.EXPANSION_NAME = "Classic (WotLK)"
end
if base.EXPANSION_LEVEL == LE_EXPANSION_DRAGONFLIGHT then
	base.EXPANSION_NAME = "Dragon Flight"
end
local function getAddonName()
	local stackTrace = debugstack(2)
	local dirNames = nil
	local addonName = nil

	if 	base.EXPANSION_LEVEL == LE_EXPANSION_DRAGONFLIGHT then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}	end
	if base.EXPANSION_LEVEL == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}
	end
	if base.EXPANSION_LEVEL == LE_EXPANSION_CLASSIC then
		dirNames = {strsplittable( "\/", stackTrace, 5 )}
	end

	addonName = dirNames[1][3]
	return addonName
end

base.ADDON_NAME 		= getAddonName() 
base.ADDON_VERSION 		= GetAddOnMetadata( base.ADDON_NAME, "Version")

function base:showPopupMsg( msg )
	UIErrorsFrame:SetTimeVisible(5)
	UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0 ) 
end
function base:enableDebugging()
	base.DEBUGGING_ENABLED = true
end
function base:disableDebugging()
	base.DEBUGGING_ENABLED = false
end
function base:debuggingIsEnabled()
	return base.DEBUGGING_ENABLED
end
function base:enableFloatingText( aura )
	base.FLOATING_TEXT_ENABLED = true
end
function base:disableFloatingText()
	base.FLOATING_TEXT_ENABLED = false
end

local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent( "PLAYER_LOGIN")
eventFrame:SetScript("OnEvent",
function( self, event, ... )
end)

local fileName = "Base.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
