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

	local cc, bloom, sunrays, dof, vignette, vignetteGradient

	RichShader = vape.Categories.Render:CreateModule({
		Name = 'Rich Shader',
		Tooltip = 'Post-processing visual effects (color correction, bloom, sun rays, depth of field)',
		Function = function(callback)
			if callback then
				if vape.ThreadFix then setthreadidentity(8) end

				cc = Instance.new('ColorCorrectionEffect')
				cc.Brightness = Brightness and Brightness.Value or 0.05
				cc.Contrast = Contrast and Contrast.Value or 0.15
				cc.Saturation = Saturation and Saturation.Value or 0.2
				cc.TintColor = TintColor and Color3.fromHSV(TintColor.Hue, TintColor.Sat, TintColor.Value) or Color3.new(1, 1, 1)
				cc.Parent = lightingService
				RichShader:Clean(cc)

				bloom = Instance.new('BloomEffect')
				bloom.Enabled = not BloomEnabled or BloomEnabled.Enabled
				bloom.Intensity = BloomIntensity and BloomIntensity.Value or 0.6
				bloom.Size = BloomSize and BloomSize.Value or 24
				bloom.Threshold = BloomThreshold and BloomThreshold.Value or 1.2
				bloom.Parent = lightingService
				RichShader:Clean(bloom)

				sunrays = Instance.new('SunRaysEffect')
				sunrays.Enabled = SunRaysEnabled and SunRaysEnabled.Enabled or false
				sunrays.Intensity = SunRaysIntensity and SunRaysIntensity.Value or 0.15
				sunrays.Spread = SunRaysSpread and SunRaysSpread.Value or 0.5
				sunrays.Parent = lightingService
				RichShader:Clean(sunrays)

				dof = Instance.new('DepthOfFieldEffect')
				dof.Enabled = DOFEnabled and DOFEnabled.Enabled or false
				dof.FarIntensity = DOFFarIntensity and DOFFarIntensity.Value or 0.3
				dof.NearIntensity = DOFNearIntensity and DOFNearIntensity.Value or 0
				dof.FocusDistance = DOFDistance and DOFDistance.Value or 50
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
				vignette.Parent = vape.gui
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
					NumberSequenceKeypoint.new(1, (VignetteEnabled and VignetteEnabled.Enabled) and (VignetteTransparency and VignetteTransparency.Value or 0.5) or 1)
				})
				gradient.Parent = vignette
				vignetteGradient = gradient
				RichShader:Clean(vignette)
			else
				cc = nil
				bloom = nil
				sunrays = nil
				dof = nil
				vignette = nil
				vignetteGradient = nil
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
			if BloomIntensity then BloomIntensity.Object.Visible = cb end
			if BloomSize then BloomSize.Object.Visible = cb end
			if BloomThreshold then BloomThreshold.Object.Visible = cb end
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
			if SunRaysIntensity then SunRaysIntensity.Object.Visible = cb end
			if SunRaysSpread then SunRaysSpread.Object.Visible = cb end
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
			if DOFFarIntensity then DOFFarIntensity.Object.Visible = cb end
			if DOFNearIntensity then DOFNearIntensity.Object.Visible = cb end
			if DOFDistance then DOFDistance.Object.Visible = cb end
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
			if VignetteTransparency then VignetteTransparency.Object.Visible = cb end
			if vignetteGradient then
				vignetteGradient.Transparency = NumberSequence.new({
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
			if vignetteGradient and VignetteEnabled.Enabled then
				vignetteGradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 1),
					NumberSequenceKeypoint.new(1, v)
				})
			end
		end
	})
end)
