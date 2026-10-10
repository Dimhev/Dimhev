local core_gui = game:GetService("CoreGui")
local players = game:GetService("Players")
local tween_service = game:GetService("TweenService")
local user_input = game:GetService("UserInputService")
local run_service = game:GetService("RunService")

local local_player = players.LocalPlayer
local mouse = local_player:GetMouse()

local lib = {}
lib.__index = lib

local theme = {
	background = Color3.fromRGB(8, 12, 22),
	sidebar = Color3.fromRGB(6, 9, 16),
	topbar = Color3.fromRGB(7, 10, 18),
	footer = Color3.fromRGB(6, 9, 16),
	card = Color3.fromRGB(11, 16, 28),
	card_stroke = Color3.fromRGB(24, 34, 56),
	accent_purple = Color3.fromRGB(175, 100, 255),
	accent_active = Color3.fromRGB(130, 75, 230),
	toggle_off = Color3.fromRGB(18, 25, 42),
	text_primary = Color3.fromRGB(230, 235, 245),
	text_muted = Color3.fromRGB(120, 135, 165),
	tab_active = Color3.fromRGB(16, 22, 38)
}

local function create(class_name, properties)
	local instance = Instance.new(class_name)
	for prop, val in pairs(properties or {}) do
		instance[prop] = val
	end
	return instance
end

function lib.notify(data)
	local notify_title = data.Title or "notification"
	local notify_content = data.Content or ""
	local duration = data.Duration or 4

	local gui = core_gui:FindFirstChild("notify_ui")
	if not gui then
		gui = create("ScreenGui", {
			Name = "notify_ui",
			Parent = core_gui,
			ResetOnSpawn = false
		})
	end

	local container = gui:FindFirstChild("container")
	if not container then
		container = create("Frame", {
			Name = "container",
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -270, 1, -20),
			AnchorPoint = Vector2.new(0, 1),
			Size = UDim2.new(0, 250, 1, -40),
			Parent = gui
		})
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 8),
			Parent = container
		})
	end

	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = theme.card,
		BackgroundTransparency = 1,
		Parent = container
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = card })
	create("UIStroke", {
		Color = theme.card_stroke,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = card
	})

	local title_lbl = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 16),
		Font = Enum.Font.RobotoMono,
		Text = notify_title,
		TextColor3 = theme.accent_purple,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		Parent = card
	})

	local desc_lbl = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 26),
		Size = UDim2.new(1, -24, 0, 26),
		Font = Enum.Font.RobotoMono,
		Text = notify_content,
		TextColor3 = theme.text_muted,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = 1,
		Parent = card
	})

	tween_service:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
	tween_service:Create(title_lbl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	tween_service:Create(desc_lbl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

	task.delay(duration, function()
		if card and card.Parent then
			local fade = tween_service:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
			tween_service:Create(title_lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			tween_service:Create(desc_lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			fade:Play()
			fade.Completed:Connect(function()
				card:Destroy()
			end)
		end
	end)
end

function lib:create_window(cfg)
	cfg = cfg or {}
	local title_text = "By dimhev"

	local gui = create("ScreenGui", {
		Name = "moonlight_gui",
		Parent = core_gui,
		ResetOnSpawn = false
	})

	local main = create("Frame", {
		Size = UDim2.new(0, 720, 0, 480),
		Position = UDim2.new(0.5, -360, 0.5, -240),
		BackgroundColor3 = theme.background,
		BorderSizePixel = 0,
		Parent = gui
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = main })
	create("UIStroke", {
		Color = theme.card_stroke,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = main
	})

	local topbar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = theme.topbar,
		BorderSizePixel = 0,
		Parent = main
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = topbar })

	local top_fix = create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = theme.topbar,
		BorderSizePixel = 0,
		Parent = topbar
	})

	local top_divider = create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = theme.card_stroke,
		BorderSizePixel = 0,
		Parent = topbar
	})

	local title_label = create("TextLabel", {
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(0, 200, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.RobotoMono,
		Text = title_text,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topbar
	})

	local title_gradient = create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(150, 75, 240)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(215, 120, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 185, 255)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(195, 95, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(150, 75, 240))
		}),
		Parent = title_label
	})

	local shimmer_conn = run_service.RenderStepped:Connect(function()
		local offset = (tick() * 0.75) % 2 - 1
		title_gradient.Offset = Vector2.new(offset, 0)
	end)

	local dragging = false
	local drag_start = nil
	local start_pos = nil

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			drag_start = input.Position
			start_pos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	user_input.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - drag_start
			main.Position = UDim2.new(
				start_pos.X.Scale,
				start_pos.X.Offset + delta.X,
				start_pos.Y.Scale,
				start_pos.Y.Offset + delta.Y
			)
		end
	end)

	local sidebar = create("Frame", {
		Position = UDim2.new(0, 0, 0, 43),
		Size = UDim2.new(0, 140, 1, -67),
		BackgroundColor3 = theme.sidebar,
		BorderSizePixel = 0,
		Parent = main
	})

	local sidebar_divider = create("Frame", {
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = theme.card_stroke,
		BorderSizePixel = 0,
		Parent = sidebar
	})

	local tab_container = create("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(1, -1, 1, -16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar
	})

	local tab_layout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
		Parent = tab_container
	})

	local content_holder = create("Frame", {
		Position = UDim2.new(0, 140, 0, 43),
		Size = UDim2.new(1, -140, 1, -67),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = main
	})

	local footer = create("Frame", {
		Position = UDim2.new(0, 0, 1, -24),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = theme.footer,
		BorderSizePixel = 0,
		Parent = main
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = footer })

	local footer_fix = create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = theme.footer,
		BorderSizePixel = 0,
		Parent = footer
	})

	local footer_divider = create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = theme.card_stroke,
		BorderSizePixel = 0,
		Parent = footer
	})

	local footer_label = create("TextLabel", {
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -32, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.RobotoMono,
		Text = "moonlight project | By dimhev",
		TextColor3 = theme.text_muted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = footer
	})

	local window = {
		gui = gui,
		main = main,
		tabs = {},
		active_tab = nil,
		shimmer_conn = shimmer_conn
	}

	function window:destroy()
		if self.shimmer_conn then
			self.shimmer_conn:Disconnect()
			self.shimmer_conn = nil
		end
		if self.gui then
			self.gui:Destroy()
		end
	end

	function window:create_tab(tab_name)
		local tab_btn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			BackgroundColor3 = theme.tab_active,
			BorderSizePixel = 0,
			Font = Enum.Font.RobotoMono,
			Text = tab_name,
			TextColor3 = theme.text_muted,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tab_container
		})
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			Parent = tab_btn
		})

		local page = create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.card_stroke,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = content_holder
		})
		create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = page
		})

		local col_left = create("Frame", {
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0.5, -5, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = page
		})
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
			Parent = col_left
		})

		local col_right = create("Frame", {
			Position = UDim2.new(0.5, 5, 0, 0),
			Size = UDim2.new(0.5, -5, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = page
		})
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
			Parent = col_right
		})

		local tab = {
			name = tab_name,
			btn = tab_btn,
			page = page,
			col_left = col_left,
			col_right = col_right,
			sections_count = 0
		}

		local function select()
			for _, t in ipairs(window.tabs) do
				t.page.Visible = false
				t.btn.BackgroundTransparency = 1
				t.btn.TextColor3 = theme.text_muted
			end
			tab.page.Visible = true
			tab.btn.BackgroundTransparency = 0
			tab.btn.TextColor3 = theme.text_primary
			window.active_tab = tab
		end

		tab_btn.MouseButton1Click:Connect(select)

		table.insert(window.tabs, tab)
		if #window.tabs == 1 then
			select()
		end

		function tab:create_section(sec_name)
			self.sections_count = self.sections_count + 1
			local parent_col = (self.sections_count % 2 == 1) and self.col_left or self.col_right

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = theme.card,
				BorderSizePixel = 0,
				Parent = parent_col
			})
			create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = card })
			create("UIStroke", {
				Color = theme.card_stroke,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Parent = card
			})
			create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				Parent = card
			})

			local header = create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Font = Enum.Font.RobotoMono,
				Text = sec_name,
				TextColor3 = theme.text_primary,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card
			})

			local list = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 24),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = card
			})
			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				Parent = list
			})

			local section = {
				card = card,
				list = list
			}

			function section:create_toggle(name, default_val, callback, desc)
				local state = default_val or false

				local row = create("Frame", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					Parent = self.list
				})

				local label = create("TextLabel", {
					Size = UDim2.new(1, -44, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.RobotoMono,
					Text = name,
					TextColor3 = theme.text_primary,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row
				})

				local toggle_bg = create("Frame", {
					Size = UDim2.new(0, 36, 0, 18),
					Position = UDim2.new(1, -36, 0.5, -9),
					BackgroundColor3 = state and theme.accent_active or theme.toggle_off,
					BorderSizePixel = 0,
					Parent = row
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggle_bg })
				create("UIStroke", {
					Color = theme.card_stroke,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = toggle_bg
				})

				local knob = create("Frame", {
					Size = UDim2.new(0, 14, 0, 14),
					Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
					BackgroundColor3 = Color3.fromRGB(240, 245, 255),
					BorderSizePixel = 0,
					Parent = toggle_bg
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

				local btn = create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					Parent = row
				})

				btn.MouseButton1Click:Connect(function()
					state = not state
					local target_color = state and theme.accent_active or theme.toggle_off
					local target_pos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)

					tween_service:Create(toggle_bg, TweenInfo.new(0.2), { BackgroundColor3 = target_color }):Play()
					tween_service:Create(knob, TweenInfo.new(0.2), { Position = target_pos }):Play()

					if callback then
						callback(state)
					end
				end)

				return row
			end

			function section:create_button(name, callback)
				local btn_frame = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = theme.sidebar,
					BorderSizePixel = 0,
					Font = Enum.Font.RobotoMono,
					Text = name,
					TextColor3 = theme.text_primary,
					TextSize = 12,
					Parent = self.list
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn_frame })
				create("UIStroke", {
					Color = theme.card_stroke,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = btn_frame
				})

				btn_frame.MouseButton1Click:Connect(function()
					if callback then
						callback()
					end
				end)

				return btn_frame
			end

			function section:create_slider(name, min_val, max_val, default_val, callback)
				min_val = min_val or 0
				max_val = max_val or 100
				local cur_val = math.clamp(default_val or min_val, min_val, max_val)

				local box = create("Frame", {
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundTransparency = 1,
					Parent = self.list
				})

				local label = create("TextLabel", {
					Size = UDim2.new(1, -60, 0, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.RobotoMono,
					Text = name,
					TextColor3 = theme.text_primary,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = box
				})

				local val_label = create("TextLabel", {
					Position = UDim2.new(1, -60, 0, 0),
					Size = UDim2.new(0, 60, 0, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.RobotoMono,
					Text = tostring(cur_val),
					TextColor3 = theme.accent_purple,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = box
				})

				local bar = create("Frame", {
					Position = UDim2.new(0, 0, 0, 22),
					Size = UDim2.new(1, 0, 0, 6),
					BackgroundColor3 = theme.toggle_off,
					BorderSizePixel = 0,
					Parent = box
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

				local init_pct = (cur_val - min_val) / (max_val - min_val)
				local fill = create("Frame", {
					Size = UDim2.new(init_pct, 0, 1, 0),
					BackgroundColor3 = theme.accent_active,
					BorderSizePixel = 0,
					Parent = bar
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

				local sliding = false

				local function update(input)
					local abs_pos = bar.AbsolutePosition.X
					local abs_size = bar.AbsoluteSize.X
					local mouse_pos = input.Position.X
					local pct = math.clamp((mouse_pos - abs_pos) / abs_size, 0, 1)

					cur_val = math.floor(min_val + ((max_val - min_val) * pct))
					val_label.Text = tostring(cur_val)
					fill.Size = UDim2.new(pct, 0, 1, 0)

					if callback then
						callback(cur_val)
					end
				end

				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = true
						update(input)
					end
				end)

				user_input.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = false
					end
				end)

				user_input.InputChanged:Connect(function(input)
					if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						update(input)
					end
				end)

				return box
			end

			return section
		end

		return tab
	end

	return window
end

return lib
