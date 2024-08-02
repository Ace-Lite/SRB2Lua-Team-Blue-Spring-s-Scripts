
local function export_array_of_ASCII()
    local sprite = app.sprite
    local copy = Sprite(sprite)
    local copybounds = sprite.bounds
    copy:flatten()

    local path = sprite.filename
    local filelesspath = path:match("(.*[/\\])")
    
    local extensionlesspath = path:match("(.+)%..+")
    local filename = extensionlesspath:match("([^/\\]+)$")

    for i = 1,#copy.cels do
        local cel = copy.cels[i]
        local image = cel.image

        if copy.tags[i] and not image:isEmpty() then
            local bounds = image.bounds
            local editedimage = Image(image, Rectangle{width = bounds.width, height = copybounds.height, x = bounds.x, y = copybounds.y})
            editedimage:saveAs(tostring(filelesspath)..'\\'..tostring(filename)..'\\'..tostring(filename)..tostring(cel.frameNumber)..'.png')
        end
    end

    copy:close()
end

export_array_of_ASCII()