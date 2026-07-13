--[[
	=====================================================================
	 AURORA UI  —  a beginner-friendly Roblox UI kit
	=====================================================================

	HOW TO USE THIS (quick start):

		1. Load the library:
			local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/JSY01-create/UI-Library/refs/heads/main/Library.lua"))()

		2. Create a window (this is the whole popup box you see):
			local Window = Library:CreateWindow({
				Title = "Aurora",
				Subtitle = "v1.0"
			})

		3. Create a tab (a page inside the window, shown in the sidebar):
			local MainTab = Window:CreateTab("Main", "🏠")

		4. Add stuff to the tab:
			Window:AddButton(MainTab, "Click me", function()
				print("The button was clicked!")
			end)

	That's really it. Every "Add___" function below always takes the tab
	you want to put it on as the FIRST argument, so it knows where to go.

	-----------------------------------------------------------------
	WHAT IS A "flag"?

	Some components (Toggle, Slider, Dropdown, Checkbox, Textbox,
	ColorPicker, Keybind) accept an optional last argument called
	`flag`. It's just a name you pick, like "FlyEnabled" or "WalkSpeed".

	If you give something a flag, the library remembers it, and you can
	later call Window:SaveConfig() / Window:LoadConfig() to save every
	flagged value to a file (or DataStore) and load it back later —
	handy for settings that should persist between sessions.

	You don't have to use flags. Everything works fine without them.
	-----------------------------------------------------------------

	This file is organised top-to-bottom like this:
		1. Services & setup
		2. Theme (all the colors/fonts/sizes live in ONE table)
		3. Small helper functions used everywhere else
		4. CreateWindow  (the popup box itself)
		5. CreateTab     (pages inside the window)
		6. Every component: Label, Section, Divider, Button, Toggle,
		   Checkbox, Slider, Textbox, Dropdown, ColorPicker, Keybind
		7. Notify (pop-up toast messages)
		8. Config saving/loading (JSON)

	Feel free to scroll to the THEME section first if you just want to
	change colors — you don't need to touch anything else for that.
]]

--=====================================================================
-- 1. SERVICES & SETUP
-- "Services" are Roblox's built-in tools. We grab the ones we need
-- once at the top so we don't have to ask for them again later.
--=====================================================================
local TweenService = game:GetService("TweenService")       -- makes things animate smoothly
local Players = game:GetService("Players")                 -- lets us find the local player
local HttpService = game:GetService("HttpService")         -- converts data to/from JSON text
local UserInputService = game:GetService("UserInputService") -- detects mouse/keyboard input
local RunService = game:GetService("RunService")           -- lets us wait a frame before reading layout sizes

local player = Players.LocalPlayer

-- Most executors expose a `gethui()` global that returns a dedicated,
-- more hidden container to parent GUIs into (instead of PlayerGui) —
-- it survives things like character resets more reliably and is the
-- de-facto standard place UI libraries are expected to parent into.
-- Not every environment has it (plain Roblox Studio doesn't), so we
-- fall back to PlayerGui when it's missing instead of erroring.
local function getGuiParent()
	if typeof(gethui) == "function" then
		local ok, result = pcall(gethui)
		if ok and result then
			return result
		end
	end
	return player:WaitForChild("PlayerGui")
end

-- If you run this script twice (e.g. from the Studio command bar while
-- testing), this deletes the old UI first so you don't end up with two
-- windows stacked on top of each other.
local existingGui = getGuiParent():FindFirstChild("Aurora")
if existingGui then
	existingGui:Destroy()
end

-- This is the "Library" table. Every function below is added onto it
-- with the `function Library:Something()` syntax, and at the very
-- bottom of the file we `return Library` so whoever loads this file
-- gets access to all of it.
local Library = {}
Library.__index = Library

-- This table stores every component that was given a `flag`, so config
-- saving/loading can find them later. You don't need to touch this.
Library.Flags = {}

--=====================================================================
-- LUCIDE ICONS
-- Tabs can show a proper icon (from the Lucide icon set, lucide.dev)
-- instead of just an emoji. This library doesn't download icons for
-- you automatically — executors sandbox/HttpGet unpredictably, so
-- baking in a live fetch would make tabs randomly break. Instead you
-- register the ones you want once, up front, and every CreateTab call
-- after that can just use the icon's name.
--
-- HOW TO GET ICON IDS:
--   Go to https://icons.rest (a searchable Lucide → Roblox asset id
--   catalogue) or https://github.com/latte-soft/lucide-roblox,
--   search for the icon you want (e.g. "home"), and copy the
--   rbxassetid it gives you.
--
-- HOW TO REGISTER THEM:
--   Library.Icons["home"] = "rbxassetid://10723407389"
--   Library.Icons["settings"] = "rbxassetid://10734950309"
--   -- or register many at once:
--   Library:SetIcons({
--       home = "rbxassetid://10723407389",
--       settings = "rbxassetid://10734950309",
--   })
--
-- HOW TO USE THEM:
--   local MainTab = Window:CreateTab("Main", "home")
--
-- If the name you pass isn't found in Library.Icons, CreateTab just
-- falls back to treating it as plain text/emoji (e.g. "🏠"), so
-- nothing breaks if you forget to register an icon.
--=====================================================================
Library.Icons = {}

function Library:SetIcons(icons)
	for name, assetId in pairs(icons or {}) do
		self.Icons[name] = assetId
	end
end

--=====================================================================
-- 2. THEME
-- Change any of these values to re-color the whole UI. Everything in
-- the library pulls its colors/fonts/sizes from here, so you only
-- ever need to edit this ONE table.
--=====================================================================
local Theme = {
	Background    = Color3.fromRGB(22, 22, 25),   -- main window background
	Sidebar       = Color3.fromRGB(14, 14, 16),    -- tab list + title bar background (noticeably darker than Background)
	Elevated      = Color3.fromRGB(34, 34, 39),    -- default color of buttons/cards (noticeably lighter than Background)
	ElevatedHover = Color3.fromRGB(44, 44, 50),    -- color of buttons/cards on hover
	Stroke        = Color3.fromRGB(56, 56, 63),    -- thin border color around cards
	Accent        = Color3.fromRGB(114, 137, 255), -- your "brand" color (toggles, sliders, active tab)
	AccentHover   = Color3.fromRGB(132, 152, 255),
	Text          = Color3.fromRGB(235, 235, 240), -- main text color
	SubText       = Color3.fromRGB(150, 150, 158), -- dimmer text color (descriptions, labels)
	Success       = Color3.fromRGB(90, 200, 130),
	Danger        = Color3.fromRGB(230, 90, 90),   -- used for the close button hover

	Font          = Enum.Font.GothamMedium,        -- normal text font
	FontBold      = Enum.Font.GothamBold,          -- bold text font (titles, active tab)

	CornerRadius  = UDim.new(0, 8),  -- how rounded corners are, in pixels
	Padding       = 16,              -- space around the inside edge of the content area
	ItemGap       = 6,               -- vertical space between components in a tab
}

Library.Theme = Theme -- exposed in case you want to read/tweak it from outside this file too

--=====================================================================
-- 2b. THEME PRESETS  —  swap the whole palette with one word
-- Instead of hand-editing the Theme table above, you can just call:
--
--     Library:SetTheme("Sakura")
--
-- ...before you create your window. Case doesn't matter ("sakura",
-- "SAKURA", "Sakura" all work), and a couple of friendly aliases are
-- supported too (e.g. "White" == "Light").
--
-- Built-in presets: "Dark" (default), "Light" (alias "White"), "Sakura",
-- "Midnight", "Ocean", "Crimson", "Grape", "Forest", "Amber", "Violet".
--
-- You can also add your own the same way any of those are defined below:
--     Library.ThemePresets.Slate = {
--         Background = Color3.fromRGB(20, 22, 26),
--         Sidebar = Color3.fromRGB(13, 14, 17),
--         Elevated = Color3.fromRGB(32, 35, 41),
--         ElevatedHover = Color3.fromRGB(41, 45, 52),
--         Stroke = Color3.fromRGB(51, 56, 65),
--         Accent = Color3.fromRGB(120, 190, 220),
--         AccentHover = Color3.fromRGB(145, 205, 230),
--         Text = Color3.fromRGB(235, 238, 240),
--         SubText = Color3.fromRGB(155, 163, 170),
--         Success = Color3.fromRGB(100, 205, 145),
--         Danger = Color3.fromRGB(230, 95, 95),
--     }
--     Library:SetTheme("Slate")
--
-- NOTE: call SetTheme BEFORE CreateWindow. Every component reads its
-- colors from the Theme table at the moment it's built, so the
-- palette needs to already be swapped in before the window (and its
-- tabs/components) get built — the same reason you'd pick a color
-- scheme before painting a room, not after. If you want to let a
-- player swap themes live from a dropdown, just rebuild the window
-- (destroy the old ScreenGui, call SetTheme, then CreateWindow again).
--=====================================================================
Library.ThemePresets = {
	Dark = {
		Background = Color3.fromRGB(22, 22, 25),
		Sidebar = Color3.fromRGB(14, 14, 16),
		Elevated = Color3.fromRGB(34, 34, 39),
		ElevatedHover = Color3.fromRGB(44, 44, 50),
		Stroke = Color3.fromRGB(56, 56, 63),
		Accent = Color3.fromRGB(114, 137, 255),
		AccentHover = Color3.fromRGB(132, 152, 255),
		Text = Color3.fromRGB(235, 235, 240),
		SubText = Color3.fromRGB(150, 150, 158),
		Success = Color3.fromRGB(90, 200, 130),
		Danger = Color3.fromRGB(230, 90, 90),
	},
	Light = {
		Background = Color3.fromRGB(246, 246, 249),
		Sidebar = Color3.fromRGB(224, 224, 231),
		Elevated = Color3.fromRGB(255, 255, 255),
		ElevatedHover = Color3.fromRGB(238, 238, 244),
		Stroke = Color3.fromRGB(212, 212, 220),
		Accent = Color3.fromRGB(88, 101, 242),
		AccentHover = Color3.fromRGB(109, 122, 255),
		Text = Color3.fromRGB(24, 24, 27),
		SubText = Color3.fromRGB(108, 108, 118),
		Success = Color3.fromRGB(45, 160, 100),
		Danger = Color3.fromRGB(215, 65, 65),
	},
	Sakura = {
		Background = Color3.fromRGB(28, 19, 24),
		Sidebar = Color3.fromRGB(18, 12, 16),
		Elevated = Color3.fromRGB(46, 32, 40),
		ElevatedHover = Color3.fromRGB(58, 41, 51),
		Stroke = Color3.fromRGB(72, 50, 61),
		Accent = Color3.fromRGB(245, 140, 181),
		AccentHover = Color3.fromRGB(250, 165, 199),
		Text = Color3.fromRGB(248, 237, 240),
		SubText = Color3.fromRGB(186, 154, 165),
		Success = Color3.fromRGB(130, 210, 160),
		Danger = Color3.fromRGB(235, 100, 120),
	},
	Midnight = {
		Background = Color3.fromRGB(12, 14, 22),
		Sidebar = Color3.fromRGB(6, 7, 13),
		Elevated = Color3.fromRGB(22, 26, 40),
		ElevatedHover = Color3.fromRGB(30, 35, 52),
		Stroke = Color3.fromRGB(41, 47, 66),
		Accent = Color3.fromRGB(99, 179, 255),
		AccentHover = Color3.fromRGB(130, 197, 255),
		Text = Color3.fromRGB(230, 236, 245),
		SubText = Color3.fromRGB(138, 148, 168),
		Success = Color3.fromRGB(84, 210, 160),
		Danger = Color3.fromRGB(235, 90, 100),
	},
	Ocean = {
		Background = Color3.fromRGB(13, 22, 25),
		Sidebar = Color3.fromRGB(7, 14, 16),
		Elevated = Color3.fromRGB(24, 40, 45),
		ElevatedHover = Color3.fromRGB(32, 52, 58),
		Stroke = Color3.fromRGB(43, 66, 72),
		Accent = Color3.fromRGB(64, 200, 197),
		AccentHover = Color3.fromRGB(94, 216, 213),
		Text = Color3.fromRGB(226, 245, 244),
		SubText = Color3.fromRGB(140, 172, 172),
		Success = Color3.fromRGB(100, 210, 150),
		Danger = Color3.fromRGB(235, 100, 95),
	},
	Crimson = {
		Background = Color3.fromRGB(22, 15, 16),
		Sidebar = Color3.fromRGB(14, 9, 9),
		Elevated = Color3.fromRGB(40, 25, 26),
		ElevatedHover = Color3.fromRGB(51, 32, 33),
		Stroke = Color3.fromRGB(65, 40, 41),
		Accent = Color3.fromRGB(230, 75, 80),
		AccentHover = Color3.fromRGB(240, 105, 108),
		Text = Color3.fromRGB(245, 234, 234),
		SubText = Color3.fromRGB(175, 145, 146),
		Success = Color3.fromRGB(110, 200, 140),
		Danger = Color3.fromRGB(250, 110, 110),
	},
	Grape = {
		Background = Color3.fromRGB(26, 20, 34),
		Sidebar = Color3.fromRGB(21, 16, 28),
		Elevated = Color3.fromRGB(38, 30, 48),
		ElevatedHover = Color3.fromRGB(46, 37, 58),
		Stroke = Color3.fromRGB(56, 45, 70),
		Accent = Color3.fromRGB(170, 110, 255),
		AccentHover = Color3.fromRGB(190, 140, 255),
		Text = Color3.fromRGB(240, 235, 245),
		SubText = Color3.fromRGB(160, 150, 170),
		Success = Color3.fromRGB(120, 200, 150),
		Danger = Color3.fromRGB(235, 95, 120),
	},
	Forest = {
		Background = Color3.fromRGB(16, 22, 18),
		Sidebar = Color3.fromRGB(10, 15, 12),
		Elevated = Color3.fromRGB(26, 36, 29),
		ElevatedHover = Color3.fromRGB(34, 46, 38),
		Stroke = Color3.fromRGB(45, 60, 49),
		Accent = Color3.fromRGB(96, 200, 120),
		AccentHover = Color3.fromRGB(120, 216, 142),
		Text = Color3.fromRGB(232, 242, 234),
		SubText = Color3.fromRGB(150, 172, 155),
		Success = Color3.fromRGB(110, 210, 140),
		Danger = Color3.fromRGB(230, 100, 95),
	},
	Amber = {
		Background = Color3.fromRGB(24, 19, 12),
		Sidebar = Color3.fromRGB(16, 12, 7),
		Elevated = Color3.fromRGB(42, 32, 20),
		ElevatedHover = Color3.fromRGB(53, 41, 26),
		Stroke = Color3.fromRGB(68, 52, 33),
		Accent = Color3.fromRGB(245, 165, 80),
		AccentHover = Color3.fromRGB(250, 185, 110),
		Text = Color3.fromRGB(245, 238, 228),
		SubText = Color3.fromRGB(178, 160, 138),
		Success = Color3.fromRGB(110, 200, 120),
		Danger = Color3.fromRGB(235, 95, 90),
	},
	Violet = {
		Background = Color3.fromRGB(20, 17, 30),
		Sidebar = Color3.fromRGB(13, 11, 21),
		Elevated = Color3.fromRGB(34, 28, 50),
		ElevatedHover = Color3.fromRGB(43, 36, 62),
		Stroke = Color3.fromRGB(54, 45, 76),
		Accent = Color3.fromRGB(140, 120, 255),
		AccentHover = Color3.fromRGB(165, 145, 255),
		Text = Color3.fromRGB(238, 235, 248),
		SubText = Color3.fromRGB(162, 155, 182),
		Success = Color3.fromRGB(110, 210, 150),
		Danger = Color3.fromRGB(235, 95, 110),
	},
}

-- friendly aliases, so people don't have to remember the "canonical" name
local ThemeAliases = {
	white = "Light",
	sakura = "Sakura",
	pink = "Sakura",
	dark = "Dark",
	black = "Midnight",
	blue = "Ocean",
	red = "Crimson",
	purple = "Grape",
	green = "Forest",
	orange = "Amber",
	gold = "Amber",
	indigo = "Violet",
}

-- Swaps every color in the Theme table for the named preset. Not case
-- sensitive. Returns true if a matching preset was found and applied,
-- false otherwise (Theme is left untouched if the name isn't found).
function Library:SetTheme(name)
	if typeof(name) ~= "string" then return false end

	local lower = name:lower()
	local presetName = ThemeAliases[lower]

	if not presetName then
		-- fall back to matching a preset key case-insensitively
		for key in pairs(self.ThemePresets) do
			if key:lower() == lower then
				presetName = key
				break
			end
		end
	end

	local preset = presetName and self.ThemePresets[presetName]
	if not preset then return false end

	for field, value in pairs(preset) do
		Theme[field] = value
	end
	return true
end

--=====================================================================
-- 3. HELPER FUNCTIONS
-- These are small building blocks used by every component below, so
-- we don't have to repeat the same code over and over. You shouldn't
-- need to edit these — but reading them will help you understand how
-- everything else works.
--=====================================================================

-- `new` creates a Roblox Instance (like a Frame, TextButton, etc),
-- sets its properties from a table, and parents any children to it.
-- Example: new("Frame", { Size = UDim2.new(1,0,1,0) }, { someChild })
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

-- Adds rounded corners to whatever it's parented to.
local function corner(radius)
	return new("UICorner", { CornerRadius = radius or Theme.CornerRadius })
end

-- Adds a thin outline border to whatever it's parented to.
local function stroke(color, thickness)
	return new("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- A small "V" shaped chevron/arrow icon, built from two rotated bars
-- instead of a unicode arrow character. The Gotham fonts this library
-- uses everywhere else don't ship a glyph for "▾", so text arrows can
-- silently render as nothing — this always renders, in any font.
-- AnchorPoint is centered, so `Position` should be the CENTER point
-- you want the arrow at, and rotating it (e.g. in a tween) spins it
-- neatly in place instead of drifting.
local function chevron(size, color, thickness)
	size = size or 10
	thickness = thickness or 2
	local icon = new("Frame", {
		Size = UDim2.new(0, size, 0, size),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	})
	local legLength = size * 0.62
	new("Frame", {
		Size = UDim2.new(0, legLength, 0, thickness),
		Position = UDim2.new(0, 0, 0.32, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Rotation = 45,
		BackgroundColor3 = color or Theme.SubText,
		BorderSizePixel = 0,
		Parent = icon,
	}, { corner(UDim.new(1, 0)) })
	new("Frame", {
		Size = UDim2.new(0, legLength, 0, thickness),
		Position = UDim2.new(1, 0, 0.32, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Rotation = -45,
		BackgroundColor3 = color or Theme.SubText,
		BorderSizePixel = 0,
		Parent = icon,
	}, { corner(UDim.new(1, 0)) })
	return icon
end

-- Adds inner spacing (like CSS "padding") to whatever it's parented to.
local function padding(all, top, right, bottom, left)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, top or all or 0),
		PaddingRight = UDim.new(0, right or all or 0),
		PaddingBottom = UDim.new(0, bottom or all or 0),
		PaddingLeft = UDim.new(0, left or all or 0),
	})
end

-- Automatically stacks children in a row/column with even spacing,
-- so we never have to manually calculate pixel positions.
local function listLayout(direction, gap, alignment)
	return new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or Theme.ItemGap),
		HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

-- Smoothly animates a property change (e.g. color, size, position)
-- instead of it snapping instantly. Used for basically every hover
-- effect / toggle switch / slider movement in this library.
local function tween(inst, props, duration, style, direction)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

-- Makes `target` movable by clicking and dragging `handle`.
-- Used so you can drag the window around by its title bar.
--
-- IMPORTANT: we listen for mouse movement on UserInputService (global,
-- covers the whole screen) rather than on `handle` itself. If we used
-- handle.InputChanged instead, moving the mouse fast enough to outrun
-- the title bar's hitbox for a single frame would stop the drag from
-- receiving updates — which is exactly why fast drags used to feel
-- like the cursor "left" the UI and the window fell behind it.
local function makeDraggable(handle, target)
	local dragging, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	-- stop dragging once the mouse/finger is released, no matter where
	-- on screen that happens (also global, for the same reason as above)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--=====================================================================
-- 4. CREATE WINDOW
-- This builds the actual popup box: the title bar, the sidebar where
-- tabs are listed, and the empty content area where each tab's
-- components will go.
--=====================================================================

-- config = { Title = "text shown at the top", Subtitle = "optional smaller text under it", Theme = "optional theme name, e.g. \"Sakura\"" }
function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Aurora"
	local subtitle = config.Subtitle

	if config.Theme then
		self:SetTheme(config.Theme)
	end

	-- ScreenGui is the container every other UI element lives inside.
	local ScreenGui = new("ScreenGui", {
		Name = "Aurora",
		ResetOnSpawn = false, -- keeps the UI alive when the player respawns
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getGuiParent(),
	})

	-- Figure out how much screen we've actually got. On a phone that's a
	-- lot smaller than a desktop window, so instead of a fixed 640x420
	-- (which would spill off the edges of a phone screen) we clamp the
	-- window to whatever fits, with sane min/max bounds either way.
	--
	-- The window height is fixed — every tab renders at the same size no
	-- matter how many components it has. A tab with only 2 components
	-- still gets the full-height window instead of shrinking down to fit
	-- just those 2; a tab with more components than fit just scrolls
	-- (every Page is already a ScrollingFrame, so this happens for free).
	local camera = workspace.CurrentCamera
	local viewport = (camera and camera.ViewportSize) or Vector2.new(1280, 720)
	local MIN_WINDOW_HEIGHT = 200 -- floor, only relevant on very short/small screens
	local function maxWindowHeight()
		local vp = (camera and camera.ViewportSize) or Vector2.new(1280, 720)
		return math.clamp(vp.Y - 100, MIN_WINDOW_HEIGHT, 480)
	end
	local windowWidth = math.clamp(viewport.X - 24, 300, 640)
	local windowHeight = math.clamp(420, MIN_WINDOW_HEIGHT, maxWindowHeight()) -- fixed height for every tab, always

	-- The main box itself.
	local MainFrame = new("Frame", {
		Size = UDim2.new(0, windowWidth, 0, windowHeight),
		Position = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2), -- centered on screen
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true, -- hides anything that overflows the box's edges
		Parent = ScreenGui,
	}, { corner(UDim.new(0, 10)), stroke(Theme.Stroke) })

	-- Tracks whether the window is currently minimized (see the Minimize
	-- button below), and remembers the "should be this tall when open"
	-- height so restoring it always lands back at the right size, even
	-- after a phone rotation resizes the window in between.
	local minimized = false
	local expandedHeight = windowHeight

	-- forward-declared so the minimize button below (created before these
	-- exist further down) can still reference the real instances once
	-- they're assigned, instead of accidentally creating new globals
	local Sidebar, ContentArea

	-- same idea: the bubble button's tap-to-restore handler needs to call
	-- setMinimized before it's actually defined further down, and
	-- Window:Destroy() needs destroyWindow before IT exists too
	local setMinimized, destroyWindow

	-- Re-run the sizing above any time the screen changes size, e.g. a
	-- phone being rotated between portrait and landscape.
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local vp = camera.ViewportSize
			windowWidth = math.clamp(vp.X - 24, 300, 640)
			-- re-clamp the height we already fit to content, rather than
			-- resetting it to the full viewport — a short tab should stay
			-- short after a rotation instead of snapping to max height
			expandedHeight = math.clamp(expandedHeight, MIN_WINDOW_HEIGHT, maxWindowHeight())
			local targetHeight = minimized and 46 or expandedHeight
			MainFrame.Size = UDim2.new(0, windowWidth, 0, targetHeight)
			MainFrame.Position = UDim2.new(0.5, -windowWidth / 2, 0.5, -targetHeight / 2)
		end)
	end

	--------------------------------------------------------------
	-- Title bar (top strip with the window name + close button)
	--------------------------------------------------------------
	local TitleBar = new("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = MainFrame,
	}, { corner(UDim.new(0, 10)) })

	-- The corner() above rounds ALL four corners of the title bar, but
	-- we only want the top two rounded (it should sit flush with the
	-- content below). This little frame just covers up the bottom
	-- rounding so it looks like a flat-bottomed strip.
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

	-- Minimize ("—") button — sits just left of the close button. Works
	-- the same way for touch as it does for a mouse: TextButton's
	-- MouseButton1Click fires for taps too, no extra input handling
	-- needed.
	local MinimizeBtn = new("TextButton", {
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -72, 0.5, -14),
		BackgroundColor3 = Theme.Elevated,
		Text = "-",
		Font = Theme.FontBold,
		TextSize = 16,
		TextColor3 = Theme.SubText,
		AutoButtonColor = false,
		Parent = TitleBar,
	}, { corner(UDim.new(0, 6)) })

	MinimizeBtn.MouseEnter:Connect(function()
		tween(MinimizeBtn, { BackgroundColor3 = Theme.ElevatedHover, TextColor3 = Theme.Text })
	end)
	MinimizeBtn.MouseLeave:Connect(function()
		tween(MinimizeBtn, { BackgroundColor3 = Theme.Elevated, TextColor3 = Theme.SubText })
	end)

	-- Small floating circular button that takes the window's place while
	-- minimized, instead of the window just collapsing down to its title
	-- bar. Tap it to bring the window back. It's draggable too, so it
	-- can be moved out of the way of whatever's happening on screen.
	-- Starts hidden — only shown while minimized.
	local minimizedIcon = config.MinimizedIcon or "rbxassetid://108404355009354"
	local BubbleButton = new("ImageButton", {
		Size = UDim2.new(0, 50, 0, 50),
		BackgroundColor3 = Theme.Elevated,
		Image = minimizedIcon,
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = Theme.Text,
		Visible = false,
		AutoButtonColor = false,
		ZIndex = 10,
		Parent = ScreenGui,
	}, { corner(UDim.new(1, 0)), stroke(Theme.Stroke) }) -- UDim.new(1,0) always yields a full circle on a square button

	BubbleButton.MouseEnter:Connect(function()
		tween(BubbleButton, { BackgroundColor3 = Theme.ElevatedHover })
	end)
	BubbleButton.MouseLeave:Connect(function()
		tween(BubbleButton, { BackgroundColor3 = Theme.Elevated })
	end)

	-- The bubble is both draggable AND clickable, which normally
	-- conflict (a drag ends in a MouseButton1Click same as a tap does).
	-- This tracks how far the pointer actually moved between press and
	-- release — under the threshold counts as a tap (restore the
	-- window), over it counts as a drag (just leave the bubble there).
	do
		local BUBBLE_TAP_THRESHOLD = 6 -- pixels
		local dragging, dragStart, startPos, moved = false, nil, nil, false

		BubbleButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				moved = false
				dragStart = input.Position
				startPos = BubbleButton.Position
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				if not moved and delta.Magnitude > BUBBLE_TAP_THRESHOLD then
					moved = true
				end
				BubbleButton.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				if not moved then
					setMinimized(false) -- short tap, not a drag — treat it as "restore"
				end
			end
		end)
	end

	-- Shared by the minimize button, the bubble's tap-to-restore above,
	-- and Window:Minimize() / Window:Restore(), so every path animates
	-- the exact same way and can't drift out of sync with each other.
	setMinimized = function(state)
		if state == minimized then return end -- already there, nothing to do
		minimized = state
		if minimized then
			Sidebar.Visible = false
			ContentArea.Visible = false
			-- the bubble picks up roughly where the window's title bar
			-- was, so it feels like the window shrank into it
			local mainPos = MainFrame.Position
			BubbleButton.Position = UDim2.new(mainPos.X.Scale, mainPos.X.Offset, mainPos.Y.Scale, mainPos.Y.Offset)
			tween(MainFrame, { Size = UDim2.new(0, windowWidth, 0, 0) }, 0.18)
			task.wait(0.18)
			MainFrame.Visible = false
			BubbleButton.Visible = true
			BubbleButton.Size = UDim2.new(0, 0, 0, 0)
			tween(BubbleButton, { Size = UDim2.new(0, 50, 0, 50) }, 0.15)
		else
			BubbleButton.Visible = false
			-- reopen wherever the bubble ended up (in case it got
			-- dragged), rather than snapping back to its original spot
			local bubblePos = BubbleButton.Position
			MainFrame.Position = UDim2.new(bubblePos.X.Scale, bubblePos.X.Offset, bubblePos.Y.Scale, bubblePos.Y.Offset)
			MainFrame.Size = UDim2.new(0, windowWidth, 0, 0)
			MainFrame.Visible = true
			tween(MainFrame, { Size = UDim2.new(0, windowWidth, 0, expandedHeight) }, 0.18)
			task.wait(0.18)
			-- only reveal these again once the window has actually
			-- finished growing back, so nothing pokes out mid-tween
			Sidebar.Visible = true
			ContentArea.Visible = true
		end
	end

	MinimizeBtn.MouseButton1Click:Connect(function()
		setMinimized(not minimized)
	end)

	-- Close ("X") button, top right of the title bar.
	local CloseBtn = new("TextButton", {
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -38, 0.5, -14),
		BackgroundColor3 = Theme.Elevated,
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 18,
		TextColor3 = Theme.SubText,
		AutoButtonColor = false, -- we handle hover coloring ourselves below
		Parent = TitleBar,
	}, { corner(UDim.new(0, 6)) })

	CloseBtn.MouseEnter:Connect(function()
		tween(CloseBtn, { BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Text })
	end)
	CloseBtn.MouseLeave:Connect(function()
		tween(CloseBtn, { BackgroundColor3 = Theme.Elevated, TextColor3 = Theme.SubText })
	end)

	-- Shared by the × button and by Window:Destroy().
	destroyWindow = function()
		-- shrink the window down to nothing, then delete it (this also
		-- takes the bubble button with it, if it happened to be
		-- minimized at the time — it's a descendant of ScreenGui too)
		tween(MainFrame, { Size = UDim2.new(0, windowWidth, 0, 0) }, 0.2)
		task.wait(0.2)
		ScreenGui:Destroy()
	end

	CloseBtn.MouseButton1Click:Connect(destroyWindow)

	-- Let the player drag the whole window by holding the title bar.
	makeDraggable(TitleBar, MainFrame)

	--------------------------------------------------------------
	-- Sidebar (the list of tabs on the left)
	--------------------------------------------------------------
	Sidebar = new("Frame", {
		Size = UDim2.new(0, 150, 1, -46),
		Position = UDim2.new(0, 0, 0, 46),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = MainFrame,
	}, { corner(UDim.new(0, 10)) })

	-- The corner() above rounds all four of the sidebar's corners, but
	-- only the bottom-left one actually sits on top of MainFrame's
	-- rounded corner (the top-left is tucked under the title bar, and
	-- the right two are interior corners against the content area) —
	-- so without this, the sidebar's own rounding would poke a curved
	-- notch into those three straight edges. These two patches just
	-- square them back off, matching the exact bug-fix trick used for
	-- the title bar above, leaving only the bottom-left corner rounded.
	new("Frame", {
		Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = Sidebar,
	})
	new("Frame", {
		Size = UDim2.new(0, 10, 1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = Sidebar,
	})

	-- Tab buttons get added inside this ScrollingFrame so if you add
	-- LOTS of tabs, the sidebar becomes scrollable instead of overflowing.
	local TabList = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),        -- start at 0, AutomaticCanvasSize grows it for us
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Sidebar,
	}, {
		padding(10),
		listLayout(Enum.FillDirection.Vertical, 6),
	})

	--------------------------------------------------------------
	-- Content area (where the currently-selected tab's page shows)
	--------------------------------------------------------------
	ContentArea = new("Frame", {
		Size = UDim2.new(1, -150, 1, -46),
		Position = UDim2.new(0, 150, 0, 46),
		BackgroundTransparency = 1,
		Parent = MainFrame,
	})
	-- No padding on ContentArea itself: each tab's Page (see CreateTab)
	-- owns its own inset now, so there's exactly one place controlling
	-- it instead of two paddings potentially stacking on top of each
	-- other.

	-- A deliberate hairline where the sidebar meets the content area.
	-- Without this, that seam is just two flat colors touching directly,
	-- and at small sizes / lower rendering quality (e.g. on phones) the
	-- boundary can look like it has a stray shadow or notch along it —
	-- an explicit divider line reads as intentional instead.
	new("Frame", {
		Size = UDim2.new(0, 1, 1, -46),
		Position = UDim2.new(0, 150, 0, 46),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = MainFrame,
	})

	-- `Window` is what gets returned to you. Every Add___ function is
	-- called like Window:AddButton(...), and internally it's really
	-- just calling the Library functions below with `self` = Window.
	local Window = setmetatable({
		ScreenGui = ScreenGui,
		MainFrame = MainFrame,
		TabList = TabList,
		ContentArea = ContentArea,
		Tabs = {}, -- keeps track of every tab created, so clicking one can hide the others

		----------------------------------------------------------------
		-- Window-level controls
		----------------------------------------------------------------

		-- Show/Hide/Toggle just flip the whole ScreenGui on or off —
		-- instant, no animation. Nothing is destroyed, so every toggle
		-- state, slider value, textbox contents, etc. are exactly as
		-- you left them when you Show() it again. Handy for binding to
		-- a keybind (e.g. RightShift) to tuck the whole menu away.
		Show = function(self)
			self.ScreenGui.Enabled = true
		end,
		Hide = function(self)
			self.ScreenGui.Enabled = false
		end,
		Toggle = function(self)
			self.ScreenGui.Enabled = not self.ScreenGui.Enabled
		end,
		IsVisible = function(self)
			return self.ScreenGui.Enabled
		end,

		-- Minimize/Restore/ToggleMinimize swap the window for the small
		-- floating circular button, just callable from code too — e.g.
		-- auto-minimizing while the player is in combat.
		Minimize = function(self)
			setMinimized(true)
		end,
		Restore = function(self)
			setMinimized(false)
		end,
		ToggleMinimize = function(self)
			setMinimized(not minimized)
		end,
		IsMinimized = function(self)
			return minimized
		end,

		-- Destroy tears the window down with the same shrink animation
		-- as the × button, then removes the ScreenGui entirely. Unlike
		-- Hide(), this is permanent — call CreateWindow again if you
		-- want a new one afterward.
		Destroy = function(self)
			destroyWindow()
		end,
	}, Library)

	return Window
end

--=====================================================================
-- 5. CREATE TAB
-- Adds a new button to the sidebar, and a matching (initially hidden,
-- unless it's the first tab) page in the content area. Returns the
-- page — pass THIS into every AddButton/AddToggle/etc call so the
-- library knows which tab to put the component on.
--=====================================================================

-- name = text shown in the sidebar.
-- icon = optional. Either:
--   • the name of an icon registered via Library.Icons / Library:SetIcons
--     (renders as a real Lucide icon image), or
--   • any other string (e.g. an emoji like "🏠"), which is just shown
--     as text in front of the tab name, same as before.
function Library:CreateTab(name, icon)
	local index = #self.Tabs + 1
	local isFirst = index == 1 -- the first tab created is automatically the one shown by default

	-- Is `icon` a name we have a real Lucide icon registered for?
	local iconAsset = icon and self.Icons and self.Icons[icon]

	local TabButton = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = isFirst and Theme.Elevated or Theme.Sidebar,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = index,
		Parent = self.TabList,
	}, { corner(UDim.new(0, 6)) })

	local IconImage
	if iconAsset then
		-- Real icon: small image on the left, label starts after it.
		IconImage = new("ImageLabel", {
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, 14, 0.5, -8),
			BackgroundTransparency = 1,
			Image = iconAsset,
			ImageColor3 = isFirst and Theme.Text or Theme.SubText,
			Parent = TabButton,
		})
	end

	local TabLabel = new("TextLabel", {
		Size = iconAsset and UDim2.new(1, -40, 1, 0) or UDim2.new(1, -20, 1, 0),
		Position = iconAsset and UDim2.new(0, 38, 0, 0) or UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		-- no registered icon, but `icon` was passed anyway -> treat it as
		-- an emoji/text prefix, exactly like before
		Text = (icon and not iconAsset and (icon .. "  ") or "") .. name,
		Font = isFirst and Theme.FontBold or Theme.Font,
		TextSize = 13,
		TextColor3 = isFirst and Theme.Text or Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TabButton,
	})

	-- The actual page. Every component you add goes inside this.
	local Page = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, -- grows as you add components; scrolls once it outgrows the fixed window height
		Visible = isFirst,
		Parent = self.ContentArea,
	}, {
		listLayout(Enum.FillDirection.Vertical, Theme.ItemGap),
		-- top/left: breathing room so cards aren't flush against the
		-- window's edge. right: clears the scrollbar so cards don't butt
		-- up against it. bottom: without this the last card sits flush
		-- against the very bottom edge of the window.
		padding(0, 10, 12, 14, 14),
	})

	local tabData = { Button = TabButton, Page = Page, Name = name }
	table.insert(self.Tabs, tabData)

	-- Clicking a tab button: show its page, hide every other page, and
	-- re-color all the tab buttons so only the active one is highlighted.
	TabButton.MouseButton1Click:Connect(function()
		for _, t in ipairs(self.Tabs) do
			local active = t == tabData
			t.Page.Visible = active
			tween(t.Button, { BackgroundColor3 = active and Theme.Elevated or Theme.Sidebar })
			local label = t.Button:FindFirstChildOfClass("TextLabel")
			label.Font = active and Theme.FontBold or Theme.Font
			tween(label, { TextColor3 = active and Theme.Text or Theme.SubText })
			local iconImg = t.Button:FindFirstChildOfClass("ImageLabel")
			if iconImg then
				tween(iconImg, { ImageColor3 = active and Theme.Text or Theme.SubText })
			end
		end
	end)

	-- Small hover highlight for inactive tabs.
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

--=====================================================================
-- 6. COMPONENTS
-- Everything below adds ONE type of element to a tab. They all start
-- with `tab` as the first argument — that's the Page you got back
-- from Window:CreateTab(...).
--=====================================================================

-- Small helper: every component (Button, Toggle, Slider, etc.) sits on
-- a rounded rectangle "card" of a given height. This just saves us
-- from repeating the same 6 lines in every single component below.
local function baseCard(parent, height, layoutOrder)
	return new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Theme.Elevated,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 0,
		Parent = parent,
	}, { corner(), stroke() })
end

----------------------------------------------------------------------
-- LABEL — just a plain line of text. Good for instructions/info.
-- Window:AddLabel(Tab, "This is a label")
----------------------------------------------------------------------
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

----------------------------------------------------------------------
-- SECTION — a small bold uppercase heading, used to group components.
-- Window:AddSection(Tab, "Movement")
----------------------------------------------------------------------
function Library:AddSection(tab, text)
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Parent = tab,
	})
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 4),
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

----------------------------------------------------------------------
-- DIVIDER — a thin horizontal line, useful for separating groups.
-- Window:AddDivider(Tab)
----------------------------------------------------------------------
function Library:AddDivider(tab)
	local wrap = new("Frame", {
		Size = UDim2.new(1, 0, 0, 13),
		BackgroundTransparency = 1,
		Parent = tab,
	})
	new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0,
		Parent = wrap,
	})
	return wrap
end

----------------------------------------------------------------------
-- BUTTON — a label on the left, and a small clickable button on the
-- right that runs `callback` when pressed — same left-label/
-- right-control layout as Toggle and Checkbox use.
-- Window:AddButton(Tab, "Click me", function() print("clicked") end)
----------------------------------------------------------------------
function Library:AddButton(tab, text, callback)
	callback = callback or function() end -- if you forget to pass a callback, this just does nothing instead of erroring
	local card = baseCard(tab, 38)

	new("TextLabel", {
		Size = UDim2.new(1, -110, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- the actual clickable control, right-aligned with the same 14px
	-- margin the Toggle switch / Slider value / Keybind box all use
	local btn = new("TextButton", {
		Size = UDim2.new(0, 84, 0, 28),
		Position = UDim2.new(1, -98, 0.5, -14),
		BackgroundColor3 = Theme.ElevatedHover,
		Text = "Run",
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		AutoButtonColor = false,
		Parent = card,
	}, { corner(UDim.new(0, 6)), stroke() })

	-- lighten on hover, flash the accent color on click — same feel as
	-- before, just scoped to the small button instead of the whole card
	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.Accent })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.ElevatedHover })
	end)
	btn.MouseButton1Click:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.AccentHover }, 0.08)
		task.wait(0.08)
		tween(btn, { BackgroundColor3 = Theme.ElevatedHover }, 0.12)
		callback()
	end)

	return btn
end

----------------------------------------------------------------------
-- TOGGLE — an on/off switch.
-- Window:AddToggle(Tab, "Enable Fly", false, function(state) print(state) end, "FlyEnabled")
--   tab      = the page to put it on
--   text     = label shown next to the switch
--   default  = true/false, starting state
--   callback = function that runs whenever it's flipped, receives the new state
--   flag     = (optional) name used for config saving, see the top of this file
----------------------------------------------------------------------
function Library:AddToggle(tab, text, default, callback, flag)
	callback = callback or function() end
	local state = default or false

	local card = baseCard(tab, 38)

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

	-- the pill-shaped track behind the knob
	local Switch = new("Frame", {
		Size = UDim2.new(0, 42, 0, 22),
		Position = UDim2.new(1, -56, 0.5, -11),
		BackgroundColor3 = state and Theme.Accent or Theme.Stroke,
		Parent = card,
	}, { corner(UDim.new(1, 0)) })

	-- the circle that slides left/right
	local Knob = new("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
		BackgroundColor3 = Theme.Text,
		Parent = Switch,
	}, { corner(UDim.new(1, 0)) })

	-- invisible button covering the whole card so clicking anywhere on
	-- the row toggles it, not just the tiny switch itself
	local ClickArea = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = card,
	})

	-- shared function so both clicking AND api.Set(...) go through the
	-- same code path (updates visuals + fires the callback)
	local function set(newState)
		state = newState
		tween(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.Stroke })
		tween(Knob, { Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) })
		callback(state)
	end

	ClickArea.MouseButton1Click:Connect(function()
		set(not state)
	end)

	-- Returned so you can control the toggle from outside, e.g.
	-- myToggle.Set(true) or if myToggle.Get() then ... end
	local api = { Set = set, Get = function() return state end }
	if flag then Library.Flags[flag] = api end -- register for config saving, if a flag was given
	return api
end

----------------------------------------------------------------------
-- CHECKBOX — a compact tick-box alternative to Toggle. Same idea, just
-- a different look — pick whichever style you prefer for a given option.
-- Window:AddCheckbox(Tab, "Show FPS", true, function(state) end, "ShowFPS")
----------------------------------------------------------------------
function Library:AddCheckbox(tab, text, default, callback, flag)
	callback = callback or function() end
	local state = default or false

	-- same height as the other single-row components (Toggle, Button,
	-- Textbox) so rows don't look mismatched sitting next to each other
	local card = baseCard(tab, 38)

	-- label on the left, same left margin (14px) every other component uses
	new("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- tick box on the right (matches the docs site layout), same 14px
	-- right margin the Toggle switch and Slider value label use
	local Box = new("Frame", {
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -34, 0.5, -10),
		BackgroundColor3 = state and Theme.Accent or Theme.Background,
		Parent = card,
	}, { corner(UDim.new(0, 5)), stroke(Theme.Stroke) })

	local Check = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "✓",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(12, 12, 16), -- dark tick on the accent-colored box, matches the docs
		TextTransparency = state and 0 or 1, -- hidden (transparent) checkmark when unticked
		Parent = Box,
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

	local api = { Set = set, Get = function() return state end }
	if flag then Library.Flags[flag] = api end
	return api
end

----------------------------------------------------------------------
-- SLIDER — drag left/right to pick a whole number between min and max.
-- Window:AddSlider(Tab, "WalkSpeed", 16, 100, 16, function(value) end, "WalkSpeed")
--   min/max = the allowed range
--   default = starting value
----------------------------------------------------------------------
function Library:AddSlider(tab, text, min, max, default, callback, flag)
	callback = callback or function() end
	min, max = min or 0, max or 100
	local value = math.clamp(default or min, min, max) -- clamp = force the number to stay inside [min, max]

	local card = baseCard(tab, 50)

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

	-- shows the current numeric value, top right
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

	-- the background bar the knob slides along
	local Track = new("Frame", {
		Size = UDim2.new(1, -28, 0, 6),
		Position = UDim2.new(0, 14, 1, -18),
		BackgroundColor3 = Theme.Stroke,
		Parent = card,
	}, { corner(UDim.new(1, 0)) })

	-- the colored portion showing "how far along" the value is
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

	-- Works out the new value based on where the mouse/finger is,
	-- relative to the track's position on screen (0 = left edge, 1 = right edge).
	local function updateFromInput(inputPos)
		local relative = math.clamp((inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		value = math.floor(min + (max - min) * relative + 0.5) -- +0.5 then floor = round to nearest whole number
		Fill.Size = UDim2.new(relative, 0, 1, 0)
		Knob.Position = UDim2.new(relative, -7, 0.5, -7)
		ValueLabel.Text = tostring(value)
		callback(value)
	end

	-- start dragging when you click/tap the track
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
	-- while dragging, follow the mouse/finger even if it moves outside the track itself
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end)

	local api = {
		Set = function(v)
			v = math.clamp(v, min, max)
			-- reuse updateFromInput by faking a mouse position that
			-- corresponds to the value we want
			updateFromInput(Vector2.new(Track.AbsolutePosition.X + (v - min) / (max - min) * Track.AbsoluteSize.X, 0))
		end,
		Get = function() return value end,
	}
	if flag then Library.Flags[flag] = api end
	return api
end

----------------------------------------------------------------------
-- TEXTBOX — a single-line text input.
-- Window:AddTextbox(Tab, "Enter your name...", function(text, enterPressed) end, "PlayerName")
-- The callback fires when the box loses focus (you click away or press Enter).
----------------------------------------------------------------------
function Library:AddTextbox(tab, placeholder, callback, flag)
	callback = callback or function() end
	local card = baseCard(tab, 38)

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
		ClearTextOnFocus = false, -- don't wipe existing text every time you click into it
		Parent = card,
	}, { corner(UDim.new(0, 6)), padding(0, 0, 8, 0, 8) })

	Box.Focused:Connect(function()
		tween(card, { BackgroundColor3 = Theme.ElevatedHover })
	end)
	Box.FocusLost:Connect(function(enterPressed)
		tween(card, { BackgroundColor3 = Theme.Elevated })
		callback(Box.Text, enterPressed)
	end)

	if flag then
		Library.Flags[flag] = {
			Set = function(v) Box.Text = tostring(v) end,
			Get = function() return Box.Text end,
		}
	end

	return Box
end

----------------------------------------------------------------------
-- DROPDOWN — pick one option from a list. Click to expand/collapse.
-- Window:AddDropdown(Tab, "Theme", {"Dark", "Light"}, "Dark", function(choice) end, "SelectedTheme")
--
-- The returned api also has a .Refresh(newOptionsTable) method, which
-- rebuilds the option list on the fly. This is what you use for a
-- "pick a config" dropdown — call Refresh(Window:ListConfigs()) any
-- time a config is saved/deleted so the list stays up to date.
----------------------------------------------------------------------
function Library:AddDropdown(tab, text, options, default, callback, flag)
	callback = callback or function() end
	options = options or {}
	local selected = default or options[1]
	local open = false

	-- closed height matches ColorPicker/Keybind (the other "click to
	-- expand a boxed control" components), so rows don't jump between
	-- 38px and 44px depending on which component they sit next to
	local CLOSED_HEIGHT = 44
	local OPTION_HEIGHT = 30
	local OPTION_GAP = 2

	-- total height of the option list for a given option count, including
	-- the small gaps we put between rows
	local function listHeight(n)
		if n <= 0 then return 0 end
		return n * OPTION_HEIGHT + (n - 1) * OPTION_GAP
	end

	-- total card height for a given option count while open
	local function openHeight(n)
		return CLOSED_HEIGHT + 8 + listHeight(n) + 10
	end

	local card = baseCard(tab, CLOSED_HEIGHT)
	card.ClipsDescendants = true -- hides the option list until the card is resized taller
	card.ZIndex = 2

	-- FIXED height/position (not scaled to the card), so this doesn't
	-- stretch — and the text inside it drift downward — as the card
	-- grows taller to reveal the option list
	new("TextLabel", {
		Size = UDim2.new(0.42, -14, 0, 30),
		Position = UDim2.new(0, 14, 0, 7),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- shows the currently selected option, click it to open/close the list
	local Selected = new("TextButton", {
		Size = UDim2.new(0.58, -14, 0, 30),
		Position = UDim2.new(0.42, 0, 0, 7),
		BackgroundColor3 = Theme.Background,
		Text = selected and tostring(selected) or "None",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		Parent = card,
	}, { corner(UDim.new(0, 6)), padding(0, 0, 26, 0, 12) })

	-- a real arrow icon instead of a text character, so it actually
	-- shows up regardless of what glyphs the current font supports
	local Arrow = chevron(9, Theme.SubText, 2)
	Arrow.Position = UDim2.new(1, -16, 0.5, 0)
	Arrow.Parent = Selected

	local OptionsList = new("Frame", {
		Size = UDim2.new(1, -28, 0, listHeight(#options)),
		Position = UDim2.new(0, 14, 0, CLOSED_HEIGHT + 4),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = card,
	}, { listLayout(Enum.FillDirection.Vertical, OPTION_GAP) })

	-- Runs whenever an option is clicked, OR when you call api.Set(...)
	-- from code — both should close the list and fire the callback the
	-- same way, so this is shared between them.
	local function selectOption(option)
		selected = option
		Selected.Text = tostring(option)
		open = false
		OptionsList.Visible = false
		tween(Arrow, { Rotation = 0 })
		tween(card, { Size = UDim2.new(1, 0, 0, CLOSED_HEIGHT) }) -- shrink back down
		callback(option)
	end

	-- Wipes out the current option buttons and builds fresh ones from
	-- `newOptions`. Used both the first time (below) and any time you
	-- call api.Refresh(...) later, e.g. after saving a new config.
	local function rebuildOptions(newOptions)
		options = newOptions or {}

		for _, child in ipairs(OptionsList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		OptionsList.Size = UDim2.new(1, -28, 0, listHeight(#options))
		if open then
			tween(card, { Size = UDim2.new(1, 0, 0, openHeight(#options)) })
		end

		for i, option in ipairs(options) do
			local optBtn = new("TextButton", {
				Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
				BackgroundColor3 = Theme.Background,
				Text = tostring(option),
				Font = Theme.Font,
				TextSize = 13,
				TextColor3 = Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				LayoutOrder = i,
				Parent = OptionsList,
			}, { corner(UDim.new(0, 6)), padding(0, 0, 12, 0, 12) })
			optBtn.MouseEnter:Connect(function()
				tween(optBtn, { BackgroundColor3 = Theme.ElevatedHover })
			end)
			optBtn.MouseLeave:Connect(function()
				tween(optBtn, { BackgroundColor3 = Theme.Background })
			end)
			optBtn.MouseButton1Click:Connect(function()
				selectOption(option)
			end)
		end
	end

	rebuildOptions(options) -- build the initial list

	-- clicking the "Selected" button grows/shrinks the card to reveal the list
	Selected.MouseButton1Click:Connect(function()
		open = not open
		OptionsList.Visible = open
		tween(Arrow, { Rotation = open and 180 or 0 })
		tween(card, { Size = open and UDim2.new(1, 0, 0, openHeight(#options)) or UDim2.new(1, 0, 0, CLOSED_HEIGHT) })
	end)

	local api = {
		Set = function(v)
			selected = v
			Selected.Text = tostring(v)
		end,
		Get = function() return selected end,
		Refresh = function(newOptions) rebuildOptions(newOptions) end,
	}
	if flag then Library.Flags[flag] = api end
	return api
end

----------------------------------------------------------------------
-- COLOR PICKER — a saturation/value square + a hue bar (the standard
-- color-picker layout), with a hex code box, a plain-English RGB
-- readout, and a Copy button. Expands from the swatch, same
-- click-to-expand idea as the Dropdown above.
-- Window:AddColorPicker(Tab, "ESP Color", Color3.fromRGB(255,0,0), function(color) end, "ESPColor")
----------------------------------------------------------------------
function Library:AddColorPicker(tab, text, default, callback, flag)
	callback = callback or function() end
	local color = default or Color3.fromRGB(255, 255, 255)
	local hue, sat, val = color:ToHSV()
	local open = false

	local HEADER_HEIGHT = 44
	local SV_HEIGHT = 130
	local HUE_HEIGHT = 20
	local HEX_ROW_HEIGHT = 34
	local GAP = 10
	local PANEL_HEIGHT = SV_HEIGHT + GAP + HUE_HEIGHT + GAP + HEX_ROW_HEIGHT
	local OPEN_HEIGHT = HEADER_HEIGHT + 8 + PANEL_HEIGHT + 14

	local card = baseCard(tab, HEADER_HEIGHT)
	card.ClipsDescendants = true

	new("TextLabel", {
		Size = UDim2.new(1, -70, 0, HEADER_HEIGHT),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- the little colored square preview, click it to open the picker
	local Swatch = new("TextButton", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -44, 0, 7),
		BackgroundColor3 = color,
		Text = "",
		AutoButtonColor = false,
		Parent = card,
	}, { corner(UDim.new(0, 6)), stroke() })

	local Panel = new("Frame", {
		Size = UDim2.new(1, -28, 0, PANEL_HEIGHT),
		Position = UDim2.new(0, 14, 0, HEADER_HEIGHT + 8),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = card,
	}, { listLayout(Enum.FillDirection.Vertical, GAP) })

	--------------------------------------------------------------
	-- the saturation/value square
	--------------------------------------------------------------
	local SVBox = new("Frame", {
		Size = UDim2.new(1, 0, 0, SV_HEIGHT),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		ClipsDescendants = true,
		LayoutOrder = 1,
		Parent = Panel,
	}, { corner(UDim.new(0, 8)), stroke() })

	-- white → transparent, left to right (controls saturation)
	new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = SVBox,
	}, {
		new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	-- black → transparent, bottom to top (controls value/brightness)
	new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = SVBox,
	}, {
		new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}),
	})

	local SVKnob = new("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(sat, 0, 1 - val, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = SVBox,
	}, { corner(UDim.new(1, 0)), stroke(Color3.new(0, 0, 0), 1.5) })

	--------------------------------------------------------------
	-- the hue bar
	--------------------------------------------------------------
	local HueBar = new("Frame", {
		Size = UDim2.new(1, 0, 0, HUE_HEIGHT),
		LayoutOrder = 2,
		Parent = Panel,
	}, { corner(UDim.new(1, 0)), stroke() })

	do
		local hueKeypoints = {}
		local steps = 12
		for i = 0, steps do
			local t = i / steps
			table.insert(hueKeypoints, ColorSequenceKeypoint.new(t, Color3.fromHSV(t, 1, 1)))
		end
		new("UIGradient", { Color = ColorSequence.new(hueKeypoints), Parent = HueBar })
	end

	local HueKnob = new("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(hue, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = HueBar,
	}, { corner(UDim.new(1, 0)), stroke(Color3.new(0, 0, 0), 1.5) })

	--------------------------------------------------------------
	-- hex code box + RGB readout + copy button
	--------------------------------------------------------------
	local HexRow = new("Frame", {
		Size = UDim2.new(1, 0, 0, HEX_ROW_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = Panel,
	})

	new("TextLabel", {
		Size = UDim2.new(0, 12, 1, 0),
		BackgroundTransparency = 1,
		Text = "#",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Theme.SubText,
		Parent = HexRow,
	})

	local function toHex(c)
		return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end

	local HexBox = new("TextBox", {
		Size = UDim2.new(0, 66, 0, 26),
		Position = UDim2.new(0, 12, 0, 4),
		BackgroundColor3 = Theme.Background,
		Text = toHex(color),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		Parent = HexRow,
	}, { corner(UDim.new(0, 6)), padding(0, 0, 6, 0, 8) })

	-- plain-English "R, G, B" readout, so you don't have to decode a
	-- Color3's 0-1 fractions yourself
	local RGBLabel = new("TextLabel", {
		Size = UDim2.new(1, -152, 1, 0),
		Position = UDim2.new(0, 88, 0, 0),
		BackgroundTransparency = 1,
		Text = string.format("R %d  G %d  B %d", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5)),
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = HexRow,
	})

	local CopyBtn = new("TextButton", {
		Size = UDim2.new(0, 60, 0, 26),
		Position = UDim2.new(1, -60, 0, 4),
		BackgroundColor3 = Theme.Background,
		Text = "Copy",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		AutoButtonColor = false,
		Parent = HexRow,
	}, { corner(UDim.new(0, 6)), stroke() })

	--------------------------------------------------------------
	-- shared update logic
	--------------------------------------------------------------
	local updatingFromCode = false -- guards against feedback loops while Set() is repainting everything

	-- repaints every visual (swatch, hex box, RGB label, both knobs)
	-- from the current hue/sat/val, without touching hue/sat/val itself
	local function repaint()
		color = Color3.fromHSV(hue, sat, val)
		Swatch.BackgroundColor3 = color
		SVBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		SVKnob.Position = UDim2.new(sat, 0, 1 - val, 0)
		HueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
		if not HexBox:IsFocused() then
			HexBox.Text = toHex(color)
		end
		RGBLabel.Text = string.format(
			"R %d  G %d  B %d",
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5)
		)
	end

	local function commit()
		repaint()
		if not updatingFromCode then
			callback(color)
		end
	end

	-- dragging inside the SV square sets saturation (x) and value (y)
	local svDragging = false
	local function updateFromSV(pos)
		local relX = math.clamp((pos.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
		local relY = math.clamp((pos.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
		sat = relX
		val = 1 - relY
		commit()
	end
	SVBox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			svDragging = true
			updateFromSV(input.Position)
		end
	end)
	SVBox.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			svDragging = false
		end
	end)

	-- dragging the hue bar sets hue (x)
	local hueDragging = false
	local function updateFromHue(pos)
		local relX = math.clamp((pos.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
		hue = relX
		commit()
	end
	HueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hueDragging = true
			updateFromHue(input.Position)
		end
	end)
	HueBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hueDragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if svDragging then
			updateFromSV(input.Position)
		elseif hueDragging then
			updateFromHue(input.Position)
		end
	end)

	-- typing a hex code in and pressing enter / clicking away applies it
	HexBox.FocusLost:Connect(function()
		local cleaned = HexBox.Text:gsub("#", ""):gsub("%s", "")
		if #cleaned == 6 and cleaned:match("^%x+$") then
			local r, g, b = tonumber(cleaned:sub(1, 2), 16), tonumber(cleaned:sub(3, 4), 16), tonumber(cleaned:sub(5, 6), 16)
			hue, sat, val = Color3.fromRGB(r, g, b):ToHSV()
			commit()
		else
			HexBox.Text = toHex(color) -- invalid input, snap back to the current color
		end
	end)

	-- copies the hex code if the executor supports setclipboard; falls
	-- back to focusing the box so you can select + Ctrl/Cmd-C it yourself
	CopyBtn.MouseButton1Click:Connect(function()
		local copied = false
		if typeof(setclipboard) == "function" then
			copied = pcall(setclipboard, "#" .. toHex(color))
		end
		if copied then
			CopyBtn.Text = "Copied!"
			tween(CopyBtn, { BackgroundColor3 = Theme.Accent })
		else
			HexBox:CaptureFocus()
			CopyBtn.Text = "Select text"
		end
		task.delay(1.2, function()
			CopyBtn.Text = "Copy"
			tween(CopyBtn, { BackgroundColor3 = Theme.Background })
		end)
	end)

	-- clicking the swatch expands/collapses the picker panel
	Swatch.MouseButton1Click:Connect(function()
		open = not open
		Panel.Visible = open
		tween(card, { Size = open and UDim2.new(1, 0, 0, OPEN_HEIGHT) or UDim2.new(1, 0, 0, HEADER_HEIGHT) })
	end)

	local api = {
		Set = function(c)
			updatingFromCode = true
			hue, sat, val = c:ToHSV()
			repaint()
			updatingFromCode = false
		end,
		Get = function() return color end,
	}
	if flag then Library.Flags[flag] = api end
	return api
end

----------------------------------------------------------------------
-- KEYBIND — click the box, then press any key to bind it. The
-- callback fires every time that key is pressed afterwards (great for
-- "press this key to toggle X" style features).
-- Window:AddKeybind(Tab, "Toggle Menu", Enum.KeyCode.RightShift, function() end, "MenuKey")
----------------------------------------------------------------------
function Library:AddKeybind(tab, text, default, callback, flag)
	callback = callback or function() end
	local bound = default or Enum.KeyCode.Unknown
	local listening = false -- true while we're waiting for the player to press a key

	local card = baseCard(tab, 44)

	new("TextLabel", {
		Size = UDim2.new(1, -110, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local KeyBtn = new("TextButton", {
		Size = UDim2.new(0, 90, 0, 30),
		Position = UDim2.new(1, -104, 0.5, -15),
		BackgroundColor3 = Theme.Background,
		Text = bound == Enum.KeyCode.Unknown and "..." or bound.Name,
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		AutoButtonColor = false,
		Parent = card,
	}, { corner(UDim.new(0, 6)), stroke() })

	-- click the box to start "listening" for the next key press
	KeyBtn.MouseButton1Click:Connect(function()
		listening = true
		KeyBtn.Text = "..."
		tween(KeyBtn, { BackgroundColor3 = Theme.ElevatedHover })
	end)

	-- this connection ONLY runs while listening=true, and captures
	-- whatever key is pressed next as the new bind
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			bound = input.KeyCode
			KeyBtn.Text = bound.Name
			listening = false
			tween(KeyBtn, { BackgroundColor3 = Theme.Background })
		end
	end)

	-- this SEPARATE connection fires the callback whenever the already-
	-- bound key is pressed (but not while we're mid-rebind, and not if
	-- Roblox already used the input for something like chat)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if listening or gameProcessed then return end
		if input.KeyCode == bound then
			callback(bound)
		end
	end)

	local api = {
		Set = function(key)
			bound = key
			KeyBtn.Text = key.Name
		end,
		Get = function() return bound end,
	}
	if flag then Library.Flags[flag] = api end
	return api
end

--=====================================================================
-- 7. NOTIFY
-- Pops up a small toast message in the top-right corner that fades
-- out on its own after `duration` seconds.
-- Window:Notify("Saved", "Your settings were saved!", 3)
--=====================================================================
function Library:Notify(title, text, duration)
	duration = duration or 3

	local gui = getGuiParent():FindFirstChild("Aurora")
	if not gui then return end -- window was closed / never created, nothing to attach to

	-- all notifications stack inside one shared holder frame, created
	-- the first time Notify() is called
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
		BackgroundTransparency = 1, -- starts invisible, we fade it in below
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

	-- fade everything IN
	tween(card, { BackgroundTransparency = 0 }, 0.25)
	for _, label in ipairs(card:GetChildren()) do
		if label:IsA("TextLabel") then
			tween(label, { TextTransparency = 0 }, 0.25)
		end
	end

	-- wait, then fade everything OUT and delete it
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

--=====================================================================
-- 8. CONFIG SAVE / LOAD (JSON)
--
-- Any component created with a trailing `flag` argument (e.g.
-- Window:AddToggle(Tab, "Fly", false, callback, "FlyEnabled")) gets
-- tracked automatically in Library.Flags. These two functions turn
-- all of that into a JSON string and save/load it.
--
-- Storage backend is auto-detected, so you don't need to change your
-- code depending on where the script runs:
--   • Executors (Synapse, Script-Ware, etc.) -> saved as a real
--     .json file using writefile/readfile
--   • Roblox Studio / published games -> DataStoreService, keyed by
--     the config name (in Studio you must turn on "Enable Studio
--     Access to API Services" under Game Settings > Security)
--=====================================================================

-- Turns every flagged value into a plain table ready for JSONEncode.
-- Color3 and Enum values need special handling since JSON can't store
-- them directly — we convert them into small marked tables instead.
local function serializeFlags()
	local data = {}
	for flag, api in pairs(Library.Flags) do
		local ok, value = pcall(api.Get)
		if ok then
			if typeof(value) == "Color3" then
				data[flag] = { __type = "Color3", r = value.R, g = value.G, b = value.B }
			elseif typeof(value) == "EnumItem" then
				data[flag] = { __type = "EnumItem", name = value.Name }
			else
				data[flag] = value
			end
		end
	end
	return data
end

-- Reverses serializeFlags(): reads the saved table and calls .Set(...)
-- on every matching component to restore its value.
local function applyFlags(data)
	for flag, value in pairs(data) do
		local api = Library.Flags[flag]
		if api then
			if type(value) == "table" and value.__type == "Color3" then
				api.Set(Color3.new(value.r, value.g, value.b))
			elseif type(value) == "table" and value.__type == "EnumItem" then
				api.Set(Enum.KeyCode[value.name])
			else
				api.Set(value)
			end
		end
	end
end

-- Returns the current config as a raw JSON string, in case you want
-- to handle saving it yourself (e.g. send it somewhere else).
function Library:GetConfigJSON()
	return HttpService:JSONEncode(serializeFlags())
end

-- Saves every flagged value under the given config `name`.
-- Returns true/false for success, and an error message if it failed.
function Library:SaveConfig(name)
	name = name or "default"
	local json = self:GetConfigJSON()

	if writefile then
		-- we're in an executor, so save a real file
		local ok, err = pcall(function()
			if not isfolder or not isfolder("AuroraConfigs") then
				if makefolder then makefolder("AuroraConfigs") end
			end
			writefile("AuroraConfigs/" .. name .. ".json", json)
		end)
		return ok, err
	else
		-- we're in Studio / a published game, so use DataStores instead
		local DataStoreService = game:GetService("DataStoreService")
		local store = DataStoreService:GetDataStore("AuroraConfigs")
		local ok, err = pcall(function()
			store:SetAsync(name, json)
		end)
		return ok, err
	end
end

-- Loads a previously-saved config by `name` and applies it to every
-- matching flagged component. Returns true if it successfully loaded
-- something, false otherwise (e.g. no config was ever saved).
function Library:LoadConfig(name)
	name = name or "default"
	local ok, result = pcall(function()
		local json

		if readfile and isfile and isfile("AuroraConfigs/" .. name .. ".json") then
			json = readfile("AuroraConfigs/" .. name .. ".json")
		else
			local DataStoreService = game:GetService("DataStoreService")
			local store = DataStoreService:GetDataStore("AuroraConfigs")
			json = store:GetAsync(name)
		end

		if not json then return false end

		local data = HttpService:JSONDecode(json)
		applyFlags(data)
		return true
	end)
	return ok and result
end

----------------------------------------------------------------------
-- CREATE CONFIG — this is really just SaveConfig with a clearer name
-- for when you're making a brand-new config for the first time (e.g.
-- from a "New Config" textbox + button in your UI), rather than
-- re-saving over an existing one. Both do exactly the same thing.
-- Window:CreateConfig("MySettings")
----------------------------------------------------------------------
function Library:CreateConfig(name)
	return self:SaveConfig(name)
end

----------------------------------------------------------------------
-- LIST CONFIGS — returns an array of every saved config's name (no
-- ".json", just the plain name you'd pass into LoadConfig/DeleteConfig).
-- This is what you feed into a Dropdown so players can pick a config:
--
--   local ConfigDropdown = Window:AddDropdown(Tab, "Config", Window:ListConfigs(), nil, function(name)
--       Window:LoadConfig(name)
--   end)
--
-- Since the list can change (new configs saved, old ones deleted)
-- after the dropdown is created, call ConfigDropdown.Refresh(Window:ListConfigs())
-- any time you want it to catch up — e.g. right after CreateConfig/DeleteConfig.
----------------------------------------------------------------------
function Library:ListConfigs()
	if listfiles then
		-- executor: read the folder directly
		local ok, result = pcall(function()
			local names = {}
			if isfolder and isfolder("AuroraConfigs") then
				for _, path in ipairs(listfiles("AuroraConfigs")) do
					local name = path:match("([^/\\]+)%.json$") -- grab "MySettings" out of ".../MySettings.json"
					if name then
						table.insert(names, name)
					end
				end
			end
			return names
		end)
		return ok and result or {}
	else
		-- Studio / published game: ask the DataStore for every key we've saved
		local DataStoreService = game:GetService("DataStoreService")
		local store = DataStoreService:GetDataStore("AuroraConfigs")
		local ok, result = pcall(function()
			local names = {}
			local pages = store:ListKeysAsync()
			while true do
				for _, item in ipairs(pages:GetCurrentPage()) do
					if item.KeyName ~= "__autoload__" then -- skip our internal autoload marker, see below
						table.insert(names, item.KeyName)
					end
				end
				if pages.IsFinished then break end
				pages:AdvanceToNextPageAsync()
			end
			return names
		end)
		return ok and result or {}
	end
end

----------------------------------------------------------------------
-- DELETE CONFIG — removes a saved config permanently.
-- Window:DeleteConfig("MySettings")
----------------------------------------------------------------------
function Library:DeleteConfig(name)
	name = name or "default"

	if delfile then
		local ok, err = pcall(function()
			if isfile and isfile("AuroraConfigs/" .. name .. ".json") then
				delfile("AuroraConfigs/" .. name .. ".json")
			end
		end)
		return ok, err
	else
		local DataStoreService = game:GetService("DataStoreService")
		local store = DataStoreService:GetDataStore("AuroraConfigs")
		local ok, err = pcall(function()
			store:RemoveAsync(name)
		end)
		return ok, err
	end
end

----------------------------------------------------------------------
-- AUTOLOAD — mark one config as the one that should load automatically
-- next time. Call SetAutoloadConfig once (e.g. from an "Autoload"
-- toggle/button in your settings tab), then call LoadAutoloadConfig()
-- near the top of your script, right after CreateWindow, so it applies
-- before the player starts using the UI.
--
--   Window:SetAutoloadConfig("MySettings")
--   ...
--   Window:LoadAutoloadConfig() -- put this early in your script
----------------------------------------------------------------------
function Library:SetAutoloadConfig(name)
	if writefile then
		local ok, err = pcall(function()
			if not isfolder or not isfolder("AuroraConfigs") then
				if makefolder then makefolder("AuroraConfigs") end
			end
			writefile("AuroraConfigs/autoload.txt", name)
		end)
		return ok, err
	else
		local DataStoreService = game:GetService("DataStoreService")
		local store = DataStoreService:GetDataStore("AuroraConfigs")
		local ok, err = pcall(function()
			store:SetAsync("__autoload__", name)
		end)
		return ok, err
	end
end

-- Reads back whatever config name was marked with SetAutoloadConfig
-- and loads it. Returns false (without erroring) if nothing was ever
-- set, so it's always safe to call this even on a fresh install.
function Library:LoadAutoloadConfig()
	local ok, result = pcall(function()
		local name

		if readfile and isfile and isfile("AuroraConfigs/autoload.txt") then
			name = readfile("AuroraConfigs/autoload.txt")
		else
			local DataStoreService = game:GetService("DataStoreService")
			local store = DataStoreService:GetDataStore("AuroraConfigs")
			name = store:GetAsync("__autoload__")
		end

		if not name or name == "" then return false end
		return self:LoadConfig(name)
	end)
	return ok and result
end

-- Reads back whatever config name is currently marked as the autoload
-- config WITHOUT loading it — useful for e.g. pre-selecting the right
-- option in a dropdown, or showing "Autoload: MySettings" as a label.
-- Returns nil if none is set.
function Library:GetAutoloadConfig()
	local ok, result = pcall(function()
		if readfile and isfile and isfile("AuroraConfigs/autoload.txt") then
			local name = readfile("AuroraConfigs/autoload.txt")
			return name ~= "" and name or nil
		else
			local DataStoreService = game:GetService("DataStoreService")
			local store = DataStoreService:GetDataStore("AuroraConfigs")
			local name = store:GetAsync("__autoload__")
			return name ~= "" and name or nil
		end
	end)
	return ok and result or nil
end

----------------------------------------------------------------------
-- ADD CONFIG MANAGER — a ready-made "Configs" section you can drop
-- into any tab. Gives you, out of the box:
--   • a dropdown listing every saved config
--   • a textbox + "Save" button to save the CURRENT settings under a
--     new (or existing) name
--   • a "Load" button to apply the config picked in the dropdown
--   • a "Set Autoload" button to mark the picked config as the one
--     that loads automatically next time (see LoadAutoloadConfig)
--   • a "Delete" button to remove the picked config
--
-- This is exactly what answers "how do I let the player pick which
-- config auto-loads?" — wire it up like this:
--
--   local SettingsTab = Window:CreateTab("Settings", "settings")
--   Window:AddConfigManager(SettingsTab)
--
--   -- then, near the very top of your script, BEFORE you create any
--   -- flagged components (or right after, then call LoadAutoloadConfig
--   -- again) so saved values apply on join:
--   Window:LoadAutoloadConfig()
--
-- Everything here just calls the SaveConfig/LoadConfig/ListConfigs/
-- SetAutoloadConfig/DeleteConfig functions above — this is purely a
-- convenience wrapper, you can always build your own UI against those
-- instead if you want something more custom.
----------------------------------------------------------------------
function Library:AddConfigManager(tab)
	local Window = self

	Window:AddSection(tab, "Configs")

	local configs = Window:ListConfigs()
	local autoloadName = Window:GetAutoloadConfig()

	local ConfigDropdown = Window:AddDropdown(
		tab,
		"Saved Configs",
		configs,
		autoloadName or configs[1],
		function() end
	)

	local NameBox = Window:AddTextbox(tab, "Config name to save as...", function() end)

	local function refreshList()
		ConfigDropdown.Refresh(Window:ListConfigs())
	end

	Window:AddButton(tab, "Save Config", function()
		local name = NameBox.Text
		if not name or name == "" then
			Window:Notify("Config", "Type a name in the box above first.", 3)
			return
		end
		local ok = Window:SaveConfig(name)
		Window:Notify("Config", ok and ("Saved \"" .. name .. "\"") or "Failed to save config.", 3)
		refreshList()
	end)

	Window:AddButton(tab, "Load Selected Config", function()
		local name = ConfigDropdown.Get()
		if not name then return end
		local ok = Window:LoadConfig(name)
		Window:Notify("Config", ok and ("Loaded \"" .. name .. "\"") or "Failed to load config.", 3)
	end)

	Window:AddButton(tab, "Set Selected as Autoload", function()
		local name = ConfigDropdown.Get()
		if not name then return end
		local ok = Window:SetAutoloadConfig(name)
		Window:Notify("Config", ok and ("\"" .. name .. "\" will now load automatically") or "Failed to set autoload.", 3)
	end)

	Window:AddButton(tab, "Delete Selected Config", function()
		local name = ConfigDropdown.Get()
		if not name then return end
		Window:DeleteConfig(name)
		Window:Notify("Config", "Deleted \"" .. name .. "\"", 3)
		refreshList()
	end)
end

-- This is the last line: it makes everything above accessible to
-- whoever wrote `local Library = loadstring(...)()` to load this file.
return Library
