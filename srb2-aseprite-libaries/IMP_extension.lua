/*

    This is lua written extension for byte based imagery format of DOOM. 
    Made around bases of Aseprite APNG / Aniamted PNG made by kettek
    -- None code was used directly, it was just purely referenced.
    > To-do: Getting bytes stored 
    > To-do: Sort them and distinct them
    > To-do: Palette(colors)
    > To-do: Save, Load IMPs
    
*/
local Binary = {}

local Palette = {











}

Binary.convert = function(str)
    if not str then return end

    local transparency = 0xFF
    
    -- getting base info
    Binary.width = str:byte(0, 0)
    Binary.height = str:byte(2, 2)
    Binary.xoffset = str:byte(4, 4)
    Binary.yoffset = str:byte(6, 6)

    Binary.nfield = str:byte(8, 8)
    



end

Binary.save = function(str)
    if not str then return end



end

Binary.load = function(str)
    if not str then return end



end
