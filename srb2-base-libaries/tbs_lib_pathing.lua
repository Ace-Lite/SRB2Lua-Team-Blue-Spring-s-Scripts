//
// Team Blue Spring's Series of Libaries. 
// Waypoint Library
//


local libWay = {
	stringversion = '0.1',
	iteration = 1,
}

local debug = CV_RegisterVar({
	name = "tbs_waypointdebug",
	defaultvalue = "off",
	flags = 0,
	PossibleValue = {off=0, pointsonly=1, full=2}
})
 

//
// Team Blue Spring's Series of Libaries. 
// Simple Waypoint System
//


//
//	Todo:
//	-- Path-Target Approximation polish
//	-- Entrance point approximation (You don't want smooth camera entrance transition???????? wtf)
//  -- Debug Options for me :P
//

//
//	PKZ Todo:
//	-- Waterpool for PKZ2 -> Special Controller
//		-- Allow "2D" movement while in the state
//		-- They going to use specialized controllers
//		-- Repeatable
//		-- Spawn bunch of particles...
//	-- Cutscenes
//		-- PKZ2-PKZ3 transition
//		-- Credits
//  -- Dino Skeleton Trains (PKZ 1-4) -> Re-use
//		-- Hangable from buttom ( :earless: shortcut for AIZ's hanging shit )
//		-- Control pathing of segments by simply teleporting them with "delayed" coordinates
//		-- Oh activated on use
//		-- Respawn
//		-- Multiplayer

local Waypoints = {}
local TaggedObj = {}
local AvailableControllers = {}
local TBS_CamWayVars = {
	active = false;
	id = 0;
	pos = 0;
	progress = 0;
	nextway = 0;
	prevway = 0;
}


addHook("MapChange", function()
	Waypoints = {}
	TaggedObj = {}
	AvailableControllers = {}
	TBS_CamWayVars = {
		active = false;
		id = 0;
		pos = 0;
		progress = 0;
		nextway = 0;
		prevway = 0;
	}	
end)

-- MT_GENERALWAYPOINT
// mapthing.args[0] = Pathway ID
// mapthing.args[1] = Point ID
// mapthing.args[2] = Easing
// mapthing.args[3] = Duration(1 = TICRATE)
// mapthing.args[4] = Enum{Waypoint(0), Starting point(1), Ending point(2)}
// mapthing.args[6] = Flags WC_*
// mapthing.args[7] = Action
// mapthing.args[8] = var1
// mapthing.args[9] = var2

// mapthing.stringargs[0] = tag -- if objects allows for it

//
//	ACTION THINKERS
//

local NumToStringAction = {
	"WAY_FORCESTOP", 
	"WAY_CHANGESCALE", 
	"WAY_CHANGETRACK",
	"WAY_TRIGGERTAG";
}

local StringtoFunctionA = { 
	//Stop movement for specific amount of time
	//var1 - stops the train for amount of time	
	["WAY_FORCESTOP"] = function(a, var1, var2) 
		if not a.tbswaypoint.pause then
			a.tbswaypoint.pause = var1
			a.tbswaypoint.pausebool = true			
		end

		if a.tbswaypoint.pause then
			a.tbswaypoint.pause = $-1
			a.tbswaypoint.progress = $-1
		else
			a.tbswaypoint.pausebool = false
		end
	end;
	
	//Change object scale
	//var1 - amount of scale per tic
	//var2 - target scale 
	["WAY_CHANGESCALE"] = function(a, var1, var2) 
		if var2 > a.scale+var1 then
			a.scale = $+var1
		elseif var2 < a.scale-var1 then
			a.scale = $-var1
		end
	end;
	
	//Target Different Track
	//var1 - target track ID
	//var2 - target pathway ID
	["WAY_CHANGETRACK"] = function(a, var1, var2) 
		a.tbswaypoint.id = var1
		a.tbswaypoint.pos = var2
		a.tbswaypoint.progress = Waypoints[var1][var2].starttics		
	end;
		
	//Triggers anything using this tag
	//var1 - tag
	["WAY_TRIGGERTAG"] = function(a, var1, var2) 
		P_LinedefExecute(var1, a)
	end;
}

//
//	FLAG Constants... yes WC how funny.
//

local WC_DOWNMOBJ = 1 		-- Puts mobj down.
local WC_UNBINDPLAYER = 2 	-- Unbinds player from holding contraption.
local WC_HIDEHUD = 4		-- Hides player's hud
local WC_SHOWHUD = 8		-- Shows player's hud
local WC_PUSHHUD = 16		-- Pushes away player's hud
local WC_BRINGHUD = 32		-- Brings in player's hud
local WC_STOPFORDIALOG = 64	-- Dialog stop

//
//	Flag constants for controller
//

local CC_MOVEMENTACT = 1	-- 	Movement on Activation
local CC_ORIGINSMOBJ = 2	-- 	Count Mobj's Origin point as very first point
local CC_REMOVENOGRV = 4	-- 	Remove MF_NOGRAVITY after removal from system
local CC_RESETPOSTOZ = 8	-- 	When there is no next waypoint, teleport at 0
local CC_IFZEROACTIV = 16	-- 	If on pos 0, it will require outside activation
local CC_REVERSEMOVE = 32	-- 	Reverse Movement
local CC_GRAVITYFORC = 64	-- 	Only manipulate X|Y
local CC_DONTTELEPOR = 128	-- 	Doesn't teleport object to start
local CC_APPRXTARGET = 256  --	Appoximates Object target
local CC_DONTROTATEO = 512  --	Doesn't rotate Angle
local CC_MOONWALKFOR = 1024 --  Moon walk lol
local CC_MOMENTUMEND = 2048 --  Gives momentum after end


freeslot("MT_GENERALWAYPOINT", "MT_PATHWAYCONTROLLER")
mobjinfo[MT_PATHWAYCONTROLLER] = {
//$Category TBS Library
//$Name Pathway Controller
//$Sprite BOM1A0
	doomednum = 2701,
	spawnstate = S_INVISIBLE,
	spawnhealth = 1,
	reactiontime = 1,
	speed = 12,
	radius = 32*FRACUNIT,
	height = 64*FRACUNIT,
	mass = 100,
	flags = MF_NOGRAVITY
}

mobjinfo[MT_GENERALWAYPOINT] = {
//$Category TBS Library
//$Name Generalize Waypoint
//$Sprite BOM1A0
	doomednum = 2700,
	spawnstate = S_INVISIBLE,
	spawnhealth = 1,
	reactiontime = 1,
	speed = 12,
	radius = 32*FRACUNIT,
	height = 64*FRACUNIT,
	mass = 100,
	flags = MF_NOGRAVITY
}

local function isminusorplus(s)
	if s > 0 then
		return 1
	else
		return -1
	end
end


local SwitchEasing = {
	[0] = function(t, s, e) return ease.linear(t, s, e) end;
	[1] = function(t, s, e) return ease.outsine(t, s, e) end;
	[2] = function(t, s, e) return ease.outexpo(t, s, e) end;
	[3] = function(t, s, e) return ease.outquad(t, s, e) end;
	[4] = function(t, s, e) return ease.outback(t, s, e) end;
	[5] = function(t, s, e) return TBSlib.quadBezier(t, s, s+isminusorplus(s)*abs(e-s)/4, e) end;
	[6] = function(t, s, e) return TBSlib.quadBezier(t, s, s-isminusorplus(s)*abs(e-s)/4, e) end;
	[7] = function(t, s, e) return TBSlib.quadBezier(t, s, s+isminusorplus(s)*abs(e-s)/2, e) end;
	[8] = function(t, s, e) return TBSlib.quadBezier(t, s, s-isminusorplus(s)*abs(e-s)/2, e) end;
	[9] = function(t, s, e) return TBSlib.quadBezier(t, s, s+isminusorplus(s)*abs(e-s)/3, e) end;
	[10] = function(t, s, e) return TBSlib.quadBezier(t, s, s-isminusorplus(s)*abs(e-s)/3, e) end;	
}

local function Math_CheckPositive(num)
	if num > 0 then
		return true
	elseif num == 0 then
		return nil
	else
		return false
	end
end


local function Path_CheckPositionInWaypoints(current, list)
	local nextway, prevway = 0, 0

	local nextone = false
	for k, v in ipairs(list) do
		if nextone then 
			nextway = v
			break
		end
		
		if v == current and not nextone then 
			nextone = true 
		else	
			prevway = v
		end
	end

	if not nextway then
		nextway = list[1]
	end

	if not prevway then
		prevway = list[#list]
	end

	return nextway, prevway
end

local function Path_IfNextPoint(data, progress)
	if progress == FRACUNIT then
		data.pos = data.nextway
		data.progress = Waypoints[data.id][data.nextway].starttics+1
	end
	if progress == 0 then
		data.progress = Waypoints[data.id][data.prevway].starttics+(Waypoints[data.id][data.pos].spawnpoint.args[3]*TICRATE)-1
		data.pos = data.prevway
	end	
end

libWay.activateMapExecute = function(line,mobj,sector)
	if not (mobj.player or AvailableControllers[line.args[1]]) then return end
	local controller = AvailableControllers[line.args[1]]

	mobj.tbswaypoint = {
		id = controller.spawnpoint.args[0];
		pos = controller.spawnpoint.args[1];
		progress = Waypoints[controller.spawnpoint.args[0]][controller.spawnpoint.args[1]].starttics;
		flip = false;
		-- original flags so, I could simply turn them on
		flags = target.flags;
		flags2 = target.flags2;
	}
	
	target.flags = $|MF_NOGRAVITY
	target.tbswaypoint.nextway, target.tbswaypoint.prevway = Path_CheckPositionInWaypoints(target.tbswaypoint.pos, Waypoints[target.tbswaypoint.id].timeline)	
end

addHook("LinedefExecute", libWay.activateMapExecute, "TBS_WAY")

libWay.activateCameraExecute = function(line,mobj,sector)
	if not AvailableControllers.camera[line.args[1]] then return end
	local controller = AvailableControllers[line.args[1]]

	TBS_CamWayVars.id = controller.spawnpoint.args[0];
	TBS_CamWayVars.pos = controller.spawnpoint.args[1];
	TBS_CamWayVars.progress = Waypoints[controller.spawnpoint.args[0]][controller.spawnpoint.args[1]].starttics;

	TBS_CamWayVars.nextway, TBS_CamWayVars.prevway = Path_CheckPositionInWaypoints(TBS_CamWayVars.pos, Waypoints[TBS_CamWayVars.id].timeline)
	TBS_CamWayVars.active = true;	
end

addHook("LinedefExecute", libWay.activateCameraExecute, "TBS_CWAY")

libWay.activate = function(source, target, path, point)
	target.tbswaypoint = {
		id = way;
		pos = point;
		progress = Waypoints[way][point].starttics;		
		flip = false;
		-- original flags so, I could simply turn them on
		flags = target.flags;
		flags2 = target.flags2;		
	}

	target.flags = $|MF_NOGRAVITY
	target.tbswaypoint.nextway, target.tbswaypoint.prevway = Path_CheckPositionInWaypoints(target.tbswaypoint.pos, Waypoints[target.tbswaypoint.id].timeline)
end

libWay.slotPathway = function(container, path)
	if not (container[path]) then
		container[path] = {}
		container[path].timeline = {}
	end
end

libWay.addWaypoint = function(path, way, a_x, a_y, a_z, a_angle, a_roll, a_pitch, a_options, a_stringoptions)	
	if not container[path][way] then
		table.insert(container[path].timeline, way)
		table.sort(container[path].timeline, function(a, b) return a < b end)
	
		container[path][way] = {starttics = 0; x = fx; y = fy; z = fz; 
		angle = a_angle; roll = a_roll; pitch = a_pitch;
		spawnpoint = {args = a_options; stringargs = a_stringoptions}}
		
		container[path].tics = 0
		for k,v in ipairs(container[path]) do
			if k <= way then
				container[path][way].starttics = $+container[path][way].spawnpoint.args[3]
			end
			container[path].tics = $+container[path][way].spawnpoint.args[3]
		end
	end
end

libWay.delWaypoint = function(container, path, way)	
	if container[path][way] then
		container[path][way] = nil

		for k,v in ipairs(container[path]) do
			if k <= way then
				container[path][way].starttics = $+container[path][way].spawnpoint.args[3]
			end
			container[path].tics = $+container[path][way].spawnpoint.args[3]
		end		
	end
end

libWay.pathingFixedMove = function(a, controller, progress, waypointinfo, waypointobj, nextwaypoint)
	local x = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.x/FRACUNIT, nextwaypoint.x/FRACUNIT)
	local y = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.y/FRACUNIT, nextwaypoint.y/FRACUNIT)
	local z = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.z/FRACUNIT, nextwaypoint.z/FRACUNIT)
	if not (controller.spawnpoint.args[3] & CC_DONTROTATEO) then
		local angleg = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.angle, nextwaypoint.angle)
		a.angle = a.tbswaypoint.flip and InvAngle(angleg) or angleg
	end
	
	P_TeleportMove(a, x*FRACUNIT, y*FRACUNIT, z*FRACUNIT)
end

libWay.lerpToPoint = function(a, target, t)	
	local x, y, z, angle, roll, pitch
	local fixedangle_a, fixedangle_target = AngleFixed(a.angle), AngleFixed(target.angle)
	local fixedpitch_a, fixedpitch_target = AngleFixed(a.pitch), AngleFixed(target.pitch)
	local fixedroll_a, fixedroll_target = AngleFixed(a.roll), AngleFixed(target.roll)

	x = FixedMul(a.x + (target.x - a.x), t)
	y = FixedMul(a.y + (target.y - a.y), t)
	z = FixedMul(a.z + (target.z - a.z), t)
	angle = FixedAngle(FixedMul(fixedangle_a + (fixedangle_target - fixedangle_a), t))
	pitch = FixedAngle(FixedMul(fixedpitch_a + (fixedpitch_target - fixedpitch_a), t))
	roll = FixedAngle(FixedMul(fixedroll_a + (fixedroll_target - fixedroll_a), t))

	return x, y, z, angle, pitch, roll
end

libWay.lerpObjToPoint = function(self, a, target, t)	
	local x, y, z, angle, pitch, roll = self.lerpToPoint(a, target, t)

	P_TeleportMove(a, x, y, z)
	a.angle = angle
	a.pitch = pitch
	a.roll = roll
end

-- varation for player position adjuements
libWay.lerpPlayToPoint = function(self, a, target, t)	
	local x, y, z, angle, pitch, roll = self.lerpToPoint(a, target, t)

	a.angle = angle
	a.pitch = pitch
	a.roll = roll
end

-- direct
libWay.directionPos = function(a, path_angle)
	local ang = a.angle+path_angle
	if ang < ANGLE_180 and ang > ANGLE_MAX then
		return 1
	else
		return -1
	end
end

libWay.directPosPerMomentum = function(self, a, path_angle)
	local direction = self:directionPos(a, path_angle)
	local momentum = FixedHypot(a.momz, FixedHypot(a.momx, a.momy))
	if momentum then
		return direction
	else
		return 0
	end
end

libWay.closestPathToTarget = function(pathway, target)
	local distancefirst = INT32_MAX
	local point_idfirst = 0	
	
	local dropDist = {}

	for k,p in ipairs(pathway) do
		dropDist[k] = P_AproxDistance(P_AproxDistance(target.x - p.x, target.y - p.y), target.z - p.z)
		if distancefirst > dropDist[k] then			
			distancefirst = dropDist[k]
			point_idfirst = k
		end
	end

	local angle_h = R_PointToDist2(pathway[point_idfirst].x, pathway[point_idfirst].y, target.x, target.y)
	local angle_v = R_PointToDist2(pathway[point_idfirst].y, pathway[point_idfirst].z, target.y, target.z)

	return {distancefirst, point_idfirst, angle_h, angle_v}
end

-- less accurate approximation
-- libWay.approxDistToTarget(pathway, target)
libWay.approxDistToTarget = function(pathway, target)
	local table = libWay.closestPathToTarget(pathway, target)
	if not table[2] then return 0 end
	
	local nexttopath, prev = Path_CheckPositionInWaypoints(table[2], pathway.timeline)
	local pointdist = R_PointToDist2(pathway[table[2]].x, pathway[table[2]].y, pathway[nexttopath].x, pathway[nexttopath].y)

	local duration = pathway[table[2]].spawnpoint.args[3]*TICRATE*FRACUNIT
	local starttime = pathway[table[2]].starttics
	
	local pyth = FixedMul(table[1], FixedMul(cos(table[3]), sin(table[4]))) 
	
	return starttime+FixedMul(FixedDiv(pyth, pointdist), duration)/FRACUNIT
end

libWay.calAvgSpeed = function(container, path, way)
	local nextway = Path_CheckPositionInWaypoints(way, container[path].timeline)
	local distance = P_AproxDistance(P_AproxDistance(
		container[path][way].x - container[path][nextway].x, 
		container[path][way].y - container[path][nextway].y),
		container[path][way].z - container[path][nextway].z
	)
	return (distance / (container[path][way].spawnpoint.args[3]*TICRATE) or 0)
end

libWay.deactive = function(target, controller, container)
	target.flags = target.tbswaypoint.flags
	target.flags2 = target.tbswaypoint.flags2
	target.tbswaypoint = nil

	if controller and (controller.spawnpoint.args[3] or controller.wayflags) then
		local flags = controller.spawnpoint.args[3] or controller.wayflags
		if flags & CC_MOMENTUMEND then
			libWay.calAvgSpeed(container, target.tbswaypoint.id, target.tbswaypoint.pos)
		end
	end
end

local function WaypointSetup(a, mt)
	if not (Waypoints[mt.args[0]]) then
		Waypoints[mt.args[0]] = {}
		Waypoints[mt.args[0]].timeline = {}
	end
	
	if not Waypoints[mt.args[0]][mt.args[1]] then
		table.insert(Waypoints[mt.args[0]].timeline, mt.args[1])
		table.sort(Waypoints[mt.args[0]].timeline, function(a, b) return a < b end)
	
		Waypoints[mt.args[0]][mt.args[1]] = {starttics = 0; x = mt.x*FRACUNIT; y = mt.y*FRACUNIT; z = a.z; 
		angle = mt.angle*ANG1; roll = mt.roll*ANG1; pitch = mt.pitch*ANG1;
		spawnpoint = {args = mt.args; stringargs = mt.stringargs}}
		
		Waypoints[mt.args[0]].tics = 0
		for k,v in ipairs(Waypoints[mt.args[0]]) do
			if k <= mt.args[1] then
				Waypoints[mt.args[0]][mt.args[1]].starttics = $+Waypoints[mt.args[0]][k].spawnpoint.args[3]*TICRATE
			end
			Waypoints[mt.args[0]].tics = $+Waypoints[mt.args[0]][k].spawnpoint.args[3]*TICRATE
		end
	end

	P_RemoveMobj(a)
end

local function MapThingCheck(a, mt)
	if not (TaggedObj[mt.tag]) then
		TaggedObj[mt.tag] = {}
	end
	table.insert(TaggedObj[mt.tag], a)
end

//
//	Controller
//	mobj.spawnpoint.args[0] -- ID
//	mobj.spawnpoint.args[1]	-- Position
//	mobj.spawnpoint.args[2]	-- Movement Type -> {0 = Linear Movement, 1 = Averaging Track to Target}
//	mobj.spawnpoint.args[3] -- Flags CC_*
//	mobj.spawnpoint.tag 	-- Used for tagging object to path and activation
//



local function ControllerThinker(mobj)
	if not (mobj.spawnpoint or TaggedObj[mobj.spawnpoint.tag]) then return end
	for _,a in ipairs(TaggedObj[mobj.spawnpoint.tag]) do
				
		//
		//	GENERAL
		//
		
		if not (a.tbswaypoint) then
			libWay.activate(mobj, a, mobj.spawnpoint.args[0], mobj.spawnpoint.args[1])
		end
			
		//
		//	PROGRESSION
		//
		
		local flipObj = false
		
		if (mobj.spawnpoint.args[3] & CC_APPRXTARGET) and a.target then
			local targetprogress = libWay.approxDistToTarget(Waypoints[a.tbswaypoint.id], a.target)
			if targetprogress > a.tbswaypoint.progress then
				a.tbswaypoint.flip = false
				a.tbswaypoint.progress = $+1
			elseif targetprogress < a.tbswaypoint.progress then
				a.tbswaypoint.flip = true				
				a.tbswaypoint.progress = $-1
			end
		else
			if not (mobj.spawnpoint.args[3] & CC_REVERSEMOVE) then
				a.tbswaypoint.flip = false				
				a.tbswaypoint.progress = $+1
			else
				a.tbswaypoint.flip = true
				a.tbswaypoint.progress = $-1
			end
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
		libWay.pathingFixedMove(a, controller, progress, waypointinfo, waypointobj, nextwaypoint)

		//	Action
		if waypointinfo.args[7] > 0 and waypointinfo.args[7] <= #NumToStringAction then
			StringtoFunctionA[NumToStringAction[waypointinfo.args[7]]](a, var1, var2)
		end
		
		//
		//	PLAYER
		//
		
		if a.p and waypointinfo.stringargs[0] ~= "" and a.state ~= waypointinfo.stringargs[0] then
			a.state = waypointinfo.stringargs[0]
		end
		
		//
		//	DEBUG MODE
		//
	
		if TBSHudObjExt and debug == 2 then
			TBSHudObjExt.addObjToList(a, a.tbswaypoint)
		end		
		
		//
		//	SPECIAL CASES
		//
		
		if waypointinfo.args[6] & WC_DOWNMOBJ then
			libWay.deactive(a, mobj, Waypoints)
			table.remove(TaggedObj, mobj.spawnpoint.tag)
		end
	end
end



local function CameraControllerThinker(mobj)
	//
	//	GENERAL
	//
		
	if not (TBS_CamWayVars.active) then
		local WPdummy = Waypoints[mobj.spawnpoint.args[0]]
		TBS_CamWayVars = {
			active = true;
			id = mobj.spawnpoint.args[0];
			pos = mobj.spawnpoint.args[1];
			progress = WPdummy[mobj.spawnpoint.args[1]].starttics;
		}
		TBS_CamWayVars.nextway, TBS_CamWayVars.prevway = Path_CheckPositionInWaypoints(TBS_CamWayVars.pos, Waypoints[TBS_CamWayVars.id].timeline)
	end
			
	//
	//	PROGRESSION
	//
		
	if not (mobj.spawnpoint.args[3] & CC_REVERSEMOVE) then
		TBS_CamWayVars.progress = $+1
	else
		TBS_CamWayVars.progress = $-1
	end

	local waypointobj = Waypoints[TBS_CamWayVars.id][TBS_CamWayVars.pos]
	local waypointinfo = Waypoints[TBS_CamWayVars.id][TBS_CamWayVars.pos].spawnpoint
	local progress = ((TBS_CamWayVars.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)		
		
	if progress == 0 or progress == FRACUNIT then
		Path_IfNextPoint(TBS_CamWayVars, progress)
		TBS_CamWayVars.nextway, TBS_CamWayVars.prevway = Path_CheckPositionInWaypoints(TBS_CamWayVars.pos, Waypoints[TBS_CamWayVars.id].timeline)			
	end

	
	//
	//	POSITION
	//		

	waypointobj = Waypoints[TBS_CamWayVars.id][TBS_CamWayVars.pos]	
	waypointinfo = Waypoints[TBS_CamWayVars.id][TBS_CamWayVars.pos].spawnpoint
	progress = ((TBS_CamWayVars.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)	
	
	local nextwaypoint = Waypoints[TBS_CamWayVars.id][TBS_CamWayVars.nextway]
	local x = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.x/FRACUNIT, nextwaypoint.x/FRACUNIT)
	local y = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.y/FRACUNIT, nextwaypoint.y/FRACUNIT)
	local z = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.z/FRACUNIT, nextwaypoint.z/FRACUNIT)

	
	camera.angle = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.angle, nextwaypoint.angle)
	P_TeleportCameraMove(camera, x*FRACUNIT, y*FRACUNIT, z*FRACUNIT)

	//	Action
	if waypointinfo.args[7] > 0 and waypointinfo.args[7] <= #NumToStringAction then
		StringtoFunctionA[NumToStringAction[waypointinfo.args[7]]](camera, var1, var2)
	end
		

	//
	//	SPECIAL CASES
	//
		
	if nextwaypoint.spawnpoint.args[6] & WC_DOWNMOBJ and progress == (FRACUNIT-1) then
		TBS_CamWayVars.active = false
	end
end



//
//	PLAYER SET UP
//

addHook("KeyDown", function(key)
	if consoleplayer and consoleplayer.taggedtowaypoint then
		return true
	end
end)


rawset(_G, "TBSWaylib", libWay)
addHook("MapThingSpawn", MapThingCheck)
addHook("MapThingSpawn", WaypointSetup, MT_GENERALWAYPOINT)

addHook("MobjThinker", ControllerThinker, MT_PATHWAYCONTROLLER)