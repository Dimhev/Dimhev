local gold = {}

local ctx = nil
local gold_entries = {}
local conns_gold = {}

local function is_inst(v)
	return typeof(v) == "Instance"
end

local function find_gold_part(obj)
	if not is_inst(obj) then return nil end
	if obj:IsA("BasePart") then
		return obj
	end
	if obj:IsA("Model") and obj.PrimaryPart then
		return obj.PrimaryPart
	end
	local hitbox = obj:FindFirstChild("Hitbox")
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox
	end
	return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function get_room_num_from_ancestry(inst)
	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
	if not rooms or not inst:IsDescendantOf(rooms) then
		return nil
	end
	local curr = inst
	while curr and curr.Parent ~= rooms do
		curr = curr.Parent
	end
	return curr and tonumber(curr.Name) or nil
end

local function get_gold_label(obj)
	if obj.Name == "GoldPile" then
		local val = obj:GetAttribute("GoldValue")
		if val then
			return "Gold [" .. tostring(val) .. "]"
		end
		return "Gold Pile"
	elseif obj.Name == "StardustPickup" then
		return "Stardust Pile"
	end
	return nil
end

local function remove_gold_entry(obj)
	local entry = gold_entries[obj]
	if not entry then return end

	if entry.conn_destroy and entry.conn_destroy.Connected then
		entry.conn_destroy:Disconnect()
	end
	if entry.conn_val and entry.conn_val.Connected then
		entry.conn_val:Disconnect()
	end
	if entry.conn_prompt and entry.conn_prompt.Connected then
		entry.conn_prompt:Disconnect()
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

	gold_entries[obj] = nil
end

local function refresh_gold_visibility(entry, min_room, max_room)
	local is_relevant = true
	if entry.room_num ~= nil then
		is_relevant = (entry.room_num >= min_room - 1 and entry.room_num <= max_room + 1)
	end

	local show = ctx.cfg.gold_esp
		and is_relevant
		and is_inst(entry.model)
		and entry.model.Parent ~= nil
		and is_inst(entry.target)
		and entry.target.Parent ~= nil

	entry.visible = show

	if show then
		if not is_inst(entry.billboard) then
			entry.billboard, entry.label = ctx.create_billboard(entry.target, entry.base_text, ctx.cfg.gold_color)
		end
		entry.billboard.Adornee = entry.target
		entry.billboard.Enabled = true
		entry.label.TextColor3 = ctx.cfg.gold_color

		if not is_inst(entry.hl) then
			entry.hl = ctx.create_highlight(entry.model, ctx.cfg.gold_color, 0.72, 0.15)
		elseif is_inst(entry.hl) then
			entry.hl.Adornee = entry.model
			entry.hl.FillColor = ctx.cfg.gold_color
			entry.hl.OutlineColor = ctx.cfg.gold_color
			entry.hl.Enabled = true
		end

		if ctx.cfg.tracers and not entry.tracer then
			entry.tracer = ctx.tracer.create(ctx.cfg.gold_color)
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

local function register_gold(obj, explicit_room_num)
	if not is_inst(obj) or gold_entries[obj] then return end
	if obj.Name ~= "GoldPile" and obj.Name ~= "StardustPickup" then return end

	task.spawn(function()
		if obj.Name == "GoldPile" and obj:GetAttribute("GoldValue") == nil then
			local waited = 0
			while is_inst(obj) and obj.Parent and obj:GetAttribute("GoldValue") == nil and waited < 20 do
				waited = waited + 1
				task.wait(0.1)
			end
		end

		if not ctx.cfg.gold_esp or not is_inst(obj) or not obj.Parent or gold_entries[obj] then
			return
		end
		if obj.Name == "GoldPile" and not obj:GetAttribute("GoldValue") then
			return
		end

		local target = find_gold_part(obj)
		local tries = 0
		while not target and is_inst(obj) and obj.Parent and tries < 30 do
			tries = tries + 1
			task.wait(0.1)
			target = find_gold_part(obj)
		end

		if not target or not ctx.cfg.gold_esp or not is_inst(obj) or not obj.Parent or gold_entries[obj] then
			return
		end

		local room_num = explicit_room_num or tonumber(obj:GetAttribute("ParentRoom")) or get_room_num_from_ancestry(obj)

		local entry = {
			model = obj,
			target = target,
			room_num = room_num,
			base_text = get_gold_label(obj) or "Gold",
			visible = false
		}

		if obj.Name == "GoldPile" then
			entry.conn_val = obj:GetAttributeChangedSignal("GoldValue"):Connect(function()
				entry.base_text = get_gold_label(obj) or "Gold"
			end)
		end

		local prompt = obj:FindFirstChild("LootPrompt") or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			entry.conn_prompt = prompt.Destroying:Once(function()
				remove_gold_entry(obj)
			end)
		end

		entry.conn_destroy = obj.Destroying:Once(function()
			remove_gold_entry(obj)
		end)

		gold_entries[obj] = entry
		local min_r, max_r = ctx.get_room_bounds()
		refresh_gold_visibility(entry, min_r, max_r)
	end)
end

local function scan_room_for_gold(room)
	if not is_inst(room) then return end
	local r_num = tonumber(room.Name)
	for _, desc in ipairs(room:GetDescendants()) do
		if (desc.Name == "GoldPile" or desc.Name == "StardustPickup") and not gold_entries[desc] then
			register_gold(desc, r_num)
		end
	end
end

function gold.init(context)
	ctx = context
end

function gold.scan_rooms()
	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
	if not rooms then return end
	local min_r, max_r = ctx.get_room_bounds()
	for _, room in ipairs(rooms:GetChildren()) do
		local r_num = tonumber(room.Name)
		if r_num and r_num >= min_r - 1 and r_num <= max_r + 1 then
			scan_room_for_gold(room)
		end
	end
end

function gold.refresh(min_r, max_r)
	for model, entry in pairs(gold_entries) do
		if not is_inst(model) or not model.Parent then
			remove_gold_entry(model)
		else
			refresh_gold_visibility(entry, min_r, max_r)
		end
	end
end

function gold.start_tracking()
	ctx.disconnect_list(conns_gold)

	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
	if rooms then
		for _, room in ipairs(rooms:GetChildren()) do
			scan_room_for_gold(room)
		end

		table.insert(conns_gold, rooms.DescendantAdded:Connect(function(inst)
			if not ctx.cfg.gold_esp or not is_inst(inst) then return end
			if inst.Name == "GoldPile" or inst.Name == "StardustPickup" then
				register_gold(inst, get_room_num_from_ancestry(inst))
			end
		end))

		table.insert(conns_gold, rooms.ChildRemoved:Connect(function(room)
			if not is_inst(room) then return end
			local r_num = tonumber(room.Name)
			for model, entry in pairs(gold_entries) do
				if entry.room_num == r_num or not model.Parent then
					remove_gold_entry(model)
				end
			end
		end))
	end

	table.insert(conns_gold, ctx.lp:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
		local min_r, max_r = ctx.get_room_bounds()
		gold.refresh(min_r, max_r)
	end))

	local gd = ctx.rs:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom")
	if lr then
		table.insert(conns_gold, lr:GetPropertyChangedSignal("Value"):Connect(function()
			local min_r, max_r = ctx.get_room_bounds()
			gold.refresh(min_r, max_r)
		end))
	end
end

function gold.stop_tracking()
	ctx.disconnect_list(conns_gold)
	for model in pairs(gold_entries) do
		remove_gold_entry(model)
	end
end

function gold.step(cam, root, origin)
	for model, entry in pairs(gold_entries) do
		if not is_inst(model) or not model.Parent or not is_inst(entry.target) or not entry.target.Parent then
			remove_gold_entry(model)
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
					ctx.tracer.update(entry.tracer, origin, Vector2.new(screen_pos.X, screen_pos.Y), ctx.cfg.gold_color)
				else
					ctx.tracer.set_visible(entry.tracer, false)
				end
			elseif entry.tracer then
				ctx.tracer.set_visible(entry.tracer, false)
			end
		end
	end
end

function gold.cleanup()
	gold.stop_tracking()
end

return gold
