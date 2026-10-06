local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.lua"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.lua"))()

local wnd = lib.new()

wnd:toggle("Delete A-90", false, function(val)
	ign.a90(val)
end)

wnd:toggle("Delete Screech", false, function(val)
	ign.screech(val)
end)

wnd:toggle("Delete Snare", false, function(val)
	ign.snare(val)
end)

wnd.gui.Destroying:Connect(function()
	ign.cleanup()
end)
