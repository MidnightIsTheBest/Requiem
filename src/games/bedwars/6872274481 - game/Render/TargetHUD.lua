run(function()
	local TargetHUD
	local ShowHealth
	local ShowDistance
	local ShowName
	local HUDColor
	local HUDTransparency
	local HUDScale
	local activeHUD
	local hud = {}

	local function clearHUD()
		if activeHUD then
			activeHUD:Destroy()
			activeHUD = nil
			table.clear(hud)
		end
	end

	local function buildHUD(entity)
		clearHUD()
		if not TargetHUD.Enabled or not entity or not entity.Head or not entity.Head.Parent then return end
		if vape.ThreadFix then setthreadidentity(8) end

		local bb = Instance.new('BillboardGui')
		bb.Name = 'RequiemTargetHUD'
		bb.Adornee = entity.Head
		bb.Size = UDim2.fromOffset(200, 90)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.ResetOnSpawn = false
		bb.Parent = vape.holder
		activeHUD = bb

		local bg = Instance.new('Frame')
		bg.BackgroundColor3 = Color3.fromHSV(HUDColor.Hue, HUDColor.Sat, HUDColor.Value)
		bg.BackgroundTransparency = HUDTransparency.Value
		bg.Size = UDim2.fromScale(1, 1)
		bg.Parent = bb
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = bg
		local stroke = Instance.new('UIStroke')
		stroke.Color = Color3.fromHSV(vape.GUIColor.Hue, vape.GUIColor.Sat, vape.GUIColor.Val or 1)
		stroke.Transparency = 0.5
		stroke.Parent = bg

		local layout = Instance.new('UIListLayout')
		layout.Padding = UDim.new(0, 2)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Parent = bg

		local pad = Instance.new('UIPadding')
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.Parent = bg

		local nameLabel = Instance.new('TextLabel')
		nameLabel.Name = 'TargetName'
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1, 0, 0, 18)
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextSize = 14
		nameLabel.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.Text = entity.Player and entity.Player.DisplayName or 'Unknown'
		nameLabel.Visible = ShowName.Enabled
		nameLabel.Parent = bg

		local healthBG = Instance.new('Frame')
		healthBG.Name = 'HealthBG'
		healthBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		healthBG.Size = UDim2.new(1, 0, 0, 10)
		healthBG.Visible = ShowHealth.Enabled
		healthBG.Parent = bg
		local hCorner = Instance.new('UICorner')
		hCorner.CornerRadius = UDim.new(1, 0)
		hCorner.Parent = healthBG

		local healthBar = Instance.new('Frame')
		healthBar.Name = 'HealthBar'
		healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
		healthBar.Size = UDim2.fromScale(1, 1)
		healthBar.Parent = healthBG
		local hbCorner = Instance.new('UICorner')
		hbCorner.CornerRadius = UDim.new(1, 0)
		hbCorner.Parent = healthBar

		local healthText = Instance.new('TextLabel')
		healthText.Name = 'HealthText'
		healthText.BackgroundTransparency = 1
		healthText.Size = UDim2.fromScale(1, 1)
		healthText.TextColor3 = Color3.new(1, 1, 1)
		healthText.TextSize = 8
		healthText.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		healthText.Text = ''
		healthText.Parent = healthBG

		local distLabel = Instance.new('TextLabel')
		distLabel.Name = 'Distance'
		distLabel.BackgroundTransparency = 1
		distLabel.Size = UDim2.new(1, 0, 0, 14)
		distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		distLabel.TextSize = 11
		distLabel.FontFace = Font.fromEnum(Enum.Font.Gotham)
		distLabel.Text = ''
		distLabel.Visible = ShowDistance.Enabled
		distLabel.Parent = bg

		hud.nameLabel = nameLabel
		hud.healthBar = healthBar
		hud.healthBG = healthBG
		hud.healthText = healthText
		hud.distLabel = distLabel

		local uiScale = Instance.new('UIScale')
		uiScale.Scale = HUDScale.Value
		uiScale.Parent = bb
		hud.uiScale = uiScale
	end

	TargetHUD = vape.Categories.Render:CreateModule({
		Name = 'Target HUD',
		Tooltip = 'Shows a HUD above your current target with health and distance',
		Function = function(callback)
			if callback then
				local lastTarget

				TargetHUD:Clean(runService.RenderStepped:Connect(function()
					local target = store.KillauraTarget
					if not target or not target.Head or not target.Head.Parent then
						-- check targetinfo fallback
						local best, bestTime = nil, 0
						if targetinfo and targetinfo.Targets then
							for ent, t in targetinfo.Targets do
								if t > bestTime and ent.Head and ent.Head.Parent then
									best = ent
									bestTime = t
								end
							end
						end
						target = best
					end

					if not target or not target.Head or not target.Head.Parent then
						clearHUD()
						lastTarget = nil
						return
					end

					if target ~= lastTarget then
						buildHUD(target)
						lastTarget = target
					end

					if not activeHUD then return end
					activeHUD.Adornee = target.Head

					local hp = target.Health or 0
					local maxHp = target.MaxHealth or 100
					local pct = math.clamp(hp / maxHp, 0, 1)
					hud.healthBar.Size = UDim2.fromScale(pct, 1)
					hud.healthBar.BackgroundColor3 = Color3.fromHSV(pct / 2.8, 0.9, 0.85)
					hud.healthText.Text = math.floor(hp)..' / '..math.floor(maxHp)

					if entitylib.isAlive and target.RootPart then
						local dist = (entitylib.character.RootPart.Position - target.RootPart.Position).Magnitude
						hud.distLabel.Text = string.format('%.1f studs', dist)
					end
				end))

				TargetHUD:Clean(clearHUD)
			else
				clearHUD()
			end
		end
	})

	ShowName = TargetHUD:CreateToggle({Name = 'Show name', Default = true})
	ShowHealth = TargetHUD:CreateToggle({Name = 'Show health', Default = true})
	ShowDistance = TargetHUD:CreateToggle({Name = 'Show distance', Default = true})
	HUDScale = TargetHUD:CreateSlider({
		Name = 'Scale', Min = 0.5, Max = 2, Default = 1, Decimal = 10,
		Function = function(v)
			if activeHUD and hud.uiScale then hud.uiScale.Scale = v end
		end
	})
	HUDTransparency = TargetHUD:CreateSlider({
		Name = 'BG transparency', Min = 0, Max = 1, Default = 0.3, Decimal = 20,
		Function = function(v)
			if activeHUD then
				local bg = activeHUD:FindFirstChildWhichIsA('Frame')
				if bg then bg.BackgroundTransparency = v end
			end
		end
	})
	HUDColor = TargetHUD:CreateColorSlider({
		Name = 'BG color',
		Function = function(h, s, v)
			if activeHUD then
				local bg = activeHUD:FindFirstChildWhichIsA('Frame')
				if bg then bg.BackgroundColor3 = Color3.fromHSV(h, s, v) end
			end
		end
	})
end)
