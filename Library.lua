--[[
	UI Library
	A tabbed window UI kit with a sidebar, themeable colors, tween-based
	animations, and a full component set (buttons, toggles, sliders,
	dropdowns, checkboxes, textboxes, sections, labels, notifications).
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local Library = {}
Library.__index = Library

--========================================================
-- THEME
--========================================================
local Theme = {
	Background   = Color3.fromRGB(24, 24, 27),
	Sidebar      = Color3.fromRGB(19, 19, 21),
	Elevated     = Color3.fromRGB(32, 32, 36),
	ElevatedHover= Color3.fromRGB(40, 40, 45),
	Stroke       = Color3.fromRGB(46, 46, 51),
	Accent       = Color3.fromRGB(114, 137, 255),
	AccentHover  = Color3.fromRGB(132, 152, 255),
	Text         = Color3.fromRGB(235, 235, 240),
	SubText      = Color3.fromRGB(150, 150, 158),
	Success      = Color3.fromRGB(90, 200, 130),
	Danger       = Color3.fromRGB(230, 90, 90),

	Font         = Enum.Font.GothamMedium,
	FontBold     = Enum.Font.GothamBold,

	CornerRadius = UDim.new(0, 8),
	Padding      = 12,
	ItemGap      = 8,
}

Library.Theme = Theme

--========================================================
-- UTILITIES
--========================================================
local function new(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do
		inst[prop] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = radius or Theme.CornerRadius })
end

local function stroke(color, thickness)
	return new("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(all, top, right, bottom, left)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, top or all or 0),
		PaddingRight = UDim.new(0, right or all or 0),
		PaddingBottom = UDim.new(0, bottom or all or 0),
		PaddingLeft = UDim.new(0, left or all or 0),
	})
end

local function listLayout(direction, gap, alignment)
	return new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or Theme.ItemGap),
		HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function tween(inst, props, duration, style, direction)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function makeDraggable(handle, target)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--========================================================
-- WINDOW
--========================================================
function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "My Library"
	local subtitle = config.Subtitle

	local ScreenGui = new("ScreenGui", {
		Name = "UILibrary",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local MainFrame = new("Frame", {
		Size = UDim2.new(0, 640, 0, 420),
		Position = UDim2.new(0.5, -320, 0.5, -210),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = ScreenGui,
	}, { corner(UDim.new(0, 10)), stroke(Theme.Stroke) })

	-- Title bar
	local TitleBar = new("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = MainFrame,
	}, { corner(UDim.new(0, 10)) })

	-- mask the bottom corners of the title bar so it reads as a flat top strip
	new("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = TitleBar,
	})

	local TitleText = new("TextLabel", {
		Size = subtitle and UDim2.new(1, -80, 0, 20) or UDim2.new(1, -80, 1, 0),
		Position = subtitle and UDim2.new(0, 16, 0, 6) or UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		Font = Theme.FontBold,
		TextSize = 16,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TitleBar,
	})

	if subtitle then
		new("TextLabel", {
			Size = UDim2.new(1, -80, 0, 16),
			Position = UDim2.new(0, 16, 0, 24),
			BackgroundTransparency = 1,
			Text = subtitle,
			Font = Theme.Font,
			TextSize = 12,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = TitleBar,
		})
	end

	local CloseBtn = new("TextButton", {
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -38, 0.5, -14),
		BackgroundColor3 = Theme.Elevated,
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 18,
		TextColor3 = Theme.SubText,
		AutoButtonColor = false,
		Parent = TitleBar,
	}, { corner(UDim.new(0, 6)) })

	CloseBtn.MouseEnter:Connect(function()
		tween(CloseBtn, { BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Text })
	end)
	CloseBtn.MouseLeave:Connect(function()
		tween(CloseBtn, { BackgroundColor3 = Theme.Elevated, TextColor3 = Theme.SubText })
	end)
	CloseBtn.MouseButton1Click:Connect(function()
		tween(MainFrame, { Size = UDim2.new(0, 640, 0, 0) }, 0.2)
		task.wait(0.2)
		ScreenGui:Destroy()
	end)

	makeDraggable(TitleBar, MainFrame)

	-- Sidebar (tab list)
	local Sidebar = new("Frame", {
		Size = UDim2.new(0, 150, 1, -46),
		Position = UDim2.new(0, 0, 0, 46),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = MainFrame,
	})

	local TabList = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Sidebar,
	}, {
		padding(10),
		listLayout(Enum.FillDirection.Vertical, 6),
	})

	-- Content area
	local ContentArea = new("Frame", {
		Size = UDim2.new(1, -150, 1, -46),
		Position = UDim2.new(0, 150, 0, 46),
		BackgroundTransparency = 1,
		Parent = MainFrame,
	}, { padding(Theme.Padding) })

	local Window = setmetatable({
		ScreenGui = ScreenGui,
		MainFrame = MainFrame,
		TabList = TabList,
		ContentArea = ContentArea,
		Tabs = {},
	}, Library)

	return Window
end

--========================================================
-- TABS
--========================================================
function Library:CreateTab(name, icon)
	local index = #self.Tabs + 1
	local isFirst = index == 1

	local TabButton = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = isFirst and Theme.Elevated or Theme.Sidebar,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = index,
		Parent = self.TabList,
	}, { corner(UDim.new(0, 6)) })

	new("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = (icon and (icon .. "  ") or "") .. name,
		Font = isFirst and Theme.FontBold or Theme.Font,
		TextSize = 13,
		TextColor3 = isFirst and Theme.Text or Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TabButton,
	})

	local Page = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = isFirst,
		Parent = self.ContentArea,
	}, {
		listLayout(Enum.FillDirection.Vertical, Theme.ItemGap),
	})

	local tabData = { Button = TabButton, Page = Page, Name = name }
	table.insert(self.Tabs, tabData)

	TabButton.MouseButton1Click:Connect(function()
		for _, t in ipairs(self.Tabs) do
			local active = t == tabData
			t.Page.Visible = active
			tween(t.Button, { BackgroundColor3 = active and Theme.Elevated or Theme.Sidebar })
			local label = t.Button:FindFirstChildOfClass("TextLabel")
			label.Font = active and Theme.FontBold or Theme.Font
			tween(label, { TextColor3 = active and Theme.Text or Theme.SubText })
		end
	end)

	TabButton.MouseEnter:Connect(function()
		if not Page.Visible then
			tween(TabButton, { BackgroundColor3 = Theme.Elevated })
		end
	end)
	TabButton.MouseLeave:Connect(function()
		if not Page.Visible then
			tween(TabButton, { BackgroundColor3 = Theme.Sidebar })
		end
	end)

	return Page
end

--========================================================
-- SHARED CARD BASE
-- every component sits on a rounded "card" with the label on top
--========================================================
local function baseCard(parent, height, layoutOrder)
	return new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Theme.Elevated,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 0,
		Parent = parent,
	}, { corner(), stroke() })
end

--========================================================
-- LABEL / SECTION HEADER
--========================================================
function Library:AddLabel(tab, text)
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Parent = tab,
	})
	new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	return card
end

function Library:AddSection(tab, text)
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Parent = tab,
	})
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 6),
		BackgroundTransparency = 1,
		Text = text:upper(),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	return card
end

--========================================================
-- BUTTON
--========================================================
function Library:AddButton(tab, text, callback)
	callback = callback or function() end
	local card = baseCard(tab, 44)

	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		AutoButtonColor = false,
		Parent = card,
	})

	btn.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = Theme.ElevatedHover })
	end)
	btn.MouseLeave:Connect(function()
		tween(card, { BackgroundColor3 = Theme.Elevated })
	end)
	btn.MouseButton1Click:Connect(function()
		tween(card, { BackgroundColor3 = Theme.Accent }, 0.08)
		task.wait(0.08)
		tween(card, { BackgroundColor3 = Theme.ElevatedHover }, 0.12)
		callback()
	end)

	return btn
end

--========================================================
-- TOGGLE
--========================================================
function Library:AddToggle(tab, text, default, callback)
	callback = callback or function() end
	local state = default or false

	local card = baseCard(tab, 44)

	new("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local Switch = new("Frame", {
		Size = UDim2.new(0, 42, 0, 22),
		Position = UDim2.new(1, -56, 0.5, -11),
		BackgroundColor3 = state and Theme.Accent or Theme.Stroke,
		Parent = card,
	}, { corner(UDim.new(1, 0)) })

	local Knob = new("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
		BackgroundColor3 = Theme.Text,
		Parent = Switch,
	}, { corner(UDim.new(1, 0)) })

	local ClickArea = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = card,
	})

	local function set(newState)
		state = newState
		tween(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.Stroke })
		tween(Knob, { Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) })
		callback(state)
	end

	ClickArea.MouseButton1Click:Connect(function()
		set(not state)
	end)

	return { Set = set, Get = function() return state end }
end

--========================================================
-- CHECKBOX (compact alternative to Toggle)
--========================================================
function Library:AddCheckbox(tab, text, default, callback)
	callback = callback or function() end
	local state = default or false

	local card = baseCard(tab, 40)

	local Box = new("Frame", {
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 12, 0.5, -10),
		BackgroundColor3 = state and Theme.Accent or Theme.Background,
		Parent = card,
	}, { corner(UDim.new(0, 5)), stroke(Theme.Stroke) })

	local Check = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "✓",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextTransparency = state and 0 or 1,
		Parent = Box,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 42, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local ClickArea = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = card,
	})

	local function set(newState)
		state = newState
		tween(Box, { BackgroundColor3 = state and Theme.Accent or Theme.Background })
		tween(Check, { TextTransparency = state and 0 or 1 })
		callback(state)
	end

	ClickArea.MouseButton1Click:Connect(function()
		set(not state)
	end)

	return { Set = set, Get = function() return state end }
end

--========================================================
-- SLIDER
--========================================================
function Library:AddSlider(tab, text, min, max, default, callback)
	callback = callback or function() end
	min, max = min or 0, max or 100
	local value = math.clamp(default or min, min, max)

	local card = baseCard(tab, 54)

	new("TextLabel", {
		Size = UDim2.new(1, -70, 0, 20),
		Position = UDim2.new(0, 14, 0, 6),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local ValueLabel = new("TextLabel", {
		Size = UDim2.new(0, 50, 0, 20),
		Position = UDim2.new(1, -64, 0, 6),
		BackgroundTransparency = 1,
		Text = tostring(value),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})

	local Track = new("Frame", {
		Size = UDim2.new(1, -28, 0, 6),
		Position = UDim2.new(0, 14, 1, -18),
		BackgroundColor3 = Theme.Stroke,
		Parent = card,
	}, { corner(UDim.new(1, 0)) })

	local Fill = new("Frame", {
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		Parent = Track,
	}, { corner(UDim.new(1, 0)) })

	local Knob = new("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7),
		BackgroundColor3 = Theme.Text,
		ZIndex = 2,
		Parent = Track,
	}, { corner(UDim.new(1, 0)) })

	local dragging = false

	local function updateFromInput(inputPos)
		local relative = math.clamp((inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		value = math.floor(min + (max - min) * relative + 0.5)
		Fill.Size = UDim2.new(relative, 0, 1, 0)
		Knob.Position = UDim2.new(relative, -7, 0.5, -7)
		ValueLabel.Text = tostring(value)
		callback(value)
	end

	Track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input.Position)
		end
	end)
	Track.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end)

	return {
		Set = function(v)
			v = math.clamp(v, min, max)
			updateFromInput(Vector2.new(Track.AbsolutePosition.X + (v - min) / (max - min) * Track.AbsoluteSize.X, 0))
		end,
		Get = function() return value end,
	}
end

--========================================================
-- TEXTBOX
--========================================================
function Library:AddTextbox(tab, placeholder, callback)
	callback = callback or function() end
	local card = baseCard(tab, 44)

	local Box = new("TextBox", {
		Size = UDim2.new(1, -28, 1, -16),
		Position = UDim2.new(0, 14, 0, 8),
		BackgroundColor3 = Theme.Background,
		PlaceholderText = placeholder,
		PlaceholderColor3 = Theme.SubText,
		Text = "",
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		Parent = card,
	}, { corner(UDim.new(0, 6)), padding(0, 0, 8, 0, 8) })

	Box.Focused:Connect(function()
		tween(card, { BackgroundColor3 = Theme.ElevatedHover })
	end)
	Box.FocusLost:Connect(function(enterPressed)
		tween(card, { BackgroundColor3 = Theme.Elevated })
		callback(Box.Text, enterPressed)
	end)

	return Box
end

--========================================================
-- DROPDOWN
--========================================================
function Library:AddDropdown(tab, text, options, default, callback)
	callback = callback or function() end
	options = options or {}
	local selected = default or options[1]
	local open = false

	local card = baseCard(tab, 44)
	card.ClipsDescendants = true
	card.ZIndex = 2

	new("TextLabel", {
		Size = UDim2.new(0.5, -14, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local Selected = new("TextButton", {
		Size = UDim2.new(0.5, -14, 0, 30),
		Position = UDim2.new(0.5, 0, 0, 7),
		BackgroundColor3 = Theme.Background,
		Text = tostring(selected) .. "  ▾",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		AutoButtonColor = false,
		Parent = card,
	}, { corner(UDim.new(0, 6)) })

	local OptionsList = new("Frame", {
		Size = UDim2.new(1, -28, 0, #options * 30),
		Position = UDim2.new(0, 14, 0, 48),
		BackgroundColor3 = Theme.Background,
		Visible = false,
		Parent = card,
	}, { corner(UDim.new(0, 6)), listLayout(Enum.FillDirection.Vertical, 0) })

	for i, option in ipairs(options) do
		local optBtn = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Theme.Background,
			Text = tostring(option),
			Font = Theme.Font,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			AutoButtonColor = false,
			LayoutOrder = i,
			Parent = OptionsList,
		})
		optBtn.MouseEnter:Connect(function()
			tween(optBtn, { BackgroundColor3 = Theme.ElevatedHover })
		end)
		optBtn.MouseLeave:Connect(function()
			tween(optBtn, { BackgroundColor3 = Theme.Background })
		end)
		optBtn.MouseButton1Click:Connect(function()
			selected = option
			Selected.Text = tostring(option) .. "  ▾"
			open = false
			OptionsList.Visible = false
			tween(card, { Size = UDim2.new(1, 0, 0, 44) })
			callback(option)
		end)
	end

	Selected.MouseButton1Click:Connect(function()
		open = not open
		OptionsList.Visible = open
		tween(card, { Size = open and UDim2.new(1, 0, 0, 48 + #options * 30 + 8) or UDim2.new(1, 0, 0, 44) })
	end)

	return {
		Set = function(v)
			selected = v
			Selected.Text = tostring(v) .. "  ▾"
		end,
		Get = function() return selected end,
	}
end

--========================================================
-- NOTIFICATION
--========================================================
function Library:Notify(title, text, duration)
	duration = duration or 3
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("UILibrary")
	if not gui then return end

	local holder = gui:FindFirstChild("NotificationHolder")
	if not holder then
		holder = new("Frame", {
			Name = "NotificationHolder",
			Size = UDim2.new(0, 280, 1, -20),
			Position = UDim2.new(1, -296, 0, 10),
			BackgroundTransparency = 1,
			Parent = gui,
		}, { listLayout(Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right) })
	end

	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = 1,
		Parent = holder,
	}, { corner(), stroke() })

	new("TextLabel", {
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.new(0, 12, 0, 8),
		BackgroundTransparency = 1,
		Text = title,
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -24, 0, 26),
		Position = UDim2.new(0, 12, 0, 28),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextTransparency = 1,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	tween(card, { BackgroundTransparency = 0 }, 0.25)
	for _, label in ipairs(card:GetChildren()) do
		if label:IsA("TextLabel") then
			tween(label, { TextTransparency = 0 }, 0.25)
		end
	end

	task.delay(duration, function()
		tween(card, { BackgroundTransparency = 1 }, 0.25)
		for _, label in ipairs(card:GetChildren()) do
			if label:IsA("TextLabel") then
				tween(label, { TextTransparency = 1 }, 0.25)
			end
		end
		task.wait(0.25)
		card:Destroy()
	end)
end

return Library
