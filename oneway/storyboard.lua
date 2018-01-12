local tween = require("tween")
local luafft = require("luafft")
local complex = luafft.complex
local math = math
local lg = love.graphics
local fftdata = {}	-- 4 smoothing
local elapsed_time
local shader
local bg10
local note_remain_counter = 23	-- 25 tap notes = switch
local update_multipler = -1

-- Tween animation: background inverted
local bgboom = {opacity = 255}
bgboom.tween = tween.new(1000, bgboom, {opacity = 0})
bgboom.tween:update(1001)

-- Tween animation: circle frequency
local fftidx = {5, 8, 11, 14, 17, 20, 23, 26, 29}
local colidx = {}
local circfreq = {
	rot = {
		0.5 * math.pi,
		0.625 * math.pi,
		0.75 * math.pi,
		0.875 * math.pi,
		math.pi,
		-0.875 * math.pi,
		-0.75 * math.pi,
		-0.625 * math.pi,
		-0.5 * math.pi,
	}
}
circfreq.tween = tween.new(1000, circfreq, {rot = {
	-0.5 * math.pi, -0.625 * math.pi, -0.75 * math.pi, -0.875 * math.pi,
	math.pi, 0.875 * math.pi, 0.75 * math.pi, 0.625 * math.pi, 0.5 * math.pi
}}, "inOutCubic")

local function getAudioFreq(freq_idx)
	local r = ((
		fftdata[1][freq_idx] +
		fftdata[2][freq_idx] +
		fftdata[3][freq_idx] +
		fftdata[4][freq_idx] )
		* complex.new(0.25, 0))
	
	return math.sqrt(r[1] * r[1] + r[2] * r[2])
end

function Initialize()
	elapsed_time = -GetLiveSimulatorDelay()
	bg10 = LoadDEPLS2Image("assets/image/background/liveback_10.png")
	shader = lg.newShader [[
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
		{
			vec4 c = Texel(texture, texture_coords) * color;
			return vec4(1.0 - c.rgb, c.a);
		}
	]]
	
	-- Initialize to empty FFT
	local emptydata = {}
	
	-- FFT size 64
	for i = 1, 64 do
		emptydata[i] = complex.new(0, 0)
	end
	
	fftdata[1] = emptydata
	fftdata[2] = emptydata
	fftdata[3] = emptydata
	fftdata[4] = emptydata
	
	-- Pre-calculate color
	for i = 1, 9 do
		local r, g, b = HSL(255 / 9 * i, 255, 127)
		colidx[i] = {r, g, b, 127}
	end
end

function Update(deltaT)
	elapsed_time = elapsed_time + deltaT
	
	-- Update FFT
	do
		local sample = GetCurrentAudioSample(64)
		local divide2 = complex.new(0.5, 0)
		local left = {}
		local right = {}
		local res = {}
		
		for i = 1, 64 do
			left[i] = complex.new(sample[i][1], 0)
			right[i] = complex.new(sample[i][2], 0)
		end
		
		local fftleft = luafft.fft(left)
		local fftright = luafft.fft(right)
		
		for i = 1, 64 do
			res[i] = (fftleft[i] + fftright[i]) * divide2
		end
		
		fftdata[1] = fftdata[2]
		fftdata[2] = fftdata[3]
		fftdata[3] = fftdata[4]
		fftdata[4] = res
	end
	
	-- Inverted background
	lg.setColor(255, 255, 255)
	lg.draw(bg10)
	do
		bgboom.tween:update(deltaT)
		SetBackgroundDimOpacity(bgboom.opacity)
		
		lg.setColor(255, 255, 255, bgboom.opacity)
		lg.setShader(shader)
		lg.draw(bg10)
		lg.setShader()
	end
	
	-- Draw freq
	lg.setColor(511, 511, 511)
	
	if elapsed_time >= 0 then
		if elapsed_time > 5000 then
			elapsed_time = elapsed_time - 5000
		end
		
		circfreq.tween:update(deltaT * update_multipler)
		
		lg.push()
		lg.translate(480, 160)
		for i = 1, 9 do
			local lvl = 10 * math.log10(getAudioFreq(fftidx[i])) + 80
			local angle = circfreq.rot[i]
			
			if lvl == -math.huge then
				lvl = 63
			end
			
			lg.setColor(unpack(colidx[i]))
			lg.circle("fill",
				math.sin(angle) * 400,
				math.abs(math.cos(angle) * 400),
				math.max(10 * math.log10(getAudioFreq(fftidx[i])) + 82, 63)
			)
		end
		lg.pop()
	end
end

function OnNoteTap()
	-- For every note tap, decrease the note remain by 1
	note_remain_counter = note_remain_counter - 1
	
	if note_remain_counter == 0 then
		bgboom.tween:reset()
		
		update_multipler = update_multipler * -1
		note_remain_counter = 23
	end
end

OnLongNoteTap = OnNoteTap
