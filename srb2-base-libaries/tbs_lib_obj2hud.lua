local registered_objects = {}

local libOBJHUDEXT = {
	stringversion = '0.1',
	iteration = 1,
}

TBSHudObjExt.addObjToList = function(obj, values)
    local settings = {
        values = values;
        x = obj.x,
        y = obj.y,
        z = obj.z,
        radius = obj.radius,
        height = obj.height,        
    }

    registered_objects:insert(settings)
end


hud.add(function(v, stplyr, cam)
    for k,v in ipairs(registered_objects) do
        local angle = R_PointToAngle(v.x, v.y)
        if not (cam.angle-ANGLE_90 < angle and cam.angle+ANGLE_90 > angle) then continue end

        local dist = R_PointToDist(v.x, v.y)/90
        local x, y = 160+(cam.x-v.x)/dist, 100+(cam.z-v.z)/dist
        local height, radius = v.height/dist, v.radius/dist

        v.drawfill(x, y, radius, 1, 10)
        v.drawfill(x, y+height, radius, 1, 10)
        v.drawfill(x-radius, y+height, 1, height, 10)
        v.drawfill(x+radius, y+height, 1, height, 10)

        if v.values then
            for k,val in ipairs(v.values) do
                v.drawString(x, y, k+": "+val)
                y = $+5
            end
        end
    end
    registered_objects = {}
end, "game")

rawset(_G, "TBSHudObjExt", libOBJHUDEXT)