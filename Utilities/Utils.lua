--------------------------------------------------------------------------------------
-- Utils.lua
-- AUTHOR: Michael Peterson 
-- ORIGINAL DATE: 16 April, 2023 
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.Utils = {}
utils = DPS_Tracker.Utils

local L = DPS_Tracker.L
local sprintf = _G.string.format

function utils:roundUp( num)
    return math.ceil( num )
end
function utils:roundDown( num )
    return math.floor( num )
end
function utils:nearestInt( num ) -- Rounds down to integer

    local lowerInt = math.floor( num )
    local diff = num - lowerInt
    if diff > 0.5 then
        return math.ceil( num )
    end
    return lowerInt
end
function utils:getMeanAndStdDev( dataSet )
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
function utils:hexStrToDecNum( hexAddress ) -- convert hex string to decimal number
	local stringNumber = string.sub(hexAddress, 9)
	return( tonumber( stringNumber, 16 ))
end
function utils:copyTable(t)
	local t2 = {}
	for k,v in pairs(t) do
	  t2[k] = v
	end
	return t2
  end
  
local fileName = "Utils.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
