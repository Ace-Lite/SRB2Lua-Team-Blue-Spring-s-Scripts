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
//	-- Special Map triggers (Would be funny if it was used for cutscenes... haha totally unrealistic... right?)
//	-- Split controller code segments for reuse. For code size optimalization + Camera work
//	-- Optimalize code somehow... for example reduce amount of calculations done in teleporting
//	-- Fix Hitbox update
//	-- Figure out path-target approximation (2D kind and 3D kind and special camera kind)
//	-- Flag - approximate momentum after pathing ends (rockets etc.)
//	-- Entrance point approximation (Camera will need it for etrance state)
//	-- Player Anim speed calculation
//	-- Looping types
//

//
//	PKZ Todo:
//	-- Waterpool for PKZ2 (let player have some movement)
//		-- Allow "2D" movement while in the state
//		-- They going to use specialized controllers
//		-- Repeatable
//		-- Spawn bunch of particles...
//	-- Cutscenes
//		-- PKZ2-PKZ3 transition
//		-- Credits
//  -- Dino Skeleton Trains (PKZ 1-4)
//		-- Hangable from buttom ( :earless: shortcut for AIZ's hanging shit )
//		-- Control pathing of segments by simply teleporting them with "delayed" coordinates
//		-- Oh activated on use
//		-- Respawn
//		-- Multiplayer

local Waypoints = {}
local TaggedObj = {}

addHook("MapChange", function()
	Waypoints = {}
	TaggedObj = {}
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

//
//	ACTION THINKERS
//

local NumToStringAction = {
	"WAY_FORCESTOP", 
	"WAY_CHANGESCALE", 
	"WAY_YAWCAMERA",
	"WAY_CHANTRACK",
	"WAY_JUMPTRACK",	
	"WAY_CHANGROLL", 
	"WAY_TRIGGERTAG";
}

local StringtoFunctionA = { 
	//Stop movement for specific amount of time
	//var1 - stops the train for amount of time	
	["WAY_FORCESTOP"] = function(a, var1, var2) 
		if a.tbswaypoint.progress == 1 and not a.tbswaypoint.pause then
			a.tbswaypoint.pause = var1
		end
		if a.tbswaypoint.pause > 1 then
			a.tbswaypoint.progress = 1
		end
		if a.tbswaypoint.pause == 1 then
			a.tbswaypoint.progress = 2	
		end
	end;
	
	//Change object scale
	//var1 - amount of time to ease
	//var2 - target scale 
	["WAY_CHANGESCALE"] = function(a, var1, var2) 
		--a.scale = ease.linear(t, s, var2)
	end;
	
	//Change yaw of the camera (camera pathway only)
	//var1 - amount of time to ease
	//var2 - target yawcamera	
	["WAY_YAWCAMERA"] = function(a, var1, var2) 
	
	
	
	end;
	
	//Target Different Track
	//var1 - target track ID
	//var2 - target pathway ID
	["WAY_CHANTRACK"] = function(a, var1, var2) 
	
	
	
	end;
	
	//Jump Different Track
	//var1 - target track ID
	//var2 - target pathway ID
	["WAY_JUMPTRACK"] = function(a, var1, var2) 
	
	
	
	end;
	
	//Changes rollangle.
	//var1 - amount of time to ease
	//var2 - target rollangle
	["WAY_CHANGROLL"] = function(a, var1, var2) 
	
	
	
	end;
		
	//Triggers anything using this tag
	//var1 - tag
	["WAY_TRIGGERTAG"] = function(a, var1, var2) 
	
	
	
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

local function ControllerThinker(mobj)
	if not (mobj.spawnpoint or TaggedObj[mobj.spawnpoint.tag]) then return end
	for _,a in ipairs(TaggedObj[mobj.spawnpoint.tag]) do
		

		
		//
		//	GENERAL
		//
		
		if not (a.tbswaypoint) then
			local WPdummy = Waypoints[mobj.spawnpoint.args[0]]
			a.tbswaypoint = {
				id = mobj.spawnpoint.args[0];
				pos = mobj.spawnpoint.args[1];
				progress = WPdummy[mobj.spawnpoint.args[1]].starttics;
			}
			a.tbswaypoint.nextway, a.tbswaypoint.prevway = Path_CheckPositionInWaypoints(a.tbswaypoint.pos, Waypoints[a.tbswaypoint.id].timeline)
		end
			
		//
		//	PROGRESSION
		//
		
		if not (mobj.spawnpoint.args[3] & CC_REVERSEMOVE) then
			a.tbswaypoint.progress = $+1
		else
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
		progress = ((a.tbswaypoint.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)	
	
		local nextwaypoint = Waypoints[a.tbswaypoint.id][a.tbswaypoint.nextway]
		local x = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.x/FRACUNIT, nextwaypoint.x/FRACUNIT)
		local y = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.y/FRACUNIT, nextwaypoint.y/FRACUNIT)
		local z = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.z/FRACUNIT, nextwaypoint.z/FRACUNIT)

	
		a.angle = SwitchEasing[waypointinfo.args[2]](progress, waypointobj.angle, nextwaypoint.angle)
		P_TeleportMove(a, x*FRACUNIT, y*FRACUNIT, z*FRACUNIT)

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
		//	SPECIAL CASES
		//
		
		if waypointinfo.args[6] & WC_DOWNMOBJ then
			table.remove(TaggedObj, mobj.spawnpoint.tag)
			P_RemoveMobj(mobj)
		end
		
	end
end

local cameratbswp = {
	active = false;
	id = 0;
	pos = 0;
	progress = 0;
	nextway = 0;
	prevway = 0;
}


local function CameraControllerThinker(mobj)
	//
	//	GENERAL
	//
		
	if not (cameratbswp.active) then
		local WPdummy = Waypoints[mobj.spawnpoint.args[0]]
		cameratbswp = {
			active = true;
			id = mobj.spawnpoint.args[0];
			pos = mobj.spawnpoint.args[1];
			progress = WPdummy[mobj.spawnpoint.args[1]].starttics;
		}
		cameratbswp.nextway, cameratbswp.prevway = Path_CheckPositionInWaypoints(cameratbswp.pos, Waypoints[cameratbswp.id].timeline)
	end
			
	//
	//	PROGRESSION
	//
		
	if not (mobj.spawnpoint.args[3] & CC_REVERSEMOVE) then
		cameratbswp.progress = $+1
	else
		cameratbswp.progress = $-1
	end

	local waypointobj = Waypoints[cameratbswp.id][cameratbswp.pos]
	local waypointinfo = Waypoints[cameratbswp.id][cameratbswp.pos].spawnpoint
	local progress = ((cameratbswp.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)		
		
	if progress == 0 or progress == FRACUNIT then
		Path_IfNextPoint(cameratbswp, progress)
		cameratbswp.nextway, cameratbswp.prevway = Path_CheckPositionInWaypoints(cameratbswp.pos, Waypoints[cameratbswp.id].timeline)			
	end

	
	//
	//	POSITION
	//		

	waypointobj = Waypoints[cameratbswp.id][cameratbswp.pos]	
	waypointinfo = Waypoints[cameratbswp.id][cameratbswp.pos].spawnpoint
	progress = ((cameratbswp.progress-waypointobj.starttics)*FRACUNIT)/(waypointinfo.args[3]*TICRATE)	
	
	local nextwaypoint = Waypoints[cameratbswp.id][cameratbswp.nextway]
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
		cameratbswp.active = false
		P_RemoveMobj(mobj)
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