run(function()
	local TexturePack
	local Mode
	local TintByTier
	local Others
	local Flip
	local Scale
	local Thickness
	local RotX, RotY, RotZ
	local OffX, OffY, OffZ

	local TEXTURE_URL = 'https://files.catbox.moe/nyk4g2.png'
	local TEXTURE_PATH = 'requiem/assets/swordtexture.png'

	-- the source texture is white, so each tier just tints it (shading in the texture is kept)
	local tierColors = {
		wood = Color3.fromRGB(165, 115, 62),
		stone = Color3.fromRGB(140, 140, 146),
		iron = Color3.fromRGB(235, 235, 240),
		diamond = Color3.fromRGB(80, 235, 225),
		emerald = Color3.fromRGB(55, 225, 105),
	}

	-- REQUIEM: minimal PNG decoder (zlib inflate + unfilter), returns w, h, pixels[y][x] = {r,g,b,a} (0-based)
	local band, bor, lshift, rshift = bit32.band, bit32.bor, bit32.lshift, bit32.rshift

	local LBASE = {[0]=3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258}
	local LEXT = {[0]=0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0}
	local DBASE = {[0]=1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577}
	local DEXT = {[0]=0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13}
	local CLORDER = {[0]=16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15}

	local function inflate(src, pos)
		local out, outn = {}, 0
		local bitbuf, bitcnt = 0, 0

		local function bits(n)
			while bitcnt < n do
				local b = string.byte(src, pos)
				if not b then error('inflate: out of input') end
				pos += 1
				bitbuf = bor(bitbuf, lshift(b, bitcnt))
				bitcnt += 8
			end
			local v = band(bitbuf, lshift(1, n) - 1)
			bitbuf = rshift(bitbuf, n)
			bitcnt -= n
			return v
		end

		local function construct(lengths, n)
			local h = {count = {}, symbol = {}}
			for len = 0, 15 do h.count[len] = 0 end
			for sym = 0, n - 1 do
				h.count[lengths[sym]] += 1
			end
			local offs = {[1] = 0}
			for len = 1, 14 do
				offs[len + 1] = offs[len] + h.count[len]
			end
			for sym = 0, n - 1 do
				local len = lengths[sym]
				if len ~= 0 then
					h.symbol[offs[len]] = sym
					offs[len] += 1
				end
			end
			return h
		end

		local function decode(h)
			local code, first, index = 0, 0, 0
			for len = 1, 15 do
				code = bor(code, bits(1))
				local count = h.count[len]
				if code - count < first then
					return h.symbol[index + (code - first)]
				end
				index += count
				first += count
				first = lshift(first, 1)
				code = lshift(code, 1)
			end
			error('inflate: bad code')
		end

		local function codes(lencode, distcode)
			while true do
				local sym = decode(lencode)
				if sym < 256 then
					outn += 1
					out[outn] = sym
				elseif sym == 256 then
					return
				else
					sym -= 257
					local len = LBASE[sym] + bits(LEXT[sym])
					local dsym = decode(distcode)
					local dist = DBASE[dsym] + bits(DEXT[dsym])
					for _ = 1, len do
						outn += 1
						out[outn] = out[outn - dist]
					end
				end
			end
		end

		local fixedLen, fixedDist
		repeat
			local last = bits(1)
			local btype = bits(2)
			if btype == 0 then
				bitbuf, bitcnt = 0, 0
				local len = string.byte(src, pos) + string.byte(src, pos + 1) * 256
				pos += 4
				for i = 0, len - 1 do
					outn += 1
					out[outn] = string.byte(src, pos + i)
				end
				pos += len
			elseif btype == 1 then
				if not fixedLen then
					local l = {}
					for s = 0, 143 do l[s] = 8 end
					for s = 144, 255 do l[s] = 9 end
					for s = 256, 279 do l[s] = 7 end
					for s = 280, 287 do l[s] = 8 end
					fixedLen = construct(l, 288)
					local d = {}
					for s = 0, 29 do d[s] = 5 end
					fixedDist = construct(d, 30)
				end
				codes(fixedLen, fixedDist)
			elseif btype == 2 then
				local nlen = bits(5) + 257
				local ndist = bits(5) + 1
				local ncode = bits(4) + 4
				local lengths = {}
				for i = 0, 18 do lengths[i] = 0 end
				for i = 0, ncode - 1 do lengths[CLORDER[i]] = bits(3) end
				local lencode = construct(lengths, 19)
				local all, index = {}, 0
				while index < nlen + ndist do
					local sym = decode(lencode)
					if sym < 16 then
						all[index] = sym
						index += 1
					else
						local len, rep = 0, 0
						if sym == 16 then
							len = all[index - 1]
							rep = 3 + bits(2)
						elseif sym == 17 then
							rep = 3 + bits(3)
						else
							rep = 11 + bits(7)
						end
						for _ = 1, rep do
							all[index] = len
							index += 1
						end
					end
				end
				local ll, dl = {}, {}
				for i = 0, nlen - 1 do ll[i] = all[i] end
				for i = 0, ndist - 1 do dl[i] = all[nlen + i] end
				codes(construct(ll, nlen), construct(dl, ndist))
			else
				error('inflate: bad block type')
			end
		until last == 1
		return out, outn
	end

	local function u32(s, i)
		local a, b, c, d = string.byte(s, i, i + 3)
		return ((a * 256 + b) * 256 + c) * 256 + d
	end

	local function decodePNG(data)
		if data:sub(1, 8) ~= '\137PNG\r\n\26\n' then error('not a png') end
		local pos = 9
		local w, h, depth, ctype, interlace
		local idat, palette, trns = {}, nil, nil
		while pos <= #data do
			local len = u32(data, pos)
			local typ = data:sub(pos + 4, pos + 7)
			local body = data:sub(pos + 8, pos + 7 + len)
			pos += 12 + len
			if typ == 'IHDR' then
				w, h = u32(body, 1), u32(body, 5)
				depth, ctype, interlace = body:byte(9), body:byte(10), body:byte(13)
			elseif typ == 'PLTE' then
				palette = body
			elseif typ == 'tRNS' then
				trns = body
			elseif typ == 'IDAT' then
				table.insert(idat, body)
			elseif typ == 'IEND' then
				break
			end
		end
		if interlace ~= 0 then error('interlaced png not supported') end
		if w * h > 128 * 128 then error('texture too big (max 128x128)') end

		local zs = table.concat(idat)
		local raw = inflate(zs, 3) -- skip 2-byte zlib header

		local channels = ({[0] = 1, [2] = 3, [3] = 1, [4] = 2, [6] = 4})[ctype]
		if not channels then error('unsupported png color type '..tostring(ctype)) end
		local bitsPerPixel = channels * depth
		local bpp = math.max(1, bitsPerPixel // 8)
		local stride = (w * bitsPerPixel + 7) // 8

		-- unfilter into rows[y][i] (1-based bytes)
		local rows, prev = {}, nil
		local rp = 1
		for y = 0, h - 1 do
			local ft = raw[rp]
			rp += 1
			local row = {}
			for i = 1, stride do
				local x = raw[rp]
				rp += 1
				local a = i > bpp and row[i - bpp] or 0
				local b = prev and prev[i] or 0
				local c = (prev and i > bpp) and prev[i - bpp] or 0
				if ft == 1 then
					x += a
				elseif ft == 2 then
					x += b
				elseif ft == 3 then
					x += (a + b) // 2
				elseif ft == 4 then
					local p = a + b - c
					local pa, pb, pc = math.abs(p - a), math.abs(p - b), math.abs(p - c)
					if pa <= pb and pa <= pc then x += a elseif pb <= pc then x += b else x += c end
				end
				row[i] = x % 256
			end
			rows[y] = row
			prev = row
		end

		local function sample(row, index) -- index: 0-based sample index within row
			if depth == 8 then
				return row[index + 1]
			elseif depth == 16 then
				return row[index * 2 + 1]
			end
			local bitpos = index * depth
			local byte = row[bitpos // 8 + 1]
			local shift = 8 - depth - (bitpos % 8)
			return band(rshift(byte, shift), lshift(1, depth) - 1)
		end

		local maxv = (depth == 16) and 255 or (lshift(1, depth) - 1)
		local pixels = {}
		for y = 0, h - 1 do
			local row, line = rows[y], {}
			for x = 0, w - 1 do
				local r, g, b, a
				if ctype == 6 then
					r, g, b, a = sample(row, x * 4), sample(row, x * 4 + 1), sample(row, x * 4 + 2), sample(row, x * 4 + 3)
				elseif ctype == 2 then
					r, g, b, a = sample(row, x * 3), sample(row, x * 3 + 1), sample(row, x * 3 + 2), 255
				elseif ctype == 4 then
					local v = sample(row, x * 2)
					r, g, b, a = v, v, v, sample(row, x * 2 + 1)
				elseif ctype == 0 then
					local v = sample(row, x) * 255 // maxv
					r, g, b, a = v, v, v, 255
				else -- palette
					local i = sample(row, x)
					r, g, b = palette:byte(i * 3 + 1, i * 3 + 3)
					a = (trns and i < #trns) and trns:byte(i + 1) or 255
				end
				line[x] = {r, g, b, a}
			end
			pixels[y] = line
		end
		return w, h, pixels
	end

	local texData, textureId, loadError
	local runs -- merged horizontal pixel runs {x0, x1, y, r, g, b}
	local texW, texH, midX, midY, extent

	local function loadTexture()
		if texData or loadError then return end
		local ok, err = pcall(function()
			if not isfolder('requiem/assets') then makefolder('requiem/assets') end
			if not isfile(TEXTURE_PATH) then
				writefile(TEXTURE_PATH, game:HttpGet(TEXTURE_URL, true))
			end
			texData = readfile(TEXTURE_PATH)
		end)
		if not ok then
			loadError = tostring(err)
			notif('Texture Pack', 'Could not download texture: '..loadError, 8, 'alert')
			return
		end
		pcall(function() textureId = getcustomasset(TEXTURE_PATH) end)

		local dok, derr = pcall(function()
			local w, h, px = decodePNG(texData)
			texW, texH = w, h
			runs = {}
			local s = math.sqrt(2)
			local minA, maxA, minB, maxB = math.huge, -math.huge, math.huge, -math.huge
			for y = 0, h - 1 do
				local x = 0
				while x < w do
					local p = px[y][x]
					if p[4] >= 128 then
						local x1 = x
						while x1 + 1 < w do
							local q = px[y][x1 + 1]
							if q[4] >= 128 and q[1] == p[1] and q[2] == p[2] and q[3] == p[3] then x1 += 1 else break end
						end
						table.insert(runs, {x, x1, y, p[1], p[2], p[3]})
						for cx = x, x1 do
							-- pixel centre in y-up space, rotated 45deg so the bottom-left -> top-right diagonal is "up"
							local ux, uy = cx + 0.5, h - y - 0.5
							local a, b = (ux - uy) / s, (ux + uy) / s
							minA, maxA = math.min(minA, a), math.max(maxA, a)
							minB, maxB = math.min(minB, b), math.max(maxB, b)
						end
						x = x1 + 1
					else
						x += 1
					end
				end
			end
			if #runs == 0 then error('texture is fully transparent') end
			midX, midY = (minA + maxA) / 2, (minB + maxB) / 2
			extent = (maxB - minB) + 1
		end)
		if not dok then
			runs = nil
			notif('Texture Pack', '3D build failed ('..tostring(derr)..'), using layered mode', 8, 'warning')
		end
	end

	local function tierOf(name)
		local tier = name:match('^(%a+)_sword$')
		return tier and tierColors[tier] and tier
	end

	local axes = {Vector3.xAxis, Vector3.yAxis, Vector3.zAxis}

	-- fit the new model to the real sword: same centre, same length, blade along its longest axis
	local function fitFrame(item, handle)
		local minV, maxV = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, part in item:GetDescendants() do
			if part:IsA('BasePart') and not part.Name:find('^Requiem') then
				local rel = handle.CFrame:ToObjectSpace(part.CFrame)
				local hs = part.Size / 2
				for _, sx in {-1, 1} do
					for _, sy in {-1, 1} do
						for _, sz in {-1, 1} do
							local c = rel * Vector3.new(hs.X * sx, hs.Y * sy, hs.Z * sz)
							minV = minV:Min(c)
							maxV = maxV:Max(c)
						end
					end
				end
			end
		end
		local size = maxV - minV
		local center = (minV + maxV) / 2
		local comps = {size.X, size.Y, size.Z}
		local long, short = 1, 1
		for i = 2, 3 do
			if comps[i] > comps[long] then long = i end
			if comps[i] < comps[short] then short = i end
		end
		if short == long then short = long % 3 + 1 end
		local up = axes[long] * (Flip.Enabled and -1 or 1)
		local back = axes[short]
		local right = up:Cross(back)
		local base = CFrame.fromMatrix(center, right, up, back)
		local user = CFrame.new(OffX.Value, OffY.Value, OffZ.Value)
			* CFrame.Angles(math.rad(RotX.Value), math.rad(RotY.Value), math.rad(RotZ.Value))
		return base * user, comps[long]
	end

	local applied = {} -- [item] = {model = Model, hidden = {[part] = oldTransparency}}

	local function restore(item)
		local data = applied[item]
		if not data then return end
		applied[item] = nil
		if data.model then data.model:Destroy() end
		for part, old in data.hidden do
			if part.Parent then part.Transparency = old end
		end
	end

	local function newPart(size, color, handle, c0, parent)
		local p = Instance.new('Part')
		p.Name = 'RequiemVoxel'
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.CFrame = handle.CFrame * c0
		local weld = Instance.new('Weld')
		weld.Part0 = handle
		weld.Part1 = p
		weld.C0 = c0
		weld.Parent = p
		p.Parent = parent
		return p
	end

	local function build3D(model, handle, frame, length, tint)
		local p = length * Scale.Value / extent
		local depth = p * Thickness.Value
		local center = frame * CFrame.new(-midX * p, -midY * p, 0) * CFrame.Angles(0, 0, math.rad(45))
		for _, r in runs do
			local x0, x1, y = r[1], r[2], r[3]
			local cx = (x0 + x1 + 1) / 2
			local cy = texH - y - 0.5
			local col = Color3.fromRGB(r[4], r[5], r[6])
			col = Color3.new(col.R * tint.R, col.G * tint.G, col.B * tint.B)
			newPart(Vector3.new((x1 - x0 + 1) * p, p, depth), col, handle, center * CFrame.new(cx * p, cy * p, 0), model)
		end
	end

	-- fallback: stack flat copies of the texture so it still looks solid from the side
	local function buildLayers(model, handle, frame, length, tint)
		if not textureId then return end
		local side = length * Scale.Value / math.sqrt(2)
		local thick = side / 16 * Thickness.Value
		local layers = 8
		for i = 0, layers - 1 do
			local z = (i / (layers - 1) - 0.5) * thick
			local part = newPart(Vector3.new(side, side, 0.01), Color3.new(1, 1, 1), handle, frame * CFrame.new(0, 0, z) * CFrame.Angles(0, 0, math.rad(45)), model)
			part.Transparency = 1
			for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
				local d = Instance.new('Decal')
				d.Face = face
				d.Texture = textureId
				d.Color3 = tint
				d.Parent = part
			end
		end
	end

	local function apply(item, tier)
		local handle = item:FindFirstChild('Handle')
		if not handle or not handle:IsA('BasePart') then return end
		loadTexture()
		if not runs and not textureId then return end

		local frame, length = fitFrame(item, handle)
		local data = {hidden = {}}
		applied[item] = data

		-- hide the original sword (only on your screen)
		for _, v in item:GetDescendants() do
			if v:IsA('BasePart') then
				data.hidden[v] = v.Transparency
				v.Transparency = 1
			end
		end

		local model = Instance.new('Model')
		model.Name = 'RequiemSwordModel'
		local tint = TintByTier.Enabled and tierColors[tier] or Color3.new(1, 1, 1)
		if runs and Mode.Value == '3D' then
			build3D(model, handle, frame, length, tint)
		else
			buildLayers(model, handle, frame, length, tint)
		end
		model.Parent = item
		data.model = model
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
		Tooltip = 'Replaces wood / stone / iron / diamond / emerald swords with a 3D pixel model of your texture',
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
					for item in applied do
						if not seen[item] or not item.Parent then restore(item) end
					end
				end))
				TexturePack:Clean(refreshAll)
			end
		end
	})

	-- any setting change just rebuilds; the scan re-applies within 0.2s
	local function rebuild()
		if TexturePack and TexturePack.Enabled then refreshAll() end
	end

	Mode = TexturePack:CreateDropdown({
		Name = 'Mode',
		List = {'3D', 'Flat'},
		Tooltip = '3D = Minecraft-style pixel model, Flat = stacked texture layers',
		Function = rebuild
	})
	TintByTier = TexturePack:CreateToggle({
		Name = 'Tint by tier', Default = true,
		Tooltip = 'Colours the white texture: wood brown, stone grey, iron white, diamond aqua, emerald green',
		Function = rebuild
	})
	Flip = TexturePack:CreateToggle({
		Name = 'Flip',
		Tooltip = 'Turn this on if the handle and tip are the wrong way round',
		Function = rebuild
	})
	Others = TexturePack:CreateToggle({
		Name = 'Other players too',
		Tooltip = 'Also show it on other players\' swords (only you see it)',
		Function = rebuild
	})
	Scale = TexturePack:CreateSlider({Name = 'Scale', Min = 0.5, Max = 2, Default = 1, Decimal = 20, Function = rebuild})
	Thickness = TexturePack:CreateSlider({Name = 'Thickness', Min = 0.25, Max = 3, Default = 1, Decimal = 20, Function = rebuild})
	RotX = TexturePack:CreateSlider({Name = 'Rotation X', Min = -180, Max = 180, Default = 0, Darker = true, Function = rebuild})
	RotY = TexturePack:CreateSlider({Name = 'Rotation Y', Min = -180, Max = 180, Default = 0, Darker = true, Function = rebuild})
	RotZ = TexturePack:CreateSlider({Name = 'Rotation Z', Min = -180, Max = 180, Default = 0, Darker = true, Function = rebuild})
	OffX = TexturePack:CreateSlider({Name = 'Offset X', Min = -3, Max = 3, Default = 0, Decimal = 20, Darker = true, Function = rebuild})
	OffY = TexturePack:CreateSlider({Name = 'Offset Y', Min = -3, Max = 3, Default = 0, Decimal = 20, Darker = true, Function = rebuild})
	OffZ = TexturePack:CreateSlider({Name = 'Offset Z', Min = -3, Max = 3, Default = 0, Decimal = 20, Darker = true, Function = rebuild})
end)
