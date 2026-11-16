-- Requiem: Jade Fly
-- Watches for the game's own  useAbility:FireServer('jade_hammer_jump')  call.
-- When it fires, starts a short fly (its own, not the Fly module) that moves with the
-- exact same movement code as the Speed module, at 28 studs by default.
run(function()
	local JadeFly
	local Value
	local VerticalValue
	local Duration
	local WallCheck
	local StopOnLand
	local TP

	local ABILITY = 'jade_hammer_jump'
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true

	local active, startTime, endTime, connection = false, 0, 0, nil
	local tpTick, tpToggle, oldy = tick(), true, nil -- TP Down state (same idea as the Fly module)

	local function stop()
		if oldy and entitylib.isAlive then
			local root = entitylib.character.RootPart
			root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, oldy, root.Position.Z), root.CFrame.LookVector)
		end
		oldy, tpToggle = nil, true
		if connection then
			connection:Disconnect()
			connection = nil
		end
		active = false
		store.JadeFlyActive = nil
		frictionTable.JadeFly = nil
		updateVelocity()
		pcall(function()
			bedwars.StatefulEntityKnockbackController.lastImpulseTime = time()
		end)
	end

	local function start()
		if not JadeFly.Enabled or not entitylib.isAlive then return end
		startTime = tick()
		endTime = startTime + Duration.Value
		if active then return end -- already flying: just extend

		active = true
		oldy, tpToggle, tpTick = nil, true, tick()
		store.JadeFlyActive = true -- makes the Speed module stand down while this runs
		frictionTable.JadeFly = true
		updateVelocity()

		connection = runService.PreSimulation:Connect(function(dt)
			if (not JadeFly.Enabled) or (not entitylib.isAlive) or tick() > endTime then
				return stop()
			end
			if StopOnLand.Enabled and (not oldy) and (tick() - startTime) > 0.6 and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				return stop()
			end
			if not isnetworkowner(entitylib.character.RootPart) then return end

			pcall(function()
				bedwars.StatefulEntityKnockbackController.lastImpulseTime = math.huge
			end)

			-- same movement as the Speed module
			local root, velo = entitylib.character.RootPart, getSpeed()
			local moveDirection = entitylib.character.Humanoid.MoveDirection
			local destination = (moveDirection * math.max(Value.Value - velo, 0) * dt)

			if WallCheck.Enabled then
				rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
				rayCheck.CollisionGroup = root.CollisionGroup
				local ray = workspace:Raycast(root.Position, destination, rayCheck)
				if ray then
					destination = ((ray.Position + ray.Normal) - root.Position)
				end
			end

			-- fly: hold height (same 1.5 baseline as the Fly module), Space up / Shift down
			local vertical = 0
			if not inputService:GetFocusedTextBox() then
				vertical = (inputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (inputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0)
			end

			local mass = 1.5 + (vertical * VerticalValue.Value)

			-- TP Down (same logic as the Fly module): after 2s in the air, drop to the ground
			-- for a moment, then put you back at your old height
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			rayCheck.CollisionGroup = root.CollisionGroup
			if tpToggle then
				if (tick() - entitylib.character.AirTime) > 2 and not oldy then
					local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
					if ray and TP.Enabled then
						tpToggle = false
						oldy = root.Position.Y
						tpTick = tick() + 0.11
						root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
					end
				end
			elseif oldy then
				if tpTick < tick() then
					root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, oldy, root.Position.Z), root.CFrame.LookVector)
					tpToggle = true
					oldy = nil
				else
					mass = 0
				end
			end

			root.CFrame += destination
			root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, mass, 0)
		end)
	end

	JadeFly = vape.Categories.Blatant:CreateModule({
		Name = 'Jade Fly',
		Function = function(callback)
			shared.RequiemJade = shared.RequiemJade or {}
			local data = shared.RequiemJade

			if callback then
				data.callback = start
				task.spawn(function()
					local suc, event = pcall(function()
						return replicatedStorage:WaitForChild('events-@easy-games/game-core:shared/game-core-networking@getEvents.Events', 15):WaitForChild('useAbility', 15)
					end)
					if not suc or not event then
						vape:CreateNotification('Requiem', 'Jade Fly: could not find the useAbility remote', 8, 'alert')
						return
					end
					data.event = event

					-- the hook is installed once per session and only reads data.callback,
					-- so turning the module off makes it a pass-through
					if not data.hooked then
						if not (hookmetamethod and getnamecallmethod and newcclosure) then
							vape:CreateNotification('Requiem', 'Jade Fly: your executor has no hookmetamethod', 8, 'alert')
							return
						end
						data.hooked = true
						local old
						old = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
							local info = shared.RequiemJade
							if info and info.callback and self == info.event and getnamecallmethod() == 'FireServer' and (...) == ABILITY then
								task.defer(info.callback)
							end
							return old(self, ...)
						end))
					end
				end)
			else
				data.callback = nil
				stop()
			end
		end,
		Tooltip = 'Starts a fly at Speed-module speed whenever you use the Jade hammer jump'
	})
	Value = JadeFly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 65,
		Default = 28,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	VerticalValue = JadeFly:CreateSlider({
		Name = 'Vertical',
		Min = 1,
		Max = 80,
		Default = 30,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Duration = JadeFly:CreateSlider({
		Name = 'Duration',
		Min = 0.5,
		Max = 10,
		Default = 3,
		Decimal = 10,
		Suffix = 's'
	})
	WallCheck = JadeFly:CreateToggle({
		Name = 'Wall Check',
		Default = true
	})
	TP = JadeFly:CreateToggle({
		Name = 'TP Down',
		Default = true,
		Tooltip = 'Like the Fly module: after 2s in the air, drops you to the ground and back up'
	})
	StopOnLand = JadeFly:CreateToggle({
		Name = 'Stop on land',
		Default = true,
		Tooltip = 'Ends the fly once you touch the ground again'
	})
end)
