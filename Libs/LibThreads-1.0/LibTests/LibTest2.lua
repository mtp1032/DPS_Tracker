-- FILE NAME:		Test2.lua
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   25 May, 2023
local _, LibTests = ...
LibTests.Test2 = {} 
test2 = LibTests.Test1
------------------------------------------------------------
-- Simple regression test: 
--  :getParentThread(), getChildThreads()
--
-- tests:   :create( ticks, function )
--          :sendSignal( thread_h, sig ), :getSignal()
--          :yield(), delay(ticks)
--          :getParentThread(), :getChildThreads()
------------------------------------------------------------

local sprintf = _G.string.format 
local C = core

local Major ="LibThreads-1.0"
local thread = LibStub:GetLibrary( Major )
if not thread then 
    return 
end

local SIG_ALERT             = thread.SIG_ALERT
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING

local SUCCESS   = thread.SUCCESS
local EMPTY_STR = thread.EMPTY_STR

local main_h    = nil

local function grandChildProc()
    local signal = SIG_NONE_PENDING
    local DONE = false

    thread:delay( 60 )
    C:dbgPrint( "Entered Grand Child thread.")
    local parent_h, result = thread:getParent()
    assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))

    local grandParent_h, result = thread:getParent( parent_h )
    assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))

    while DONE do
        thread:yield()
        signal, sender_h = getSignal()
        if signal == SIG_TERMINATE then
            DONE = true
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage( "Grand child thread terminated successully.", 0.0, 1.0, 1.0 )
end
local function childFunc()
    local result = { SUCCESS, EMPTY_STR, EMPTY_STR }
    local signal = SIG_NONE_PENDING
    local DONE = false
    C:dbgPrint( "Entered Child thread.")

    -- create a grandChild
    local grandChild_h, result = thread:create( 30, grandChildProc )
    assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))

    while not DONE do
        thread:yield()
        signal, sender_h = thread:getSignal()
        if signal == SIG_TERMINATE then
            DONE = true
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage( "Child thread terminated successully.", 0.0, 1.0, 1.0 )
end
local function main()
    local signal = SIG_NONE_PENDING
    local DONE = false
    local childThreads = {}
    
    C:dbgPrint("Entered main()")

    local child_h, result = thread:create( 60, childFunc )
    assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))
    
    thread:delay( 60 )

    while not DONE do
        thread:yield()
        local grandChild_h, result = thread:getParent( child_h )
        assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))

        result = thread:sendSignal( grandChild_h, SIG_TERMINATE)
        assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))

        result = thread:sendSignal( child_h, SIG_TERMINATE)
        assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))

        DONE = true
    end
    DEFAULT_CHAT_FRAME:AddMessage( "Main thread terminated successully.", 0.0, 1.0, 1.0 )
end
local status = {SUCCESS, EMPTY_STR, EMPTY_STR}
main_h, status = thread:create( 60, main )
assert( status[1] == SUCCESS, sprintf("ASSERT FAILED: %s", status[2]))
C:dbgPrint("main_h created.")




