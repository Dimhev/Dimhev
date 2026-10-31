local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local core = game:GetService("CoreGui")

local lp = plrs.LocalPlayer

local vis = {}
local conns_dupe = {}
local conns_door = {}
local conns_entity = {}
local active_dupe = false

local cfg = {
	door_esp = false,
	entity_esp = false,
	entity_notify = false,
	tracers = false,
	door_color = Color3.fromRGB(0, 200, 255),
	entity_color = Color3.fromRGB(255, 65, 65)
}

local notify_callback = nil
local door_entries = {}
local entity_entries = {}
local active_highlights = 0
local max_highlights = 25
local render_conn = nil

local spawn_entities = {
	["RushMoving"] = { alias = "Rush", body = "Find a hiding spot." },
	["AmbushMoving"] = { alias = "Ambush", body = "Find a hiding spot." },
	["BackdoorRush"] = { alias = "Blitz", body = "Find a hiding spot." },
	["A60"] = { alias = "A-60", body = "Find a hiding spot." },
	["A120"] = { alias = "A-120", body = "Find a hiding spot." },
	["GlitchRush"] = { alias = "RNIUSHCG==", body = "Find a hiding spot." },
	["GlitchAmbush"] = { alias = "AR0xMBUSH", body = "Find a hiding spot." },
	["FrozenAmbush"] = { alias = "Frozen Ambush", body = "Find a hiding spot." },
	["CustomEntity"] = { alias = "Custom Entity", body = "Find a hiding spot." },
	["Eyes"] = { alias = "Eyes", body = "Avoid looking at it." },
	["Lookman"] = { alias = "Eyes", body = "Avoid looking at it." },
	["BackdoorLookman"] = { alias = "Lookman", body = "Avoid looking at its eyes." },
	["GloombatSwarm"] = { alias = "Gloombat Swarm", body = "Keep all light sources turned off." },
	["MonumentEntity"] = { alias = "Monument", body = "Keep looking at it so it cannot move." },
	["JeffTheKiller"] = { alias = "Jeff the Killer", body = "Avoid touching him." },
	["SallyMoving"] = { alias = "Sally", body = "Drop an item for her." },
	["Groundskeeper"] = { alias = "Groundskeeper", body = "Avoid stepping on the grass." },
	["SeekMovingNewClone"] = { alias = "Seek", body = "Run from Seek!" },
	["SeekMoving"] = { alias = "Seek", body = "Run from Seek!" }
}

local rusher_aliases = {
	["Rush"] = true,
	["Ambush"] = true,
	["Eyes"] = true,
	["Lookman"] = true,
	["Blitz"] = true,
	["A-60"] = true,
	["A-120"] = true,
	["AR0xMBUSH"] = true,
	["RNIUSHCG=="] = true,
	["Frozen Ambush"] = true,
	["Custom Entity"] = true
}

local room_entities = {
	["FigureRig"] = "Figure",
	["FigureRagdoll"] = "Figure",
	["Figure"] = "Figure",
	["GrumbleRig"] = "Grumble",
	["GiggleCeiling"] = "Giggle",
	["Snare"] = "Snare",
	["GloomPile"] = "Gloombat Eggs",
	["LiveEntityBramble"] = "Bramble",
	["Groundskeeper"] = "Groundskeeper"
}

local gui_holder = Instance.new("ScreenGui")
gui_holder.Name = "door_vis_layer"
gui_holder.ResetOnSpawn = false
gui_holder.IgnoreGuiInset = true
gui_holder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
	gui_holder.Parent = (gethui and gethui()) or core
end)
if not gui_holder.Parent then
	gui_holder.Parent = lp:WaitForChild("PlayerGui")
end

local function is_inst(v)
	return typeof(v) == "Instance"
end

local function disconnect_list(list)
	for _, c in ipairs(list) do
		if typeof(c) == "RBXScriptConnection" and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(list)
end

local function fire_notify(title, content, duration)
	if notify_callback then
		pcall(notify_callback, title, content, duration or 5)
	end
end

local function get_floor()
	local gd = rs:FindFirstChild("GameData")
	local fl = gd and gd:FindFirstChild("Floor")
	return fl and fl.Value or "Hotel"
end

local function get_room_bounds()
	local cur = tonumber(lp:GetAttribute("CurrentRoom"))
	local gd = rs:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom") and gd.LatestRoom.Value
	local min_r = cur or lr or 0
	local max_r = lr or cur or 0
	if min_r > max_r then
		min_r, max_r = max_r, min_r
	end
	return min_r, max_r
end

local function get_door_number(door_model, room_num)
	local num = (room_num or (is_inst(door_model.Parent) and tonumber(door_model.Parent.Name)) or 0) + 1
	local fl = get_floor()
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

local function create_tracer(col)
	local ok, line = pcall(function()
		local d = Drawing.new("Line")
		d.Visible = false
		d.Thickness = 1
		d.Transparency = 0.85
		d.Color = col
		return d
	end)
	if ok and line then
		return { is_drawing = true, obj = line }
	end

	local f = Instance.new("Frame")
	f.BackgroundColor3 = col
	f.BackgroundTransparency = 0.2
	f.BorderSizePixel = 0
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Visible = false
	f.Parent = gui_holder
	return { is_drawing = false, obj = f }
end

local function destroy_tracer(tr)
	if not tr then return end
	if tr.is_drawing then
		pcall(function()
			tr.obj.Visible = false
			tr.obj:Remove()
		end)
	else
		if is_inst(tr.obj) then
			tr.obj:Destroy()
		end
	end
end

local function set_tracer_visible(tr, state)
	if not tr then return end
	pcall(function()
		tr.obj.Visible = state
	end)
end

local function update_tracer(tr, from_pos, to_pos, col)
	if not tr then return end
	if tr.is_drawing then
		tr.obj.From = from_pos
		tr.obj.To = to_pos
		tr.obj.Color = col
		tr.obj.Visible = true
	else
		local diff = to_pos - from_pos
		local dist = diff.Magnitude
		local mid = (from_pos + to_pos) * 0.5
		tr.obj.Position = UDim2.fromOffset(mid.X, mid.Y)
		tr.obj.Size = UDim2.fromOffset(dist, 1)
		tr.obj.Rotation = math.deg(math.atan2(diff.Y, diff.X))
		tr.obj.BackgroundColor3 = col
		tr.obj.Visible = true
	end
end

local function create_billboard(target, text, col)
	local bb = Instance.new("BillboardGui")
	bb.Name = "esp_tag"
	bb.Adornee = target
	bb.Size = UDim2.fromOffset(150, 26)
	bb.AlwaysOnTop = true
	bb.ResetOnSpawn = false
	bb.Parent = gui_holder

	local lbl = Instance.new("TextLabel")
	lbl.Name = "label"
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextColor3 = col
	lbl.TextStrokeTransparency = 0.45
	lbl.TextStrokeColor3 = Color3.fromRGB(15, 15, 15)
	lbl.Text = text
	lbl.Parent = bb

	return bb, lbl
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
		entry.hl:Destroy()
		entry.hl = nil
		active_highlights = math.max(0, active_highlights - 1)
	end
	if is_inst(entry.billboard) then
		entry.billboard:Destroy()
		entry.billboard = nil
	end
	destroy_tracer(entry.tracer)
	entry.tracer = nil

	door_entries[door_model] = nil
end

local function remove_entity_entry(obj)
	local entry = entity_entries[obj]
	if not entry then return end

	if entry.conn_destroy and entry.conn_destroy.Connected then
		entry.conn_destroy:Disconnect()
	end
	if is_inst(entry.hl) then
		entry.hl:Destroy()
		entry.hl = nil
		active_highlights = math.max(0, active_highlights - 1)
	end
	if is_inst(entry.billboard) then
		entry.billboard:Destroy()
		entry.billboard = nil
	end
	destroy_tracer(entry.tracer)
	entry.tracer = nil

	entity_entries[obj] = nil
end

local function refresh_door_visibility(entry, min_room, max_room)
	local is_relevant = (entry.room_num >= min_room - 1 and entry.room_num <= max_room + 1)
	local show = cfg.door_esp and is_relevant and is_inst(entry.target) and entry.target.Parent ~= nil
	entry.visible = show

	if show then
		hide_barrier_parts(entry.model)

		if not is_inst(entry.billboard) then
			entry.billboard, entry.label = create_billboard(entry.target, entry.base_text, cfg.door_color)
		end
		entry.billboard.Adornee = entry.target
		entry.billboard.Enabled = true
		entry.label.TextColor3 = cfg.door_color

		if not is_inst(entry.hl) and active_highlights < max_highlights then
			local hl = Instance.new("Highlight")
			hl.Name = "door_hl"
			hl.Adornee = entry.model
			hl.FillColor = cfg.door_color
			hl.OutlineColor = cfg.door_color
			hl.FillTransparency = 0.78
			hl.OutlineTransparency = 0.15
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = gui_holder
			entry.hl = hl
			active_highlights = active_highlights + 1
		elseif is_inst(entry.hl) then
			entry.hl.Adornee = entry.model
			entry.hl.FillColor = cfg.door_color
			entry.hl.OutlineColor = cfg.door_color
			entry.hl.Enabled = true
		end

		if cfg.tracers and not entry.tracer then
			entry.tracer = create_tracer(cfg.door_color)
		elseif not cfg.tracers and entry.tracer then
			set_tracer_visible(entry.tracer, false)
		end
	else
		if is_inst(entry.billboard) then
			entry.billboard.Enabled = false
		end
		if is_inst(entry.hl) then
			entry.hl:Destroy()
			entry.hl = nil
			active_highlights = math.max(0, active_highlights - 1)
		end
		if entry.tracer then
			set_tracer_visible(entry.tracer, false)
		end
	end
end

local function refresh_entity_visibility(entry, min_room, max_room)
	local is_relevant = true
	if entry.room_based and entry.room_num then
		is_relevant = (entry.room_num >= min_room - 1 and entry.room_num <= max_room + 1)
	end
	local show = cfg.entity_esp and is_relevant and is_inst(entry.target) and entry.target.Parent ~= nil
	entry.visible = show

	if show then
		if not is_inst(entry.billboard) then
			entry.billboard, entry.label = create_billboard(entry.target, entry.base_text, cfg.entity_color)
		end
		entry.billboard.Adornee = entry.target
		entry.billboard.Enabled = true
		entry.label.TextColor3 = cfg.entity_color

		if not is_inst(entry.hl) and active_highlights < max_highlights then
			local hl = Instance.new("Highlight")
			hl.Name = "entity_hl"
			hl.Adornee = entry.adornee or entry.model
			hl.FillColor = cfg.entity_color
			hl.OutlineColor = cfg.entity_color
			hl.FillTransparency = 0.65
			hl.OutlineTransparency = 0.1
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = gui_holder
			entry.hl = hl
			active_highlights = active_highlights + 1
		elseif is_inst(entry.hl) then
			entry.hl.Adornee = entry.adornee or entry.model
			entry.hl.FillColor = cfg.entity_color
			entry.hl.OutlineColor = cfg.entity_color
			entry.hl.Enabled = true
		end

		if cfg.tracers and not entry.tracer then
			entry.tracer = create_tracer(cfg.entity_color)
		elseif not cfg.tracers and entry.tracer then
			set_tracer_visible(entry.tracer, false)
		end
	else
		if is_inst(entry.billboard) then
			entry.billboard.Enabled = false
		end
		if is_inst(entry.hl) then
			entry.hl:Destroy()
			entry.hl = nil
			active_highlights = math.max(0, active_highlights - 1)
		end
		if entry.tracer then
			set_tracer_visible(entry.tracer, false)
		end
	end
end

local function refresh_all()
	local min_r, max_r = get_room_bounds()
	for model, entry in pairs(door_entries) do
		if not is_inst(model) or not model.Parent then
			remove_door_entry(model)
		else
			refresh_door_visibility(entry, min_r, max_r)
		end
	end
	for obj, entry in pairs(entity_entries) do
		if not is_inst(obj) or not obj.Parent then
			remove_entity_entry(obj)
		else
			refresh_entity_visibility(entry, min_r, max_r)
		end
	end
end

local function update_door_text(entry)
	if not is_inst(entry.model) then return end
	local locked = (entry.model:FindFirstChild("Lock") ~= nil) or (entry.model:FindFirstChild("KeyObtain") ~= nil)
	local suffix = locked and " [locked]" or ""
	entry.base_text = "Door " .. entry.door_num .. suffix
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

		if not target or not cfg.door_esp or not is_inst(door_model) or not door_model.Parent or door_entries[door_model] then
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
		local min_r, max_r = get_room_bounds()
		refresh_door_visibility(entry, min_r, max_r)
	end)
end

local function find_entity_part(obj)
	if not is_inst(obj) then return nil end
	if obj:IsA("BasePart") then
		return obj
	end
	if obj:IsA("Model") then
		if obj.PrimaryPart then
			return obj.PrimaryPart
		end
		local main = obj:FindFirstChild("RushNew") or obj:FindFirstChild("Main") or obj:FindFirstChild("Core") or obj:FindFirstChild("Hitbox") or obj:FindFirstChild("Top")
		if main and main:IsA("BasePart") then
			obj.PrimaryPart = main
			return main
		end
		local any_part = obj:FindFirstChildWhichIsA("BasePart", true)
		if any_part then
			obj.PrimaryPart = any_part
			return any_part
		end
	end
	return nil
end

local function get_parent_room_num(obj)
	if not is_inst(obj) then return nil end
	local rooms = ws:FindFirstChild("CurrentRooms")
	if not rooms then return nil end
	for _, r in ipairs(rooms:GetChildren()) do
		if obj:IsDescendantOf(r) then
			return tonumber(r.Name)
		end
	end
	return nil
end

local function register_entity(obj, alias, room_based, room_num)
	if not is_inst(obj) or entity_entries[obj] or not obj.Parent then return end

	local target = find_entity_part(obj)
	if not target then return end

	if rusher_aliases[alias] and obj:IsA("Model") then
		if not obj:FindFirstChild("HighlightHumanoid") then
			local hum = Instance.new("Humanoid")
			hum.Name = "HighlightHumanoid"
			hum.Parent = obj
		end
		target.Transparency = 0.999
		target.Material = Enum.Material.Plastic
	end

	local adornee = obj
	if obj.Name == "MonumentEntity" and obj:FindFirstChild("Top") then
		adornee = obj.Top
		target = find_entity_part(obj.Top) or target
	end

	local entry = {
		model = obj,
		target = target,
		adornee = adornee,
		base_text = alias,
		room_based = room_based or false,
		room_num = room_num,
		visible = false
	}

	entry.conn_destroy = obj.Destroying:Once(function()
		remove_entity_entry(obj)
	end)

	entity_entries[obj] = entry
	local min_r, max_r = get_room_bounds()
	refresh_entity_visibility(entry, min_r, max_r)
end

local function handle_spawned_entity(ent)
	if not is_inst(ent) then return end
	local data = spawn_entities[ent.Name]
	if not data then return end

	task.spawn(function()
		local tries = 0
		local root = find_entity_part(ent)
		while not root and is_inst(ent) and ent.Parent and tries < 40 do
			tries = tries + 1
			task.wait(0.05)
			root = find_entity_part(ent)
		end
		task.wait(0.1)

		if not is_inst(ent) or not ent.Parent or not root then return end
		if lp:DistanceFromCharacter(root.Position) >= 10000 then return end

		local alias = data.alias
		if ent.Name == "RushMoving" and root.Name ~= "RushNew" then
			alias = root.Name
		end

		if cfg.entity_notify then
			fire_notify("Entity '" .. alias .. "' has spawned.", data.body, 5)
		end

		if ent.Name ~= "GloombatSwarm" then
			register_entity(ent, alias, false, nil)
		end
	end)
end

local function handle_room_descendant(inst)
	if not is_inst(inst) or not inst.Parent then return end
	local name = inst.Name

	if room_entities[name] then
		local alias = room_entities[name]
		local r_num = get_parent_room_num(inst)
		if name == "Groundskeeper" and cfg.entity_notify then
			fire_notify("Entity 'Groundskeeper' has spawned.", "Avoid stepping on the grass.", 5)
		end
		task.defer(function()
			if is_inst(inst) and inst.Parent then
				register_entity(inst, alias, true, r_num)
			end
		end)
	elseif name == "MandrakeLive" then
		task.defer(function()
			if not is_inst(inst) then return end
			local hole = inst:FindFirstChild("Hole")
			if hole then
				register_entity(hole, "Mandrake Hole", true, get_parent_room_num(inst))
			end
		end)
	end
end

local function check_halt_room(room)
	task.defer(function()
		if not is_inst(room) or not room.Parent then return end
		local raw = room:GetAttribute("RawName")
		if (raw and tostring(raw):find("Halt")) or room:GetAttribute("Shade") == true then
			if cfg.entity_notify then
				fire_notify("Entity 'Halt'", "Halt will spawn in the next room.", 5)
			end
		end
	end)
end

local last_room_check = 0

local function step_render()
	if not cfg.door_esp and not cfg.entity_esp then return end
	local cam = ws.CurrentCamera
	if not cam then return end

	local now = os.clock()
	if now - last_room_check > 0.4 then
		last_room_check = now
		if cfg.door_esp then
			local rooms = ws:FindFirstChild("CurrentRooms")
			if rooms then
				for _, room in ipairs(rooms:GetChildren()) do
					local d = room:FindFirstChild("Door")
					if d and d:IsA("Model") and not door_entries[d] then
						register_door(d)
					end
				end
			end
		end
		refresh_all()
	end

	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local vp = cam.ViewportSize
	local origin = Vector2.new(vp.X * 0.5, vp.Y)

	if cfg.door_esp then
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

				if cfg.tracers and entry.tracer then
					local screen_pos, on_screen = cam:WorldToViewportPoint(pos)
					if on_screen and screen_pos.Z > 0 then
						update_tracer(entry.tracer, origin, Vector2.new(screen_pos.X, screen_pos.Y), cfg.door_color)
					else
						set_tracer_visible(entry.tracer, false)
					end
				elseif entry.tracer then
					set_tracer_visible(entry.tracer, false)
				end
			end
		end
	end

	if cfg.entity_esp then
		for obj, entry in pairs(entity_entries) do
			if not is_inst(obj) or not obj.Parent or not is_inst(entry.target) or not entry.target.Parent then
				remove_entity_entry(obj)
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

				if cfg.tracers and entry.tracer then
					local screen_pos, on_screen = cam:WorldToViewportPoint(pos)
					if on_screen and screen_pos.Z > 0 then
						update_tracer(entry.tracer, origin, Vector2.new(screen_pos.X, screen_pos.Y), cfg.entity_color)
					else
						set_tracer_visible(entry.tracer, false)
					end
				elseif entry.tracer then
					set_tracer_visible(entry.tracer, false)
				end
			end
		end
	end
end

local function update_render_loop()
	if (cfg.door_esp or cfg.entity_esp) and not render_conn then
		render_conn = run.RenderStepped:Connect(step_render)
	elseif not cfg.door_esp and not cfg.entity_esp and render_conn then
		render_conn:Disconnect()
		render_conn = nil
	end
end

local function start_door_tracking()
	disconnect_list(conns_door)
	local rooms = ws:FindFirstChild("CurrentRooms")
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
			if d and d:IsA("Model") and cfg.door_esp then
				register_door(d)
				refresh_all()
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

	table.insert(conns_door, lp:GetAttributeChangedSignal("CurrentRoom"):Connect(refresh_all))

	local gd = rs:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom")
	if lr then
		table.insert(conns_door, lr:GetPropertyChangedSignal("Value"):Connect(refresh_all))
	end

	update_render_loop()
end

local function stop_door_tracking()
	disconnect_list(conns_door)
	for model in pairs(door_entries) do
		remove_door_entry(model)
	end
	update_render_loop()
end

local function scan_room_children(room)
	if not is_inst(room) then return end
	for _, ch in ipairs(room:GetChildren()) do
		handle_room_descendant(ch)
		if ch.Name == "Assets" or ch:IsA("Folder") or ch:IsA("Model") then
			for _, sub in ipairs(ch:GetChildren()) do
				handle_room_descendant(sub)
			end
		end
	end
end

local function sync_entity_tracking()
	disconnect_list(conns_entity)
	if not cfg.entity_esp and not cfg.entity_notify then
		for obj in pairs(entity_entries) do
			remove_entity_entry(obj)
		end
		update_render_loop()
		return
	end

	for _, ch in ipairs(ws:GetChildren()) do
		if spawn_entities[ch.Name] then
			handle_spawned_entity(ch)
		end
	end

	table.insert(conns_entity, ws.ChildAdded:Connect(function(ch)
		if is_inst(ch) and spawn_entities[ch.Name] then
			handle_spawned_entity(ch)
		end
	end))

	local rooms = ws:FindFirstChild("CurrentRooms")
	if is_inst(rooms) then
		for _, room in ipairs(rooms:GetChildren()) do
			scan_room_children(room)
		end
		table.insert(conns_entity, rooms.DescendantAdded:Connect(function(inst)
			if is_inst(inst) then
				handle_room_descendant(inst)
			end
		end))
		table.insert(conns_entity, rooms.ChildAdded:Connect(function(room)
			if is_inst(room) then
				check_halt_room(room)
				task.delay(0.5, function()
					scan_room_children(room)
				end)
			end
		end))
	end

	if not cfg.entity_esp then
		for obj in pairs(entity_entries) do
			remove_entity_entry(obj)
		end
	end

	update_render_loop()
	refresh_all()
end

function vis.set_notifier(fn)
	notify_callback = fn
end

function vis.door_esp(state)
	cfg.door_esp = state
	if state then
		start_door_tracking()
		refresh_all()
	else
		stop_door_tracking()
	end
end

function vis.entity_esp(state, notify_fn)
	if notify_fn then
		notify_callback = notify_fn
	end
	cfg.entity_esp = state
	sync_entity_tracking()
end

function vis.entity_notify(state, notify_fn)
	if notify_fn then
		notify_callback = notify_fn
	end
	cfg.entity_notify = state
	sync_entity_tracking()
end

function vis.door_tracers(state)
	cfg.tracers = state
	refresh_all()
end

local function apply_dupe_visual(door)
	if not is_inst(door) then return end
	local sign = door:FindFirstChild("Sign") or door:FindFirstChild("Sign", true)
	if not is_inst(sign) then return end

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
	if not is_inst(inst) then return end
	if inst.Name == "DoorFake" or inst.Name == "FakeDoor" then
		apply_dupe_visual(inst)
	elseif inst.Name == "Sign" and is_inst(inst.Parent) and (inst.Parent.Name == "DoorFake" or inst.Parent.Name == "FakeDoor") then
		apply_dupe_visual(inst.Parent)
	end
end

function vis.dupe(state)
	active_dupe = state
	disconnect_list(conns_dupe)

	local rooms = ws:FindFirstChild("CurrentRooms") or ws
	if not is_inst(rooms) then return end

	if active_dupe then
		for _, room in ipairs(rooms:GetChildren()) do
			if not active_dupe then break end
			if is_inst(room) then
				for _, ch in ipairs(room:GetChildren()) do
					if ch.Name == "DoorFake" or ch.Name == "FakeDoor" or ch.Name == "SideroomDupe" then
						apply_dupe_visual(ch)
					elseif ch.Name == "Assets" then
						for _, sub in ipairs(ch:GetChildren()) do
							if sub.Name == "DoorFake" or sub.Name == "FakeDoor" then
								apply_dupe_visual(sub)
							end
						end
					end
				end
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
	vis.door_esp(false)
	vis.entity_esp(false)
	vis.entity_notify(false)
	if is_inst(gui_holder) then
		gui_holder:Destroy()
	end
end

return vis
