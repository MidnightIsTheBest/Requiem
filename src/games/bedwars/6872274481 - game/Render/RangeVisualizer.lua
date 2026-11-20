run(function()
	local RangeVis
	local Mode
	local Radius
	local Color
	local InRangeColor
	local Transparency
	local Rainbow
	local RainbowSpeed
	local Segments = 64
	local parts = {}
	local currentRadius = 0

	local function getSwordReach()
		local reach = 14.4
		pcall(function()
			reach = bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE or reach
		end)
		pcall(function()
			local tool = store.hand and store.hand.tool
			if tool then
				local meta = bedwars.ItemMeta[tool.Name]
				if meta and meta.sword and meta.sword.attackRange then
					reach = math.max(reach, meta.sword.attackRange)
				end
			end
		end)
		return reach
	end

	local function getRadius()
		if Mode and Mode.Value == 'Custom' then
			return Radius and Radius.Value or 14
		end
		return getSwordReach()
	end

	local function clearParts()
		for _, p in parts do p:Destroy() end
		table.clear(parts)
	end

	local function buildParts()
		clearParts()
		for i = 1, Segments do
			local p = Instance.new('Part')
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.Transparency = Transparency and Transparency.Value or 0.3
			p.Parent = gameCamera
			parts[i] = p
		end
	end

	local function enemyInRange(origin, r)
		for _, ent in entitylib.List do
			if ent.Targetable and ent.RootPart and ent.Health and ent.Health > 0 then
				local d = ent.RootPart.Position - origin
				if Vector3.new(d.X, 0, d.Z).Magnitude <= r then
					return true
				end
			end
		end
		return false
	end

	RangeVis = vape.Categories.Render:CreateModule({
		Name = 'Range Visualizer',
		Tooltip = 'Draws a ring at your feet showing exactly how far your sword can hit',
		Function = function(callback)
			if callback then
				if vape.ThreadFix then setthreadidentity(8) end
				buildParts()

				RangeVis:Clean(runService.RenderStepped:Connect(function()
					local alive = entitylib.isAlive and entitylib.character.RootPart
					for _, p in parts do
						p.Parent = alive and gameCamera or nil
					end
					if not alive then return end

					local root = entitylib.character.RootPart
					local r = getRadius()
					local y = root.Position.Y - (entitylib.character.HipHeight or 3) + 0.08
					local center = Vector3.new(root.Position.X, y, root.Position.Z)

					local col
					if InRangeColor.Enabled and enemyInRange(root.Position, r) then
						col = Color3.fromRGB(60, 255, 90)
					elseif Rainbow.Enabled then
						col = Color3.fromHSV((tick() * RainbowSpeed.Value * 0.1) % 1, 0.9, 1)
					else
						col = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
					end

					local segLen = (2 * math.pi * r) / Segments + 0.05
					local resize = r ~= currentRadius
					currentRadius = r
					for i, p in parts do
						local a = (i / Segments) * math.pi * 2
						local pos = center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
						p.CFrame = CFrame.new(pos) * CFrame.Angles(0, -a, 0)
						if resize then
							p.Size = Vector3.new(0.18, 0.05, segLen)
						end
						p.Color = col
					end
				end))

				RangeVis:Clean(function()
					clearParts()
					currentRadius = 0
				end)
			end
		end
	})

	Mode = RangeVis:CreateDropdown({
		Name = 'Mode',
		List = {'Sword', 'Custom'},
		Tooltip = 'Sword = matches your real hit range (includes Reach module)',
		Function = function(v)
			if Radius then Radius.Object.Visible = v == 'Custom' end
			currentRadius = 0
		end
	})
	Radius = RangeVis:CreateSlider({
		Name = 'Radius', Min = 1, Max = 30, Default = 14.4, Decimal = 10, Darker = true, Visible = false,
		Suffix = function(v) return v == 1 and 'stud' or 'studs' end,
		Function = function() currentRadius = 0 end
	})
	InRangeColor = RangeVis:CreateToggle({
		Name = 'Green when in range',
		Default = true,
		Tooltip = 'Ring turns green when an enemy is close enough to hit'
	})
	Transparency = RangeVis:CreateSlider({
		Name = 'Transparency', Min = 0, Max = 0.95, Default = 0.3, Decimal = 20,
		Function = function(v)
			for _, p in parts do p.Transparency = v end
		end
	})
	Color = RangeVis:CreateColorSlider({
		Name = 'Color'
	})
	Rainbow = RangeVis:CreateToggle({
		Name = 'Rainbow',
		Function = function(cb)
			if RainbowSpeed then RainbowSpeed.Object.Visible = cb end
		end
	})
	RainbowSpeed = RangeVis:CreateSlider({
		Name = 'Rainbow speed', Min = 1, Max = 30, Default = 8, Darker = true, Visible = false
	})
end)
