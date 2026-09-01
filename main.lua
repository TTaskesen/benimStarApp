-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local sahne_degis = require( "composer" )
local oyunKayit = require("oyun_kayit")

display.setStatusBar(display.HiddenStatusBar)

--random sayı üretme tohumu oluştur
math.randomseed(os.time())

--oyuna ses kanalı açmak
audio.reserveChannels( 3 )

--genel ses düzeyini ayarlama
local kayit = oyunKayit.load()
local sesSeviyesi = kayit.soundEnabled and 0.5 or 0
audio.setVolume( sesSeviyesi, { channel = 1 })
audio.setVolume( sesSeviyesi, { channel = 2 })
audio.setVolume( sesSeviyesi, { channel = 3 })

local function uygulamaOlayi(event)
	if event.type == "applicationSuspend" or event.type == "applicationExit" then
		oyunKayit.saveCurrent()
	end
	return true
end

Runtime:addEventListener("system", uygulamaOlayi)

--menu ekranına git
sahne_degis.gotoScene( "menu")
