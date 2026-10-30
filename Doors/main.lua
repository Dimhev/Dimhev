local moonlight = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.lua"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.lua"))()
local vis = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/visuals.lua"))()
local autolib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/auto/autolibrary.lua"))()
local autolever = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/auto/autolever.lua"))()
local archives = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/refs/heads/main/Doors/floors/archives.lua"))()
local stairwell = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/refs/heads/main/Doors/floors/stairwell.lua"))()

local wnd = moonlight:CreateWindow({
	Title = "By dimhev"
})

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

local tab_visuals = wnd:CreateTab("Visuals")

local sec_vis_doors = tab_visuals:CreateSection("ESP")

sec_vis_esp:CreateToggle("Enable Door ESP", false, function(val)
	vis.door_esp(val)
end, "Highlights active doors with door number and distance")

sec_vis_esp:CreateToggle("Enable Entity ESP", false, function(val)
	vis.entity_esp(val)
	vis.entity_notify(val, function(title, content, duration)
		moonlight:Notify({
			Title = title,
			Content = content,
			Duration = duration or 5
		})
	end)
end, "Highlights all entities and notifies when an entity spawns")

sec_vis_esp:CreateToggle("Enable Tracers", false, function(val)
	vis.door_tracers(val)
end, "Draws thin tracer lines to active doors and entities")

local tab_doors = wnd:CreateTab("Hotel")

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

local tab_mines = wnd:CreateTab("Mines")

local sec_mines_entities = tab_mines:CreateSection("Entities")

sec_mines_entities:CreateToggle("Ignore Giggle", false, function(val)
	ign.giggle(val)
end, "Prevents Giggle from latching onto you")

local tab_archives = wnd:CreateTab("Archives")

local sec_archives_entities = tab_archives:CreateSection("Entities & Traps")

sec_archives_entities:CreateToggle("Delete A-90", false, function(val)
	archives.a90(val)
end, "Removes A-90 mechanics entirely")

sec_archives_entities:CreateToggle("Bypass Drones", false, function(val)
	archives.drones(val)
end, "Prevents drones from push")

sec_archives_entities:CreateToggle("Bypass Alma", false, function(val)
	archives.alma(val)
end, "Removes Alma")

sec_archives_entities:CreateToggle("Bypass Electric Water", false, function(val)
	archives.water(val)
end, "Places safe collisions over electric water")

sec_archives_entities:CreateToggle("Anti Stampede / Stop Time", false, function(val)
	archives.anti_stampede(val)
end, "Automatically interacts with clocks to counter Stampede")

local tab_stairwell = wnd:CreateTab("Stairwell")

local sec_stairwell_misc = tab_stairwell:CreateSection("Exploits / Anti / Misc")

sec_stairwell_misc:CreateToggle("Noise TV Breaker", false, function(val)
	stairwell.break_tv(val)
end, "Breaks the TV of Noise while holding it")

sec_stairwell_misc:CreateToggle("Item Number", false, function(val)
	stairwell.dropped_item_value(val)
end, "Shows the number of dropped items on screen")

sec_stairwell_misc:CreateToggle("Kill All (Requires >=1 Cart)", false, function(val)
	stairwell.kill_all_with_cart(val)
end, "Teleports shopping carts to other alive players")

sec_stairwell_misc:CreateToggle("Bug Out Creak (Requires >=5 Cart)", false, function(val)
	stairwell.fling_creak(val)
end, "Teleports shopping carts to Creak (do not touch the carts yourself)")

sec_stairwell_misc:CreateToggle("Creak Aggression Meter", false, function(val)
	stairwell.creak_aggression_meter(val)
end, "Shows Creak's aggression percentage above its head")

sec_stairwell_misc:CreateToggle("Disable Crushers", false, function(val)
	stairwell.disable_crushers(val)
end, "Disables crusher collisions and destroys crusher triggers")

sec_stairwell_misc:CreateToggle("Delete Crushers", false, function(val)
	stairwell.delete_crushers(val)
end, "Deletes stairwell crushers except BasicWall")

sec_stairwell_misc:CreateToggle("Remove Meld", false, function(val)
	stairwell.remove_meld(val)
end, "Removes Meld walls and Meld folders")

sec_stairwell_misc:CreateToggle("TP to Trash & Drop Trash", false, function(val)
	stairwell.landing_spam(val)
end, "Teleports to landing trash prompts and drops trash repeatedly")

sec_stairwell_misc:CreateButton("TP Shopping Carts To You", function()
	stairwell.tp_shopping_carts_to_player(game.Players.LocalPlayer.Name)
end, "Teleports all shopping carts in Misc to your character")

local sec_stairwell_exp = tab_stairwell:CreateSection("Experimental & Drops")

sec_stairwell_exp:CreateButton("TP All Drops to Nearest Grinder", function()
	stairwell.tp_drops_to_nearest_grinder()
end, "Teleports every dropped item to the grinder closest to you")

sec_stairwell_exp:CreateButton("Bring Dropped Items", function()
	stairwell.bring_dropped_items()
end, "Brings all dropped items to your character")

sec_stairwell_exp:CreateToggle("Enable Bring Interval", false, function(val)
	stairwell.enable_dropped_items_interval(val)
end, "Automatically brings dropped items at the selected interval")

sec_stairwell_exp:CreateSlider("Bring Interval (s)", 0, 60, 1, function(val)
	stairwell.set_dropped_items_interval(val)
end, "How often dropped items are brought")

sec_stairwell_exp:CreateToggle("Orbit Dropped Items", false, function(val)
	stairwell.orbit_dropped_items(val)
end, "Orbits dropped items around you and prevents despawn every 10s")

sec_stairwell_exp:CreateSlider("Orbit Height", -20, 20, 2, function(val)
	stairwell.set_orbit_height(val)
end, "The height of the item orbit")

sec_stairwell_exp:CreateSlider("Orbit Distance", 0, 50, 5, function(val)
	stairwell.set_orbit_distance(val)
end, "The radius distance of the item orbit")

sec_stairwell_exp:CreateSlider("Orbit Speed", 0, 20, 2, function(val)
	stairwell.set_orbit_speed(val)
end, "The rotation speed of the item orbit")

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
	archives.cleanup()
	stairwell.cleanup()
end)

moonlight:Notify({
	Title = "By dimhev",
	Content = "Loaded successfully",
	Duration = 2.5
})
