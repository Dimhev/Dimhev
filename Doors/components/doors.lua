local doors = {}

local ctx = nil
local door_entries = {}
local conns_door = {}

local function is_inst(v)
	return typeof(v) == "Instance"
end

local function get_door_number(door_model, room_num)
	local num = (room_num or (is_inst(door_model.Parent) and tonumber(door_model.Parent.Name)) or 0) + 1
	local fl = ctx.get_floor()
	if fl == "Mines" then
		num = num + 100
	elseif fl == "Backdoor" then
		num = num - 50
	end
	return tostring(num)
end

local function hide_barrier_parts(door_model)
	if not is_inst(door_model) then return end
	local h = door_model:FindFirstChild("Hidden")
	if h and h:IsA("BasePart") then
		h.Transparency = 1
	end
	local cb = door_model:FindFirstChild("ColBox")
	if cb and cb:IsA("BasePart") then
		cb.Transparency = 1
	end
	for _, ch in ipairs(door_model:GetChildren()) do
		if ch:IsA("BasePart") and (ch.Name == "Hidden" or ch.Name == "ColBox") then
			ch.Transparency = 1
		end
	end
end

local function find_door_part(door_model)
	if not is_inst(door_model) then return nil end
	local d = door_model:FindFirstChild("Door")
	if d and d:IsA("BasePart") then
		return d
	end
	if door_model:IsA("Model") and door_model.PrimaryPart then
		return door_model.PrimaryPart
	end
	return door_model:FindFirstChildWhichIsA("BasePart", true)
end

local function update_door_text(entry)
	if not is_inst(entry.model) then return end
	local locked = (entry.model:FindFirstChild("Lock") ~= nil) or (entry.model:FindFirstChild("KeyObtain") ~= nil)
	local suffix = locked and " [locked]" or ""
	entry.base_text = "Door " .. entry.door_num .. suffix
end

local function remove_door_entry(door_model)
	local entry = door_entries[door_model]
	if not entry then return end

	if entry.conn_destroy and entry.conn_destroy.Connected then
		entry.conn_destroy:Disconnect()
	end
	if entry.conn_child_add and entry.conn_child_add.Connected then
		entry.conn_child_add:Disconnect()
	end
	if entry.conn_child_rem and entry.conn_child_rem.Connected then
		entry.conn_child_rem:Disconnect()
	end

	if is_inst(entry.hl) then
		ctx.destroy_highlight(entry.hl)
		entry.hl = nil
	end
	if is_inst(entry.billboard) then
		entry.billboard:Destroy()
		entry.billboard = nil
	end
	if entry.tracer then
		ctx.tracer.destroy(entry.tracer)
		entry.tracer = nil
	end

	door_entries[door_model] = nil
end

local function refresh_door_visibility(entry, min_room, max_room)
	local is_relevant = (entry.room_num >= min_room - 1 and entry.room_num <= max_room + 1)
	local show = ctx.cfg.door_esp and is_relevant and is_inst(entry.target) and entry.target.Parent ~= nil
	entry.visible = show

	if show then
		hide_barrier_parts(entry.model)

		if not is_inst(entry.billboard) then
			entry.billboard, entry.label = ctx.create_billboard(entry.target, entry.base_text, ctx.cfg.door_color)
		end
		entry.billboard.Adornee = entry.target
		entry.billboard.Enabled = true
		entry.label.TextColor3 = ctx.cfg.door_color

		if not is_inst(entry.hl) then
			entry.hl = ctx.create_highlight(entry.model, ctx.cfg.door_color, 0.78, 0.15)
		elseif is_inst(entry.hl) then
			entry.hl.Adornee = entry.model
			entry.hl.FillColor = ctx.cfg.door_color
			entry.hl.OutlineColor = ctx.cfg.door_color
			entry.hl.Enabled = true
		end

		if ctx.cfg.tracers and not entry.tracer then
			entry.tracer = ctx.tracer.create(ctx.cfg.door_color)
		elseif not ctx.cfg.tracers and entry.tracer then
			ctx.tracer.set_visible(entry.tracer, false)
		end
	else
		if is_inst(entry.billboard) then
			entry.billboard.Enabled = false
		end
		if is_inst(entry.hl) then
			ctx.destroy_highlight(entry.hl)
			entry.hl = nil
		end
		if entry.tracer then
			ctx.tracer.set_visible(entry.tracer, false)
		end
	end
end

local function register_door(door_model)
	if not is_inst(door_model) or door_entries[door_model] then return end
	if door_model.Name ~= "Door" or not door_model:IsA("Model") or not is_inst(door_model.Parent) then return end

	local room_num = tonumber(door_model.Parent.Name)
	if not room_num then return end

	task.spawn(function()
		local target = find_door_part(door_model)
		local tries = 0
		while not target and is_inst(door_model) and door_model.Parent and tries < 50 do
			tries = tries + 1
			task.wait(0.1)
			target = find_door_part(door_model)
		end

		if not target or not ctx.cfg.door_esp or not is_inst(door_model) or not door_model.Parent or door_entries[door_model] then
			return
		end

		hide_barrier_parts(door_model)

		local entry = {
			model = door_model,
			target = target,
			room_num = room_num,
			door_num = get_door_number(door_model, room_num),
			base_text = "",
			visible = false
		}

		update_door_text(entry)

		entry.conn_child_add = door_model.ChildAdded:Connect(function(ch)
			if ch:IsA("BasePart") and (ch.Name == "Hidden" or ch.Name == "ColBox") then
				ch.Transparency = 1
			elseif ch.Name == "Lock" then
				update_door_text(entry)
			end
		end)

		entry.conn_child_rem = door_model.ChildRemoved:Connect(function(ch)
			if ch.Name == "Lock" then
				task.defer(function()
					if door_entries[door_model] then
						update_door_text(entry)
					end
				end)
			end
		end)

		entry.conn_destroy = door_model.Destroying:Once(function()
			remove_door_entry(door_model)
		end)

		door_entries[door_model] = entry
		local min_r, max_r = ctx.get_room_bounds()
		refresh_door_visibility(entry, min_r, max_r)
	end)
end

function doors.init(context)
	ctx = context
end

function doors.scan_rooms()
	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
	if not rooms then return end
	for _, room in ipairs(rooms:GetChildren()) do
		local d = room:FindFirstChild("Door")
		if d and d:IsA("Model") and not door_entries[d] then
			register_door(d)
		end
	end
end

function doors.refresh(min_r, max_r)
	for model, entry in pairs(door_entries) do
		if not is_inst(model) or not model.Parent then
			remove_door_entry(model)
		else
			refresh_door_visibility(entry, min_r, max_r)
		end
	end
end

function doors.start_tracking()
	ctx.disconnect_list(conns_door)
	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
	if not rooms then return end

	for _, room in ipairs(rooms:GetChildren()) do
		local d = room:FindFirstChild("Door")
		if d and d:IsA("Model") then
			register_door(d)
		end
	end

	table.insert(conns_door, rooms.ChildAdded:Connect(function(room)
		task.spawn(function()
			if not is_inst(room) then return end
			local d = room:WaitForChild("Door", 15)
			if d and d:IsA("Model") and ctx.cfg.door_esp then
				register_door(d)
				local min_r, max_r = ctx.get_room_bounds()
				doors.refresh(min_r, max_r)
			end
		end)
	end))

	table.insert(conns_door, rooms.ChildRemoved:Connect(function(room)
		if not is_inst(room) then return end
		local r_num = tonumber(room.Name)
		for model, entry in pairs(door_entries) do
			if entry.room_num == r_num or not model.Parent then
				remove_door_entry(model)
			end
		end
	end))

	table.insert(conns_door, ctx.lp:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
		local min_r, max_r = ctx.get_room_bounds()
		doors.refresh(min_r, max_r)
	end))

	local gd = ctx.rs:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom")
	if lr then
		table.insert(conns_door, lr:GetPropertyChangedSignal("Value"):Connect(function()
			local min_r, max_r = ctx.get_room_bounds()
			doors.refresh(min_r, max_r)
		end))
	end
end

function doors.stop_tracking()
	ctx.disconnect_list(conns_door)
	for model in pairs(door_entries) do
		remove_door_entry(model)
	end
end

function doors.step(cam, root, origin)
	for model, entry in pairs(door_entries) do
		if not is_inst(model) or not model.Parent or not is_inst(entry.target) or not entry.target.Parent then
			remove_door_entry(model)
		elseif entry.visible then
			local pos = entry.target.Position
			if is_inst(entry.label) then
				if root then
					local dist = math.floor((root.Position - pos).Magnitude)
					entry.label.Text = entry.base_text .. " [" .. tostring(dist) .. "m]"
				else
					entry.label.Text = entry.base_text
				end
			end

			if ctx.cfg.tracers and entry.tracer then
				local screen_pos, on_screen = cam:WorldToViewportPoint(pos)
				if on_screen and screen_pos.Z > 0 then
					ctx.tracer.update(entry.tracer, origin, Vector2.new(screen_pos.X, screen_pos.Y), ctx.cfg.door_color)
				else
					ctx.tracer.set_visible(entry.tracer, false)
				end
			elseif entry.tracer then
				ctx.tracer.set_visible(entry.tracer, false)
			end
		end
	end
end

function doors.cleanup()
	doors.stop_tracking()
end

return doors
