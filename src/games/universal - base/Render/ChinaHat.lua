run(function()
	local ChinaHat
	local Radius
	local Height
	local Offset
	local Layers
	local Transparency
	local Color
	local Rainbow
	local RainbowSpeed
	local Self
	local Others
	local HideFirstPerson
	local Hats = {}

	local function destroyHat(ent)
		local hat = Hats[ent]
		if hat then
			Hats[ent] = nil
			for _, v in hat do v:Destroy() end
		end
	end

	local function buildHat(ent)
		destroyHat(ent)
		if not ChinaHat.Enabled or not ent or not ent.Head or not ent.Head.Parent then return end
		local isSelf = ent.Player == lplr
		if isSelf and not Self.Enabled then return end
		if (not isSelf) and not Others.Enabled then return end
		if vape.ThreadFix then setthreadidentity(8) end

		local hat = {}
		local n = math.floor(Layers.Value)
		local layerH = Height.Value / n
		local top = ent.Head.Size.Y / 2 + Offset.Value
		for i = 1, n do
			local frac = (i - 0.5) / n
			local a = Instance.new('CylinderHandleAdornment')
			a.Adornee = ent.Head
			a.Radius = math.max(Radius.Value * (1 - frac), 0.03)
			a.Height = layerH + 0.02
			a.InnerRadius = 0
			a.CFrame = CFrame.new(0, top + (i - 0.5) * layerH, 0) * CFrame.Angles(math.rad(90), 0, 0)
			a.Color3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			a.Transparency = Transparency.Value
			a.AlwaysOnTop = false
			a.ZIndex = 1
			a.Parent = vape.holder
			hat[i] = a
		end
		Hats[ent] = hat
	end

	local function rebuildAll()
		for ent in Hats do destroyHat(ent) end
		if not ChinaHat.Enabled then return end
		if entitylib.isAlive then buildHat(entitylib.character) end
		for _, ent in entitylib.List do buildHat(ent) end
	end

	ChinaHat = vape.Categories.Render:CreateModule({
		Name = 'China Hat',
		Tooltip = 'Cone shaped hat on players (stepped cylinders)',
		Function = function(callback)
			if callback then
				ChinaHat:Clean(entitylib.Events.LocalAdded:Connect(buildHat))
				ChinaHat:Clean(entitylib.Events.LocalRemoved:Connect(function(ent) destroyHat(ent or entitylib.character) end))
				ChinaHat:Clean(entitylib.Events.EntityAdded:Connect(buildHat))
				ChinaHat:Clean(entitylib.Events.EntityRemoved:Connect(destroyHat))
				rebuildAll()

				ChinaHat:Clean(runService.RenderStepped:Connect(function()
					local rainbowColor = Rainbow.Enabled and Color3.fromHSV((tick() * RainbowSpeed.Value * 0.1) % 1, 0.9, 1) or nil
					local firstPerson = HideFirstPerson.Enabled and gameCamera and (gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude < 1
					for ent, hat in Hats do
						if not (ent.Head and ent.Head.Parent) then
							destroyHat(ent)
						else
							local hide = firstPerson and ent.Player == lplr
							for _, a in hat do
								a.Visible = not hide
								if rainbowColor then a.Color3 = rainbowColor end
							end
						end
					end
				end))
			else
				for ent in Hats do destroyHat(ent) end
			end
		end
	})

	Radius = ChinaHat:CreateSlider({
		Name = 'Radius', Min = 0.5, Max = 6, Default = 2.2, Decimal = 10,
		Function = function() if ChinaHat.Enabled then rebuildAll() end end
	})
	Height = ChinaHat:CreateSlider({
		Name = 'Height', Min = 0.2, Max = 5, Default = 1.1, Decimal = 10,
		Function = function() if ChinaHat.Enabled then rebuildAll() end end
	})
	Offset = ChinaHat:CreateSlider({
		Name = 'Offset', Min = -1, Max = 3, Default = 0, Decimal = 10,
		Function = function() if ChinaHat.Enabled then rebuildAll() end end
	})
	Layers = ChinaHat:CreateSlider({
		Name = 'Smoothness', Min = 4, Max = 40, Default = 16,
		Tooltip = 'Number of stacked layers (higher = smoother cone)',
		Function = function() if ChinaHat.Enabled then rebuildAll() end end
	})
	Transparency = ChinaHat:CreateSlider({
		Name = 'Transparency', Min = 0, Max = 1, Default = 0.35, Decimal = 20,
		Function = function(v)
			for _, hat in Hats do for _, a in hat do a.Transparency = v end end
		end
	})
	Color = ChinaHat:CreateColorSlider({
		Name = 'Color',
		Function = function(h, s, v)
			if Rainbow and Rainbow.Enabled then return end
			for _, hat in Hats do for _, a in hat do a.Color3 = Color3.fromHSV(h, s, v) end end
		end
	})
	Rainbow = ChinaHat:CreateToggle({
		Name = 'Rainbow',
		Function = function(callback)
			if RainbowSpeed then RainbowSpeed.Object.Visible = callback end
			if not callback then
				for _, hat in Hats do for _, a in hat do a.Color3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value) end end
			end
		end
	})
	RainbowSpeed = ChinaHat:CreateSlider({
		Name = 'Rainbow speed', Min = 1, Max = 30, Default = 8, Darker = true, Visible = false
	})
	Self = ChinaHat:CreateToggle({
		Name = 'Self', Default = true,
		Function = function() if ChinaHat.Enabled then rebuildAll() end end
	})
	Others = ChinaHat:CreateToggle({
		Name = 'Others',
		Function = function() if ChinaHat.Enabled then rebuildAll() end end
	})
	HideFirstPerson = ChinaHat:CreateToggle({
		Name = 'Hide in first person', Default = true
	})
end)
