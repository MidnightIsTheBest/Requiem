run(function()
	local TexturePack
	local TintByTier
	local Others
	local SpriteSize
	local RotX, RotY, RotZ
	local OffX, OffY, OffZ
	local Glow

	local TEXTURE_URL = 'https://files.catbox.moe/nyk4g2.png'
	local TEXTURE_PATH = 'requiem/assets/swordtexture.png'

	-- the source texture is white, so each tier just tints it
	local tierColors = {
		wood = Color3.fromRGB(160, 112, 60),
		stone = Color3.fromRGB(140, 140, 145),
		iron = Color3.fromRGB(235, 235, 240),
		diamond = Color3.fromRGB(85, 235, 225),
		emerald = Color3.fromRGB(60, 225, 110),
	}

	local textureId
	local applied = {} -- [item instance] = {sprite = Part, hidden = {[part] = oldTransparency}}

	local function loadTexture()
		if textureId then return textureId end
		local ok, err = pcall(function()
			if not isfolder('requiem/assets') then makefolder('requiem/assets') end
			if not isfile(TEXTURE_PATH) then
				writefile(TEXTURE_PATH, game:HttpGet(TEXTURE_URL, true))
			end
			textureId = getcustomasset(TEXTURE_PATH)
		end)
		if not ok then
			notif('Texture Pack', 'Could not load texture: '..tostring(err), 8, 'alert')
		end
		return textureId
	end

	local function tierOf(name)
		local tier = name:match('^(%a+)_sword$')
		return tier and tierColors[tier] and tier
	end

	local function spriteCFrame()
		return CFrame.new(OffX.Value, OffY.Value, OffZ.Value)
			* CFrame.Angles(math.rad(RotX.Value), math.rad(RotY.Value), math.rad(RotZ.Value))
	end

	local function restore(item)
		local data = applied[item]
		if not data then return end
		applied[item] = nil
		if data.sprite then data.sprite:Destroy() end
		for part, old in data.hidden do
			if part.Parent then part.Transparency = old end
		end
	end

	local function apply(item, tier)
		local handle = item:FindFirstChild('Handle')
		if not handle or not handle:IsA('BasePart') then return end
		local tex = loadTexture()
		if not tex then return end

		local data = {hidden = {}}
		applied[item] = data

		-- hide the original model (local only, other players still see the normal sword)
		for _, v in item:GetDescendants() do
			if v:IsA('BasePart') then
				data.hidden[v] = v.Transparency
				v.Transparency = 1
			end
		end

		local sprite = Instance.new('Part')
		sprite.Name = 'RequiemSwordSprite'
		sprite.Size = Vector3.new(SpriteSize.Value, SpriteSize.Value, 0.02)
		sprite.Transparency = 1
		sprite.CanCollide = false
		sprite.CanQuery = false
		sprite.CanTouch = false
		sprite.Massless = true
		sprite.CastShadow = false
		sprite.CFrame = handle.CFrame * spriteCFrame()

		local color = TintByTier.Enabled and tierColors[tier] or Color3.new(1, 1, 1)
		for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
			local d = Instance.new('Decal')
			d.Face = face
			d.Texture = tex
			d.Color3 = color
			d.Parent = sprite
		end

		if Glow.Enabled then
			local light = Instance.new('PointLight')
			light.Color = color
			light.Range = 4
			light.Brightness = 0.6
			light.Parent = sprite
		end

		local weld = Instance.new('Weld')
		weld.Part0 = handle
		weld.Part1 = sprite
		weld.C0 = spriteCFrame()
		weld.Parent = sprite
		sprite.Parent = item
		data.sprite = sprite
		data.weld = weld
	end

	local function scanContainer(container, seen)
		if not container then return end
		for _, item in container:GetChildren() do
			local tier = tierOf(item.Name)
			if tier then
				seen[item] = true
				if not applied[item] then apply(item, tier) end
			end
		end
	end

	local function refreshAll()
		for item in applied do restore(item) end
	end

	TexturePack = vape.Categories.Render:CreateModule({
		Name = 'Texture Pack',
		Tooltip = 'Replaces wood / stone / iron / diamond / emerald swords with a 2D texture',
		Function = function(callback)
			if callback then
				task.spawn(loadTexture)
				local nextScan = 0
				TexturePack:Clean(runService.Heartbeat:Connect(function()
					if tick() < nextScan then return end
					nextScan = tick() + 0.2
					local seen = {}
					scanContainer(lplr.Character, seen)
					scanContainer(gameCamera:FindFirstChild('Viewmodel'), seen)
					if Others.Enabled then
						for _, plr in playersService:GetPlayers() do
							if plr ~= lplr then scanContainer(plr.Character, seen) end
						end
					end
					-- drop sprites for swords that were unequipped / destroyed
					for item in applied do
						if not seen[item] or not item.Parent then restore(item) end
					end
				end))
				TexturePack:Clean(refreshAll)
			end
		end
	})

	local function rebuild()
		if TexturePack and TexturePack.Enabled then refreshAll() end
	end
	local function moveSprites()
		for _, data in applied do
			if data.weld then data.weld.C0 = spriteCFrame() end
		end
	end

	TintByTier = TexturePack:CreateToggle({
		Name = 'Tint by tier', Default = true,
		Tooltip = 'Colours the white texture: wood brown, stone grey, iron white, diamond aqua, emerald green',
		Function = rebuild
	})
	Glow = TexturePack:CreateToggle({Name = 'Glow', Function = rebuild})
	Others = TexturePack:CreateToggle({
		Name = 'Other players too',
		Tooltip = 'Also show the texture on other players\' swords (only you see it)',
		Function = rebuild
	})
	SpriteSize = TexturePack:CreateSlider({
		Name = 'Size', Min = 0.5, Max = 6, Default = 2.5, Decimal = 10,
		Function = function(v)
			for _, data in applied do
				if data.sprite then data.sprite.Size = Vector3.new(v, v, 0.02) end
			end
		end
	})
	RotX = TexturePack:CreateSlider({Name = 'Rotation X', Min = -180, Max = 180, Default = 0, Darker = true, Function = moveSprites})
	RotY = TexturePack:CreateSlider({Name = 'Rotation Y', Min = -180, Max = 180, Default = 90, Darker = true, Function = moveSprites})
	RotZ = TexturePack:CreateSlider({Name = 'Rotation Z', Min = -180, Max = 180, Default = 45, Darker = true, Function = moveSprites})
	OffX = TexturePack:CreateSlider({Name = 'Offset X', Min = -3, Max = 3, Default = 0, Decimal = 20, Darker = true, Function = moveSprites})
	OffY = TexturePack:CreateSlider({Name = 'Offset Y', Min = -3, Max = 3, Default = 0.8, Decimal = 20, Darker = true, Function = moveSprites})
	OffZ = TexturePack:CreateSlider({Name = 'Offset Z', Min = -3, Max = 3, Default = 0, Decimal = 20, Darker = true, Function = moveSprites})
end)
