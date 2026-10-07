local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.lua"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.lua"))()

local wnd = lib.new()

wnd:toggle("Delete A-90", false, function(val)
	ign.a90(val)
end)

wnd:toggle("Delete Screech", false, function(val)
	ign.screech(val)
end)

wnd:toggle("Ignore Snare", false, function(val)
	ign.snare(val)
end)

wnd:toggle("Ignore Eyes", false, function(val)
	ign.eyes(val)
end)

wnd:toggle("Speed Boost", false, function(val)
	ign.speed(val)
end)

wnd:slider("Speed Value", 0, 50, 15, function(val)
	ign.set_speed(val)
end)

wnd:warn("Warning: This feature is highly experimental and unstable. May cause network drops and does not guarantee damage immunity.")

wnd.gui.Destroying:Connect(function()
	ign.cleanup()
end)
