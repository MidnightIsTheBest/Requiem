run(function()
	-- REQUIEM: Target HUD rebuilt after studying LiquidBounce, FDPClient and LiquidBounce++
	-- target HUD sources (Modern / Rise / Astolfo styles). Exponential-lerp health, a damage
	-- trail that holds then drains, head shrink + red tint on hurt, hit particles, pop-in.
	local TargetHUD
	local Style
	local BarMode
	local Accent
	local Particles
	local ShowWinLose
	local HUDScale
	local BGTransparency
	local PosX
	local PosY

	local STYLES = {
		Modern = {
			w = 240, h = 72, corner = 8, bg = Color3.fromRGB(15, 15, 18), bgT = 0.3, stroke = true,
			head = {8, 8, 56, 6}, name = {74, 9, 15}, sub = {74, 29, 12},
			bar = {74, 52, 158, 8, 4}, track = true, gloss = true, number = 'right', tag = true,
		},
		Rise = {
			w = 250, h = 78, corner = 10, bg = Color3.fromRGB(0, 0, 0), bgT = 0.38, stroke = false,
			head = {10, 10, 44, 8}, name = {62, 12, 15}, sub = {62, 31, 12},
			bar = {10, 64, 230, 7, 4}, track = true, gloss = false, number = 'ride', tag = false,
		},
		Astolfo = {
			w = 210, h = 68, corner = 0, bg = Color3.fromRGB(0, 0, 0), bgT = 0.37, stroke = false,
			head = {8, 8, 44, 0}, name = {60, 6, 14}, sub = nil, big = {60, 22, 26},
			bar = {8, 56, 194, 8, 0}, track = false, gloss = false, number = 'big', tag = false,
		},
	}

	local ui, root, style = {}, nil, nil
	local currentTarget, lastSeen = nil, 0
	local lastHp, shownPct, trailPct, shownHp = nil, 1, 1, 0
	local hurtTime = 0
	local isShown = false
	local dragging = false

	local function font(weight)
		return Font.new('rbxasset://fonts/families/GothamSSm.json', weight or Enum.FontWeight.Regular)
	end

	local function new(class, props, parent)
		local o = Instance.new(class)
		for k, v in props do o[k] = v end
		o.Parent = parent
		return o
	end

	local function accentColor()
		return Color3.fromHSV(Accent.Hue, Accent.Sat, Accent.Value)
	end

	-- FDP getHealthColor: dark red -> orange -> green, then brightened
	local function healthColor(pct)
		local a
		if pct < 0.5 then
			a = Color3.fromRGB(108, 0, 0):Lerp(Color3.fromRGB(255, 51, 0), pct * 2)
		else
			a = Color3.fromRGB(255, 51, 0):Lerp(Color3.fromRGB(0, 255, 0), (pct - 0.5) * 2)
		end
		return Color3.new(math.min(a.R / 0.7, 1), math.min(a.G / 0.7, 1), math.min(a.B / 0.7, 1))
	end

	local function palette(index, pct)
		local mode = BarMode.Value
		local t = tick()
		if mode == 'Astolfo' then
			local h = ((t * 1000 + index * 109) / 5 % 360) / 360
			if h < 0.5 then h = 1 - h end
			return Color3.fromHSV(h, 0.5, 1)
		elseif mode == 'Rainbow' then
			return Color3.fromHSV((t * 0.25 + index * 0.06) % 1, 0.7, 1)
		elseif mode == 'Fade' then
			local acc = accentColor()
			local v = 0.55 + 0.45 * math.abs(math.sin(t * math.pi / 2 + index * 0.5))
			local h, s = acc:ToHSV()
			return Color3.fromHSV(h, s, v)
		elseif mode == 'Accent' then
			return accentColor()
		end
		return healthColor(pct)
	end

	local function build()
		style = STYLES[Style.Value] or STYLES.Modern
		local s = style
		root = new('CanvasGroup', {
			Name = 'RequiemTargetHUD',
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(s.w, s.h),
			Position = UDim2.fromScale(PosX.Value / 100, PosY.Value / 100),
			BackgroundColor3 = s.bg,
			BackgroundTransparency = BGTransparency.Value,
			BorderSizePixel = 0,
			GroupTransparency = 1,
			Active = true,
			ZIndex = 50,
		}, vape.gui)
		if s.corner > 0 then new('UICorner', {CornerRadius = UDim.new(0, s.corner)}, root) end
		ui.stroke = s.stroke and new('UIStroke', {Thickness = 1, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, root) or nil
		ui.scale = new('UIScale', {Scale = HUDScale.Value * 0.85}, root)

		-- head (centred anchor so it shrinks in place on hurt)
		local hd = s.head
		ui.head = new('ImageLabel', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(hd[3], hd[3]),
			Position = UDim2.fromOffset(hd[1] + hd[3] / 2, hd[2] + hd[3] / 2),
			BackgroundColor3 = Color3.fromRGB(30, 30, 36),
			BackgroundTransparency = 0.2,
			ZIndex = 52,
		}, root)
		ui.headSize = hd[3]
		ui.headCenter = Vector2.new(hd[1] + hd[3] / 2, hd[2] + hd[3] / 2)
		if hd[4] > 0 then new('UICorner', {CornerRadius = UDim.new(0, hd[4])}, ui.head) end

		ui.name = new('TextLabel', {
			Size = UDim2.fromOffset(s.w - s.name[1] - (s.tag and 76 or 10), 18),
			Position = UDim2.fromOffset(s.name[1], s.name[2]),
			BackgroundTransparency = 1,
			FontFace = font(Enum.FontWeight.Bold),
			TextSize = s.name[3],
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 52,
		}, root)

		if s.sub then
			ui.sub = new('TextLabel', {
				Size = UDim2.fromOffset(s.w - s.sub[1] - 10, 16),
				Position = UDim2.fromOffset(s.sub[1], s.sub[2]),
				BackgroundTransparency = 1,
				FontFace = font(Enum.FontWeight.Medium),
				TextSize = s.sub[3],
				RichText = true,
				TextColor3 = Color3.new(1, 1, 1),
				TextTransparency = 0.4,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 52,
			}, root)
		end

		if s.tag then
			ui.tag = new('TextLabel', {
				AnchorPoint = Vector2.new(1, 0),
				Size = UDim2.fromOffset(62, 16),
				Position = UDim2.new(1, -8, 0, 9),
				BackgroundTransparency = 0.15,
				FontFace = font(Enum.FontWeight.Bold),
				TextSize = 10,
				TextColor3 = Color3.new(1, 1, 1),
				ZIndex = 52,
			}, root)
			new('UICorner', {CornerRadius = UDim.new(0, 4)}, ui.tag)
		end

		-- bar: track -> trail -> fill (+ gloss)
		local b = s.bar
		ui.barX, ui.barY, ui.barW, ui.barH = b[1], b[2], b[3], b[4]
		ui.track = new('Frame', {
			Size = UDim2.fromOffset(b[3], b[4]),
			Position = UDim2.fromOffset(b[1], b[2]),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = s.track and 0.5 or 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 52,
		}, root)
		if b[5] > 0 then new('UICorner', {CornerRadius = UDim.new(0, b[5])}, ui.track) end
		ui.trail = new('Frame', {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 245, 200),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 53,
		}, ui.track)
		if b[5] > 0 then new('UICorner', {CornerRadius = UDim.new(0, b[5])}, ui.trail) end
		ui.fill = new('Frame', {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 54,
		}, ui.track)
		if b[5] > 0 then new('UICorner', {CornerRadius = UDim.new(0, b[5])}, ui.fill) end
		ui.grad = new('UIGradient', {}, ui.fill)
		if s.gloss then
			new('Frame', {
				Size = UDim2.fromScale(1, 0.5),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				ZIndex = 55,
			}, ui.fill)
		end

		-- health number: right of the sub line / riding the bar end / big Astolfo number
		if s.number == 'big' then
			ui.num = new('TextLabel', {
				Size = UDim2.fromOffset(s.w - s.big[1] - 8, s.big[3]),
				Position = UDim2.fromOffset(s.big[1], s.big[2]),
				BackgroundTransparency = 1,
				FontFace = font(Enum.FontWeight.Heavy),
				TextSize = s.big[3],
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 52,
			}, root)
		elseif s.number == 'ride' then
			ui.num = new('TextLabel', {
				AnchorPoint = Vector2.new(0.5, 1),
				Size = UDim2.fromOffset(48, 14),
				BackgroundTransparency = 1,
				FontFace = font(Enum.FontWeight.Bold),
				TextSize = 12,
				TextColor3 = Color3.new(1, 1, 1),
				ZIndex = 56,
			}, root)
		else
			ui.num = new('TextLabel', {
				AnchorPoint = Vector2.new(1, 0),
				Size = UDim2.fromOffset(80, 16),
				Position = UDim2.new(1, -8, 0, s.sub[2]),
				BackgroundTransparency = 1,
				FontFace = font(Enum.FontWeight.Bold),
				TextSize = 13,
				RichText = true,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 52,
			}, root)
		end

		-- dragging while the click GUI is open
		local dragStart, startPos
		root.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = root.AbsolutePosition + root.AbsoluteSize / 2
			end
		end)
		ui.dragMove = inputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local screen = vape.gui.AbsoluteSize
				local p = startPos + (Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(dragStart.X, dragStart.Y))
				local sx = math.clamp(p.X / screen.X * 100, 0, 100)
				local sy = math.clamp(p.Y / screen.Y * 100, 0, 100)
				root.Position = UDim2.fromScale(sx / 100, sy / 100)
				PosX:SetValue(math.floor(sx * 10) / 10)
				PosY:SetValue(math.floor(sy * 10) / 10)
			end
		end)
		ui.dragEnd = inputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		isShown = false
	end

	local function destroy()
		if ui.dragMove then ui.dragMove:Disconnect() end
		if ui.dragEnd then ui.dragEnd:Disconnect() end
		if root then root:Destroy() end
		root = nil
		table.clear(ui)
		currentTarget, lastHp, isShown, dragging = nil, nil, false, false
	end

	local function setShown(show)
		if show == isShown or not root then return end
		isShown = show
		local target = HUDScale.Value
		if show then
			ui.scale.Scale = target * 0.85
			tweenService:Create(ui.scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target}):Play()
			tweenService:Create(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
		else
			tweenService:Create(ui.scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = target * 0.92}):Play()
			tweenService:Create(root, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1}):Play()
		end
	end

	local function spawnParticles(color)
		if not root then return end
		for _ = 1, 9 do
			local size = math.random(3, 6)
			local p = new('Frame', {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(size, size),
				Position = UDim2.fromOffset(ui.headCenter.X, ui.headCenter.Y),
				BackgroundColor3 = Color3.new(1, 1, 1):Lerp(color, math.random()),
				BorderSizePixel = 0,
				Rotation = math.random(0, 90),
				ZIndex = 60,
			}, root)
			if math.random() < 0.5 then new('UICorner', {CornerRadius = UDim.new(1, 0)}, p) end
			local goal = ui.headCenter + Vector2.new(math.random(-50, 50), math.random(-40, 40))
			tweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(goal.X, goal.Y),
				Rotation = p.Rotation + 90,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(1, 1),
			}):Play()
			task.delay(0.55, function() p:Destroy() end)
		end
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
		shownPct, trailPct, shownHp = pct, pct, ent.Health or 0
		ui.name.Text = ent.Player and ent.Player.DisplayName or (ent.Character and ent.Character.Name) or 'Target'
		ui.head.Image = ent.Player and ('rbxthumb://type=AvatarHeadShot&id='..ent.Player.UserId..'&w=150&h=150') or ''
	end

	local function lerpFactor(dt, speed)
		return 1 - math.exp(-dt * speed)
	end

	TargetHUD = vape.Categories.Render:CreateModule({
		Name = 'Target HUD',
		Tooltip = 'Minecraft-client style target panel (Modern / Rise / Astolfo). Drag it while the GUI is open.',
		Function = function(callback)
			if callback then
				build()

				TargetHUD:Clean(runService.RenderStepped:Connect(function(dt)
					if not root then return end
					local guiOpen = vape.gui.ScaledGui and vape.gui.ScaledGui.ClickGui and vape.gui.ScaledGui.ClickGui.Visible
					local ent = findTarget()
					if ent then
						if ent ~= currentTarget then setTarget(ent) end
						lastSeen = tick()
					end

					local showing = currentTarget and (tick() - lastSeen) < 1.5 and currentTarget.Head and currentTarget.Head.Parent
					if not showing and guiOpen and entitylib.isAlive then
						if currentTarget ~= entitylib.character then setTarget(entitylib.character) end
						showing = true
					end
					setShown(showing and true or false)
					root.Active = guiOpen and true or false
					if not currentTarget then return end

					local t = currentTarget
					local hp = t.Health or 0
					local maxHp = math.max(t.MaxHealth or 100, 1)
					local pct = math.clamp(hp / maxHp, 0, 1)

					if lastHp and hp < lastHp - 0.01 then
						hurtTime = tick()
						if Particles.Enabled and isShown then spawnParticles(palette(0, pct)) end
					end
					lastHp = hp

					-- health eases in ~100ms, trail holds 0.25s then drains
					shownPct += (pct - shownPct) * lerpFactor(dt, 10)
					shownHp += (hp - shownHp) * lerpFactor(dt, 10)
					if trailPct > shownPct then
						if tick() - hurtTime > 0.25 then
							trailPct += (shownPct - trailPct) * lerpFactor(dt, 6)
						end
					else
						trailPct = shownPct
					end
					ui.fill.Size = UDim2.fromScale(shownPct, 1)
					ui.trail.Size = UDim2.fromScale(trailPct, 1)

					-- bar colours (4 palette stops, animated)
					local c0 = palette(0, pct)
					ui.grad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, c0),
						ColorSequenceKeypoint.new(0.33, palette(50, pct)),
						ColorSequenceKeypoint.new(0.66, palette(100, pct)),
						ColorSequenceKeypoint.new(1, palette(150, pct)),
					})
					if ui.stroke then ui.stroke.Color = c0 end

					-- hurt: head shrinks to 0.8 and flashes red over 0.5s (Minecraft hurt time)
					local hurt = math.clamp(1 - (tick() - hurtTime) / 0.5, 0, 1)
					local size = ui.headSize * (1 - 0.2 * hurt)
					ui.head.Size = UDim2.fromOffset(size, size)
					ui.head.ImageColor3 = Color3.new(1, 1 - 0.6 * hurt, 1 - 0.6 * hurt)

					-- texts
					local myAlive = entitylib.isAlive and entitylib.character.RootPart
					local isSelf = t == entitylib.character
					if ui.sub then
						local parts = {}
						if myAlive and t.RootPart and not isSelf then
							table.insert(parts, string.format('%.1fm', (entitylib.character.RootPart.Position - t.RootPart.Position).Magnitude))
							local diff = (entitylib.character.Health or 0) - hp
							table.insert(parts, string.format('<font color="%s">%s%.1f HP</font>', diff >= 0 and '#5fe08a' or '#ff6b6b', diff >= 0 and '+' or '', diff))
						else
							table.insert(parts, isSelf and 'Preview' or '')
						end
						ui.sub.Text = table.concat(parts, '  ·  ')
					end

					if style.number == 'big' then
						ui.num.Text = string.format('%d \u{2764}', math.floor(shownHp + 0.5))
						ui.num.TextColor3 = c0
					elseif style.number == 'ride' then
						ui.num.Text = string.format('%.1f', shownHp)
						ui.num.Position = UDim2.fromOffset(math.clamp(ui.barX + ui.barW * shownPct, ui.barX + 14, ui.barX + ui.barW - 14), ui.barY - 1)
					else
						ui.num.Text = string.format('<font color="#ff5a6e">\u{2764}</font> %.1f', shownHp)
					end

					if ui.tag then
						if ShowWinLose.Enabled and myAlive and not isSelf then
							local mine = entitylib.character.Health or 0
							if mine > hp + 0.5 then
								ui.tag.Text, ui.tag.BackgroundColor3 = 'WINNING', Color3.fromRGB(45, 170, 85)
							elseif mine < hp - 0.5 then
								ui.tag.Text, ui.tag.BackgroundColor3 = 'LOSING', Color3.fromRGB(200, 55, 55)
							else
								ui.tag.Text, ui.tag.BackgroundColor3 = 'EVEN', Color3.fromRGB(190, 160, 45)
							end
							ui.tag.Visible = true
						else
							ui.tag.Visible = false
						end
					end
				end))

				TargetHUD:Clean(destroy)
			end
		end
	})

	local function rebuild()
		if TargetHUD and TargetHUD.Enabled and root then
			destroy()
			build()
		end
	end

	Style = TargetHUD:CreateDropdown({
		Name = 'Style',
		List = {'Modern', 'Rise', 'Astolfo'},
		Function = rebuild
	})
	BarMode = TargetHUD:CreateDropdown({
		Name = 'Bar colour',
		List = {'Health', 'Astolfo', 'Rainbow', 'Fade', 'Accent'}
	})
	Accent = TargetHUD:CreateColorSlider({Name = 'Accent', DefaultHue = 0.72})
	Particles = TargetHUD:CreateToggle({Name = 'Hit particles', Default = true})
	ShowWinLose = TargetHUD:CreateToggle({Name = 'Winning / Losing', Default = true, Tooltip = 'Modern style only'})
	HUDScale = TargetHUD:CreateSlider({
		Name = 'Scale', Min = 0.5, Max = 2, Default = 1, Decimal = 10,
		Function = function(v) if ui.scale and isShown then ui.scale.Scale = v end end
	})
	BGTransparency = TargetHUD:CreateSlider({
		Name = 'BG transparency', Min = 0, Max = 0.9, Default = 0.3, Decimal = 20,
		Function = function(v) if root then root.BackgroundTransparency = v end end
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
