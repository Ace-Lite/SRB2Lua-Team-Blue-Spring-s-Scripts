local function export_based_on_tags()
    local sprite = app.sprite

    local path = sprite.filename
    local filelesspath = path:match("(.*[/\\])")
    
    local extensionlesspath = path:match("(.+)%..+")
    local filename = extensionlesspath:match("([^/\\]+)$")

    local temp_sprite = Sprite(sprite)
    temp_sprite:flatten()

    for _,tag in ipairs(temp_sprite.tags) do
        local first = tag.fromFrame.frameNumber
        local cel = temp_sprite.cels[first].image
        cel:saveAs(filelesspath..'\\'..tostring(tag.name)..'.png')
    end

    temp_sprite:close()
end

export_based_on_tags()