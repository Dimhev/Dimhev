local plrs = game:GetService("Players")
local rep = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local ws = game:GetService("Workspace")
local lp = plrs.LocalPlayer

local remotes = rep:WaitForChild("RemotesFolder")
local screech_rem = remotes:WaitForChild("Screech")
local crouch_rem = remotes:FindFirstChild("Crouch")
local real_motor = remotes:FindFirstChild("MotorReplication_Real") or remotes:WaitForChild("MotorReplication")
local fake_motor = nil

local gd = rep:FindFirstChild("GameData")
local floor_val = gd and gd:FindFirstChild("Floor")
local is_old = floor_val and (floor_val.Value == "Fools" or floor_val.Value == "OldHotel")

local ign = {}
local conns_a90 = {}
local conns_screech = {}
local conns_giggle = {}
local conns_snare = {}
local conns_dupe = {}
local conns_eyes = {}
local conns_speed = {}
local conns_rush = {}

local active_a90 = false
local active_screech = false
local active_giggle = false
local active_snare = false
local active_dupe = false
local active_eyes = false
local active_speed = false
local active_rush = false

local speed_boost = 15
local MIN_BOOST = 0
local MAX_BOOST = 50

local col_clone = nil
local col_part_clone = nil
local original_c1 = nil

local function disconnect_list(list)
	for _, c in ipairs(list) do
		if typeof(c) == "RBXScriptConnection" and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(list)
end

local function is_crouching(char)
	if not char then return false end
	local col = char:FindFirstChild("CollisionPart") or char:FindFirstChild("Collision")
	return (col and col.CollisionGroup == "PlayerCrouching") or false
end

local function get_a90_frame()
	local pgui = lp:FindFirstChild("PlayerGui")
	local mui = pgui and pgui:FindFirstChild("MainUI")
	local jmp = mui and mui:FindFirstChild("Jumpscare")
	return jmp and jmp:FindFirstChild("Jumpscare_A90")
end

function ign.a90(state)
	active_a90 = state
	disconnect_list(conns_a90)
	
	if active_a90 then
		lp:SetAttribute("Invincibility", true)
		local frame = get_a90_frame()
		if frame then
			frame.Visible = false
			local c = frame:GetPropertyChangedSignal("Visible"):Connect(function()
				if active_a90 and frame.Visible then
					frame.Visible = false
				end
			end)
			table.insert(conns_a90, c)
		end
	else
		lp:SetAttribute("Invincibility", nil)
		local frame = get_a90_frame()
		if frame then
			frame.Visible = false
		end
	end
end

local function get_screech_module()
	local pgui = lp:FindFirstChild("PlayerGui")
	local rl = pgui and pgui:FindFirstChild("MainUI")
	rl = rl and rl:FindFirstChild("Initiator")
	rl = rl and rl:FindFirstChild("Main_Game")
	rl = rl and rl:FindFirstChild("RemoteListener")
	local mods = rl and rl:FindFirstChild("Modules")
	return mods and mods:FindFirstChild("Screech")
end

function ign.screech(state)
	active_screech = state
	disconnect_list(conns_screech)
	
	local smod = get_screech_module()
	
	if active_screech then
		if smod then
			smod:SetAttribute("Static", true)
		end
		
		local c1 = screech_rem.OnClientEvent:Connect(function()
			if active_screech then
				screech_rem:FireServer(true)
			end
		end)
		table.insert(conns_screech, c1)
		
		local function hook_camera(cam)
			if not cam then return end
			local c = cam.ChildAdded:Connect(function(child)
				if active_screech and (child.Name == "Screech" or child.Name == "ScreechRetro") then
					task.defer(function()
						child:Destroy()
					end)
				end
			end)
			table.insert(conns_screech, c)
		end
		
		hook_camera(ws.CurrentCamera)
		
		local c2 = ws:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			if active_screech then
				hook_camera(ws.CurrentCamera)
			end
		end)
		table.insert(conns_screech, c2)
	else
		if smod then
			smod:SetAttribute("Static", nil)
		end
	end
end

local function disable_giggle(inst)
	if not inst then return end
	local hb = inst.Name == "Hitbox" and inst or inst:FindFirstChild("Hitbox", true)
	if hb and hb:IsA("BasePart") and not hb:GetAttribute("GiggleDisabled") then
		hb:SetAttribute("GiggleDisabled", true)
		hb.CanTouch = false
	end
end

function ign.giggle(state)
	active_giggle = state
	disconnect_list(conns_giggle)

	if active_giggle then
		local rooms = ws:FindFirstChild("CurrentRooms") or ws

		for _, inst in ipairs(rooms:GetDescendants()) do
			if not active_giggle then break end
			if inst.Name == "GiggleCeiling" or (inst.Name == "Hitbox" and inst:FindFirstAncestor("GiggleCeiling")) then
				disable_giggle(inst)
			end
		end

		local c = (ws:FindFirstChild("CurrentRooms") or ws).DescendantAdded:Connect(function(inst)
			if active_giggle and (inst.Name == "GiggleCeiling" or (inst.Name == "Hitbox" and inst:FindFirstAncestor("GiggleCeiling"))) then
				disable_giggle(inst)
			end
		end)
		table.insert(conns_giggle, c)
	end
end

local function disable_snare(inst)
	if not inst then return end
	local hb = inst.Name == "Hitbox" and inst or inst:FindFirstChild("Hitbox", true)
	if hb and hb:IsA("BasePart") and not hb:GetAttribute("SnareDisabled") then
		hb:SetAttribute("SnareDisabled", true)
		hb.CanTouch = false
	end
end

function ign.snare(state)
	active_snare = state
	disconnect_list(conns_snare)

	if active_snare then
		local rooms = ws:FindFirstChild("CurrentRooms") or ws
		for _, inst in ipairs(rooms:GetDescendants()) do
			if not active_snare then break end
			if inst.Name == "Snare" or (inst.Name == "Hitbox" and inst:FindFirstAncestor("Snare")) then
				disable_snare(inst)
			end
		end

		local c = (ws:FindFirstChild("CurrentRooms") or ws).DescendantAdded:Connect(function(inst)
			if active_snare and (inst.Name == "Snare" or inst.Name == "Hitbox") then
				disable_snare(inst)
			end
		end)
		table.insert(conns_snare, c)
	end
end

local function disable_dupe(inst)
	if not inst then return end
	local door = nil
	if inst.Name == "DoorFake" or inst.Name == "FakeDoor" then
		door = inst
	elseif inst.Name == "Hidden" and inst.Parent and (inst.Parent.Name == "DoorFake" or inst.Parent.Name == "FakeDoor") then
		door = inst.Parent
	end

	if door then
		local hidden = door:FindFirstChild("Hidden")
		if hidden and hidden:IsA("BasePart") and not hidden:GetAttribute("DupeDisabled") then
			hidden:SetAttribute("DupeDisabled", true)
			hidden.CanTouch = false
		end
	end
end

function ign.dupe(state)
	active_dupe = state
	disconnect_list(conns_dupe)

	local rooms = ws:FindFirstChild("CurrentRooms") or ws

	if active_dupe then
		for _, inst in ipairs(rooms:GetDescendants()) do
			if not active_dupe then break end
			if inst.Name == "DoorFake" or inst.Name == "FakeDoor" or inst.Name == "Hidden" then
				disable_dupe(inst)
			end
		end

		local c = rooms.DescendantAdded:Connect(function(inst)
			if active_dupe and (inst.Name == "DoorFake" or inst.Name == "FakeDoor" or inst.Name == "Hidden") then
				disable_dupe(inst)
			end
		end)
		table.insert(conns_dupe, c)
	else
		for _, inst in ipairs(rooms:GetDescendants()) do
			if inst.Name == "Hidden" and inst.Parent and (inst.Parent.Name == "DoorFake" or inst.Parent.Name == "FakeDoor") then
				if inst:IsA("BasePart") and inst:GetAttribute("DupeDisabled") then
					inst:SetAttribute("DupeDisabled", nil)
					inst.CanTouch = true
				end
			end
		end
	end
end

local function get_eyes()
	return ws:FindFirstChild("Eyes")
		or ws:FindFirstChild("Lookman")
		or ws:FindFirstChild("BackdoorLookman")
end

local function is_eyes_visible(inst)
	if not inst then return false end
	local part = inst:FindFirstChild("Core") or inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
	if not part then return false end
	local cam = ws.CurrentCamera
	if not cam then return false end
	local pos, on_screen = cam:WorldToViewportPoint(part.Position)
	return on_screen and pos.Z > 0
end

function ign.eyes(state)
	active_eyes = state
	disconnect_list(conns_eyes)

	if active_eyes then
		if not fake_motor and real_motor.Name == "MotorReplication" then
			fake_motor = Instance.new("RemoteEvent")
			fake_motor.Name = "MotorReplication"
			real_motor.Name = "MotorReplication_Real"
			fake_motor.Parent = remotes
		end

		local c = run.RenderStepped:Connect(function()
			if active_eyes then
				local e = get_eyes()
				if e and is_eyes_visible(e) then
					for _ = 1, 2 do
						if is_old then
							real_motor:FireServer(0, -90, 0, false)
						else
							real_motor:FireServer(-650)
						end
					end
				end
			end
		end)
		table.insert(conns_eyes, c)
	else
		if fake_motor then
			fake_motor:Destroy()
			fake_motor = nil
			if real_motor then
				real_motor.Name = "MotorReplication"
			end
		end
	end
end

local function get_base_speed(char)
	local speed = 15
	if is_crouching(char) then
		speed = speed - 5
	end
	return speed
end

function ign.set_speed(val)
	speed_boost = math.clamp(tonumber(val) or 0, MIN_BOOST, MAX_BOOST)
	local char = lp.Character
	if char then
		char:SetAttribute("SpeedBoost", active_speed and speed_boost or 0)
	end
end

function ign.speed(state, boost)
	active_speed = state
	if boost ~= nil then
		ign.set_speed(boost)
	end
	disconnect_list(conns_speed)

	local char = lp.Character
	if char then
		char:SetAttribute("SpeedBoost", active_speed and speed_boost or 0)
	end

	if active_speed then
		local last_crouch = 0

		local c_render = run.RenderStepped:Connect(function()
			if not active_speed then return end
			local c = lp.Character
			if not c then return end

			local hum = c:FindFirstChildOfClass("Humanoid")
			if hum and speed_boost > 0 then
				hum.WalkSpeed = get_base_speed(c) + speed_boost
			end

			if crouch_rem and (tick() - last_crouch > 0.15) then
				last_crouch = tick()
				local sending_crouch = active_rush or is_crouching(c)
				crouch_rem:FireServer(sending_crouch, true)
			end
		end)
		table.insert(conns_speed, c_render)

		local c_char = lp.CharacterAdded:Connect(function(new_char)
			task.wait(0.2)
			if active_speed then
				new_char:SetAttribute("SpeedBoost", speed_boost)
			end
		end)
		table.insert(conns_speed, c_char)
	else
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = get_base_speed(char)
			end
		end
	end
end

local function cleanup_rush_clones()
	if col_clone and col_clone.Parent then
		col_clone:Destroy()
		col_clone = nil
	end
	if col_part_clone and col_part_clone.Parent then
		col_part_clone:Destroy()
		col_part_clone = nil
	end
end

function ign.rush(state)
	active_rush = state
	disconnect_list(conns_rush)

	local char = lp.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local real_col = char and char:FindFirstChild("Collision")
	local real_col_part = char and (char:FindFirstChild("CollisionPart") or real_col)
	local lower_torso = char and char:FindFirstChild("LowerTorso")
	local root_joint = lower_torso and lower_torso:FindFirstChild("Root")

	if active_rush then
		if not char or not hum or not root or not real_col then
			active_rush = false
			return
		end

		if root_joint then
			original_c1 = root_joint.C1
		end

		cleanup_rush_clones()

		col_clone = real_col:Clone()
		col_clone.Name = "CollisionClone"
		col_clone.Massless = true
		col_clone.Parent = char

		col_part_clone = real_col_part:Clone()
		col_part_clone.Name = "CollisionPartClone"
		col_part_clone.CanCollide = false
		col_part_clone.Massless = true
		col_part_clone.Parent = char

		if col_part_clone:FindFirstChild("CollisionCrouch") then
			col_part_clone.CollisionCrouch:Destroy()
		end

		root.CFrame = root.CFrame * CFrame.new(0, -2.346, 0)
		hum.HipHeight = 0.05

		if crouch_rem then
			crouch_rem:FireServer(true, true)
		end

		local last_crouch_send = 0

		local c_render = run.RenderStepped:Connect(function()
			if not active_rush then return end
			local c = lp.Character
			if not c then return end

			local r = c:FindFirstChild("HumanoidRootPart")
			local h = c:FindFirstChildOfClass("Humanoid")
			local col = c:FindFirstChild("Collision")
			local col_p = c:FindFirstChild("CollisionPart")
			local lt = c:FindFirstChild("LowerTorso")
			local rj = lt and lt:FindFirstChild("Root")
			if not r or not col or not col_clone then return end

			r.CanCollide = false
			for _, part in ipairs(c:GetChildren()) do
				if part:IsA("BasePart") and part ~= col_clone and part ~= col_clone:FindFirstChild("CollisionCrouch") then
					part.CanCollide = false
				end
			end

			col.CanCollide = false
			if col:FindFirstChild("CollisionCrouch") then
				col.CollisionCrouch.CanCollide = false
			end

			local is_crouch = is_crouching(c)

			local clone_crouch = col_clone:FindFirstChild("CollisionCrouch")
			if clone_crouch then
				col_clone.CanCollide = not is_crouch
				clone_crouch.CanCollide = is_crouch
			else
				col_clone.CanCollide = not is_crouch
			end

			if rj and original_c1 then
				rj.C1 = original_c1 * CFrame.new(0, -2.346, 0)
			end

			local spoof_y = 2.328
			col.Position = r.Position + Vector3.new(0, spoof_y, 0)
			if col_p then
				col_p.Position = r.Position + Vector3.new(0, spoof_y, 0)
			end

			if col:FindFirstChild("CollisionCrouch") and clone_crouch then
				col.CollisionCrouch.Position = r.Position + Vector3.new(0, 1.328, 0)
				clone_crouch.CollisionGroup = col.CollisionCrouch.CollisionGroup
			end

			if clone_crouch then
				clone_crouch.Position = r.Position + Vector3.new(0, 0.75, 0)
			end

			col_clone.CollisionGroup = col.CollisionGroup
			col_clone.Position = r.Position + Vector3.new(0, 1.75, 0)

			if crouch_rem and (tick() - last_crouch_send > 0.1) then
				last_crouch_send = tick()
				crouch_rem:FireServer(true, true)
			end
		end)
		table.insert(conns_rush, c_render)

	else
		cleanup_rush_clones()

		if hum and root then
			root.CFrame = root.CFrame * CFrame.new(0, 2.346, 0)
			hum.HipHeight = 2.396
		end

		if real_col and root then
			real_col.CanCollide = true
			real_col.Position = root.Position + Vector3.new(0, 0.18, 0)
			if real_col:FindFirstChild("CollisionCrouch") then
				real_col.CollisionCrouch.Position = root.Position + Vector3.new(0, -0.982, 0)
			end
		end

		if root_joint and original_c1 then
			root_joint.C1 = original_c1
		end

		if crouch_rem then
			crouch_rem:FireServer(is_crouching(char), true)
		end
	end
end

function ign.cleanup()
	ign.a90(false)
	ign.screech(false)
	ign.giggle(false)
	ign.snare(false)
	ign.dupe(false)
	ign.eyes(false)
	ign.speed(false)
	ign.rush(false)
	cleanup_rush_clones()
end

return ign
