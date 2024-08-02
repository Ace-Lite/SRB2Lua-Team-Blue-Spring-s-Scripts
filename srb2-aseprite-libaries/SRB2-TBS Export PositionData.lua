--   Tag export SRB2

local filepath = "C:/Users/davee/AppData/Roaming/Aseprite/scripts/hudinfo.txt"
local filepathsprites = "C:/Users/davee/AppData/Roaming/Aseprite/scripts/hudinfosprites/"

local function export_hudinfotable()
    local hudinfodata = "addHook(\"HUD\", function() \n \n \n"
    local sprite = app.sprite
    
    for _,cel in ipairs(sprite.cels) do
        local name = cel.layer.name  
        if name ~= 'base' or name ~= 'bg' or name ~= 'background' then    
            local frame = cel.frameNumber
            
            if frame == 1 then
                local position = cel.position
                local userdata = cel.layer.data ~= '' and cel.layer.data or '0'
                hudinfodata = hudinfodata..'--'..name..'\n v.draw('..tostring(position.x)..', '..tostring(position.y)..', sprite, '..tostring(userdata)..')\n \n'
                cel.image:saveAs(filepathsprites..name..'.png')
            end
        end
    end

    local file = io.open(filepath, "w")
    if file then
        file:write(hudinfodata..'end, \"game\")')
        file:close()
        os.execute('start '..filepath)
    end
end

export_hudinfotable()
