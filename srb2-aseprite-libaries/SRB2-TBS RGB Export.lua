--   Tag export SRB2

local filepath = "C:/Users/davee/AppData/Roaming/Aseprite/scripts/texttable.txt"
local rangeType = app.range.type
local numFrames = app.range.frames

local function export_table(image)
    local color_table_string = "local img = { \n"
    local width = image.width-1
    local height = image.height-1

    for y = 0, height do
        color_table_string = color_table_string.." {"
        for x = 0, width do
            local color = Color{index=image:getPixel(x, y)}
            color_table_string = color_table_string.."{red = "..(color.red)..", green = "..(color.green)..", blue ="..(color.blue).."}, "
        end
        color_table_string = color_table_string.."}, \n"
    end

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
