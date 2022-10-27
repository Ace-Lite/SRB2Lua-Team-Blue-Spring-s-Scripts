--   Tag export SRB2

local rangeType = app.range.type
local numFrames = app.range.frames
local activeTag = app.activeTag.name

local function exportFrames()
    for k,n in ipairs(numFrames) do
        image:drawSprite(sprite, n)
        filename = string.match(sprite.filename, "(.+)%..+")    
        if #numFrames > 0 and rangeType == RangeType.FRAMES then
                image:saveAs(filename..activeTag.."A0"..".png")
            end
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
