//
// Team Blue Spring's Series of Libaries. 
// "Artificial Inteligence" Functions
//

rawset(_G, "TBS_AI", {
	-- version control
	major_iteration = 1, -- versions with extensive changes. 	
	iteration = 1, -- additions, fixes. No variable changes.
	version = "DEV", -- just a string...
})


TBS_AI.runAwayFromPlayer = function(mobj, speed, fly)





end

-- todo: make enemy go to player but once they damage the player, either overshoot or go back
-- mobjinfo_t mobj; fixed_t speed; bool fly; bool fallback;
TBS_AI.towardsPlayer = function(mobj, speed, fly, fallback)





end

TBS_AI.panicMovement = function(mobj, speed, fly)





end

--
--	Modules
--


if TBSWaylib then
	TBS_AI.findPathToTarget = function(mobj, target)




	end

	TBS_AI.findPathToDest = function(mobj, x, y, z)




	end	

	TBS_AI.pathTrace = function(mobj, speed, fly)




	end
end

if TBSlib then 
	TBS_AI.snakeSwinging = function(mobj, target)




	end
end