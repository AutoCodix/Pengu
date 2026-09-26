--[[ Pengu UI v0.5.0 — Resonance-style sidebar + pages. No intro. ]]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local UI = {
	Gui = nil,
	Connections = {},
	AccentBindings = {},
	ActivePage = "Combat",
	Search = "",
}

local Config, TargetManager, Combat, Defense, PlayerController, Pengu

local BG = Color3.fromRGB(12, 12, 16)
local SIDE = Color3.fromRGB(16, 16, 22)
local CARD = Color3.fromRGB(22, 22, 30)
local HEADER = Color3.fromRGB(28, 28, 38)
local MUTED = Color3.fromRGB(140, 140, 155)
local TEXT = Color3.fromRGB(235, 235, 245)
local STROKE = Color3.fromRGB(40, 40, 55)

local function accent()
	return (Config and Config.Accent) or Color3.fromRGB(119, 0, 255)
end

local function panelT()
	local t = (Config and Config.UITransparency) or 0.08
	if t < 0 then t = 0 end
	if t > 0.75 then t = 0.75 end
	return t
end

local function bindAccent(inst, prop)
	table.insert(UI.AccentBindings, {inst = inst, prop = prop})
	inst[prop] = accent()
end

local function applyAccent()
	local a = accent()
	for _, b in ipairs(UI.AccentBindings) do
		pcall(function() b.inst[b.prop] = a end)
	end
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
end

local function stroke(p, t)
	local s = Instance.new("UIStroke")
	s.Color = STROKE
	s.Thickness = t or 1
	s.Transparency = 0.35
	s.Parent = p
	return s
end

local function pad(p, l, t, r, b)
	local u = Instance.new("UIPadding")
	u.PaddingLeft = UDim.new(0, l or 8)
	u.PaddingTop = UDim.new(0, t or 8)
	u.PaddingRight = UDim.new(0, r or 8)
	u.PaddingBottom = UDim.new(0, b or 8)
	u.Parent = p
end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then o.Parent = parent end
	return o
end

local function notify(msg)
	if Pengu and Pengu.Notify then
		Pengu.Notify(msg)
	end
end

-- ---------- widgets ----------
local function sectionCard(parent, title)
	local card = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = CARD,
		BackgroundTransparency = panelT(),
		BorderSizePixel = 0,
	}, parent)
	corner(card, 10)
	stroke(card, 1)
	local lay = mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, card)
	pad(card, 12, 10, 12, 12)
	local head = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
	}, card)
	bindAccent(head, "TextColor3")
	return card
end

local function toggleRow(card, label, key, onChange)
	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = #card:GetChildren() + 1,
	}, card)
	mk("TextLabel", {
		Size = UDim2.new(1, -52, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local btn = mk("TextButton", {
		Size = UDim2.new(0, 42, 0, 22),
		Position = UDim2.new(1, -42, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(50, 50, 60),
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, row)
	corner(btn, 11)
	local knob = mk("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0, 2, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(220, 220, 230),
		BorderSizePixel = 0,
	}, btn)
	corner(knob, 9)
	local function paint()
		local on = Config and Config[key]
		btn.BackgroundColor3 = on and accent() or Color3.fromRGB(50, 50, 60)
		knob.Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
	end
	paint()
	btn.MouseButton1Click:Connect(function()
		if not Config then return end
		Config[key] = not Config[key]
		paint()
		if onChange then pcall(onChange, Config[key]) end
	end)
	return row
end

local function sliderRow(card, label, key, minV, maxV, onChange)
	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = #card:GetChildren() + 1,
	}, card)
	local top = mk("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1}, row)
	mk("TextLabel", {
		Size = UDim2.new(0.7, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, top)
	local valLab = mk("TextLabel", {
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.7, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(Config and Config[key] or minV),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, top)
	local bar = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(40, 40, 52),
		BorderSizePixel = 0,
	}, row)
	corner(bar, 4)
	local fill = mk("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = accent(),
		BorderSizePixel = 0,
	}, bar)
	corner(fill, 4)
	bindAccent(fill, "BackgroundColor3")
	local function setFromX(x)
		local rel = math.clamp(x / bar.AbsoluteSize.X, 0, 1)
		local v = minV + (maxV - minV) * rel
		if maxV - minV > 5 then v = math.floor(v + 0.5) else v = math.floor(v * 100 + 0.5) / 100 end
		if Config then Config[key] = v end
		valLab.Text = tostring(v)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		if onChange then pcall(onChange, v) end
	end
	local dragging = false
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(i.Position.X - bar.AbsolutePosition.X)
		end
	end)
	table.insert(UI.Connections, UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end))
	table.insert(UI.Connections, UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(i.Position.X - bar.AbsolutePosition.X)
		end
	end))
	task.defer(function()
		local cur = Config and Config[key] or minV
		local rel = (cur - minV) / math.max(maxV - minV, 1e-6)
		fill.Size = UDim2.new(math.clamp(rel, 0, 1), 0, 1, 0)
		valLab.Text = tostring(cur)
	end)
	return row
end

local function buttonRow(card, label, fn)
	local b = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = HEADER,
		Text = label,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = TEXT,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		LayoutOrder = #card:GetChildren() + 1,
	}, card)
	corner(b, 6)
	stroke(b, 1)
	b.MouseButton1Click:Connect(function()
		pcall(fn)
	end)
	return b
end

local function note(card, text)
	return mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = #card:GetChildren() + 1,
	}, card)
end

-- ---------- pages ----------
local pages = {}

local function clearPage(host)
	for _, c in ipairs(host:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

function pages.Combat(host)
	local c1 = sectionCard(host, "Super Strength")
	toggleRow(c1, "Super Strength", "SuperStrength")
	sliderRow(c1, "Strength", "StrengthValue", 50, 800)
	toggleRow(c1, "Fling Up", "FlingUp")
	toggleRow(c1, "Slam", "Slam")
	toggleRow(c1, "Void Fling", "VoidFling")
	toggleRow(c1, "Spin Fling", "SpinFling")
	note(c1, "RMB while holding a valid target. Sliders never move objects.")

	local c2 = sectionCard(host, "Line / Reach")
	toggleRow(c2, "Extend Line", "ExtendLine")
	sliderRow(c2, "Extend Speed", "ExtendSpeed", 1, 20)
	toggleRow(c2, "Grab Reach", "GrabReach")
	sliderRow(c2, "Max Reach", "MaxGrabReach", 10, 80)

	local c3 = sectionCard(host, "Auras")
	toggleRow(c3, "Fling Aura", "FlingAura")
	toggleRow(c3, "Ragdoll Aura", "RagdollAura")
	toggleRow(c3, "Sit Aura", "SitAura")
	toggleRow(c3, "Spin Aura", "SpinAura")
	toggleRow(c3, "Bring Aura", "BringAura")
	toggleRow(c3, "Void Aura", "VoidAura")
	sliderRow(c3, "Aura Distance", "AuraRange", 5, 80)
	toggleRow(c3, "Exclude Friends", "AuraIgnoreFriends")
	toggleRow(c3, "Show Radius", "ShowAuraRadius")

	local c4 = sectionCard(host, "Grab Modes")
	toggleRow(c4, "Toggle Grabs", "ToggleGrabs")
	note(c4, "Modes apply with Super Strength throw path when enabled (Void/Spin/Fling/…).")
end

function pages.Defense(host)
	local a = sectionCard(host, "Antis")
	toggleRow(a, "Anti Grab", "AntiGrab")
	toggleRow(a, "Gucci Anti-Grab", "AntiGrabGucci")
	toggleRow(a, "Anti Gucci", "AntiGucci")
	toggleRow(a, "Anti Blobman", "AntiBlobman")
	toggleRow(a, "Anti Fling", "AntiFling")
	toggleRow(a, "Anti Ragdoll", "AntiRagdoll")
	toggleRow(a, "Instant Get Up", "InstantGetUp")
	toggleRow(a, "Anti Sit", "AntiSit")
	toggleRow(a, "Anti Void", "AntiVoid")
	toggleRow(a, "Disable Void", "DisableVoid")
	toggleRow(a, "Anti Lag", "AntiLag")
	toggleRow(a, "Auto Anti-Lag", "AutoAntiLag")
	toggleRow(a, "Anti Sticky", "AntiSticky")
	toggleRow(a, "Anti Banana", "AntiBanana")
	toggleRow(a, "Anti Paint", "AntiPaint")
	toggleRow(a, "Anti Snowball", "AntiSnowball")
	toggleRow(a, "Anti Poison", "AntiPoison")
	toggleRow(a, "Anti Explosion", "AntiExplosion")
	toggleRow(a, "Anti Burn", "AntiBurn")
	toggleRow(a, "Anti Kick", "AntiKick")
	toggleRow(a, "Anti Invis", "AntiInvis")
	toggleRow(a, "Auto Reset", "AutoReset")
	toggleRow(a, "Counter Attack", "CounterAttack")

	local b = sectionCard(host, "Held Object")
	toggleRow(b, "Noclip Barrier", "NoclipBarrier")
	note(b, "Disables CanCollide on held movable target only. Restores on drop.")

	local u = sectionCard(host, "Unsupported")
	note(u, "Anti Network Ownership / Net Owner Spam / Break PCLD — not implemented.")
end

function pages.Player(host)
	local v = sectionCard(host, "Values")
	toggleRow(v, "Walk Speed", "SpeedEnabled")
	sliderRow(v, "Walk Speed", "WalkSpeed", 16, 200)
	toggleRow(v, "Jump Boost", "JumpEnabled")
	sliderRow(v, "Jump Power", "JumpPower", 50, 200)
	toggleRow(v, "Flight", "Flight")
	sliderRow(v, "Flight Speed", "FlightSpeed", 10, 200)
	toggleRow(v, "Character Spin", "CharSpin")
	sliderRow(v, "Spin Speed", "SpinSpeed", 1, 40)
	toggleRow(v, "Noclip", "Noclip")
	toggleRow(v, "Infinite Jump", "InfJump")

	local c = sectionCard(host, "Camera")
	toggleRow(c, "Third Person", "ThirdPerson")
	sliderRow(c, "Max Wheel Zoom", "TPMaxZoom", 4, 64)
	sliderRow(c, "FOV", "FOV", 50, 120)
	note(c, "Third Person uses Roblox native scroll-wheel camera.")
end

function pages.Target(host)
	local t = sectionCard(host, "Targeting")
	toggleRow(t, "Nearest Target", "NearestTarget")
	toggleRow(t, "Target Lock", "TargetLock")
	sliderRow(t, "Distance Limit", "DistLimit", 50, 500)
	buttonRow(t, "Select Nearest", function()
		if TargetManager and TargetManager.SelectNearest then TargetManager.SelectNearest() end
	end)
	buttonRow(t, "Clear Target", function()
		if TargetManager and TargetManager.Clear then TargetManager.Clear() end
	end)

	local b = sectionCard(host, "Blobman")
	toggleRow(b, "Blob Loop", "BlobLoop")
	toggleRow(b, "Blob Grab All", "BlobGrabAll")
	toggleRow(b, "Auto Sit Blobman", "BlobAutoSit")
	toggleRow(b, "Freeze Blobman", "BlobFreeze")
	note(b, "Net Owner Spam: unsupported")
end

function pages.Visuals(host)
	local e = sectionCard(host, "Player ESP")
	toggleRow(e, "Player ESP", "PlayerESP")
	toggleRow(e, "Distance ESP", "DistESP")
	toggleRow(e, "Health ESP", "HealthESP")
	toggleRow(e, "Target ESP", "TargetESP")
	toggleRow(e, "Rainbow ESP", "Rainbow")
	sliderRow(e, "ESP Distance", "ESPMaxDist", 50, 800)

	local w = sectionCard(host, "World")
	toggleRow(w, "Fullbright", "Fullbright")
	toggleRow(w, "No Fog", "NoFog")
	toggleRow(w, "No Shadows", "NoShadows")
	toggleRow(w, "Custom Time", "CustomTime")
	sliderRow(w, "Clock Time", "ClockTime", 0, 24)
end

function pages.World(host)
	local m = sectionCard(host, "World / Misc")
	buttonRow(m, "Respawn", function()
		pcall(function()
			local ch = LP.Character
			if ch then local h = ch:FindFirstChildOfClass("Humanoid"); if h then h.Health = 0 end end
		end)
	end)
	buttonRow(m, "Rejoin Server", function()
		pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
	end)
	toggleRow(m, "Fullbright", "Fullbright")
	toggleRow(m, "No Fog", "NoFog")
	toggleRow(m, "No Shadows", "NoShadows")
	toggleRow(m, "Custom Time", "CustomTime")
	sliderRow(m, "Clock Time", "ClockTime", 0, 24)
	toggleRow(m, "Noclip Barrier", "NoclipBarrier")
	toggleRow(m, "Anti Invis", "AntiInvis")
end

function pages.Lists(host)
	local w = sectionCard(host, "Whitelist")
	toggleRow(w, "Whitelist Enabled", "WhitelistEnabled")
	toggleRow(w, "Auto Whitelist Friends", "AutoWLFriends")
	note(w, "Whitelisted players are ignored by targeting/combat where supported.")
end

function pages.Settings(host)
	local a = sectionCard(host, "Appearance")
	sliderRow(a, "UI Transparency", "UITransparency", 0, 0.75, function()
		-- live refresh cards if needed later
	end)
	note(a, "BackgroundImage: set Config.BackgroundImage to rbxassetid:// or leave empty.")
	toggleRow(a, "Rainbow UI", "RainbowUI")
	sliderRow(a, "Rainbow Speed", "RainbowSpeed", 0.1, 2)

	local c = sectionCard(host, "Config")
	toggleRow(c, "Notifications", "NotifEnabled")
	buttonRow(c, "Save Default", function()
		if Pengu and Pengu.Get then
			local cm = Pengu.Get("ConfigManager.lua")
			if cm and cm.Save then cm.Save() end
		end
		notify("Config saved")
	end)
	buttonRow(c, "Load Default", function()
		if Pengu and Pengu.Get then
			local cm = Pengu.Get("ConfigManager.lua")
			if cm and cm.Load then cm.Load() end
		end
		notify("Config loaded")
	end)

	local i = sectionCard(host, "Info")
	note(i, "Pengu " .. ((Config and Config.Version) or "0.5.0"))
	note(i, "RightCtrl toggles GUI. Super Strength = RMB while holding.")
end

local PAGE_ORDER = {
	{id = "Combat", icon = "⚔"},
	{id = "Defense", icon = "🛡"},
	{id = "Player", icon = "👤"},
	{id = "Target", icon = "◎"},
	{id = "Visuals", icon = "👁"},
	{id = "World", icon = "🌐"},
	{id = "Lists", icon = "☰"},
	{id = "Settings", icon = "⚙"},
}

local function showPage(id, content, sideButtons)
	UI.ActivePage = id
	clearPage(content)
	local builder = pages[id]
	if builder then
		builder(content)
	end
	for name, btn in pairs(sideButtons) do
		if name == id then
			btn.BackgroundColor3 = accent()
			btn.TextColor3 = Color3.new(1, 1, 1)
		else
			btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			btn.BackgroundTransparency = 1
			btn.TextColor3 = MUTED
		end
	end
end

function UI.Init(ctx)
	Pengu = ctx
	Config = ctx.Get("config.lua")
	TargetManager = ctx.Get("TargetManager.lua")
	Combat = ctx.Get("combat.lua")
	Defense = ctx.Get("defense.lua")
	PlayerController = ctx.Get("PlayerController.lua")

	for _, n in ipairs({"PenguUI", "PenguIntro"}) do
		local old = CoreGui:FindFirstChild(n)
		if old then old:Destroy() end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "PenguUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	pcall(function() gui.Parent = CoreGui end)
	if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
	UI.Gui = gui

	local root = mk("Frame", {
		Name = "Root",
		Size = UDim2.new(0, 720, 0, 460),
		Position = UDim2.new(0.5, -360, 0.5, -230),
		BackgroundColor3 = BG,
		BackgroundTransparency = panelT(),
		BorderSizePixel = 0,
		Active = true,
	}, gui)
	corner(root, 12)
	stroke(root, 1)

	-- optional background image
	local bgImg = mk("ImageLabel", {
		Name = "CustomBG",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
	}, root)
	corner(bgImg, 12)
	local function refreshBG()
		local id = Config and Config.BackgroundImage or ""
		if type(id) == "string" and #id > 0 then
			bgImg.Image = id
			bgImg.Visible = true
		else
			bgImg.Visible = false
		end
		root.BackgroundTransparency = panelT()
	end
	refreshBG()

	-- top bar
	local top = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = SIDE,
		BackgroundTransparency = panelT() * 0.5,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, root)
	mk("UICorner", {CornerRadius = UDim.new(0, 12)}, top)
	local brand = mk("TextLabel", {
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = "Pengu",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, top)
	bindAccent(brand, "TextColor3")

	local search = mk("TextBox", {
		Size = UDim2.new(0, 180, 0, 28),
		Position = UDim2.new(1, -200, 0.5, -14),
		BackgroundColor3 = CARD,
		BackgroundTransparency = panelT(),
		PlaceholderText = "Search",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = TEXT,
		PlaceholderColor3 = MUTED,
		ClearTextOnFocus = false,
		ZIndex = 3,
	}, top)
	corner(search, 6)
	stroke(search, 1)
	pad(search, 8, 0, 8, 0)

	-- sidebar
	local side = mk("Frame", {
		Size = UDim2.new(0, 140, 1, -44),
		Position = UDim2.new(0, 0, 0, 44),
		BackgroundColor3 = SIDE,
		BackgroundTransparency = panelT() * 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, root)

	local sideList = mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, side)
	pad(side, 8, 10, 8, 10)

	-- content scroll
	local content = mk("ScrollingFrame", {
		Size = UDim2.new(1, -150, 1, -54),
		Position = UDim2.new(0, 146, 0, 50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
	}, root)
	local cl = mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
	}, content)
	pad(content, 6, 4, 10, 12)

	-- two-column helper: single column list of cards is fine for density
	local sideButtons = {}
	for i, p in ipairs(PAGE_ORDER) do
		local b = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			Text = "  " .. p.id,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = MUTED,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			LayoutOrder = i,
			AutoButtonColor = false,
			ZIndex = 3,
		}, side)
		corner(b, 6)
		sideButtons[p.id] = b
		b.MouseButton1Click:Connect(function()
			showPage(p.id, content, sideButtons)
		end)
	end

	showPage("Combat", content, sideButtons)

	-- drag
	local dragging, dragStart, startPos
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = root.Position
		end
	end)
	table.insert(UI.Connections, UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end))
	table.insert(UI.Connections, UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - dragStart
			root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))

	-- toggle key
	table.insert(UI.Connections, UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		local key = (Config and Config.MenuKey) or Enum.KeyCode.RightControl
		if input.KeyCode == key then
			root.Visible = not root.Visible
		end
	end))

	-- rainbow accent
	table.insert(UI.Connections, RunService.RenderStepped:Connect(function()
		if Config and Config.RainbowUI then
			local h = (tick() * (Config.RainbowSpeed or 0.5)) % 1
			Config.Accent = Color3.fromHSV(h, 0.75, 1)
			applyAccent()
		end
	end))

	-- search filters card titles (simple hide)
	search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(search.Text or "")
		for _, child in ipairs(content:GetChildren()) do
			if child:IsA("Frame") then
				local head = child:FindFirstChildWhichIsA("TextLabel")
				if head then
					child.Visible = q == "" or string.find(string.lower(head.Text), q, 1, true) ~= nil
				end
			end
		end
	end)

	notify("Pengu ready")
end

function UI.Destroy()
	for _, c in ipairs(UI.Connections) do
		pcall(function() c:Disconnect() end)
	end
	UI.Connections = {}
	if UI.Gui then UI.Gui:Destroy() UI.Gui = nil end
end

return UI
