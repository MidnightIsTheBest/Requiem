run(function()
	local RichShader
	local Brightness
	local Contrast
	local Saturation
	local TintColor
	local BloomEnabled
	local BloomIntensity
	local BloomSize
	local BloomThreshold
	local SunRaysEnabled
	local SunRaysIntensity
	local SunRaysSpread
	local DOFEnabled
	local DOFFarIntensity
	local DOFNearIntensity
	local DOFDistance
	local VignetteEnabled
	local VignetteTransparency

	local cc, bloom, sunrays, dof, vignette

	RichShader = vape.Categories.Render:CreateModule({
		Name = 'Rich Shader',
		Tooltip = 'Post-processing visual effects (color correction, bloom, sun rays, depth of field)',
		Function = function(callback)
			if callback then
				if vape.ThreadFix then setthreadidentity(8) end

				cc = Instance.new('ColorCorrectionEffect')
				cc.Brightness = Brightness.Value
				cc.Contrast = Contrast.Value
				cc.Saturation = Saturation.Value
				cc.TintColor = Color3.fromHSV(TintColor.Hue, TintColor.Sat, TintColor.Value)
				cc.Parent = lightingService
				RichShader:Clean(cc)

				bloom = Instance.new('BloomEffect')
				bloom.Enabled = BloomEnabled.Enabled
				bloom.Intensity = BloomIntensity.Value
				bloom.Size = BloomSize.Value
				bloom.Threshold = BloomThreshold.Value
				bloom.Parent = lightingService
				RichShader:Clean(bloom)

				sunrays = Instance.new('SunRaysEffect')
				sunrays.Enabled = SunRaysEnabled.Enabled
				sunrays.Intensity = SunRaysIntensity.Value
				sunrays.Spread = SunRaysSpread.Value
				sunrays.Parent = lightingService
				RichShader:Clean(sunrays)

				dof = Instance.new('DepthOfFieldEffect')
				dof.Enabled = DOFEnabled.Enabled
				dof.FarIntensity = DOFFarIntensity.Value
				dof.NearIntensity = DOFNearIntensity.Value
				dof.FocusDistance = DOFDistance.Value
				dof.InFocusRadius = 30
				dof.Parent = lightingService
				RichShader:Clean(dof)

				vignette = Instance.new('Frame')
				vignette.Name = 'RichShaderVignette'
				vignette.BackgroundColor3 = Color3.new(0, 0, 0)
				vignette.BackgroundTransparency = 1
				vignette.Size = UDim2.fromScale(1, 1)
				vignette.BorderSizePixel = 0
				vignette.ZIndex = 0
				vignette.Parent = gui
				local gradient = Instance.new('UIGradient')
				gradient.GradientType = Enum.UIGradientType.Radial
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
				})
				gradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 1),
					NumberSequenceKeypoint.new(1, VignetteEnabled.Enabled and VignetteTransparency.Value or 1)
				})
				gradient.Parent = vignette
				vignette._gradient = gradient
				RichShader:Clean(vignette)
			else
				cc = nil
				bloom = nil
				sunrays = nil
				dof = nil
				vignette = nil
			end
		end
	})

	-- Color Correction
	Brightness = RichShader:CreateSlider({
		Name = 'Brightness', Min = -1, Max = 1, Default = 0.05, Decimal = 100,
		Function = function(v) if cc then cc.Brightness = v end end
	})
	Contrast = RichShader:CreateSlider({
		Name = 'Contrast', Min = -1, Max = 1, Default = 0.15, Decimal = 100,
		Function = function(v) if cc then cc.Contrast = v end end
	})
	Saturation = RichShader:CreateSlider({
		Name = 'Saturation', Min = -1, Max = 1, Default = 0.2, Decimal = 100,
		Function = function(v) if cc then cc.Saturation = v end end
	})
	TintColor = RichShader:CreateColorSlider({
		Name = 'Tint',
		Function = function(h, s, v) if cc then cc.TintColor = Color3.fromHSV(h, s, v) end end
	})

	-- Bloom
	BloomEnabled = RichShader:CreateToggle({
		Name = 'Bloom', Default = true,
		Function = function(cb)
			if bloom then bloom.Enabled = cb end
			BloomIntensity.Object.Visible = cb
			BloomSize.Object.Visible = cb
			BloomThreshold.Object.Visible = cb
		end
	})
	BloomIntensity = RichShader:CreateSlider({
		Name = 'Bloom intensity', Min = 0, Max = 3, Default = 0.6, Decimal = 100, Darker = true,
		Function = function(v) if bloom then bloom.Intensity = v end end
	})
	BloomSize = RichShader:CreateSlider({
		Name = 'Bloom size', Min = 1, Max = 56, Default = 24, Darker = true,
		Function = function(v) if bloom then bloom.Size = v end end
	})
	BloomThreshold = RichShader:CreateSlider({
		Name = 'Bloom threshold', Min = 0, Max = 4, Default = 1.2, Decimal = 10, Darker = true,
		Function = function(v) if bloom then bloom.Threshold = v end end
	})

	-- Sun Rays
	SunRaysEnabled = RichShader:CreateToggle({
		Name = 'Sun Rays',
		Function = function(cb)
			if sunrays then sunrays.Enabled = cb end
			SunRaysIntensity.Object.Visible = cb
			SunRaysSpread.Object.Visible = cb
		end
	})
	SunRaysIntensity = RichShader:CreateSlider({
		Name = 'Rays intensity', Min = 0, Max = 1, Default = 0.15, Decimal = 100, Darker = true, Visible = false,
		Function = function(v) if sunrays then sunrays.Intensity = v end end
	})
	SunRaysSpread = RichShader:CreateSlider({
		Name = 'Rays spread', Min = 0, Max = 1, Default = 0.5, Decimal = 100, Darker = true, Visible = false,
		Function = function(v) if sunrays then sunrays.Spread = v end end
	})

	-- Depth of Field
	DOFEnabled = RichShader:CreateToggle({
		Name = 'Depth of Field',
		Function = function(cb)
			if dof then dof.Enabled = cb end
			DOFFarIntensity.Object.Visible = cb
			DOFNearIntensity.Object.Visible = cb
			DOFDistance.Object.Visible = cb
		end
	})
	DOFFarIntensity = RichShader:CreateSlider({
		Name = 'Far blur', Min = 0, Max = 1, Default = 0.3, Decimal = 100, Darker = true, Visible = false,
		Function = function(v) if dof then dof.FarIntensity = v end end
	})
	DOFNearIntensity = RichShader:CreateSlider({
		Name = 'Near blur', Min = 0, Max = 1, Default = 0, Decimal = 100, Darker = true, Visible = false,
		Function = function(v) if dof then dof.NearIntensity = v end end
	})
	DOFDistance = RichShader:CreateSlider({
		Name = 'Focus distance', Min = 0, Max = 200, Default = 50, Darker = true, Visible = false,
		Function = function(v) if dof then dof.FocusDistance = v end end
	})

	-- Vignette
	VignetteEnabled = RichShader:CreateToggle({
		Name = 'Vignette',
		Function = function(cb)
			VignetteTransparency.Object.Visible = cb
			if vignette and vignette._gradient then
				vignette._gradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 1),
					NumberSequenceKeypoint.new(1, cb and VignetteTransparency.Value or 1)
				})
			end
		end
	})
	VignetteTransparency = RichShader:CreateSlider({
		Name = 'Vignette darkness', Min = 0, Max = 1, Default = 0.5, Decimal = 20, Darker = true, Visible = false,
		Function = function(v)
			if vignette and vignette._gradient and VignetteEnabled.Enabled then
				vignette._gradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 1),
					NumberSequenceKeypoint.new(1, v)
				})
			end
		end
	})
end)
