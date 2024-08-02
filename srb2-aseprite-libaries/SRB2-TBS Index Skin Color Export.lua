--   Tag export SRB2

local filepath = "C:/Users/davee/AppData/Roaming/Aseprite/scripts/skincolortable.txt"
local rangeType = app.range.type
local numFrames = app.range.frames

local function export_table(image)
    local color_table_string = "skincolors[SKINCOLOR_EXPORT] = { \n    ramp = {"
    local height = image.height-1
    
    for y = 0, height do
        color_table_string = color_table_string..image:getPixel(0, y)..", "
    end
    color_table_string = color_table_string.."}, \n    accesible = false, \n"    

    local file = io.open(filepath, "w")
    if file then
        file:write(color_table_string.."}")
        file:close()
    end
end

sprite = app.activeSprite
if sprite == nil then
    print("Error, no sprite active")
    return
end
image = Image(sprite)
export_table(image)
