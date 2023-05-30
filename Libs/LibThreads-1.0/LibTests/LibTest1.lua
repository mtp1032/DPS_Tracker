-- FILE NAME:		Test1.lua
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   25 May, 2023
local _, LibTests = ...
LibTests.Test1 = {} 
test1 = LibTests.Test1
------------------------------------------------------------
-- Simple regression test: 
--  Child thread sends terminate signal
--  to parent thread (sender_h)
--  Upon receipt, parent thread terminates
--  child thread.
--
-- tests:   :create( ticks, function )
--          :sendSignal( thread_h, sig ), :getSignal()
--          :yield(), delay(ticks)
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

local SUCCESS = true
local main_h = nil

local function threadFunc1()
    local result = { SUCCESS, EMPTY_STR, EMPTY_STR }
    local signal = SIG_NONE_PENDING
    local DONE = false
    C:dbgPrint( "Entered Child thread.")

    while not DONE do
        thread:yield()
        signal, sender_h = thread:getSignal()
        if signal ~= SIG_TERMINATE then
            if sender_h ~= nil then
            local senderId, result = thread:getThreadId( sender_h)

            end 
        else
            C:dbgPrint( "Child thread Received SIG_TERMINATE.")
            result = thread:sendSignal( sender_h, SIG_TERMINATE )
            assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))
            DONE = true
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage( "Child thread terminated successully.", 0.0, 1.0, 1.0 )
end

local function main()
    local signal = SIG_NONE_PENDING
    local DONE = false
    
    C:dbgPrint("Entered main()")

    local child_h, result = thread:create( 60, threadFunc1 )
    assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))
    
    thread:delay( 60 )

    result = thread:sendSignal( child_h, SIG_TERMINATE )
    assert( result[1] == SUCCESS, sprintf("ASSERT FAILED: %s", result[2]))

    while not DONE do
        thread:yield()
        signal, sender_h = thread:getSignal()        
        if signal == SIG_TERMINATE then
            DONE = true
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage( "Main thread terminated successully.", 0.0, 1.0, 1.0 )
end

local status = {SUCCESS, EMPTY_STR, EMPTY_STR}
main_h, status = thread:create( 60, main )
assert( status[1] == SUCCESS, sprintf("ASSERT FAILED: %s", status[2]))




