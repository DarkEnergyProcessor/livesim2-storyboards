local love = love
local tween = require("tween")
local Data = {Font1 = LoadFont(nil, 24), Font2 = LoadFont(nil, 16)}
local ElapsedTime

local Lyrics = {	-- Time, Kanji, Romaji
	{320, "çž¬ãç™½ã«æº¶ã‹ã—ã¦æ¶ˆãˆã‚†ã", "Matataku shiro ni tokashite kie yuku"},
	{13610, "ç‹¬ã‚Šã½ã¤ã‚Šã¨æ¯ã‚’æŸ“ã‚ã¦", "Hitori potsuri to iki o somete"},
	{23890, "ç©ºã«è½ã¡ãŸ", "Sora ni ochita"}, {29350, "", ""},
	
	{41500, "ç…Œãå¤œã«å¹ã‹ã‚Œã¦æ¶ˆãˆã‚†ã", "Kirameku yoru ni fuka rete kie yuku"},
	{54780, "è‰²ã‚’å¤±ãã—ã¦æ„å‘³ã‚’çŸ¥ã£ãŸ", "Iro o nakushite imi o shitta"},
	{65140, "é€æ˜Žã«", "Tomei ni"},
	
	{68570, "æŒ¯ã‚Šç©ã‚€ç™½ã«æŸ“ã¾ã‚‹", "Furi tsumu shiro ni somaru"}, {75000, "", ""},
	{75960, "ä¸–ç•ŒãŒãŸã ç§ã‚’åŒ…ã‚€", "Sekai ga tada watashi o tsutsumu"},
	{82820, "I fall into night", ""},
	{85280, "ã¾ã å¤œã¯ç¶šã", "Mada yoru wa tsudzuku"}, {88710, "", ""},
	{90000, "Weisser Schnee", ""},
	{92140, "é€æ˜Žã«æŸ“ã¾ã‚‹", "Tomei ni somaru"},
	{97070, "", ""}
}

local Breakdowns = {1710, 
	29140, 30850, 31710, 32570, 34280, 35140, 36000, 37710, 38570, 39420, 41140, 42000,
	63420, 63850, 64280, 64710, 65140, 65570, 66000, 66420,
	66850, 67070, 67280, 67500, 67710, 67920, 68140, 68250, 68350, 68460, 68570
}

for i = 70280, 111550, 60000 / 140 do
	Breakdowns[#Breakdowns + 1] = math.floor(i)
end

function Initialize()
	SetBackgroundDimOpacity(255)
	ElapsedTime = -GetLiveSimulatorDelay()
	
	Data.LyricsInfo = {Opacity = 0, Text1 = "", Text2 = ""}
	Data.LyricsTween = tween.new(300, Data.LyricsInfo, {Opacity = 255})
	Data.BreakdownInfo = {Opacity = 127, Dim = 190}
	Data.BreakdownTween = tween.new(375, Data.BreakdownInfo, {Opacity = 0, Dim = 190})
	Data.Background = GetCurrentBackgroundImage(0)
	Data.BloomShader = love.graphics.newShader[[
#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif	// GL_FRAGMENT_PRECISION_HIGH
#endif	// GL_ES

extern vec2 size;
extern int samples; // pixels per axis; higher = bigger glow, worse performance
extern float quality; // lower = smaller glow, better quality

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
  
  return ((sum / vec4(samples * samples)) + source) * colour;
}
]]
	Data.BreakdownTween:update(500)
	
	Data.BloomShader:send("size", {960, 640})
	
	if IsRenderingMode() then
		print("Render mode quality")
		Data.BloomShader:send("samples", 5)
		Data.BloomShader:send("quality", 4)
	else
		Data.BloomShader:send("samples", 2)
		Data.BloomShader:send("quality", 2)
	end
end

function Update(deltaT)
	ElapsedTime = ElapsedTime + deltaT
	
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(Data.Background, 0, 0, 0, 960 / 2124, 640 / 1416)
	
	local brd = Breakdowns[1]
	if brd and ElapsedTime >= brd then
		table.remove(Breakdowns, 1)
		Data.BreakdownTween:reset()
	end
	
	if Data.BreakdownTween:update(deltaT) == false then
		love.graphics.setColor(0, 0, 0, Data.BreakdownInfo.Dim)
		love.graphics.rectangle("fill", 0, 0, 960, 640)
		love.graphics.setShader(Data.BloomShader)
		love.graphics.setColor(255, 255, 255, Data.BreakdownInfo.Opacity)
		love.graphics.draw(Data.Background, 0, 0, 0, 960 / 2124, 640 / 1416)
		love.graphics.setShader()
	else
		love.graphics.setColor(0, 0, 0, 190)
		love.graphics.rectangle("fill", 0, 0, 960, 640)
	end
	
	local lyr = Lyrics[1]
	if lyr and ElapsedTime >= lyr[1] then
		Data.LyricsInfo.Text1 = lyr[2]
		Data.LyricsInfo.Text2 = lyr[3]
		
		Data.LyricsTween:reset()
		table.remove(Lyrics, 1)
	end
	
	Data.LyricsTween:update(deltaT)
	
	love.graphics.setFont(Data.Font1)
	love.graphics.setColor(0, 0, 0, Data.LyricsInfo.Opacity)
	love.graphics.print(Data.LyricsInfo.Text1, 8, 592)
	love.graphics.setColor(255, 255, 255, Data.LyricsInfo.Opacity)
	love.graphics.print(Data.LyricsInfo.Text1, 6, 590)
	
	love.graphics.setFont(Data.Font2)
	love.graphics.setColor(0, 0, 0, Data.LyricsInfo.Opacity)
	love.graphics.print(Data.LyricsInfo.Text2, 7, 621)
	love.graphics.setColor(255, 255, 255, Data.LyricsInfo.Opacity)
	love.graphics.print(Data.LyricsInfo.Text2, 6, 620)
end
