-- Copied from Poppin' Party - Senbonzakura
assert(DEPLS_VERSION_NUMBER >= 02000000, "Live Simulator: 2 version not compatible. Disable storyboard!")

local Sen = {Event = {}}
local BPM = 140 -- Only use the fast beat
local Bar = 4	-- 4/4
local Offset = -15520 -- ms. Only use the fast beat

local function BeatToTime(bar, beat, tick)
	tick = tick or 0
	return 60000 / BPM * ((beat - 1) + tick / 96 + (bar - 1) * Bar) - Offset
end

local GaussianBlur = [[
// https://github.com/Jam3/glsl-fast-gaussian-blur
extern number strength;
extern vec2 direction;

vec4 blur13(sampler2D image, vec2 uv, vec2 resolution) {
	vec4 color = vec4(0.0);
	vec2 off1 = vec2(1.411764705882353) * direction;
	vec2 off2 = vec2(3.2941176470588234) * direction;
	vec2 off3 = vec2(5.176470588235294) * direction;
	color += texture2D(image, uv) * 0.1964825501511404;
	color += texture2D(image, uv + (off1 / resolution)) * 0.2969069646728344;
	color += texture2D(image, uv - (off1 / resolution)) * 0.2969069646728344;
	color += texture2D(image, uv + (off2 / resolution)) * 0.09447039785044732;
	color += texture2D(image, uv - (off2 / resolution)) * 0.09447039785044732;
	color += texture2D(image, uv + (off3 / resolution)) * 0.010381362401148057;
	color += texture2D(image, uv - (off3 / resolution)) * 0.010381362401148057;
	return color;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 fragCoord)
{
	vec4 blur = blur13(tex, uv, love_ScreenSize.xy);
	return mix(Texel(tex, uv), blur, strength) * color;
}
]]

function Sen.LoadBackgroundID(id)
	local t = {}
	t[0] = LoadDEPLS2Image("assets/image/background/liveback_"..id..".png")
	t[1] = LoadDEPLS2Image(string.format("assets/image/background/b_liveback_%03d_01.png", id))
	t[2] = LoadDEPLS2Image(string.format("assets/image/background/b_liveback_%03d_02.png", id))
	t[3] = LoadDEPLS2Image(string.format("assets/image/background/b_liveback_%03d_03.png", id))
	t[4] = LoadDEPLS2Image(string.format("assets/image/background/b_liveback_%03d_04.png", id))
	
	return assert(t[0] and t[1] and t[2] and t[3] and t[4] and t)
end

Sen.Navi = {}

local function makeScore(score, idx, rarity)
	return function()
		AddScore(score)
		return SkillPopup(idx, "green", "score_up", Sen.Navi[idx], rarity)
	end
end

local function makeHealer(idx, rarity)
	return function()
		return SkillPopup(idx, "blue", "healer", Sen.Navi[idx], rarity)
	end
end

local function makePerflock(duration, lock_good, idx, rarity)
	return function()
		(lock_good and SetRedTimingDuration or SetYellowTimingDuration)(duration)
		return SkillPopup(idx, lock_good and "red" or "yellow", lock_good and "tw++" or "tw+", Sen.Navi[idx], rarity)
	end
end

-- Timer-based event
Sen.Event.Timed = {
	-- {Second, Chance, Callback}
	{10, 45, makeScore(452, 2, "SR")},
	{10, 39, makePerflock(2000, false, 6, "SR")},
}

-- Note-based event
Sen.Event.Note = {
	-- {Notes, Chance, Callback}
	{27, 37, makePerflock(4000, true, 8, "UR")},
	{32, 43, makeScore(820, 4, "UR")},
}

-- Perfect-based event
Sen.Event.Perfect = {
	-- {Perfect, Chance, Callback}
	{14, 40, makeHealer(5, "UR")},
}

function Sen.Event.Initialize(start_et)
	start_et = start_et or 0
	
	-- Timed based
	for i, v in ipairs(Sen.Event.Timed) do
		v.ET = start_et * 0.001
	end
	
	--Note-based and Perfect-based
	for a, b in ipairs({Sen.Event.Note, Sen.Event.Perfect}) do
		for i, v in ipairs(b) do
			v.Count = 0
		end
	end
end

function Sen.AttemptToTrigger(idx)
	if math.random(0, 100) <= idx[2] then
		idx[3]()
	end
end

function Sen.NoteHandler(accuracy)
	-- For Note-based, it doesn't matter if it's even miss
	-- as long as this function is called
	for i, v in ipairs(Sen.Event.Note) do
		v.Count = v.Count + 1
		
		if v.Count == v[1] then
			Sen.AttemptToTrigger(v)
			v.Count = 0
		end
	end
	
	-- For perfect-based, accuracy must be 1
	if accuracy == 1 then
		for i, v in ipairs(Sen.Event.Perfect) do
			v.Count = v.Count + 1
			
			if v.Count == v[1] then
				Sen.AttemptToTrigger(v)
				v.Count = 0
			end
		end
	end
end

function Sen.DrawBackground(bg)
	DrawObject(bg[0])
	DrawObject(bg[1], -88, 0)
	DrawObject(bg[2], 960, 0)
	DrawObject(bg[3], 0, -43)
	DrawObject(bg[4], 0, 640)
end

function Initialize()
	AllowComboCheer()
	Sen.ET = -GetLiveSimulatorDelay()
	Sen.Event.Initialize(Sen.ET)
	
	Sen.BG = Sen.LoadBackgroundID(10)
	Sen.Navi[2] = LoadImage("650Ako-Udagawa-Cool-khEW7J.png")
	Sen.Navi[4] = LoadImage("648Lisa-Imai-Happy-b2isLo.png")
	Sen.Navi[5] = LoadImage("647Yukina-Minato-Cool-LY3Cbq.png")
	Sen.Navi[6] = LoadImage("649Sayo-Hikawa-Power-Cppbqj.png")
	Sen.Navi[8] = LoadImage("646Rinko-Shirokane-Cool-aChlO9.png")
	
	Sen.Sh1h = LoadShader(GaussianBlur)
	Sen.Sh1h:send("direction", {2, 0})
	Sen.Sh1v = LoadShader(GaussianBlur)
	Sen.Sh1v:send("direction", {0, 1})
	Sen.Sh2 = LoadShader [[
		/*
		#ifdef GL_ES
		#ifdef GL_FRAGMENT_PRECISION_HIGH
		precision highp float;
		#else
		precision mediump float;
		#endif	// GL_FRAGMENT_PRECISION_HIGH
		#endif	// GL_ES
		*/

		#define size love_ScreenSize.xy
		extern int samples; // pixels per axis; higher = bigger glow, worse performance
		extern float quality; // lower = smaller glow, better quality
		extern float strength;

		vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
		{
		  vec4 source = Texel(tex, tc);
		  vec4 sum = vec4(0.0);
		  int diff = (samples - 1) / 2;
		  vec2 sizeFactor = vec2(1.0) / size * quality;
		  
		  for (int x = -diff; x <= diff; x++)
		  {
			for (int y = -diff; y <= diff; y++)
			{
			  vec2 offset = vec2(x, y) * sizeFactor;
			  sum += Texel(tex, tc + offset);
			}
		  }
		  
		  return mix(source, ((sum / vec4(samples * samples)) + source), strength) * colour;
		}
	]]
	Sen.Sh1AddMul = -1	-- -1 = decrease, 1 = increase, 0 = stay
	Sen.LNBlurCount = 0
	Sen.LNBlurMul = 0	-- 1 = on, 0 = off
	Sen.Sh1Strength = 0
	Sen.Sh2Strength = 0
	Sen.Sh2:send("samples", 3)
	Sen.Sh2:send("quality", 0.75)
	SetPostProcessingShader(Sen.Sh1h, Sen.Sh1v, Sen.Sh2)
	
	Sen.TimePoints = {
		{BeatToTime(1, 1, 0), Sen.SetBloom},
		{BeatToTime(9, 1, 0), Sen.EnableLNBlur},
		{BeatToTime(14, 4, 0), Sen.DisableLNBlur},
		{BeatToTime(15, 1, 0), Sen.SetBlurAndBloom},
		{BeatToTime(17, 1, 0), Sen.SetBlurAndBloom},
		{BeatToTime(17, 1, 72), Sen.SetBlurAndBloom},
		{BeatToTime(17, 2, 48), Sen.SetBlurAndBloom},
		{BeatToTime(19, 1, 0), Sen.SetBlurAndBloom},
		{BeatToTime(22, 3, 0), Sen.BlurOn},
		{BeatToTime(22, 4, 0), Sen.BlurOff},
		{BeatToTime(25, 1, 0), Sen.SetBlurAndBloom},
		{BeatToTime(25, 1, 72), Sen.SetBlurAndBloom},
		{BeatToTime(25, 2, 48), Sen.SetBlurAndBloom},
		{BeatToTime(27, 1, 0), Sen.SetBlurAndBloom},
		{BeatToTime(31, 1, 0), Sen.SetBlurAndBloom},
		{BeatToTime(31, 1, 0), Sen.EnableLNBlur},
		{BeatToTime(31, 1, 0), Sen.DisableLNBlur},
		{BeatToTime(40, 1, 0), Sen.EnableLNBlur},
		{BeatToTime(43, 3, 0), Sen.BlurOn},
		{BeatToTime(43, 4, 0), Sen.BlurOff},
		{BeatToTime(57, 1, 0), Sen.DisableLNBlur},
	}
	for i = 5, 8 do
		Sen.TimePoints[#Sen.TimePoints + 1] = {BeatToTime(i, 1, 0), Sen.SetBloom}
		Sen.TimePoints[#Sen.TimePoints + 1] = {BeatToTime(i, 1, 0), Sen.BlurOn}
		Sen.TimePoints[#Sen.TimePoints + 1] = {BeatToTime(i, 2, 0), Sen.SetBloom}
		Sen.TimePoints[#Sen.TimePoints + 1] = {BeatToTime(i, 2, 0), Sen.BlurOff}
	end
	for i = 0, 96, 24 do
		Sen.TimePoints[#Sen.TimePoints + 1] = {BeatToTime(22, 3, i), Sen.SetBloom}
		Sen.TimePoints[#Sen.TimePoints + 1] = {BeatToTime(43, 3, i), Sen.SetBloom}
	end
	for i = 0, 192, 24 do
		Sen.TimePoints[#Sen.TimePoints + 1] = {BeatToTime(30, 3, i), Sen.SetBloom}
	end
	for i = 48, 192, 24 do
		Sen.TimePoints[#Sen.TimePoints + 1] = {BeatToTime(34, 2, i), Sen.SetBlurAndBloom}
	end
	
	table.sort(Sen.TimePoints, function(a, b)
		return a[1] < b[1]
	end)
end

function Sen.SetBloom()
	Sen.Sh2Strength = 0.3
end

function Sen.SetBlur()
	Sen.Sh1AddMul = -1
	Sen.Sh1Strength = 0.1
end

function Sen.SetBlurAndBloom()
	Sen.SetBloom()
	Sen.SetBlur()
end

function Sen.BlurOn()
	Sen.Sh1AddMul = 1
end

function Sen.BlurOff()
	Sen.Sh1AddMul = -1
end

function Sen.EnableLNBlur()
	Sen.LNBlurMul = 1
end

function Sen.DisableLNBlur()
	Sen.LNBlurMul = 0
	
	if Sen.LNBlurCount > 0 then
		Sen.SetBlur()
		Sen.LNBlurCount = 0
	end
end

function Update(deltaT)
	local timed = Sen.TimePoints[1]
	Sen.ET = Sen.ET + deltaT
	
	if Sen.ET >= 0 then
		while timed and Sen.ET >= timed[1] do
			table.remove(Sen.TimePoints, 1)
			timed[2]()
			timed = Sen.TimePoints[1]
		end
	end
	
	local dt = deltaT * 0.001
	Sen.Sh1Strength = Sen.Sh1Strength + Sen.Sh1AddMul * dt
	Sen.Sh2Strength = math.max(Sen.Sh2Strength - dt, 0)
	
	if Sen.Sh1Strength >= 0.1 then
		Sen.Sh1Strength = 0.1
		Sen.Sh1AddMul = 0
	elseif Sen.Sh1Strength <= 0 then
		Sen.Sh1Strength = 0
		Sen.Sh1AddMul = 0
	end
	
	Sen.Sh1h:send("strength", Sen.Sh1Strength * 10)
	Sen.Sh1v:send("strength", Sen.Sh1Strength * 10)
	Sen.Sh2:send("strength", Sen.Sh2Strength * 4)
	Sen.DrawBackground(Sen.BG)
	
	-- For timed-based, wrap the elapsed time
	if not(IsLiveEnded()) then
		deltaT = deltaT * 0.001
		
		for i, v in ipairs(Sen.Event.Timed) do
			v.ET = v.ET + deltaT
			
			if v.ET >= v[1] then
				v.ET = v.ET - v[1]
				Sen.AttemptToTrigger(v)
			end
		end
	end
end

function OnNoteTap(pos, accuracy)
	return Sen.NoteHandler(accuracy)
end

function OnLongNoteTap(rel, pos, accuracy)
	--if rel then Sen.Sh1Strength = 0.25 end
	if Sen.LNBlurMul > 0 then
		if rel then
			Sen.LNBlurCount = Sen.LNBlurCount - 1
			if Sen.LNBlurCount == 0 then
				Sen.BlurOff()
				Sen.SetBloom()
			end
		else
			Sen.LNBlurCount = Sen.LNBlurCount + 1
			if Sen.LNBlurCount == 1 then
				Sen.BlurOn()
				Sen.SetBloom()
			end
		end
	end
	
	return Sen.NoteHandler(accuracy)
end


