run(function()
	local TargetHUD
	local Accent
	local RainbowAccent
	local ShowWinLose
	local ShowDistance
	local HUDScale
	local BGTransparency
	local PosX
	local PosY

	local ui = {}
	local root
	local currentTarget, lastSeen = nil, 0
	local lastHp, shownPct, trailPct = nil, 1, 1
	local visibleAlpha = 0
	local hurtTime = 0
	local dragging = false

	local function font(weight)
		return Font.new('rbxasset://fonts/families/GothamSSm.json', weight or Enum.FontWeight.Regular)
	end

	local function accentColor()
		if RainbowAccent and RainbowAccent.Enabled then
			return Color3.fromHSV((tick() * 0.15) % 1, 0.75, 1)
		end
		if Accent then return Color3.fromHSV(Accent.Hue, Accent.Sat, Accent.Value) end
		return Color3.fromRGB(140, 110, 255)
	end

	local function new(class, props, parent)
		local o = Instance.new(class)
		for k, v in props do o[k] = v end
		o.Parent = parent
		return o
	end

	local function build()
		root = new('Frame', {
			Name = 'RequiemTargetHUD',
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(250, 72),
			Position = UDim2.fromScale((PosX and PosX.Value or 50) / 100, (PosY and PosY.Value or 64) / 100),
			BackgroundColor3 = Color3.fromRGB(12, 12, 14),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 50,
		}, vape.gui)
		new('UICorner', {CornerRadius = UDim.new(0, 8)}, root)
		ui.stroke = new('UIStroke', {Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, root)
		ui.scale = new('UIScale', {Scale = HUDScale and HUDScale.Value or 1}, root)

		-- accent line along the top
		ui.topLine = new('Frame', {
			Size = UDim2.new(1, -16, 0, 2),
			Position = UDim2.fromOffset(8, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ZIndex = 51,
		}, root)
		new('UICorner', {CornerRadius = UDim.new(1, 0)}, ui.topLine)

		-- avatar
		ui.headHolder = new('Frame', {
			Size = UDim2.fromOffset(52, 52),
			Position = UDim2.fromOffset(10, 10),
			BackgroundColor3 = Color3.fromRGB(25, 25, 30),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 51,
		}, root)
		new('UICorner', {CornerRadius = UDim.new(0, 6)}, ui.headHolder)
		ui.headScale = new('UIScale', {Scale = 1}, ui.headHolder)
		ui.head = new('ImageLabel', {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			ZIndex = 52,
		}, ui.headHolder)
		new('UICorner', {CornerRadius = UDim.new(0, 6)}, ui.head)
		ui.hurt = new('Frame', {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 53,
		}, ui.headHolder)
		new('UICorner', {CornerRadius = UDim.new(0, 6)}, ui.hurt)

		-- name
		ui.name = new('TextLabel', {
			Size = UDim2.new(1, -140, 0, 18),
			Position = UDim2.fromOffset(72, 9),
			BackgroundTransparency = 1,
			FontFace = font(Enum.FontWeight.Bold),
			TextSize = 15,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 52,
		}, root)

		-- win / lose tag
		ui.status = new('TextLabel', {
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.fromOffset(64, 16),
			Position = UDim2.new(1, -10, 0, 10),
			BackgroundColor3 = Color3.fromRGB(60, 200, 90),
			BackgroundTransparency = 1,
			FontFace = font(Enum.FontWeight.Bold),
			TextSize = 10,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 1,
			ZIndex = 52,
		}, root)
		new('UICorner', {CornerRadius = UDim.new(0, 4)}, ui.status)

		-- health number with heart
		ui.hp = new('TextLabel', {
			Size = UDim2.fromOffset(120, 16),
			Position = UDim2.fromOffset(72, 28),
			BackgroundTransparency = 1,
			FontFace = font(Enum.FontWeight.SemiBold),
			TextSize = 13,
			RichText = true,
			TextColor3 = Color3.fromRGB(230, 230, 230),
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 52,
		}, root)

		-- distance
		ui.dist = new('TextLabel', {
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.fromOffset(80, 16),
			Position = UDim2.new(1, -10, 0, 28),
			BackgroundTransparency = 1,
			FontFace = font(Enum.FontWeight.Regular),
			TextSize = 11,
			TextColor3 = Color3.fromRGB(150, 150, 160),
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 52,
		}, root)

		-- health bar
		ui.barBG = new('Frame', {
			Size = UDim2.new(1, -82, 0, 8),
			Position = UDim2.fromOffset(72, 50),
			BackgroundColor3 = Color3.fromRGB(35, 35, 42),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 52,
		}, root)
		new('UICorner', {CornerRadius = UDim.new(1, 0)}, ui.barBG)
		ui.trail = new('Frame', {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 235, 235),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 53,
		}, ui.barBG)
		new('UICorner', {CornerRadius = UDim.new(1, 0)}, ui.trail)
		ui.bar = new('Frame', {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 54,
		}, ui.barBG)
		new('UICorner', {CornerRadius = UDim.new(1, 0)}, ui.bar)
		ui.barGrad = new('UIGradient', {}, ui.bar)

		-- dragging (only while the click GUI is open)
		local dragStart, startPos
		root.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = root.AbsolutePosition + root.AbsoluteSize / 2
			end
		end)
		TargetHUD:Clean(inputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local screen = vape.gui.AbsoluteSize
				local p = startPos + (Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(dragStart.X, dragStart.Y))
				local sx = math.clamp(p.X / screen.X * 100, 0, 100)
				local sy = math.clamp(p.Y / screen.Y * 100, 0, 100)
				root.Position = UDim2.fromScale(sx / 100, sy / 100)
				if PosX then PosX:SetValue(math.floor(sx * 10) / 10) end
				if PosY then PosY:SetValue(math.floor(sy * 10) / 10) end
			end
		end))
		TargetHUD:Clean(inputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
	end

	local function setAlpha(a)
		-- a: 0 = hidden, 1 = fully shown
		local bgT = BGTransparency and BGTransparency.Value or 0.15
		root.BackgroundTransparency = 1 - (1 - bgT) * a
		ui.stroke.Transparency = 1 - 0.6 * a
		ui.topLine.BackgroundTransparency = 1 - a
		ui.headHolder.BackgroundTransparency = 1 - a
		ui.head.ImageTransparency = 1 - a
		ui.name.TextTransparency = 1 - a
		ui.hp.TextTransparency = 1 - a
		ui.dist.TextTransparency = 1 - a
		ui.status.TextTransparency = 1 - a
		ui.status.BackgroundTransparency = 1 - 0.85 * a
		ui.barBG.BackgroundTransparency = 1 - a
		ui.bar.BackgroundTransparency = 1 - a
		ui.trail.BackgroundTransparency = 1 - 0.6 * a
		root.Visible = a > 0.01
	end

	local function findTarget()
		local t = store.KillauraTarget
		if t and t.Head and t.Head.Parent and (t.Health or 0) > 0 then return t end
		local best, bestTime = nil, 0
		if targetinfo and targetinfo.Targets then
			for ent, time in targetinfo.Targets do
				if time > bestTime and time > os.clock() - 0.1 and ent.Head and ent.Head.Parent then
					best, bestTime = ent, time
				end
			end
		end
		return best
	end

	local function setTarget(ent)
		currentTarget = ent
		lastHp = ent.Health
		local pct = math.clamp((ent.Health or 0) / math.max(ent.MaxHealth or 100, 1), 0, 1)
		shownPct, trailPct = pct, pct
		ui.name.Text = ent.Player and ent.Player.DisplayName or (ent.Character and ent.Character.Name) or 'Target'
		if ent.Player then
			ui.head.Image = 'rbxthumb://type=AvatarHeadShot&id='..ent.Player.UserId..'&w=150&h=150'
		else
			ui.head.Image = ''
		end
	end

	TargetHUD = vape.Categories.Render:CreateModule({
		Name = 'Target HUD',
		Tooltip = 'Client-style target panel on your screen. Drag it while the GUI is open.',
		Function = function(callback)
			if callback then
				build()
				setAlpha(0)

				TargetHUD:Clean(runService.RenderStepped:Connect(function(dt)
					local guiOpen = vape.gui.ScaledGui and vape.gui.ScaledGui.ClickGui and vape.gui.ScaledGui.ClickGui.Visible
					local ent = findTarget()

					if ent then
						if ent ~= currentTarget then setTarget(ent) end
						lastSeen = tick()
					end

					-- keep showing the last target briefly, or show a preview while the GUI is open
					local showing = currentTarget and (tick() - lastSeen) < 1.2 and currentTarget.Head and currentTarget.Head.Parent
					if not showing and guiOpen and entitylib.isAlive then
						if currentTarget ~= entitylib.character then setTarget(entitylib.character) end
						showing = true
					end

					local goal = showing and 1 or 0
					visibleAlpha += (goal - visibleAlpha) * math.min(dt * 12, 1)
					setAlpha(visibleAlpha)
					root.Active = guiOpen and true or false
					if not showing or not currentTarget then return end

					local t = currentTarget
					local hp = t.Health or 0
					local maxHp = math.max(t.MaxHealth or 100, 1)
					local pct = math.clamp(hp / maxHp, 0, 1)

					if lastHp and hp < lastHp - 0.01 then hurtTime = tick() end
					lastHp = hp

					-- animated bars
					shownPct += (pct - shownPct) * math.min(dt * 14, 1)
					if trailPct > shownPct then
						trailPct = math.max(shownPct, trailPct - dt * 0.35)
					else
						trailPct = shownPct
					end
					ui.bar.Size = UDim2.fromScale(shownPct, 1)
					ui.trail.Size = UDim2.fromScale(trailPct, 1)

					local hpColor = Color3.fromHSV(pct * 0.33, 0.85, 1)
					local acc = accentColor()
					ui.barGrad.Color = ColorSequence.new(hpColor:Lerp(acc, 0.35), hpColor)
					ui.topLine.BackgroundColor3 = acc
					ui.stroke.Color = acc

					ui.hp.Text = string.format('<font color="#ff5a6e">\u{2764}</font> %.1f <font color="#8a8a96">/ %d</font>', hp, math.floor(maxHp))

					-- hurt flash + head punch
					local since = tick() - hurtTime
					local flash = math.clamp(1 - since / 0.35, 0, 1)
					ui.hurt.BackgroundTransparency = 1 - flash * 0.55
					ui.headScale.Scale = 1 - flash * 0.12

					-- distance + win/lose
					local myAlive = entitylib.isAlive and entitylib.character.RootPart
					if ShowDistance.Enabled and myAlive and t.RootPart and t ~= entitylib.character then
						ui.dist.Text = string.format('%.1fm', (entitylib.character.RootPart.Position - t.RootPart.Position).Magnitude)
					else
						ui.dist.Text = ''
					end

					if ShowWinLose.Enabled and myAlive and t ~= entitylib.character then
						local mine = entitylib.character.Health or 0
						if mine > hp + 0.5 then
							ui.status.Text = 'WINNING'
							ui.status.BackgroundColor3 = Color3.fromRGB(50, 190, 90)
						elseif mine < hp - 0.5 then
							ui.status.Text = 'LOSING'
							ui.status.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
						else
							ui.status.Text = 'EVEN'
							ui.status.BackgroundColor3 = Color3.fromRGB(200, 170, 50)
						end
					else
						ui.status.Text = ''
						ui.status.BackgroundTransparency = 1
					end
				end))

				TargetHUD:Clean(function()
					if root then root:Destroy() end
					root = nil
					table.clear(ui)
					currentTarget, lastHp, visibleAlpha, dragging = nil, nil, 0, false
				end)
			end
		end
	})

	Accent = TargetHUD:CreateColorSlider({Name = 'Accent', DefaultHue = 0.72})
	RainbowAccent = TargetHUD:CreateToggle({Name = 'Rainbow accent'})
	ShowWinLose = TargetHUD:CreateToggle({Name = 'Winning / Losing', Default = true})
	ShowDistance = TargetHUD:CreateToggle({Name = 'Show distance', Default = true})
	HUDScale = TargetHUD:CreateSlider({
		Name = 'Scale', Min = 0.5, Max = 2, Default = 1, Decimal = 10,
		Function = function(v) if ui.scale then ui.scale.Scale = v end end
	})
	BGTransparency = TargetHUD:CreateSlider({
		Name = 'BG transparency', Min = 0, Max = 0.9, Default = 0.15, Decimal = 20
	})
	PosX = TargetHUD:CreateSlider({
		Name = 'X position', Min = 0, Max = 100, Default = 50, Decimal = 10, Darker = true,
		Suffix = function() return '%' end,
		Function = function(v)
			if root and not dragging then root.Position = UDim2.fromScale(v / 100, root.Position.Y.Scale) end
		end
	})
	PosY = TargetHUD:CreateSlider({
		Name = 'Y position', Min = 0, Max = 100, Default = 64, Decimal = 10, Darker = true,
		Suffix = function() return '%' end,
		Function = function(v)
			if root and not dragging then root.Position = UDim2.fromScale(root.Position.X.Scale, v / 100) end
		end
	})
end)
