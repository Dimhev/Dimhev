local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.lua"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.lua"))()
local vis = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/visuals.lua"))()

local wnd = lib:create_window({
	title = "By dimhev"
})

local tab_entities = wnd:create_tab("Entities")

local sec_basic = tab_entities:create_section("Basic modifiers")

sec_basic:create_toggle("Delete A-90", false, function(val)
	ign.a90(val)
end)

sec_basic:create_toggle("Delete Screech", false, function(val)
	ign.screech(val)
end)

sec_basic:create_toggle("Ignore Giggle", false, function(val)
	ign.giggle(val)
end)

sec_basic:create_toggle("Ignore Snare", false, function(val)
	ign.snare(val)
end)

sec_basic:create_toggle("Ignore Dupe", false, function(val)
	ign.dupe(val)
	vis.dupe(val)
end)

sec_basic:create_toggle("Ignore Eyes & Lookman", false, function(val)
	ign.eyes(val)
end)

local sec_library = tab_entities:create_section("Library")

sec_library:create_toggle("Auto Library", false, function(val)
	ign.library(val, function(code)
		lib.notify({
			Title = "Library Solved",
			Content = "Code: " .. code .. " (Entering into padlock...)",
			Duration = 10
		})
	end)
end)

local sec_exp = tab_entities:create_section("Experimental")

sec_exp:create_toggle("Ignore Rush & Ambush", false, function(val)
	ign.rush(val)
end)

local tab_movement = wnd:create_tab("Movement")

local sec_speed = tab_movement:create_section("Speed")

sec_speed:create_toggle("Speed Boost", false, function(val)
	ign.speed(val)
end)

sec_speed:create_slider("Speed Value", 0, 50, 15, function(val)
	ign.set_speed(val)
end)

local tab_settings = wnd:create_tab("Settings")

local sec_settings = tab_settings:create_section("Management")

sec_settings:create_button("Unload Script", function()
	wnd:destroy()
end)

wnd.gui.Destroying:Connect(function()
	ign.cleanup()
	vis.cleanup()
end)

lib.notify({
	Title = "By dimhev",
	Content = "Loaded successfully",
	Duration = 2.5
})
