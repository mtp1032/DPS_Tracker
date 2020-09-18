--------------------------------------------------------------------------------------
-- EventHandler.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2019
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.EventHandler = {}
eh = DPS_Tracker.EventHandler
local L = DPS_Tracker.L
local E = errors

local sprintf = _G.string.format
local debugprofilestop = _G.debugprofilestop

--*********************************************************************************
--                      DEV NOTES/LINKS
--  https://wow.gamepedia.com/World_of_Warcraft_API#Units
--  https://wow.gamepedia.com/API_UnitAffectingCombat
--  https://wow.gamepedia.com/API_UnitGUID
--  https://wow.gamepedia.com/API_UnitHealth (Use b4 entering combat to get max health of target)
--  https://wow.gamepedia.com/API_UnitHealthMax (Doesn't work on enemies in Classic)
--  https://wow.gamepedia.com/API_UnitLevel
--  https://wow.gamepedia.com/API_UnitPower
--  https://wow.gamepedia.com/API_UnitStat
--  https://wowwiki.fandom.com/wiki/Events/Unit_Info (e.g., UNIT_COMBAT, UNIT_HEALTH)
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
--	https://us.forums.blizzard.com/en/wow/t/api-getparrychance-and-getblockchance-yield-same-value-classic/386439/2
--

-- ********************************************************************************
--						GLOBAL (TO THIS FILE) CONSTANTS AND VARIABLES
-- ********************************************************************************
	-- indices into the avoidanceCasts table
local DODGE_COUNT 	= 1
local PARRY_COUNT 	= 2
local MISS_COUNT 	= 3

local avoidanceCasts = {
		0, -- DODGE_COUNT
		0, -- PARRY_COUNT
		0  -- MISS_COUNT
	}

--						Indices into the school name table
local PHYSICAL 	= 1
local HOLY 		= 2
local FIRE 		= 3
local NATURE 	= 4
local FROST 	= 5
local SHADOW 	= 6
local ARCANE 	= 7
--					Indices into the damage stats table
local ACCUMULATED_DMG 	= 1
local CRITICAL_DMG 		= 2
local PERIODIC_DMG 		= 3
local NUM_TICKS 		= 4
local PERIODIC_DMG 		= 5
local PET_DMG 			= 6
local RANGED_DMG 		= 7
local RESISTED			= 8	-- amount in stats[17]
local ABSORBED			= 9
local BLOCKED			= 10
local PARRIED 			= 11
local DODGED			= 12
local MISSED			= 13
local GLANCING			= 14
local CRUSHING			= 15
local DEFLECTED			= 16
local TOTAL_AVOIDED		= 17

--						Indices into the healing stats table
local TOTAL_HEALING 		= 1
local TOTAL_OVERHEALED 		= 2
local TOTAL_CRITICAL_HEALS 	= 3
local TOTAL_PERIODIC_HEALS 	= 4

--	These are indices into COMBAT_LOG_EVENT_UNFILTERED stat table returned by CombatLogGetCurrentEventInfo()
local EVENT_TIMESTAMP		= 1		-- valid for all subEvents
local EVENT_SUBEVENT    	= 2		-- valid for all subEvents
local EVENT_HIDECASTER      = 3		-- valid for all subEvents
local EVENT_SOURCEGUID      = 4 	-- valid for all subEvents
local EVENT_SOURCENAME      = 5 	-- valid for all subEvents
local EVENT_SOURCEFLAGS     = 6 	-- valid for all subEvents
local EVENT_SOURCERAIDFLAGS = 7 	-- valid for all subEvents
local EVENT_TARGETGUID      = 8 	-- valid for all subEvents
local EVENT_TARGETNAME      = 9 	-- valid for all subEvents
local EVENT_TARGETFLAGS     = 10 	-- valid for all subEvents
local EVENT_TARGETRAIDFLAGS = 11	-- valid for all subEvents

-- Used for SPELL and SPELL_PERIODIC prefixes. 
local EVENT_SPELLID         = 12 	-- nil for SWING prefex
local EVENT_SPELLNAME       = 13  	-- nil for SWING prefex
local EVENT_SPELLSCHOOL     = 14 	-- nil for SWING prefex

local EVENT_AMOUNT          = 15	-- _DAMAGE suffix
local EVENT_OVERKILL        = 16 	-- _DAMAGE suffix
local EVENT_SCHOOL          = 17	-- _DAMAGE suffix
local EVENT_RESISTED        = 18 	-- _DAMAGE suffix
local EVENT_BLOCKED         = 19 	-- _DAMAGE suffix
local EVENT_ABSORBED        = 20 	-- _DAMAGE suffix
local EVENT_CRITICAL        = 21	-- _DAMAGE suffix
local EVENT_GLANCING        = 22 	-- _DAMAGE suffix
local EVENT_CRUSHING        = 23	-- _DAMAGE suffix

--									Indices into the playerInfo table
local INFO_PLAYER_NAME 		= 1
local INFO_PET_NAME 		= 2

local COMBAT_START_TIME		= 0
local COMBAT_END_TIME		= 0
local COMBAT_EVENT_COUNT	= 0
local PLAYER_DEAD			= false
local PLAYER_IN_COMBAT		= false
local ADDON_ENABLED			= true
local DUMP_COMBAT_LOG		= false	-- dumps all entries in the combat log (CELU)
local elapsedTime 			= 0
local playerCastsMissed		= 0	-- only counts misses by the player
local petCastsMissed		= 0
local playerCastsHit		= 0
local petCastsHit			= 0
local helpFrame				= nil
local addonDisabled			= false
local damageMitigated 		= { 0, 0, 0, 0, 0 }
local debuffTable 			= {}
local CELU_Table 			= {}

local MITIGATED_DMG_BLOCKED 	= 1
local MITIGATED_DMG_DEFLECTED 	= 2
local MITIGATED_DMG_IMMUNE		= 3
local MITIGATED_DMG_REFLECTED	= 4
local MITIGATED_DMG_RESISTED	= 5

--									Tables for collecting various data
local damageStats = {
	0, 			-- 1 Accumulated Damage
	0,			-- 2 Accumulated Critical Damage
	0,			-- 3 Accumulated Periodic Damage
	0,			-- 4 Accumulated Pet Damage
	0,			-- 5 Accumulated Ticks
	0,			-- 6 Accumulated Tick Damage
	0,			-- 7 Accumulated Ranged Damage (notably, wands)
	0,			-- 8 Accumulated Damage resisted
	0, 			-- 9 Accumulated Damage absorbed
	0, 			-- 10 Accumulated Damage blocked
	0,			-- 11 Accumulated Damage parried,
	0,			-- 12 Accumulated Damage dodged,
	0,			-- 13 Accumulated Damage missed
	0,			-- 14 Accumulated Damage glancing
	0,			-- 15 Accumulated Damage crushing
	0,			-- 16 Accumulated damage deflected
	0 }			-- 17 Total damage avoided
local healingStats = {
	0,	-- TOTAL
	0,	-- TOTAL_OVERHEALED
	0, 	-- TOTAL_CRITICAL_HEALS
	0}	-- TOTAL_PERIODIC_HEALS

local playerInfo = { 
	nil,	-- INFO_PLAYER_NAME 
	nil, 	-- INFO_PET_NAME
}
local spellSchoolNames = {
	{1, "Physical"},
	{2, "Holy"},
	{4, "Fire"},
	{8, "Nature"},
	{16, "Frost"},
	{32, "Shadow"},
	{64, "Arcane"}}

local schoolDamageTable = {
	0,							-- Physical damage
	0,							-- Holy damage
	0,							-- Fire damage
	0,							-- Nature damage
	0,							-- Frost damage
	0,							-- Shadow damage
	0}							-- Arcane damage
	
local schoolNameTable = {
	"Physical",
	"Holy",
	"Fire",
	"Nature",
	"Frost",
	"Shadow",
	"Arcane"}

local auraCount = 0
-- ********************************************************************************
--							FUNCTION DEFINITIONS
-- ********************************************************************************
function eh:enableAddon()
	ADDON_ENABLED = true
end
function eh:disableAddon()
	ADDON_ENABLED = false
end
local function printMsg( msg )
	DEFAULT_CHAT_FRAME:AddMessage( msg, 1.0, 1.0, 0.0, 8.0 )
end
local function isGuardianType( flags )
	return bit.band( flags, COMBATLOG_OBJECT_TYPE_MASK ) == bit.band( flags, COMBATLOG_OBJECT_TYPE_GUARDIAN )
end
local function isPetType( flags )
	return bit.band( flags, COMBATLOG_OBJECT_TYPE_MASK ) == bit.band( flags, COMBATLOG_OBJECT_TYPE_PET )
end
local function isPlayerType( flags )
	return bit.band( flags, COMBATLOG_OBJECT_TYPE_MASK ) == bit.band( flags, COMBATLOG_OBJECT_TYPE_PLAYER )
end
local function isPlayersGuardian( flags )
	if isGuardianType( flags ) == false then
		return false
	end
	-- 	Is this guardian affiliated with (belong to) the player
	return bit.band( flags, COMBATLOG_OBJECT_AFFILIATION_MASK) == bit.band( flags, COMBATLOG_OBJECT_AFFILIATION_MINE)
end
local function isPlayersPet( flags )
	if isPetType( flags ) == false then
		return false
	end
	return bit.band( flags, COMBATLOG_OBJECT_AFFILIATION_MASK) == bit.band( flags, COMBATLOG_OBJECT_AFFILIATION_MINE)
end
local function dumpSubEvent( stats )
	local dataType = nil

	-- DUMPS A SUB EVENT IN A COMMA DELIMITED FORMAT.
	for i = 1, 24 do
		if stats[i] ~= nil then
			local value = nil
			dataType = type(stats[i])

			if dataType ~= "string" then
				value = tostring( stats[i] )
			else
				value = stats[i]
			end
			mf:postMsg( sprintf("arg[%d] %s, ", i, value ))
		else
			mf:postMsg( sprintf("arg[%d] nil, ", i))
		end
	end
	mf:postMsg( sprintf("\n\n"))
end	
local function dumpCELU()
	local num = #CELU_Table
	for i = 1, num do
		local stats = CELU_Table[i]
		dumpSubEvent( stats )
	end
end
local function setPlayerInfo()
	playerInfo[INFO_PLAYER_NAME] = UnitName("Player")
	playerInfo[INFO_PET_NAME] = UnitName("Pet")
	return
end
-- CHECKS WHETHER THE UNIT IS THE PLAYER OR THE PLAYER'S
-- PET OR GUARDIAN. RETURNS FALSE IF NOT.
local function isUnitValid( stats )		
	local sourceName = stats[EVENT_SOURCENAME]
	local sourceFlags = stats[EVENT_SOURCEFLAGS]
	local targetName = stats[EVENT_TARGETNAME]
	local targetFlags = stats[EVENT_TARGETFLAGS]

	local unitIsValid = false
	setPlayerInfo()
	local player = playerInfo[INFO_PLAYER_NAME]
	local pet = playerInfo[INFO_PET_NAME]
	
	-- is this unit a pet and, if so, does the pet belong to the
	-- player?
	if pet ~= nil then
		if isPlayersPet( sourceFlags) or isPlayersPet( targetFlags ) then
			unitIsValid = true
		end
	end
	-- is this unit the player's guardian (e.g., the Warlock's Darkglare)?
	if unitIsValid == false then
		if isPlayersGuardian( sourceFlags) or isPlayersGuardian( targetFlags ) then
			unitIsValid = true
		end
	end
	-- is this unit the source or target of the attack?
	if unitIsValid == false then
		if player == sourceName or player == targetName then
			unitIsValid = true
		end
	end
	return unitIsValid
end
local function getSpellSchoolName( spellSchoolNumber )
	local spellSchoolName = nil
	for key, value in pairs(spellSchoolNames) do
		local t = spellSchoolNames[key]
		if t[1] == spellSchoolNumber then 
			spellSchoolName = t[2]
            return spellSchoolName
		end
	end
	return spellSchoolName
end
local function accumDmgBySchool( schoolName, damage )
	if schoolName == "Physical" then
		index = PHYSICAL
	end
	if schoolName == "Holy" then
		index = HOLY
	end
	if schoolName == "Fire" then
		index = FIRE
	end
	if schoolName == "Nature" then
		index = NATURE
	end
	if schoolName == "Frost" then
		index = FROST
	end
	if schoolName == "Shadow" then
		index = SHADOW
	end
	if schoolName == "Arcane" then
		index = ARCANE
	end
	schoolDamageTable[index] = schoolDamageTable[index] + damage
end
local function getSchoolDmg( dmgTableIndex )
	local schoolName = schoolNameTable[dmgTableIndex]
	local schoolDmg = schoolDamageTable[dmgTableIndex]
	return schoolName, schoolDmg
end
local function reset()
	COMBAT_START_TIME 	= 0		-- Timestamp of the player's first combat event
	COMBAT_END_TIME		= 0		-- timestamp of the player's last combat event
	COMBAT_EVENT_COUNT	= 0
	PLAYER_IN_COMBAT	= false
	PLAYER_DEAD			= false
	STOP_COMBAT			= false
	CELU_Table			= {}
	elapsedTime			= 0
	damageStats 		= {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	damageMitigated 	= { 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	healingStats 		= {0, 0, 0, 0}
	schoolDamageTable 	= {0, 0, 0, 0, 0, 0, 0}
	avoidanceCasts		= {0, 0, 0 }
	playerCastsMissed 	= 0
	petCastsMissed		= 0
	playerCastsHit		= 0
	petCastsHit			= 0
	auraCount			= 0
	playerInfo			= {nil, nil}
	debuffTable			= {}
end
local function getMitigatedDamage()
	local sum = 0
	for i = MITIGATED_DMG_BLOCKED, MITIGATED_DMG_RESISTED do
		sum = sum + damageMitigated[i]
	end
	return sum
end
local function anyDebuffsActive()
	for i,v in pairs(debuffTable) do
		if debuffTable[i] == true then
			return true
		end
	end
	return false
end
local function collectAuraStats( stats )
	local subEvent 		= stats[2]
	local sourceName 	= stats[5]
    local targetName	= stats[9]
	local auraName 		= stats[13]
	local auraType		= stats[15]
	local auraAmount	= stats[16]
	local logEntry 		= nil

	if subEvent ~= "SPELL_AURA_REMOVED" and
		subEvent ~= "SPELL_AURA_REMOVED_DOSE" and
		subEvent ~= "SPELL_AURA_APPLIED" and
		subEvent ~= "SPELL_AURA_APPLIED_DOSE" then
		return
	end

	if auraType ~= "DEBUFF" then
		return nil
	end
	if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_APPLIED_DOSE" then
		if debuffTable[auraName] ~= true then
			debuffTable[auraName] = true
			auraCount = auraCount + 1
			if auraAmount ~= nil then
				logEntry = sprintf("%s debuff applied %d to %s.\n", auraName, auraAmount, targetName )
			else
				logEntry = sprintf("%s debuff applied to %s.\n", auraName, targetName )
			end
		end
	end

	if subEvent == "SPELL_AURA_REMOVED" or subEvent == "SPELL_AURA_REMOVED_DOSE" then
		if debuffTable[auraName] == true then
			debuffTable[auraName] = false
			auraCount = auraCount - 1
			logEntry = sprintf("%s removed or expired.\n", auraName )
		end
	end
	return logEntry
end
local function collectAuraBrokenStats( stats)
	local subEvent 		= stats[EVENT_SUBEVENT]
	local sourceName	= stats[EVENT_SOURCENAME]
	local targetName 	= stats[EVENT_TARGETNAME]
	local spellName 	= stats[EVENT_SPELLNAME]
	local currentTime	= stats[EVENT_TIMESTAMP]
	local extraSpellName = stats[16]
	local logEntry		= nil

	if subEvent ~= "SPELL_AURA_BROKEN" and
	   subEvent ~= "SPELL_AURA_BROKEN_SPELL" then
		return
	end
	if subEvent == "SPELL_AURA_BROKEN" then
		local logEntry = sprintf("%s's %s spell broken.\n", targetName, spellName)
	end
	if subEvent == "SPELL_AURA_BROKEN_SPELL" then
		local logEntry = sprintf("%s's %s spell broken by %s's %s\n", targetName, spellName, sourceName, extraSpellName )
	end
	return logEntry
end
local function collectHealingStats( stats )
	local subEvent 			= stats[2]
    local sourceName 	    = stats[5]
    local targetName 	    = stats[9]
    local spellName 	    = stats[13]
    local amountHealed 		= stats[15]
    local amountOverHealed  = stats[16]
    local damageAbsorbed    = stats[17]
	local wasCritical 	    = stats[18]

	if subEvent ~= "SPELL_HEAL" and subEvent ~= "SPELL_PERIODIC_HEAL" then
		return nil
	end
 	if amountHealed ~= nil and amountHealed > 0 then
		healingStats[TOTAL_HEALING] = healingStats[TOTAL_HEALING] + amountHealed
		if subEvent == "SPELL_PERIODIC_HEAL" then
			healingStats[TOTAL_PERIODIC_HEALS] = healingStats[TOTAL_PERIODIC_HEALS] + amountHealed
		end	
    	if wasCritical then
        	healingStats[TOTAL_CRITICAL_HEALS] = healingStats[TOTAL_CRITICAL_HEALS] + amountHealed
		end
	end

	if amountOverHealed ~= nil and amountOverHealed > 0 then
		healingStats[TOTAL_OVERHEALED] = healingStats[TOTAL_OVERHEALED] + amountOverHealed
	end
    
    local str1 = sprintf("%s's %s", sourceName, spellName )
    local str2 = nil
    local str3 = nil

    if wasCritical then
        str2 = sprintf(" critically healed %s for %d", targetName, amountHealed)
    else
        str2 = sprintf(" healed %s for %d", targetName, amountHealed)
    end

    if amountOverHealed ~= nil and amountOverHealed > 0 then
        str3 = sprintf(" (OVERHEALED %d.\n", amountOverHealed )
    else
        str3 = sprintf(".\n", str1)
	end
    return str1..str2..str3
end
local function collectMissedStats( stats )
	local subEvent = stats[EVENT_SUBEVENT]
	local playersName = playerInfo[INFO_PLAYER_NAME]
	local playersPet = playerInfo[INFO_PET_NAME]

	-- if not a *_MISSED subevent, then return
	if subEvent ~= "SPELL_MISSED" and
	   subEvent ~= "RANGE_MISSED" and
	   subEvent ~= "SWING_MISSED" and
	   subEvent ~= "SPELL_PERIODIC_MISSED" then
		return nil
	end

	local sourceName 	= stats[EVENT_SOURCENAME]
	local target 		= stats[EVENT_TARGETNAME]
	local spellName 	= stats[EVENT_SPELLNAME]
	local missType		= stats[15]
	local isOffHandMiss = stats[16]
	local amountMissed  = stats[17]
	local isCritical	= stats[18]

	if subEvent == "SWING_MISSED" then
		missType		= stats[12]
		isOffHandMiss 	= stats[13]
		amountMissed  	= stats[14]
		isCritical		= stats[15]
	end

	if missType == nil then
		return nil
	end

	-- Set to 0 if amountMissed is nil
	if amountMissed == nil then
		amountMissed = 0
	end
	if target == playersName or target == playersPet then
		damageStats[TOTAL_AVOIDED] = damageStats[TOTAL_AVOIDED] + amountMissed
	end

	-- Update the player and pet cast counts
	if sourceName == playersName then
		playerCastsMissed = playerCastsMissed + 1
	end
	if sourceName == playersPet then
		petCastsMissed = petCastsMissed + 1
	end
	
	if subEvent == "SWING_MISSED" and isOffHand then
		spellName = "melee attack (Off-Hand)"
	else
		spellName = "melee attack"
	end
		
	local logEntry = nil

	if missType == "DEFLECT" then
		damageMitigated[MITIGATED_DMG_DEFLECTED] = damageMitigated[MITIGATED_DMG_DEFLECTED] + amountMissed
		logEntry = sprintf("%s's %s DEFLECTED by %s\n", sourceName, spellName, target)

	elseif missType == "IMMUNE" then
		damageMitigated[MITIGATED_DMG_IMMUNE] = damageMitigated[MITIGATED_DMG_IMMUNE] + amountMissed
		logEntry = sprintf("%s's %s failed: %s IMMUNE\n", sourceName, spellName, target )

	elseif missType == "REFLECTED" then
		damageMitigated[MITIGATED_DMG_REFLECTED] = damageMitigated[MITIGATED_DMG_REFLECTED] + amountMissed
		logEntry = sprintf("%s's %s REFLECTED by %s\n", sourceName, spellName, target )

	elseif missType == "PARRY" then
		avoidanceCasts[PARRY_COUNT] = avoidanceCasts[PARRY_COUNT] + 1  
		logEntry = sprintf("%s's %s PARRIED by %s\n", sourceName, spellName, target)

	elseif missType == "MISS" then
		avoidanceCasts[MISS_COUNT] = avoidanceCasts[MISS_COUNT] + 1  
		logEntry = sprintf("%s's %s MISSED %s\n", sourceName, spellName, target )

	elseif missType == "DODGE" then
		avoidanceCasts[DODGE_COUNT] = avoidanceCasts[DODGE_COUNT] + 1  
		logEntry = sprintf("%s's %s DODGED by %s\n", sourceName, spellName, target )

	elseif missType == "MISS" then
		avoidanceCasts[MISS_COUNT] = avoidanceCasts[MISS_COUNT] + 1  
		logEntry = sprintf("%s's %s MISSED %s\n", sourceName, spellName, target )
	
	elseif missType ~= "ABSORB" and 
		   missType ~= "RESIST" and 
		   missType ~= "BLOCK" and
		   missType ~= "PARRY" then
			logEntry = sprintf("Unknown Miss Type, %s (%d damage mitigated)\n", missType )	
	end

	return logEntry
end
local function collectDamageStats(stats)
	local subEvent 		= stats[EVENT_SUBEVENT]

	if subEvent ~= "SPELL_DAMAGE" and
	   subEvent ~= "SPELL_PERIODIC_DAMAGE" and
	   subEvent ~= "RANGE_DAMAGE" and
	   subEvent ~= "SWING_DAMAGE" then
		return
	 end

	 setPlayerInfo()
	local targetName 	= stats[EVENT_TARGETNAME]
	local playersName 	= playerInfo[INFO_PLAYER_NAME]
	local playersPet  	= playerInfo[INFO_PET_NAME]
	local isRanged 		= false
	local logEntry		= nil

	-- these values are for SPELL_DAMAGE, RANGE_DAMAGE, and SPELL_PERIODIC_DAMAGE
	local sourceName  = stats[EVENT_SOURCENAME]
	local targetName = stats[EVENT_TARGETNAME]
	local sourceFlags = stats[EVENT_SOURCEFLAGS]
	local spellName   = stats[13]
	local spellSchool = stats[14] -- identical to stats[17]
	local damage      = stats[15] 
	local overkill    = stats[16] 
	local schoolIndex = stats[17] -- identical to stats[14]
	local resisted    = stats[18] 
	local blocked     = stats[19] 
	local absorbed    = stats[20] 
	local isCritical  = stats[21] 
	local glancing    = stats[22] 
	local crushing    = stats[23] 
	local isOffHand   = stats[24] 

	-- these values are for SWING_DAMAGE. Note that they have different
	-- indices and so over-write the
	-- previous values
	if subEvent == "SWING_DAMAGE" then
		spellName 		= "melee attack"
		damage 			= stats[12]
		overkill 		= stats[13]
		spellSchool 	= stats[14]
		resisted 		= stats[15]
		blocked 		= stats[16]
		absorbed 		= stats[17]
		isCritical 		= stats[18]	
		glancing		= stats[19]
		crushing		= stats[20]
		isOffHand		= stats[21]
	end
	
	if subEvent == "RANGE_DAMAGE" then
		spellName = "Ranged attack"
		isRanged = true
	end

	local playersGuardian = isPlayersGuardian( sourceFlags )
	if sourceName ~= playersName and
		targetName ~= playersName and
		sourceName ~= playersPet and
		targetName ~= playersPet and
		playersGuardian ~= true then
		return
	end
	local schoolName = getSpellSchoolName( spellSchool )

	local logStr = nil
	if isCritical then
		logStr = sprintf("%s %s's dealt %d critical %s damage to %s", sourceName, spellName, damage, schoolName, targetName )
	else
		logStr = sprintf("%s's %s dealt %d %s damage to %s", sourceName, spellName, damage, schoolName, targetName )
	end
	if suffix then
		logStr = logStr..suffix
	end
	
	suffix = nil
	if crushing then
		suffix = "CRUSHING BLOW"
	end
	-- if glancing ~= nil and glancing > 0 then
	if glancing then
		suffix = "(GLANCING BLOW)"
	end
	if suffix == nil then
		logEntry = sprintf("%s\n", logStr)
	else
		logEntry = sprintf("%s %s\n", logStr, suffix)
	end

	if sourceName == playersName then
		playerCastsHit = playerCastsHit + 1
	end
	if sourceName == playersPet then
		petCastsHit = petCastsHit + 1
	end

	local suffix = nil
	local netDamage = damage
	if resisted then
		damageMitigated[MITIGATED_DMG_RESISTED] = damageMitigated[MITIGATED_DMG_RESISTED] + resisted
		damageStats[RESISTED] = damageStats[RESISTED] + resisted
		damageStats[TOTAL_AVOIDED] = damageStats[TOTAL_AVOIDED] + resisted
		netDamage = damage - resisted
		suffix = sprintf(" (%d RESISTED)", resisted )
	end
	if blocked then
		damageMitigated[MITIGATED_DMG_BLOCKED] = damageMitigated[MITIGATED_DMG_BLOCKED] + blocked
		damageStats[BLOCKED] = damageStats[BLOCKED] + blocked
		damageStats[TOTAL_AVOIDED] = damageStats[TOTAL_AVOIDED] + blocked
		netDamage = damage - blocked
		suffix = sprintf(" (%d BLOCKED)", blocked )
	end
	if absorbed then
		damageStats[ABSORBED] = damageStats[ABSORBED] + absorbed
		damageStats[TOTAL_AVOIDED] = damageStats[TOTAL_AVOIDED] + absorbed
		netDamage = damage - absorbed
		suffix = sprintf(" (%d ABSORBED)", absorbed )
	end

	-- This conditional ensures that we only collect data caused by
	-- the player or the player's pet.
	if sourceName == playersName or sourceName == playersPet then
		-- accumulate total damage
		damageStats[ACCUMULATED_DMG] = damageStats[ACCUMULATED_DMG] + netDamage
		-- accumulate critical damage
		if isCritical then
			damageStats[CRITICAL_DMG] = damageStats[CRITICAL_DMG] + netDamage
		end
		-- accumulate ranged damage
		if isRanged then
			damageStats[RANGED_DMG] = damageStats[RANGED_DMG] + netDamage
		end
		-- accumulate pet damage
		if sourceName == playersPet then
			damageStats[PET_DMG] = damageStats[PET_DMG] + netDamage
		end
		-- accumulate periodic damage

		if subEvent == "SPELL_PERIODIC_DAMAGE" then
				
			if sourceName == playersName or sourceName == playersPet then
				damageStats[NUM_TICKS] = damageStats[NUM_TICKS] + 1
				damageStats[PERIODIC_DMG] = damageStats[PERIODIC_DMG] + netDamage
			end
		end
		accumDmgBySchool( schoolName, netDamage )
	end
	return logEntry
end
local function collectLeechStats( stats )
	-- if not a SPELL_LEECH subevent, then return
	if subEvent ~= "SPELL_LEECH" then
		return nil
	end

	local sourceName 	= stats[EVENT_SOURCENAME]
	local target 		= stats[EVENT_TARGETNAME]
	local spellName 	= stats[EVENT_SPELLNAME]
	local amountLeeched	= stats[15]
	local leechType		= stats[16]
	local logEntry = nil
	if amountLeeched ~= nil then
		logEntry = sprintf("%d of %s LEECHED from %s\n", amountLeeched, leechType, target )
	end
	return logEntry
end
local function summarizeCombat( elapsedTime )

	local totalDamage 		= damageStats[ACCUMULATED_DMG]
	local criticalDamage 	= damageStats[CRITICAL_DMG]
	local periodicDamage 	= damageStats[PERIODIC_DMG]
	local numTicks 			= damageStats[NUM_TICKS]
	local tickDamage		= damageStats[PERIODIC_DMG]
	local petDamage 		= damageStats[PET_DMG]
	local rangedDamage		= damageStats[RANGED_DMG]
	local resisted			= damageStats[RESISTED]
	local absorbed			= damageStats[ABSORBED]
	local blocked			= damageStats[BLOCKED]
	local effectiveDamage 	= totalDamage
	local effectiveDPS		= 0

	if elapsedTime == 0 then
		return nil
	end
	-- TOTAL DAMAGE
	local summaryLine = {}
	local totalDPS = totalDamage/elapsedTime
	if (playerCastsHit + playerCastsMissed ) > 0 then
		effectiveDamage = totalDamage * (playerCastsHit/ (playerCastsHit + playerCastsMissed))
	end
	effectiveDPS = effectiveDamage/elapsedTime

	local s = sprintf("Total casts %d, Successful casts %d, Missed casts %d\n", playerCastsHit+playerCastsMissed, playerCastsHit, playerCastsMissed )
	if playerCastsMissed > 0 then
		summaryLine[1] = sprintf("\n%d Total Damage (%.02f DPS, %.02f Effective DPS).\n", totalDamage, totalDPS, effectiveDPS )
	else
		summaryLine[1] = sprintf("\n%d total damage (%.02f DPS).\n", totalDamage, totalDPS )
	end

	-- CRITICAL DAMAGE
	local percentOfTotal = 0
	if criticalDamage > 0 then
		summaryLine[2] = sprintf("%d critical damage (%.02f%% of total)\n", criticalDamage, (criticalDamage/totalDamage*100))
	else
		summaryLine[2] = nil
	end

	-- PERIODIC DAMAGE
	local percentOfTotal = 0
	if periodicDamage > 0 then
		percentOfTotal = (periodicDamage / totalDamage) * 100
		summaryLine[3] = sprintf("%d periodic damage (%.02f%% of total)\n",periodicDamage, percentOfTotal )
	else
		summaryLine[3] = nil
	end

	-- PET DAMAGE
	local percentOfTotal = 0
	if petDamage > 0 then
		percentOfTotal = (petDamage / totalDamage) * 100
		summaryLine[4] = sprintf("%d pet damage (%.02f%% of total)\n", petDamage, percentOfTotal  )
	else
		summaryLine[4] = nil
	end

	-- RANGED DAMAGE
	local percentOfTotal = 0
	if rangedDamage > 0 then
		percentOfTotal = (rangedDamage / totalDamage) * 100
		summaryLine[5] = sprintf("%d ranged damage (%.02f%%)\n", rangedDamage, percentOfTotal )
	else
		summaryLine[5] = nil
	end
	
	-- DAMAGE RESISTED OR BLOCKED
	local mitigatedDmg = getMitigatedDamage()

	percentOfTotal = 0
	if mitigatedDmg > 0 then
		local percentMitigatedDmg = mitigatedDmg/totalDamage*100
		summaryLine[6] = sprintf("Damage Resisted or Blocked by Target: %d (%.02f%% of total damage)\n", mitigatedDmg, percentMitigatedDmg  )
	else
		summaryLine[6] = nil
	end
	percentOfTotal = 0
	if absorbed > 0 then
		percentOfTotal = (absorbed/totalDamage) * 100
		summaryLine[7] = sprintf("%d damage absorbed by %s (%.02f%%)\n", absorbed, playersName, percentOfTotal)
	else
		summaryLine[7] = nil
	end
	percentOfTotal = 0
	if blocked > 0 then
		percentOfTotal = (blocked/totalDamage) * 100
		summaryLine[8] = sprintf("%d damage BLOCKED (%.02f%%)\n", blocked, percentOfTotal)
	else
		summaryLine[8] = nil
	end

	cl:postLogEntry( sprintf("\n*** COMBAT SUMMARY ***\n"))
	local s = sprintf("Combat Ended After %.02f seconds\n", elapsedTime )
	cl:postLogEntry(s )

	for i =1, 8 do
		if summaryLine[i] ~= nil then
			cl:postLogEntry( summaryLine[i])
		end
	end

	-- 	DAMAGE BY SCHOOL
	local schoolDmgEntry = {nil, nil, nil, nil, nil, nil, nil}
	n = 0
	for i = PHYSICAL, ARCANE do
		schoolName, schoolDmg = getSchoolDmg( i )
		n = n + 1
		if schoolDmg > 0 then
			percentOfTotal = (schoolDmg / totalDamage) * 100
			schoolDmgEntry[n] = sprintf("%s: %d damage (%.02f%% of total)\n", schoolName, schoolDmg, percentOfTotal )
		else
			schoolDmgEntry[n] = nil
		end
	end

	local dodgeCount = avoidanceCasts[DODGE_COUNT]
	local parryCount = avoidanceCasts[PARRY_COUNT]
	local missCount  = avoidanceCasts[MISS_COUNT]
	totalAvoidanceCasts = dodgeCount + parryCount + missCount

	local defenseStr = sprintf("No failed casts (missed, dodged, or parried\n")
	if totalAvoidanceCasts > 0 then
		defenseStr = sprintf("%d Mitigated Attacks: %d Missed, %d Dodged, %d Parried\n", totalAvoidanceCasts, missCount, dodgeCount, parryCount )
	end
	cl:postLogEntry( defenseStr )

	local s = "Damage by School"
	cl:postLogEntry( sprintf("-- %s\n", s ))
	for i = PHYSICAL, ARCANE do
		if schoolDmgEntry ~= nil then
			cl:postLogEntry( schoolDmgEntry[i])
		end
	end
	-- TOTAL HEALING
	local totalHealing 		= healingStats[TOTAL_HEALING]
	local criticalHealing	= healingStats[TOTAL_CRITICAL_HEALS]
	local overHealing		= healingStats[TOTAL_OVERHEALED]
	local periodicHealing	= healingStats[TOTAL_PERIODIC_HEALS]
	
	local healTable = {nil,nil,nil,nil}
	if totalHealing > 0 then
		cl:postLogEntry("-- Healing Stats\n")
		local totalHPS = (totalHealing/elapsedTime)
		healTable[1] = sprintf("Total Healing: %d\n", totalHealing )
	end
	if criticalHealing > 0 then
		healTable[2] = sprintf("Total Critical Healing: %d (%.02f%% of total)\n", criticalHealing, (criticalHealing /totalHealing)*100)
	end
	if overHealing > 0 then
		healTable[3] = sprintf("Total Overhealing: %d (%.02f%% of total)\n", overHealing, (overHealing/totalHealing)*100)
	end
	if periodicHealing > 0 then
		healTable[4] = sprintf("Total Periodic Healing: %d (%.02f%% of total)\n", periodicHealing, (periodicHealing/totalHealing)*100)
	end
	for i = 1, 4 do
		if healTable[i] ~= nil then
			cl:postLogEntry( healTable[i])
		end
	end
	healingStats = {0,0,0,0}

	cl:postLogEntry(sprintf("\n"))
end
local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent( "ADDON_LOADED")
eventFrame:RegisterEvent( "PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent( "PLAYER_LOGIN")
eventFrame:RegisterEvent( "PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent( "PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED") 
eventFrame:SetScript("OnEvent",
function( self, event, ... )
	local arg1, arg2, arg3, arg4 = ...

	if event == "ADDON_LOADED" and arg1 == "DPS_Tracker" then
		printMsg( L["ADDON_LOADED_MSG"])
	end
	if event == "PLAYER_ENTERING_WORLD" then 
		eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		return
	end
	if event == "PLAYER_LOGIN" then
		-- Init everything: this is where the magic happens
		if playerInfo[INFO_PLAYER_NAME] == nil then
			setPlayerInfo()
		end
		return
	end
	if event == "PLAYER_REGEN_DISABLED" then
		PLAYER_IN_COMBAT = true
		if playerInfo[INFO_PLAYER_NAME] == nil then
			setPlayerInfo()
		end
		local msg = sprintf("%s entered combat.\n", playerInfo[INFO_PLAYER_NAME] )
		printMsg( msg )
		return
	end
	if event == "PLAYER_REGEN_ENABLED" then
			PLAYER_IN_COMBAT = false
			local msg = sprintf("%s exited combat.\n", playerInfo[INFO_PLAYER_NAME] )
			printMsg( msg )
			summarizeCombat( elapsedTime )
			-- if DUMP_COMBAT_LOG then 
			-- 	dumpCELU()
			-- end
			reset()
	end
	if event == "COMBAT_LOG_EVENT_UNFILTERED" and addonDisabled == false then

		local stats = {CombatLogGetCurrentEventInfo()}		-- BLIZZ API
		local subEvent = stats[EVENT_SUBEVENT]
		local logEntry = nil

		-- log each of the following subEvents
		if 	subEvent ~= "SWING_DAMAGE" and
			subEvent ~= "UNIT_DIED" and
			subEvent ~= "RANGE_DAMAGE" and
			subEvent ~= "SPELL_DAMAGE" and 
			subEvent ~= "SPELL_SUMMON" and
			subEvent ~= "SPELL_PERIODIC_DAMAGE" and
			subEvent ~= "SPELL_LEECH" and
			subEvent ~= "SWING_MISSED" and
			subEvent ~= "RANGE_MISSED" and
			subEvent ~= "SPELL_MISSED" and 
			subEvent ~= "SPELL_PERIOD_MISSED" and
			subEvent ~= "SPELL_HEAL" and
			subEvent ~= "SPELL_CAST_START" and
			subEvent ~= "SPELL_CAST_SUCCESS" and
			subEvent ~= "SPELL_CAST_FAILED" and
			subEvent ~= "SPELL_PERIODIC_HEAL" and
			subEvent ~= "SPELL_INTERRUPT" and
			subEvent ~= "SPELL_AURA_APPLIED" and	-- crowd control spell 
			subEvent ~= "SPELL_AURA_APPLIED_DOSE" and
			subEvent ~= "SPELL_AURA_REMOVED" and	-- crowd control spell expired
			subEvent ~= "SPELL_AURA_REMOVED_DOSE" and
			subEvent ~= "SPELL_AURA_BROKEN" and		-- crowd control spell was broken
			subEvent ~= "SPELL_AURA_BROKEN_SPELL" then
			-- do nothing. It's an event of no interest
			return
		end
					
		if PLAYER_IN_COMBAT == false or PLAYER_DEAD then
			return
		end
		-- return if this unit (pet, player, guardian) is not the source or target of the attack.
		if isUnitValid( stats ) == false then
			return
		end
		if COMBAT_EVENT_COUNT == 0 then
			COMBAT_START_TIME = stats[EVENT_TIMESTAMP]
			COMBAT_END_TIME = COMBAT_START_TIME
			elapsedTime = 0
		end
	
		COMBAT_EVENT_COUNT 	= COMBAT_EVENT_COUNT + 1
		COMBAT_END_TIME 	= stats[EVENT_TIMESTAMP]
		elapsedTime 		= COMBAT_END_TIME - COMBAT_START_TIME

		-- Insert event into the CELU table
		-- if DUMP_COMBAT_LOG then
		-- CELU_Table[COMBAT_EVENT_COUNT] = stats
		-- end

		--				PROCESS ALL DAMAGE EVENTS
		logEntry = collectDamageStats( stats )
		if logEntry ~= nil then
			cl:postLogEntry( logEntry )
			return
		end		
		--				PROCESS ALL SPELL_LEECH SUBEVENTS
		logEntry = collectLeechStats( stats )
		if logEntry ~= nil then
			cl:postLogEntry( logEntry)
			return
		end
		--				PROCESS ALL MISSED SUBEVENTS
		logEntry = collectMissedStats( stats )
		if logEntry ~= nil then
			cl:postLogEntry( logEntry)
			return
		end
		--			PROCESS ALL AURA SUBEVENTS
		logEntry = collectAuraStats(stats)
		if logEntry ~= nil then
			cl:postLogEntry( logEntry)
			return
		end
		logEntry = collectAuraBrokenStats(stats)
		if logEntry ~= nil then
			cl:postLogEntry( logEntry )
			return
		end
		--				PROCESS ALL HEALING SUBEVENTS
		logEntry = collectHealingStats( stats )
		if logEntry ~= nil then
			cl:postLogEntry( logEntry )
			return
		end
		--				PROCESS UNIT DIED
		if subEvent == "UNIT_DIED" then
			-- recapLink = GetDeathRecapLink( stats[12])
			-- dumpSubEvent( stats )
			PLAYER_DEAD = true
			cl:postLogEntry( sprintf("%s has died\n", stats[EVENT_TARGETNAME] ))
			return
		end
	end
end)

-- **************************************************************************************
--						SLASH COMMANDS
-- **************************************************************************************
function eh:hideHelpFrame()
	if helpFrame == nil then
		return
	end
	if helpFrame:IsVisible() == true then
		helpFrame:Hide()
	end
end
function eh:showHelpFrame()
	if helpFrame == nil then
		helpFrame = celd:createHelpFrame()
	end
	if helpFrame:IsVisible() == false then
		helpFrame:Show()
	end

end
function eh:clearHelpText()
	if helpFrame == nil then
		return
	end
	helpFrame.Text:EnableMouse( false )    
	helpFrame.Text:EnableKeyboard( false )   
	helpFrame.Text:SetText("") 
	helpFrame.Text:ClearFocus()
end

local line1  = sprintf("\n%s\n", "DPS Tracker: slash commands\n")
local line2  = sprintf("   help - This message\n")
local line3  = sprintf("   show - Displays the tracker window\n")
local line4  = sprintf("   hide - Hides the tracker window\n")
local line5  = sprintf("   delete - Deletes the entries in the tracker window\n")
-- local line6  = sprintf("   enable - Enables logging\n")
-- local line7  = sprintf("   disable - Disables logging (only show the encounter summaries)\n")
-- local line8  = sprintf("   stop - immediately stops logging and combat.\n")
local line6  = sprintf("   config - Display the DPS_Tracker configuration options.\n") 
local line7 = sprintf("   config - Click the <RedX> minimap button\n")

local helpMsg = line1..line2..line3..line4..line5..line6..line7

local function postHelpMsg( helpMsg )
	if helpFrame == nil then
		helpFrame = fm:createHelpFrame( "DPS Tracker V3.5 Help")
	end
	fm:showFrame( helpFrame )
	helpFrame.Text:Insert( helpMsg )
end

SLASH_DPS_TRACKER1 = "/dps"
SlashCmdList["DPS_TRACKER"] = function( msg )
	if msg == nil then
		msg = "help"
	end
	if msg == "" then
		msg = "help"
	end

	msg = string.upper( msg )
	if msg == "HELP" then
		postHelpMsg( helpMsg )
	elseif msg == "SHOW" then
		cl:showFrame()
	elseif msg == "HIDE" then
		cl:hideFrame()
	elseif msg == "DELETE" then
		celd:clearFrameText()
	elseif msg == "CONFIG" then
		InterfaceOptionsFrame_OpenToCategory("DPS_Tracker")
		InterfaceOptionsFrame_OpenToCategory("DPS_Track")
		InterfaceOptionsFrame_OpenToCategory("DPS_Tracker")
	elseif msg == "DUMP" then -- disable logging, but not summary
		DUMP_COMBAT_LOG = true
	elseif msg == "NODUMP" then -- enable logging + summary
		DUMP_COMBAT_LOG = false
	else
		local s = sprintf("DPS_Tracker: '%s' - unknown or invalid command.\n", msg)
		postHelpMsg( s..helpMsg )
	end
end
