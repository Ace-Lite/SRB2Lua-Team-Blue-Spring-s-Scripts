//
// Team Blue Spring's Series of Libaries. 
// Lua Extensions
//

rawset(_G, "TBS_LUAEXT", {
	-- version control
	major_iteration = 1, -- versions with extensive changes. 	
	iteration = 1, -- additions, fixes. No variable changes.
	version = "DEV", -- just a string...

	classes = {}
})

//
// Classes
//

TBS_LUAEXT.registerClass = function(class)
	table.insert(TBS_LUAEXT.classes, class)
end

//
// Objects
//

TBS_LUAEXT.new = function(class, additions)
	local object = {}
	
	for k,v in ipairs(class) do
		object:insert(v, k)
	end
	
	for k,v in ipairs(additions) do
		object:insert(v, k)
	end	
	
	return object
end


//
// String
//

TBS_LUAEXT.bytedec = function(str)
	str:format("%x")
end

TBS_LUAEXT.trim = function(str, split)

end





