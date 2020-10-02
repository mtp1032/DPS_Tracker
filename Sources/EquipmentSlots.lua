--------------------------------------------------------------------------------------
-- EquipmentSlots.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 23 September, 2020
local _, DPS_Tracker = ...
DPS_Tracker.EquipmentSlots = {}
eqs = DPS_Tracker.EquipmentSlots

local L = DPS_Tracker.L
local E = errors
local sprintf = _G.string.format

-- https://wow.gamepedia.com/API_GetInventoryItemLink
-- https://wow.gamepedia.com/API_GetInventorySlotInfo
-- https://wow.gamepedia.com/InventorySlotName
-- https://wow.gamepedia.com/API_GetAverageItemLevel
-- https://wow.gamepedia.com/API_GetItemStats
-- https://www.townlong-yak.com/framexml/8.3.0/Constants.lua#336
-- https://github.com/tekkub/wow-globalstrings/blob/master/GlobalStrings/enUS.lua
-- https://wow.gamepedia.com/Category:Mixins       << General URL with links to all mixin types
-- https://wow.gamepedia.com/SpellMixin
-- https://wow.gamepedia.com/ItemLocationMixin

-----------------------------------------------------------------------------------------------------------
--                      The Equipment Slot Table
-----------------------------------------------------------------------------------------------------------
local SLOT_HEAD             = INVSLOT_HEAD
local SLOT_NECK             = INVSLOT_NECK
local SLOT_SHOULDER         = INVSLOT_SHOULDER
local SLOT_SHIRT            = INVSLOT_BODY
local SLOT_CHEST            = INVSLOT_CHEST
local SLOT_BELT             = INVSLOT_WAIST
local SLOT_LEGS             = INVSLOT_LEGS
local SLOT_FEET             = INVSLOT_FEET
local SLOT_WRIST            = INVSLOT_WRIST
local SLOT_GLOVES           = INVSLOT_HAND
local SLOT_FINGER_TOP       = INVSLOT_FINGER1
local SLOT_FINGER_BOTTOM    = INVSLOT_FINGER2
local SLOT_TRINKET_TOP      = INVSLOT_TRINKET1
local SLOT_TRINKET_BOTTOM   = INVSLOT_TRINKET2
local SLOT_BACK             = INVSLOT_BACK
local SLOT_MAIN_HAND        = INVSLOT_MAINHAND
local SLOT_OFF_HAND         = INVSLOT_OFFHAND
local SLOT_RANGED           = INVSLOT_RANGED
local SLOT_TABARD           = INVSLOT_TABARD
local FIRST_SLOT            = INVSLOT_HEAD
local LAST_SLOT             = INVSLOT_TABARD

local STAT_STAMINA       = 1
local STAT_INTELLECT     = 2
local STAT_HASTE         = 3
local STAT_CRITSTRIKE    = 4
local STAT_MASTERY       = 5
local STAT_AGILITY       = 6
local STAT_VERSATILITY   = 7
local FIRST_STAT = STAT_STAMINA
local LAST_STAT = STAT_VERSATILITY

-- ONLY CHANGES WHEN AN ITEM IS REMOVED OR INSERTED INTO AN EQUIPMENT SLOT
local playerStatsTable = {
    {"Stamina", 0},
    {"Intellect",0},
    {"Haste",0},
    {"Crit Strike",0},
    {"Mastery",0},
    {"Agility",0},
    {"Versatility", 0}
}

local equipmentSlotTable = {}

--*****************************************************************************
--              LOCAL FUNCTIONS
--*****************************************************************************
local function addNvp( nvp1, nvp2)
    if nvp1[1] ~= nvp2[1] then
        return nil
    end
    return {nvp1[1], nvp1[2] + nvp2[2]}
end
local function initEquipSlotTable()
    for slotNum = FIRST_SLOT, LAST_SLOT do
        local itemLink = GetInventoryItemLink("Player", slotNum)
        equipmentSlotTable[slotNum] = itemLink
    end
end
local function getInvItemLink(slotNum)
    return equipmentSlotTable[slotNum]
end
local function initPlayerStatsTable()
    playerStatsTable = { 
        {"Stamina", 0},
        {"Intellect",0},
        {"Haste",0},
        {"Crit Strike",0},
        {"Mastery", 0},
        {"Agility",0},
        {"Versatility", 0}}
end
local function initTotalStats()
    local numSlot = 0
    initPlayerStatsTable()
    for numSlot = FIRST_SLOT, LAST_SLOT do
        local itemStats = eqs:getItemStats( numSlot )
        if itemStats ~= nil then
            for stat = FIRST_STAT, LAST_STAT do 
                local nvp = itemStats[stat]
                if nvp ~= nil then
                    playerStatsTable[stat] = addNvp( playerStatsTable[stat], nvp )
                end
            end
        end
    end
end

--*****************************************************************************
--              PUBLIC (EXPORTED) FUNCTIONS
--*****************************************************************************
function eqs:getItemILevel( slotNum )
    if slotNum == SLOT_SHIRT or slotNum == SLOT_TABARD then
        return nil
    end
    local itemLink = GetInventoryItemLink("Player", slotNum )
    if itemLink == nil then
        return nil
    end
    local location = ItemLocation:CreateFromEquipmentSlot( slotNum )
    return C_Item.GetCurrentItemLevel( location )
end
function eqs:getPlayerILevel()
    local sum = 0 -- sum of item levels
    local count = 0 -- item count
    local itemLevel = 0

    for slotNum = FIRST_SLOT, LAST_SLOT do
        itemLevel = eqs:getItemILevel( slotNum )
        if itemLevel ~= nil then
            sum = sum + itemLevel
            count = count + 1
        end
    end

    if count ~= 0 then
        itemLevel = sum/count
    end
    return itemLevel
end
function eqs:getItemStats( slotNum )
    local numStats = 0
    local itemStats = {}
    itemLink = getInvItemLink( slotNum )
    if itemLink == nil then
        return nil
    end
    if slotNum == SLOT_SHIRT or slotNum == SLOT_TABARD then
        return nil
    end
    local stats = {}
    GetItemStats( itemLink, stats )
    local value = stats["ITEM_MOD_STAMINA_SHORT"]
    if value ~= nil then 
        local nvp = {"Stamina", value}
        itemStats[STAT_STAMINA] = nvp
        numStats = numStats + 1
    end
    value = stats["ITEM_MOD_INTELLECT_SHORT"]
    if value ~= nil then 
        local nvp = {"Intellect", value}
        itemStats[STAT_INTELLECT] = nvp
        numStats = numStats + 1
    end
    value = stats["ITEM_MOD_HASTE_RATING_SHORT"]
    if value ~= nil then 
        local nvp = {"Haste", value}
        itemStats[STAT_HASTE] = nvp
        numStats = numStats + 1
    end
    value = stats["ITEM_MOD_CRIT_RATING_SHORT"]
    if value ~= nil then 
        local nvp = {"Crit Strike", value}
        itemStats[STAT_CRITSTRIKE] = nvp
        numStats = numStats + 1
    end
    value = stats["ITEM_MOD_MASTERY_SHORT"]
    if value ~= nil then 
        local nvp = {"Mastery", value}
        itemStats[STAT_MASTERY] = nvp
        numStats = numStats + 1
    end
    value = stats["ITEM_MOD_AGILITY_SHORT"]
    if value ~= nil then 
        local nvp = {"Agility", value}
        itemStats[STAT_AGILITY] = nvp
        numStats = numStats + 1
    end
    value = stats["ITEM_MOD_VERSATILITY_SHORT"]
    if value ~= nil then 
        local nvp = {"Versatility", value}
        itemStats[STAT_VERSATILITY] = nvp
        numStats = numStats + 1
    end
    if numStats == 0 then
        return nil
    end
    return itemStats
end
function eqs:getPlayerStats( totalStats )
    for i = FIRST_STAT, LAST_STAT do
        local nvp = playerStatsTable[i]
        totalStats[i] = nvp
    end
end
function eqs:getPlayerStamina()
    return playerStatsTable[STAT_STAMINA]
end
function eqs:getPlayerIntellect()
    return playerStatsTable[STAT_INTELLECT]
end
function eqs:getPlayerHaste()
    return playerStatsTable[STAT_HASTE]
end
function eqs:getPlayerCritStrike()
    return playerStatsTable[STAT_CRITSTRIKE]
end
function eqs:getPlayerAgility()
    return playerStatsTable[STAT_AGILITY]
end
function eqs:getPlayerMastery()
    return playerStatsTable[STAT_MASTERY]
end
function eqs:getPlayerVersatility()
    return playerStatsTable[STAT_VERSATILITY]
end

--*****************************************************************************
--              EVENT HANDLER
-- Fires when the player equips or unequips an item.
--*****************************************************************************
local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent( "PLAYER_EQUIPMENT_CHANGED") 
eventFrame:RegisterEvent( "PLAYER_ENTERING_WORLD") 
eventFrame:SetScript("OnEvent",
function( self, event, ... )
    local arg1, arg2, arg3, arg4 = ...
    
    initEquipSlotTable()
    initTotalStats()
end)

--*****************************************************************************
--              UNIT TESTS
--*****************************************************************************
local helpFrame = nil
local function postHelpMsg( helpMsg )
	if helpFrame == nil then
		helpFrame = fm:createHelpFrame( L["UNIT_TESTS"] )
	end
	fm:showFrame( helpFrame )
	helpFrame.Text:Insert( helpMsg )
end

local function tests_Execute()
    mf:postMsg(sprintf("********************\n"))
    mf:postMsg(sprintf("* COMBAT STATS TESTS *\n"))
    mf:postMsg(sprintf("********************\n\n"))    

    local totalStats = {}
    eqs:getPlayerStats( totalStats )
    for i = FIRST_STAT, LAST_STAT do
        local nvp = totalStats[i]
        mf:postMsg(sprintf("%s;%d\n", nvp[1], nvp[2]))
    end


    mf:postMsg(sprintf("\n********************\n"))
    mf:postMsg(sprintf("* ITEM LEVEL TESTS *\n"))
    mf:postMsg(sprintf("********************\n\n"))    

    local iLvl = eqs:getPlayerILevel()
    mf:postMsg( sprintf("%s's Average ItemLevel: %d\n\n", GetUnitName("Player"), iLvl ))

    for slotNum = FIRST_SLOT, LAST_SLOT do
        if slotNum ~= SLOT_SHIRT and slotNum ~= SLOT_TABARD then
            local itemLink = equipmentSlotTable[slotNum]
            local iLvl = eqs:getItemILevel( slotNum )
            mf:postMsg( sprintf("%s: %d\n", itemLink, iLvl ) )
        end
    end
    E:where()

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
        postHelpMsg( sprintf("This is a help message.\n"))
        return
    end
    tests_Execute()
end
