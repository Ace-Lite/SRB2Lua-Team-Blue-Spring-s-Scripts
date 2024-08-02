--   Tag export SRB2

local filepath = "C:/Users/davee/AppData/Roaming/Aseprite/scripts/skincolortable.txt"
local rangeType = app.range.type
local frames = app.range.frames

local function export_table(input_sprite)
    local color_table_string
    for i,cel in ipairs(input_sprite.cels) do
        local image = cel.image
        local height = Image(sprite).height-1

        color_table_string = color_table_string and (color_table_string.."{") or "{"
        for y = 0, height do
            color_table_string = color_table_string..image:getPixel(0, y)..", "
        end
        color_table_string = color_table_string.."}, \n"    
    end

    local file = io.open(filepath, "w")
    if file then
        file:write(color_table_string)
        file:close()
    end
end

sprite = app.activeSprite

if sprite == nil then
    print("Error, no active sprite")
    return
end


export_table(sprite)
