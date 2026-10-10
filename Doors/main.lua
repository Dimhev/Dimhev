local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.lua"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.lua"))()
local vis = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/visuals.lua"))()

local wnd = lib:CreateWindow({
	title = "By dimhev"
})

local tab_entities = wnd:CreateTab("Entities")

local sec_basic = tab_entities:CreateSection("Basic modifiers")

sec_basic:CreateToggle("Delete A-90", false, function(val)
	ign.a90(val)
end)

sec_basic:CreateToggle("Delete Screech", false, function(val)
	ign.screech(val)
end)

sec_basic:CreateToggle("Ignore Giggle", false, function(val)
	ign.giggle(val)
end)

sec_basic:CreateToggle("Ignore Snare", false, function(val)
	ign.snare(val)
end)

sec_basic:CreateToggle("Ignore Dupe", false, function(val)
	ign.dupe(val)
	vis.dupe(val)
end)

sec_basic:create_toggle("Ignore Eyes & Lookman", false, function(val)
	ign.eyes(val)
end)

local sec_library = tab_entities:CreateSection("Library")

sec_library:CreateToggle("Auto Library", false, function(val)
	ign.library(val, function(code)
		lib.notify({
			Title = "Library Solved",
			Content = "Code: " .. code .. " (Entering into padlock...)",
			Duration = 10
		})
	end)
end)

local sec_exp = tab_entities:CreateSection("Experimental")

sec_exp:CreateToggle("Ignore Rush & Ambush", false, function(val)
	ign.rush(val)
end)

local tab_movement = wnd:CreateTab("Movement")

local sec_speed = tab_movement:CreateSection("Speed")

sec_speed:CreateToggle("Speed Boost", false, function(val)
	ign.speed(val)
end)

sec_speed:CreateSlider("Speed Value", 0, 50, 15, function(val)
	ign.set_speed(val)
end)

local tab_settings = wnd:CreateTab("Settings")

local sec_settings = tab_settings:CreateSection("Management")

sec_settings:CreateButton("Unload Script", function()
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
