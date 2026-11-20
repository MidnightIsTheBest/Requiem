run(function()
	local HitFX
	local Mode
	local CustomText
	local CustomImage
	local FXScale
	local FXDuration
	local FXColor
	local AutoToxic
	local ToxicOnKill
	local ToxicMessages
	local ToxicCloned = {}

	local defaults = {
		'ez', 'gg ez', 'LOL', 'too easy', 'get good',
		'sit', 'L bozo', 'free', 'clapped', '🤡'
	}

	local function sendChat(message)
		if not message then return end
		if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			pcall(function()
				if textChatService:CanUserChatAsync(lplr.UserId) then
					textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(message)
				end
			end)
		else
			pcall(function()
				replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, 'All')
			end)
		end
	end

	local function getToxicMessage(targetName)
		local pool = ToxicMessages and #ToxicMessages.ListEnabled > 0 and ToxicMessages.ListEnabled or defaults
		if #ToxicCloned <= 0 then
			ToxicCloned = table.clone(pool)
		end
		local idx = Random.new():NextInteger(1, #ToxicCloned)
		local msg = ToxicCloned[idx]
		table.remove(ToxicCloned, idx)
		return msg and msg:gsub('<name>', targetName or '') or 'ez'
	end

	local function spawnFX(position)
		if not HitFX.Enabled then return end
		if vape.ThreadFix then setthreadidentity(8) end

		local bb = Instance.new('BillboardGui')
		bb.Adornee = nil
		bb.Size = UDim2.fromOffset(120, 60)
		bb.StudsOffset = Vector3.new(
			(math.random() - 0.5) * 2,
			math.random() * 2 + 1,
			(math.random() - 0.5) * 2
		)
		bb.AlwaysOnTop = true
		bb.Parent = vape.holder

		local anchor = Instance.new('Part')
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.Position = position
		anchor.Parent = vape.holder
		bb.Adornee = anchor

		local uiScale = Instance.new('UIScale')
		uiScale.Scale = FXScale.Value
		uiScale.Parent = bb

		if Mode.Value == 'Text' then
			local texts = CustomText and #CustomText.ListEnabled > 0 and CustomText.ListEnabled or {'💥', '✨', 'HIT', '🔥'}
			local txt = texts[math.random(1, #texts)]
			local label = Instance.new('TextLabel')
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Text = txt
			label.TextColor3 = Color3.fromHSV(FXColor.Hue, FXColor.Sat, FXColor.Value)
			label.TextScaled = true
			label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
			label.TextStrokeTransparency = 0.5
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.Parent = bb
		elseif Mode.Value == 'Image' then
			local images = CustomImage and #CustomImage.ListEnabled > 0 and CustomImage.ListEnabled or {'rbxassetid://6031075938'}
			local img = images[math.random(1, #images)]
			local label = Instance.new('ImageLabel')
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Image = img
			label.ImageColor3 = Color3.fromHSV(FXColor.Hue, FXColor.Sat, FXColor.Value)
			label.ScaleType = Enum.ScaleType.Fit
			label.Parent = bb
		else
			local label = Instance.new('TextLabel')
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Text = '💥'
			label.TextScaled = true
			label.Parent = bb
		end

		local dur = FXDuration.Value
		task.spawn(function()
			local start = tick()
			while tick() - start < dur do
				local alpha = (tick() - start) / dur
				bb.StudsOffset = bb.StudsOffset + Vector3.new(0, 0.03, 0)
				uiScale.Scale = FXScale.Value * (1 + alpha * 0.3)
				for _, child in bb:GetChildren() do
					if child:IsA('TextLabel') then
						child.TextTransparency = alpha
						child.TextStrokeTransparency = 0.5 + alpha * 0.5
					elseif child:IsA('ImageLabel') then
						child.ImageTransparency = alpha
					end
				end
				task.wait()
			end
			bb:Destroy()
			anchor:Destroy()
		end)
	end

	HitFX = vape.Categories.Render:CreateModule({
		Name = 'Hit FX',
		Tooltip = 'Visual effects on hit + auto toxic chat on kills',
		Function = function(callback)
			if callback then
				HitFX:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(data)
					if not data then return end
					local attacker = data.fromEntity and playersService:GetPlayerFromCharacter(data.fromEntity)
					if attacker ~= lplr then return end

					local target = data.entityInstance
					if target and target.PrimaryPart then
						spawnFX(target.PrimaryPart.Position)
					end
				end))

				HitFX:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if not deathTable then return end
					local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
					local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
					if killer ~= lplr or not killed then return end

					if AutoToxic.Enabled and ToxicOnKill.Enabled then
						local name = killed.DisplayName or killed.Name
						task.delay(0.3 + math.random() * 0.5, function()
							sendChat(getToxicMessage(name))
						end)
					end
				end))
			end
		end
	})

	Mode = HitFX:CreateDropdown({
		Name = 'FX Mode',
		List = {'Text', 'Image', 'Emoji'},
		Function = function(v)
			if CustomText then CustomText.Object.Visible = v == 'Text' end
			if CustomImage then CustomImage.Object.Visible = v == 'Image' end
		end
	})
	CustomText = HitFX:CreateTextList({
		Name = 'Custom texts',
		Darker = true,
		Tooltip = 'Add custom hit texts (leave empty for defaults: 💥 ✨ HIT 🔥)',
	})
	CustomImage = HitFX:CreateTextList({
		Name = 'Image IDs',
		Darker = true,
		Visible = false,
		Tooltip = 'Roblox asset IDs for hit images (rbxassetid://123456)',
	})
	FXScale = HitFX:CreateSlider({
		Name = 'Size', Min = 0.3, Max = 3, Default = 1, Decimal = 10
	})
	FXDuration = HitFX:CreateSlider({
		Name = 'Duration', Min = 0.2, Max = 3, Default = 0.8, Decimal = 10,
		Suffix = function(v) return 's' end
	})
	FXColor = HitFX:CreateColorSlider({
		Name = 'FX color',
		Tooltip = 'Color tint for text/image FX'
	})

	-- AutoToxic section
	AutoToxic = HitFX:CreateToggle({
		Name = 'Auto Toxic',
		Tooltip = 'Sends a message in chat when you get a kill',
		Function = function(cb)
			if ToxicOnKill then ToxicOnKill.Object.Visible = cb end
			if ToxicMessages then ToxicMessages.Object.Visible = cb end
		end
	})
	ToxicOnKill = HitFX:CreateToggle({
		Name = 'On kill', Default = true, Darker = true, Visible = false,
		Tooltip = 'Send toxic message when you kill someone'
	})
	ToxicMessages = HitFX:CreateTextList({
		Name = 'Messages',
		Darker = true,
		Visible = false,
		Tooltip = 'Custom messages (use <name> for victim name). Leave empty for defaults.',
		Function = function()
			table.clear(ToxicCloned)
		end
	})
end)
