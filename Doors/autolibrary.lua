local plrs = game:GetService("Players")
local rep = game:GetService("ReplicatedStorage")
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

local function is_valid(obj)
	return obj and obj.Parent and obj:IsDescendantOf(ws)
end

local function tp_and_interact(target)
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
	local stand_pos = target_pos + (target_cf.LookVector * 1.8) + Vector3.new(0, 0.5, 0)

	root.CFrame = CFrame.lookAt(stand_pos, target_pos)
	root.AssemblyLinearVelocity = Vector3.zero
	cam.CFrame = CFrame.lookAt(cam.CFrame.Position, target_pos)

	local ps = lp:FindFirstChild("PlayerScripts")
	local prompt_svc = ps and ps:FindFirstChild("PromptService")
	if prompt_svc and prompt_svc:GetAttribute("Suppressed") then
		prompt_svc:SetAttribute("Suppressed", false)
	end

	local found_prompt = false
	for _, prompt in ipairs(target:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			found_prompt = true

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
	return found_prompt
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

function autolib.run(state, cb)
	active_library = state
	if cb then
		lib_notify_cb = cb
	end
	last_lib_code = nil

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
		while active_library and not has_hint_paper() and paper_tries < 50 do
			local paper = r50:FindFirstChild("LibraryHintPaper", true) or r50:FindFirstChild("LibraryHintPaperHard", true)
			if paper and is_valid(paper) then
				tp_and_interact(paper)
			end
			paper_tries = paper_tries + 1
			task.wait(0.1)
		end

		while active_library do
			local code = get_library_code()
			if code and not code:find("_") then
				last_lib_code = code
				if lib_notify_cb then
					lib_notify_cb(code)
				end
				break
			end

			local books = {}
			for _, desc in ipairs(r50:GetDescendants()) do
				if desc.Name == "LiveHintBook" and is_valid(desc) then
					table.insert(books, desc)
				end
			end

			if #books == 0 then
				task.wait(0.3)
			end

			for _, book in ipairs(books) do
				if not active_library then break end
				
				local cur_code = get_library_code()
				if cur_code and not cur_code:find("_") then break end

				if is_valid(book) then
					local start_time = os.clock()
					while active_library and is_valid(book) and (os.clock() - start_time < 6) do
						tp_and_interact(book)
						task.wait(0.08)
					end
					task.wait(0.05)
				end
			end

			task.wait(0.1)
		end

		if active_library and last_lib_code then
			local pl = pl_remote or remotes:FindFirstChild("PL") or remotes:WaitForChild("PL", 5)
			if pl then
				local padlock = r50:FindFirstChild("Padlock", true) or ws:FindFirstChild("Padlock", true)
				if padlock and is_valid(padlock) then
					for _ = 1, 10 do
						if not active_library then break end
						tp_and_interact(padlock)
						pl:FireServer(last_lib_code)
						task.wait(0.2)
					end
				else
					pl:FireServer(last_lib_code)
				end
			end
		end
	end)
end

function autolib.cleanup()
	active_library = false
	if lib_thread then
		task.cancel(lib_thread)
		lib_thread = nil
	end
end

return autolib
