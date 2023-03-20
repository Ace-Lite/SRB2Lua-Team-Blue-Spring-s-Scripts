//
// C-Lua translation of A_DragonSegment
//

local function segment_follow(a)
  if not (a.target or a.targetmove) then return end
  local t = a.target
  
  local dist = P_AproxDistance(P_AproxDistance(a.x - t.x, a.y - t.y), a.z - t.z)
	local radius = a.radius + t.radius
	local hangle = R_PointToAngle2(t.x, t.y, a.x, a.y)
	local zangle = R_PointToAngle2(0, t.z, dist, a.z)
	local hdist = P_ReturnThrustX(t, zangle, radius)
	local xdist = P_ReturnThrustX(t, hangle, hdist)
	local ydist = P_ReturnThrustY(t, hangle, hdist)
	local zdist = P_ReturnThrustY(t, zangle, radius)

	local a.angle = hangle
	P_MoveOrigin(a, t.x + xdist, t.y + ydist, t.z + zdist)

  if a.tracer then
    local p = a.tracer
    p.

    
  end
end



local function dragontrain_run(a)
  if not (a.spawnpoint or      TaggedObj[a.spawnpoint.tag]) then return end
  
	if not (a.tbswaypoint) then
		libWay.activate(a, a, a.spawnpoint.args[0], a.spawnpoint.args[1])
	end

  if not (a.spawnpoint.args[3] & CC_REVERSEMOVE) then
		a.tbswaypoint.flip = false				
		a.tbswaypoint.progress = $+1
	else
		a.tbswaypoint.flip = true
		a.tbswaypoint.progress = $-1
  end

	local waypointobj = Waypoints[a.tbswaypoint.id][a.tbswaypoint.pos]
	local waypointinfo = Waypoints[a.tbswaypoint.id][a.tbswaypoint.pos].spawnpoint		
		
	local progress = ((a.tbswaypoint.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)		
		
	if progress == 0 or progress == FRACUNIT then
			Path_IfNextPoint(a.tbswaypoint, progress)
			a.tbswaypoint.nextway, a.tbswaypoint.prevway = Path_CheckPositionInWaypoints(a.tbswaypoint.pos, Waypoints[a.tbswaypoint.id].timeline)			
	end

		//
		//	POSITION
		//		

		waypointobj = Waypoints[a.tbswaypoint.id][a.tbswaypoint.pos]	
		waypointinfo = Waypoints[a.tbswaypoint.id][a.tbswaypoint.pos].spawnpoint
		local nextwaypoint = Waypoints[a.tbswaypoint.id][a.tbswaypoint.nextway]

		progress = ((a.tbswaypoint.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)	
		libWay.pathingFixedMove(a, a, progress, waypointinfo, waypointobj, nextwaypoint)

		//
		//	SPECIAL CASES
		//
		
	if waypointinfo.args[6] & WC_DOWNMOBJ then
	  libWay.deactive(a, a, Waypoints)
		table.remove(TaggedObj, a.spawnpoint.tag)
	end
  
end


local function waterpool_run(mobj)
  if not (mobj.spawnpoint or      TaggedObj[mobj.spawnpoint.tag] or a.target) then return end
  local a = a.target
  
	if not (a.tbswaypoint) then
		libWay.activate(mobj, a, mobj.spawnpoint.args[0], a.spawnpoint.args[1])
    a.tbswaypoint.x-offset = 0
    a.tbswaypoint.y-offset = 0
	end

  if not (mobj.spawnpoint.args[3] & CC_REVERSEMOVE) then
		a.tbswaypoint.flip = false				
		a.tbswaypoint.progress = $+1
	else
		a.tbswaypoint.flip = true
		a.tbswaypoint.progress = $-1
  end

	local waypointobj = Waypoints[a.tbswaypoint.id][a.tbswaypoint.pos]
	local waypointinfo = Waypoints[a.tbswaypoint.id][a.tbswaypoint.pos].spawnpoint		
		
	local progress = ((a.tbswaypoint.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)		
		
	if progress == 0 or progress == FRACUNIT then
			Path_IfNextPoint(a.tbswaypoint, progress)
			a.tbswaypoint.nextway, a.tbswaypoint.prevway = Path_CheckPositionInWaypoints(a.tbswaypoint.pos, Waypoints[a.tbswaypoint.id].timeline)			
	end

		//
		//	POSITION
		//		

    a.tbswaypoint.x-offset = max(min(mobj.radius, a.tbswaypoint.x-offset), -mobj.radius)
    a.tbswaypoint.y-offset = max(min(mobj.radius, a.tbswaypoint.y-offset), -mobj.radius)
  
		waypointobj = Waypoints[a.tbswaypoint.id][a.tbswaypoint.pos]	
		waypointinfo = Waypoints[a.tbswaypoint.id][a.tbswaypoint.pos].spawnpoint
		local nextwaypoint = Waypoints[a.tbswaypoint.id][a.tbswaypoint.nextway]

		progress = ((a.tbswaypoint.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)	
		libWay.pathingFixedMove(a, a, progress, waypointinfo, waypointobj, nextwaypoint)

		//
		//	SPECIAL CASES
		//
		
	if waypointinfo.args[6] & WC_DOWNMOBJ then
	  libWay.deactive(a, mobj, Waypoints)
		table.remove(TaggedObj, mobj.spawnpoint.tag)
	end
  
end

local credits = 0

local function Credits_Run()
    

end

local credits = {
      [1] = "- Blue Spring Team -",
      v.cachePatch(""),
      
      [12] = "- Art -",
      "Ace Lite",
      "Motor Roach",
      "Clone Fighter",
      "Bededede",
      "KamiJojo"

      [18] = "- Programming -",
      "Ace Lite",
      "Clone Fighter",
      "Krabs",

      [24] = "- Map Design -",
      "Ace Lite",
      "Othius",
      ""

      [24] = "- Play Testing -",


      [29] = "- Special Thanks -",  



      [55] = v.cachePatch(""),
}

local Side-By-Side Art = {
  [2] = "MarioSonc",
  
  
}

addHud(function(v, p)
  if not credits then return end


  TBSlib.fontdrawer(v, font, x, y, scale, value, flags, color, alligment, padding, leftadd, symbol)

    
end, "game")
