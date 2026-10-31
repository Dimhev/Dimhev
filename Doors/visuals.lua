local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local core = game:GetService("CoreGui")

local lp = plrs.LocalPlayer

local vis = {}
local conns_dupe = {}
local active_dupe = false

local cfg = {
	door_esp = false,
	entity_esp = false,
	entity_notify = false,
	item_esp = false,
	gold_esp = false,
	tracers = false,
	door_color = Color3.fromRGB(0, 200, 255),
	entity_color = Color3.fromRGB(255, 65, 65),
	item_color = Color3.fromRGB(130, 255, 130),
	gold_color = Color3.fromRGB(255, 215, 0)
}

local notify_callback = nil
local active_highlights = 0
local max_highlights = 31
local render_conn = nil
local last_room_check = 0

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

local function alloc_highlight(adornee, color, fill_trans, outline_trans)
	if active_highlights >= max_highlights then return nil end
	local hl = Instance.new("Highlight")
	hl.Name = "vis_hl"
	hl.Adornee = adornee
	hl.FillColor = color
	hl.OutlineColor = color
	hl.FillTransparency = fill_trans or 0.7
	hl.OutlineTransparency = outline_trans or 0.15
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = gui_holder
	active_highlights = active_highlights + 1
	return hl
end

local function free_highlight(hl)
	if is_inst(hl) then
		hl:Destroy()
		active_highlights = math.max(0, active_highlights - 1)
	end
end

local tracer_service = {}

function tracer_service.create(col)
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

function tracer_service.destroy(tr)
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

function tracer_service.set_visible(tr, state)
	if not tr then return end
	pcall(function()
		tr.obj.Visible = state
	end)
end

function tracer_service.update(tr, from_pos, to_pos, col)
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

local ctx = {
	ws = ws,
	rs = rs,
	plrs = plrs,
	run = run,
	lp = lp,
	cfg = cfg,
	gui_holder = gui_holder,
	is_inst = is_inst,
	disconnect_list = disconnect_list,
	fire_notify = fire_notify,
	get_floor = get_floor,
	get_room_bounds = get_room_bounds,
	create_billboard = create_billboard,
	create_highlight = alloc_highlight,
	destroy_highlight = free_highlight,
	tracer = tracer_service
}

local base = "https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/components/"

local function load_component(name)
	local url = base .. name .. ".lua"
	local ok, res = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)
	res.init(ctx)
	return res
end

local doors_comp = load_component("doors")
local entities_comp = load_component("entities")
local items_comp = load_component("items")
local gold_comp = load_component("gold")

local function has_any_esp()
	return cfg.door_esp or cfg.entity_esp or cfg.item_esp or cfg.gold_esp
end

local function refresh_all()
	local min_r, max_r = get_room_bounds()
	if doors_comp then
		doors_comp.refresh(min_r, max_r)
	end
	if entities_comp then
		entities_comp.refresh(min_r, max_r)
	end
	if items_comp then
		items_comp.refresh(min_r, max_r)
	end
	if gold_comp then
		gold_comp.refresh(min_r, max_r)
	end
end

local function step_render()
	if not has_any_esp() then return end
	local cam = ws.CurrentCamera
	if not cam then return end

	local now = os.clock()
	if now - last_room_check > 0.4 then
		last_room_check = now
		if cfg.door_esp and doors_comp then
			doors_comp.scan_rooms()
		end
		if cfg.item_esp and items_comp then
			items_comp.scan_rooms()
		end
		if cfg.gold_esp and gold_comp then
			gold_comp.scan_rooms()
		end
		refresh_all()
	end

	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local vp = cam.ViewportSize
	local origin = Vector2.new(vp.X * 0.5, vp.Y)

	if cfg.door_esp and doors_comp then
		doors_comp.step(cam, root, origin)
	end
	if cfg.entity_esp and entities_comp then
		entities_comp.step(cam, root, origin)
	end
	if cfg.item_esp and items_comp then
		items_comp.step(cam, root, origin)
	end
	if cfg.gold_esp and gold_comp then
		gold_comp.step(cam, root, origin)
	end
end

local function update_render_loop()
	if has_any_esp() and not render_conn then
		render_conn = run.RenderStepped:Connect(step_render)
	elseif not has_any_esp() and render_conn then
		render_conn:Disconnect()
		render_conn = nil
	end
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

function vis.set_notifier(fn)
	notify_callback = fn
end

function vis.door_esp(state)
	cfg.door_esp = state
	if doors_comp then
		if state then
			doors_comp.start_tracking()
			refresh_all()
		else
			doors_comp.stop_tracking()
		end
	end
	update_render_loop()
end

function vis.entity_esp(state, notify_fn)
	if notify_fn then
		notify_callback = notify_fn
	end
	cfg.entity_esp = state
	if entities_comp then
		entities_comp.sync()
	end
	update_render_loop()
end

function vis.entity_notify(state, notify_fn)
	if notify_fn then
		notify_callback = notify_fn
	end
	cfg.entity_notify = state
	if entities_comp then
		entities_comp.sync()
	end
	update_render_loop()
end

function vis.item_esp(state)
	cfg.item_esp = state
	if items_comp then
		if state then
			items_comp.start_tracking()
			refresh_all()
		else
			items_comp.stop_tracking()
		end
	end
	update_render_loop()
end

function vis.gold_esp(state)
	cfg.gold_esp = state
	if gold_comp then
		if state then
			gold_comp.start_tracking()
			refresh_all()
		else
			gold_comp.stop_tracking()
		end
	end
	update_render_loop()
end

function vis.door_tracers(state)
	cfg.tracers = state
	refresh_all()
end

function vis.cleanup()
	vis.dupe(false)
	vis.door_esp(false)
	vis.entity_esp(false)
	vis.entity_notify(false)
	vis.item_esp(false)
	vis.gold_esp(false)

	if doors_comp then
		doors_comp.cleanup()
	end
	if entities_comp then
		entities_comp.cleanup()
	end
	if items_comp then
		items_comp.cleanup()
	end
	if gold_comp then
		gold_comp.cleanup()
	end

	if render_conn then
		render_conn:Disconnect()
		render_conn = nil
	end

	if is_inst(gui_holder) then
		gui_holder:Destroy()
	end
end

return vis
