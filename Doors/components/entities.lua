local entities = {}

local ctx = nil
local entity_entries = {}
local conns_entity = {}

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

local function is_inst(v)
	return typeof(v) == "Instance"
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
	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
	if not rooms then return nil end
	for _, r in ipairs(rooms:GetChildren()) do
		if obj:IsDescendantOf(r) then
			return tonumber(r.Name)
		end
	end
	return nil
end

local function remove_entity_entry(obj)
	local entry = entity_entries[obj]
	if not entry then return end

	if entry.conn_destroy and entry.conn_destroy.Connected then
		entry.conn_destroy:Disconnect()
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

	entity_entries[obj] = nil
end

local function refresh_entity_visibility(entry, min_room, max_room)
	local is_relevant = true
	if entry.room_based and entry.room_num then
		is_relevant = (entry.room_num >= min_room - 1 and entry.room_num <= max_room + 1)
	end
	local show = ctx.cfg.entity_esp and is_relevant and is_inst(entry.target) and entry.target.Parent ~= nil
	entry.visible = show

	if show then
		if not is_inst(entry.billboard) then
			entry.billboard, entry.label = ctx.create_billboard(entry.target, entry.base_text, ctx.cfg.entity_color)
		end
		entry.billboard.Adornee = entry.target
		entry.billboard.Enabled = true
		entry.label.TextColor3 = ctx.cfg.entity_color

		if not is_inst(entry.hl) then
			entry.hl = ctx.create_highlight(entry.adornee or entry.model, ctx.cfg.entity_color, 0.65, 0.1)
		elseif is_inst(entry.hl) then
			entry.hl.Adornee = entry.adornee or entry.model
			entry.hl.FillColor = ctx.cfg.entity_color
			entry.hl.OutlineColor = ctx.cfg.entity_color
			entry.hl.Enabled = true
		end

		if ctx.cfg.tracers and not entry.tracer then
			entry.tracer = ctx.tracer.create(ctx.cfg.entity_color)
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
	local min_r, max_r = ctx.get_room_bounds()
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
		if ctx.lp:DistanceFromCharacter(root.Position) >= 10000 then return end

		local alias = data.alias
		if ent.Name == "RushMoving" and root.Name ~= "RushNew" then
			alias = root.Name
		end

		if ctx.cfg.entity_notify then
			ctx.fire_notify("Entity '" .. alias .. "' has spawned.", data.body, 5)
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
		if name == "Groundskeeper" and ctx.cfg.entity_notify then
			ctx.fire_notify("Entity 'Groundskeeper' has spawned.", "Avoid stepping on the grass.", 5)
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
			if ctx.cfg.entity_notify then
				ctx.fire_notify("Entity 'Halt'", "Halt will spawn in the next room.", 5)
			end
		end
	end)
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

function entities.init(context)
	ctx = context
end

function entities.sync()
	ctx.disconnect_list(conns_entity)
	if not ctx.cfg.entity_esp and not ctx.cfg.entity_notify then
		for obj in pairs(entity_entries) do
			remove_entity_entry(obj)
		end
		return
	end

	for _, ch in ipairs(ctx.ws:GetChildren()) do
		if spawn_entities[ch.Name] then
			handle_spawned_entity(ch)
		end
	end

	table.insert(conns_entity, ctx.ws.ChildAdded:Connect(function(ch)
		if is_inst(ch) and spawn_entities[ch.Name] then
			handle_spawned_entity(ch)
		end
	end))

	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
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

	if not ctx.cfg.entity_esp then
		for obj in pairs(entity_entries) do
			remove_entity_entry(obj)
		end
	end

	local min_r, max_r = ctx.get_room_bounds()
	entities.refresh(min_r, max_r)
end

function entities.refresh(min_r, max_r)
	for obj, entry in pairs(entity_entries) do
		if not is_inst(obj) or not obj.Parent then
			remove_entity_entry(obj)
		else
			refresh_entity_visibility(entry, min_r, max_r)
		end
	end
end

function entities.step(cam, root, origin)
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

			if ctx.cfg.tracers and entry.tracer then
				local screen_pos, on_screen = cam:WorldToViewportPoint(pos)
				if on_screen and screen_pos.Z > 0 then
					ctx.tracer.update(entry.tracer, origin, Vector2.new(screen_pos.X, screen_pos.Y), ctx.cfg.entity_color)
				else
					ctx.tracer.set_visible(entry.tracer, false)
				end
			elseif entry.tracer then
				ctx.tracer.set_visible(entry.tracer, false)
			end
		end
	end
end

function entities.cleanup()
	ctx.disconnect_list(conns_entity)
	for obj in pairs(entity_entries) do
		remove_entity_entry(obj)
	end
end

return entities
