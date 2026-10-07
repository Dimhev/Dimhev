local ws = game:GetService("Workspace")

local vis = {}
local conns_dupe = {}
local active_dupe = false

local function disconnect_list(list)
	for _, c in ipairs(list) do
		if typeof(c) == "RBXScriptConnection" and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(list)
end

local function apply_dupe_visual(door)
	if not door then return end
	local sign = door:FindFirstChild("Sign") or door:FindFirstChild("Sign", true)
	if not sign then return end

	local duped_label = sign:FindFirstChild("Duped", true)
	if duped_label and duped_label:IsA("ImageLabel") then
		duped_label.Visible = true
		duped_label.ImageTransparency = 0
	end

	local stinker = sign:FindFirstChild("Stinker", true)
	if stinker then
		stinker:Destroy()
	end
end

local function check_inst(inst)
	if not inst then return end
	if inst.Name == "DoorFake" or inst.Name == "FakeDoor" then
		apply_dupe_visual(inst)
	elseif inst.Name == "Sign" and inst.Parent and (inst.Parent.Name == "DoorFake" or inst.Parent.Name == "FakeDoor") then
		apply_dupe_visual(inst.Parent)
	end
end

function vis.dupe(state)
	active_dupe = state
	disconnect_list(conns_dupe)

	local rooms = ws:FindFirstChild("CurrentRooms") or ws

	if active_dupe then
		for _, inst in ipairs(rooms:GetDescendants()) do
			if not active_dupe then break end
			if inst.Name == "DoorFake" or inst.Name == "FakeDoor" then
				apply_dupe_visual(inst)
			end
		end

		local c = rooms.DescendantAdded:Connect(function(inst)
			if active_dupe then
				check_inst(inst)
			end
		end)
		table.insert(conns_dupe, c)
	end
end

function vis.cleanup()
	vis.dupe(false)
end

return vis
