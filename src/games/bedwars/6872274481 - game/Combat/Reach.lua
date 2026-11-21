local Value
local FOV
local ShowHits

-- REQUIEM: Reach used to only change CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE.
-- If that lookup fails after a game update (or the game caches the value) it silently did
-- nothing, and the game never even sends a hit for targets past ~14 studs. Now Reach also
-- picks the enemy you're aiming at when you swing and sends the hit itself.
local VANILLA_RANGE = 14.4
local AttackRemote
local lastSwingSeen, lastReachHit = nil, 0

local function setConstant(on)
	pcall(function()
		bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = on and Value.Value + 2 or VANILLA_RANGE
	end)
end

local function getRemote()
	if AttackRemote then return AttackRemote end
	pcall(function()
		AttackRemote = bedwars.Client:Get(remotes.AttackEntity).instance
	end)
	return AttackRemote
end

local function findAimTarget()
	local cam = gameCamera.CFrame
	local selfpos = entitylib.character.RootPart.Position
	local maxDist = Value.Value + 2
	local cone = math.rad(FOV.Value) / 2
	local best, bestAngle, bestDist
	for _, ent in entitylib.List do
		if ent.Targetable and ent.RootPart and ent.RootPart.Parent and ent.Character and (ent.Health or 0) > 0 then
			local dist = (ent.RootPart.Position - selfpos).Magnitude
			if dist <= maxDist then
				local dir = ent.RootPart.Position - cam.Position
				local angle = math.acos(math.clamp(cam.LookVector:Dot(dir.Unit), -1, 1))
				if angle <= cone and (not bestAngle or angle < bestAngle) then
					best, bestAngle, bestDist = ent, angle, dist
				end
			end
		end
	end
	return best, bestDist
end

local function reachHit()
	if tick() - lastReachHit < 0.08 then return end
	if not entitylib.isAlive or not entitylib.character.RootPart then return end
	local hand = store.hand
	if not hand or hand.toolType ~= 'sword' or not hand.tool then return end

	local target, dist = findAimTarget()
	-- in normal range the game's own swing already hits; only step in past it
	if not target or dist <= VANILLA_RANGE then return end

	local remote = getRemote()
	local root = target.Character.PrimaryPart or target.RootPart
	if not remote or not root then return end
	lastReachHit = tick()

	local selfpos = entitylib.character.RootPart.Position
	local dir = CFrame.lookAt(selfpos, root.Position).LookVector
	local pos = selfpos + dir * math.max(dist - 14.399, 0)
	pcall(function()
		bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
	end)
	store.attackReach = (dist * 100) // 1 / 100
	store.attackReachUpdate = tick() + 1
	targetinfo.Targets[target] = os.clock() + 1

	remote:FireServer({
		weapon = hand.tool,
		chargedAttack = {chargeRatio = 0},
		entityInstance = target.Character,
		validate = {
			raycast = {
				cameraPosition = {value = pos},
				cursorDirection = {value = dir}
			},
			targetPosition = {value = root.Position},
			selfPosition = {value = pos}
		}
	})

	if ShowHits.Enabled then
		notif('Reach', string.format('Hit %s at %.1f studs', target.Player and target.Player.DisplayName or 'target', dist), 1.5)
	end
end

Reach = vape.Categories.Combat:CreateModule({
	Name = 'Reach',
	Function = function(callback)
		setConstant(callback)
		if callback then
			task.spawn(getRemote)
			pcall(function() lastSwingSeen = bedwars.SwordController.lastSwing end)

			-- PC click / mobile tap while holding a sword
			Reach:Clean(inputService.InputBegan:Connect(function(input, processed)
				if processed then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					task.spawn(reachHit)
				end
			end))

			-- also catch swings the game registers some other way (autoclicker, mobile button)
			Reach:Clean(runService.Heartbeat:Connect(function()
				local ok, swing = pcall(function() return bedwars.SwordController.lastSwing end)
				if ok and swing ~= nil and swing ~= lastSwingSeen then
					lastSwingSeen = swing
					reachHit()
				end
			end))
		end
	end,
	Tooltip = 'Extends attack reach. Swing at an enemy past normal range to hit them.'
})
Value = Reach:CreateSlider({
	Name = 'Range',
	Min = 0,
	Max = 18,
	Default = 18,
	Function = function()
		if Reach.Enabled then setConstant(true) end
	end,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})
FOV = Reach:CreateSlider({
	Name = 'Aim angle',
	Min = 10,
	Max = 180,
	Default = 70,
	Tooltip = 'How close to your crosshair the enemy has to be',
	Suffix = function() return '°' end
})
ShowHits = Reach:CreateToggle({
	Name = 'Show reach hits',
	Tooltip = 'Pops a notification each time Reach lands a hit past normal range (for testing)'
})
