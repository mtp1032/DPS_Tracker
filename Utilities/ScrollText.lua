--------------------------------------------------------------------------------------
-- ScrollText.lua 
-- AUTHOR: Michael Peterson 
-- ORIGINAL DATE: 16 April, 2023
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.ScrollText = {}
scroll = DPS_Tracker.ScrollText

local L = DPS_Tracker.L
local sprintf = _G.string.format

	-- set the color
	-- f.Text:SetTextColor( 1.0, 1.0, 1.0 )  -- white
	-- f.Text:SetTextColor( 0.0, 1.0, 0.0 )  -- green
	-- f.Text:SetTextColor( 1.0, 1.0, 0.0 )  -- yellow
	-- f.Text:SetTextColor( 0.0, 1.0, 1.0 )  -- turquoise
	-- f.Text:SetTextColor( 0.0, 0.0, 1.0 )  -- blue
	-- f.Text:SetTextColor( 1.0, 0.0, 0.0 )  -- red

local DAMAGE_EVENT  = base.DAMAGE_EVENT
local HEALING_EVENT	= base.HEALING_EVENT
local AURA_EVENT    = base.AURA_EVENT
local MISS_EVENT	= base.MISS_EVENT

local TICKS_PER_INTERVAL = 4

local framePool = {}

local function createNewFrame()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetSize(5, 5)
	f:SetPoint( "CENTER", 0, 0 )
	f.Text = f:CreateFontString("Bazooka")
	f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 32 )
	f.Text:SetPoint( "CENTER" )
	f.Text:SetJustifyH("LEFT")
	f.Text:SetJustifyV("TOP")
	f.Text:SetText("")

	f.IsCrit 			= false
	f.alpha				= 0.03
	f.TotalTicks 		= 0
	f.TicksPerFrame 	= TICKS_PER_INTERVAL
	f.TicksRemaining 	= f.TicksPerFrame
  return f
end
local function releaseFrame( f ) 
    f.Text:SetText("")
	f:Hide()
    table.insert( framePool, f )
end
local function initFramePool()
  local f = createNewFrame()
  table.insert( framePool, f )
end
local function acquireFrame()
  	local f = table.remove( framePool )
  	if f == nil then 
      	f = createNewFrame() 
    end
	f:Show()
    return f
end

local DMG_STARTX 	= 50
local DMG_XDELTA	= 0
local DMG_STARTY 	= 25
local DMG_YDELTA	= 3

local HEAL_STARTX 	= -(2* DMG_STARTX)
local HEAL_XDELTA	= 0
local HEAL_STARTY 	= DMG_STARTY
local HEAL_YDELTA	= 3

local AURA_STARTX 	= -600
local AURA_XDELTA	= 0
local AURA_STARTY 	= 200
local AURA_YDELTA	= 3

local MISS_STARTX 	= 0
local MISS_XDELTA	= 0
local MISS_STARTY 	= 100
local MISS_YDELTA	= 3

local count = 0
local function getStartingPositions( combatType )
  
	if combatType == DAMAGE_EVENT then 
		if count == 1 then
			DMG_STARTX = 70
			count = 0
		else
			DMG_STARTX = 50
			count = 1
		end
		return DMG_STARTX, DMG_XDELTA, DMG_STARTY, DMG_YDELTA
	end
	if combatType == HEALING_EVENT then
		return HEAL_STARTX, HEAL_XDELTA, HEAL_STARTY, HEAL_YDELTA
	end 
	if combatType == AURA_EVENT then
		return AURA_STARTX, AURA_XDELTA, AURA_STARTY, AURA_YDELTA
	end
	if combatType == MISS_EVENT then    -- -400 pixels left of center, 200 pixels above center
		return MISS_STARTX, MISS_XDELTA, MISS_STARTY, MISS_YDELTA
	end
	return nil, nil, nil, nil
end
local function scrollText(f, startX, xDelta, startY, yDelta )
	local xPos = startX
	local yPos = startY

	f:SetScript("OnUpdate", 
	function( f )
		f.TicksRemaining = f.TicksRemaining - 1
		if f.TicksRemaining > 0 then
			return
		end
		f.TicksRemaining = TICKS_PER_INTERVAL
		f.TotalTicks = f.TotalTicks + 1

		if f.TotalTicks == 4 then 
			xPos = xPos + xDelta
			yPos = yPos + yDelta
		-- elseif f.TotalTicks == 10 then 
		-- 	xPos = xPos + xDelta
		-- 	yPos = yPos + yDelta
		elseif f.TotalTicks == 24 then
			xPos = xPos + xDelta
			yPos = yPos + yDelta
		-- elseif f.TotalTicks == 30 then 
		-- 	xPos = xPos + xDelta
		-- 	yPos = yPos + yDelta
		-- elseif f.TotalTicks == 40 then
		-- 	xPos = xPos + xDelta
		-- 	yPos = yPos + yDelta
		end	
		if f.TotalTicks <=  30 then 	-- move the frame
			xPos = xPos + xDelta
			yPos = yPos + yDelta
			f:ClearAllPoints()
			f:SetPoint( "CENTER", xPos, yPos )
		end
		if f.TotalTicks > 30 then	-- reset and release the frame
			f.TotalTicks = 0
			f.Text:SetText("")
			f:ClearAllPoints()
			f:SetPoint( "CENTER", 0, 0 )
			releaseFrame(f)
		end
	end)
end
function scroll:damageEntry( isCrit, dmgText )
	local f = acquireFrame()
	f.Text:SetTextColor( 1.0, 0.0, 0.0 )	-- red
	f.Text:SetText( dmgText )
	f.IsCrit = isCrit

	local startX, xDelta, startY, yDelta = getStartingPositions( DAMAGE_EVENT )
	local xPos 		= startX
	local yPos 		= startY
	f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 32 )
	if f.IsCrit then
		f.Alpha	= 0.9
		f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 40 )
		yDelta 	= 6
		xDelta	= 6
		xPos	= xPos + 25
	end

	f:ClearAllPoints()
	f:SetPoint("CENTER", xPos, yPos )

	scrollText(f, xPos, xDelta, yPos, yDelta )
end
function scroll:healEntry( isCrit, healText )
	local f = acquireFrame()
	f.Text:SetTextColor( 0.0, 1.0, 0.0 )  -- green
	f.Text:SetText( healText )
	f.IsCrit 		= isCrit

	local startX, xDelta, startY, yDelta = getStartingPositions( HEALING_EVENT )
	local xPos 		= startX
	local yPos 		= startY
	f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 32 )
	if f.IsCrit then
		f.Alpha	= 0.9
		f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 32 )
		yDelta 	= 6
		xDelta	= -6
		xPos	= xPos + 25
	end

	f:ClearAllPoints()
	f:SetPoint("CENTER", xPos, yPos )

	scrollText(f, xPos, xDelta, yPos, yDelta )
end
function scroll:auraEntry( auraText )
	local f = acquireFrame()
	f.Text:SetTextColor( 1.0, 1.0, 0.0 )  -- yellow
	f.Text:SetText( auraText )

	local startX, xDelta, startY, yDelta = getStartingPositions( AURA_EVENT )
	local xPos 		= startX 
	local yPos 		= startY

	f:ClearAllPoints()
	f:SetPoint("CENTER", xPos, 200 )

	scrollText(f, xPos, xDelta, startY, yDelta)
end
function scroll:missEntry( missText )
	local f = acquireFrame()
	f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 24 )
	f.Text:SetTextColor( 1.0, 1.0, 1.0 )  -- white
	f.Text:SetText( missText )

	local startX, xDelta, startY, yDelta = getStartingPositions( MISS_EVENT )
	local xPos 		= startX 
	local yPos 		= startY

	f:ClearAllPoints()
	f:SetPoint("CENTER", xPos, yPos )
	scrollText(f, xPos, xDelta, startY, yDelta)
end

initFramePool()
local fileName = "ScrollText.lua"
if base:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded.", fileName ), 1.0, 1.0, 0.0 )
end
