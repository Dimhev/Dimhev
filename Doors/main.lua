local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.lua"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.lua"))()
local vis = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/visuals.lua"))()

local wnd = lib.new({
	Title = "ui"
})

local tab_entities = wnd:create_tab("Entities")

tab_entities:create_section("Basic modifiers")

tab_entities:create_toggle("Delete A-90", false, function(val)
	ign.a90(val)
end, "Removes A-90 mechanics entirely")

tab_entities:create_toggle("Delete Screech", false, function(val)
	ign.screech(val)
end, "Removes Screech mechanics in dark rooms")

tab_entities:create_toggle("Ignore Giggle", false, function(val)
	ign.giggle(val)
end, "Prevents Giggle from latching onto you")

tab_entities:create_toggle("Ignore Snare", false, function(val)
	ign.snare(val)
end, "Avoids floor snare traps")

tab_entities:create_toggle("Ignore Dupe", false, function(val)
	ign.dupe(val)
	vis.dupe(val)
end, "Negates fake door damage and highlights them")

tab_entities:create_toggle("Ignore Eyes & Lookman", false, function(val)
	ign.eyes(val)
end, "Prevents damage when looking at Eyes or Lookman")

tab_entities:create_section("Experimental")

tab_entities:create_paragraph(
	"Warning",
	"This feature is highly experimental and unstable. May cause network drops and does not guarantee damage immunity."
)

tab_entities:create_toggle("Ignore Rush & Ambush", false, function(val)
	ign.rush(val)
end, "Attempts to avoid damage from rushing entities")

local tab_movement = wnd:create_tab("Movement")

tab_movement:create_section("Speed")

tab_movement:create_toggle("Speed Boost", false, function(val)
	ign.speed(val)
end, "Enables walkspeed modifier")

tab_movement:create_slider("Speed Value", 0, 50, 15, function(val)
	ign.set_speed(val)
end)

local tab_settings = wnd:create_tab("Settings")

tab_settings:create_section("Info")

tab_settings:create_paragraph(
	"Keybind",
	"Press [RightShift] on your keyboard to toggle the interface."
)

tab_settings:create_button("Unload script", function()
	wnd.gui:Destroy()
end)

wnd.gui.Destroying:Connect(function()
	ign.cleanup()
	vis.cleanup()
end)

lib.notify({
	Title = "ui",
	Content = "Loaded successfully",
	Duration = 2.5
})
