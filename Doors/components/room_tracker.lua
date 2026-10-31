local tracker_module = {}

function tracker_module.init()
end

function tracker_module.new(context, spec)
	local api = {}
	local ctx = context

	local entries = {}
	local active = {}
	local connections = {}
	local root_connections = {}

	local ignored = setmetatable({}, { __mode = "k" })

	local scan_stack = {}
	local rooms = nil
	local running = false
	local disposed = false
	local heartbeat = nil

	local maintenance_at = 0
	local label_at = 0

	local MAINTENANCE_INTERVAL = 0.25
	local LABEL_INTERVAL = 0.1
	local SCAN_NODE_BUDGET = 100
	local SCAN_TIME_BUDGET = 0.0015

	local remove_entry
	local refresh_entry

	local function disconnect(list)
		for i = #list, 1, -1 do
			local connection = list[i]
			list[i] = nil

			if connection then
				connection:Disconnect()
			end
		end
	end

	local function connect(list, signal, callback)
		local connection = signal:Connect(callback)
		list[#list + 1] = connection
		return connection
	end

	local function set_active(entry, state)
		local index = entry.active_index

		if state then
			if not index then
				active[#active + 1] = entry
				entry.active_index = #active
			end
		elseif index then
			local last_index = #active
			local last_entry = active[last_index]

			active[last_index] = nil

			if index ~= last_index then
				active[index] = last_entry
				last_entry.active_index = index
			end

			entry.active_index = nil
		end

		entry.visible = state
	end

	local function release_visuals(entry)
		set_active(entry, false)

		local hl = entry.hl
		local billboard = entry.billboard
		local tracer = entry.tracer

		entry.hl = nil
		entry.billboard = nil
		entry.label = nil
		entry.tracer = nil
		entry.color = nil
		entry.last_text = nil

		if hl then
			ctx.destroy_highlight(hl)
		end

		if billboard then
			billboard:Destroy()
		end

		if tracer then
			ctx.tracer.destroy(tracer)
		end
	end

	remove_entry = function(model)
		local entry = entries[model]
		if not entry then
			return
		end

		entries[model] = nil
		entry.dead = true

		disconnect(entry.connections)
		release_visuals(entry)

		entry.model = nil
		entry.target = nil
		entry.room = nil
		entry.prompt = nil
	end

	local function find_room(model)
		if not rooms or not model:IsDescendantOf(rooms) then
			return nil
		end

		local current = model

		while current and current.Parent ~= rooms do
			current = current.Parent
		end

		return current
	end

	local function valid_target(entry)
		local target = entry.target
		local model = entry.model

		return target ~= nil
			and target.Parent ~= nil
			and (
				target == model
				or target:IsDescendantOf(model)
			)
	end

	local function bind_prompt(entry)
		if not spec.watch_prompt or entry.prompt then
			return
		end

		local model = entry.model
		local prompt = model:FindFirstChild("LootPrompt")
			or model:FindFirstChildWhichIsA("ProximityPrompt", true)

		if not prompt then
			return
		end

		entry.prompt = prompt

		connect(entry.connections, prompt.Destroying, function()
			if entry.dead or not running then
				return
			end

			local object = entry.model

			if object then
				ignored[object] = true
				remove_entry(object)
			end
		end)
	end

	local function update_visuals(entry, color)
		if not entry.billboard then
			entry.billboard, entry.label = ctx.create_billboard(
				entry.target,
				entry.base_text,
				color
			)

			entry.last_text = entry.base_text
		end

		if not entry.hl then
			entry.hl = ctx.create_highlight(
				entry.model,
				color,
				spec.fill_transparency or 0.72,
				0.15
			)
		end

		if entry.color ~= color then
			entry.color = color

			if entry.label then
				entry.label.TextColor3 = color
			end

			if entry.hl then
				entry.hl.FillColor = color
				entry.hl.OutlineColor = color
			end
		end

		if ctx.cfg.tracers then
			if not entry.tracer then
				entry.tracer = ctx.tracer.create(color)
			end
		elseif entry.tracer then
			local tracer = entry.tracer
			entry.tracer = nil
			ctx.tracer.destroy(tracer)
		end
	end

	refresh_entry = function(entry, min_room, max_room)
		if entry.dead then
			return
		end

		local model = entry.model
		local room = find_room(model)

		if not room then
			remove_entry(model)
			return
		end

		if spec.accept and not spec.accept(model, room) then
			remove_entry(model)
			return
		end

		entry.room = room
		entry.room_num = tonumber(room.Name)
			or tonumber(model:GetAttribute("ParentRoom"))

		if not valid_target(entry) then
			if entry.target then
				release_visuals(entry)
				entry.target = nil
			end
		end

		local dirty = entry.dirty

		if dirty then
			entry.dirty = false

			local target = spec.find_target(model)

			if target ~= entry.target then
				release_visuals(entry)
				entry.target = target
			end

			bind_prompt(entry)
		end

		local ready = valid_target(entry)

		if ready and spec.ready then
			ready = spec.ready(model)
		end

		local room_num = entry.room_num
		local relevant = room_num == nil
			or (
				room_num >= min_room - 1
				and room_num <= max_room + 1
			)

		local show = ctx.cfg[spec.enabled_key]
			and ready
			and relevant

		if not show then
			if entry.visible
				or entry.billboard
				or entry.hl
				or entry.tracer
			then
				release_visuals(entry)
			end

			return
		end

		entry.base_text = spec.get_text(
			model,
			room_num,
			ctx
		)

		local was_visible = entry.visible

		if spec.prepare and (dirty or not was_visible) then
			spec.prepare(model)
		end

		update_visuals(entry, ctx.cfg[spec.color_key])
		set_active(entry, true)
	end

	local function register(model)
		if not running
			or entries[model]
			or ignored[model]
			or not spec.match(model)
		then
			return
		end

		local room = find_room(model)

		if not room then
			return
		end

		if spec.accept and not spec.accept(model, room) then
			return
		end

		local entry = {
			model = model,
			target = nil,
			room = room,
			room_num = tonumber(room.Name),
			base_text = "",
			connections = {},
			dirty = true,
			dead = false,
			visible = false,
		}

		entries[model] = entry

		connect(entry.connections, model.Destroying, function()
			remove_entry(model)
		end)

		connect(entry.connections, model.DescendantAdded, function()
			if not entry.dead then
				entry.dirty = true
			end
		end)

		connect(entry.connections, model.DescendantRemoving, function()
			if not entry.dead then
				entry.dirty = true
			end
		end)

		for _, attribute in ipairs(spec.attributes or {}) do
			connect(
				entry.connections,
				model:GetAttributeChangedSignal(attribute),
				function()
					if not entry.dead then
						entry.dirty = true
					end
				end
			)
		end
	end

	local function clear_entries()
		for model in pairs(entries) do
			remove_entry(model)
		end

		table.clear(entries)
		table.clear(active)
	end

	local function bind_rooms(new_rooms)
		if rooms == new_rooms then
			return
		end

		disconnect(root_connections)
		clear_entries()
		table.clear(scan_stack)

		rooms = new_rooms

		if not rooms then
			return
		end

		connect(root_connections, rooms.DescendantAdded, function(inst)
			register(inst)
		end)

		connect(root_connections, rooms.DescendantRemoving, function(inst)
			if entries[inst] then
				remove_entry(inst)
			end
		end)

		scan_stack[1] = rooms
	end

	local function ensure_rooms()
		local current = ctx.ws:FindFirstChild("CurrentRooms")

		if current ~= rooms then
			bind_rooms(current)
		end
	end

	local function process_scan()
		local started = os.clock()
		local processed = 0

		while #scan_stack > 0 do
			if processed >= SCAN_NODE_BUDGET then
				break
			end

			if os.clock() - started >= SCAN_TIME_BUDGET then
				break
			end

			local index = #scan_stack
			local inst = scan_stack[index]
			scan_stack[index] = nil

			processed += 1

			if rooms and (
				inst == rooms
				or inst:IsDescendantOf(rooms)
			) then
				register(inst)

				local descend = not spec.shallow_scan
					or inst == rooms
					or inst.Parent == rooms

				if descend then
					for _, child in ipairs(inst:GetChildren()) do
						scan_stack[#scan_stack + 1] = child
					end
				end
			end
		end
	end

	function api.refresh(min_room, max_room)
		if disposed or not running then
			return
		end

		for _, entry in pairs(entries) do
			refresh_entry(entry, min_room, max_room)
		end
	end

	function api.scan_rooms()
		if disposed or not running then
			return
		end

		ensure_rooms()
	end

	function api.start_tracking()
		if disposed or running then
			return
		end

		running = true
		maintenance_at = 0
		label_at = 0

		ensure_rooms()

		heartbeat = ctx.run.Heartbeat:Connect(function()
			if not running then
				return
			end

			process_scan()

			local now = os.clock()

			if now >= maintenance_at then
				maintenance_at = now + MAINTENANCE_INTERVAL
				ensure_rooms()

				local min_room, max_room = ctx.get_room_bounds()
				api.refresh(min_room, max_room)
			end
		end)

		connections[#connections + 1] = heartbeat
	end

	function api.stop_tracking()
		running = false

		disconnect(connections)
		disconnect(root_connections)

		heartbeat = nil

		clear_entries()
		table.clear(scan_stack)
		table.clear(ignored)

		rooms = nil
	end

	function api.step(cam, root, origin)
		if disposed or not running then
			return
		end

		local now = os.clock()
		local update_labels = now >= label_at

		if update_labels then
			label_at = now + LABEL_INTERVAL
		end

		local root_position = root and root.Position
		local tracers_enabled = ctx.cfg.tracers
		local color = ctx.cfg[spec.color_key]

		local i = 1

		while i <= #active do
			local entry = active[i]
			local model = entry.model
			local target = entry.target

			if not model or not model.Parent then
				remove_entry(model)
			elseif not target or not target.Parent then
				release_visuals(entry)
				entry.target = nil
				entry.dirty = true
			else
				local position = target.Position

				if update_labels and entry.label then
					local text = entry.base_text

					if root_position then
						local distance = math.floor(
							(root_position - position).Magnitude
						)

						text ..= " [" .. tostring(distance) .. "m]"
					end

					if text ~= entry.last_text then
						entry.last_text = text
						entry.label.Text = text
					end
				end

				if entry.tracer then
					if tracers_enabled then
						local screen, on_screen =
							cam:WorldToViewportPoint(position)

						if on_screen and screen.Z > 0 then
							ctx.tracer.update(
								entry.tracer,
								origin,
								Vector2.new(screen.X, screen.Y),
								color
							)
						else
							ctx.tracer.set_visible(
								entry.tracer,
								false
							)
						end
					else
						ctx.tracer.set_visible(entry.tracer, false)
					end
				end

				i += 1
			end
		end
	end

	function api.get_stats()
		local count = 0
		local connection_count = #connections + #root_connections

		for _, entry in pairs(entries) do
			count += 1
			connection_count += #entry.connections
		end

		return {
			running = running,
			entries = count,
			visible = #active,
			scan_pending = #scan_stack,
			connections = connection_count,
		}
	end

	function api.cleanup()
		if disposed then
			return
		end

		api.stop_tracking()
		disposed = true
		ctx = nil
	end

	return api
end

return tracker_module
