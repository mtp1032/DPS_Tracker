--------------------------------------------------------------------------------------
-- CleuDB.lua
-- AUTHOR: Michael Peterson 
-- ORIGINAL DATE: 10 October, 2019 
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.CleuDB = {}
cleu = DPS_Tracker.CleuDB 

local libName ="WoWThreads-1.0"
local thread = LibStub:GetLibrary( libName )
if not thread then 
    return 
end

local SIG_ALERT             = thread.SIG_ALERT
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_STOP              = thread.SIG_STOP
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING

local L = DPS_Tracker.L

local sprintf = _G.string.format

SAVED_HEALTHBAR_SETTING = {}

local FRAME_POINT 		= SAVED_HEALTHBAR_SETTING[1]
local REFERENCE_FRAME 	= SAVED_HEALTHBAR_SETTING[2]
local RELATIVE_TO 		= SAVED_HEALTHBAR_SETTING[3]
local OFFSET_X 			= SAVED_HEALTHBAR_SETTING[4]
local OFFSET_Y			= SAVED_HEALTHBAR_SETTING[5]

-- these are temporary tables of
-- the strings that are displayed
-- floating combat text 
local cleuStatsDB 		= {}	-- a table containing stats/subEvents from from all CLEU events

-- These DBs contain the strings displayed by the various display threads
local damageStringsDB 	= {}	
local healStringsDB 	= {}
local auraStringsDB		= {}
local missStringsDB		= {}

-- these are Subevents according to type
local dmgSubEventsDB	= {}
local healSubEventsDB	= {}
local auraSubEventsDB	= {}
local missSubEventsDB	= {}

local cleuElapsedTime = 0

-- RECORD LAYOUT IN THE dmgRecordTable
--  	{sourceName, targetGUID, spellName, spellSchool, 
--	  		normalDmg, critDmg, overkill, resisted, 
--				blocked, absorbed, numCalls }
--
-- EXAMPLE:
-- 		dmgRecordsDB = {
-- 			Frostbolt, ,,, 5
-- 			ice lance, ,,, 11
-- 			blizzard, ,,, 56
-- 		}	
-- 
local dmgRecordsDB		= {}
local healRecordsDB		= {}
local missRecordsDB		= {}
local auraRecordsDB		= {}

local encounterDB		= {}

local spellSchoolNames = {
	{1,  "Physical"},
	{2,  "Holy"},
	{3,  "Holystrike"},
	{4,  "Fire"},
	{5,  "Flamestrike"},
	{6,  "Holyfire (Radiant"},
	{8,  "Nature"},
	{9,  "Stormstrike"},
	{10, "Holystorm"},
	{12, "Firestorm"},
	{16, "Frost"},
	{17, "Froststrike"},
	{18, "Holyfrost"},
	{20, "Frostfire"},
	{24, "Froststorm"},
	{28, "Elemental"},
	{32, "Shadow"},
	{33, "Shadowstrike"},
	{34, "Shadowlight"},
	{36, "Shadowflame"},
	{40, "Shadowstorm(Plague)"},
	{48, "Shadowfrost"},
	{64, "Arcane"},
	{65, "Spellstrike"},
	{66, "Divine"},
	{68, "Spellfire"},
	{72, "Spellstorm"},
	{80, "Spellfrost"},
	{96, "Spellshadow"},
	{124, "Chromatic(Chaos)"},
	{126, "Magic"},
	{127, "Chaos"}
}

local targetHealthBar		= nil
local startOfCombat			= 0
local totalEncounterDmg		= 0
local totalEncounterHealing	= 0
local guardianIsActive = false

local DISPLAY_DMG_ENABLED 		= false
local DISPLAY_HEALS_ENABLED 	= false
local DISPLAY_AURAS_ENABLED 	= false
local DISPLAY_MISSES_ENABLED	= false

local PLAYER_NAME 	= nil
local PLAYER_PET	= nil

local SUCCESS	= base.SUCCESS
local FAILURE	= base.FAILURE

local SIG_ALERT             = thread.SIG_ALERT
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_STOP              = thread.SIG_STOP
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING

------ INDICES FOR THE CLEU SUBEVENT TABLE----
local CLEU_TIMESTAMP			= 1		
local CLEU_SUBEVENT			= 2
local CLEU_HIDECASTER		= 3
local CLEU_SOURCEGUID 		= 4	
local CLEU_SOURCENAME		= 5 	
local CLEU_SOURCEFLAGS		= 6 	
local CLEU_SOURCERAIDFLAGS	= 7	
local CLEU_TARGETGUID		= 8 	
local CLEU_TARGETNAME		= 9 	
local CLEU_TARGETFLAGS		= 10 	
local CLEU_TARGETRAIDFLAGS	= 11
local CLEU_SPELLID			= 12
local CLEU_SWING_DMG		= 12
local CLEU_SPELLNAME		= 13
local CLEU_AURA_NAME		= 13
local CLEU_SPELLSCHOOL		= 14
local CLEU_DMG_AMOUNT		= 15
local CLEU_HEAL_AMOUNT		= 15
local CLEU_MISS_TYPE		= 15
local CLEU_AURA_TYPE		= 15
local CLEU_OVERKILL			= 16
local CLEU_OVERHEAL			= 16
local CLEU_MISS_OFFHAND		= 16	
local CLEU_AURA_AMOUNT		= 16
local CLEU_DMG_SCHOOL		= 17
local CLEU_MISS_AMOUNT		= 17
local CLEU_HEAL_ABSORBED	= 17
local CLEU_DMG_RESISTED		= 18
local CLEU_MISS_CRITICAL	= 18
local CLEU_HEAL_IS_CRITICAL	= 18
local CLEU_DMG_BLOCKED		= 19
local CLEU_DMG_ABSORBED		= 20
local CLEU_DMG_IS_CRIT		= 21 -- boolean
local CLEU_DMG_GLANCING		= 22 -- boolean
local CLEU_DMG_CRUSHING		= 23 -- boolean
local CLEU_DMG_IS_OFFHAND 	= 24 -- boolean

-- ********************************************************************************
--							DAMAGE RECORD INDICES
-- ********************************************************************************
local REC_SPELLNAME		= 1
local REC_SPELLSCHOOL	= 2
local REC_DMG			= 3
local REC_HEALS			= 3
local REC_CRIT_DMG		= 4
local REC_CRIT_HEALS	= 4
local REC_OVERKILL  	= 5
local REC_OVERHEALING	= 5
local REC_RESISTED  	= 6
local REC_BLOCKED   	= 7
local REC_ABSORBED  	= 8
local REC_NUM_CASTS     	= 9 
local NUM_RECORD_ELEMENTS = REC_NUM_CASTS

local missVerbs = {
	{"BLOCK", 	"blocked"},
	{"ABSORB", 	"absorbed"},
	{"DEFLECT", "deflected"},
	{"MISS", 	"missed"},
	{"PARRY", 	"parried"},
	{"DODGE", 	"dodged"},
	{"RESIST", 	"resisted"}
}

local function getSpellSchool( index )
	for i, v in ipairs(spellSchoolNames) do
		if v[1] == index then return v[2] end
	end
	return nil
end
local function getMeanAndStdDev( dataSet )
	assert( dataSet ~= nil, "ASSERT FAILED: Dataset was nil.")
	assert( type( dataSet ) == "table", "ASSERT FAILED: Dataset not a table")

	local damage = 0
	local critDamage = 0
	local critCount = 0
	local sampleSize = 0

	for i, entry in ipairs( dataSet) do
		damage = damage + entry[2]
		if entry[3] == true then
			critCount = critCount + 1
			critDamage = critDamage + damage
		end
		sampleSize = sampleSize + 1
	end

	local mean = damage/sampleSize
	local critMean = critDamage/critCount
	
	-- calculate the variance
	local diffSquared = 0
	local damage = 0
	local sum = 0
	local n = 0
	for i, entry in ipairs( dataSet) do
		local damage = damage + entry[2]
		diffSquared = (damage - mean)^2
		sum = sum + diffSquared
	end

	-- local n = #dataSet
	local variance = sum/(sampleSize - 1)
	local stdDev = math.sqrt( variance )

	return mean, stdDev, variance
end
local function dbgDumpDmgRecord( dmgRecord )
	local s = nil
	if dmgRecord[REC_OVERKILL] ~= -1 then	-- indicates a guardian damage record
		s = sprintf("Spell: %s, School: %s, Dmg: %d, Crit: %d, %d, %d, %d, %d, Calls: %d\n",	
			dmgRecord[REC_SPELLNAME],
			dmgRecord[REC_SPELLSCHOOL],
			dmgRecord[REC_DMG],
			dmgRecord[REC_CRIT_DMG],
			dmgRecord[REC_OVERKILL],
			dmgRecord[REC_RESISTED],
			dmgRecord[REC_BLOCKED],
			dmgRecord[REC_ABSORBED],
			dmgRecord[REC_NUM_CASTS] )
	else
		s = sprintf("\n Spell: %s, School: %s, Dmg: %d, Crit: %d, Calls: %d\n",	
			dmgRecord[REC_SPELLNAME],
			dmgRecord[REC_SPELLSCHOOL],
			dmgRecord[REC_DMG],
			dmgRecord[REC_CRIT_DMG],
			dmgRecord[REC_NUM_CASTS] )
	end
	return s			
end
local function dbgDumpHealRecord( R  )
	local str = nil

	if R[REC_CRIT_DMG] > 0 then
		str = sprintf("[%s] School: %s, Amount Healed: %d (Crit), Over healed %d\n",	
			R[REC_SPELLNAME],
			R[REC_SPELLSCHOOL],
			R[REC_CRIT_HEALS],
			R[REC_OVERHEALING] )
	else
		str = sprintf("[%s] School: %s, Amount Healed: %d, Over healed %d\n",	
		R[REC_SPELLNAME],
		R[REC_SPELLSCHOOL],
		R[REC_HEALS],
		R[REC_OVERHEALING] )
	end

	return str			
end
local function dbgDumpSavedVars()
	mf:postMsg( "Dump of SAVED_HEALTHBAR_FRAME\n")
	mf:postMsg(sprintf("%s, ", SAVED_HEALTHBAR_FRAME[1]))
	mf:postMsg(sprintf("nil, "))
	mf:postMsg(sprintf("%s, ", SAVED_HEALTHBAR_FRAME[3]))
	mf:postMsg(sprintf("%s, ", SAVED_HEALTHBAR_FRAME[4]))
	mf:postMsg(sprintf("%s\n\n", SAVED_HEALTHBAR_FRAME[5]))
end
local function dbgDumpSubEvent( stats ) -- DUMPS A SUB EVENT IN A COMMA DELIMITED FORMAT.
	local dataType = nil
	
	for i = 1, 24 do
		if stats[i] ~= nil then
			local value = nil
			dataType = type(stats[i])

			if type(stats[i]) == "number" or type(stats[i] == "boolean") then
				value = tostring( stats[i] )
			end
			if i == 1 then
				mf:postMsg( sprintf("arg[%d] %s, ", i, value ))
			else
				mf:postMsg( sprintf(" arg[%d] %s, ", i, value ))
			end
		elseif stats[i] == EMPTY_STR then
			mf:postMsg( sprintf(" arg[%d] EMPTY, ", i))
		else
			mf:postMsg( sprintf(" arg[%d] NIL, ", i))
		end
	end
	mf:postMsg( sprintf("\n\n"))
end	
local function dbgDumpCLEU() -- dumps the entire CLEU database
	local num = #cleuStatsDB
	for i = 1, num do
		local stats = cleuStatsDB[i]
		-- dbgDumpSubEvent( stats )
	end
end
-- thread handles and their cleu tables
local damage_h	= nil
local heal_h 	= nil
local aura_h 	= nil
local miss_h 	= nil

local function missType2missName( missType )
	for i, miss in ipairs( missVerbs ) do
		if miss[1] == missType then
			missName = miss[2]
		end
	end
	return string.upper( missName )
end
local function isDamageSubEvent( stats )
	local isValid = false
	local str = string.sub( stats[CLEU_SUBEVENT], -7 )
	if str == "_DAMAGE" then 
		isValid = true
	end	
	return isValid
end
local function isHealSubEvent( stats )
	local isValid = false
	local str = string.sub( stats[CLEU_SUBEVENT], -5 )
	if str == "_HEAL" then 
		isValid = true
	end

	return isValid
end
local function isAuraSubEvent( stats )
	local isValid = false	
	local str = string.sub( stats[CLEU_SUBEVENT], 1,11 )
	if str == "SPELL_AURA_" then 
		isValid = true
	end
	return isValid
end
local function isMissSubEvent( stats )
	local isValid = false
	local str = string.sub( stats[CLEU_SUBEVENT], -5 )
	if str == "_MISSED" then 
		isValid = true 
	end
	return isValid
end
local function scrollDmgIsEnabled()
	return DISPLAY_DMG_ENABLED
end
local function sortByTimestamp( stats1, stats2 )
	return stats1[CLEU_TIMESTAMP] < stats2[CLEU_TIMESTAMP]
end
local function healTextIsEnabled()
	return DISPLAY_HEALS_ENABLED
end
local function auraTextIsEnabled()
	return DISPLAY_AURAS_ENABLED
end
local function missTextIsEnabled()
	return DISPLAY_MISSES_ENABLED
end
local function getDmgOffset( stats )
	local offset = 0
	local s = string.sub( stats[CLEU_SUBEVENT], 1, 6)
	if s == "SWING_" then 
		offset = 3
	end
	return offset
end
--============================ BEGIN SIGNAL SERVICES =====================
local function signalDamageThread( stats ) -- sends thread:sentSignal( damage_h, SIG_ALERT)
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
	table.insert( dmgSubEventsDB, stats )

	-- now prepare the string to be displayed
	local offset = getDmgOffset( stats )
	
	local isCrit	= CLEU_DMG_IS_CRIT	- offset
	local dmgAmount	= CLEU_DMG_AMOUNT	- offset

	local dmgString = tostring( stats[dmgAmount])
	local entry = {stats[isCrit], dmgString }

	table.insert( damageStringsDB, entry )
	result = thread:sendSignal( damage_h, SIG_ALERT )
	return result
end
local function signalHealThread( stats ) -- sends thread:sentSignal( heal_h, SIG_ALERT)
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
	table.insert( healSubEventsDB, stats )
	if not cleu:isScrollingHealsEnabled() then
		return result
	end
	-- now prepare the string to be displayed
	local healingString = tostring( stats[CLEU_HEAL_AMOUNT] )

	local entry = {stats[CLEU_HEAL_IS_CRITICAL], healingString }
	table.insert( healStringsDB, entry )
	result = thread:sendSignal( heal_h, SIG_ALERT )
	return result
end
local function signalAuraThread( stats ) -- sends thread:sentSignal( aura_h, SIG_ALERT)
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
	table.insert( auraSubEventsDB, stats )
	if not cleu:isScrollingAurasEnabled() then
		return result
	end

	local auraAmount = 0
	local auraString = nil

	
	-- now prepare the string to be displayed
	local subEvent = stats[CLEU_SUBEVENT]

	if stats[CLEU_OVERKILL] ~= nil then auraAmount = stats[CLEU_OVERKILL] end
	local auraName 	 = stats[CLEU_AURA_NAME]
	local targetName = stats[CLEU_TARGETNAME]

	if  subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_APPLIED_DOSE" then
        if auraAmount > 0 then
            auraString = sprintf("%s (%d)", auraName, auraAmount )
        else
            auraString = sprintf("%s", auraName )
        end
    end
    if subEvent == "SPELL_AURA_REMOVED" or subEvent == "SPELL_AURA_REMOVED_DOSE" then
        if auraAmount > 0 then
            auraString = sprintf("%s Removed (%d)", auraName, auraAmount)
        else
            auraString = sprintf("%s Removed ", auraName )
        end
    end



	table.insert( auraStringsDB, auraString )
	result = thread:sendSignal( aura_h, SIG_ALERT )
	return result
end
local function signalMissThread( stats ) -- sends thread:sentSignal( miss_h, SIG_ALERT)
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
	table.insert( missSubEventsDB, stats )
	if not cleu:isScrollingMissesEnabled() then
		return result
	end
		--[[ 
		arg[2] SWING_MISSED,  
		arg[12] DODGE,  
		arg[13] false,  isOffhand
		arg[14] NIL,    amountMissed
		arg[15] NIL, 	isCritical 
		]]
	local subEvent = stats[CLEU_SUBEVENT]
	if subEvent ~= "SWING_MISSED" and
		subEvent ~= "SPELL_MISSED" and
		subEvent ~= "SPELL_PERIODIC_MISS" and
		subEvent ~= "RANGE_MISS" then
			return result
	end

	local offset = getDmgOffset( stats )

	local missAmount = stats[CLEU_MISS_AMOUNT - offset]
	local sourceName = stats[CLEU_SOURCENAME]
	local targetName = stats[CLEU_TARGETNAME]
	local missName = missType2missName( stats[CLEU_MISS_TYPE - offset] )
	local missString = nil

	if missAmount ~= nil then
		missString = sprintf("%s (%d)", missName, missAmount )
	else
		missString = sprintf("%s", missName )
	end

	table.insert( missStringsDB, missString  )
	result = thread:sendSignal( miss_h, SIG_ALERT )
	return result
end
--============================ END SIGNAL SERVICES =====================

--[[
Each entry in the DB records the number of times each
spell was cast by the player. In the example below,
5 frostbolts, 11 ice lances, and 56
blizzard spells were cast by the player

	dmgRecordsDB = {
		Frostbolt, ,,, 5
		ice lance, ,,, 11
		blizzard, ,,, 56
	}	

The following two functions creates a dmgRecord and then
inserts it into the dmgRecordsDB.

local sum = createDmgRecord( stats )
insertDmgRecord( sum) 
 ]]
 ---------------- DAMAGE RECORD ----------------------
local function dmgRecordIsValid( dmgRecord )

	assert( dmgRecord  ~= nil, "ASSERT FAILURE: Input param sum = nil" )
	assert( #dmgRecord == NUM_RECORD_ELEMENTS, sprintf("ASSERT FAILURE: Input param Ill-Formed - %d elements.", #dmgRecord ))
	for i = 1, NUM_RECORD_ELEMENTS do
		assert( dmgRecord[i] ~= nil, sprintf("ASSERT FAILURE: Record[%d] was nil", i ))
	end
	assert( type(dmgRecord[1]) == "string", sprintf("ASSERT FAILURE: expected 'string', got '%s'.", type(dmgRecord[1])))
	assert( type(dmgRecord[2]) == "string", sprintf("ASSERT FAILURE: expected 'string', got '%s'.", type(dmgRecord[2])))

	for i = 3, NUM_RECORD_ELEMENTS do
		assert( type(dmgRecord[i]) == "number", sprintf("ASSERT FAILURE: Record[%d] - Expected 'number' got '%s'.", i, tostring( type(dmgRecord[i]))))
	end
	return true
end
local function combineDmgRecords( existingRec, newRec ) -- combines two damage records of the same spellname into one record
	existingRec[REC_DMG]		= existingRec[REC_DMG]		 + newRec[REC_DMG]
    existingRec[REC_CRIT_DMG]	= existingRec[REC_CRIT_DMG]  + newRec[REC_CRIT_DMG]
    existingRec[REC_OVERKILL]	= existingRec[REC_OVERKILL]  + newRec[REC_OVERKILL]
    existingRec[REC_RESISTED]	= existingRec[REC_RESISTED]  + newRec[REC_RESISTED]
    existingRec[REC_BLOCKED]	= existingRec[REC_BLOCKED]   + newRec[REC_BLOCKED]
    existingRec[REC_ABSORBED]	= existingRec[REC_ABSORBED]  + newRec[REC_ABSORBED]
    existingRec[REC_NUM_CASTS]	= existingRec[REC_NUM_CASTS] + newRec[REC_NUM_CASTS]
end
local function insertDmgRecord( dmgRecord ) -- adds a damage record to dmgRecordsDB
	local recordUpdated = false
	local numRecords = #dmgRecordsDB
	if numRecords == 0 then table.insert( dmgRecordsDB, dmgRecord ) return end

	local record = nil
	for i = 1, numRecords do
		local existingRecord = dmgRecordsDB[i]
		if dmgRecord[REC_SPELLNAME] == existingRecord[REC_SPELLNAME] then
			combineDmgRecords( existingRecord, dmgRecord )
			recordUpdated = true
		end
	end

	if not recordUpdated then -- this record is appearing for the first time.
		table.insert( dmgRecordsDB, dmgRecord )
	end
end
local function createDmgRecord( stats ) -- create a single damage record from a stats block
	local dmgRecord	= {EMPTY_STR, EMPTY_STR, 0, 0, 0, 0, 0, 0, 0}

	local offset	= getDmgOffset( stats )
	
	local isCritical	= CLEU_DMG_IS_CRIT 	- offset
	local overkill 		= CLEU_OVERKILL 	- offset
	local resisted 		= CLEU_DMG_RESISTED - offset
	local blocked 		= CLEU_DMG_BLOCKED 	- offset
	local absorbed 		= CLEU_DMG_ABSORBED	- offset
	local dmgDone		= CLEU_DMG_AMOUNT 	- offset
	local spellSchool	= CLEU_SPELLSCHOOL	- offset

	if stats[CLEU_SUBEVENT] == "SWING_DAMAGE" then
		spellName = "Swing Damage"
	end
	if stats[overkill] == nil then
		stats[overkill] = 0
	end
	if stats[resisted] == nil then
		stats[resisted] = 0
	end
	if stats[blocked] == nil then
		stats[blocked]	= 0
	end
	if stats[absorbed] == nil then
		stats[absorbed]	= 0
	end

	dmgRecord[REC_OVERKILL] 	= overkill
	dmgRecord[REC_RESISTED] 	= resisted
	dmgRecord[REC_BLOCKED]  	= blocked
	dmgRecord[REC_ABSORBED] 	= absorbed 

	if stats[isCritical] then
		dmgRecord[REC_CRIT_DMG]	= stats[dmgDone] -- accum only crit damage
	else
		dmgRecord[REC_DMG]		= stats[dmgDone] -- accum only normal, non-crit damage
	end

	dmgRecord[REC_SPELLNAME] 	= stats[CLEU_SPELLNAME]

	if offset == 3 then 
		dmgRecord[REC_SPELLNAME] 	= "Melee"
		dmgRecord[REC_SPELLSCHOOL] = "Physical"
	else
		dmgRecord[REC_SPELLNAME] 	= stats[CLEU_SPELLNAME]
		dmgRecord[REC_SPELLSCHOOL]	= getSpellSchool( stats[CLEU_SPELLSCHOOL] ) 
	end

	dmgRecord[REC_NUM_CASTS] = 1
	if base:debuggingIsEnabled() then
		dmgRecordIsValid( dmgRecord )
	end
    return dmgRecord 
end
----------------- HEAL RECORD -------------------------
local function healRecordIsValid( healRecord )

	assert( healRecord  ~= nil, "ASSERT FAILURE: Input param sum = nil" )
	assert( #healRecord == NUM_RECORD_ELEMENTS, sprintf("ASSERT FAILURE: Input param Ill-Formed - %d elements.", #healRecord ))
	for i = 1, NUM_RECORD_ELEMENTS do
		assert( healRecord[i] ~= nil, sprintf("ASSERT FAILURE: Record[%d] was nil", i ))
	end
	assert( type(healRecord[1]) == "string", sprintf("ASSERT FAILURE: expected 'string', got '%s'.", type(healRecord[1])))
	assert( type(healRecord[2]) == "string", sprintf("ASSERT FAILURE: expected 'string', got '%s'.", type(healRecord[2])))

	for i = 3, NUM_RECORD_ELEMENTS do
		assert( type(healRecord[i]) == "number", sprintf("ASSERT FAILURE: Record[%d] - Expected 'number' got '%s'.", i, tostring( type(healRecord[i]))))
	end
	return true
end
local function combineHealRecords( existingRec, newRec ) -- combines two damage records of the same spellname into one record
	existingRec[REC_HEALS]		= existingRec[REC_HEALS]		 + newRec[REC_HEALS]
    existingRec[REC_CRIT_HEALS]	= existingRec[REC_CRIT_HEALS]  + newRec[REC_CRIT_HEALS]
    existingRec[REC_OVERHEALING]	= existingRec[REC_OVERHEALING]  + newRec[REC_OVERHEALING]
    existingRec[REC_NUM_CASTS]	= existingRec[REC_NUM_CASTS] + newRec[REC_NUM_CASTS]
end
local function insertHealRecord( healRecord ) -- adds a damage record to healRecordsDB
	local isInDB = false
	local numRecords = #healRecordsDB
		
	if numRecords == 0 then table.insert( healRecordsDB, healRecord ) return end

	for i, rec in ipairs( healRecordsDB ) do
		local rec = healRecordsDB[i]
		if healRecord[REC_SPELLNAME] == rec[REC_SPELLNAME] then
			combineHealRecords( rec, healRecord )
			isInDB = true
		end
	end

	if not isInDB then
		table.insert( healRecordsDB, healRecord )
	end
end
local function createHealRecord( stats ) -- create a single damage record from a stats block
	local healRecord	= {EMPTY_STR, EMPTY_STR, 0, 0, 0, 0, 0, 0, 0}

	if stats[CLEU_OVERHEAL] == nil then
		stats[CLEU_OVERHEAL] = 0
	end
	if stats[CLEU_HEAL_ABSORBED] == nil then
		stats[CLEU_HEAL_ABSORBED]	= 0
	end

	healRecord[REC_OVERHEALING] = stats[CLEU_OVERHEAL]
	healRecord[REC_RESISTED] 	= 0
	healRecord[REC_BLOCKED]  	= 0
	healRecord[REC_ABSORBED] 	= stats[CLEU_HEAL_ABSORBED] 

	if stats[CLEU_HEAL_IS_CRITICAL] then
		healRecord[REC_CRIT_HEALS]	= stats[CLEU_HEAL_AMOUNT] -- accum only crit damage
	else
		healRecord[REC_HEALS]		= stats[CLEU_HEAL_AMOUNT] -- accum only normal, non-crit damage
	end

	healRecord[REC_SPELLNAME] 	= stats[CLEU_SPELLNAME]
	healRecord[REC_SPELLSCHOOL]	= getSpellSchool( stats[CLEU_SPELLSCHOOL] ) 

	healRecord[REC_NUM_CASTS] = 1
	if base:debuggingIsEnabled() then
		healRecordIsValid( healRecord )
	end
	return healRecord 
end
-------------------------------------------------------

local function targetIsDummy( targetName )
	local isDummy = false

	if targetName == nil then return isDummy end
	targetName = string.upper( targetName )
	if strlen(targetName) < 14 then return isDummy end
	
	local targetName = string.sub( targetName, -14)
	if targetName == "TRAINING DUMMY" then
		isDummy = true
	end
	return isDummy
end
function cleu:resetTargetHealthBar()
	local f = targetHealthBar
	f.TargetMaxHealth	= 0
	f.TargetHealth		= UnitHealthMax( "Player ")
	f.TargetName 		= nil
	f.TargetGUID		= nil
	f.ElapsedTime		= 0

	f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f.bar:SetStatusBarColor( 0.0, 1.0, 0.0 )
	f.bar:SetMinMaxSmoothedValue( f.TargetHealth, f.TargetMaxHealth)
	f.bar:SetSmoothedValue(f.TargetHealth)
	f.bar.text:SetText( "" )
	f:Hide()
end
function cleu:resetCombatState()
	cleu:resetTargetHealthBar()
	wipe( encounterDB )
	encounterDB = {}
	totalEncounterDmg = 0
	totalEncounterHealing = 0
	startOfCombat = 0
	guardianIsActive = false
	cleuElapsedTime	= 0

	wipe( cleuStatsDB )
	wipe( dmgSubEventsDB )
	wipe( healSubEventsDB )
	wipe( auraSubEventsDB )
	wipe( missSubEventsDB )

	wipe( damageStringsDB )
	wipe( healStringsDB )
	wipe( auraStringsDB )
	wipe( missStringsDB )

	wipe( dmgRecordsDB )
	wipe( healRecordsDB )
	-- wipe( missRecordsDBsDB )
	-- wipe( auraRecordsDB )

	DEFAULT_CHAT_FRAME:AddMessage("State reset.")
end
local function getElapsedTime()
	local elapsedTime = 0 
	if targetHealthBar.ElapsedTime == 0 then
		elapsedTime = cleuElapsedTime
	else
		elapsedTime = targetHealthBar.ElapsedTime
	end
	return elapsedTime
end
-- called from insertCleuStats when the encounter ends
local function createDmgEncounter() -- converts dmgRecordTable to an encounter, clears all settings

	local recordTable = {}

	local totalNormalDmg 	= 0
	local totalCritDmg		= 0

	for i = 1, #dmgRecordsDB do
		local combatRec = dmgRecordsDB[i]
		totalCritDmg	= totalCritDmg + combatRec[REC_CRIT_DMG]
		totalNormalDmg	= totalNormalDmg + combatRec[REC_DMG]
	end

	for i = 1, #dmgRecordsDB do
		local combatRec = dmgRecordsDB[i]
		local dmgRecord = nil

		local spellName 	= combatRec[REC_SPELLNAME]
		local critDmg 		= combatRec[REC_CRIT_DMG]
		local normalDmg 	= combatRec[REC_DMG]
		local numCasts		= combatRec[REC_NUM_CASTS]

		local totalDmg		= normalDmg + critDmg
		local percentCrit 	= critDmg/totalDmg * 100
		local DPC			= totalDmg/numCasts

		if critDmg > 0 then
			dmgRecord = sprintf("[%s] Damage: %d, Crit %0.1f%%, Damage/Cast %0.1f\n", spellName, totalDmg, percentCrit, DPC  )
		else
			dmgRecord = sprintf("[%s] Damage: %d, Damage/Cast %0.1f\n", spellName, totalDmg, DPC  )
		end

		recordTable[i] = dmgRecord
	end

	local elapsedTime = getElapsedTime()

	local totalDamage = totalNormalDmg + totalCritDmg
	local totalDPS = totalDamage/elapsedTime
	local percentCrit = (totalCritDmg/totalDamage) * 100
	local player = UnitName( "Player")

	local title = sprintf("\n\nDAMAGE: combat completed after %d seconds.\n", elapsedTime)
	local subHeader1 = sprintf("Total Damage %d (%0.1f%% Crit), DPS %0.1f\n", totalDamage, percentCrit, totalDPS )
	header = sprintf("%s%s\n", title, subHeader1 )
	
	local encounter = {header, recordTable }	
	-- table.insert( encounterDB, encounter )	
	return encounter
end
local function createHealingEncounter() -- converts dmgRecordTable to an encounter, clears all settings
	local recordTable = {}
	local totalNormalHeals 	= 0
	local totalCritHeals	= 0
	local totalOverHeal		= 0

	for i = 1, #healRecordsDB do
		local combatRec 	= healRecordsDB[i]
		totalCritHeals		= totalCritHeals + combatRec[REC_CRIT_HEALS]
		totalNormalHeals	= totalNormalHeals + combatRec[REC_HEALS]
		totalOverHeal		= totalOverHeal + combatRec[REC_OVERHEALING]
	end
	for i = 1, #healRecordsDB do
		local combatRec = healRecordsDB[i]
		local healRecord = nil

		local spellName 	= combatRec[REC_SPELLNAME]
		local critHeals 	= combatRec[REC_CRIT_HEALS]
		local normalHeals 	= combatRec[REC_HEALS]
		local numCasts		= combatRec[REC_NUM_CASTS]
		local overHeal		= combatRec[REC_OVERHEALING]

		local totalHeals	= normalHeals + critHeals
		local percentCrit 	= critHeals/totalHeals * 100
		local DPC			= totalHeals/numCasts

		if critHeals > 0 then
			healRecord = sprintf("[%s] Heals: %d (Over heal %d), Crit %0.1f%%, Heals/Cast %0.1f\n", spellName, totalHeals, overHeal, percentCrit, DPC  )
		else
			healRecord = sprintf("[%s] Heals: %d (Over heal %d), Heals/Cast %0.1f\n", spellName, totalHeals, overHeal, DPC  )
		end

		recordTable[i] = healRecord
	end
	local elapsedTime = getElapsedTime()

	local totalHealing = totalNormalHeals + totalCritHeals
	local totalHPS = totalHealing/elapsedTime
	local percentCrit = (totalCritHeals/totalHealing) * 100
	local player = UnitName( "Player")

	local title = sprintf("\n\nSELF-HEALING: combat completed after %d seconds.\n", elapsedTime)
	local subHeader1 = nil

	if totalCritHeals > 0 then
		subHeader1 = sprintf("Total Healing %d (%0.1f%% crit), HPS (Heals/Second) %0.1f\n", totalHealing, percentCrit, totalHPS )
	else
		subHeader1 = sprintf("Total Healing %d, Heals/Second %0.1f\n", totalHealing, totalHPS )
	end
	header = sprintf("%s%s\n", title, subHeader1 )
	
	local encounter = {header, recordTable }	
	-- table.insert( encounterDB, encounter )
	return encounter	
end
function cleu:summarizeEncounter() -- called from SLASH_COMMAND. See CommandLine.lua
	local dmgEncounter 	= createDmgEncounter()
	local healEncounter = createHealingEncounter()

	-- print the damage encounter
	local spellTable 	= dmgEncounter[2]
	mf:postMsg( dmgEncounter[1] )
	for j = 1, #spellTable do
		mf:postMsg( sprintf("     %s", spellTable[j] ))
	end

	-- print the heal encounter
	header 		= healEncounter[1]
	spellTable 	= healEncounter[2]
	mf:postMsg( healEncounter[1] )
	for j = 1, #spellTable do
		mf:postMsg( sprintf("     %s", spellTable[j] ))
	end
	
end
local function updateHealthBar( stats )
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
	local f = targetHealthBar
	if f.TargetGUID ~= stats[CLEU_TARGETGUID] then 
		return nil, result 
	end

	f.TargetHealth = f.TargetHealth - stats[CLEU_DMG_AMOUNT]
	if f.TargetHealth <= 0 then 
		f.bar:SetSmoothedValue( 0 )
		f:Hide()
		PlaySound(SOUNDKIT.READY_CHECK)

	else
		f.bar:SetSmoothedValue( f.TargetHealth  )
	end
	local percent = math.floor( f.TargetHealth/f.TargetMaxHealth * 100)	
	local s = sprintf("[%s HP %d] %0.1f%%", f.TargetName, f.TargetHealth, percent )
	f.bar.text:SetText( s )	

	return f.TargetHealth, result
end
local function insertCleuStats( stats ) -- signals damage, heal, aura, and miss threads
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
	table.insert( cleuStatsDB, stats ) 

	if isDamageSubEvent( stats ) then
		if startOfCombat == 0 then
			startOfCombat = stats[CLEU_TIMESTAMP]
		end

		local dmgRecord = createDmgRecord( stats ) 
		insertDmgRecord( dmgRecord )
		local logEntry = dbgDumpDmgRecord( dmgRecord )
		-- mf:postLogEntry( logEntry )

		result = signalDamageThread( stats )
		if result[2] == "completed" then
			local logMsg = sprintf("%s damage_h has completed.", thread:prefix())
			DEFAULT_CHAT_FRAME:AddMessage( logMsg, 1.0, 1.0, 0.0 )
		end
	end

	if isHealSubEvent( stats ) then
		if startOfCombat == 0 then
			startOfCombat = stats[CLEU_TIMESTAMP]
		end

		local healRecord = createHealRecord( stats ) 
		insertHealRecord( healRecord )
		local logEntry = dbgDumpHealRecord( healRecord )
		-- mf:postLogEntry( logEntry )

		result = signalHealThread(stats)
		if result[2] == "completed" then
			local logMsg = sprintf("%s heal_h has completed.", thread:prefix())
			DEFAULT_CHAT_FRAME:AddMessage( logMsg, 1.0, 1.0, 0.0 )
		end
	end
	if isAuraSubEvent(stats) then
		if startOfCombat == 0 then
			startOfCombat = stats[CLEU_TIMESTAMP]
		end

		result = signalAuraThread(stats)
		if result[2] == "completed" then
			local logMsg = sprintf("%s aura_h has completed.", thread:prefix())
			DEFAULT_CHAT_FRAME:AddMessage( logMsg, 1.0, 1.0, 0.0 )
		end
		return result
	end
	if isMissSubEvent( stats ) then
		if startOfCombat == 0 then
			startOfCombat = stats[CLEU_TIMESTAMP]
		end

		result = signalHealThread(stats)
		if result[2] == "completed" then
			local logMsg = sprintf("%s miss_h has completed.", thread:prefix())
			DEFAULT_CHAT_FRAME:AddMessage( logMsg, 1.0, 1.0, 0.0 )
		end
		return result
	end

	-- Only continue beyond this point if the target is
	-- a target dummy.
	-- if not targetIsDummy( stats[CLEU_TARGETNAME]) then
	-- 	return result
	-- end
	if not isDamageSubEvent( stats ) then
		if not isHealSubEvent( stats ) then
			return result
		end
	end

	if targetIsDummy( stats[CLEU_TARGETNAME] ) then
		local remainingDmg, result = updateHealthBar( stats )
		if remainingDmg == nil then return result end

		if remainingDmg <= 0 then
			local elapsedTime = stats[CLEU_TIMESTAMP] - startOfCombat
			targetHealthBar.ElapsedTime = elapsedTime	
		end
	end

	return result
end

-- **************************** THREAD FUNCTIONS *************************
function cleu:setDamageThread( H )
	damage_h = H
end
function cleu:setHealThread( H )
	heal_h = H
end
function cleu:setAuraThread( H )
	aura_h = H
end
function cleu:setMissThread( H )
	miss_h = H
end
-- called when ADDON_LOADED is fired
local function createHealthBarFrame()

	local f = CreateFrame("Frame", "StatusBarFrame", UIParent,"TooltipBackdropTemplate")
	f.TargetMaxHealth	= 0
	f.TargetHealth		= 0
	f.TargetName 		= nil
	f.TargetGUID		= nil
	f.ElapsedTime		= 0

	if f.TargetMaxHealth == 0 and
		f.TargetHealth 	== 0 and
		f.TargetName 	== nil then f.Status = CREATED
	end

	f:SetBackdropBorderColor(0.5,0.5,0.5)
	f:SetSize(300,30)

	local a = FRAME_POINT
	local b = REFERENCE_FRAME
	local c = RELATIVE_TO
	local d = OFFSET_X
	local e = OFFSET_Y

	-- f:SetPoint( a, b, c, d, e )
	f:SetPoint( "CENTER")

    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", 
		function(self)
			self:StopMovingOrSizing()
			local a, b, c, d, e = self:GetPoint()
			SAVED_HEALTHBAR_FRAME = {a, b, c, d, e}
		end)

	f.bar = CreateFrame("StatusBar",nil,f)
	f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f.bar:SetStatusBarColor( 0.0, 1.0, 0.0 )
	f.bar:SetPoint("TOPLEFT",5,-5)
	f.bar:SetPoint("BOTTOMRIGHT",-5,5)

	-- create a font string for the text
	f.bar.text = f.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.bar.text:SetTextColor( 1.0, 1.0, 0.0 )	-- yellow
	f.bar.text:SetPoint("LEFT")

	-- copying mixins to statusbar
	Mixin(f.bar,SmoothStatusBarMixin)
	f.bar:SetMinMaxSmoothedValue(0, f.TargetMaxHealth )
	f.bar:SetSmoothedValue( f.TargetMaxHealth )

	f.bar.text:SetText( "" )
    return f
end
local function setTargetHealth( targetName, targetGUID, targetMaxHealth )
	assert( targetName ~= nil, "ASSERT FAILURE: target name not specified")

	local f = targetHealthBar

	f.TargetMaxHealth	= targetMaxHealth
	f.TargetHealth		= f.TargetMaxHealth
	f.TargetName 		= targetName
	f.TargetGUID		= targetGUID

	f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f.bar:SetStatusBarColor( 0.0, 1.0, 0.0 )
	f.bar:SetMinMaxSmoothedValue(0, f.TargetMaxHealth)
	f.bar:SetSmoothedValue(f.TargetMaxHealth)
	local percent = math.floor( f.TargetHealth/f.TargetMaxHealth * 100)	
	local s = sprintf("[%s] %d HP ( %0.1f%%)", f.TargetName, f.TargetMaxHealth, percent )
	f.bar.text:SetText( s )
	f:Show()
end
-- Only called from the Options Menu Panel (OptionsMenu.lua)
function cleu:setTargetDummyHealth( targetDummyHealth )

	if UnitExists("Target") == false then
		UIErrorsFrame:SetTimeVisible(4)
		local msg = sprintf("[INFO] No Target Selected.")	
		UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0 )
		return
	end

	local targetName = UnitName("Target")
	local targetGUID = UnitGUID("Target")

	if not targetIsDummy( targetName ) then
		UIErrorsFrame:SetTimeVisible(5)
		local msg = sprintf("[INFO] %s Must Be A Target Dummy.", targetName )	
		UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0 )
		return
	end

	if targetDummyHealth == nil then
		UIErrorsFrame:SetTimeVisible(5)
		local msg = sprintf("[INFO] %s health not specified.", targetName )	
		UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0 )
		return
	end

	if targetDummyHealth == EMPTY_STR then
		UIErrorsFrame:SetTimeVisible(5)
		local msg = sprintf("[INFO] %s health not specified.", targetName )	
		UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0 )
		return
	end
	local targetHealth = tonumber( targetDummyHealth )

	if targetHealth < 1 then
		UIErrorsFrame:SetTimeVisible(5)
		local msg = sprintf("[INFO] %s's health (%d) invalid.", targetName, targetHealth )	
		UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0 )
		return
	end

	targetHealth = UnitHealthMax("Player")
	setTargetHealth( targetName, targetGUID, targetHealth)
	targetHealthBar:Show()
end
-- local function printHealMetrics()
-- end
-- local function printAuraMetrics()
-- end
-- local function printMissMetrics()
-- end
--------------- SCROLLING DAMAGE ---------------
function cleu:enableScrollingDmg()
	DISPLAY_DMG_ENABLED = true
	-- DEFAULT_CHAT_FRAME:AddMessage( "Scrolling Damage Now ENABLED.")
end
function cleu:disableScrollingDmg()
	DISPLAY_DMG_ENABLED = false
	-- DEFAULT_CHAT_FRAME:AddMessage( "Scrolling Damage now DISABLED.")
end
function cleu:isScrollingDmgEnabled()
	return DISPLAY_DMG_ENABLED
end
--------------- SCROLLING HEALS ---------------
function cleu:enableScrollingHeals()
	DISPLAY_HEALS_ENABLED = true
	-- DEFAULT_CHAT_FRAME:AddMessage( "Scrolling Heals Events Now ENABLED.")
end
function cleu:disableScrollingHeals()
	DISPLAY_HEALS_ENABLED = false
	-- DEFAULT_CHAT_FRAME:AddMessage( "Scrolling Heals now DISABLED.")
end
function cleu:isScrollingHealsEnabled()
	return DISPLAY_HEALS_ENABLED
end
--------------- SCROLLING AURAS ---------------
function cleu:enableScrollingAuras()
	DISPLAY_AURAS_ENABLED = true
	-- DEFAULT_CHAT_FRAME:AddMessage( "Scrolling Auras Events Now ENABLED.")
end
function cleu:disableScrollingAuras()
	DISPLAY_AURAS_ENABLED = false
	-- DEFAULT_CHAT_FRAME:AddMessage( "Scrolling Auras Now DISABLED.")
end
function cleu:isScrollingAurasEnabled()
	return DISPLAY_AURAS_ENABLED
end
--------------- SCROLLING MISSES ---------------
function cleu:enableScrollingMisses()
	DISPLAY_MISSES_ENABLED = true
	-- DEFAULT_CHAT_FRAME:AddMessage( "Scrolling Misses Events Now ENABLED.")
end
function cleu:disableScrollingMisses()
	DISPLAY_MISSES_ENABLED = false
	-- DEFAULT_CHAT_FRAME:AddMessage( "Scrolling Misses Now DISABLED.")
end
function cleu:isScrollingMissesEnabled()
	return DISPLAY_MISSES_ENABLED
end
--============================= BEGIN SIGNAL SERVICES
function cleu:getDmgString()
	local numEntries = #damageStringsDB
	if numEntries == 0 then return nil, nil, numEntries end
	local entry = table.remove( damageStringsDB, 1)
	local isCrit = entry[1]
	local damageStr = entry[2]
	return isCrit, damageStr, #damageStringsDB
end
function cleu:getHealString()
	numEntries = healStringsDB
	if numEntries == 0 then return nil, nil, 0 end
	local entry = table.remove( healStringsDB, 1 )
	if entry == nil then return nil, nil, 0 end

	-- assert( entry ~= nil, "ASSERT FAILED: entry was nil")
	-- assert( type( entry ) == "table", "ASSERT FAILED: entry not a table is a %s", type( entry[1]))
	-- assert( #entry == 2, "ASSERT FAILED: Expected 2, got %d", #entry )
	-- assert( type(entry[1] == "boolean", "ASSERT FAILED: expected boolen got %s", type(entry[1])))
	
	local isCrit = entry[1]
	local healString = entry[2]
	return isCrit, healString, #numEntries
end
function cleu:getAuraString()
	if #auraStringsDB == 0 then return nil, 0 end
	local auraString = table.remove( auraStringsDB, 1 )
	return auraString, #auraStringsDB
end
function cleu:getMissString()
	if #missStringsDB == 0 then return nil, nil, 0 end
	local missString= table.remove( missStringsDB, 1 )
	return missString, #missStringsDB
end
local function isPetType( flags )
	return bit.band( flags, COMBATLOG_OBJECT_TYPE_MASK ) == bit.band( flags, COMBATLOG_OBJECT_TYPE_PET )
end
local function isPlayerType( flags )
	return bit.band( flags, COMBATLOG_OBJECT_TYPE_MASK ) == bit.band( flags, COMBATLOG_OBJECT_TYPE_PLAYER )
end
local function isPlayersPet( flags )
	if isPetType( flags ) == false then
		return false
	end
	return bit.band( flags, COMBATLOG_OBJECT_AFFILIATION_MASK) == bit.band( flags, COMBATLOG_OBJECT_AFFILIATION_MINE)
end
-- CHECKS WHETHER THE UNIT IS THE PLAYER OR THE PLAYER'S
-- PET OR GUARDIAN. RETURNS FALSE IF NOT.
local function isUnitValid( stats )	-- checks that the unit is the player or the player's pet or guardien	
	local isValid = false

	--- is this unit the player?
	if PLAYER_NAME == stats[CLEU_SOURCENAME] then
		return true
	end

	-- Return true if this is the player's pet
	local n = bit.band(stats[CLEU_SOURCEFLAGS], COMBATLOG_OBJECT_TYPE_PET )
	local m = bit.band( stats[CLEU_SOURCEFLAGS], COMBATLOG_OBJECT_AFFILIATION_MINE)
	-- if n == 4096 and m == 1 then
	if n > 0 and m == 1 then
		return true
	end
	-- Return true if this is the player's guardian
	local n = bit.band(stats[CLEU_SOURCEFLAGS], COMBATLOG_OBJECT_TYPE_GUARDIAN )
	local m = bit.band( stats[CLEU_SOURCEFLAGS], COMBATLOG_OBJECT_AFFILIATION_MINE)
	-- if n == 8192 and m == 1 then
	if n > 0 and m == 1 then
		return true
	end
	return isValid
end

local function filterCLEU( stats )
	-- log each of the following subEvents
	if 	subEvent ~= "SWING_DAMAGE" and
		subEvent ~= "RANGE_DAMAGE" and
		subEvent ~= "SPELL_DAMAGE" and 
		subEvent ~= "SPELL_PERIODIC_DAMAGE" and
		subEvent ~= "SPELL_START" and

		subEvent ~= "SWING_MISSED" and
		subEvent ~= "RANGE_MISSED" and
		subEvent ~= "SPELL_MISSED" and 
		subEvent ~= "SPELL_PERIOD_MISSED" and

		subEvent ~= "SPELL_HEAL" and
		subEvent ~= "SPELL_PERIODIC_HEAL" and
		subEvent ~= "SPELL_LEECH" and

		subEvent ~= "SPELL_CAST_START" and
		subEvent ~= "SPELL_CAST_SUCCESS" and
		subEvent ~= "SPELL_CAST_FAILED" and
		subEvent ~= "SPELL_INTERRUPT" and

		subEvent ~= "SPELL_AURA_APPLIED" and	-- crowd control spell 
		subEvent ~= "SPELL_AURA_APPLIED_DOSE" and
		subEvent ~= "SPELL_AURA_REMOVED" and	-- crowd control spell expired
		subEvent ~= "SPELL_AURA_REMOVED_DOSE" and
		subEvent ~= "SPELL_AURA_REFRESH" and
		subEvent ~= "SPELL_AURA_BROKEN" and		-- broken because of melee action
		subEvent ~= "SPELL_AURA_BROKEN_SPELL" then	-- broken by spell
			-- do nothing. It's an event of no interest
		return true
	end
	return false
end

-- https://github.com/liquidbase/wowui-source/blob/master/SmoothStatusBar.lua


-- default health bar position
local FRAME_POINT 		= "BOTTOM"
local REFERENCE_FRAME 	= nil
local RELATIVE_TO 		= "BOTTOM"
local OFFSET_X 			= 39.398860931396
local OFFSET_Y			= 184.8804473877

local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent( "PLAYER_LOGIN")
eventFrame:RegisterEvent( "PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent( "PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent( "ADDON_LOADED")

eventFrame:SetScript("OnEvent",
function( self, event, ... )
	local arg1, arg2, arg3, arg4 = ...

	if event == "ADDON_LOADED" and arg1 == base.ADDON_NAME then
		DEFAULT_CHAT_FRAME:AddMessage( L["ADDON_LOADED_MSG"],  1.0, 1.0, 0.0 )
		eventFrame:UnregisterEvent("ADDON_LOADED") 
		
		targetHealthBar = createHealthBarFrame()
		targetHealthBar:Hide()

		PLAYER_NAME = UnitName("Player")
		PLAYER_PET = UnitName("Pet")
		return
	end
	if event == "PLAYER_LOGIN" then
		if DPS_TRACKER_HEALTHBAR_VARS  == nil then
			DPS_TRACKER_HEALTHBAR_VARS = { FRAME_POINT, REFERENCE_FRAME, RELATIVE_TO, OFFSET_X, OFFSET_Y }
		end
	end
	if event == "PLAYER_REGEN_ENABLED" then
		if targetHealthBar.TargetMaxHealth == 0 then
			local last = #cleuStatsDB
			local stats = cleuStatsDB[last]	
			cleuElapsedTime = stats[CLEU_TIMESTAMP] - startOfCombat
		end
	end
		
 	if event == "PLAYER_TARGET_CHANGED" then

		local f = targetHealthBar
		-- return if the player has deselected the target (or
		-- no target selected.)
		local targetName = UnitName("Target")
		local targetIsDummy = targetIsDummy( targetName )
		if not targetIsDummy then return end

		-- if the target is dead, there is nothing to record.
		-- if UnitIsDead("Target") then return end
		-- if not UnitExists("Target") then
		-- 	cleu:resetTargetHealthBar()
		-- 	if f:IsVisible() then
		-- 		f:Hide()
		-- 	end
		-- 	if panel:isVisible() then
		-- 		panel:hide()
		-- 	end
		-- 	return
		-- end

		local targetGUID = UnitGUID( "Target" )
		targetHealth = 2*UnitHealthMax("Player")
		setTargetHealth( targetName, targetGUID, targetHealth)
	end
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then

		local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

		local stats = {CombatLogGetCurrentEventInfo()}	
		if not filterCLEU( stats ) then return end

		-- return if this unit (pet, player, guardian) is not the source or target of the attack.
		if isUnitValid( stats ) == false then
			return
		end

		result = insertCleuStats( stats )
		if not result[1] and result[2] ~= "completed" then 
			mf:postResult( result ) 
		end
		return
	end
end)

local fileName = "CleuDB.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
