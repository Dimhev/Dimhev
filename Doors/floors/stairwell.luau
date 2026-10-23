local stairwell = {}

local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local core_gui = game:GetService("CoreGui")
local local_player = players.LocalPlayer

-- состояния и переменные модуля
local state = {
	bypass_noise = false,
	dropped_item_value = false,
	kill_all_with_cart = false,
	fling_creak = false,
	creak_aggression_meter = false,
	disable_crushers = false,
	delete_crushers = false,
	remove_meld = false,
	landing_spam = false,
	landing_token = 0,
	shopping_cart_target = local_player and local_player.Name or "",
	bring_interval_enabled = false,
	bring_interval_running = false,
	bring_interval_time = 1,
	orbit_enabled = false,
	orbit_height = 2,
	orbit_distance = 5,
	orbit_speed = 2,
	orbit_angle = 0,
	orbit_last_tp = 0,
	orbit_pause_until = 0
}

local connections = {
	bypass_noise = nil,
	creak_child_added = nil,
	orbit_heartbeat = nil
}

local creak_meters_table = {}

-- 1. сломать телевизор noise (noise tv breaker)
function stairwell.bypass_noise(val)
	state.bypass_noise = val

	if connections.bypass_noise then
		connections.bypass_noise:Disconnect()
		connections.bypass_noise = nil
	end

	if not val then return end

	local function check_tv_stand(target_tv)
		if not target_tv:IsA("Model") then return end
		if target_tv.Name ~= "TV_Stand" then return end

		local current_cf = target_tv:GetPivot()
		if current_cf.Position.Y > -119 then
			target_tv:PivotTo(CFrame.new(
				current_cf.Position.X,
				-120,
				current_cf.Position.Z
			))
		end
	end

	local misc_folder = workspace:FindFirstChild("Misc")
	if not misc_folder then return end

	connections.bypass_noise = misc_folder.ChildAdded:Connect(function(new_child)
		if state.bypass_noise then
			check_tv_stand(new_child)
		end
	end)

	for _, child in ipairs(misc_folder:GetChildren()) do
		check_tv_stand(child)
	end
end

-- 2. счётчик выброшенных предметов (item number)
function stairwell.dropped_item_value(val)
	state.dropped_item_value = val

	local existing_gui = core_gui:FindFirstChild("DropsCoinCounter")
	if existing_gui then
		existing_gui:Destroy()
	end

	if not val then return end

	local drops_folder = workspace:WaitForChild("Drops", 5)
	if not drops_folder then return end

	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "DropsCoinCounter"
	screen_gui.ResetOnSpawn = false
	screen_gui.Parent = core_gui

	local coin_text = Instance.new("TextLabel")
	coin_text.Name = "CoinText"
	coin_text.AnchorPoint = Vector2.new(0.5, 0)
	coin_text.Position = UDim2.new(0.5, 0, 0.02, 0)
	coin_text.Size = UDim2.new(0, 250, 0, 40)
	coin_text.BackgroundTransparency = 1
	coin_text.Text = "Items: 0"
	coin_text.TextSize = 24
	coin_text.Font = Enum.Font.GothamBold
	coin_text.TextColor3 = Color3.fromRGB(255, 255, 255)
	coin_text.TextStrokeTransparency = 0.5
	coin_text.Parent = screen_gui

	local counted_drops = {}

	task.spawn(function()
		while state.dropped_item_value do
			for _, drop in ipairs(drops_folder:GetChildren()) do
				if drop:IsA("Model") and not counted_drops[drop] then
					drop:SetAttribute("CoinsChecked", true)
					counted_drops[drop] = true
				end
			end

			for drop in pairs(counted_drops) do
				if not drop.Parent or drop.Parent ~= drops_folder then
					counted_drops[drop] = nil
				end
			end

			local total_items = 0
			for drop in pairs(counted_drops) do
				if drop.Parent == drops_folder then
					total_items += 1
				end
			end

			if coin_text and coin_text.Parent then
				coin_text.Text = "Items: " .. total_items
			end
			task.wait(1)
		end

		if screen_gui and screen_gui.Parent then
			screen_gui:Destroy()
		end
	end)
end

-- 3. убить всех тележками (kill all with cart)
function stairwell.kill_all_with_cart(val)
	state.kill_all_with_cart = val
	if not val then return end

	local target_index = 1

	task.spawn(function()
		while state.kill_all_with_cart do
			local misc_folder = workspace:FindFirstChild("Misc")
			local carts = {}

			if misc_folder then
				for _, model in ipairs(misc_folder:GetChildren()) do
					if model.Name == "ShoppingCart" and model:IsA("Model") then
						carts[#carts + 1] = model
					end
				end
			end

			local alive_players = {}
			for _, plr in ipairs(players:GetPlayers()) do
				if plr ~= local_player and plr.Character then
					local hum = plr.Character:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 then
						alive_players[#alive_players + 1] = plr
					end
				end
			end

			if #carts > 0 and #alive_players > 0 then
				if target_index > #alive_players then
					target_index = 1
				end
				local target_plr = alive_players[target_index]
				if target_plr and target_plr.Character then
					local target_cf = target_plr.Character:GetPivot()
					for i = 1, #carts do
						carts[i]:PivotTo(target_cf)
					end
				end
				target_index += 1
			end

			task.wait(0.10)
		end
	end)
end

-- 4. забагать сущность creak тележками (fling creak)
function stairwell.fling_creak(val)
	state.fling_creak = val
	if not val then return end

	task.spawn(function()
		while state.fling_creak do
			local live_entities = workspace:FindFirstChild("LiveEntities")
			local creak = live_entities and live_entities:FindFirstChild("Creak")
			local misc_folder = workspace:FindFirstChild("Misc")

			if creak and misc_folder then
				local target_cf = creak:GetPivot()
				for _, model in ipairs(misc_folder:GetChildren()) do
					if model.Name == "ShoppingCart" and model:IsA("Model") then
						model:PivotTo(target_cf)
					end
				end
			end
			task.wait(0.10)
		end
	end)
end

-- 5. индикатор агрессии creak (creak aggression meter)
local function cleanup_creak_meter(creak_model)
	local meter_data = creak_meters_table[creak_model]
	if not meter_data then return end

	creak_meters_table[creak_model] = nil

	if meter_data.render_conn then
		meter_data.render_conn:Disconnect()
	end
	if meter_data.destroy_conn then
		meter_data.destroy_conn:Disconnect()
	end

	for _, drawing_obj in ipairs(meter_data.drawings) do
		pcall(function() drawing_obj:Remove() end)
	end
end

local function get_creak_aggression(creak_model)
	local animator = creak_model:FindFirstChildOfClass("Animator")
		or (creak_model:FindFirstChild("AnimationController") and creak_model.AnimationController:FindFirstChildOfClass("Animator"))
		or creak_model:FindFirstChildOfClass("AnimationController")

	if not animator then return nil end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Name == "CreakGraph" or (track.Animation and track.Animation.Name == "CreakGraph") then
			local ok, val = pcall(track.GetParameter, track, "Aggression")
			if ok and typeof(val) == "number" then
				return math.clamp(val, 0, 1)
			end
		end
	end
	return nil
end

local function create_creak_drawings()
	local list = {}

	local function make_drawing(dtype)
		local obj = Drawing.new(dtype)
		table.insert(list, obj)
		return obj
	end

	local title_text = make_drawing("Text")
	title_text.Text = "Aggression --%"
	title_text.Size = 16
	title_text.Font = Drawing.Fonts.Plex
	title_text.Color = Color3.fromRGB(255, 255, 255)
	title_text.Center = true
	title_text.Outline = true
	title_text.Visible = false

	local bar_bg = make_drawing("Square")
	bar_bg.Size = Vector2.new(112, 6)
	bar_bg.Filled = true
	bar_bg.Color = Color3.fromRGB(58, 58, 64)
	bar_bg.Transparency = 0.15
	bar_bg.Visible = false

	local bar_fill = make_drawing("Square")
	bar_fill.Size = Vector2.new(0, 6)
	bar_fill.Filled = true
	bar_fill.Visible = false

	return {
		drawings = list,
		title_text = title_text,
		bar_bg = bar_bg,
		bar_fill = bar_fill
	}
end

local function add_creak_meter(creak_model)
	if not state.creak_aggression_meter or creak_model.Name ~= "Creak" or creak_meters_table[creak_model] then
		return
	end
	if not Drawing then return end

	local head_part = creak_model:FindFirstChild("Head")
	if not head_part or not head_part:IsA("BasePart") then return end

	local meter_data = create_creak_drawings()
	creak_meters_table[creak_model] = meter_data

	meter_data.render_conn = run_service.RenderStepped:Connect(function()
		if not state.creak_aggression_meter or not creak_model.Parent or not head_part.Parent then
			cleanup_creak_meter(creak_model)
			return
		end

		local cam = workspace.CurrentCamera
		if not cam then return end

		local screen_pos, on_screen = cam:WorldToViewportPoint(head_part.Position + Vector3.new(0, 1.85, 0))
		if not (on_screen and screen_pos.Z > 0) then
			meter_data.title_text.Visible = false
			meter_data.bar_bg.Visible = false
			meter_data.bar_fill.Visible = false
			return
		end

		meter_data.title_text.Position = Vector2.new(screen_pos.X, screen_pos.Y - 28)
		meter_data.bar_bg.Position = Vector2.new(screen_pos.X - 56, screen_pos.Y - 6)
		meter_data.bar_fill.Position = meter_data.bar_bg.Position

		local aggr_val = get_creak_aggression(creak_model)
		if not aggr_val then
			meter_data.title_text.Text = "Aggression --%"
			meter_data.title_text.Color = Color3.fromRGB(200, 200, 200)
			meter_data.bar_fill.Size = Vector2.new(0, 6)
			meter_data.title_text.Visible = true
			meter_data.bar_bg.Visible = true
			meter_data.bar_fill.Visible = false
			return
		end

		meter_data.title_text.Text = "Aggression " .. math.floor(aggr_val * 100 + 0.5) .. "%"
		meter_data.title_text.Color = Color3.fromRGB(255, 255, 255)
		meter_data.bar_fill.Size = Vector2.new(112 * aggr_val, 6)
		meter_data.bar_fill.Color = Color3.fromRGB(70, 220, 100):Lerp(Color3.fromRGB(255, 55, 55), aggr_val)
		meter_data.title_text.Visible = true
		meter_data.bar_bg.Visible = true
		meter_data.bar_fill.Visible = true
	end)

	meter_data.destroy_conn = creak_model.Destroying:Connect(function()
		cleanup_creak_meter(creak_model)
	end)
end

function stairwell.creak_aggression_meter(val)
	state.creak_aggression_meter = val

	if connections.creak_child_added then
		connections.creak_child_added:Disconnect()
		connections.creak_child_added = nil
	end

	if val then
		local live_entities = workspace:FindFirstChild("LiveEntities")
		if live_entities then
			local existing = live_entities:FindFirstChild("Creak")
			if existing then
				add_creak_meter(existing)
			end
			connections.creak_child_added = live_entities.ChildAdded:Connect(function(child)
				if child.Name == "Creak" then
					add_creak_meter(child)
				end
			end)
		end
	else
		for model in pairs(creak_meters_table) do
			cleanup_creak_meter(model)
		end
	end
end

-- 6. отключить коллизию прессов (disable crushers)
function stairwell.disable_crushers(val)
	state.disable_crushers = val
	if not val then return end

	task.spawn(function()
		while state.disable_crushers do
			local current_rooms = workspace:FindFirstChild("CurrentRooms")
			if current_rooms then
				for _, room in ipairs(current_rooms:GetChildren()) do
					local assets = room:FindFirstChild("Assets")
					if assets then
						for _, container in ipairs(assets:GetChildren()) do
							if container.Name == "StairwellCrusherContainer1" then
								for _, desc in ipairs(container:GetDescendants()) do
									if desc:IsA("BasePart") and desc.CanCollide then
										local under_basic_wall = false
										local parent = desc.Parent
										while parent and parent ~= container do
											if parent.Name == "BasicWall" then
												under_basic_wall = true
												break
											end
											parent = parent.Parent
										end
										if not under_basic_wall then
											desc.CanCollide = false
										end
									end
								end
							end

							local crusher = container:FindFirstChild("StairwellCrusher")
							if crusher then
								local outer_trigger = crusher:FindFirstChild("OuterTrigger")
								local core_trigger = crusher:FindFirstChild("CoreTrigger")
								if outer_trigger then outer_trigger:Destroy() end
								if core_trigger then core_trigger:Destroy() end
							end
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

-- 7. удалить прессы кроме стен (delete crushers)
function stairwell.delete_crushers(val)
	state.delete_crushers = val
	if not val then return end

	task.spawn(function()
		while state.delete_crushers do
			local current_rooms = workspace:FindFirstChild("CurrentRooms")
			if current_rooms then
				for _, room in ipairs(current_rooms:GetChildren()) do
					local assets = room:FindFirstChild("Assets")
					if assets then
						for _, container in ipairs(assets:GetChildren()) do
							if container.Name == "StairwellCrusherContainer1" then
								local to_destroy = {}
								for _, desc in ipairs(container:GetDescendants()) do
									local under_basic_wall = false
									local parent = desc.Parent
									while parent and parent ~= container do
										if parent.Name == "BasicWall" then
											under_basic_wall = true
											break
										end
										parent = parent.Parent
									end
									if not under_basic_wall and desc.Name ~= "BasicWall" then
										to_destroy[#to_destroy + 1] = desc
									end
								end
								for _, inst in ipairs(to_destroy) do
									if inst and inst.Parent then
										inst:Destroy()
									end
								end
							end
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

-- 8. удалить meld (remove meld)
function stairwell.remove_meld(val)
	state.remove_meld = val
	if not val then return end

	task.spawn(function()
		while state.remove_meld do
			local current_rooms = workspace:FindFirstChild("CurrentRooms")
			if current_rooms then
				for _, room in pairs(current_rooms:GetChildren()) do
					for _, folder_name in ipairs({"Assets", "Parts"}) do
						local folder = room:FindFirstChild(folder_name)
						if folder then
							for _, child in ipairs(folder:GetChildren()) do
								if child.Name == "MeldWall" or child.Name == "Boleahghth29tdgfhy2thuy2htuu259uhh3u" then
									child:Destroy()
								end
							end
						end
					end
					for _, name in ipairs({"MeldData", "MeldPads", "Meldview", "Meld"}) do
						local obj = room:FindFirstChild(name)
						if obj and obj:IsA("Folder") then
							obj:Destroy()
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

-- 9. телепорт к мусору и сброс (tp to trash and drop trash)
function stairwell.landing_spam(val)
	state.landing_spam = val
	state.landing_token += 1

	if not val then return end

	local current_token = state.landing_token

	task.spawn(function()
		while state.landing_spam and current_token == state.landing_token do
			local current_rooms = workspace:FindFirstChild("CurrentRooms")
			local stairwell_models = {}

			if current_rooms then
				for _, room in ipairs(current_rooms:GetChildren()) do
					local landing_logic = room:FindFirstChild("StairwellLandingLogic")
					if landing_logic then
						for _, model in ipairs(landing_logic:GetChildren()) do
							if model:IsA("Model") then
								local prompts = {}
								for _, obj in ipairs(model:GetDescendants()) do
									if obj:IsA("ProximityPrompt") then
										prompts[#prompts + 1] = obj
									end
								end
								if #prompts > 0 then
									stairwell_models[#stairwell_models + 1] = {
										model = model,
										prompts = prompts
									}
								end
							end
						end
					end
				end
			end

			table.sort(stairwell_models, function(first, second)
				local first_room = first.model.Parent and first.model.Parent.Parent
				local second_room = second.model.Parent and second.model.Parent.Parent
				return (tonumber(first_room and first_room.Name) or math.huge) <
					(tonumber(second_room and second_room.Name) or math.huge)
			end)

			for _, data in ipairs(stairwell_models) do
				if not state.landing_spam or current_token ~= state.landing_token then
					break
				end

				local model = data.model

				while model.Parent
					and model:IsDescendantOf(workspace)
					and state.landing_spam
					and current_token == state.landing_token do

					local char = local_player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")

					if hrp then
						hrp.CFrame = model:GetPivot() + Vector3.new(0, 5, 0)

						for i = 1, #data.prompts do
							local prompt = data.prompts[i]
							if prompt.Parent and prompt.Enabled and fireproximityprompt then
								fireproximityprompt(prompt)
							end
						end

						if keypress and keyrelease then
							keypress(0x58)
							task.wait(0.03)
							keyrelease(0x58)
						end
					end

					run_service.Heartbeat:Wait()
				end
			end

			run_service.Heartbeat:Wait()
		end
	end)
end

-- 10. управление тележками (tp shopping carts to player)
function stairwell.set_shopping_cart_target(name)
	state.shopping_cart_target = name
end

function stairwell.tp_shopping_carts_to_player(target_name)
	local name_to_find = target_name or state.shopping_cart_target
	local target_player = players:FindFirstChild(name_to_find) or local_player
	if not target_player or not target_player.Character then return end

	local target_cf = target_player.Character:GetPivot()
	local misc_folder = workspace:FindFirstChild("Misc")
	if not misc_folder then return end

	for _, cart_model in ipairs(misc_folder:GetChildren()) do
		if cart_model.Name == "ShoppingCart" and cart_model:IsA("Model") then
			cart_model:PivotTo(target_cf)
		end
	end
end

-- 11. телепорт всех предметов к ближайшему измельчителю (tp all drops to nearest grinder)
function stairwell.tp_drops_to_nearest_grinder()
	local drops_folder = workspace:FindFirstChild("Drops")
	local char = local_player and local_player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local current_rooms = workspace:FindFirstChild("CurrentRooms")

	if not drops_folder or not hrp or not current_rooms then return end

	local player_pos = hrp.Position
	local nearest_grinder = nil
	local nearest_dist = math.huge

	for _, room in ipairs(current_rooms:GetChildren()) do
		local scrapper = room:FindFirstChild("StairwellScrapper", true)
		if scrapper then
			for _, obj in ipairs(scrapper:GetDescendants()) do
				if obj.Name == "Grinder1" and (obj:IsA("Model") or obj:IsA("BasePart")) then
					local pos = obj:GetPivot().Position
					local dist = (player_pos - pos).Magnitude
					if dist < nearest_dist then
						nearest_dist = dist
						nearest_grinder = obj
					end
				end
			end
		end
	end

	if not nearest_grinder then return end
	local grinder_cf = nearest_grinder:GetPivot()

	for _, drop_item in ipairs(drops_folder:GetChildren()) do
		if drop_item:IsA("Model") or drop_item:IsA("BasePart") then
			drop_item:PivotTo(grinder_cf)
		end
	end
end

-- 12. притянуть выброшенные предметы к себе (bring dropped items & interval)
function stairwell.bring_dropped_items()
	local drops_folder = workspace:FindFirstChild("Drops")
	local char = local_player and local_player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if hrp and drops_folder then
		for _, item in ipairs(drops_folder:GetChildren()) do
			if item:IsA("Model") then
				item:PivotTo(hrp.CFrame)
			elseif item:IsA("BasePart") then
				item.CFrame = hrp.CFrame
			end
		end
	end
end

function stairwell.set_dropped_items_interval(val)
	state.bring_interval_time = val
end

function stairwell.enable_dropped_items_interval(val)
	state.bring_interval_enabled = val
	if val then
		if state.bring_interval_running then return end
		state.bring_interval_running = true
		task.spawn(function()
			while state.bring_interval_enabled do
				stairwell.bring_dropped_items()
				local interval = state.bring_interval_time
				if interval <= 0 then
					task.wait()
				else
					task.wait(interval)
				end
			end
			state.bring_interval_running = false
		end)
	end
end

-- 13. вращение предметов вокруг игрока (orbit dropped items)
function stairwell.set_orbit_height(val)
	state.orbit_height = val
end

function stairwell.set_orbit_distance(val)
	state.orbit_distance = val
end

function stairwell.set_orbit_speed(val)
	state.orbit_speed = val
end

function stairwell.orbit_dropped_items(val)
	state.orbit_enabled = val

	if connections.orbit_heartbeat then
		connections.orbit_heartbeat:Disconnect()
		connections.orbit_heartbeat = nil
	end

	if not val then return end

	state.orbit_angle = 0
	state.orbit_last_tp = tick()
	state.orbit_pause_until = 0

	connections.orbit_heartbeat = run_service.Heartbeat:Connect(function(dt)
		if not local_player or not local_player.Character then return end
		local hrp = local_player.Character:FindFirstChild("HumanoidRootPart")
		local drops_folder = workspace:FindFirstChild("Drops")
		if not hrp or not drops_folder then return end

		local current_time = tick()
		local items_list = {}

		for _, obj in ipairs(drops_folder:GetChildren()) do
			if obj:IsA("Model") or obj:IsA("BasePart") then
				items_list[#items_list + 1] = obj
			end
		end

		local count = #items_list
		if count == 0 then return end

		if current_time - state.orbit_last_tp >= 10 then
			state.orbit_last_tp = current_time
			state.orbit_pause_until = current_time + 2
			local center_pos = hrp.Position
			for _, obj in ipairs(items_list) do
				if obj:IsA("Model") then
					obj:PivotTo(CFrame.new(center_pos))
				else
					obj.CFrame = CFrame.new(center_pos)
				end
			end
		end

		if current_time < state.orbit_pause_until then return end

		state.orbit_angle += dt * state.orbit_speed
		for idx, obj in ipairs(items_list) do
			local obj_angle = state.orbit_angle + ((idx - 1) / count) * math.pi * 2
			local offset = Vector3.new(
				math.cos(obj_angle) * state.orbit_distance,
				state.orbit_height,
				math.sin(obj_angle) * state.orbit_distance
			)
			local target_pos = hrp.Position + offset
			if obj:IsA("Model") then
				obj:PivotTo(CFrame.new(target_pos))
			else
				obj.CFrame = CFrame.new(target_pos)
			end
		end
	end)
end

-- 14. очистка при выгрузке скрипта (cleanup)
function stairwell.cleanup()
	stairwell.bypass_noise(false)
	stairwell.dropped_item_value(false)
	stairwell.kill_all_with_cart(false)
	stairwell.fling_creak(false)
	stairwell.creak_aggression_meter(false)
	stairwell.disable_crushers(false)
	stairwell.delete_crushers(false)
	stairwell.remove_meld(false)
	stairwell.landing_spam(false)
	stairwell.enable_dropped_items_interval(false)
	stairwell.orbit_dropped_items(false)
end

return stairwell
