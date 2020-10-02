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
local SLOT_LEGS             = INVSLOT_LETS
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

DPS_TRACKER_STAMINA       = 1
DPS_TRACKER_INTELLECT     = 2
DPS_TRACKER_HASTE         = 3
DPS_TRACKER_CRITSTRIKE    = 4
DPS_TRACKER_MASTERY       = 5
DPS_TRACKER_AGILITY       = 6
DPS_TRACKER_VERSATILITY   = 7

local FIRST_STAT = DPS_TRACKER_STAMINA
local LAST_STAT = DPS_TRACKER_VERSATILITY

--*****************************************************************************
--              PRIVATE UTILITY FUNCTIONS
--*****************************************************************************
local equipmentSlotTable = {}

-- populate the equipmentSlotTable with the items in the Paper Doll
local function initEquipSlotTable()
    for slotNum = FIRST_SLOT, LAST_SLOT do
        local itemLink = GetInventoryItemLink("Player", slotNum)
        if itemLink ~= nil then
            equipmentSlotTable[slotNum] = itemLink
        end
    end
end
-- return the number of equipped items
local function getNumEquippedItems()

    local numEquippedItems = 0
    for slotNum = FIRST_SLOT, LAST_SLOT do
        local itemId = GetInventoryItemID("Player", slotNum )
        if itemId ~= nil then
            numEquippedItems = numEquippedItems + 1
        end
    end
    return numEquippedItems
end
--*****************************************************************************
--              PUBLIC (EXPORTED) FUNCTIONS
--*****************************************************************************

-------------------------------------------------------------------------------
-- Return the item level of the item in the specified slot. If slot is empty,
-- the return value is nil.
function eqs:getItemLevel( slotNum )
    local itemLink = GetInventoryItemLink("Player", slotNum )
    if itemLink == nil then
        return nil
    end
    local location = ItemLocation:CreateFromEquipmentSlot( slotNum )
    return C_Item.GetCurrentItemLevel( location )
end
-------------------------------------------------------------------------------
-- Return a table of combat stats corresponding to the item in the specified
-- slot. If the slot is empty, nil is returned.
function eqs:getItemCombatStats( slotNum )
    local itemStats = {0,0,0,0,0,0}
    itemLink = equipmentSlotTable[slotNum]
    if itemLink ~= nil then
        local stats = {}
        stats = GetItemStats( itemLink, stats )
        -- E:where( sprintf("%d, %d, %d, %d, %d, %d, %d\n", stats[1],stats[2],stats[3],stats[4],stats[5],stats[6],stats[7] ))
        -- itemStats[DPS_TRACKER_STAMINA]        = stats["ITEM_MOD_STAMINA_SHORT"]
        -- itemStats[DPS_TRACKER_INTELLECT]      = stats["ITEM_MOD_INTELLECT_SHORT"]
        -- itemStats[DPS_TRACKER_HASTE]          = stats["ITEM_MOD_HASTE_RATING_SHORT"]
        -- itemStats[DPS_TRACKER_CRITSTRIKE]     = stats["ITEM_MOD_CRIT_RATING_SHORT"]
        -- itemStats[DPS_TRACKER_MASTERY]        = stats["ITEM_MOD_MASTERY_RATING_SHORT"]
        -- itemStats[DPS_TRACKER_AGILITY]        = stats["ITEM_MOD_AGILITY_SHORT"]
        -- itemStats[DPS_TRACKER_VERSATILITY]    = stats["ITEM_MOD_VERSATILITY"]
        
        return itemStats
    end
    return nil
end
-------------------------------------------------------------------------------
-- Sums the player's combat stats. If a table is supplied in the argument list,
-- each summed combat stat is written into the appropriate element of the table.
-- In all cases the values of the summed combat stats are returned as a list
-- of values.
-- USAGE:
--      (1) combatStats = { eqs:getTotalStats() }
--      (2)local stamina, intellect, haste, critStrike, mastery, agility, versatility = eqs:getTotalStats()
--
--      (3local combatStats = {}
--      eqs:getTotalStats( combatStats )
function eqs:getTotalStats( totalStats )
    if totalStats ~= nil then
        totalStats = {}
    end
    for slotNum = FIRST_SLOT, LAST_SLOT do
        itemStats = eqs:getItemCombatStats( slotNum )
        E:where( "Equipment slot # "..tostring( slotNum ))
        if itemStats ~= nil then
            for i = DPS_TRACKER_STAMINA, DPS_TRACKER_VERSATILITY do
                -- if itemStats[i] ~= nil then
                --     totalStats[i] = totalStats[i] + itemStats[i]
                -- end
                E:where("Combat Stat["..tostring(i).."]")
            end
        end
    end
    return totalStats[1],totalStats[2],totalStats[3],totalStats[4],totalStats[5],totalStats[6],totalStats[7]
end
-------------------------------------------------------------------------------
-- Returns the player's average item level as calculated from the item levels of 
-- each equipped item divided by the number of equipped items.
function eqs:getPlayerItemLevel()
    local sum = 0 -- sum of item levels
    local count = 0 -- item count
    local itemLevel = 0

    for slotNum = FIRST_SLOT, LAST_SLOT do
        local n = eqs:getItemLevel( slotNum )
        if n ~= nil then
            sum = sum + n
            count = count + 1
        end
    end

    if count ~= 0 then
        itemLevel = sum/count
    end
    return itemLevel
end

initEquipSlotTable()
--*****************************************************************************
--              EVENT HANDLER
-- Fires when the player equips or unequips an item.
--*****************************************************************************
local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent( "PLAYER_EQUIPMENT_CHANGED") 
eventFrame:SetScript("OnEvent",
function( self, event, ... )
    local arg1, arg2, arg3, arg4 = ...
    
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        -- arg1 - the slot that changed
        -- arg2 - true if the slot is now empty, false otherwise
            mf:postMsg(sprintf("Player inventory changed.\n" ))
            initEquipSlotTable()
        return
    end
end)










