local items = {}

local ctx = nil
local item_entries = {}
local conns_item = {}

local itemNames = {
	["AbrahamHat"]        = "Hat",
	["LargeScrew"]        = "Screw",
	["DinkyLamp"]         = "Lamp",
	["BottleCrate"]       = "18+ Bottles",
	["GweenSodaPack"]     = "Gween Soda Pack",
	["BrokenMonitor"]     = "Broken Monitor",
	["JerryCan"]          = "Jerry Can",
	["SallyToyObtain"]    = "Sally Toy",
	["Leftovers"]         = "Lunch Box",
	["HoneyPot"]          = "Honey Pot",
	["FihFlakes"]         = "Fih Food",
	["SecretCD"]          = "CD Disc",
	["Pizza"]             = "Pizza",
	["PaperPlanePickup"]  = "Paper Plane",
	["Lighter"]           = "Lighter",
	["Flashlight"]        = "Flashlight",
	["Lockpick"]          = "Lockpicks",
	["Vitamins"]          = "Vitamins",
	["Bandage"]           = "Bandage",
	["StarVial"]          = "Starlight Vial",
	["StarBottle"]        = "Starlight Bottle",
	["StarJug"]           = "Starlight Barrel",
	["Shakelight"]        = "Gummy Flashlight",
	["Straplight"]        = "Straplight",
	["Bulklight"]         = "Spotlight",
	["Battery"]           = "Battery",
	["Candle"]            = "Candle",
	["Crucifix"]          = "Crucifix",
	["CrucifixWall"]      = "Crucifix",
	["Glowsticks"]        = "Glowstick",
	["SkeletonKey"]       = "Skeleton Key",
	["Candy"]             = "Candy",
	["ShieldMini"]        = "Mini Shield Potion",
	["ShieldBig"]         = "Big Shield Potion",
	["BandagePack"]       = "Bandage Pack",
	["BatteryPack"]       = "Battery Pack",
	["RiftCandle"]        = "Moonlight Candle",
	["LaserPointer"]      = "Laser Pointer",
	["HolyGrenade"]       = "Holy Hand Grenade",
	["Shears"]            = "Shears",
	["Smoothie"]          = "Smoothie",
	["Cheese"]            = "Cheese",
	["Bread"]             = "Bread",
	["AlarmClock"]        = "Alarm Clock",
	["RiftSmoothie"]      = "Moonlight Smoothie",
	["GweenSoda"]         = "Gween Soda",
	["GlitchCube"]        = "Glitch Fragment",
	["Scanner"]           = "Tablet",
	["Bomb"]              = "Bomb",
	["Knockbomb"]         = "Knockbomb",
	["Nanner"]            = "Nanner",
	["BigBomb"]           = "Big Bomb",
	["SnakeBox"]          = "Hiding Box",
	["GoldGun"]           = "Golden Gun",
	["StopSign"]          = "Stop Sign",
	["TipJar"]            = "Tip Jar",
	["Lantern"]           = "Lantern",
	["IronKey"]           = "Iron Key",
	["LotusPetal"]        = "Lotus Petal",
	["Compass"]           = "Compass",
	["LotusPetalPickup"]  = "Lotus Petal",
	["LanternLitItem"]    = "Lantern",
	["KeyIron"]           = "Iron Key",
	["IronKeyForCrypt"]   = "Iron Key",
	["LotusHolder"]       = "Lotus Petal",
	["Multitool"]         = "Multitool",
	["RiftJar"]           = "Rift Jar",
	["AloeVera"]          = "Aloe Vera",
	["Donut"]             = "Donut",
	["Lotus"]             = "Lotus",
	["BoxingGloves"]      = "Boxing Gloves",
	["Green_Herb"]        = "Green Herb"
}

local function is_inst(v)
	return typeof(v) == "Instance"
end

local function find_item_part(item_obj)
	if not is_inst(item_obj) then return nil end
	if item_obj:IsA("BasePart") then
		return item_obj
	end
	if item_obj:IsA("Model") and item_obj.PrimaryPart then
		return item_obj.PrimaryPart
	end
	local main = item_obj:FindFirstChild("Main") or item_obj:FindFirstChild("Handle")
	if main and main:IsA("BasePart") then
		return main
	end
	return item_obj:FindFirstChildWhichIsA("BasePart", true)
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

local function is_valid_item(inst)
	if not is_inst(inst) then return false end
	local name = inst.Name
	if name == "Green_Herb" then
		return true
	end
	if itemNames[name] then
		if inst:FindFirstChild("ModulePrompt") or inst:FindFirstChildWhichIsA("ProximityPrompt", true) then
			return true
		end
	end
	return false
end

local function remove_item_entry(item_obj)
	local entry = item_entries[item_obj]
	if not entry then return end

	if entry.conn_destroy and entry.conn_destroy.Connected then
		entry.conn_destroy:Disconnect()
	end
	if entry.conn_ancestry and entry.conn_ancestry.Connected then
		entry.conn_ancestry:Disconnect()
	end
	if entry.conn_trans and entry.conn_trans.Connected then
		entry.conn_trans:Disconnect()
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

	item_entries[item_obj] = nil
end

local function refresh_item_visibility(entry, min_room, max_room)
	local is_relevant = true
	if entry.room_num ~= nil then
		is_relevant = (entry.room_num >= min_room - 1 and entry.room_num <= max_room + 1)
	end

	local show = ctx.cfg.item_esp
		and is_relevant
		and not entry.blacklisted
		and is_inst(entry.model)
		and entry.model.Parent ~= nil
		and is_inst(entry.target)
		and entry.target.Parent ~= nil

	entry.visible = show

	if show then
		if not is_inst(entry.billboard) then
			entry.billboard, entry.label = ctx.create_billboard(entry.target, entry.base_text, ctx.cfg.item_color)
		end
		entry.billboard.Adornee = entry.target
		entry.billboard.Enabled = true
		entry.label.TextColor3 = ctx.cfg.item_color

		if not is_inst(entry.hl) then
			entry.hl = ctx.create_highlight(entry.model, ctx.cfg.item_color, 0.72, 0.15)
		elseif is_inst(entry.hl) then
			entry.hl.Adornee = entry.model
			entry.hl.FillColor = ctx.cfg.item_color
			entry.hl.OutlineColor = ctx.cfg.item_color
			entry.hl.Enabled = true
		end

		if ctx.cfg.tracers and not entry.tracer then
			entry.tracer = ctx.tracer.create(ctx.cfg.item_color)
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

local function register_item(item_obj, explicit_room_num)
	if not is_inst(item_obj) or item_entries[item_obj] then return end
	if not itemNames[item_obj.Name] then return end

	task.spawn(function()
		if item_obj.Name ~= "Green_Herb" and not item_obj:FindFirstChild("ModulePrompt") and not item_obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
			local waited = 0
			while is_inst(item_obj) and item_obj.Parent and not item_obj:FindFirstChild("ModulePrompt") and not item_obj:FindFirstChildWhichIsA("ProximityPrompt", true) and waited < 25 do
				waited = waited + 1
				task.wait(0.1)
			end
		end

		if not ctx.cfg.item_esp or not is_valid_item(item_obj) or not item_obj.Parent or item_entries[item_obj] then
			return
		end

		local target = find_item_part(item_obj)
		local tries = 0
		while not target and is_inst(item_obj) and item_obj.Parent and tries < 30 do
			tries = tries + 1
			task.wait(0.1)
			target = find_item_part(item_obj)
		end

		if not target or not ctx.cfg.item_esp or not is_inst(item_obj) or not item_obj.Parent or item_entries[item_obj] then
			return
		end

		local room_num = explicit_room_num or tonumber(item_obj:GetAttribute("ParentRoom")) or get_room_num_from_ancestry(item_obj)

		local entry = {
			model = item_obj,
			target = target,
			room_num = room_num,
			base_text = itemNames[item_obj.Name] or item_obj.Name,
			blacklisted = false,
			visible = false
		}

		if item_obj.Name == "LotusHolder" or item_obj.Name == "LotusPetalPickup" then
			local handle = item_obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				entry.conn_trans = handle:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
					entry.blacklisted = true
					remove_item_entry(item_obj)
				end)
			end
		end

		local prompt = item_obj:FindFirstChild("ModulePrompt") or item_obj:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			entry.conn_prompt = prompt.Destroying:Once(function()
				remove_item_entry(item_obj)
			end)
		end

		entry.conn_ancestry = item_obj.AncestryChanged:Connect(function(_, new_parent)
			if not new_parent then
				remove_item_entry(item_obj)
			else
				local char = ctx.lp.Character
				local bp = ctx.lp:FindFirstChild("Backpack")
				if (char and item_obj:IsDescendantOf(char)) or (bp and item_obj:IsDescendantOf(bp)) then
					remove_item_entry(item_obj)
				end
			end
		end)

		entry.conn_destroy = item_obj.Destroying:Once(function()
			remove_item_entry(item_obj)
		end)

		item_entries[item_obj] = entry
		local min_r, max_r = ctx.get_room_bounds()
		refresh_item_visibility(entry, min_r, max_r)
	end)
end

local function scan_room_for_items(room)
	if not is_inst(room) then return end
	local r_num = tonumber(room.Name)
	for _, desc in ipairs(room:GetDescendants()) do
		if itemNames[desc.Name] and not item_entries[desc] then
			register_item(desc, r_num)
		end
	end
end

function items.init(context)
	ctx = context
end

function items.scan_rooms()
	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
	if rooms then
		local min_r, max_r = ctx.get_room_bounds()
		for _, room in ipairs(rooms:GetChildren()) do
			local r_num = tonumber(room.Name)
			if r_num and r_num >= min_r - 1 and r_num <= max_r + 1 then
				scan_room_for_items(room)
			end
		end
	end

	local drops = ctx.ws:FindFirstChild("Drops")
	if drops then
		for _, drop in ipairs(drops:GetChildren()) do
			if itemNames[drop.Name] and not item_entries[drop] then
				register_item(drop, nil)
			end
		end
	end
end

function items.refresh(min_r, max_r)
	for model, entry in pairs(item_entries) do
		if not is_inst(model) or not model.Parent then
			remove_item_entry(model)
		else
			refresh_item_visibility(entry, min_r, max_r)
		end
	end
end

function items.start_tracking()
	ctx.disconnect_list(conns_item)

	local rooms = ctx.ws:FindFirstChild("CurrentRooms")
	if rooms then
		for _, room in ipairs(rooms:GetChildren()) do
			scan_room_for_items(room)
		end

		table.insert(conns_item, rooms.DescendantAdded:Connect(function(inst)
			if not ctx.cfg.item_esp or not is_inst(inst) then return end
			if itemNames[inst.Name] then
				register_item(inst, get_room_num_from_ancestry(inst))
			elseif inst.Name == "ModulePrompt" and is_inst(inst.Parent) and itemNames[inst.Parent.Name] then
				register_item(inst.Parent, get_room_num_from_ancestry(inst.Parent))
			end
		end))

		table.insert(conns_item, rooms.ChildRemoved:Connect(function(room)
			if not is_inst(room) then return end
			local r_num = tonumber(room.Name)
			for model, entry in pairs(item_entries) do
				if entry.room_num == r_num or not model.Parent then
					remove_item_entry(model)
				end
			end
		end))
	end

	local drops = ctx.ws:FindFirstChild("Drops")
	if drops then
		for _, drop in ipairs(drops:GetChildren()) do
			if itemNames[drop.Name] then
				register_item(drop, nil)
			end
		end

		table.insert(conns_item, drops.ChildAdded:Connect(function(drop)
			if ctx.cfg.item_esp and is_inst(drop) and itemNames[drop.Name] then
				register_item(drop, nil)
			end
		end))

		table.insert(conns_item, drops.ChildRemoved:Connect(function(drop)
			if item_entries[drop] then
				remove_item_entry(drop)
			end
		end))
	end

	table.insert(conns_item, ctx.lp:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
		local min_r, max_r = ctx.get_room_bounds()
		items.refresh(min_r, max_r)
	end))

	local gd = ctx.rs:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom")
	if lr then
		table.insert(conns_item, lr:GetPropertyChangedSignal("Value"):Connect(function()
			local min_r, max_r = ctx.get_room_bounds()
			items.refresh(min_r, max_r)
		end))
	end
end

function items.stop_tracking()
	ctx.disconnect_list(conns_item)
	for model in pairs(item_entries) do
		remove_item_entry(model)
	end
end

function items.step(cam, root, origin)
	for model, entry in pairs(item_entries) do
		if not is_inst(model) or not model.Parent or not is_inst(entry.target) or not entry.target.Parent then
			remove_item_entry(model)
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
					ctx.tracer.update(entry.tracer, origin, Vector2.new(screen_pos.X, screen_pos.Y), ctx.cfg.item_color)
				else
					ctx.tracer.set_visible(entry.tracer, false)
				end
			elseif entry.tracer then
				ctx.tracer.set_visible(entry.tracer, false)
			end
		end
	end
end

function items.cleanup()
	items.stop_tracking()
end

return items
