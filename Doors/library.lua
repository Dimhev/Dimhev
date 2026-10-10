local core_gui = game:GetService("CoreGui")
local players = game:GetService("Players")
local tween_service = game:GetService("TweenService")
local user_input = game:GetService("UserInputService")
local run_service = game:GetService("RunService")

local local_player = players.LocalPlayer

local Moonlight = {}
Moonlight.__index = Moonlight

local theme = {
	background = Color3.fromRGB(8, 12, 22),
	sidebar = Color3.fromRGB(6, 9, 16),
	topbar = Color3.fromRGB(7, 10, 18),
	footer = Color3.fromRGB(6, 9, 16),
	card = Color3.fromRGB(12, 17, 30),
	card_stroke = Color3.fromRGB(26, 36, 62),
	card_divider = Color3.fromRGB(20, 28, 48),
	accent_purple = Color3.fromRGB(180, 105, 255),
	accent_glow = Color3.fromRGB(135, 75, 235),
	accent_stroke = Color3.fromRGB(175, 120, 255),
	toggle_off = Color3.fromRGB(16, 22, 38),
	toggle_off_stroke = Color3.fromRGB(28, 38, 64),
	knob_off = Color3.fromRGB(125, 140, 170),
	knob_on = Color3.fromRGB(255, 255, 255),
	row_hover = Color3.fromRGB(22, 30, 52),
	text_primary = Color3.fromRGB(240, 245, 255),
	text_secondary = Color3.fromRGB(195, 205, 225),
	text_muted = Color3.fromRGB(115, 130, 160),
	tab_active = Color3.fromRGB(16, 23, 40)
}

local function create(class_name, properties)
	local instance = Instance.new(class_name)
	for prop, val in pairs(properties or {}) do
		instance[prop] = val
	end
	return instance
end

function Moonlight:Notify(data)
	local notify_title = data.Title or "notification"
	local notify_content = data.Content or ""
	local duration = data.Duration or 4

	local gui = core_gui:FindFirstChild("moonlight_notify_gui")
	if not gui then
		gui = create("ScreenGui", {
			Name = "moonlight_notify_gui",
			Parent = core_gui,
			ResetOnSpawn = false
		})
	end

	local container = gui:FindFirstChild("container")
	if not container then
		container = create("Frame", {
			Name = "container",
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -280, 1, -25),
			AnchorPoint = Vector2.new(0, 1),
			Size = UDim2.new(0, 260, 1, -40),
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
		Size = UDim2.new(1, 0, 0, 62),
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
		Size = UDim2.new(1, -24, 0, 18),
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
		Position = UDim2.new(0, 12, 0, 28),
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

	tween_service:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
	tween_service:Create(title_lbl, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	tween_service:Create(desc_lbl, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()

	task.delay(duration, function()
		if card and card.Parent then
			local fade = tween_service:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
			tween_service:Create(title_lbl, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
			tween_service:Create(desc_lbl, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
			fade:Play()
			fade.Completed:Connect(function()
				card:Destroy()
			end)
		end
	end)
end

function Moonlight:CreateWindow(cfg)
	cfg = cfg or {}

	local gui = create("ScreenGui", {
		Name = "MoonlightGui",
		Parent = core_gui,
		ResetOnSpawn = false
	})

	local tooltip_frame = create("Frame", {
		Name = "MoonTooltip",
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(9, 13, 24),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 200,
		Parent = gui
	})
	create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = tooltip_frame })
	create("UIStroke", {
		Color = theme.card_stroke,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = tooltip_frame
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 9),
		PaddingRight = UDim.new(0, 9),
		Parent = tooltip_frame
	})

	local tooltip_label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.RobotoMono,
		TextColor3 = theme.text_secondary,
		TextSize = 11,
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 201,
		Parent = tooltip_frame
	})

	local function show_tooltip(text)
		if text and text ~= "" then
			tooltip_label.Text = text
			tooltip_frame.Visible = true
		end
	end

	local function hide_tooltip()
		tooltip_frame.Visible = false
	end

	user_input.InputChanged:Connect(function(input)
		if tooltip_frame.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
			tooltip_frame.Position = UDim2.new(0, input.Position.X + 14, 0, input.Position.Y + 14)
		end
	end)

	local main = create("Frame", {
		Size = UDim2.new(0, 750, 0, 500),
		Position = UDim2.new(0.5, -375, 0.5, -250),
		BackgroundColor3 = theme.background,
		BorderSizePixel = 0,
		Parent = gui
	})
	create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = main })
	create("UIStroke", {
		Color = theme.card_stroke,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = main
	})

	local topbar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = theme.topbar,
		BorderSizePixel = 0,
		Parent = main
	})
	create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = topbar })

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

	local icon_img = create("ImageLabel", {
		Position = UDim2.new(0, 14, 0.5, -11),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundTransparency = 1,
		Image = "rbxassetid://97257226725113",
		Parent = topbar
	})
	create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = icon_img })

	local title_label = create("TextLabel", {
		Position = UDim2.new(0, 44, 0, 0),
		Size = UDim2.new(0, 220, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.RobotoMono,
		Text = "By dimhev",
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topbar
	})

	local title_gradient = create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(150, 75, 240)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(215, 120, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 190, 255)),
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
		Position = UDim2.new(0, 0, 0, 45),
		Size = UDim2.new(0, 150, 1, -71),
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
		Position = UDim2.new(0, 150, 0, 45),
		Size = UDim2.new(1, -150, 1, -71),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = main
	})

	local footer = create("Frame", {
		Position = UDim2.new(0, 0, 1, -26),
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = theme.footer,
		BorderSizePixel = 0,
		Parent = main
	})
	create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = footer })

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
		Text = "Moonlight | By dimhev",
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

	function window:Destroy()
		if self.shimmer_conn then
			self.shimmer_conn:Disconnect()
			self.shimmer_conn = nil
		end
		if self.gui then
			self.gui:Destroy()
		end
	end

	function window:CreateTab(tab_name)
		local tab_btn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
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
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			Parent = page
		})

		local col_left = create("Frame", {
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0.5, -7, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = page
		})
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
			Parent = col_left
		})

		local col_right = create("Frame", {
			Position = UDim2.new(0.5, 7, 0, 0),
			Size = UDim2.new(0.5, -7, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = page
		})
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
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

		function tab:CreateSection(sec_name)
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
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = card
			})

			local header = create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Font = Enum.Font.RobotoMono,
				Text = sec_name,
				TextColor3 = theme.text_primary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card
			})

			local divider = create("Frame", {
				Position = UDim2.new(0, 0, 0, 24),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = theme.card_divider,
				BorderSizePixel = 0,
				Parent = card
			})

			local list = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 31),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = card
			})
			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				Parent = list
			})

			local section = {
				card = card,
				list = list
			}

			function section:CreateToggle(name, default_val, callback, desc)
				local state = default_val or false

				local row = create("Frame", {
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundColor3 = theme.row_hover,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Parent = self.list
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = row })
				create("UIPadding", {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					Parent = row
				})

				local label = create("TextLabel", {
					Size = UDim2.new(1, -48, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.RobotoMono,
					Text = name,
					TextColor3 = state and theme.text_primary or theme.text_secondary,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row
				})

				local toggle_bg = create("Frame", {
					Size = UDim2.new(0, 38, 0, 20),
					Position = UDim2.new(1, -38, 0.5, -10),
					BackgroundColor3 = state and theme.accent_glow or theme.toggle_off,
					BorderSizePixel = 0,
					Parent = row
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggle_bg })
				local toggle_stroke = create("UIStroke", {
					Color = state and theme.accent_stroke or theme.toggle_off_stroke,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = toggle_bg
				})

				local knob = create("Frame", {
					Size = UDim2.new(0, 14, 0, 14),
					Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
					BackgroundColor3 = state and theme.knob_on or theme.knob_off,
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

				btn.MouseEnter:Connect(function()
					tween_service:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = 0.9 }):Play()
					if desc then show_tooltip(desc) end
				end)

				btn.MouseLeave:Connect(function()
					tween_service:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
					hide_tooltip()
				end)

				btn.MouseButton1Click:Connect(function()
					state = not state
					local target_color = state and theme.accent_glow or theme.toggle_off
					local stroke_color = state and theme.accent_stroke or theme.toggle_off_stroke
					local knob_color = state and theme.knob_on or theme.knob_off
					local knob_pos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
					local text_color = state and theme.text_primary or theme.text_secondary

					tween_service:Create(toggle_bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = target_color }):Play()
					tween_service:Create(toggle_stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Color = stroke_color }):Play()
					tween_service:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = knob_pos, BackgroundColor3 = knob_color }):Play()
					tween_service:Create(label, TweenInfo.new(0.2), { TextColor3 = text_color }):Play()

					if callback then
						callback(state)
					end
				end)

				return row
			end

			function section:CreateButton(name, callback, desc)
				local row = create("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Parent = self.list
				})

				local btn_frame = create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = theme.sidebar,
					BorderSizePixel = 0,
					Font = Enum.Font.RobotoMono,
					Text = name,
					TextColor3 = theme.text_secondary,
					TextSize = 13,
					Parent = row
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn_frame })
				local btn_stroke = create("UIStroke", {
					Color = theme.card_stroke,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = btn_frame
				})

				btn_frame.MouseEnter:Connect(function()
					tween_service:Create(btn_frame, TweenInfo.new(0.15), { BackgroundColor3 = theme.row_hover, TextColor3 = theme.text_primary }):Play()
					tween_service:Create(btn_stroke, TweenInfo.new(0.15), { Color = theme.accent_purple }):Play()
					if desc then show_tooltip(desc) end
				end)

				btn_frame.MouseLeave:Connect(function()
					tween_service:Create(btn_frame, TweenInfo.new(0.15), { BackgroundColor3 = theme.sidebar, TextColor3 = theme.text_secondary }):Play()
					tween_service:Create(btn_stroke, TweenInfo.new(0.15), { Color = theme.card_stroke }):Play()
					hide_tooltip()
				end)

				btn_frame.MouseButton1Click:Connect(function()
					if callback then
						callback()
					end
				end)

				return btn_frame
			end

			function section:CreateSlider(name, min_val, max_val, default_val, callback, desc)
				min_val = min_val or 0
				max_val = max_val or 100
				local cur_val = math.clamp(default_val or min_val, min_val, max_val)

				local box = create("Frame", {
					Size = UDim2.new(1, 0, 0, 42),
					BackgroundColor3 = theme.row_hover,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Parent = self.list
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })
				create("UIPadding", {
					PaddingTop = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					Parent = box
				})

				local label = create("TextLabel", {
					Size = UDim2.new(1, -60, 0, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.RobotoMono,
					Text = name,
					TextColor3 = theme.text_secondary,
					TextSize = 13,
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
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = box
				})

				local bar = create("Frame", {
					Position = UDim2.new(0, 0, 0, 24),
					Size = UDim2.new(1, 0, 0, 6),
					BackgroundColor3 = theme.toggle_off,
					BorderSizePixel = 0,
					Parent = box
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
				create("UIStroke", {
					Color = theme.toggle_off_stroke,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = bar
				})

				local init_pct = (cur_val - min_val) / (max_val - min_val)
				local fill = create("Frame", {
					Size = UDim2.new(init_pct, 0, 1, 0),
					BackgroundColor3 = theme.accent_glow,
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

				box.MouseEnter:Connect(function()
					tween_service:Create(box, TweenInfo.new(0.15), { BackgroundTransparency = 0.9 }):Play()
					if desc then show_tooltip(desc) end
				end)

				box.MouseLeave:Connect(function()
					tween_service:Create(box, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
					hide_tooltip()
				end)

				return box
			end

			return section
		end

		return tab
	end

	return window
end

return Moonlight
