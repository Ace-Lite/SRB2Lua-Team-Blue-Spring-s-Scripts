--   Tag export SRB2

local rangeType = app.range.type
local numFrames = app.range.frames
local activeTag = app.activeTag.name
local tableFrame = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", 
"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", 
"Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", 
"c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", 
"q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "!", "@"}

local function exportFrames()
    for k,n in ipairs(numFrames) do
        image:drawSprite(sprite, n)
        filename = string.match(sprite.filename, "(.+)%..+")    
        if #numFrames > 0 and rangeType == RangeType.FRAMES then
                image:saveAs(filename..activeTag..tableFrame[k].."0"..".png")
        else 
            print("Error: Invalid")
        end
    end
end

sprite = app.activeSprite
if sprite == nil then
    print("Error, no sprite active")
    return
end
image = Image(sprite)
exportFrames()
