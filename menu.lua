local sahne_degis = require("composer")

local scene = sahne_degis.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------


local function gotoOyun2()
	sahne_degis.gotoScene("oyun2", { time = 800, effect = "crossFade" })
end

local function gotoOyun()
	sahne_degis.gotoScene("oyun", { time = 800, effect = "crossFade" })
end

local function gotoYuksekSkor()
	sahne_degis.gotoScene("yuksek_skor", { time = 800, effect = "crossFade" })
end

--menu sesi yükleme
local menuSesi
local basla_buton
local ayar
local sesAcik = true

local function baslaButonuBagla()
	if basla_buton then
		basla_buton:removeEventListener("tap", gotoOyun2)
		basla_buton:removeEventListener("tap", gotoOyun)
		if oyunBitti then
			basla_buton:addEventListener("tap", gotoOyun2)
		else
			basla_buton:addEventListener("tap", gotoOyun)
		end
	end
end

local function sesiDegistir()
	sesAcik = not sesAcik
	local seviye = 0
	if sesAcik then
		seviye = 0.5
	end
	audio.setVolume(seviye, { channel = 1 })
	audio.setVolume(seviye, { channel = 2 })
	audio.setVolume(seviye, { channel = 3 })
	if ayar then
		if sesAcik then
			ayar.text = "Ayarlar"
		else
			ayar.text = "Ses Kapalı"
		end
	end
end


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)
	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
	local arkaPlan = display.newImageRect(sceneGroup, "background.png", 800, 1400)
	arkaPlan.x = display.contentCenterX
	arkaPlan.y = display.contentCenterY

	local title = display.newImageRect(sceneGroup, "title.png", 500, 80)
	title.x = display.contentCenterX
	title.y = 200

	basla_buton = display.newText(sceneGroup, "Başla", display.contentCenterX, 700, native.systemFont, 44)
	basla_buton:setFillColor(0.82, 0.86, 1)

	local yuksek_skor_buton = display.newText(sceneGroup, "Yüksek Skor", display.contentCenterX, 810, native.systemFont,
		44)
	yuksek_skor_buton:setFillColor(0.75, 1, 1)

	ayar = display.newText(sceneGroup, "Ayarlar", display.contentCenterX, 900, native.systemFont,
		44)
	ayar:setFillColor(0.75, 1, 1)
	ayar:addEventListener("tap", sesiDegistir)

	yuksek_skor_buton:addEventListener("tap", gotoYuksekSkor)

	menuSesi = audio.loadStream("audio/Escape_Looping.wav")
end

-- show()
function scene:show(event)
	local sceneGroup = self.view
	local phase = event.phase

	if (phase == "will") then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
		baslaButonuBagla()
	elseif (phase == "did") then
		-- Code here runs when the scene is entirely on screen
		--start müzik
		audio.play(menuSesi, { channel = 1, loops = -1 })
	end
end

-- hide()
function scene:hide(event)
	local sceneGroup = self.view
	local phase = event.phase

	if (phase == "will") then
		-- Code here runs when the scene is on screen (but is about to go off screen)
	elseif (phase == "did") then
		-- Code here runs immediately after the scene goes entirely off screen
		audio.stop(1)
	end
end

-- destroy()
function scene:destroy(event)
	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

	audio.dispose(menuSesi)
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)
-- -----------------------------------------------------------------------------------

return scene
