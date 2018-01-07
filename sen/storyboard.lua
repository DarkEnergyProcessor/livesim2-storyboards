-- Poppin' Party - Senbonzakura
assert(DEPLS_VERSION_NUMBER >= 01010503, "Live Simulator: 2 version not compatible. Disable storyboard!")

local Sen = {Event = {}}
local dummy = function() return false end

-- TODO this function in Live Simulator: 2
SetRedTimingDuration = SetRedTimingDuration or dummy
AddScore = AddScore or dummy
IsRandomMode = IsRandomMode or dummy
IsLiveEnded = IsLiveEnded or dummy

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

-- Timer-based event
Sen.Event.Timed = {
	-- {Second, Chance, Callback}
	{14, 40, function()
		return SkillPopup(2, "blue", "healer", Sen.Navi[2], "UR")
	end}
}

-- Note-based event
Sen.Event.Note = {
	-- {Notes, Chance, Callback}
	{40, 38, function()
		AddScore(920)
		return SkillPopup(8, "green", "score_up", Sen.Navi[8], "UR")
	end},
	{31, 36, function()
		SetRedTimingDuration(2500)
		return SkillPopup(6, "red", "tw++", Sen.Navi[6], "SR")
	end}
}

-- Perfect-based event
Sen.Event.Perfect = {
	-- {Perfect, Chance, Callback}
	{29, 70, function()
		SetRedTimingDuration(5000)
		return SkillPopup(5, "red", "tw++", Sen.Navi[5], "UR")
	end},
	{20, 32, function()
		AddScore(420)
		return SkillPopup(4, "green", "score_up", Sen.Navi[4], "SR")
	end}
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
	
	Sen.BG = Sen.LoadBackgroundID(IsRandomMode() and 12 or 11)
	Sen.Navi[2] = LoadImage("616Rimi-Ushigome-Happy-sWiNjI.png")
	Sen.Navi[4] = LoadImage("619Kasumi-Toyama-Pure-Utszgc.png")
	Sen.Navi[5] = LoadImage("618Tae-Hanazono-Power-8bAHL2.png")
	Sen.Navi[6] = LoadImage("620Arisa-Ichigaya-Power-svPvYl.png")
	Sen.Navi[8] = LoadImage("617Saaya-Yamabuki-Power-a3gTXJ.png")
end

function Update(deltaT)
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
	return Sen.NoteHandler(accuracy)
end
