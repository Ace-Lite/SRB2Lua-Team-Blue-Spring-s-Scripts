//
// Team Blue Spring's Series of Libaries. 
// Menu Framework
//


//
//	MENU VARIABLES
//
rawset(_G, "TBS_Menu", {
	//	global table for menus in TBS framework

	-- version control
	major_iteration = 1, -- versions with extensive changes. 	
	iteration = 1, -- additions, fixes. No variable changes.
	version = "DEV", -- just a string...
	
	-- toggle for menu
	enabled_Menu = 0,

	-- menuitems (containers for menu info)
	menutypes = {},

	-- style variables per menu, includes: 
	-- limiters of space display in Y for each menu object
	-- limitz = {start of menu contains - y1, end of menu contains - y2, space between y1-y2} >> eachitem
	-- optional usage, but required for smooth scrolling within default keydown hook behavior
	styles = {},
	
	-- smoothing between scrolling.
	smoothing = 0,

	// selection
	-- to move these please, refer to pre-built functions
	menu = 1, -- menu object
	submenu = 1, -- submenu within menu object
	selection = 1, -- selection of menu item in submenu structure
	prev_sel = 1,  -- previous selection of menu item
		
	-- input detector
	-- whenever you wanted that kind of thing ig.
	pressbt = 0,
	caps = false,
	capslock = false,

	-- simple boolean to skip checking.
	edgescr = false,

	-- mouse variables
	mouse_visible = false,
	mouse_sensitivity = 0,
	mouse_delayclick = 0,
	angle_lock = 0,
	mouse_x = 0,
	mouse_y = 0,
	
	-- in combination with confirmed variable, pop-ups are for extra menus appearing in for example: 	
	-- uhhh inputs? can be text or literal kind
	input_buffer = "",
	
	-- in combination with confirmed variable, pop-ups are for extra menus appearing in for example: 
	-- confirmation whenever or not you want delete your entire progress of hard earned coins?
	popup_type = "none",
	popup_message = {},
	
	-- stops menu control. Makes you click double to either confirm your choice or not.
	-- should really be used with popup or input.
	confirmed = 0,
})

rawset(_G, "TBS_MENUCONFIG", {
	-- MENU TRIGGER
	open_key1 = "h",
	open_key2 = "h",
	
	close_key1 = "escape",
	close_key2 = "escape",
	-- >> REST
})

//
//	Current_Menu[TBS_Menu.selection].flags
//

rawset(_G, "TBS_MENUTRG", {
	-- CONTROLLER / KEYBOARD
	LEFT_BUMPER = 1,
	RIGHT_BUMPER = 2,
	CONFIRM = 4,
	ESCAPE = 8,
	UP = 16,
	DOWN = 32,
	LEFT = 64,
	RIGHT = 128,
})

--TBS_MFLAG
rawset(_G, "TBS_MFLAG", {
	-- SKIP OVER MENU ITEM FLAG
	NOTOUCH = 1;
	
	-- DEFAULT MENU Current_Menu[TBS_Menu.selection].flags
	TEXTONLY = 2;
	HEADER = 4;
	SPLIT = 8;
	
	-- CVARS (off-on and slider require cvar flag)
	CVAR = 16;	
	OFFON = 32;
	SLIDER = 64;
	
	-- INPUT
	INPUT = 128;
	INPUTTEXT = 256;	
	
	-- MISC.
	SPECIALDRAW = 512;
})


//
//	MENU FUNCTIONS
//

TBS_Menu.toggleMenu = function(self, toggle)
	if toggle then
		self.enabled_Menu = 1
		if consoleplayer and consoleplayer.mo then 
			self.angle_lock = consoleplayer.mo.angle
		end
	else
		self.enabled_Menu = 0
		self.confirmed = 0
	end	
end


-- 
--	TBS_Menu:check_MouseOver(mx1, my1, mx2, my2) 
TBS_Menu.check_MouseOver = function(self, mx1, my1, mx2, my2)
	TBS_Menu.mouse_delayclick = TBS_Menu.mouse_delayclick > 0 and $-1 or 0
	if mx1 <= self.mouse_x and my1 <= self.mouse_y and 
	mx2 >= self.mouse_x and my2 >= self.mouse_y then 
		return true
	else
		return false
	end
end

--
--	TBS_Menu.draw_ClickableImage(v, x, y, scale, patch, flags, colormap)
TBS_Menu.draw_ClickableImage = function(v, x, y, scale, patch, flags, colormap)
	v.drawScaled(x, y, scale, patch, flags, colormap)
	local nx, ny = x/scale-patch.leftoffset, y/scale-patch.topoffset
	if TBS_Menu:check_MouseOver(nx, ny, nx+patch.width*(scale/FRACUNIT), ny+patch.height*(scale/FRACUNIT)) and mouse.buttons & MB_BUTTON1 and TBS_Menu.mouse_delayclick == 0 then
		TBS_Menu.mouse_delayclick = 30
		return true
	else
		return false
	end
end

--
--	TBS_Menu.draw_ClickableFill(v, x, y, width, height, color)
TBS_Menu.draw_ClickableFill = function(v, x, y, width, height, color)
	v.drawFill(x, y, width, height, color)
	if TBS_Menu:check_MouseOver(x, y, width, height) and mouse.buttons & MB_BUTTON1 and TBS_Menu.mouse_delayclick == 0 then
		TBS_Menu.mouse_delayclick = 30
		return true
	else
		return false
	end
end

-- 
--	TBS_Menu:check_MouseOverText(mx1, my1, string, font, allign) 
--TBS_Menu.check_MouseOverText = function(self, mx1, my1)
--	if mx1 < self.mouse_x and my1 < self.mouse_y 
--		and mx2 > self.mouse_x and my2 > self.mouse_y then 
--		return true
--	else
--		return false
--	end
--end
--

-- checks conditions
TBS_Menu.check_Condition = function(menutx)
	if menutx and menutx.condition then 
		return menutx.condition()
	else
		return nil
	end
end

local function P_IsMenuUntouchable(flags, condition)
	if (flags & TBS_MFLAG.HEADER or flags & TBS_MFLAG.NOTOUCH or flags & TBS_MFLAG.SPLIT) 
	or (condition ~= nil and condition == false) then
		return true
	else
		return false
	end
end

TBS_Menu.select_menu_structure = function(move)	
	if TBS_Menu.smoothing and abs(TBS_Menu.smoothing) then
		TBS_Menu.smoothing = 0
	end

	TBS_Menu.selection = 1
	TBS_Menu.submenu = 1	
	
	local xlen = TBS_Menu.menutypes
	
	if move then
		TBS_Menu.menu = (1 < TBS_Menu.menu and $-1 or #xlen)
	else
		TBS_Menu.menu = (#xlen > TBS_Menu.menu and $+1 or 1)		
	end
end


TBS_Menu.select_sub_menu_structure = function(submenux, menutab)
	local numsel = 1
	while (true) do
		local menutx = menutab[submenux][numsel]
		local flags = menutx.flags
		if not (P_IsMenuUntouchable(flags, TBS_Menu.check_Condition(menutx))) then
			break
		end
		numsel = $+1
	end
	
	if TBS_Menu.smoothing and abs(TBS_Menu.smoothing) then
		TBS_Menu.smoothing = 0
	end
	
	TBS_Menu.selection = numsel
	TBS_Menu.submenu = submenux
end

-- TBS_Menu:confirmButtom(sel)
TBS_Menu.confirmButtom = function(self, sel)
	local pick = self.menutypes[self.menu][self.submenu][sel]
	if (pick.flags & TBS_MFLAG.INPUT or pick.flags & TBS_MFLAG.INPUTTEXT) then
		TBS_Menu.confirmed = 1
		return true
	else
		pick.func(self.menutypes[self.menu])
		return true
	end
	return false
end


local function M_selectionItemMMM(move, itemcount, skip)
	if not skip then
		TBS_Menu.prev_sel = TBS_Menu.selection
	end

	if (move and 1 < TBS_Menu.selection) or (not move and itemcount > TBS_Menu.selection) then
		TBS_Menu.edgescr = false
	else
		TBS_Menu.edgescr = true
	end
	
	if move then
		TBS_Menu.selection = (1 < TBS_Menu.selection and $-1 or itemcount)
	else
		TBS_Menu.selection = (itemcount > TBS_Menu.selection and $+1 or 1)
	end
end

-- TBS_Menu:scrollMenuItems(move)
TBS_Menu.scrollMenuItems = function(self, move)
	local Current_Menu = self.menutypes[self.menu][self.submenu]
	M_selectionItemMMM(move, #Current_Menu)
								
	-- another in case of header
	while (P_IsMenuUntouchable(Current_Menu[self.selection].flags, self.check_Condition(Current_Menu[self.selection]))) do
		M_selectionItemMMM(move, #Current_Menu, true)		
	end

	if move then
		if not (self.edgescr or Current_Menu[#Current_Menu].z <= Current_Menu[self.selection].z+self.styles[self.menu].limitz[3] 
		or Current_Menu[#Current_Menu].z <= (self.styles[self.menu].limitz[2]+15)) then
			self.smoothing = abs(Current_Menu[self.selection].z - Current_Menu[self.prev_sel].z)/3
		end
	else
		if not (self.edgescr or Current_Menu[#Current_Menu].z <= Current_Menu[self.selection].z+self.styles[self.menu].limitz[3]
		or Current_Menu[#Current_Menu].z <= (self.styles[self.menu].limitz[2]+15)) then
			self.smoothing = -abs(Current_Menu[self.selection].z - Current_Menu[self.prev_sel].z)/3
		end
	end
end



local function M_selectionMenu(move)
	if move then
		TBS_Menu.select_menu_structure(true)			
		TBS_Menu.pressbt = $|TBS_MENUTRG.RIGHT_BUMPER
	else 
		TBS_Menu.select_menu_structure(false)
		TBS_Menu.pressbt = $|TBS_MENUTRG.LEFT_BUMPER	
	end
end

COM_AddCommand("tbs_menu", function(player, arg1)
	if gamestate & GS_LEVEL and not paused then
		CONS_Printf(player, "\x82".."Menu Activated")
		TBS_Menu.select_sub_menu_structure(1, tonumber(arg1) or TBS_Menu.menutypes[TBS_Menu.menu])
		TBS_Menu:toggleMenu(true)
	else
		CONS_Printf(player, "\x82".."Menu can only be activated in game.")
	end
end, COM_LOCAL)

local acceptable_inputs = {
	"q","w","e","r","t","z","u","i","o","p","a","s","d","f","g","h","j","k","l","y","x","c","v","b","n","m",
	
	",",".","-","'",":","?","!",
	
	"0","1","2","3","4","5","6","7","8","9"
}

local function P_iterateInputs(input)
	for _,v in ipairs(acceptable_inputs) do
		if input == v then
			return true
		end
	end
	
	return false
end


addHook("KeyUp", function(key)
	if (key.name == "lshift" or key.name == "rshift") and TBS_Menu.caps and not TBS_Menu.capslock then
		TBS_Menu.caps = false
	end
end)

addHook("KeyDown", function(key)
	--print(key.name)	
	
	if TBS_Menu.enabled_Menu == 1 then
		local Menu = TBS_Menu.menutypes[TBS_Menu.menu]
		local Current_Menu = Menu[TBS_Menu.submenu]
		
		if Current_Menu[TBS_Menu.selection].special_input then
			Current_Menu[TBS_Menu.selection].special_input(key)
			return true
		end

		if not TBS_Menu.confirmed then
			--
			-- CLOSE
			--		
			if key.name == TBS_MENUCONFIG.close_key1 or key.name == TBS_MENUCONFIG.close_key2 then
				TBS_Menu.select_sub_menu_structure(1, TBS_Menu.menutypes[TBS_Menu.menu])
				TBS_Menu:toggleMenu(false)
			end
		
			--
			-- SCROLL UP
			--
			if key.num == ctrl_inputs.up[1] or mouse.buttons & MB_SCROLLUP then
				TBS_Menu.mouse_visible = false
				TBS_Menu:scrollMenuItems(true)
			end


			--
			-- SCROLL DOWN
			--	
			if key.num == ctrl_inputs.down[1] or mouse.buttons & MB_SCROLLDOWN then
				TBS_Menu.mouse_visible = false
				TBS_Menu:scrollMenuItems(false)
			end


			--
			-- CONFIRM
			--
			if ((key.num == ctrl_inputs.jmp[1] or key.num == ctrl_inputs.spn[1]) and (Current_Menu[TBS_Menu.selection].func or Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUT or Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUTTEXT)) then
				TBS_Menu.mouse_visible = false
				TBS_Menu:confirmButtom(TBS_Menu.selection)
			end


			--
			-- CVAR ADD/SUB
			--		
			if Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.CVAR and Current_Menu[TBS_Menu.selection].cvar and not (Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUT or Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUTTEXT) then
				TBS_Menu.mouse_visible = false			
				if (key.num == ctrl_inputs.right[1] or key.num == ctrl_inputs.turr[1]) then
					CV_AddValue(Current_Menu[TBS_Menu.selection].cvar(), 1)
				end
		
				if (key.num == ctrl_inputs.left[1] or key.num == ctrl_inputs.turl[1]) then
					CV_AddValue(Current_Menu[TBS_Menu.selection].cvar(), -1)
				end
				
			end

			--
			-- SWITCH BETWEEN MENUS
			--		
			if key.name == "q" then
				TBS_Menu.mouse_visible = false			
				M_selectionMenu(false)
			end
			
			if key.name == "e" then
				TBS_Menu.mouse_visible = false			
				M_selectionMenu(true)
			end
		else
			-- confirmation state

			--
			-- INPUTS FOR TEXT EDITING / ENTERING INPUTS
			--
			if Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUT or Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUTTEXT then
				local inputs = TBS_Menu.input_buffer
				TBS_Menu.mouse_visible = false
				
				if (key.name == "enter") then
					-- Check whenever menu item is also cvar... nobody has to go through extra hassle.
					if Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.CVAR then
						CV_Set(Current_Menu[TBS_Menu.selection].cvar(), TBS_Menu.input_buffer) 						
					else
						Current_Menu[TBS_Menu.selection].func()
					end
					TBS_Menu.input_buffer = ""
					TBS_Menu.confirmed = 0		
					
				elseif (key.name == "escape") then
					-- GO BACK!!!			
					TBS_Menu.input_buffer = ""
					TBS_Menu.confirmed = 0
					
				elseif (key.name == "space") and Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUTTEXT and (not Current_Menu[TBS_Menu.selection].input_limit or (Current_Menu[TBS_Menu.selection].input_limit > #inputs)) then
					-- Jump..
					TBS_Menu.input_buffer = $+" "
					
				elseif (key.name == "lshift" or key.name == "rshift") and Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUTTEXT then
					-- Dear... upper case letters...
					TBS_Menu.caps = true
					
				elseif (key.name == "capslock") and Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUTTEXT then
					-- GUYS WE INVENTED CAPSLOCK
					TBS_Menu.capslock = (TBS_Menu.caps and false or true)
					TBS_Menu.caps = TBS_Menu.capslock
					
				elseif (key.name == "backspace") then
					-- delete this or else...				
					if Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUT then	
						TBS_Menu.input_buffer = ""
					elseif Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUTTEXT then
						TBS_Menu.input_buffer = string.sub(TBS_Menu.input_buffer, 1, -2)
					end
					
				else
					-- record inputs
					if Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUT then	
						TBS_Menu.input_buffer = key.name
					
					-- record letters
					elseif Current_Menu[TBS_Menu.selection].flags & TBS_MFLAG.INPUTTEXT then												
						if P_iterateInputs(key.name) and (not Current_Menu[TBS_Menu.selection].input_limit or (Current_Menu[TBS_Menu.selection].input_limit > #inputs)) then				
							TBS_Menu.input_buffer = $+(TBS_Menu.caps and string.upper(key.name) or key.name)
						end				
					end
					
				end
			else
				TBS_Menu.mouse_visible = false
				
				-- pop-up confirmation variant
				if (key.num == ctrl_inputs.jmp[1]) then
					Current_Menu[TBS_Menu.selection].func()
				elseif (key.num == ctrl_inputs.spn[1]) then
					TBS_Menu.popupmessage = {}
					TBS_Menu.confirmed = 0
				end			
			end
		end

		return true
	else
		--
		-- OPEN MENU
		--
		if key.name == TBS_MENUCONFIG.open_key1 or key.name == TBS_MENUCONFIG.open_key2 then
			TBS_Menu.select_sub_menu_structure(1, TBS_Menu.menutypes[TBS_Menu.menu])
			TBS_Menu:toggleMenu(true)
		end
	end
end)

addHook("PlayerThink", function(p)
	if TBS_Menu.enabled_Menu == 1 then
		p.mo.angle = TBS_Menu.angle_lock
	end
end)


hud.add(function(v, stplyr)	
	if TBS_Menu.enabled_Menu == 1 then
		TBS_Menu.mouse_x = min(max(TBS_Menu.mouse_x+mouse.dx/10, 0), v.width()/v.dupx())
		TBS_Menu.mouse_y = min(max(TBS_Menu.mouse_y+mouse.dy/10, 0), v.height()/v.dupy())
		
		if mouse.dx or mouse.dy then
			TBS_Menu.mouse_visible = true
		end
		
		TBS_Menu.menutypes[TBS_Menu.menu][TBS_Menu.submenu].style(v)

		local num_menus = TBS_Menu.menutypes
		
		if TBS_Menu.mouse_visible then
			v.drawFill(TBS_Menu.mouse_x, TBS_Menu.mouse_y, 4, 2, 1)
			v.drawFill(TBS_Menu.mouse_x, TBS_Menu.mouse_y+2, 2, 2, 1)		
		end
		
		if #num_menus < 1 then return end
		
		local menu_name = TBS_Menu.menutypes[TBS_Menu.menu].name
		local name_len = v.stringWidth(menu_name)/2
		
		local vibes = abs((leveltime/3 % 6)-3)
		local tbs = "_TBS_MENU"
		
		local left_key = v.cachePatch(tbs.."QP"..((TBS_Menu.pressbt & 1) and "R" or "S"))
		local right_key = v.cachePatch(tbs.."EP"..((TBS_Menu.pressbt & 2) and "R" or "S"))
		
		local left_arrow = v.cachePatch(tbs.."LA"..((TBS_Menu.pressbt & 1) and "R" or "S"))
		local right_arrow = v.cachePatch(tbs.."RA"..((TBS_Menu.pressbt & 2) and "R" or "S"))		
		
		TBS_Menu.pressbt = 0

		if TBS_Menu.draw_ClickableImage(v, (160-name_len)*FRACUNIT, 7*FRACUNIT, FRACUNIT, left_key, 0, v.getStringColormap(0x80)) then
			M_selectionMenu(false)
		end
		
		if TBS_Menu.draw_ClickableImage(v, (170+name_len)*FRACUNIT, 7*FRACUNIT, FRACUNIT, right_key, 0, v.getStringColormap(0x80)) then
			M_selectionMenu(true)
		end	
		
		--v.draw(160-name_len, 7, left_key, 0)
		--v.draw(170+name_len, 7, right_key, 0)

		-- arrow
		v.draw(160-name_len-left_key.width-vibes, 8+left_key.height/2, left_arrow, 0)
		v.draw(170+name_len+right_key.width+vibes, 8+right_key.height/2, right_arrow, 0)
		
		v.drawString(165, 9, menu_name, 0, "center")
	end	
end, "game")

-------------
----------	HUD SYSTEM
-------------

rawset(_G, "TBS_Hud", {
	names = {[0] = "SRB2", },
	registered_huds = {[0] = 1},
	configurations = {[0] = {off = {""}}},
	
	hud_elements = {},
	disabled_elements = {},	
	enabled_elements = {},
	
	selectedhud = 0,
})

local vanilla_hud_items = {
	"stagetitle",
	"textspectator",
	"score",
	"time",
	"rings",
	"lives",
	"teamscores",
	"weaponrings",
	"powerstones",
	"nightslink",
	"nightsdrill",
	"nightsrings",
	"nightsscore",
	"nightstime",
	"nightsrecords",
	"rankings",
	"coopemeralds",
	"tokens",
	"tabemblems",
	"intermissiontally",
	"intermissionmessages"
}

// Slots

-- TBS_Hud.freeslot_hud()
TBS_Hud.freeslot_hud = function(...)

end

-- TBS_Hud.configurate_hud()
TBS_Hud.configurate_hud = function(...)


end

-- TBS_Hud.freeslot_hud_element()
TBS_Hud.freeslot_hud_element = function(...)


end

// Removes hud element -- use in cases when you don't want it appear even after other mods enabled it.
-- TBS_Hud.free_hud_element()
TBS_Hud.free_hud_element = function(...)


end

// Change

-- TBS_Hud.select_hud(select hud)
TBS_Hud.select_hud = function(hud)
	for i,k in ipairs(vanilla_hud_items) do
		hud.enable(k)
	end

	for i,k in ipairs(TBS_Hud[configurations][hud].off) do
		hud.disable(k)
	end
	
	TBS_Hud.selectedhud = hud
end

// Toggles

-- TBS_Hud.disable_all_hud()
TBS_Hud.disable_all_hud = function()
	for i,k in ipairs(vanilla_hud_items) do
		hud.enable(k)
	end
	
	TBS_Hud.selectedhud = 0
end

-- TBS_Hud.reset_hud()
TBS_Hud.reset_hud = function()


end

// Hud Element functions

-- TBS_Hud.enable_hud(select hud)
TBS_Hud.enable_hud = function(hud)


end

-- TBS_Hud.disable_hud(select hud)
TBS_Hud.disable_hud = function(hud)


end






