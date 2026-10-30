local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local core = game:GetService("CoreGui")

local lp = plrs.LocalPlayer

local vis = {}
local conns_dupe = {}
local conns_door = {}
local active_dupe = false

local door_cfg = {
	esp = false,
	tracers = false,
	color = Color3.fromRGB(0, 200, 255)
}

local door_entries = {}
local active_highlights = 0
local max_highlights = 25
local render_conn = nil

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

local function disconnect_list(list)
	for _, c in ipairs(list) do
		if typeof(c) == "RBXScriptConnection" and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(list)
end

local function get_floor()
	local gd = rs:FindFirstChild("GameData")
	local fl = gd and gd:FindFirstChild("Floor")
	return fl and fl.Value or "Hotel"
end

local function get_current_room()
	local attr = tonumber(lp:GetAttribute("CurrentRoom"))
	if attr then return attr end
	local gd = rs:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom")
	return lr and lr.Value or 0
end

local function get_door_number(door_model, room_num)
	local num = (room_num or tonumber(door_model.Parent.Name) or 0) + 1
	local fl = get_floor()
	if fl == "Mines" then
		num = num + 100
	elseif fl == "Backdoor" then
		num = num - 50
	end
	return tostring(num)
end

local function get_door_target(door_model)
	local base = door_model:FindFirstChild("Door")
	if base and base:IsA("BasePart") then
		return base
	end
	if door_model.PrimaryPart then
		return door_model.PrimaryPart
	end
	return door_model:FindFirstChildWhichIsA("BasePart", true)
end

local function create_tracer()
	local ok, line = pcall(function()
		local d = Drawing.new("Line")
		d.Visible = false
		d.Thickness = 1
		d.Transparency = 0.85
		d.Color = door_cfg.color
		return d
	end)
	if ok and line then
		return { is_drawing = true, obj = line }
	end

	local f = Instance.new("Frame")
	f.BackgroundColor3 = door_cfg.color
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
		if tr.obj then
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

local function remove_door_entry(door_model)
	local entry = door_entries[door_model]
	if not entry then return end

	if entry.conn_destroy and entry.conn_destroy.Connected then
		entry.conn_destroy:Disconnect()
	end
	if entry.conn_lock and entry.conn_lock.Connected then
		entry.conn_lock:Disconnect()
	end
	if entry.hl then
		entry.hl:Destroy()
		entry.hl = nil
		active_highlights = math.max(0, active_highlights - 1)
	end
	if entry.billboard then
		entry.billboard:Destroy()
		entry.billboard = nil
	end
	destroy_tracer(entry.tracer)
	entry.tracer = nil

	door_entries[door_model] = nil
end

local function refresh_entry_visibility(entry, cur_room)
	local is_relevant = (entry.room_num == cur_room or entry.room_num == cur_room + 1)
	local show = door_cfg.esp and is_relevant and entry.target and entry.target.Parent ~= nil
	entry.visible = show

	if show then
		if not entry.billboard then
			local bb = Instance.new("BillboardGui")
			bb.Name = "door_tag"
			bb.Adornee = entry.target
			bb.Size = UDim2.fromOffset(140, 26)
			bb.AlwaysOnTop = true
			bb.ResetOnSpawn = false
			bb.Parent = gui_holder

			local lbl = Instance.new("TextLabel")
			lbl.Name = "label"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.Gotham
			lbl.TextSize = 13
			lbl.TextColor3 = door_cfg.color
			lbl.TextStrokeTransparency = 0.45
			lbl.TextStrokeColor3 = Color3.fromRGB(15, 15, 15)
			lbl.Text = entry.base_text
			lbl.Parent = bb

			entry.billboard = bb
			entry.label = lbl
		end
		entry.billboard.Enabled = true
		entry.label.TextColor3 = door_cfg.color

		if not entry.hl and active_highlights < max_highlights then
			local hl = Instance.new("Highlight")
			hl.Name = "door_hl"
			hl.Adornee = entry.model
			hl.FillColor = door_cfg.color
			hl.OutlineColor = door_cfg.color
			hl.FillTransparency = 0.78
			hl.OutlineTransparency = 0.15
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = gui_holder
			entry.hl = hl
			active_highlights = active_highlights + 1
		elseif entry.hl then
			entry.hl.FillColor = door_cfg.color
			entry.hl.OutlineColor = door_cfg.color
			entry.hl.Enabled = true
		end

		if door_cfg.tracers and not entry.tracer then
			entry.tracer = create_tracer()
		elseif not door_cfg.tracers and entry.tracer then
			set_tracer_visible(entry.tracer, false)
		end
	else
		if entry.billboard then
			entry.billboard.Enabled = false
		end
		if entry.hl then
			entry.hl:Destroy()
			entry.hl = nil
			active_highlights = math.max(0, active_highlights - 1)
		end
		if entry.tracer then
			set_tracer_visible(entry.tracer, false)
		end
	end
end

local function refresh_all_doors()
	local cur_room = get_current_room()
	for model, entry in pairs(door_entries) do
		if not model.Parent then
			remove_door_entry(model)
		else
			refresh_entry_visibility(entry, cur_room)
		end
	end
end

local function update_door_text(entry)
	local locked = entry.model:FindFirstChild("Lock") ~= nil
	local suffix = locked and " [locked]" or ""
	entry.base_text = "Door " .. entry.door_num .. suffix
end

local function register_door(door_model)
	if door_entries[door_model] then return end
	if door_model.Name ~= "Door" or not door_model.Parent then return end

	local room_num = tonumber(door_model.Parent.Name)
	if not room_num then return end

	local target = get_door_target(door_model)
	if not target then return end

	local entry = {
		model = door_model,
		target = target,
		room_num = room_num,
		door_num = get_door_number(door_model, room_num),
		base_text = "",
		visible = false
	}

	update_door_text(entry)

	entry.conn_lock = door_model.ChildRemoved:Connect(function(ch)
		if ch.Name == "Lock" then
			update_door_text(entry)
		end
	end)

	entry.conn_destroy = door_model.Destroying:Once(function()
		remove_door_entry(door_model)
	end)

	door_entries[door_model] = entry
	refresh_entry_visibility(entry, get_current_room())
end

local function step_render()
	if not door_cfg.esp then return end
	local cam = ws.CurrentCamera
	if not cam then return end

	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local vp = cam.ViewportSize
	local origin = Vector2.new(vp.X * 0.5, vp.Y)

	for model, entry in pairs(door_entries) do
		if not model.Parent or not entry.target or not entry.target.Parent then
			remove_door_entry(model)
		elseif entry.visible then
			local pos = entry.target.Position
			if entry.label then
				if root then
					local dist = math.floor((root.Position - pos).Magnitude)
					entry.label.Text = entry.base_text .. " [" .. tostring(dist) .. "m]"
				else
					entry.label.Text = entry.base_text
				end
			end

			if door_cfg.tracers and entry.tracer then
				local screen_pos, on_screen = cam:WorldToViewportPoint(pos)
				if on_screen and screen_pos.Z > 0 then
					update_tracer(entry.tracer, origin, Vector2.new(screen_pos.X, screen_pos.Y), door_cfg.color)
				else
					set_tracer_visible(entry.tracer, false)
				end
			elseif entry.tracer then
				set_tracer_visible(entry.tracer, false)
			end
		end
	end
end

local function start_door_tracking()
	disconnect_list(conns_door)
	local rooms = ws:FindFirstChild("CurrentRooms")
	if not rooms then return end

	for _, room in ipairs(rooms:GetChildren()) do
		local d = room:FindFirstChild("Door")
		if d then
			register_door(d)
		end
	end

	table.insert(conns_door, rooms.ChildAdded:Connect(function(room)
		task.defer(function()
			local d = room:WaitForChild("Door", 5)
			if d and door_cfg.esp then
				register_door(d)
				refresh_all_doors()
			end
		end)
	end))

	table.insert(conns_door, rooms.ChildRemoved:Connect(function(room)
		for model, entry in pairs(door_entries) do
			if entry.room_num == tonumber(room.Name) or not model:IsDescendantOf(rooms) then
				remove_door_entry(model)
			end
		end
	end))

	table.insert(conns_door, lp:GetAttributeChangedSignal("CurrentRoom"):Connect(refresh_all_doors))

	local gd = rs:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom")
	if lr then
		table.insert(conns_door, lr:GetPropertyChangedSignal("Value"):Connect(refresh_all_doors))
	end

	if not render_conn then
		render_conn = run.RenderStepped:Connect(step_render)
	end
end

local function stop_door_tracking()
	disconnect_list(conns_door)
	if render_conn then
		render_conn:Disconnect()
		render_conn = nil
	end
	for model in pairs(door_entries) do
		remove_door_entry(model)
	end
end

function vis.door_esp(state)
	door_cfg.esp = state
	if state then
		start_door_tracking()
		refresh_all_doors()
	else
		stop_door_tracking()
	end
end

function vis.door_tracers(state)
	door_cfg.tracers = state
	if door_cfg.esp then
		refresh_all_doors()
	end
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
	vis.door_esp(false)
	if gui_holder then
		gui_holder:Destroy()
	end
end

return vis
