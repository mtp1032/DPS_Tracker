--------------------------------------------------------------------------------------
-- UnitTestEQS.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 November, 2018	(Formerly DbgInfo.lua prior to this date)
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.UnitTestEQS = {}	
ut = DPS_Tracker.UnitTestEQS	
local sprintf = _G.string.format

local L = DPS_Tracker.L
local E = printErrorResult

local STAMINA       = DPS_TRACKER_STAMINA
local INTELLECT     = DPS_TRACKER_INTELLECT
local HASTE         = DPS_TRACKER_HASTE
local CRIT          = DPS_TRACKER_CRITSTRIKE
local MASTERY       = DPS_TRACKER_MASTERY
local AGILITY       = DPS_TRACKER_AGILITY
local VERSATILITY   = DPS_TRACKER_VERSATILITY

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    local n = (math.floor(num * mult + 0.5) / mult)
    return n
 end
local function printCombatStats()
    combatStats = {eqs:getTotalStats()}
    local stat = nil
    mainStr = ""
    for i = STAMINA, VERSATILITY do
        if combatStats[i] ~= 0 then
            if combatStats[i] > 0 then
                str = nil
                if i == STAMINA then
                    str = sprintf("Stamina %d", combatStats[i])
                elseif i == INTELLECT then
                    str = sprintf("Intellect %d", combatStats[i])
                elseif i == HASTE then
                    str = sprintf("Haste %d", combatStats[i])
                elseif i == CRIT then
                    str = sprintf("Crit Strike %d", combatStats[i])
                elseif i == MASTERY then
                    str = sprintf("Mastery %d", combatStats[i])
                elseif i == AGILITY then
                    str = sprintf("Agility %d", combatStats[i])
                elseif i == VERSATILITY then
                    str = sprintf("Versatility %d", combatStats[i])
                end
            end
            if str ~= nil then
                if mainStr ~= nil then
                    mainStr = str
                else
                    mainStr = mainStr..str
                end
            end
        end
    end
    mf:postMsg( mainStr )
end

local helpFrame = nil
local function postHelpMsg( helpMsg )
	if helpFrame == nil then
		helpFrame = fm:createHelpFrame( L["UNIT_TESTS"] )
	end
	fm:showFrame( helpFrame )
	helpFrame.Text:Insert( helpMsg )
end
local function executeEquip()
    local combatStats = {}
    local stats = {eqs:getTotalStats( combatStats )}
    for i = STAMINA, VERSATILITY do
        if combatStats[i] ~= stats[i] then
            local result = {errors:setFailure(L["UNEXPECTED_RETURN_VALUE"])}
            emf:postResult( result )
        else
            E:where( sprintf("%d %d\n", i, stats[i]))
        end
    end
    printCombatStats()
end

SLASH_EQUIPTEST1 = "/eqp"
SlashCmdList["EQUIPTEST"] = function( msg )
	if msg == nil then
		msg = "help"
	end
	if msg == "" then
		msg = "help"
	end

    msg = string.upper( msg )
    
    if msg == "HELP" then
        postHelpMsg( "This is a help message.")
        return
    end
    mf:postMsg(sprintf("****************************\n"))
    mf:postMsg(sprintf("* EQUIPPED ITEMS UNIT TEST *\n"))
    mf:postMsg(sprintf("****************************\n"))    
    executeEquip()
end

-- mf:postMsg(sprintf("sta %s, int %s, haste %s, crit %s, mastery %s, agi %s, vers %s\n", a,b,c,d,e,f,g ))

-- local numItems = getNumEquippedItems()
-- if numItems > 0 then
--     local i = eqs:getPlayerItemLevel()
--     mf:postMsg( sprintf("\nPLAYER ITEM LEVEL: %.02f%%.\n", i ) )
-- else
--     mf:postMsg( sprintf("\nPLAYER HAS NO EQUIPPED ITEMS.\n") )
-- end


-- local itemsEquipped = 0
-- for slotNum = FIRST_SLOT, LAST_SLOT do
--     local itemLink = equipmentSlotTable[slotNum]

--     if itemLink ~= nil then
--         local itemLevel = eqs:getItemLevel( slotNum )
--         mf:postMsg( sprintf("[%d] %s, iLevel %f \n", slotNum, equipmentSlotTable[slotNum], itemLevel ))
--         itemsEquipped = itemsEquipped + 1
--     end
-- end
-- if itemsEquipped == 0 then
--     mf:postMsg( sprintf("No Items Equipped.\n"))
-- end

-- local i = eqs:getPlayerItemLevel()

-- table.wipe( equipmentSlotTable )
-- initEquipSlotTable()
-- itemsEquipped = 0

-- for slotNum = FIRST_SLOT, LAST_SLOT do
--     local itemStats = eqs:getItemCombatStats( slotNum )
--     if itemStats ~= nil then
--         local sta   = itemStats[STAMINA]
--         local int   = itemStats[INTELLECT]
--         local haste = itemStats[HASTE]
--         local cs    = itemStats[CRIT_STRIKE]
--         local ms    = itemStats[MASTERY]
--         local ag    = itemStats[AGILITY]
--         local v     = itemStats[VERSATILITY]
--         local s = sprintf("Item %s: Sta %s, Int %s, Haste %s, Crit %s, Mastery %s, Ag %s, V %s\n",
--                            itemLink, tostring(sta), tostring(int), tostring(haste), tostring(cs), tostring(ma), tostring(ag), tostring(v))
--         mf:postMsg( s )
--         itemsEquipped = itemsEquipped + 1
--     end
-- end
-- if itemsEquipped == 0 then
--     mf:postMsg( sprintf("No Items Equipped.\n"))
-- end



-- local result = {errors:setFailure(L["PARAM_OUTOFRANGE"])}
-- errors:printErrorResult( result )

-- errors:printMsg( "Test 2: printMsg")

-- errors:printErrorMsg("Test 3: printErrorMsg(msg)")

-- errors:printInfoMsg( "Test 4: printInfoMsg(msg)")

--*****************************************************************************
--						EMF UNIT TESTS
--*****************************************************************************
-- local msg = {"one", "two", "three", "four"}
-- for i =1,4 do
--     fm:printErrorMsg( "This is just wrong")
-- end
-- local emf = fm:createErrorMsgFrame( "DPS Tracker Error Message")
-- emf:Show()


-- mf:postMsg( "Unit Test 1 - passed")