-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local sahne_degis = require( "composer" )

display.setStatusBar(display.HiddenStatusBar)

--random sayı üretme tohumu oluştur
math.randomseed(os.time())

--oyuna ses kanalı açmak
audio.reserveChannels( 3 )

--genel ses düzeyini ayarlama
audio.setVolume( 0.5, { channel = 1 })
audio.setVolume( 0.5, { channel = 2 })
audio.setVolume( 0.5, { channel = 3 })

--menu ekranına git
sahne_degis.gotoScene( "menu")