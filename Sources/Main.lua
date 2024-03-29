--------------------------------------------------------------------------------------
-- Main.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2019 
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.Main = {}
main = DPS_Tracker.Main

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

-- ********************************************************************************
--						GLOBAL (TO THIS FILE) CONSTANTS AND VARIABLES
-- ********************************************************************************
local damage_h  = nil
local heal_h    = nil
local aura_h 	= nil
local miss_h 	= nil
local main_h	= nil

-- ********************************************************************************
--							FUNCTION DEFINITIONS
-- ********************************************************************************


local function damageThreadFunc()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR }
    local DONE = false 

    local _, selfId = thread:self()
    -- DEFAULT_CHAT_FRAME:AddMessage( sprintf("Damage thread[%d] (damage_h) running", selfId) ) 

    while not DONE do
        thread:yield()
        
        local signal = thread:getSignal()
        while signal == SIG_ALERT do
            local isCrit, damageStr, remainingEntries = cleu:getDmgString()
            if damageStr ~= nil then
                scroll:damageEntry( isCrit, damageStr )
                isCrit, damageStr, remainingEntries = cleu:getDmgString()
            end
            thread:delay( 20 )
            signal = thread:getSignal()
        end
        if signal == SIG_TERMINATE then
            DONE = true
        end  
    end
end
local function healThreadFunc()     -- action routine for the heal_h thread
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR }
    local DONE = false 

    local _, selfId = thread:self()
    -- DEFAULT_CHAT_FRAME:AddMessage( sprintf("Heal thread[%d] (heal_h) running", selfId) ) 

    while not DONE do
        thread:yield()

        local signal = thread:getSignal()
        while signal == SIG_ALERT do
            local isCrit, healStr, remainingEntries = cleu:getHealString()
            if healStr ~= nil then
                scroll:healEntry( isCrit, healStr)
                isCrit, healStr, remainingEntries = cleu:getHealString()
            end
            thread:delay( 20 )
            signal = thread:getSignal()
        end
        if signal == SIG_TERMINATE then
            DONE = true
        end                
    end
end
local function auraThreadFunc()     -- action routine for the aura thread
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR }
    local DONE = false 

    local _, selfId = thread:self()
    -- DEFAULT_CHAT_FRAME:AddMessage( sprintf("Aura thread[%d] (aura_h) running", selfId) ) 

    while not DONE do
        thread:yield()

        local signal = thread:getSignal()
        while signal == SIG_ALERT do
            local auraString, remainingEntries = cleu:getAuraString()
            if auraString ~= nil then
                scroll:auraEntry( auraString )
                auraString, remainingEntries = cleu:getAuraString()
            end
            thread:delay( 20 )
            signal = thread:getSignal()
        end
        if signal == SIG_TERMINATE then
            DONE = true
        end                
    end
end
local function missThreadFunc()     -- action routine for the miss thread
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR }
    local DONE = false 

    local _, selfId = thread:self()
    -- DEFAULT_CHAT_FRAME:AddMessage( sprintf("Miss thread[%d] (miss_h) running", selfId) ) 

    while not DONE do
        thread:yield()

        local signal = thread:getSignal()
        while signal == SIG_ALERT do
            local missString = cleu:getMissString()
            if missString ~= nil then
                scroll:missEntry( missString)
                missString, remainingEntries = cleu:getMissString()
            end
            thread:delay( 20 )
            signal = thread:getSignal()
        end
        if signal == SIG_TERMINATE then
            DONE = true
        end                
    end
end
local function exitDpsTracker()
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR }

	result = thread:sentSignal( damage_h, SIG_TERMINATE)
	if not result[1] then mf:postResult( result ) return end

	result = thread:sentSignal( heal_h, SIG_TERMINATE)
	if not result[1] then mf:postResult( result ) return end

	result = thread:sentSignal( miss_h, SIG_TERMINATE)
	if not result[1] then mf:postResult( result ) return end

	result = thread:sentSignal( main_h, SIG_TERMINATE)
	if not result[1] then mf:postResult( result ) return end
end
-------------------------  MAIN FUNCTION -------------------
local function main()
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR }
	local yieldInterval = 30 -- ~ 5 seconds
	local signal = SIG_NONE_PENDING
    local _, selfId = thread:self()

	damage_h, result = thread:create( yieldInterval, damageThreadFunc )
	if not result[1] then mf:postResult( result )return end
	cleu:setDamageThread( damage_h )

	heal_h, result = thread:create( yieldInterval, healThreadFunc )
	if not result[1] then mf:postResult( result ) return end
	cleu:setHealThread( heal_h )

	aura_h, result = thread:create( yieldInterval, auraThreadFunc )
    if not result[1] then mf:postResult( result ) return end
	cleu:setAuraThread( aura_h )

    miss_h, result = thread:create( yieldInterval, missThreadFunc )
	if not result[1] then mf:postResult( result ) return end
	cleu:setMissThread( miss_h )

	while signal ~= SIG_TERMINATE do
		thread:yield()
		signal, sender_h = thread:getSignal()
	end
end

local main_h = nil
local yieldInterval = 300 -- ~ 5 seconds
local result = {SUCCESS, EMPTY_STR, EMPTY_STR }

main_h, result = thread:create( yieldInterval, main )
if not result[1] then mf:postResult( result ) end

local fileName = "Main.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end