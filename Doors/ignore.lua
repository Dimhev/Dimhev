local plrs = game:GetService("Players")
local rep = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local ws = game:GetService("Workspace")
local lp = plrs.LocalPlayer

local remotes = rep:WaitForChild("RemotesFolder")
local screech_rem = remotes:WaitForChild("Screech")
local real_motor = remotes:FindFirstChild("MotorReplication_Real") or remotes:WaitForChild("MotorReplication")
local fake_motor = nil

local gd = rep:FindFirstChild("GameData")
local floor_val = gd and gd:FindFirstChild("Floor")
local is_old = floor_val and (floor_val.Value == "Fools" or floor_val.Value == "OldHotel")

local ign = {}
local conns_a90 = {}
local conns_screech = {}
local conns_snare = {}
local conns_eyes = {}

local active_a90 = false
local active_screech = false
local active_snare = false
local active_eyes = false

local function disconnect_list(list)
	for _, c in ipairs(list) do
		if typeof(c) == "RBXScriptConnection" and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(list)
end

local function get_a90_frame()
	local pgui = lp:FindFirstChild("PlayerGui")
	if not pgui then return nil end
	local mui = pgui:FindFirstChild("MainUI")
	if not mui then return nil end
	local jmp = mui:FindFirstChild("Jumpscare")
	if not jmp then return nil end
	return jmp:FindFirstChild("Jumpscare_A90")
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
		
		local cam = ws.CurrentCamera
		if cam then
			local c2 = cam.ChildAdded:Connect(function(child)
				if active_screech and (child.Name == "Screech" or child.Name == "ScreechRetro") then
					task.defer(function()
						child:Destroy()
					end)
				end
			end)
			table.insert(conns_screech, c2)
		end
	else
		if smod then
			smod:SetAttribute("Static", nil)
		end
	end
end

local function disable_snare_hitbox(hitbox)
	if hitbox and hitbox:IsA("BasePart") and not hitbox:GetAttribute("SnareDisabled") then
		hitbox:SetAttribute("SnareDisabled", true)
		pcall(function()
			hitbox.CanTouch = false
		end)
	end
end

local function check_snare_instance(inst)
	if not inst then return end

	if inst.Name == "Hitbox" and inst:FindFirstAncestor("Snare") then
		disable_snare_hitbox(inst)
	elseif inst.Name == "Snare" then
		local hb = inst:FindFirstChild("Hitbox", true)
		if hb then
			disable_snare_hitbox(hb)
		end
	end
end

function ign.snare(state)
	active_snare = state
	disconnect_list(conns_snare)

	if active_snare then
		for _, inst in ipairs(ws:GetDescendants()) do
			if not active_snare then break end
			check_snare_instance(inst)
		end

		local c = ws.DescendantAdded:Connect(function(inst)
			if active_snare then
				check_snare_instance(inst)
			end
		end)
		table.insert(conns_snare, c)
	end
end

local function has_eyes()
	return ws:FindFirstChild("Eyes") ~= nil
		or ws:FindFirstChild("Lookman") ~= nil
		or ws:FindFirstChild("BackdoorLookman") ~= nil
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
			if active_eyes and has_eyes() then
				if is_old then
					real_motor:FireServer(0, -90, 0, false)
				else
					real_motor:FireServer(-650)
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

function ign.cleanup()
	ign.a90(false)
	ign.screech(false)
	ign.snare(false)
	ign.eyes(false)
end

return ign
