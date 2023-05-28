--------------------------------------------------------------------------------------
-- FILE NAME:       LibThreads-1.0.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   23 May, 2023
--------------------------------------------------------------------------------------
--      This is the public interface to WoWThreads.                                 --
--------------------------------------------------------------------------------------
local _, WoWThreads = ...

-- Establish LibThreads
local Major, Minor = "LibThreads-1.0", 1
local lib = LibStub:NewLibrary( Major, Minor)
if not lib then return end
lib.Table = lib.Table or {}

local L = WoWThreads.L
local sprintf = _G.string.format 

lib.SIG_ALERT            = dispatch.SIG_ALERT
lib.SIG_JOIN_DATA_READY  = dispatch.SIG_JOIN_DATA_READY
lib.SIG_TERMINATE        = dispatch.SIG_TERMINATE
lib.SIG_METRICS          = dispatch.SIG_METRICS
lib.SIG_NONE_PENDING     = dispatch.SIG_NONE_PENDING

local SUCCESS = core.SUCCESS

local function validateThreadHandle( thread_h )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    if thread_h == nil then
        local errMsg = sprintf("Input thread handle nil - %s\n", L["THREAD_HANDLE_NIL"])
        result = core:setResult(L["THREAD_HANDLE_NIL"], debugstack(1) )
        return result
    end  
    -- validate the thread handle's elements
    result = dispatch:checkIfHandleValid( thread_h )
    if not result[1] then return result end
    
    return result
end
-- DESCRIPTION:
-- RETURNS: result
local function validateThreadCreateParms( ticks, func )
    local result = { SUCCESS, EMPTY_STR, EMPTY_STR } 

    if ticks == nil then
        local errMsg = sprintf("%s - ticks not specified.\n", L["INPUT_PARM_NIL"])
        result = core:setResult( errMsg, debugstack(1))
    end
    if type( ticks ) ~= "number" then
        local errMsg = sprintf("%s - ticks not a number.\n", L["INVALID_TYPE"])
        result = core:setResult( errMsg, debugstack(1))
    end
    if func == nil then
        local errMsg = sprintf("%s - Thread function not specified.\n", L["INPUT_PARM_NIL"])
        result = core:setResult( errMsg, debugstack(1))
    end
    if type(func) ~= "function" then
        local errMsg = sprintf("%s - Parameter 2 not a function.\n", L["INVALID_TYPE"])
        result = core:setResult( errMsg, debugstack(1))
    end    
    return result
end
-- DESCRIPTION: Create a new thread.
-- RETURNS: (handle) thread_h, result
function lib:create( ticks, func, ... )
    local result = { SUCCESS, EMPTY_STR, EMPTY_STR } 
    result = validateThreadCreateParms( ticks, func )
    if not result[1] then return nil, result end

    -- Create a handle with a suspended coroutine
    local H, result = dispatch:createHandle( ticks, func )
    if not result[1] then return nil, result end

    local co = dispatch:getCoroutine( H )
    dispatch:insertHandleIntoTCB(H)
    local resumed, val = coroutine.resume( co, ... )
    if not resumed then
        local threadId = dispatch:getThreadId( H )
        local threadState = coroutine.status( co )
        local msg = sprintf("Thread[%d] %s: %s,\n%s\n", threadId, threadState, L["THREAD_RESUME_FAILED"], val)
        result = core:setResult( msg, debugstack(2) )
        return nil, result
    end
    assert( H ~= nil, "ASSERT FAILED")
    assert( result[1] == SUCCESS, sprintf( "%s: Expected 'true', got %s", "ASSERT_FAILED", tostring(result[1]) ))
    return H, result
end 
-- DESCRIPTION: Delays the calling thread for specified number of ticks
-- RETURNS: void
function lib:delay( ticks )
    assert( ticks ~= nil, "ticks: " ..L["INPUT_PARM_NIL"] .. "in lib:delay()." )
    assert( type(ticks) == "number", L["INVALID_TYPE"])

    -- Get the handle of the calling thread
    local thread_h = dispatch:getRunningHandle()

    dispatch:setDelay( thread_h, ticks )    
    dispatch:yield()
end
-- DESCRIPTION: yields execution of the number of ticks specified in thread:create()
-- RETURNS; void
function lib:yield()
    local self_h = dispatch:getRunningHandle()
    dispatch:yield(self_h)
end
-- DESCRIPTION: returns the thread numerical Id
-- RETURNS: (number) threadId, result
function lib:getId( thread_h )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local threadId = nil

    if thread_h == nil then
        thread_h, threadId = dispatch:getRunningHandle()
        return threadId, result
    else -- thread_h was not nil
        result = dispatch:checkIfHandleValid( thread_h )
        if not result[1] then return nil, result end
    end
    if threadId == nil then
        threadId = dispatch:getThreadId( thread_h )
    end
    return threadId, result
end
-- DESCRIPTION: Returns the handle of the calling thread.
-- RETURNS: (handle) thread_h, (number) threadId
function lib:self()
    local self_h, selfId = dispatch:getRunningHandle()
    return self_h, selfId
end
-- DESCRIPTION: determines whether two threads are the same
-- RETURNS: (boolean) true if equal, result
function lib:areEqual( th1, th2 )
    local areEqual = false
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    assert( th1 ~= nil, sprintf("ASSERT FAILED: Param 1 - %s", L["THREAD_HANDLE_NIL"] ))
    assert( th2 ~= nil, sprintf("ASSERT FAILED: Param 2 - %s", L["THREAD_HANDLE_NIL"] ))

    result = validateThreadHandle( th1 )
    if not result[1] then return areEqual, result end
    result = validateThreadHandle( th2 )
    if not result[1] then return areEqual, result end

    local th1Id = dispatch:getThreadId( th1 )
    local th2Id = dispatch:getThreadId( th2)

    areEqual = th1Id == th2Id
    return areEqual, result
end
-- DESCRIPTION: gets the specified thread's parent
-- RETURNS: (handle) parent_h, result
function lib:getParentThread( thread_h )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    -- if thread_h is nil then this is equivalent to "getMyParent"
    if thread_h == nil then
        thread_h = dispatch:getRunningHandle()
    else
        result = dispatch:checkIfHandleValid( thread_h ) 
        if not result[1] then return result end
    end

    local parent_h = dispatch:getThreadParent( thread_h )
    return parent_h, result
end
-- DESCRIPTION: gets a table of the specified thread's children.
-- RETURNS: (table) childThreads, result
function lib:getChildThreads( thread_h )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    -- if thread_h is nil then this is equivalent to "getMyParent"
    if thread_h == nil then
        thread_h = dispatch:getRunningHandle()
    else
        result = dispatch:checkIfHandleValid( thread_h )
        if not result[1] then 
            return nil, result 
        end
    end

    local children, tableCount = dispatch:getThreadChildren( thread_h )
    if tableCount == 0 then 
        children = nil 
    end
    return children, result
end    
-- DESCRIPTION: gets the specified thread's execution state
-- RETURNS: (string) state ( = "completed", "suspended", "queued", ), result.
function lib:getState( thread_h )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    if thread_h == nil then
        result = core:setResult( L["THREAD_HANDLE_NIL"], debugstack(1))
        return nil, result
    end
    result = validateThreadHandle( thread_h )
    if not result[1] then return nil, result end
            
    local state = dispatch:getThreadState( thread_h )
    return state, result
end
-----------------------------------------------------------
--                   SIGNAL FUNCTIONS                      -
-----------------------------------------------------------
-- DESCRIPTION: gets the string name of the specified signal
-- RETURNS: (string) signalName. result
function lib:getSignalName( signal )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    result = dispatch:validateSignal( signal )
    if not result[1] then return nil, result end

    local signalName = dispatch:getSignalName( signal )
    return signalName, result
end
-- DESCRIPTION: sends a signal to the specified thread. 
-- RETURNS: result. 
function lib:sendSignal( thread_h, signal )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    if thread_h == nil then
        result = core:setResult( L["THREAD_HANDLE_NIL"], debugstack(1) )
        return result
    end
    result = validateThreadHandle( thread_h )
    if not result[1] then return result end
    
    result = dispatch:validateSignal( signal )
    if not result[1] then return result end

    local state = dispatch:getThreadState( thread_h )
    if state == "completed" then
        core:setResult(L["THREAD_ILLEGAL_OPERATION"], debugstack(1) )
        return result
    end
    
    -- everything is hunky dory
    dispatch:deliverSignal( thread_h, signal )
    return result
end
-- DESCRIPTION: retrieves a signal sent to the calling thread.
-- RETURNS: (number) signal, (handle) sender_h NOTE: sender_h 
-- will be "" (EMPTY_STR) if sent from Blizzard code.
--
-- EXAMPLE: More than one signal in the thread's queue.
-- signal, sender_h = lib:getSignal()
-- while signal ~= SIG_NONE_PENDING do
--     <process signal>
--     signal, sender_h = lib:getSignal()
-- end
function lib:getSignal()
    signal, sender_h = dispatch:getSignal()
    local thread_h, threadId = dispatch:getRunningHandle()
    return signal, sender_h
end
local fileName = "LibThreads-1.0.lua"
if core:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
