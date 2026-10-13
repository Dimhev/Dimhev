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

local function lock_and_harvest(target, max_time)
	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local cam = ws.CurrentCamera
	if not root or not cam or not is_valid(target) then return false end

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
	local hover_pos = target_pos + Vector3.new(0, 0.4, 0)
	local start_hints = count_hints()
	local start_time = os.clock()
	local success = false

	local ps = lp:FindFirstChild("PlayerScripts")
	local prompt_svc = ps and ps:FindFirstChild("PromptService")
	if prompt_svc and prompt_svc:GetAttribute("Suppressed") then
		prompt_svc:SetAttribute("Suppressed", false)
	end

	local conn = run.RenderStepped:Connect(function()
		if not active_library or not char or not root then return end
		root.CFrame = CFrame.lookAt(hover_pos, target_pos)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, target_pos)
	end)

	while active_library and (os.clock() - start_time < (max_time or 5)) do
		if not is_valid(target) then
			success = true
			break
		end

		if count_hints() > start_hints then
			success = true
			break
		end

		local cur_code = get_library_code()
		if cur_code and not cur_code:find("_") then
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

	conn:Disconnect()
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
				lock_and_harvest(paper, 3)
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

			local char = lp.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then
				task.wait(0.2)
				continue
			end

			local available_books = {}
			local now = os.clock()

			for _, desc in ipairs(r50:GetDescendants()) do
				if desc.Name == "LiveHintBook" and is_valid(desc) then
					local blocked_until = blacklisted_books[desc] or 0
					if now >= blocked_until then
						local pos = desc:IsA("Model") and desc:GetPivot().Position or desc.Position
						local dist = (root.Position - pos).Magnitude
						table.insert(available_books, { obj = desc, dist = dist })
					end
				end
			end

			if #available_books == 0 then
				table.clear(blacklisted_books)
				task.wait(0.3)
				continue
			end

			table.sort(available_books, function(a, b)
				return a.dist < b.dist
			end)

			local target_book = available_books[1].obj
			local harvested = lock_and_harvest(target_book, 5)

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
					lock_and_harvest(padlock, 2)
				end
				for _ = 1, 5 do
					if not active_library then break end
					pl:FireServer(last_lib_code)
					task.wait(0.15)
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
