local plrs = game:GetService("Players")
local rep = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local ws = game:GetService("Workspace")
local lp = plrs.LocalPlayer

local remotes = rep:WaitForChild("RemotesFolder")
local pl_remote = remotes:FindFirstChild("PL")
local gd = rep:FindFirstChild("GameData")

local autolib = {}
local active_library = false
local lib_thread = nil
local last_lib_code = nil
local lib_notify_cb = nil
local blacklisted_books = {}

local function is_valid(obj)
	return obj and obj.Parent and obj:IsDescendantOf(ws)
end

local function get_alive_root()
	local char = lp.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function get_figure_pos(r50)
	local fsetup = r50:FindFirstChild("FigureSetup")
	if not fsetup then return nil end
	local rig = fsetup:FindFirstChild("FigureRig") or fsetup:FindFirstChild("FigureRagdoll")
	if not rig then return nil end
	local root = rig:FindFirstChild("RootPart")
		or rig:FindFirstChild("HumanoidRootPart")
		or rig:FindFirstChild("Torso")
		or rig.PrimaryPart
	return root and root.Position
end

local function get_open_stand_pos(r50, target_pos, target_obj)
	local char = lp.Character
	local ray_params = RaycastParams.new()
	ray_params.FilterType = Enum.RaycastFilterType.Exclude
	ray_params.FilterDescendantsInstances = { char, target_obj }

	local dirs = {
		Vector3.new(0, 0, 1),
		Vector3.new(0, 0, -1),
		Vector3.new(1, 0, 0),
		Vector3.new(-1, 0, 0),
	}

	local origin = target_pos + Vector3.new(0, 0.4, 0)
	local best_dir = dirs[1]
	local max_dist = -1

	for _, dir in ipairs(dirs) do
		local res = ws:Raycast(origin, dir * 10, ray_params)
		local dist = res and (res.Position - origin).Magnitude or 10
		if dist > max_dist then
			max_dist = dist
			best_dir = dir
		end
	end

	return target_pos + (best_dir * 2.2) + Vector3.new(0, 0.2, 0)
end

local function count_hints()
	local pgui = lp:FindFirstChild("PlayerGui")
	local perm_ui = pgui and pgui:FindFirstChild("PermUI")
	local hints = perm_ui and perm_ui:FindFirstChild("Hints")
	if not hints then return 0 end

	local count = 0
	for _, h in ipairs(hints:GetChildren()) do
		if h:IsA("ImageLabel") and h:FindFirstChild("TextLabel") then
			count = count + 1
		end
	end
	return count
end

local function has_hint_paper()
	local char = lp.Character
	local bp = lp:FindFirstChild("Backpack")
	return (char and (char:FindFirstChild("LibraryHintPaper", true) or char:FindFirstChild("LibraryHintPaperHard", true)))
		or (bp and (bp:FindFirstChild("LibraryHintPaper", true) or bp:FindFirstChild("LibraryHintPaperHard", true)))
end

local function get_library_code()
	local char = lp.Character
	local bp = lp:FindFirstChild("Backpack")
	local paper = (char and (char:FindFirstChild("LibraryHintPaper") or char:FindFirstChild("LibraryHintPaperHard")))
		or (bp and (bp:FindFirstChild("LibraryHintPaper") or bp:FindFirstChild("LibraryHintPaperHard")))

	if not paper or not paper:FindFirstChild("UI") then
		return nil
	end

	local pgui = lp:FindFirstChild("PlayerGui")
	local perm_ui = pgui and pgui:FindFirstChild("PermUI")
	local hints = perm_ui and perm_ui:FindFirstChild("Hints")
	if not hints then
		return nil
	end

	local fl = gd and gd:FindFirstChild("Floor")
	local is_fools = fl and fl.Value == "Fools"
	local len = is_fools and 10 or 5

	local code = {}
	for i = 1, len do
		code[i] = "_"
	end

	local hint_children = hints:GetChildren()
	local ui_children = paper.UI:GetChildren()

	for _, hint in ipairs(hint_children) do
		if hint:IsA("ImageLabel") and hint:FindFirstChild("TextLabel") then
			for _, ui_child in ipairs(ui_children) do
				if ui_child:IsA("ImageLabel") and ui_child.ImageRectOffset == hint.ImageRectOffset then
					local idx = tonumber(ui_child.Name)
					if idx and code[idx] then
						code[idx] = hint.TextLabel.Text
					end
				end
			end
		end
	end

	return table.concat(code)
end

local function lock_and_harvest(r50, target, max_time)
	if not is_valid(target) then return false end
	local root = get_alive_root()
	local cam = ws.CurrentCamera
	if not root or not cam then return false end

	local target_cf = nil
	if target:IsA("Model") then
		target_cf = target:GetPivot()
	elseif target:IsA("BasePart") then
		target_cf = target.CFrame
	else
		local p = target:FindFirstChildWhichIsA("BasePart", true)
		if p then target_cf = p.CFrame end
	end
	if not target_cf then return false end

	local target_pos = target_cf.Position
	local stand_pos = get_open_stand_pos(r50, target_pos, target)
	local start_hints = count_hints()
	local initial_code = get_library_code() or ""
	local start_time = os.clock()
	local success = false

	local ps = lp:FindFirstChild("PlayerScripts")
	local prompt_svc = ps and ps:FindFirstChild("PromptService")
	if prompt_svc and prompt_svc:GetAttribute("Suppressed") then
		prompt_svc:SetAttribute("Suppressed", false)
	end

	local conn = nil
	local function cleanup_conn()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		local r = get_alive_root()
		if r then
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end
	end

	conn = run.RenderStepped:Connect(function()
		if not active_library then return end
		local cur_root = get_alive_root()
		if not cur_root then return end
		cur_root.CFrame = CFrame.lookAt(stand_pos, target_pos)
		cur_root.AssemblyLinearVelocity = Vector3.zero
		cur_root.AssemblyAngularVelocity = Vector3.zero
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, target_pos)
	end)

	while active_library and (os.clock() - start_time < (max_time or 5)) do
		if not get_alive_root() then
			break
		end

		if not is_valid(target) then
			success = true
			break
		end

		local prompt_found = target:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not prompt_found and (count_hints() > start_hints) then
			success = true
			break
		end

		local cur_code = get_library_code() or ""
		if cur_code ~= initial_code and cur_code ~= "" then
			success = true
			break
		end

		for _, prompt in ipairs(target:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") then
				if prompt:HasTag("DisableWhenEnabledOnClient") then
					prompt:RemoveTag("DisableWhenEnabledOnClient")
				end

				prompt.RequiresLineOfSight = false
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = 60
				prompt.Enabled = true

				pcall(function()
					prompt:InputHoldBegin()
				end)

				if fireproximityprompt then
					fireproximityprompt(prompt)
				end
			end
		end

		task.wait(0.06)
	end

	cleanup_conn()
	return success
end

function autolib.run(state, cb)
	active_library = state
	if cb then
		lib_notify_cb = cb
	end
	last_lib_code = nil
	table.clear(blacklisted_books)

	if lib_thread then
		task.cancel(lib_thread)
		lib_thread = nil
	end

	if not active_library then return end

	lib_thread = task.spawn(function()
		local rooms = ws:WaitForChild("CurrentRooms", 10)
		if not rooms then return end

		while active_library do
			local cur = tonumber(lp:GetAttribute("CurrentRoom"))
			if cur == 50 then break end
			task.wait(0.2)
		end
		if not active_library then return end

		local r50 = rooms:WaitForChild("50", 15)
		if not r50 then return end

		local paper_tries = 0
		while active_library and not has_hint_paper() and paper_tries < 40 do
			local paper = r50:FindFirstChild("LibraryHintPaper", true) or r50:FindFirstChild("LibraryHintPaperHard", true)
			if paper and is_valid(paper) then
				lock_and_harvest(r50, paper, 3)
			end
			paper_tries = paper_tries + 1
			task.wait(0.1)
		end

		while active_library do
			local current_code = get_library_code()
			if current_code and not current_code:find("_") then
				last_lib_code = current_code
				if lib_notify_cb then
					lib_notify_cb(current_code)
				end
				break
			end

			local root = get_alive_root()
			if not root then
				task.wait(0.2)
				continue
			end

			local now = os.clock()
			for obj, exp in pairs(blacklisted_books) do
				if now >= exp or not is_valid(obj) then
					blacklisted_books[obj] = nil
				end
			end

			local fig_pos = get_figure_pos(r50)
			local available_books = {}

			for _, desc in ipairs(r50:GetDescendants()) do
				if desc.Name == "LiveHintBook" and is_valid(desc) then
					if not blacklisted_books[desc] then
						local pos = desc:IsA("Model") and desc:GetPivot().Position or desc.Position
						local dist_to_fig = fig_pos and (pos - fig_pos).Magnitude or 100
						if dist_to_fig >= 32 then
							local dist_to_me = (root.Position - pos).Magnitude
							table.insert(available_books, { obj = desc, dist = dist_to_me })
						end
					end
				end
			end

			if #available_books == 0 then
				local wait_time = 1
				for _, exp in pairs(blacklisted_books) do
					local rem = exp - now
					if rem > 0 and rem < wait_time then
						wait_time = rem
					end
				end
				task.wait(math.clamp(wait_time, 0.4, 2))
				continue
			end

			table.sort(available_books, function(a, b)
				return a.dist < b.dist
			end)

			local target_book = available_books[1].obj
			local harvested = lock_and_harvest(r50, target_book, 5)

			if not harvested then
				blacklisted_books[target_book] = os.clock() + 15
			end

			task.wait(0.1)
		end

		if active_library and last_lib_code then
			local pl = pl_remote or remotes:FindFirstChild("PL") or remotes:WaitForChild("PL", 5)
			if pl then
				local padlock = r50:FindFirstChild("Padlock", true) or ws:FindFirstChild("Padlock", true)
				if padlock and is_valid(padlock) then
					local pad_start = os.clock()
					while active_library and is_valid(padlock) and (os.clock() - pad_start < 8) do
						local cur_root = get_alive_root()
						if not cur_root then break end

						local pad_pos = padlock:IsA("Model") and padlock:GetPivot().Position or padlock.Position
						local stand_pos = get_open_stand_pos(r50, pad_pos, padlock)

						cur_root.CFrame = CFrame.lookAt(stand_pos, pad_pos)
						cur_root.AssemblyLinearVelocity = Vector3.zero
						ws.CurrentCamera.CFrame = CFrame.lookAt(ws.CurrentCamera.CFrame.Position, pad_pos)

						for _, prompt in ipairs(padlock:GetDescendants()) do
							if prompt:IsA("ProximityPrompt") then
								prompt.RequiresLineOfSight = false
								prompt.HoldDuration = 0
								prompt.MaxActivationDistance = 60
								prompt.Enabled = true
								pcall(function() prompt:InputHoldBegin() end)
								if fireproximityprompt then fireproximityprompt(prompt) end
							end
						end

						pl:FireServer(last_lib_code)
						task.wait(0.2)
					end
				end
			end
		end
	end)
end

function autolib.cleanup()
	active_library = false
	table.clear(blacklisted_books)
	if lib_thread then
		task.cancel(lib_thread)
		lib_thread = nil
	end
end

return autolib
