-- Copied from Roselia - A Cruel Angel Thesis
-- Which is copied from Poppin' Party - Senbonzakura
RequireDEPLSVersion(02010300)

local Sen = {Event = {}}
local fft = require("luafft")

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
	Sen.Event.Initialize(-GetLiveSimulatorDelay())
	Sen.SpectrumOkay = GetLiveUI() == "lovewing" and IsDesktopSystem()
	
	-- Load images
	Sen.BG = Sen.LoadBackgroundID(11)
	Sen.Navi[2] = LoadImage("650Ako-Udagawa-Cool-khEW7J.png")
	Sen.Navi[4] = LoadImage("648Lisa-Imai-Happy-b2isLo.png")
	Sen.Navi[5] = LoadImage("647Yukina-Minato-Cool-LY3Cbq.png")
	Sen.Navi[6] = LoadImage("649Sayo-Hikawa-Power-Cppbqj.png")
	Sen.Navi[8] = LoadImage("646Rinko-Shirokane-Cool-aChlO9.png")
	
	-- Initialize FFT
	-- Canvas is 640x96+160+93
	if Sen.SpectrumOkay then
		Sen.SpectrumCanvas = NewCanvas(840, 384)
		Sen.Spectrum1 = {}
		Sen.Spectrum2 = {}

		local step = (math.log(22050/20) / 512) / math.log(2)

		Sen.BandFreq = {}
		Sen.BandFreq[1] = 20 * math.pow(2, step * 0.5)

		for i = 2, 512 do
			Sen.BandFreq[i] = (Sen.BandFreq[i - 1] * math.pow(2, step))
		end
	end
end

local lc = {}
local rc = {}
local lcn = {}
local rcn = {}
local result_fft = {lcn, rcn}
function Sen.FFTSample(waveform)
	local n = math.floor(#waveform * 0.5)
	for i = 1, #waveform do
		lc[i] = fft.complex.new(waveform[i][1])
		rc[i] = fft.complex.new(waveform[i][2])
	end
	
	local lcfft, rcfft = fft.fft(lc), fft.fft(rc)
	
	for i = 1, n do
		assert(lcfft[i].r, i)
		lcn[i] = math.sqrt(lcfft[i].r * lcfft[i].r + lcfft[i].i * lcfft[i].i) / n
		rcn[i] = math.sqrt(rcfft[i].r * rcfft[i].r + rcfft[i].i * rcfft[i].i) / n
	end
	
	return result_fft
end

local bandout = {{}, {}}
function Sen.ToLogSpace(fftsmp)
	-- Shamelessly stolen from Rainmeter AudioLevel plugin
	-- https://github.com/dcgrace/AudioLevel/blob/master/AudioLevel.cpp#L650
	local df = 44100 / 1024
	local scalar = 2 / 44100
	
	for i = 1, 512 do
		bandout[1][i] = 0
		bandout[2][i] = 0
	end
	
	for iChan = 1, 2 do
		local iBin = 1
		local iBand = 1
		local f0 = 0
		
		while iBin <= 512 and iBand <= 512 do
			local fLin1 = (iBin - 0.5) * df
			local fLog1 = Sen.BandFreq[iBand]
			local x = fftsmp[iChan][iBin]
			
			if fLin1 <= fLog1 then
				bandout[iChan][iBand] = bandout[iChan][iBand] + (fLin1 - f0) * x * scalar
				f0 = fLin1
				iBin = iBin + 1
			else
				bandout[iChan][iBand] = math.max((bandout[iChan][iBand] + (fLog1 - f0) * x * scalar) * 44100)
				f0 = fLog1
				iBand = iBand + 1
			end
		end
	end

	return bandout
end

local function f(i)
	--return math.log(i)/b512 * 0.75
	return 1/(i^(1/640)) * 0.1
end

function Update(deltaT)
	-- Update FFT
	if Sen.SpectrumOkay then
		local spectrum = Sen.ToLogSpace(Sen.FFTSample(GetCurrentAudioSample(1024)))
		SetCanvas(Sen.SpectrumCanvas)
		ClearDrawing()
		SetBlendMode("add")
		
		-- Left
		SetColor(255, 0, 0)
		for i = 1, 512 do
			local xp = (i - 1) / 513 * 640
			DrawEllipse("fill", xp, -48, 17, 96 * spectrum[1][i] * f(i))
			DrawEllipse("line", xp, -48, 17, 96 * spectrum[1][i] * f(i))
		end
		
		--Right
		SetColor(0, 255, 255)
		for i = 1, 512 do
			local xp = (i - 1) / 513 * 640
			DrawEllipse("fill", xp, -48, 17, 96 * spectrum[2][i] * f(i))
			DrawEllipse("line", xp, -48, 17, 96 * spectrum[2][i] * f(i))
		end
		
		-- Reset
		SetBlendMode("alpha", "alphamultiply")
		SetColor(255, 255, 255)
		SetCanvas()
	end
	
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
	
	-- Draw spectrum
	if Sen.SpectrumOkay then
		SetBlendMode("alpha", "premultiplied")
		SetColor(255, 255, 255, 192)
		DrawObject(Sen.SpectrumCanvas, 80, 93)
		SetColor(255, 255, 255)
		SetBlendMode("alpha", "alphamultiply")
		SetShader()
	end
end

function OnNoteTap(pos, accuracy)
	return Sen.NoteHandler(accuracy)
end

function OnLongNoteTap(rel, pos, accuracy)
	return Sen.NoteHandler(accuracy)
end
