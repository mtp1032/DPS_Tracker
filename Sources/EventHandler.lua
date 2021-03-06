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

-- indices into the avoidanceCasts table
local DODGE_COUNT 	= 1
local PARRY_COUNT 	= 2
local MISS_COUNT 	= 3
	
local avoidanceCasts = {
		0, -- DODGE_COUNT
		0, -- PARRY_COUNT
		0  -- MISS_COUNT
	}

local MISS_ABSORB 	= 1
local MISS_BLOCK 	= 2
local MISS_DODGE 	= 3
local MISS_DEFLECT 	= 4
local MISS_EVADE 	= 5
local MISS_IMMUNE 	= 6
local MISS_MISS 	= 7
local MISS_PARRY 	= 8
local MISS_REFLECT 	= 9
local MISS_RESIST 	= 10
local FIRST_MISS = MISS_ABSORB
local LAST_MISS = MISS_RESIST

local damageMitigatedByFoe 	= {0,0,0,0,0,0,0,0,0,0}
local damageMitigatedByFriend = {0,0,0,0,0,0,0,0,0,0}

--						Indices into the school name table
local PHYSICAL 	= 1
local HOLY 		= 2
local FIRE 		= 3
local NATURE 	= 4
local FROST 	= 5
local SHADOW 	= 6
local ARCANE 	= 7
--						Indices into the healing stats table
local TOTAL_HEALING 		= 1
local TOTAL_OVERHEALED 		= 2
local TOTAL_CRITICAL_HEALS 	= 3
local TOTAL_PERIODIC_HEALS 	= 4

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
local debuffTable 			= {}
local CELU_Table 			= {}

--									Tables for collecting various data
--					Indices into the damage accumulator table
local ALL_DMG 		= 1
local SPELL_DMG		= 2
local CRITICAL_DMG	= 3
local PERIODIC_DMG 	= 4
local NUM_TICKS 	= 5
local TICK_DMG		= 6
local PET_DMG 		= 7
local RANGED_DMG 	= 8
local GLANCING		= 9
local CRUSHING		= 10
local DMG_FIRST = SPELL_DMG
local DMG_LAST  = CRUSHING

local damageAccumTable = {
	0, 			-- 1 Accumulated Damage for all types
	0,			-- 2 Accumulated Spell Damage
	0,			-- 3 Accumulated Critical Damage
	0,			-- 4 Accumulated Periodic Damage
	0,			-- 5 Accumulated Num Ticks
	0,			-- 6 Accumulated Tick Damage
	0,			-- 7 Accumulated Pet Damage
	0,			-- 7 Accumulated Tick Damage
	0,			-- 8 Accumulated Ranged Damage (notably, wands)
	0,			-- 9 Accumulated Damage glancing
	0,			-- 10 Accumulated Damage crushing 
}
local healingStats = {
	0,	-- TOTAL
	0,	-- TOTAL_OVERHEALED
	0, 	-- TOTAL_CRITICAL_HEALS
	0}	-- TOTAL_PERIODIC_HEALS

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

local missNameTable = {
	"ABSORB",
	"BLOCK",
	"DEFLECT",
	"DODGE",
	"EVADE",
	"IMMUNE",
	"MISS",
	"PARRY",
	"REFLECT",
	"RESIST"
}

local auraCount = 0
local testCasts = 0
local testMissedCasts = 0

-- ********************************************************************************
--							FUNCTION DEFINITIONS
-- ********************************************************************************
-- Get the miss type from the name table
local function getMissTypeName( index )
	local name = missNameTable[index]
	return name
end
-- Get the index from a name table
local function getMissNameTableIndex( name )
	local index = 0
	if name == "ABSORB" then
		index = MISS_ABSORB
	elseif name == "BLOCK" then 
		index = MISS_BLOCK
	elseif name == "DODGE" then 
		index = MISS_DODGE	
	elseif name == "DEFLECT" then 
		index = MISS_DEFLECT
	elseif name == "EVADE" then 
		index = MISS_EVADE
	elseif name == "IMMUNE" then 
		index = MISS_IMMUNE
	elseif name == "MISS" then 
		index = MISS_MISS
	elseif name == "PARRY" then 
		index = MISS_PARRY
	elseif name == "REFLECT" then 
		index = MISS_REFLECT
	elseif name == "RESIST" then 
		index = MISS_RESIST
	else
		index = -1
	end
	return index
end
-- return name-value pair from a table
local function getTableEntry( tbl, index )
	local name = getMissTypeName( index )
	local value = tbl[index]
	return name, value
end
-- Overwrites existing entry
local function insertTableEntry( tbl, name, value )
	local index = getMissNameTableIndex( name )
	tbl[index] = value
end
-- Adds to existing entry
local function addTableEntry( tbl, name, value )
	local index = getMissNameTableIndex( name )
	tbl[index] = tbl[index] + value
end


local function getPlayerStats( stats )
	eqs:getPlayerStats( stats )
end
local function getPlayerILevel()
	return eqs:getPlayerILevel()
end
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
local function getPlayerInfo()
	local playersName = UnitName("Player")
	local playersPet = UnitName("Pet")
	return playersName, playersPet
end
-- CHECKS WHETHER THE UNIT IS THE PLAYER OR THE PLAYER'S
-- PET OR GUARDIAN. RETURNS FALSE IF NOT.
local function isUnitValid( stats )		
	local sourceName = stats[EVENT_SOURCENAME]
	local sourceFlags = stats[EVENT_SOURCEFLAGS]
	local targetName = stats[EVENT_TARGETNAME]
	local targetFlags = stats[EVENT_TARGETFLAGS]

	local unitIsValid = false
	playersName, playersPet = getPlayerInfo()
	
	-- is this unit a playersPet and, if so, does the pet belong to the
	-- player?
	if playersPet ~= nil then
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
		if playersName == sourceName or playersName == targetName then
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
	playerCastsMissed 	= 0
	petCastsMissed		= 0
	playerCastsHit		= 0
	petCastsHit			= 0
	testCasts			= 0
	testMissedCasts		= 0
	auraCount			= 0
	debuffTable				= {}
	damageAccumTable 		= {0,0,0,0,0,0,0,0,0,0}
	damageMitigatedByFoe 	= {0,0,0,0,0,0,0,0,0,0}
	damageMitigatedByFriend = {0,0,0,0,0,0,0,0,0,0}
	healingStats 			= {0,0,0,0}
	schoolDamageTable 		= {0,0,0,0,0,0,0}
	avoidanceCasts 			= {0,0,0}
	E:where( "testCasts reset to "..tostring(testCasts))
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

	-- if not a *_MISSED subevent, then return
	if subEvent ~= "SPELL_MISSED" and
	   subEvent ~= "RANGE_MISSED" and
	   subEvent ~= "SWING_MISSED" and
	   subEvent ~= "SPELL_PERIODIC_MISSED" then
		return nil
	end
	-- dumpSubEvent( stats )
	local playersName = GetUnitName("Player")
	local playersPet = GetUnitName("Pet")

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

	-- There are 10 kinds of miss types. They are:
	-- ABSORB, BLOCK, DEFLECT, DODGE, EVADE, IMMUNE, MISS, PARRY, REFLECT, and RESIST
	if  missType ~= "ABSORB" and
		missType ~= "BLOCK" and
		missType ~= "DEFLECT" and
		missType ~= "DODGE" and
		missType ~= "EVADE" and
		missType ~= "IMMUNE" and
		missType ~= "MISS" and
		missType ~= "PARRY" and
		missType ~= "REFLECT" and
		misstype ~= "RESIST" then
			mf:postMsg( sprintf("[%s] Unknown miss type - %s\n", E:where(), missType))
			return
		end
	-- Set to 0 if amountMissed is nil
	if amountMissed == nil then
		amountMissed = 0
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

	if amountMissed > 0 then
		logEntry = sprintf("%s mitigated %d (%s) damage by %s's %s\n", target, amountMissed, missType, sourceName, spellName )
		if target == playersName or target == playersPet then
			addTableEntry( damageMitigatedByFriend, missType, amountMissed )
		end
	else
		logEntry = sprintf("%s mitigated all damage (%s) by %s's %s\n", target, missType, sourceName, spellName  )
	end

	return logEntry
end
local function collectDamageStats(stats)
	local subEvent = stats[EVENT_SUBEVENT]

	if subEvent ~= "SPELL_DAMAGE" and
	   subEvent ~= "SPELL_PERIODIC_DAMAGE" and
	   subEvent ~= "RANGE_DAMAGE" and
	   subEvent ~= "SWING_DAMAGE" then
		return
	 end

	playersName = GetUnitName("Player")
	playersPet = GetUnitName("Pet")
	local targetName 	= stats[EVENT_TARGETNAME]
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

	local schoolName = getSpellSchoolName( spellSchool )

	local logStr = nil
	if isCritical then
		logStr = sprintf("%s's %s dealt %d CRITICAL %s damage to %s", sourceName, spellName, damage, schoolName, targetName )
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
		damageMitigated[DMG_RESISTED] = damageMitigated[DMG_RESISTED] + resisted
		damageAccumTable[RESISTED] = damageAccumTable[RESISTED] + resisted
		netDamage = damage - resisted
		suffix = sprintf(" (%d RESISTED)", resisted )
	end

	-- if blocked then
	-- 	damageMitigated[DMG_BLOCKED] = damageMitigated[DMG_BLOCKED] + blocked
	-- 	damageAccumTable[BLOCKED] = damageAccumTable[BLOCKED] + blocked
	-- 	netDamage = damage - blocked
	-- 	suffix = sprintf(" (%d BLOCKED)", blocked )
	-- end

	-- if absorbed then
	-- 	damageAccumTable[DMG_ABSORBED] = damageAccumTable[DMG_ABSORBED] + absorbed
	-- 	netDamage = damage - absorbed
	-- 	suffix = sprintf(" (%d ABSORBED)", absorbed )
	-- end

	-- This conditional ensures that we only collect data caused by
	-- the player or the player's pet.

	if sourceName == playersName or sourceName == playersPet then
		damageAccumTable[ALL_DMG] = damageAccumTable[ALL_DMG] + netDamage
		if isCritical then
			damageAccumTable[CRITICAL_DMG] = damageAccumTable[CRITICAL_DMG] + netDamage
		end
		if isRanged then
			damageAccumTable[RANGED_DMG] = damageAccumTable[RANGED_DMG] + netDamage
		end
		if sourceName == playersPet then
			damageAccumTable[PET_DMG] = damageAccumTable[PET_DMG] + netDamage
		end
		if subEvent == "SPELL_PERIODIC_DAMAGE" then
			if sourceName == playersName then
				damageAccumTable[NUM_TICKS] = damageAccumTable[NUM_TICKS] + 1
				damageAccumTable[PERIODIC_DMG] = damageAccumTable[PERIODIC_DMG] + netDamage
			end
		end
		if subEvent == "SPELL_DAMAGE" then
			if sourceName == playersName then
				damageAccumTable[SPELL_DMG] = damageAccumTable[SPELL_DMG] + netDamage
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

-------------------------------------------------------------------------------
--				Indices into the players combat stats table
local STAT_STAMINA       = 1
local STAT_INTELLECT     = 2
local STAT_HASTE         = 3
local STAT_CRITSTRIKE    = 4
local STAT_MASTERY       = 5
local STAT_AGILITY       = 6
local STAT_VERSATILITY   = 7
local FIRST_STAT = STAT_STAMINA
local LAST_STAT = STAT_VERSATILITY

-------------------------------------------------------------------------------


local function summarizeCombat( elapsedTime )

	local totalDamage 		= damageAccumTable[ALL_DMG]
	local criticalDamage 	= damageAccumTable[CRITICAL_DMG]
	local periodicDamage 	= damageAccumTable[PERIODIC_DMG]
	local numTicks 			= damageAccumTable[NUM_TICKS]
	local tickDamage		= damageAccumTable[PERIODIC_DMG]
	local petDamage 		= damageAccumTable[PET_DMG]
	local rangedDamage		= damageAccumTable[RANGED_DMG]
	local resisted			= damageAccumTable[RESISTED]
	local absorbed			= damageAccumTable[ABSORBED]
	local blocked			= damageAccumTable[BLOCKED]
	local effectiveDamage 	= totalDamage
	local effectiveDPS		= 0
	local spellPower		= 0
	local totalCasts		= playerCastsHit + playerCastsMissed

	E:where( "testCasts "..tostring(testCasts))
	-- E:where( "testMissedCasts "..tostring(testMissedCasts)..", playerCastsMissed "..tostring(playerCastsMissed ))

	if elapsedTime == 0 then
		return nil
	end
	-- TOTAL DAMAGE
	local summaryLine = {}
	local totalDPS = totalDamage/elapsedTime
	if totalCasts > 0 then
		effectiveDamage = totalDamage * (playerCastsHit/ (playerCastsHit + playerCastsMissed))
	end
	effectiveDPS = effectiveDamage/elapsedTime

	spellPower = damageAccumTable[SPELL_DMG] + damageAccumTable[PERIODIC_DMG] / totalCasts

	local s = sprintf("Total casts %d, Successful casts %d, Missed casts %d\n", totalCasts, playerCastsHit, playerCastsMissed )
	if playerCastsMissed > 0 then
		summaryLine[1] = sprintf("\n%.01f Spell Power, %d Total Damage (%.02f DPS, %.02f Effective DPS).\n", spellPower, totalDamage, totalDPS, effectiveDPS )
	else
		summaryLine[1] = sprintf("\n%.01f Spell Power, %d total damage (%.02f DPS).\n", spellPower, totalDamage, totalDPS )
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
	-- MISSED CASTS (SPELL_MISSED SUBEVENTS)
	local mitigated = {}
	local totalMitigatedDmg = 0
	for i = FIRST_MISS, LAST_MISS do
		local nvp = {getTableEntry( damageMitigatedByFriend, i)}
		mitigated[i] = nvp
		if nvp[2] > 0 then
			totalMitigatedDmg = totalMitigatedDmg + nvp[2]
		end
	end
		-- local damageMitigatedByFoe = getMitigatedDamageByFoe()
	-- local damageMitigatedByFriend = getMitigatedDamageByFriend()

	percentOfTotal = 0
 	summaryLine[8] = sprintf("Total damage mitigated by %s (including pet): %d\n", playersName, totalMitigatedDmg )

	
	-- if damageMitigated > 0 then
	-- 	local percentMitigatedDmg = damageMitigated/totalDamage*100
	-- 	summaryLine[6] = sprintf("Damage Resisted or Blocked by Target: %d (%.02f%% of total damage)\n", damageMitigated, percentMitigatedDmg  )
	-- else
	-- 	summaryLine[6] = nil
	-- end
	-- percentOfTotal = 0
	-- if absorbed > 0 then
	-- 	percentOfTotal = (absorbed/totalDamage) * 100
	-- 	summaryLine[7] = sprintf("%d damage absorbed by %s (%.02f%%)\n", absorbed, playersName, percentOfTotal)
	-- else
	-- 	summaryLine[7] = nil
	-- end
	-- percentOfTotal = 0
	-- if blocked > 0 then
	-- 	percentOfTotal = (blocked/totalDamage) * 100
	-- 	summaryLine[8] = sprintf("%d damage BLOCKED (%.02f%%)\n", blocked, percentOfTotal)
	-- else
	-- 	summaryLine[8] = nil
	-- end

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
	local defenseStr = sprintf("%s experienced no failed casts (missed, dodged, or parried\n", playersName )
	-- if totalAvoidanceCasts > 0 then
	-- 	defenseStr = sprintf("%d Mitigated Attacks: %d Missed, %d Dodged, %d Parried\n", totalAvoidanceCasts, missCount, dodgeCount, parryCount )
	-- end
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
	if event == "PLAYER_LOGIN" then
		-- Init everything: this is where the magic happens
		playersName, playersPet = getPlayerInfo()
		return
	end
	if event == "PLAYER_REGEN_DISABLED" then
		PLAYER_IN_COMBAT = true
			
		playersName, playersPet = getPlayerInfo()
		if playersPet == nil then
			printMsg( sprintf("%s entered combat.\n", playersName ) )
		else
			printMsg( sprintf("%s and %s entered combat.\n", playersName, playersPet ) )
		end
	end
	if event == "PLAYER_REGEN_ENABLED" then
			PLAYER_IN_COMBAT = false
			local playersName, playersPet = getPlayerInfo()
			if playersPet == nil then
				printMsg( sprintf("%s exited combat.\n", playersName ) )
			else
				printMsg( sprintf("%s and %s exited combat.\n", playersName, playersPet ) )
			end
			local logging = cl:isCombatLoggingEnabled()
			if logging == false then
				cl:enableCombatLogging()
				summarizeCombat( elapsedTime )
				cl:disableCombatLogging()
			else
				summarizeCombat( elapsedTime )
			end
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
					
		-- if PLAYER_IN_COMBAT == false or PLAYER_DEAD then
		-- 	return
		-- end
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

		local playersName = GetUnitName("Player")
		if stats[EVENT_SOURCENAME] ~= playersName then
			return
		end
		--				PROCESS ALL DAMAGE EVENTS
		if subEvent == "SPELL_CAST_MISS" then
			testMissedCasts = testMissedCasts + 1
		end
		if subEvent == "SPELL_CAST_SUCCESS" then -- track periodic damage casts, not their ticks
			testCasts = testCasts + 1
			print( subEvent..", "..tostring(testCasts) )
		elseif subEvent == "SPELL_DAMAGE" then
			testCasts = testCasts + 1
			print( subEvent..", "..tostring(testCasts) )
		end
   
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

-- local function test()
-- 	for i = FIRST_MISS, LAST_MISS do
-- 		E:where( tostring(i))
-- 		if i == MISS_DEFLECT then
-- 			local missName = getMissTypeName( i )
-- 			local value = 81
-- 			E:where( missName..", "..tostring(value))
-- 			insertTableEntry( damageMitigatedByFoe, missName, value )
-- 			local name, value = getTableEntry( damageMitigatedByFoe,i)
-- 			mf:postMsg( sprintf( "[%s, %d]\n", missName, i ))
-- 		end
-- 		-- local missName = getMissTypeName( i )
-- 		-- insertTableEntry( damageMitigatedByFoe, missName, i )
-- 		-- mf:postMsg( sprintf( "[%s, %d]\n", missName, i ))
-- 	end
-- 	-- mf:postMsg( sprintf("\n"))
-- 	-- for i = FIRST_MISS, LAST_MISS do
-- 	-- 	local name, value = getTableEntry( damageMitigatedByFoe, i )
-- 	-- 	mf:postMsg( sprintf( "[%s, %d]\n", name, value ))
-- 	-- end
-- end
-- test1()

-- local function test2()
-- 	-- populate the mitigation table with data
-- 	for i = FIRST_MISS, LAST_MISS do
-- 		local missName = getMissTypeName(i)
-- 		local value = random( 0, 10 )
-- 		insertTableEntry( damageMitigatedByFoe, missName, value )
-- 		local n,v = getTableEntry( damageMitigatedByFoe, i )
-- 		mf:postMsg( sprintf( "[%s, %d]\n", n, v ))	
-- 	end
-- 	mf:postMsg( sprintf( "\n"))	

-- 	for i = FIRST_MISS, LAST_MISS do
-- 		local name, value = getTableEntry( damageMitigatedByFoe, i )
-- 		mf:postMsg( sprintf( "[%s, %d]\n", name, value ))	
-- 	end
-- 	mf:postMsg( sprintf( "\n"))	
	
-- 	for i = FIRST_MISS, LAST_MISS do
-- 		local missName = getMissTypeName(i)
-- 		local value = random( 0, 10 )
-- 		addTableEntry( damageMitigatedByFoe, missName, value )
-- 		local n,v = getTableEntry( damageMitigatedByFoe, i )
-- 		mf:postMsg( sprintf( "[%s, %d]\n", n, v ))	
-- 	end


-- end
-- test2()


