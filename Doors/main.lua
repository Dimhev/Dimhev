local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.luau"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.luau"))()

local wnd = lib.new()

wnd:toggle("Delete A-90", false, function(val)
	ign.set(val)
end)

wnd.gui.Destroying:Connect(function()
	ign.cleanup()
end)
