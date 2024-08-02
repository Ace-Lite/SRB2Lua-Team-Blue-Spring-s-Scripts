
local function create_array_of_ASCII()
    local sprite = app.sprite

    for i = 2, 128 do
        local frame = sprite:newFrame(i)
        local tag = sprite:newTag(i, i)
        tag.name = string.char(i)
    end
end

create_array_of_ASCII()