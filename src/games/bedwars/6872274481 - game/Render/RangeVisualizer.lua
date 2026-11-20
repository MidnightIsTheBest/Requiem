run(function()
	local RangeVis
	local Radius
	local Color
	local Transparency
	local Rainbow
	local RainbowSpeed
	local ring

	RangeVis = vape.Categories.Render:CreateModule({
		Name = 'Range Visualizer',
		Tooltip = 'Shows a circle around you indicating your reach distance',
		Function = function(callback)
			if callback then
				if vape.ThreadFix then setthreadidentity(8) end

				local part = Instance.new('Part')
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.Material = Enum.Material.Neon
				part.Shape = Enum.PartType.Cylinder
				part.TopSurface = Enum.SurfaceType.Smooth
				part.BottomSurface = Enum.SurfaceType.Smooth
				part.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
				part.Transparency = Transparency.Value
				part.Parent = vape.holder
				ring = part

				local inner = Instance.new('Part')
				inner.Anchored = true
				inner.CanCollide = false
				inner.CanQuery = false
				inner.CanTouch = false
				inner.Material = Enum.Material.Neon
				inner.Shape = Enum.PartType.Cylinder
				inner.TopSurface = Enum.SurfaceType.Smooth
				inner.BottomSurface = Enum.SurfaceType.Smooth
				inner.Color = Color3.new(0, 0, 0)
				inner.Transparency = 0
				inner.Parent = vape.holder
				ring._inner = inner

				local function updateSize()
					local r = Radius.Value
					local thick = 0.15
					part.Size = Vector3.new(0.05, r * 2, r * 2)
					inner.Size = Vector3.new(0.06, (r - thick) * 2, (r - thick) * 2)
				end
				updateSize()

				RangeVis:Clean(runService.RenderStepped:Connect(function()
					if not entitylib.isAlive or not ring then
						part.Parent = nil
						inner.Parent = nil
						return
					end
					part.Parent = vape.holder
					inner.Parent = vape.holder

					local root = entitylib.character.RootPart
					if not root then return end
					local y = root.Position.Y - entitylib.character.HipHeight - 1
					local pos = Vector3.new(root.Position.X, y, root.Position.Z)

					part.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
					inner.CFrame = part.CFrame

					if Rainbow.Enabled then
						part.Color = Color3.fromHSV((tick() * RainbowSpeed.Value * 0.1) % 1, 0.9, 1)
					end
				end))

				RangeVis:Clean(part)
				RangeVis:Clean(inner)
			else
				ring = nil
			end
		end
	})

	Radius = RangeVis:CreateSlider({
		Name = 'Radius', Min = 1, Max = 25, Default = 14, Decimal = 10,
		Suffix = function(v) return v == 1 and 'stud' or 'studs' end,
		Function = function(v)
			if ring then
				local thick = 0.15
				ring.Size = Vector3.new(0.05, v * 2, v * 2)
				ring._inner.Size = Vector3.new(0.06, (v - thick) * 2, (v - thick) * 2)
			end
		end
	})
	Transparency = RangeVis:CreateSlider({
		Name = 'Transparency', Min = 0, Max = 0.95, Default = 0.3, Decimal = 20,
		Function = function(v)
			if ring then ring.Transparency = v end
		end
	})
	Color = RangeVis:CreateColorSlider({
		Name = 'Color',
		Function = function(h, s, v)
			if Rainbow and Rainbow.Enabled then return end
			if ring then ring.Color = Color3.fromHSV(h, s, v) end
		end
	})
	Rainbow = RangeVis:CreateToggle({
		Name = 'Rainbow',
		Function = function(cb)
			if RainbowSpeed then RainbowSpeed.Object.Visible = cb end
			if not cb and ring then
				ring.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			end
		end
	})
	RainbowSpeed = RangeVis:CreateSlider({
		Name = 'Rainbow speed', Min = 1, Max = 30, Default = 8, Darker = true, Visible = false
	})
end)
