local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")

local function get_container()
	if gethui then return gethui() end
	local s, res = pcall(function() return game:GetService("CoreGui") end)
	if s and res then return res end
	return plrs.LocalPlayer:WaitForChild("PlayerGui")
end

local cg = get_container()

local function purge()
	local targets = {
		gethui and gethui(),
		pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or nil,
		plrs.LocalPlayer and plrs.LocalPlayer:FindFirstChild("PlayerGui")
	}
	for _, holder in ipairs(targets) do
		if holder then
			for _, ch in ipairs(holder:GetChildren()) do
				if ch.Name == "ui" or ch.Name == "dimhev_ui" then
					ch:Destroy()
				end
			end
		end
	end
end
purge()

local lib = {}
lib.__index = lib

local theme = {
	bg = Color3.fromRGB(22, 17, 33),
	bg_grad = Color3.fromRGB(15, 11, 23),
	sec = Color3.fromRGB(30, 23, 45),
	elm = Color3.fromRGB(35, 27, 52),
	stroke = Color3.fromRGB(62, 48, 92),
	accent = Color3.fromRGB(142, 82, 242),
	txt = Color3.fromRGB(242, 238, 252),
	sub = Color3.fromRGB(142, 128, 170),
	warn = Color3.fromRGB(245, 195, 65),
	danger = Color3.fromRGB(245, 75, 75),
	font = Enum.Font.GothamMedium,
	bold = Enum.Font.GothamBold
}

local function tw(obj, dur, props)
	ts:Create(obj, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

function lib.new()
	local self = setmetatable({}, lib)
	
	local scr = Instance.new("ScreenGui")
	scr.Name = "ui"
	scr.ResetOnSpawn = false
	scr.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	scr.Parent = cg
	
	local main = Instance.new("Frame")
	main.Name = "main"
	main.Size = UDim2.new(0, 420, 0, 340)
	main.Position = UDim2.new(0.5, -210, 0.5, -170)
	main.BackgroundColor3 = theme.bg
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = scr

	local main_grad = Instance.new("UIGradient")
	main_grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.bg),
		ColorSequenceKeypoint.new(1, theme.bg_grad)
	})
	main_grad.Rotation = 45
	main_grad.Parent = main
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.stroke
	stroke.Thickness = 1
	stroke.Parent = main
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = main

	local top = Instance.new("Frame")
	top.Name = "topbar"
	top.Size = UDim2.new(1, 0, 0, 38)
	top.BackgroundColor3 = theme.sec
	top.BorderSizePixel = 0
	top.Parent = main
	
	local top_str = Instance.new("UIStroke")
	top_str.Color = theme.stroke
	top_str.Thickness = 1
	top_str.Parent = top
	
	local author = Instance.new("TextLabel")
	author.Text = "By dimhev"
	author.Font = theme.bold
	author.TextSize = 13
	author.TextColor3 = Color3.fromRGB(255, 255, 255)
	author.Position = UDim2.new(0, 14, 0.5, 0)
	author.AnchorPoint = Vector2.new(0, 0.5)
	author.AutomaticSize = Enum.AutomaticSize.XY
	author.BackgroundTransparency = 1
	author.Parent = top

	local shimmer = Instance.new("UIGradient")
	shimmer.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 85, 245)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 205, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 55, 215))
	})
	shimmer.Offset = Vector2.new(-1, 0)
	shimmer.Parent = author

	ts:Create(shimmer, TweenInfo.new(2.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
		Offset = Vector2.new(1, 0)
	}):Play()

	local btns_wrap = Instance.new("Frame")
	btns_wrap.Size = UDim2.new(0, 54, 1, 0)
	btns_wrap.Position = UDim2.new(1, -62, 0, 0)
	btns_wrap.BackgroundTransparency = 1
	btns_wrap.Parent = top

	local min_btn = Instance.new("TextButton")
	min_btn.Size = UDim2.new(0, 22, 0, 22)
	min_btn.Position = UDim2.new(0, 0, 0.5, -11)
	min_btn.BackgroundColor3 = theme.elm
	min_btn.Text = "-"
	min_btn.Font = theme.bold
	min_btn.TextSize = 13
	min_btn.TextColor3 = theme.sub
	min_btn.AutoButtonColor = false
	min_btn.Parent = btns_wrap

	local min_crn = Instance.new("UICorner")
	min_crn.CornerRadius = UDim.new(0, 4)
	min_crn.Parent = min_btn

	local min_stk = Instance.new("UIStroke")
	min_stk.Color = theme.stroke
	min_stk.Thickness = 1
	min_stk.Parent = min_btn

	local cls_btn = Instance.new("TextButton")
	cls_btn.Size = UDim2.new(0, 22, 0, 22)
	cls_btn.Position = UDim2.new(0, 28, 0.5, -11)
	cls_btn.BackgroundColor3 = theme.elm
	cls_btn.Text = "x"
	cls_btn.Font = theme.bold
	cls_btn.TextSize = 11
	cls_btn.TextColor3 = theme.sub
	cls_btn.AutoButtonColor = false
	cls_btn.Parent = btns_wrap

	local cls_crn = Instance.new("UICorner")
	cls_crn.CornerRadius = UDim.new(0, 4)
	cls_crn.Parent = cls_btn

	local cls_stk = Instance.new("UIStroke")
	cls_stk.Color = theme.stroke
	cls_stk.Thickness = 1
	cls_stk.Parent = cls_btn

	local cont = Instance.new("ScrollingFrame")
	cont.Name = "content"
	cont.Size = UDim2.new(1, 0, 1, -38)
	cont.Position = UDim2.new(0, 0, 0, 38)
	cont.BackgroundTransparency = 1
	cont.BorderSizePixel = 0
	cont.ScrollBarThickness = 2
	cont.ScrollBarImageColor3 = theme.accent
	cont.Parent = main

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = cont
	
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = cont

	local drag, d_start, s_pos
	top.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = true
			d_start = inp.Position
			s_pos = main.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					drag = false
				end
			end)
		end
	end)
	
	uis.InputChanged:Connect(function(inp)
		if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - d_start
			main.Position = UDim2.new(s_pos.X.Scale, s_pos.X.Offset + d.X, s_pos.Y.Scale, s_pos.Y.Offset + d.Y)
		end
	end)

	local opened = true
	local toggling = false
	local orig_size = main.Size
	
	local function toggle_state()
		if toggling then return end
		toggling = true
		opened = not opened
		
		if opened then
			main.Visible = true
			tw(main, 0.22, {Size = orig_size})
			task.wait(0.22)
		else
			tw(main, 0.18, {Size = UDim2.new(orig_size.X.Scale, orig_size.X.Offset, 0, 0)})
			task.wait(0.18)
			main.Visible = false
		end
		toggling = false
	end

	min_btn.MouseButton1Click:Connect(toggle_state)

	cls_btn.MouseButton1Click:Connect(function()
		tw(main, 0.15, {Size = UDim2.new(orig_size.X.Scale, orig_size.X.Offset, 0, 0)})
		task.wait(0.15)
		scr:Destroy()
	end)

	uis.InputBegan:Connect(function(inp, gpe)
		if not gpe and inp.KeyCode == Enum.KeyCode.RightShift then
			toggle_state()
		end
	end)

	self.gui = scr
	self.main = main
	self.cont = cont
	self.toggle_ui = toggle_state
	return self
end

function lib:toggle(text, def, cb, desc)
	cb = cb or function() end
	local state = def or false
	
	local box = Instance.new("TextButton")
	box.Size = desc and UDim2.new(1, -24, 0, 44) or UDim2.new(1, -24, 0, 32)
	box.BackgroundColor3 = theme.elm
	box.AutoButtonColor = false
	box.Text = ""
	box.Parent = self.cont
	
	local crn = Instance.new("UICorner")
	crn.CornerRadius = UDim.new(0, 6)
	crn.Parent = box
	
	local stk = Instance.new("UIStroke")
	stk.Color = theme.stroke
	stk.Thickness = 1
	stk.Parent = box

	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Font = theme.font
	lbl.TextSize = 12
	lbl.TextColor3 = theme.txt
	lbl.Position = desc and UDim2.new(0, 10, 0, 5) or UDim2.new(0, 10, 0, 0)
	lbl.Size = desc and UDim2.new(1, -55, 0, 16) or UDim2.new(1, -55, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = box

	if desc then
		local d_lbl = Instance.new("TextLabel")
		d_lbl.Text = desc
		d_lbl.Font = theme.font
		d_lbl.TextSize = 10
		d_lbl.TextColor3 = theme.txt
		d_lbl.Position = UDim2.new(0, 10, 0, 22)
		d_lbl.Size = UDim2.new(1, -55, 0, 15)
		d_lbl.BackgroundTransparency = 1
		d_lbl.TextXAlignment = Enum.TextXAlignment.Left
		d_lbl.TextTruncate = Enum.TextTruncate.AtEnd
		d_lbl.Parent = box
	end

	local switch = Instance.new("Frame")
	switch.Size = UDim2.new(0, 36, 0, 18)
	switch.Position = UDim2.new(1, -44, 0.5, -9)
	switch.BackgroundColor3 = state and theme.accent or theme.sec
	switch.Parent = box
	
	local s_crn = Instance.new("UICorner")
	s_crn.CornerRadius = UDim.new(1, 0)
	s_crn.Parent = switch
	
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 14, 0, 14)
	dot.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
	dot.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
	dot.Parent = switch
	
	local d_crn = Instance.new("UICorner")
	d_crn.CornerRadius = UDim.new(1, 0)
	d_crn.Parent = dot

	local function update()
		tw(switch, 0.18, {
			BackgroundColor3 = state and theme.accent or theme.sec
		})
		tw(dot, 0.18, {
			Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		})
		cb(state)
	end

	box.MouseButton1Click:Connect(function()
		state = not state
		update()
	end)
end

function lib:input(text, placeholder, def, cb)
	cb = cb or function() end
	
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, -24, 0, 32)
	box.BackgroundColor3 = theme.elm
	box.Parent = self.cont
	
	local crn = Instance.new("UICorner")
	crn.CornerRadius = UDim.new(0, 6)
	crn.Parent = box
	
	local stk = Instance.new("UIStroke")
	stk.Color = theme.stroke
	stk.Thickness = 1
	stk.Parent = box

	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Font = theme.font
	lbl.TextSize = 12
	lbl.TextColor3 = theme.txt
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.Size = UDim2.new(0, 0, 1, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = box

	local inp = Instance.new("TextBox")
	inp.Size = UDim2.new(0, 100, 0, 22)
	inp.Position = UDim2.new(1, -108, 0.5, -11)
	inp.BackgroundColor3 = theme.sec
	inp.Text = def or ""
	inp.PlaceholderText = placeholder or "..."
	inp.Font = theme.font
	inp.TextSize = 11
	inp.TextColor3 = theme.txt
	inp.PlaceholderColor3 = theme.sub
	inp.ClearTextOnFocus = false
	inp.Parent = box
	
	local i_crn = Instance.new("UICorner")
	i_crn.CornerRadius = UDim.new(0, 4)
	i_crn.Parent = inp
	
	local i_stk = Instance.new("UIStroke")
	i_stk.Color = theme.stroke
	i_stk.Thickness = 1
	i_stk.Parent = inp

	inp.FocusLost:Connect(function()
		cb(inp.Text)
	end)
end

function lib:desc(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -34, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = theme.font
	lbl.TextSize = 11
	lbl.TextColor3 = theme.txt
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = self.cont
	return lbl
end

function lib:warn(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -34, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = theme.font
	lbl.TextSize = 11
	lbl.TextColor3 = theme.warn
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = self.cont
	return lbl
end

function lib:danger(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -34, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = theme.font
	lbl.TextSize = 11
	lbl.TextColor3 = theme.danger
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = self.cont
	return lbl
end
lib.alert = lib.danger

return lib
