assert(DEPLS_VERSION_NUMBER >= 01010503 and UseZeroToOneColorRange, "Current version of Live Simulator: 2 is not supported. Disable storyboard!")
UseZeroToOneColorRange()		-- LOVE 0.11.0

local tween = require("tween")
local Data = {Font1 = LoadFont(nil, 24), Font2 = LoadFont(nil, 16)}
local ElapsedTime

local Lyrics = {
	-- Format: {Time in ms, Kanji, Romaji}
	{12690, "もうどれくらい季節が経つの", "Mou dorekurai toki ga tatsu no"},
	{17960, "今年もきっと思い出すね", "Kotoshi mo kitto omoidasu ne"},
	{23240, "舞い落ちた一片が頬を伝う", "Mai ochita hitohira ga hoho o tsutau"},
	{28510, "吐息だけが白く滲んだ", "Toiki dake ga shiroku nijinda"},
	
	{33790, "不器用で幼かったね", "Bukiyoude osanakatta ne"},
	{39060, "すれ違いばかりだけど", "Surechigai bakaridakedo"},
	{44340, "それでも二人で笑いあえたから", "Soredemo futari de warai aetakara"},
	{49610, "永遠を信じてたよ", "Eien o shinji teta yo"},
	
	{54390, "ねぇ僕たちが手にいれた自由は", "Ne~e bokutachi ga te ni ireta jiyuu wa"},
	{59830, "こんなにも胸を締め付けるんだよ", "Kon'nanimo mune o shimetsukeru nda yo"},
	{65110, "ねぇ僕たちは生まれてきた事で…", "Ne~e bokutachi wa umarete kita koto de..."},
	{70380, "ねぇ僕たちは巡り逢えた事で…", "Ne~e bokutachi wa meguri aeta koto de..."},
	
	{75650, "ねぇ僕たちが目指していた世界は", "Ne~e bokutachi ga mezashite ita basho wa"},
	{80930, "ひとりでは届かないよ 遠すぎるから", "Hitoride wa todokanai yo to sugirukara"},
	{86260, "僕たち 二人 愛しあえた真実が", "Bokutachi futari aishi aeta shinjitsu ga"},
	{91480, "かけがえのない旅路のしおりだから", "Kakegae no nai tabiji no shioridakara"},
	{97580, "", ""},	-- Stop displaying lyrics
	
	{119170, "どうか願いが叶いますように", "Dou ka negai ga kanaimasu yo ni"},
	{124450, "また君と笑いあえる そんな日々を", "Mata kimi to warai aeru son'na hibi o"},
	{133840, "", ""}
}

function Initialize()
	SetBackgroundDimOpacity(1)
	AllowComboCheer()
	
	Data.BG0 = GetCurrentBackgroundImage(0)
	Data.BG1 = GetCurrentBackgroundImage(1)
	Data.BG2 = GetCurrentBackgroundImage(2)
	Data.LyricsInfo = {Opacity = 0, Text1 = "", Text2 = ""}
	Data.LyricsTween = tween.new(300, Data.LyricsInfo, {Opacity = 1})
	Data.Delay = GetLiveSimulatorDelay()
	ElapsedTime = -Data.Delay
end

function Update(deltaT)
	ElapsedTime = ElapsedTime + deltaT
	
	SetColor(1, 1, 1)
	DrawObject(Data.BG0)
	DrawObject(Data.BG1, -88, 0)
	DrawObject(Data.BG2, 960, 0)
	SetColor(0, 0, 0, math.min((Data.Delay + ElapsedTime) / Data.Delay, 1) * 0.75)
	DrawRectangle("fill", -88, -43, 1136, 726)
	
	local lyr = Lyrics[1]
	if lyr and ElapsedTime >= lyr[1] then
		Data.LyricsInfo.Text1 = lyr[2]
		Data.LyricsInfo.Text2 = lyr[3]
		
		Data.LyricsTween:reset()
		table.remove(Lyrics, 1)
	end
	
	Data.LyricsTween:update(deltaT)
	
	SetFont(Data.Font1)
	SetColor(0, 0, 0, Data.LyricsInfo.Opacity)
	PrintText(Data.LyricsInfo.Text1, 8, 592)
	SetColor(1, 1, 1, Data.LyricsInfo.Opacity)
	PrintText(Data.LyricsInfo.Text1, 6, 590)
	
	SetFont(Data.Font2)
	SetColor(0, 0, 0, Data.LyricsInfo.Opacity)
	PrintText(Data.LyricsInfo.Text2, 7, 621)
	SetColor(1, 1, 1, Data.LyricsInfo.Opacity)
	PrintText(Data.LyricsInfo.Text2, 6, 620)
end
