local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

local ign = {}
local conns = {}
local active = false

local function get_frame()
	local pgui = lp:FindFirstChild("PlayerGui")
	if not pgui then return nil end
	local mui = pgui:FindFirstChild("MainUI")
	if not mui then return nil end
	local jmp = mui:FindFirstChild("Jumpscare")
	if not jmp then return nil end
	return jmp:FindFirstChild("Jumpscare_A90")
end

local function disconnect_all()
	for _, c in ipairs(conns) do
		if typeof(c) == "RBXScriptConnection" and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(conns)
end

function ign.set(state)
	active = state
	disconnect_all()
	
	if active then
		lp:SetAttribute("Invincibility", true)
		
		local frame = get_frame()
		if frame then
			frame.Visible = false
			local c = frame:GetPropertyChangedSignal("Visible"):Connect(function()
				if active and frame.Visible then
					frame.Visible = false
				end
			end)
			table.insert(conns, c)
		end
	else
		lp:SetAttribute("Invincibility", nil)
		local frame = get_frame()
		if frame then
			frame.Visible = false
		end
	end
end

function ign.cleanup()
	ign.set(false)
	disconnect_all()
end

return ign
