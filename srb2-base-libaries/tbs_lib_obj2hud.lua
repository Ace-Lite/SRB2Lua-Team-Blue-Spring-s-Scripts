local registered_objects = {}

local TBSHudObjExt = {
	stringversion = '0.1',
	iteration = 1,
}

TBSHudObjExt.addObjToList = function(obj, list)
    local settings = {
        x = obj.x,
        y = obj.y,
        z = obj.z,
        radius = obj.radius,
        height = obj.height,        
    }

	settings.values = list
    table.insert(registered_objects, settings)
end



hud.add(function(v, stplyr, cam)
    for k,obj in ipairs(registered_objects) do
		local angle = R_PointToAngle(obj.x, obj.y)
        if not (cam.angle-ANGLE_90 < angle and cam.angle+ANGLE_90 > angle) then continue end


		local realangle = 320*sin(cam.angle - angle)/FRACUNIT
		local dx = (obj.x-cam.x)
		
		local z = 4*FixedMul((obj.y-cam.y), tan(angle/2))
		local x = 160+dx/z+realangle
		local y = 100-(obj.z-cam.z)/z+200*sin(cam.aiming)/FRACUNIT
        local height, radius = obj.height/z, obj.radius/z

        v.drawFill(x-radius, y, radius*2, 1, 10)
        v.drawFill(x-radius, y-height, radius*2, 1, 10)
        v.drawFill(x-radius, y-height, 1, height, 10)
        v.drawFill(x+radius, y-height, 1, height, 10)

        if obj.values then
            for k,val in ipairs(obj.values) do
                v.drawString(x, y, val)
                y = $+8
            end
        end
    end
    registered_objects = {}
end, "game")

rawset(_G, "TBSHudObjExt", TBSHudObjExt)