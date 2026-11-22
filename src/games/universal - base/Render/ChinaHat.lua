run(function()
	-- REQUIEM: China Hat rebuilt after studying LiquidBounce++ AsianHat and FDPClient Hat:
	-- a real cone (triangle fan, 2:1 radius:height), per-segment palette colours that scroll
	-- around the rim, a bright rim outline, optional spin / bob / head tilt.
	local ChinaHat
	local ColorMode
	local Color
	local ColorSpace
	local ColorSpeed
	local Radius
	local Height
	local Offset
	local Segments
	local Transparency
	local Outline
	local OutlineTransparency
	local Spin
	local Bob
	local Tilt
	local Self
	local Others
	local FirstPerson
	local Hats = {}

	local function newPart(class)
		local p = Instance.new(class)
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		return p
	end

	-- palettes, same maths as the Minecraft clients (time based, offset per segment)
	local function palette(index)
		local t = tick() * ColorSpeed.Value
		local mode = ColorMode.Value
		if mode == 'Rainbow' then
			return Color3.fromHSV((t * 0.25 + index * 0.01) % 1, 0.7, 1)
		elseif mode == 'Astolfo' then
			-- LiquidBounce skyRainbow: hue sweeps cyan -> blue -> purple -> pink and back
			local h = ((t * 1000 + index * 109) / 5 % 360) / 360
			if h < 0.5 then h = 1 - h end
			return Color3.fromHSV(h, 0.5, 1)
		elseif mode == 'Fade' then
			local v = 0.55 + 0.45 * math.abs(math.sin(t * math.pi / 2 + index * 0.03))
			return Color3.fromHSV(Color.Hue, Color.Sat, Color.Value * v)
		end
		return Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
	end

	-- one triangle out of two WedgeParts (local space). Returns {part, cframe} pairs.
	local function triangle(a, b, c, out)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local h = math.abs(ab:Dot(up))
		local w1, w2 = newPart('WedgePart'), newPart('WedgePart')
		w1.Size = Vector3.new(0.02, h, math.abs(ab:Dot(back)))
		w2.Size = Vector3.new(0.02, h, math.abs(ac:Dot(back)))
		table.insert(out, {w1, CFrame.fromMatrix((a + b) / 2, right, up, back)})
		table.insert(out, {w2, CFrame.fromMatrix((a + c) / 2, -right, up, -back)})
	end

	local function destroyHat(ent)
		local hat = Hats[ent]
		if hat then
			Hats[ent] = nil
			hat.folder:Destroy()
		end
	end

	local function buildHat(ent)
		destroyHat(ent)
		if not ChinaHat.Enabled or not ent or not ent.Head or not ent.Head.Parent then return end
		local isSelf = ent.Player == lplr
		if isSelf and not Self.Enabled then return end
		if (not isSelf) and not Others.Enabled then return end
		if vape.ThreadFix then setthreadidentity(8) end

		local n = math.floor(Segments.Value)
		local r, h = Radius.Value, Height.Value
		local tip = Vector3.new(0, h, 0)
		local rim = {}
		for i = 0, n - 1 do
			local a = (i / n) * math.pi * 2
			rim[i] = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		end

		local hat = {folder = Instance.new('Folder'), parts = {}, locals = {}, segIndex = {}, outline = {}}
		hat.folder.Name = 'RequiemChinaHat'
		for i = 0, n - 1 do
			local pairsOut = {}
			triangle(tip, rim[i], rim[(i + 1) % n], pairsOut)
			for _, pc in pairsOut do
				local part = pc[1]
				part.Transparency = Transparency.Value
				part.Parent = hat.folder
				table.insert(hat.parts, part)
				table.insert(hat.locals, pc[2])
				table.insert(hat.segIndex, i)
			end
			if Outline.Enabled then
				local p0, p1 = rim[i], rim[(i + 1) % n]
				local line = newPart('Part')
				line.Material = Enum.Material.Neon
				line.Size = Vector3.new(0.05, 0.05, (p1 - p0).Magnitude + 0.04)
				line.Transparency = OutlineTransparency.Value
				line.Parent = hat.folder
				table.insert(hat.parts, line)
				table.insert(hat.locals, CFrame.lookAt((p0 + p1) / 2, p1))
				table.insert(hat.segIndex, i)
				hat.outline[line] = true
			end
		end
		hat.folder.Parent = gameCamera
		hat.cframes = table.create(#hat.parts)
		Hats[ent] = hat
	end

	local function rebuildAll()
		for ent in Hats do destroyHat(ent) end
		if not ChinaHat.Enabled then return end
		if entitylib.isAlive then buildHat(entitylib.character) end
		for _, ent in entitylib.List do
			if ent ~= entitylib.character then buildHat(ent) end
		end
	end

	ChinaHat = vape.Categories.Render:CreateModule({
		Name = 'China Hat',
		Tooltip = 'Minecraft-client style cone hat with animated colours',
		Function = function(callback)
			if callback then
				ChinaHat:Clean(entitylib.Events.LocalAdded:Connect(buildHat))
				ChinaHat:Clean(entitylib.Events.LocalRemoved:Connect(function(ent) destroyHat(ent or entitylib.character) end))
				ChinaHat:Clean(entitylib.Events.EntityAdded:Connect(buildHat))
				ChinaHat:Clean(entitylib.Events.EntityRemoved:Connect(destroyHat))
				rebuildAll()

				local nextColor, spinAngle = 0, 0
				ChinaHat:Clean(runService.RenderStepped:Connect(function(dt)
					spinAngle = (spinAngle + math.rad(Spin.Value) * dt) % (math.pi * 2)
					local bob = Bob.Enabled and math.sin(tick() * 2) * 0.06 or 0
					local doColor = tick() >= nextColor
					if doColor then nextColor = tick() + 1 / 30 end
					local camPos = gameCamera.CFrame.Position
					local space = ColorSpace.Value

					local allParts, allCFrames = {}, {}
					for ent, hat in Hats do
						local head = ent.Head
						if not (head and head.Parent) then
							destroyHat(ent)
							continue
						end

						local hidden = ent.Player == lplr and not FirstPerson.Enabled and (camPos - head.Position).Magnitude < 1.5
						if hidden ~= hat.hidden then
							hat.hidden = hidden
							hat.folder.Parent = not hidden and gameCamera or nil
						end
						if hidden then continue end

						local base
						if Tilt.Enabled then
							base = head.CFrame
						else
							local look = head.CFrame.LookVector
							base = CFrame.new(head.Position) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
						end
						local hatCF = base * CFrame.new(0, head.Size.Y / 2 + Offset.Value + bob, 0) * CFrame.Angles(0, spinAngle, 0)

						for i, part in hat.parts do
							table.insert(allParts, part)
							table.insert(allCFrames, hatCF * hat.locals[i])
							if doColor then
								local c = palette(hat.segIndex[i] * space)
								if hat.outline[part] then
									part.Color = c:Lerp(Color3.new(1, 1, 1), 0.25)
								else
									part.Color = c
								end
							end
						end
					end

					if #allParts > 0 then
						local ok = pcall(function()
							workspace:BulkMoveTo(allParts, allCFrames, Enum.BulkMoveMode.FireCFrameChanged)
						end)
						if not ok then
							for i, part in allParts do part.CFrame = allCFrames[i] end
						end
					end
				end))
			else
				for ent in Hats do destroyHat(ent) end
			end
		end
	})

	local function rebuild()
		if ChinaHat and ChinaHat.Enabled then rebuildAll() end
	end

	ColorMode = ChinaHat:CreateDropdown({
		Name = 'Colour mode',
		List = {'Astolfo', 'Rainbow', 'Fade', 'Custom'},
		Function = function(v)
			if ColorSpace then ColorSpace.Object.Visible = v ~= 'Custom' end
		end
	})
	Color = ChinaHat:CreateColorSlider({Name = 'Colour', DefaultHue = 0.55})
	ColorSpace = ChinaHat:CreateSlider({
		Name = 'Colour spread', Min = 0, Max = 30, Default = 8, Darker = true,
		Tooltip = 'How far the colours are spread around the rim (0 = whole hat one colour)'
	})
	ColorSpeed = ChinaHat:CreateSlider({Name = 'Colour speed', Min = 0.1, Max = 3, Default = 1, Decimal = 10, Darker = true})
	Radius = ChinaHat:CreateSlider({Name = 'Radius', Min = 0.5, Max = 4, Default = 1.6, Decimal = 10, Function = rebuild})
	Height = ChinaHat:CreateSlider({Name = 'Height', Min = 0.1, Max = 3, Default = 0.8, Decimal = 10, Function = rebuild})
	Offset = ChinaHat:CreateSlider({Name = 'Offset', Min = -1, Max = 3, Default = 0.25, Decimal = 20})
	Segments = ChinaHat:CreateSlider({
		Name = 'Smoothness', Min = 8, Max = 64, Default = 32,
		Tooltip = 'Number of slices around the cone (higher = rounder)',
		Function = rebuild
	})
	Transparency = ChinaHat:CreateSlider({
		Name = 'Transparency', Min = 0, Max = 0.95, Default = 0.45, Decimal = 20,
		Function = function(v)
			for _, hat in Hats do
				for _, part in hat.parts do
					if not hat.outline[part] then part.Transparency = v end
				end
			end
		end
	})
	Outline = ChinaHat:CreateToggle({
		Name = 'Outline', Default = true,
		Function = function(cb)
			if OutlineTransparency then OutlineTransparency.Object.Visible = cb end
			rebuild()
		end
	})
	OutlineTransparency = ChinaHat:CreateSlider({
		Name = 'Outline transparency', Min = 0, Max = 0.95, Default = 0.1, Decimal = 20, Darker = true,
		Function = function(v)
			for _, hat in Hats do
				for part in hat.outline do part.Transparency = v end
			end
		end
	})
	Spin = ChinaHat:CreateSlider({
		Name = 'Spin speed', Min = 0, Max = 360, Default = 45,
		Suffix = function() return '°/s' end
	})
	Bob = ChinaHat:CreateToggle({Name = 'Bob'})
	Tilt = ChinaHat:CreateToggle({
		Name = 'Tilt with head',
		Tooltip = 'Hat follows where the head is looking instead of staying flat'
	})
	Self = ChinaHat:CreateToggle({Name = 'Self', Default = true, Function = rebuild})
	Others = ChinaHat:CreateToggle({Name = 'Others', Function = rebuild})
	FirstPerson = ChinaHat:CreateToggle({Name = 'Show in first person'})
end)
