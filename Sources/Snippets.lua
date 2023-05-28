--------------------------------------------------------------------------------------
-- Snippets.lua
-- AUTHOR: Michael Peterson 
-- ORIGINAL DATE: 18 April, 2023
--------------------------------------------------------------------------------------
local _, DPS_Tracker = ...
DPS_Tracker.Snippets = {}
snippets = DPS_Tracker.CleuDB 

local L = DPS_Tracker.L
local sprintf = _G.string.format


--[[  
========== COPIES OF scrollEntry() services ============
function scroll:damageEntry( isCrit, floatingText )
	local f = acquireFrame()
	f.Text:SetTextColor( 1.0, 0.0, 0.0 )	-- red
	f.Text:SetText( floatingText )
	f:ClearAllPoints()
	f:SetPoint("CENTER", xPos, yPos )

	local origXpos, xDelta, origYpos, yDelta = getStartingPositions( DAMAGE_EVENT )
	local xPos 		= origXpos
	local yPos 		= origYpos
	local alpha		= 0.3
	f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\LibFonts\\Bazooka.ttf", 16 )

	if isCrit then
		f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\LibFonts\\Bazooka.ttf", 32 )
		yDelta 	= 6
		xDelta	= 6
		alpha	= 1.0
		xPos	= xPos + 25
	end

	f:SetPoint("CENTER", xPos, yPos )

  	f:SetScript("OnUpdate", 
		function(self, elapsed)
			self.TicksRemaining = self.TicksRemaining - 1
			if self.TicksRemaining > 0 then
				return
			end

			self.TicksRemaining = TICKS_PER_INTERVAL
			self.TotalTicks = self.TotalTicks + 1

			if self.TotalTicks == 4 then 
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			elseif self.TotalTicks == 10 then 
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			elseif self.TotalTicks == 20 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			elseif self.TotalTicks == 30 then 
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			elseif self.TotalTicks == 40 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks <=  50 then 	-- move the frame
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks > 50 then	-- reset and release the frame
				self.TotalTicks = 0
				f.Text:SetText("")
				f:ClearAllPoints()
				f.Text:SetPoint( "CENTER", origXpos, origYpos )
				if isCrit then
					f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\LibFonts\\Bazooka.ttf", 16 )
				end
				releaseFrame(f)
			elseif self.TotalTicks < 50 then
				f:ClearAllPoints()
				f:SetPoint( "CENTER", xPos, yPos )
			end
		end)
end
function scroll:healEntryXXX( isCrit, floatText )
	-- dbg:print( tostring(isCrit) .. ", " .. floatText)
	local f = acquireFrame()
	f.Text:SetTextColor(  0.0, 1.0, 0.0 )	-- green
	f.Text:SetText( floatText )
	f:ClearAllPoints()

	-- Sets the size depending on whether the spell hit critcally
	if isCrit then		
		f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 32 )
	else
		f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 16 )
	end

	local xPos, xDelta, yPos, yDelta = getStartingPositions( HEALING_EVENT )
	
	-- this setting means the text scrolls straight vertically
	local yDelta = 4 -- move vertically every interval (currently set at 4 ticks)
	local xDelta = 0 -- text does not move off of the x-axis

	-- starting positions
	local yPos = yPos + 100
	local xPos = xPos - 200
	if isCrit then
		xPos = xPos - 250
	end

	f.Text:SetPoint( "LEFT", "UIParent", "CENTER", yPos, yPos )
  	f:SetScript("OnUpdate", 
    	function(self, elapsed)
    		self.TicksRemaining = self.TicksRemaining - 1
      		if self.TicksRemaining > 0 then
        		return
      		end
      		self.TicksRemaining = self.TicksPerFrame
      		self.TotalTicks = self.TotalTicks + 1

      		if self.TotalTicks == 40 then -- Original Position
				f:SetAlpha( 0.7 ) 
				if isCrit then f:SetAlpha(1.0) end
				xPos = xPos +xDelta
				yPos = yPos + yDelta
			end
      		if self.TotalTicks == 45 then -- Jump UP
				f:SetAlpha( 0.5 ) 
				if isCrit then f:SetAlpha(1.0) end
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 40 then -- Jump LEFT
				f:SetAlpha(1.0) 
				if isCrit then f:SetAlpha(1.0) end
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 45 then -- Jump DOWN
				f:SetAlpha(1.0) 
				if isCrit then f:SetAlpha(1.0) end
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
      		if self.TotalTicks == 50 then -- Jump RIGHT
				f:SetAlpha(1.0) 
				if isCrit then f:SetAlpha(1.0) end
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
      		if self.TotalTicks == 55 then -- Jump RIGHT
				f:SetAlpha(1.0) 
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
      		if self.TotalTicks >= 60 then 
        		f.Done = true
				f:ClearAllPoints()
				releaseFrame(f)
    		else
				f:SetAlpha(1.0) 
				if isCrit then f:SetAlpha(1.0) end

				-- update/advance the frame's position
				xPos = xPos + xDelta
				yPos = yPos + yDelta
				f.Text:SetPoint( "LEFT", UIParent,"CENTER", xPos, yPos )

				-- f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
				-- f.Text:SetPoint( anchor, "UIParent", anchor, xPos, yPos )
				-- f:ClearAllPoints()
				-- f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
				-- f.Text:SetPoint( anchor, UIParent, anchor, xPos, yPos )
			end
    	end)
end
function scroll:healEntry( isCrit, floatingText)
	-- dbg:print( sprintf("Received '%s'", auraStr ))
	local f = acquireFrame()
	f.Text:SetTextColor( 0.0, 1.0, 0.0  ) -- yellow
	f.Text:SetText( auraStr )  
	-- Sets the size depending on whether the spell hit critcally
	if isCrit then		
		f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 32 )
	else
		f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 16 )
	end

	local anchor, xPos, xDelta, yPos, yDelta = getStartingPositions( HEALING_EVENT )	
	local yDelta = 4 -- move vertically every interval (currently set at 4 ticks)
	local xDelta = 0 -- text does not move off of the x-axis

	-- starting positions
	local yPos = yPos + 100
	local xPos = xPos + 200

	f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
	f:Show()
	f:SetScript("OnUpdate", 
    	function( self )
    		f.TicksRemaining = self.TicksRemaining - 1
      		if self.TicksRemaining > 0 then
        		return
      		end
      		self.TicksRemaining = self.TicksPerFrame
      		self.TotalTicks = self.TotalTicks + 1

      		if self.TotalTicks == 5 then -- Starting position
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
      		if self.TotalTicks == 10 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 15 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 20 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
      		if self.TotalTicks == 25 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 30 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 35 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks >= 35 then 
				dbg:print( tostring( self.TotalTicks ))
				f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
				releaseFrame(f)
    		else
				f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
			end
    	end)
end
function scroll:auraEntry( auraStr )
	-- dbg:print( sprintf("Received '%s'", auraStr ))
	local f = acquireFrame()
	f.Text:SetTextColor( 1.0, 1.0, 0.0 ) -- yellow
	f.Text:SetText( auraStr )  

	local anchor, xPos, xDelta, yPos, yDelta = getStartingPositions( HEALING_EVENT )	
	
	-- starting positions
	local yPos = yPos + 100 -- Right of center
	local xPos = xPos - 200 -- Below center
	
	local yDelta = 4 -- move vertically every interval (currently set at 4 ticks)
	local xDelta = 0 -- text does not move off of the x-axis

	f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
	f:Show()
	f:SetScript("OnUpdate", 
    	function( self )
    		f.TicksRemaining = self.TicksRemaining - 1
      		if self.TicksRemaining > 0 then
        		return
      		end
      		self.TicksRemaining = self.TicksPerFrame
      		self.TotalTicks = self.TotalTicks + 1

      		if self.TotalTicks == 5 then -- Starting position
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
      		if self.TotalTicks == 10 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 15 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 20 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
      		if self.TotalTicks == 25 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 30 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks == 35 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end
			if self.TotalTicks >= 35 then 
				dbg:print( tostring( self.TotalTicks ))
				f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
				releaseFrame(f)
    		else
				f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
			end
    	end)
end
function scroll:missEntry( entry )
	local f = acquireFrame()
	f.Text:SetTextColor(  0.0, 1.0, 1.0  )	-- turquoise
	f.Text:SetFont( "Interface\\Addons\\DPS_Tracker\\Fonts\\Bazooka.ttf", 16 )
	f.Text:SetText( entry )

	local anchor, xPos, xDelta, yPos, yDelta = getStartingPositions( MISS_EVENT )
	f.Text:SetPoint( anchor, "UIParent", anchor, xPos, yPos )

	xPos = -150
	yPos = 200

	local yDelta = 2.0 -- move this much each update
	local xDelta = 0.0 -- this means the text will scroll vertically

  	f:ClearAllPoints()
	f.Done = false

  	f.TotalTicks = 0
  	f.TicksPerFrame = 4 -- Move the frame once every 4 ticks
  	f.TicksRemaining = f.TicksPerFrame
  	f:SetScript("OnUpdate", 
  
    	function(self, elapsed)
    		self.TicksRemaining = self.TicksRemaining - 1
      		if self.TicksRemaining > 0 then
        		return
      		end

      		self.TicksRemaining = self.TicksPerFrame
      		self.TotalTicks = self.TotalTicks + 1
      		if self.TotalTicks == 40 then f:SetAlpha( 1.0 ) end
      		if self.TotalTicks == 45 then f:SetAlpha( 0.7 ) end
      		if self.TotalTicks == 50 then f:SetAlpha( 0.4 ) end
      		if self.TotalTicks == 55 then f:SetAlpha( 0.1 ) end
      		if self.TotalTicks >= 60 then 
      			f:Hide()
        		f.Done = true
    		else
        		yPos = yPos + yDelta
        		xPos = xPos + xDelta
        		f:ClearAllPoints()
				f.Text:SetPoint( "LEFT", UIParent, "CENTER", xPos, yPos )
			end
    	end
	)
    if f.Done == true then
      	releaseFrame(f)
    end
end
 ]]





-- f.SetPoint()
-- https://wowpedia.fandom.com/wiki/API_ScriptRegionResizing_SetPoint
-- f:SetPoint(point [, relativeTo [, relativePoint]] [, offsetX, offsetY])

f.SetPoint(
	Region1,			-- TOPLEFT, TOPRIGHT, LEFT, CENTER, RIGHT, BOTTOMRIGJHT, BOTTOMLEFT
	ParentFrame,	-- Optional
	Region2,
	xOffset,
	yOffset )



-- "TOPLEFT"		"TOP"		"TOPRIGHT"
-- "LEFT"			"CENTER"	"RIGHT
-- "BOTTOMLEFT"				"BOTTOMRIGHT

-- Events:
--	UNIT_COMBAT https://wowpedia.fandom.com/wiki/UNIT_COMBAT
--  UNIT_SPELLCAST_INTERRUPTIBLE: unitTarget https://wowpedia.fandom.com/wiki/UNIT_SPELLCAST_INTERRUPTIBLE
--  UNIT_COMBAT: unitTarget, event, flagText, amount, schoolMask https://wowpedia.fandom.com/wiki/UNIT_COMBAT


	-- HEAL SUBEVENTS
	-- if 	subEvent == "SPELL_HEAL" or 
	-- 	subEvent == "SPELL_HEAL" or
	-- 	subEvent == "SPELL_PERIODIC_HEAL" then
	-- 		table.insert( healSubEventsDB, stats )
	-- 		local spellHealRecord = createSpellDmgRecord( stats )

	-- 		local remainingDmg = updateHealthBar( healthBar, damageDone)
	-- 		if remainingDmg <= 0 then
	-- 			stopRecording()		-- sets RECORDING_IN_PROGRESS to false
	-- 			dbg:print(" ***** TARGET HAS DIED ***** ")
	-- 			spellHealRecord[SUBEVENT_OVERKILL] = remainingDmg * (-1)
	-- 		end
	-- 		updateSpellDmgDB( spellHealRecord )
	-- 		local spellHealRecord = createSpellDmgRecord( stats )
	-- 		insertDamage( isCritical, damageDone)				-- signals damage_h thread


	-- 		table.insert( healSubEventsDB, stats )
	-- 		return
	-- end
	-- if  subEvent == "SPELL_MISSED" or
	-- 	subEvent == "SWING_MISSED" or
	-- 	subEvent == "SPELL_PERIODIC_MISSED" or
	-- 	subEvent == "RANGE_MISSED" then

	-- 		return
	-- end
	-- if  subEvent == "SPELL_AURA_APPLIED" or 
	-- 	subEvent == "SPELL_AURA_REMOVED" or
	-- 	subEvent == "SPELL_AURA_REFRESH" or
	-- 	subEvent == "SPELL_AURA_BROKEN" or
	-- 	subEvent == "SPELL_AURA_BROKEN_SPELL" or
	-- 	subEvent == "SPELL_AURA_APPLIED_DOSE" then

	-- 	table.insert( auraSubEventsDB, stats )
	-- 	-- if cleu:floatingAurasIsEnabled() then
	-- 	-- 	result = thread:sendSignal( aura_h, SIG_ALERT )
	-- 	-- 	if not result[1] then mf:postResult( result ) return end
	-- 	-- end
	-- 	return
	-- end
-- end



	-- StaticPopupDialogs["SUMMARIZE_COMBAT"] = {
	-- 	text = "Summarize The Encounter?",
	-- 	button1 = "Yes",
	-- 	button2 = "No",
	-- 	OnAccept = function()
	-- 				summarizeEncounter()
	-- 	 		   end,
	-- 	timeout = 0,
	-- 	whileDead = true,
	-- 	hideOnEscape = true,
	-- }
	-- StaticPopup_Show("SUMMARIZE_COMBAT")

	-- -- if DUMP_COMBAT_LOG then 
	-- -- 	dumpCELU()
	-- -- end
-- end

