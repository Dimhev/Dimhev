local moonlight = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.lua"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.lua"))()
local vis = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/visuals.lua"))()
local autolib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/auto/autolibrary.lua"))()
local autolever = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/auto/autolever.lua"))()

local wnd = moonlight:CreateWindow({
	Title = "By dimhev"
})

-- Main

local tab_main = wnd:CreateTab("Main")

local sec_movement = tab_main:CreateSection("Movement")

sec_movement:CreateToggle("Speed Boost", false, function(val)
	ign.speed(val)
end, "Enables walkspeed modifier")

sec_movement:CreateSlider("Speed Value", 0, 50, 15, function(val)
	ign.set_speed(val)
end, "Adjusts additional walkspeed amount")

local sec_main_entities = tab_main:CreateSection("General Entities")

sec_main_entities:CreateToggle("Ignore Screech", false, function(val)
	ign.screech(val)
end, "Removes Screech mechanics in dark rooms")

sec_main_entities:CreateToggle("Ignore Dupe", false, function(val)
	ign.dupe(val)
	vis.dupe(val)
end, "Negates fake door damage and highlights them")

sec_main_entities:CreateToggle("Ignore Rush-like Entities", false, function(val)
	ign.rush(val)
end, "Attempts to avoid damage from rushing entities (Rush, Ambush, etc.)")

sec_main_entities:CreateToggle("Ignore Eyes & Lookman", false, function(val)
	ign.eyes(val)
end, "Prevents damage when looking at Eyes or Lookman")

-- Hotel

local tab_doors = wnd:CreateTab("Doors")

local sec_doors_entities = tab_doors:CreateSection("Entities & Traps")

sec_doors_entities:CreateToggle("Ignore Snare", false, function(val)
	ign.snare(val)
end, "Avoids floor snare traps")

local sec_doors_auto = tab_doors:CreateSection("Automation")

sec_doors_auto:CreateToggle("Auto Library", false, function(val)
	autolib.run(val, function(code)
		moonlight:Notify({
			Title = "Library Solved",
			Content = "Code: " .. code .. " (Entering into padlock...)",
			Duration = 10
		})
	end)
end, "Auto collects paper & books, decodes and unlocks Room 50")

sec_doors_auto:CreateToggle("Auto Lever", false, function(val)
	autolever.run(val, function(room_name)
		moonlight:Notify({
			Title = "Gate Lever",
			Content = "Pulled Lever! Room " .. room_name,
			Duration = 4
		})
	end)
end, "Auto pulls gate levers and teleports to gate")

-- Mines

local tab_mines = wnd:CreateTab("Mines")

local sec_mines_entities = tab_mines:CreateSection("Entities")

sec_mines_entities:CreateToggle("Ignore Giggle", false, function(val)
	ign.giggle(val)
end, "Prevents Giggle from latching onto you")

-- Archives

local tab_archives = wnd:CreateTab("Archives")

local sec_archives_entities = tab_archives:CreateSection("Entities")

sec_archives_entities:CreateToggle("Delete A-90", false, function(val)
	ign.a90(val)
end, "Removes A-90 mechanics entirely")

-- Settings

local tab_settings = wnd:CreateTab("Settings")

local sec_settings = tab_settings:CreateSection("Management")

sec_settings:CreateButton("Unload Script", function()
	wnd:Destroy()
end, "Safely restores original mechanics and closes menu")

wnd.gui.Destroying:Connect(function()
	ign.cleanup()
	vis.cleanup()
	autolib.cleanup()
	autolever.cleanup()
end)

moonlight:Notify({
	Title = "By dimhev",
	Content = "Loaded successfully",
	Duration = 2.5
})
