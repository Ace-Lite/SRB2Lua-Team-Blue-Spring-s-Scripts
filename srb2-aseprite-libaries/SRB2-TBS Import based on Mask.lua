
-- Not our function
local function getFilePaths(folderPath)
    local filePaths = {}
    local cmd = io.popen('dir /B /S "' .. folderPath .. '"')
    local output = cmd:read('*all')
    cmd:close()

    for filePath in string.gmatch(output, "[^\r\n]+") do
        table.insert(filePaths, filePath)
    end

    return filePaths
end

local function import_layers_based_on_mask()
    local sprite = app.sprite

    local path = sprite.filename
    local filelesspath = path:match("(.*[/\\])")
    
    local extensionlesspath = path:match("(.+)%..+")
    local filename = extensionlesspath:match("([^/\\]+)$")

    --print(path)
    --print(extensionlesspath)
    local folder = getFilePaths(extensionlesspath)

    --print(tostring(folder ~= nil))

    local selected_layer
    local found_mask = false
    for i = 1, #sprite.layers do
        selected_layer = sprite.layers[i]
        if selected_layer.name == "mask" then
            found_mask = true
            break
        end
    end

    --print(tostring(found_mask))   

    if found_mask then
        local work_layer = sprite:newLayer()
        local position = selected_layer:cel(1).position
        --print(tostring('hixd'))
        if folder then
            for k,v in ipairs(folder) do
                --print(tostring(k))
                local extension = v:match("^.+%.(%w+)$")
                if extension == "png" then
                    --print(v)
                    local frame = sprite:newFrame(k + 1)                    
                    local tag = sprite:newTag(k + 1, k + 1)
                    local new_img = Image{fromFile = v}
                    local cel_img = sprite:newCel(work_layer, frame, new_img, position)
                    local name = v:match("([^/\\]+)$")
                    tag.name = name:match("(.+)%..+")
                end
            end
        else
            print("Problem")
        end
    end

end

import_layers_based_on_mask()