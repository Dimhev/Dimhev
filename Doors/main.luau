local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.luau"))()

local wnd = lib.new("internal test")

wnd:toggle("fly hack", false, function(val)
	print("fly:", val)
end)

wnd:toggle("speed boost", true, function(val)
	print("speed:", val)
end)

wnd:input("speed value", "16", "32", function(val)
	local num = tonumber(val)
	if num then
		print("set speed to", num)
	end
end)

wnd:input("teleport to", "player name", "", function(val)
	print("target:", val)
end)
