local width = 312
local height = 176

local backgroundFile = '/Background.png'

local buttons = {
	{File = '/A.png', Pos = {189, 88}, Size = {60,60} },
	{File = '/b-button.png', Pos = {141, 123}, Size = {37,37} },
	{File = '/X.png', Pos = {266, 81}, Size = {35,63} },
	{File = '/Y.png', Pos = {177, 44}, Size = {63,37} },
	{File = '/Start.png', Pos = {121, 71}, Size = {24,24} },
	{File = '/R.png', Pos = {25, 4}, Size = {111,20} },
	{File = '/R.png', Pos = {170, 4}, Size = {111,20} },
--	{File = '/R.png', Pos = {500, 6}, Size = {110,20} },
--	{File = '/R.png', Pos = {500, 6}, Size = {110,20} },
	{File = '/Z.png', Pos = {254, 34}, Size = {52,26} }
}

local analogMarkers = {
	{File = '/Stick.png', Pos = {21, 68}, Size = {74,74}, Range = 25 },
	{File = '/cstick.png', Pos = {500, 500}, Size = {45,45}, Range = 31 }
}

local shoulders = {
--	{Color = 0xffffff, Pos = {25, 4}, Size = {110,14} },
--	{Color = 0xffffff, Pos = {170, 4}, Size = {110,14} }
	{Color = 0xffffff, Pos = {500, 500}, Size = {110,14} },
	{Color = 0xffffff, Pos = {500, 500}, Size = {110,14} }}

return {
	width = width,
	height = height,
	backgroundFile = backgroundFile,
	buttons = buttons,
	analogMarkers = analogMarkers,
	shoulders = shoulders
}