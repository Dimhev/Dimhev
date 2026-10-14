local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local ws = game:GetService("Workspace")
local lp = plrs.LocalPlayer

local autolever = {}
local active_lever = false
local lever_thread = nil
local lever_notify_cb = nil
local completed_rooms = {}

local function is_valid(obj)
	return obj and obj.Parent and obj:IsDescendantOf(ws)
end

local function get_alive_root()
	local char = lp.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function get_object_pos(obj)
	if not obj then return nil end
	if obj:IsA("Model") then
		return obj:GetPivot().Position
	elseif obj:IsA("BasePart") then
		return obj.Position
	end
	local p = obj:FindFirstChildWhichIsA("BasePart", true)
	return p and p.Position or nil
end

local function can_reach_room(room, target_part)
	local root = get_alive_root()
	if not root or not target_part then return false end

	local char = lp.Character
	local origin = root.Position
	local target_pos = target_part.Position
	local dir = target_pos - origin

	if dir.Magnitude > 150 then
		return false
	end

	local ray_params = RaycastParams.new()
	ray_params.FilterType = Enum.RaycastFilterType.Exclude
	ray_params.FilterDescendantsInstances = { char }

	local res = ws:Raycast(origin, dir, ray_params)
	if res and res.Instance then
		if res.Instance:IsDescendantOf(room) then
			return true
		end
	end

	return false
end

local function get_open_stand_pos(target_pos, target_obj)
	local char = lp.Character
	local ray_params = RaycastParams.new()
	ray_params.FilterType = Enum.RaycastFilterType.Exclude
	ray_params.FilterDescendantsInstances = { char, target_obj }

	local dirs = {
		Vector3.new(0, 0, 1),
		Vector3.new(0, 0, -1),
		Vector3.new(1, 0, 0),
		Vector3.new(-1, 0, 0),
	}

	local origin = target_pos + Vector3.new(0, 0.4, 0)
	local best_dir = dirs[1]
	local max_dist = -1

	for _, dir in ipairs(dirs) do
		local res = ws:Raycast(origin, dir * 10, ray_params)
		local dist = res and (res.Position - origin).Magnitude or 10
		if dist > max_dist then
			max_dist = dist
			best_dir = dir
		end
	end

	return target_pos + (best_dir * 2.0) + Vector3.new(0, 0.2, 0)
end

local function pull_lever(lever, handle)
	local root = get_alive_root()
	local cam = ws.CurrentCamera
	if not root or not cam or not is_valid(lever) then return false end

	local handle_part = handle or lever:FindFirstChild("Handle", true) or lever:FindFirstChildWhichIsA("BasePart", true)
	if not handle_part then return false end

	local target_pos = handle_part.Position
	local stand_pos = get_open_stand_pos(target_pos, lever)
	local initial_y = target_pos.Y
	local start_time = os.clock()
	local success = false

	local ps = lp:FindFirstChild("PlayerScripts")
	local prompt_svc = ps and ps:FindFirstChild("PromptService")
	if prompt_svc and prompt_svc:GetAttribute("Suppressed") then
		prompt_svc:SetAttribute("Suppressed", false)
	end

	local conn = nil
	local function cleanup_pull()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		local r = get_alive_root()
		if r then
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end
	end

	conn = run.RenderStepped:Connect(function()
		if not active_lever then return end
		local cur_root = get_alive_root()
		local cur_cam = ws.CurrentCamera
		if not cur_root or not cur_cam then return end
		cur_root.CFrame = CFrame.lookAt(stand_pos, target_pos)
		cur_root.AssemblyLinearVelocity = Vector3.zero
		cur_root.AssemblyAngularVelocity = Vector3.zero
		cur_cam.CFrame = CFrame.lookAt(cur_cam.CFrame.Position, target_pos)
	end)

	while active_lever and (os.clock() - start_time < 5) do
		if not get_alive_root() then break end
		if not is_valid(lever) then
			success = true
			break
		end

		if is_valid(handle_part) then
			local diff_y = initial_y - handle_part.Position.Y
			if diff_y >= 0.35 then
				success = true
				break
			end
		end

		local prompt = lever:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not prompt or not prompt.Enabled then
			success = true
			break
		end

		if prompt then
			prompt.RequiresLineOfSight = false
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 50
			prompt.Enabled = true

			pcall(function()
				prompt:InputHoldBegin()
			end)

			if fireproximityprompt then
				fireproximityprompt(prompt)
			end
		end

		task.wait(0.06)
	end

	cleanup_pull()
	return success
end

local function tp_to_gate(gate)
	local root = get_alive_root()
	if not root or not is_valid(gate) then return end

	local thing = gate:FindFirstChild("ThingToOpen", true)
	local target_pos = thing and get_object_pos(thing) or get_object_pos(gate)
	if not target_pos then return end

	root.CFrame = CFrame.new(target_pos + Vector3.new(0, 1.5, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

function autolever.run(state, cb)
	active_lever = state
	if cb then lever_notify_cb = cb end
	table.clear(completed_rooms)

	if lever_thread then
		task.cancel(lever_thread)
		lever_thread = nil
	end

	if not active_lever then return end

	lever_thread = task.spawn(function()
		local rooms = ws:WaitForChild("CurrentRooms", 10)
		if not rooms then return end

		while active_lever do
			local root = get_alive_root()
			if not root then
				task.wait(0.2)
				continue
			end

			for _, room in ipairs(rooms:GetChildren()) do
				if not active_lever then break end

				if not completed_rooms[room] then
					local assets = room:FindFirstChild("Assets")
					local lever = assets and assets:FindFirstChild("LeverForGate")
					local gate = assets and assets:FindFirstChild("Gate")

					if lever and gate and is_valid(lever) and is_valid(gate) then
						local handle = lever:FindFirstChild("Handle", true) or lever:FindFirstChildWhichIsA("BasePart", true)
						local prompt = lever:FindFirstChildWhichIsA("ProximityPrompt", true)

						if prompt and prompt.Enabled and handle then
							if can_reach_room(room, handle) then
								local pulled = pull_lever(lever, handle)
								if pulled then
									completed_rooms[room] = true
									task.wait(0.1)
									tp_to_gate(gate)

									if lever_notify_cb then
										lever_notify_cb(room.Name)
									end

									task.wait(0.8)
								end
							end
						end
					end
				end
			end

			task.wait(0.25)
		end
	end)
end

function autolever.cleanup()
	active_lever = false
	table.clear(completed_rooms)
	if lever_thread then
		task.cancel(lever_thread)
		lever_thread = nil
	end
end

return autolever
