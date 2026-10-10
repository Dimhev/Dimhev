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
				if ch.Name == "DimhevUI" then
					ch:Destroy()
				end
			end
		end
	end
end
purge()

local Library = {
	ToggleKey = Enum.KeyCode.RightShift,
	Theme = {
		bg = Color3.fromRGB(15, 12, 22),
		sidebar = Color3.fromRGB(20, 16, 30),
		sec = Color3.fromRGB(26, 21, 39),
		elm = Color3.fromRGB(33, 26, 50),
		elm_hover = Color3.fromRGB(42, 34, 63),
		stroke = Color3.fromRGB(60, 47, 89),
		stroke_focus = Color3.fromRGB(142, 82, 242),
		accent = Color3.fromRGB(142, 82, 242),
		accent_hover = Color3.fromRGB(160, 105, 255),
		txt = Color3.fromRGB(245, 242, 255),
		sub = Color3.fromRGB(145, 134, 172),
		font = Enum.Font.GothamMedium,
		bold = Enum.Font.GothamBold
	}
}

local function tw(obj, dur, props, style, dir)
	local info = TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
	local tween = ts:Create(obj, info, props)
	tween:Play()
	return tween
end

-- Система уведомлений (Toasts)
local notif_container
local function create_notification_holder()
	if notif_container and notif_container.Parent then return notif_container end
	local scr = Instance.new("ScreenGui")
	scr.Name = "DimhevNotifs"
	scr.ResetOnSpawn = false
	scr.DisplayOrder = 999
	scr.Parent = cg

	notif_container = Instance.new("Frame")
	notif_container.Size = UDim2.new(0, 260, 1, -20)
	notif_container.Position = UDim2.new(1, -270, 0, 10)
	notif_container.BackgroundTransparency = 1
	notif_container.Parent = scr

	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 8)
	layout.Parent = notif_container

	return notif_container
end

function Library:Notify(cfg)
	cfg = typeof(cfg) == "table" and cfg or { Title = "Notification", Content = tostring(cfg), Duration = 3 }
	local holder = create_notification_holder()

	local n = Instance.new("Frame")
	n.Size = UDim2.new(1, 0, 0, 0)
	n.AutomaticSize = Enum.AutomaticSize.Y
	n.BackgroundColor3 = Library.Theme.sec
	n.BackgroundTransparency = 1
	n.Parent = holder

	local crn = Instance.new("UICorner")
	crn.CornerRadius = UDim.new(0, 8)
	crn.Parent = n

	local stk = Instance.new("UIStroke")
	stk.Color = Library.Theme.accent
	stk.Transparency = 1
	stk.Thickness = 1
	stk.Parent = n

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = n

	local title = Instance.new("TextLabel")
	title.Text = cfg.Title or "Notice"
	title.Font = Library.Theme.bold
	title.TextSize = 13
	title.TextColor3 = Library.Theme.txt
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 16)
	title.Parent = n

	local desc = Instance.new("TextLabel")
	desc.Text = cfg.Content or ""
	desc.Font = Library.Theme.font
	desc.TextSize = 11
	desc.TextColor3 = Library.Theme.sub
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.AutomaticSize = Enum.AutomaticSize.Y
	desc.Size = UDim2.new(1, 0, 0, 0)
	desc.Position = UDim2.new(0, 0, 0, 20)
	desc.BackgroundTransparency = 1
	desc.Parent = n

	tw(n, 0.3, { BackgroundTransparency = 0 })
	tw(stk, 0.3, { Transparency = 0.2 })

	task.delay(cfg.Duration or 3.5, function()
		tw(n, 0.3, { BackgroundTransparency = 1 })
		tw(stk, 0.3, { Transparency = 1 })
		task.wait(0.3)
		n:Destroy()
	end)
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title_text = cfg.Title or "Dimhev Hub"
	local sub_text = cfg.SubTitle or "by dimhev"

	local scr = Instance.new("ScreenGui")
	scr.Name = "DimhevUI"
	scr.ResetOnSpawn = false
	scr.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	scr.Parent = cg

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.new(0, 560, 0, 380)
	main.Position = UDim2.new(0.5, -280, 0.5, -190)
	main.BackgroundColor3 = Library.Theme.bg
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = scr

	local main_crn = Instance.new("UICorner")
	main_crn.CornerRadius = UDim.new(0, 10)
	main_crn.Parent = main

	local main_stk = Instance.new("UIStroke")
	main_stk.Color = Library.Theme.stroke
	main_stk.Thickness = 1.2
	main_stk.Parent = main

	-- Верхняя панель (Topbar)
	local topbar = Instance.new("Frame")
	topbar.Name = "Topbar"
	topbar.Size = UDim2.new(1, 0, 0, 42)
	topbar.BackgroundColor3 = Library.Theme.sidebar
	topbar.BorderSizePixel = 0
	topbar.Parent = main

	local top_div = Instance.new("Frame")
	top_div.Size = UDim2.new(1, 0, 0, 1)
	top_div.Position = UDim2.new(0, 0, 1, -1)
	top_div.BackgroundColor3 = Library.Theme.stroke
	top_div.BorderSizePixel = 0
	top_div.Parent = topbar

	local title_lbl = Instance.new("TextLabel")
	title_lbl.Text = title_text
	title_lbl.Font = Library.Theme.bold
	title_lbl.TextSize = 14
	title_lbl.TextColor3 = Library.Theme.txt
	title_lbl.Position = UDim2.new(0, 16, 0.5, 0)
	title_lbl.AnchorPoint = Vector2.new(0, 0.5)
	title_lbl.AutomaticSize = Enum.AutomaticSize.X
	title_lbl.BackgroundTransparency = 1
	title_lbl.Parent = topbar

	local sub_lbl = Instance.new("TextLabel")
	sub_lbl.Text = sub_text
	sub_lbl.Font = Library.Theme.font
	sub_lbl.TextSize = 11
	sub_lbl.TextColor3 = Library.Theme.accent
	sub_lbl.Position = UDim2.new(0, title_lbl.AbsoluteSize.X + 24, 0.5, 0)
	sub_lbl.AnchorPoint = Vector2.new(0, 0.5)
	sub_lbl.AutomaticSize = Enum.AutomaticSize.X
	sub_lbl.BackgroundTransparency = 1
	sub_lbl.Parent = topbar

	title_lbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		sub_lbl.Position = UDim2.new(0, title_lbl.AbsoluteSize.X + 24, 0.5, 0)
	end)

	-- Кнопки управления (Minimize / Close)
	local ctrl_wrap = Instance.new("Frame")
	ctrl_wrap.Size = UDim2.new(0, 60, 1, 0)
	ctrl_wrap.Position = UDim2.new(1, -70, 0, 0)
	ctrl_wrap.BackgroundTransparency = 1
	ctrl_wrap.Parent = topbar

	local function make_icon_btn(txt, x_pos, click_cb)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 24, 0, 24)
		b.Position = UDim2.new(0, x_pos, 0.5, -12)
		b.BackgroundColor3 = Library.Theme.elm
		b.Text = txt
		b.Font = Library.Theme.bold
		b.TextSize = 12
		b.TextColor3 = Library.Theme.sub
		b.AutoButtonColor = false
		b.Parent = ctrl_wrap

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = b

		local s = Instance.new("UIStroke")
		s.Color = Library.Theme.stroke
		s.Thickness = 1
		s.Parent = b

		b.MouseEnter:Connect(function()
			tw(b, 0.15, { BackgroundColor3 = Library.Theme.elm_hover, TextColor3 = Library.Theme.txt })
		end)
		b.MouseLeave:Connect(function()
			tw(b, 0.15, { BackgroundColor3 = Library.Theme.elm, TextColor3 = Library.Theme.sub })
		end)
		b.MouseButton1Click:Connect(click_cb)
		return b
	end

	local is_open = true
	local is_animating = false
	local orig_size = main.Size

	local function toggle_ui()
		if is_animating then return end
		is_animating = true
		is_open = not is_open
		if is_open then
			main.Visible = true
			tw(main, 0.25, { Size = orig_size }, Enum.EasingStyle.Quart)
			task.wait(0.25)
		else
			tw(main, 0.2, { Size = UDim2.new(orig_size.X.Scale, orig_size.X.Offset, 0, 0) }, Enum.EasingStyle.Quart)
			task.wait(0.2)
			main.Visible = false
		end
		is_animating = false
	end

	make_icon_btn("-", 0, toggle_ui)
	make_icon_btn("✕", 30, function()
		tw(main, 0.15, { Size = UDim2.new(orig_size.X.Scale, orig_size.X.Offset, 0, 0) })
		task.wait(0.15)
		scr:Destroy()
	end)

	-- Плавный перенос окна (Draggable)
	local dragging, drag_start, start_pos
	topbar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			drag_start = inp.Position
			start_pos = main.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	uis.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local delta = inp.Position - drag_start
			main.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
		end
	end)

	uis.InputBegan:Connect(function(inp, gpe)
		if not gpe and inp.KeyCode == Library.ToggleKey then
			toggle_ui()
		end
	end)

	-- Боковая панель Вкладок (Sidebar Tabs)
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 140, 1, -42)
	sidebar.Position = UDim2.new(0, 0, 0, 42)
	sidebar.BackgroundColor3 = Library.Theme.sidebar
	sidebar.BorderSizePixel = 0
	sidebar.Parent = main

	local side_div = Instance.new("Frame")
	side_div.Size = UDim2.new(0, 1, 1, 0)
	side_div.Position = UDim2.new(1, -1, 0, 0)
	side_div.BackgroundColor3 = Library.Theme.stroke
	side_div.BorderSizePixel = 0
	side_div.Parent = sidebar

	local tab_scroll = Instance.new("ScrollingFrame")
	tab_scroll.Size = UDim2.new(1, 0, 1, 0)
	tab_scroll.BackgroundTransparency = 1
	tab_scroll.BorderSizePixel = 0
	tab_scroll.ScrollBarThickness = 0
	tab_scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tab_scroll.Parent = sidebar

	local tab_layout = Instance.new("UIListLayout")
	tab_layout.Padding = UDim.new(0, 4)
	tab_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tab_layout.SortOrder = Enum.SortOrder.LayoutOrder
	tab_layout.Parent = tab_scroll

	local tab_pad = Instance.new("UIPadding")
	tab_pad.PaddingTop = UDim.new(0, 8)
	tab_pad.PaddingBottom = UDim.new(0, 8)
	tab_pad.Parent = tab_scroll

	-- Область страниц (Pages Container)
	local pages_folder = Instance.new("Frame")
	pages_folder.Name = "Pages"
	pages_folder.Size = UDim2.new(1, -140, 1, -42)
	pages_folder.Position = UDim2.new(0, 140, 0, 42)
	pages_folder.BackgroundTransparency = 1
	pages_folder.Parent = main

	local window = {
		Tabs = {},
		ActiveTab = nil,
		Main = main,
		ScreenGui = scr,
		Toggle = toggle_ui
	}

	-- Создание вкладки
	function window:CreateTab(name)
		local tab_btn = Instance.new("TextButton")
		tab_btn.Size = UDim2.new(1, -14, 0, 32)
		tab_btn.BackgroundColor3 = Library.Theme.sidebar
		tab_btn.AutoButtonColor = false
		tab_btn.Text = ""
		tab_btn.Parent = tab_scroll

		local tb_crn = Instance.new("UICorner")
		tb_crn.CornerRadius = UDim.new(0, 6)
		tb_crn.Parent = tab_btn

		local active_bar = Instance.new("Frame")
		active_bar.Size = UDim2.new(0, 3, 0, 14)
		active_bar.Position = UDim2.new(0, 0, 0.5, -7)
		active_bar.BackgroundColor3 = Library.Theme.accent
		active_bar.BackgroundTransparency = 1
		active_bar.Parent = tab_btn

		local ab_crn = Instance.new("UICorner")
		ab_crn.CornerRadius = UDim.new(1, 0)
		ab_crn.Parent = active_bar

		local tab_title = Instance.new("TextLabel")
		tab_title.Text = name
		tab_title.Font = Library.Theme.font
		tab_title.TextSize = 12
		tab_title.TextColor3 = Library.Theme.sub
		tab_title.Position = UDim2.new(0, 12, 0, 0)
		tab_title.Size = UDim2.new(1, -16, 1, 0)
		tab_title.BackgroundTransparency = 1
		tab_title.TextXAlignment = Enum.TextXAlignment.Left
		tab_title.TextTruncate = Enum.TextTruncate.AtEnd
		tab_title.Parent = tab_btn

		-- Страница контента
		local page = Instance.new("ScrollingFrame")
		page.Name = name .. "_Page"
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = Library.Theme.accent
		page.Visible = false
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.Parent = pages_folder

		local page_layout = Instance.new("UIListLayout")
		page_layout.Padding = UDim.new(0, 6)
		page_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		page_layout.SortOrder = Enum.SortOrder.LayoutOrder
		page_layout.Parent = page

		local page_pad = Instance.new("UIPadding")
		page_pad.PaddingTop = UDim.new(0, 10)
		page_pad.PaddingBottom = UDim.new(0, 12)
		page_pad.PaddingLeft = UDim.new(0, 12)
		page_pad.PaddingRight = UDim.new(0, 12)
		page_pad.Parent = page

		local tab_obj = {
			Button = tab_btn,
			Page = page
		}

		local function select_tab()
			for _, t in ipairs(window.Tabs) do
				t.Page.Visible = false
				tw(t.Button, 0.2, { BackgroundColor3 = Library.Theme.sidebar })
				tw(t.Button:FindFirstChild("TextLabel"), 0.2, { TextColor3 = Library.Theme.sub })
				tw(t.Button:FindFirstChild("Frame"), 0.2, { BackgroundTransparency = 1 })
			end
			page.Visible = true
			tw(tab_btn, 0.2, { BackgroundColor3 = Library.Theme.sec })
			tw(tab_title, 0.2, { TextColor3 = Library.Theme.txt })
			tw(active_bar, 0.2, { BackgroundTransparency = 0 })
			window.ActiveTab = tab_obj
		end

		tab_btn.MouseButton1Click:Connect(select_tab)
		table.insert(window.Tabs, tab_obj)

		if #window.Tabs == 1 then
			select_tab()
		end

		-- =================== КОМПОНЕНТЫ ВКЛАДКИ =================== --

		-- Раздел (Section)
		function tab_obj:CreateSection(sec_name)
			local sec = Instance.new("Frame")
			sec.Size = UDim2.new(1, 0, 0, 26)
			sec.BackgroundTransparency = 1
			sec.Parent = page

			local s_lbl = Instance.new("TextLabel")
			s_lbl.Text = string.upper(sec_name)
			s_lbl.Font = Library.Theme.bold
			s_lbl.TextSize = 10
			s_lbl.TextColor3 = Library.Theme.accent
			s_lbl.Position = UDim2.new(0, 4, 0.5, 0)
			s_lbl.AnchorPoint = Vector2.new(0, 0.5)
			s_lbl.AutomaticSize = Enum.AutomaticSize.X
			s_lbl.BackgroundTransparency = 1
			s_lbl.Parent = sec

			local line = Instance.new("Frame")
			line.Size = UDim2.new(1, -(s_lbl.AbsoluteSize.X + 16), 0, 1)
			line.Position = UDim2.new(1, 0, 0.5, 0)
			line.AnchorPoint = Vector2.new(1, 0.5)
			line.BackgroundColor3 = Library.Theme.stroke
			line.BorderSizePixel = 0
			line.Parent = sec

			s_lbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				line.Size = UDim2.new(1, -(s_lbl.AbsoluteSize.X + 16), 0, 1)
			end)
		end

		-- Кнопка (Button)
		function tab_obj:CreateButton(name, cb)
			cb = cb or function() end
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 32)
			btn.BackgroundColor3 = Library.Theme.elm
			btn.AutoButtonColor = false
			btn.Text = ""
			btn.Parent = page

			local crn = Instance.new("UICorner")
			crn.CornerRadius = UDim.new(0, 6)
			crn.Parent = btn

			local stk = Instance.new("UIStroke")
			stk.Color = Library.Theme.stroke
			stk.Thickness = 1
			stk.Parent = btn

			local lbl = Instance.new("TextLabel")
			lbl.Text = name
			lbl.Font = Library.Theme.font
			lbl.TextSize = 12
			lbl.TextColor3 = Library.Theme.txt
			lbl.Size = UDim2.new(1, -20, 1, 0)
			lbl.Position = UDim2.new(0, 10, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = btn

			btn.MouseEnter:Connect(function()
				tw(btn, 0.15, { BackgroundColor3 = Library.Theme.elm_hover })
				tw(stk, 0.15, { Color = Library.Theme.accent })
			end)
			btn.MouseLeave:Connect(function()
				tw(btn, 0.15, { BackgroundColor3 = Library.Theme.elm })
				tw(stk, 0.15, { Color = Library.Theme.stroke })
			end)
			btn.MouseButton1Down:Connect(function()
				tw(btn, 0.1, { Size = UDim2.new(1, -4, 0, 30) })
			end)
			btn.MouseButton1Up:Connect(function()
				tw(btn, 0.1, { Size = UDim2.new(1, 0, 0, 32) })
				cb()
			end)
		end

		-- Переключатель (Toggle)
		function tab_obj:CreateToggle(name, def, cb, desc)
			cb = cb or function() end
			local state = def or false

			local box = Instance.new("TextButton")
			box.Size = desc and UDim2.new(1, 0, 0, 42) or UDim2.new(1, 0, 0, 32)
			box.BackgroundColor3 = Library.Theme.elm
			box.AutoButtonColor = false
			box.Text = ""
			box.Parent = page

			local crn = Instance.new("UICorner")
			crn.CornerRadius = UDim.new(0, 6)
			crn.Parent = box

			local stk = Instance.new("UIStroke")
			stk.Color = Library.Theme.stroke
			stk.Thickness = 1
			stk.Parent = box

			local lbl = Instance.new("TextLabel")
			lbl.Text = name
			lbl.Font = Library.Theme.font
			lbl.TextSize = 12
			lbl.TextColor3 = Library.Theme.txt
			lbl.Position = desc and UDim2.new(0, 10, 0, 5) or UDim2.new(0, 10, 0, 0)
			lbl.Size = desc and UDim2.new(1, -60, 0, 16) or UDim2.new(1, -60, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = box

			if desc then
				local d_lbl = Instance.new("TextLabel")
				d_lbl.Text = desc
				d_lbl.Font = Library.Theme.font
				d_lbl.TextSize = 10
				d_lbl.TextColor3 = Library.Theme.sub
				d_lbl.Position = UDim2.new(0, 10, 0, 22)
				d_lbl.Size = UDim2.new(1, -60, 0, 14)
				d_lbl.BackgroundTransparency = 1
				d_lbl.TextXAlignment = Enum.TextXAlignment.Left
				d_lbl.TextTruncate = Enum.TextTruncate.AtEnd
				d_lbl.Parent = box
			end

			local sw = Instance.new("Frame")
			sw.Size = UDim2.new(0, 36, 0, 18)
			sw.Position = UDim2.new(1, -46, 0.5, -9)
			sw.BackgroundColor3 = state and Library.Theme.accent or Library.Theme.sec
			sw.Parent = box

			local sw_crn = Instance.new("UICorner")
			sw_crn.CornerRadius = UDim.new(1, 0)
			sw_crn.Parent = sw

			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 14, 0, 14)
			dot.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
			dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			dot.Parent = sw

			local dot_crn = Instance.new("UICorner")
			dot_crn.CornerRadius = UDim.new(1, 0)
			dot_crn.Parent = dot

			local function update()
				tw(sw, 0.18, { BackgroundColor3 = state and Library.Theme.accent or Library.Theme.sec })
				tw(dot, 0.18, { Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) })
				cb(state)
			end

			box.MouseButton1Click:Connect(function()
				state = not state
				update()
			end)

			return {
				Set = function(v)
					state = v
					update()
				end
			}
		end

		-- Ползунок (Slider)
		function tab_obj:CreateSlider(name, min, max, def, cb)
			cb = cb or function() end
			min = min or 0
			max = max or 100
			def = math.clamp(def or min, min, max)

			local box = Instance.new("Frame")
			box.Size = UDim2.new(1, 0, 0, 46)
			box.BackgroundColor3 = Library.Theme.elm
			box.Parent = page

			local crn = Instance.new("UICorner")
			crn.CornerRadius = UDim.new(0, 6)
			crn.Parent = box

			local stk = Instance.new("UIStroke")
			stk.Color = Library.Theme.stroke
			stk.Thickness = 1
			stk.Parent = box

			local lbl = Instance.new("TextLabel")
			lbl.Text = name
			lbl.Font = Library.Theme.font
			lbl.TextSize = 12
			lbl.TextColor3 = Library.Theme.txt
			lbl.Position = UDim2.new(0, 10, 0, 6)
			lbl.Size = UDim2.new(1, -70, 0, 16)
			lbl.BackgroundTransparency = 1
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = box

			local val_lbl = Instance.new("TextLabel")
			val_lbl.Text = tostring(def)
			val_lbl.Font = Library.Theme.bold
			val_lbl.TextSize = 12
			val_lbl.TextColor3 = Library.Theme.accent
			val_lbl.Position = UDim2.new(1, -55, 0, 6)
			val_lbl.Size = UDim2.new(0, 45, 0, 16)
			val_lbl.BackgroundTransparency = 1
			val_lbl.TextXAlignment = Enum.TextXAlignment.Right
			val_lbl.Parent = box

			local track = Instance.new("TextButton")
			track.Size = UDim2.new(1, -20, 0, 6)
			track.Position = UDim2.new(0, 10, 0, 28)
			track.BackgroundColor3 = Library.Theme.sec
			track.AutoButtonColor = false
			track.Text = ""
			track.Parent = box

			local t_crn = Instance.new("UICorner")
			t_crn.CornerRadius = UDim.new(1, 0)
			t_crn.Parent = track

			local pct = math.clamp((def - min) / (max - min), 0, 1)
			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(pct, 0, 1, 0)
			fill.BackgroundColor3 = Library.Theme.accent
			fill.BorderSizePixel = 0
			fill.Parent = track

			local f_crn = Instance.new("UICorner")
			f_crn.CornerRadius = UDim.new(1, 0)
			f_crn.Parent = fill

			local dragging = false
			local function apply_pos(inp)
				local x_ratio = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				fill.Size = UDim2.new(x_ratio, 0, 1, 0)
				local current_val = math.floor(min + (max - min) * x_ratio)
				val_lbl.Text = tostring(current_val)
				cb(current_val)
			end

			track.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					apply_pos(inp)
				end
			end)

			uis.InputChanged:Connect(function(inp)
				if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
					apply_pos(inp)
				end
			end)

			uis.InputEnded:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
		end

		-- Текстовое поле ввода (Input)
		function tab_obj:CreateInput(name, placeholder, def, cb)
			cb = cb or function() end

			local box = Instance.new("Frame")
			box.Size = UDim2.new(1, 0, 0, 34)
			box.BackgroundColor3 = Library.Theme.elm
			box.Parent = page

			local crn = Instance.new("UICorner")
			crn.CornerRadius = UDim.new(0, 6)
			crn.Parent = box

			local stk = Instance.new("UIStroke")
			stk.Color = Library.Theme.stroke
			stk.Thickness = 1
			stk.Parent = box

			local lbl = Instance.new("TextLabel")
			lbl.Text = name
			lbl.Font = Library.Theme.font
			lbl.TextSize = 12
			lbl.TextColor3 = Library.Theme.txt
			lbl.Position = UDim2.new(0, 10, 0, 0)
			lbl.Size = UDim2.new(0.5, -10, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = box

			local tb = Instance.new("TextBox")
			tb.Size = UDim2.new(0, 120, 0, 22)
			tb.Position = UDim2.new(1, -130, 0.5, -11)
			tb.BackgroundColor3 = Library.Theme.sec
			tb.Text = def or ""
			tb.PlaceholderText = placeholder or "..."
			tb.Font = Library.Theme.font
			tb.TextSize = 11
			tb.TextColor3 = Library.Theme.txt
			tb.PlaceholderColor3 = Library.Theme.sub
			tb.ClearTextOnFocus = false
			tb.Parent = box

			local tb_crn = Instance.new("UICorner")
			tb_crn.CornerRadius = UDim.new(0, 4)
			tb_crn.Parent = tb

			local tb_stk = Instance.new("UIStroke")
			tb_stk.Color = Library.Theme.stroke
			tb_stk.Thickness = 1
			tb_stk.Parent = tb

			tb.Focused:Connect(function()
				tw(tb_stk, 0.15, { Color = Library.Theme.accent })
			end)
			tb.FocusLost:Connect(function(enter)
				tw(tb_stk, 0.15, { Color = Library.Theme.stroke })
				cb(tb.Text, enter)
			end)
		end

		-- Раскрывающийся список (Dropdown)
		function tab_obj:CreateDropdown(name, list, def, cb)
			cb = cb or function() end
			list = list or {}
			local sel = def or list[1] or "Select"
			local dropped = false

			local drop = Instance.new("Frame")
			drop.Size = UDim2.new(1, 0, 0, 34)
			drop.BackgroundColor3 = Library.Theme.elm
			drop.ClipsDescendants = true
			drop.Parent = page

			local crn = Instance.new("UICorner")
			crn.CornerRadius = UDim.new(0, 6)
			crn.Parent = drop

			local stk = Instance.new("UIStroke")
			stk.Color = Library.Theme.stroke
			stk.Thickness = 1
			stk.Parent = drop

			local head_btn = Instance.new("TextButton")
			head_btn.Size = UDim2.new(1, 0, 0, 34)
			head_btn.BackgroundTransparency = 1
			head_btn.Text = ""
			head_btn.Parent = drop

			local lbl = Instance.new("TextLabel")
			lbl.Text = name
			lbl.Font = Library.Theme.font
			lbl.TextSize = 12
			lbl.TextColor3 = Library.Theme.txt
			lbl.Position = UDim2.new(0, 10, 0, 0)
			lbl.Size = UDim2.new(0.5, 0, 0, 34)
			lbl.BackgroundTransparency = 1
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = head_btn

			local val_lbl = Instance.new("TextLabel")
			val_lbl.Text = tostring(sel) .. " ▼"
			val_lbl.Font = Library.Theme.bold
			val_lbl.TextSize = 11
			val_lbl.TextColor3 = Library.Theme.sub
			val_lbl.Position = UDim2.new(0.5, 0, 0, 0)
			val_lbl.Size = UDim2.new(0.5, -12, 0, 34)
			val_lbl.BackgroundTransparency = 1
			val_lbl.TextXAlignment = Enum.TextXAlignment.Right
			val_lbl.Parent = head_btn

			local opt_holder = Instance.new("Frame")
			opt_holder.Size = UDim2.new(1, -16, 0, #list * 26)
			opt_holder.Position = UDim2.new(0, 8, 0, 36)
			opt_holder.BackgroundTransparency = 1
			opt_holder.Parent = drop

			local opt_layout = Instance.new("UIListLayout")
			opt_layout.Padding = UDim.new(0, 2)
			opt_layout.Parent = opt_holder

			for _, opt_name in ipairs(list) do
				local o_btn = Instance.new("TextButton")
				o_btn.Size = UDim2.new(1, 0, 0, 24)
				o_btn.BackgroundColor3 = Library.Theme.sec
				o_btn.Text = tostring(opt_name)
				o_btn.Font = Library.Theme.font
				o_btn.TextSize = 11
				o_btn.TextColor3 = Library.Theme.sub
				o_btn.AutoButtonColor = false
				o_btn.Parent = opt_holder

				local o_crn = Instance.new("UICorner")
				o_crn.CornerRadius = UDim.new(0, 4)
				o_crn.Parent = o_btn

				o_btn.MouseEnter:Connect(function()
					tw(o_btn, 0.15, { BackgroundColor3 = Library.Theme.elm_hover, TextColor3 = Library.Theme.txt })
				end)
				o_btn.MouseLeave:Connect(function()
					tw(o_btn, 0.15, { BackgroundColor3 = Library.Theme.sec, TextColor3 = Library.Theme.sub })
				end)
				o_btn.MouseButton1Click:Connect(function()
					sel = opt_name
					val_lbl.Text = tostring(sel) .. " ▼"
					dropped = false
					tw(drop, 0.2, { Size = UDim2.new(1, 0, 0, 34) })
					cb(sel)
				end)
			end

			head_btn.MouseButton1Click:Connect(function()
				dropped = not dropped
				local target_size = dropped and UDim2.new(1, 0, 0, 42 + (#list * 26)) or UDim2.new(1, 0, 0, 34)
				tw(drop, 0.2, { Size = target_size })
			end)
		end

		-- Выбор бинда (Keybind)
		function tab_obj:CreateKeybind(name, def_key, cb)
			cb = cb or function() end
			local curr_key = def_key or Enum.KeyCode.E
			local listening = false

			local box = Instance.new("Frame")
			box.Size = UDim2.new(1, 0, 0, 34)
			box.BackgroundColor3 = Library.Theme.elm
			box.Parent = page

			local crn = Instance.new("UICorner")
			crn.CornerRadius = UDim.new(0, 6)
			crn.Parent = box

			local stk = Instance.new("UIStroke")
			stk.Color = Library.Theme.stroke
			stk.Thickness = 1
			stk.Parent = box

			local lbl = Instance.new("TextLabel")
			lbl.Text = name
			lbl.Font = Library.Theme.font
			lbl.TextSize = 12
			lbl.TextColor3 = Library.Theme.txt
			lbl.Position = UDim2.new(0, 10, 0, 0)
			lbl.Size = UDim2.new(0.6, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = box

			local bind_btn = Instance.new("TextButton")
			bind_btn.Size = UDim2.new(0, 70, 0, 22)
			bind_btn.Position = UDim2.new(1, -80, 0.5, -11)
			bind_btn.BackgroundColor3 = Library.Theme.sec
			bind_btn.Text = curr_key.Name
			bind_btn.Font = Library.Theme.bold
			bind_btn.TextSize = 11
			bind_btn.TextColor3 = Library.Theme.accent
			bind_btn.AutoButtonColor = false
			bind_btn.Parent = box

			local b_crn = Instance.new("UICorner")
			b_crn.CornerRadius = UDim.new(0, 4)
			b_crn.Parent = bind_btn

			local b_stk = Instance.new("UIStroke")
			b_stk.Color = Library.Theme.stroke
			b_stk.Thickness = 1
			b_stk.Parent = bind_btn

			bind_btn.MouseButton1Click:Connect(function()
				if listening then return end
				listening = true
				bind_btn.Text = "..."
				tw(b_stk, 0.15, { Color = Library.Theme.accent })

				local conn
				conn = uis.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.Keyboard then
						curr_key = inp.KeyCode
						bind_btn.Text = curr_key.Name
						tw(b_stk, 0.15, { Color = Library.Theme.stroke })
						listening = false
						conn:Disconnect()
					end
				end)
			end)

			uis.InputBegan:Connect(function(inp, gpe)
				if not gpe and not listening and inp.KeyCode == curr_key then
					cb(curr_key)
				end
			end)
		end

		-- Информационный текст (Paragraph/Label)
		function tab_obj:CreateParagraph(title, desc)
			local box = Instance.new("Frame")
			box.Size = UDim2.new(1, 0, 0, 0)
			box.AutomaticSize = Enum.AutomaticSize.Y
			box.BackgroundColor3 = Library.Theme.elm
			box.Parent = page

			local crn = Instance.new("UICorner")
			crn.CornerRadius = UDim.new(0, 6)
			crn.Parent = box

			local stk = Instance.new("UIStroke")
			stk.Color = Library.Theme.stroke
			stk.Thickness = 1
			stk.Parent = box

			local pad = Instance.new("UIPadding")
			pad.PaddingTop = UDim.new(0, 8)
			pad.PaddingBottom = UDim.new(0, 8)
			pad.PaddingLeft = UDim.new(0, 10)
			pad.PaddingRight = UDim.new(0, 10)
			pad.Parent = box

			local t = Instance.new("TextLabel")
			t.Text = title
			t.Font = Library.Theme.bold
			t.TextSize = 12
			t.TextColor3 = Library.Theme.txt
			t.Size = UDim2.new(1, 0, 0, 14)
			t.BackgroundTransparency = 1
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Parent = box

			local d = Instance.new("TextLabel")
			d.Text = desc
			d.Font = Library.Theme.font
			d.TextSize = 11
			d.TextColor3 = Library.Theme.sub
			d.Position = UDim2.new(0, 0, 0, 18)
			d.Size = UDim2.new(1, 0, 0, 0)
			d.AutomaticSize = Enum.AutomaticSize.Y
			d.BackgroundTransparency = 1
			d.TextXAlignment = Enum.TextXAlignment.Left
			d.TextWrapped = true
			d.Parent = box
		end

		return tab_obj
	end

	return window
end
