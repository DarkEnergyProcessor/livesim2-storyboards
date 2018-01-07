local Fyd = {}
local tween = require("tween")
local EffectPlayer = require("EffectPlayer")
local love = love
assert(DEPLS_VERSION_NUMBER >= 01010502, "Older release of Live Simulator: 2 is not supported. Disable storyboard!")
assert(MultiVideoFormatSupported(), "Loading MKV video is not supported. Disable storyboard!")

Fyd.BPM = 120
Fyd.Bar = 4	-- 4/4
Fyd.Offset = 140 -- ms

local function BeatToTime(bar, beat, tick)
	tick = tick or 0
	return 60000 / Fyd.BPM * ((beat - 1) + tick / 96 + (bar - 1) * Fyd.Bar) - Fyd.Offset
end

function Initialize()
	-- Variable declaration
	Fyd.BackgroundDim = 0
	Fyd.BackgroundDimTween = tween.new(400, Fyd, {BackgroundDim = 190})
	
	Fyd.SpinningYellow = LoadImage("ef_356_001.png")
	Fyd.SpinningCircOpacity = 0
	Fyd.SpinningCircScale = 1
	Fyd.SpinningCircTweenAppear = tween.new(500, Fyd, {SpinningCircOpacity = 1})
	Fyd.SpinningCircTweenExplode = tween.new(500, Fyd, {SpinningCircOpacity = 0, SpinningCircScale = 4}, "outCubic")
	Fyd.SpinningCircYui = GetCurrentUnitImage(5)
	
	Fyd.URRed = LoadDEPLS2Image("assets/image/unit_icon/f_UR_1.png")
	Fyd.URGreen = LoadDEPLS2Image("assets/image/unit_icon/f_UR_2.png")
	Fyd.URBlue = LoadDEPLS2Image("assets/image/unit_icon/f_UR_3.png")
	Fyd.Placeholder = GetCurrentUnitImage(9)
	Fyd.PlaceholderOpacity = 1
	Fyd.PlaceholderFrame = "URBlue"
	Fyd.URDrawPos = {
		{816, 96 }, {698, 378},
		{133, 378}, {16 , 96 }
	}
	Fyd.URSpotColor = {
		URRed = {255, 0, 0},
		URBlue = {0, 0, 255},
		URGreen = {0, 255, 0}
	}
	
	Fyd.ET = -GetLiveSimulatorDelay()
	
	-- Video
	Fyd.Video = assert(LoadVideo("video_background.mkv"))
	Fyd.VideoGlowShader = love.graphics.newShader [[
	// adapted from http://www.youtube.com/watch?v=qNM0k522R7o
	// https://gist.github.com/BlackBulletIV/4218802

	extern int samples;   // pixels per axis; higher = bigger glow, worse performance
	extern float quality; // lower = smaller glow, better quality

	vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
	{
		vec2 size = love_ScreenSize.xy;
		vec4 source = VideoTexel(tc);
		vec4 sum = vec4(0);
		int diff = (samples - 1) / 2;
		vec2 sizeFactor = vec2(1) / size * quality;
		
		for (int x = -diff; x <= diff; x++)
		{
			for (int y = -diff; y <= diff; y++)
			{
				vec2 offset = vec2(x, y) * sizeFactor;
				sum += VideoTexel(tc + offset);
			}
		}
		
		return ((sum / (vec4(samples * samples))) + source) * colour;
	}
	]]
	Fyd.VideoGlowShader:send("samples", 3)
	Fyd.VideoGlowShader:send("quality", 2)
	Fyd.VideoGlowMix = 1
	Fyd.VideoGlowMixTween = tween.new(400, Fyd, {VideoGlowMix = 0})
	Fyd.VideoGlowMixTween:update(500)
	
	-- Drawing function
	function Fyd.DrawPlaceholder()
		love.graphics.setColor(255, 255, 255, Fyd.PlaceholderOpacity * 255)
		for i = 1, 4 do
			love.graphics.draw(Fyd.Placeholder, Fyd.URDrawPos[i][1], Fyd.URDrawPos[i][2])
			love.graphics.draw(Fyd[Fyd.PlaceholderFrame], Fyd.URDrawPos[i][1], Fyd.URDrawPos[i][2])
		end
	end
	
	function Fyd.SetAllUnitOpacityExcept5(opacity)
		Fyd.PlaceholderOpacity = opacity
		SetUnitOpacity(2, opacity * 255)
		SetUnitOpacity(4, opacity * 255)
		SetUnitOpacity(6, opacity * 255)
		SetUnitOpacity(8, opacity * 255)
	end
	
	function Fyd.SwitchPlaceholderURFrameColor(frame)
		local col = assert(Fyd.URSpotColor[frame])
		Fyd.PlaceholderFrame = frame
		
		SpawnSpotEffect(9, col[1], col[2], col[3])
		SpawnSpotEffect(7, col[1], col[2], col[3])
		SpawnSpotEffect(3, col[1], col[2], col[3])
		SpawnSpotEffect(1, col[1], col[2], col[3])
	end
	
	-- Functions
	function Fyd.Start()
		SetBackgroundDimOpacity(255)
		SetUnitOpacity(9, 0)
		SetUnitOpacity(7, 0)
		SetUnitOpacity(3, 0)
		SetUnitOpacity(1, 0)
		Fyd.BackgroundDimTween:update(500)
		Fyd.Video:play()
	end
	
	function Fyd.FlashScreen()
		Fyd.BackgroundDimTween:reset()
	end
	
	function Fyd.GlowVideo()
		Fyd.VideoGlowMixTween:reset()
	end
	
	Fyd.StartGlowVideoSlowlyAndOpacityTween = tween.new(2000, Fyd, {VideoGlowMix = 1})
	function Fyd.StartGlowVideoSlowlyAndOpacity()
		Fyd.StartGlowVideoSlowlyAndOpacityTweenStart = true
	end
	
	function Fyd.YellowCircleAppear()
		Fyd.SpinningCircTweenAppearStart = true
	end
	
	function Fyd.YellowCircleExplode()
		Fyd.SpinningCircTweenExplodeStart = true
	end
	
	local SwitchPlaceholderURFrameColorList = {}
	function Fyd.CreateSwitchPlaceholderURFrameColorFunction(frame)
		if not(SwitchPlaceholderURFrameColorList[frame]) then
			SwitchPlaceholderURFrameColorList[frame] = function()
				return Fyd.SwitchPlaceholderURFrameColor(frame)
			end
		end
		return SwitchPlaceholderURFrameColorList[frame]
	end
	
	function Fyd.AllUnitOpaqueIn500Millisecond()
		EffectPlayer.Spawn({ET = 0},
		-- Update
		function(udata, deltaT)
			udata.ET = math.min(udata.ET + deltaT, 500)
			Fyd.SetAllUnitOpacityExcept5(udata.ET / 500)
			
			return udata.ET >= 500
		end,
		function() end)
	end
	
	-- Time points
	Fyd.TimePoints = {
		{0, Fyd.Start},
		{BeatToTime(18, 1), Fyd.FlashScreen},
		{BeatToTime(18, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URRed")},
		{BeatToTime(18, 2), Fyd.FlashScreen},
		{BeatToTime(18, 3), Fyd.FlashScreen},
		{BeatToTime(18, 4), Fyd.FlashScreen},
		{BeatToTime(19, 1), Fyd.FlashScreen},
		{BeatToTime(19, 2), Fyd.FlashScreen},
		{BeatToTime(19, 3), Fyd.FlashScreen},
		{BeatToTime(19, 4), Fyd.FlashScreen},
		{BeatToTime(20, 1), Fyd.FlashScreen},
		{BeatToTime(20, 2), Fyd.FlashScreen},
		{BeatToTime(20, 3), Fyd.FlashScreen},
		{BeatToTime(20, 4), Fyd.FlashScreen},
		{BeatToTime(22, 1), Fyd.FlashScreen},
		{BeatToTime(22, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URGreen")},
		{BeatToTime(26, 1), Fyd.FlashScreen},
		{BeatToTime(26, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URBlue")},
		{BeatToTime(30, 1), Fyd.FlashScreen},
		{BeatToTime(30, 1), Fyd.GlowVideo},
		{BeatToTime(30, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URGreen")},
		{BeatToTime(32, 1), Fyd.FlashScreen},
		{BeatToTime(32, 1), Fyd.GlowVideo},
		{BeatToTime(34, 1), Fyd.FlashScreen},
		{BeatToTime(34, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URBlue")},
		{BeatToTime(34, 3), Fyd.FlashScreen},
		{BeatToTime(34, 3), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URBlue")},
		{BeatToTime(35, 1), Fyd.FlashScreen},
		{BeatToTime(35, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URBlue")},
		{BeatToTime(35, 3), Fyd.FlashScreen},
		{BeatToTime(35, 3), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URBlue")},
		{BeatToTime(38, 1), Fyd.StartGlowVideoSlowlyAndOpacity},
		
		{BeatToTime(39, 1), Fyd.FlashScreen},
		{BeatToTime(39, 1), Fyd.GlowVideo},
		{BeatToTime(39, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URRed")},
		{BeatToTime(39, 2), Fyd.FlashScreen},
		{BeatToTime(39, 2), Fyd.GlowVideo},
		{BeatToTime(39, 3), Fyd.FlashScreen},
		{BeatToTime(39, 3), Fyd.GlowVideo},
		{BeatToTime(39, 4), Fyd.FlashScreen},
		{BeatToTime(39, 4), Fyd.GlowVideo},
		
		-- Beat 40 til 54 is filled with loops
		{BeatToTime(47, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URRed")},
		{BeatToTime(55, 1), Fyd.GlowVideo},
		{BeatToTime(55, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URRed")},
		{BeatToTime(65, 1), Fyd.YellowCircleAppear},
		{BeatToTime(68, 4), Fyd.AllUnitOpaqueIn500Millisecond},
		{BeatToTime(72, 4), Fyd.YellowCircleExplode},
		{BeatToTime(73, 1), Fyd.CreateSwitchPlaceholderURFrameColorFunction("URBlue")},
	}
	for i = 40, 54 do
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 1), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 1), Fyd.GlowVideo}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 2), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 2), Fyd.GlowVideo}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 3), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 3), Fyd.GlowVideo}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 4), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 4), Fyd.GlowVideo}
	end
	for i = 51, 62 do
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 1), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 2), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 3), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 4), Fyd.FlashScreen}
	end
	for i = 73, 80 do
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 1), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 1), Fyd.GlowVideo}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 2), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 2), Fyd.GlowVideo}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 3), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 3), Fyd.GlowVideo}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 4), Fyd.FlashScreen}
		Fyd.TimePoints[#Fyd.TimePoints + 1] = {BeatToTime(i, 4), Fyd.GlowVideo}
	end
	
	table.sort(Fyd.TimePoints, function(a, b)
		return a[1] < b[1]
	end)
end

function Update(deltaT)
	local timed = Fyd.TimePoints[1]
	Fyd.ET = Fyd.ET + deltaT
	
	if Fyd.ET >= 0 then
		while timed and Fyd.ET >= timed[1] do
			table.remove(Fyd.TimePoints, 1)
			timed[2]()
			timed = Fyd.TimePoints[1]
		end
		
		-- Opacity update
		Fyd.BackgroundDimTween:update(deltaT)
		
		-- Draw video
		if Fyd.Video:isPlaying() then
			Fyd.VideoGlowMixTween:update(deltaT)
			if Fyd.StartGlowVideoSlowlyAndOpacityTweenStart then
				Fyd.StartGlowVideoSlowlyAndOpacityTweenStart = not(Fyd.StartGlowVideoSlowlyAndOpacityTween:update(deltaT))
				Fyd.BackgroundDim = math.min(2 * Fyd.VideoGlowMix, 1) * 190
			end
			
			if Fyd.SpinningCircAppear and not(Fyd.SpinningCircTweenExplodeStart) then
				Fyd.VideoGlowMix = math.min(math.max(Fyd.ET - BeatToTime(68, 1), 0), 2000) / 4000
			end
			
			love.graphics.push("all")
			love.graphics.setColor(255, 255, 255)
			love.graphics.draw(Fyd.Video, -88, 0, 0, 1136/848, 640/480)
			
			if Fyd.VideoGlowMix > 0 then
				love.graphics.setShader(Fyd.VideoGlowShader)
				love.graphics.setColor(255, 255, 255, Fyd.VideoGlowMix * 255)
				love.graphics.draw(Fyd.Video, -88, 0, 0, 1136/848, 640/480)
				love.graphics.setShader()
			end
			love.graphics.pop()
		end
		
		-- Yellow circle update
		if Fyd.SpinningCircTweenAppearStart then
			SetUnitOpacity(5, 0)
			Fyd.SpinningCircAppear = true
			Fyd.SpinningCircTweenAppearStart = not(Fyd.SpinningCircTweenAppear:update(deltaT))
			Fyd.SetAllUnitOpacityExcept5(1 - Fyd.SpinningCircOpacity)
			
		end
		
		if Fyd.SpinningCircTweenExplodeStart then
			local res = Fyd.SpinningCircTweenExplode:update(deltaT)
			Fyd.VideoGlowMix = Fyd.SpinningCircOpacity
			
			if res then
				Fyd.VideoGlowMix = 0
				Fyd.BackgroundDim = 190
				Fyd.SpinningCircTweenExplodeStart = false
				Fyd.SpinningCircAppear = false
				SetUnitOpacity(5, 255)
			end
		end
		
		-- Opacity draw
		if Fyd.SpinningCircAppear then
			Fyd.BackgroundDim = (1 - Fyd.SpinningCircOpacity) * 190
		end
		love.graphics.setColor(0, 0, 0, Fyd.BackgroundDim)
		love.graphics.rectangle("fill", -88, -43, 1136, 726)
		
		-- Yellow circle draw
		if Fyd.SpinningCircAppear then
			love.graphics.setColor(255, 255, 255)
			love.graphics.draw(Fyd.SpinningCircYui, 416, 496)
			love.graphics.setColor(255, 255, 255, Fyd.SpinningCircOpacity * 255)
			love.graphics.draw(Fyd.SpinningYellow, 480, 560, Fyd.ET * 0.001 * math.pi, Fyd.SpinningCircScale, Fyd.SpinningCircScale, 90, 90)
		end
		
		-- Placeholder
		Fyd.DrawPlaceholder()
	end
end
