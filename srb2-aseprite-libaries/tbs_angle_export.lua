--   Tag export SRB2

local rangeType = app.range.type
local numFrames = app.range.frames
local activeTag = app.activeTag.name
local fname = {
    sixte = {"1", "9", "2", "A", "3", "B", "4", "C", "5", "D", "6", "E", "7", "F", "8", "G"},    
    eight = {"1", "2", "3", "4", "5", "6", "7", "8"},
    two = {"L", "R"}
}

local function exportFrames()
    for k,n in ipairs(numFrames) do
        image:drawSprite(sprite, n)
        filename = string.match(sprite.filename, "(.+)%..+")    
        if #numFrames > 0 and rangeType == RangeType.FRAMES then
            if #numFrames == 16 then
                image:saveAs(filename..activeTag..fname.sixte[k]..".png")            
            elseif #numFrames == 8 then
                image:saveAs(filename..activeTag..fname.eight[k]..".png")
            elseif #numFrames == 5 then
                if k > 1 and k < 5 then
                    image:saveAs(filename..activeTag..fname.eight[k]..activeTag..fname.eight[10-k]..".png")
                else
                    image:saveAs(filename..activeTag..fname.eight[k]..".png")
                end
            elseif #numFrames == 2 then
                image:saveAs(filename..activeTag..fname.two[k]..".png")
            elseif #numFrames == 1 then
                image:saveAs(filename..activeTag.."0"..".png")
            else
                print("To do this action you need 1, 2, 5 or 8 amount of frames in selected Range")
                return
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
