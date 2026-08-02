local sahne_degis = require( "composer" )

local scene = sahne_degis.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------


--başlangıç verileri
local json = require("json")
local skorTablosu = {}
local yuksekSkorSes

local dosyayolu = system.pathForFile("skor.json", system.DocumentsDirectory)

local function skoruYukle()
    local dosya = io.open(dosyayolu, "r" ) -- r okuma işlemi yapar
    if dosya then
        local baglam = dosya:read("*a")
        io.close(dosya)
        if (baglam and baglam ~= "") then
            skorTablosu = json.decode(baglam)
        end
    end
    if (type(skorTablosu) ~= "table" or #skorTablosu == 0) then
        skorTablosu = {0,0,0,0,0,0,0,0,0,0}

    end
end

local function skoruKaydet()
    for i = #skorTablosu,11, -1 do
        table.remove(skorTablosu, i)
    end

    local dosya = io.open (dosyayolu, "w")
    if dosya then
        dosya:write(json.encode(skorTablosu))
        io.close(dosya)
    end
end

local function gotoMenu()
    sahne_degis.gotoScene( "menu", { time = 800, effect = "crossFade"})
end


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
    skoruYukle()

    --kaydedilmiş skorları yükleyip son oyundan diğerlerini sileriz
    local finalSkor = sahne_degis.getVariable("finalSkor")
    if finalSkor then
        table.insert(skorTablosu, finalSkor)
        sahne_degis.setVariable("finalSkor", 0)
    end

    --tabloda sıralama yapalım
    local function karsilastir(a,b)
        return a > b
    end
    table.sort(skorTablosu, karsilastir)

    --skoru kaydedelim
    skoruKaydet()

    local arkaPlan = display.newImageRect(sceneGroup, "background1.png", 800, 1400)
    arkaPlan.x = display.contentCenterX
    arkaPlan.y = display.contentCenterY

    local yuksekSkorBaslik = display.newText(sceneGroup, "En Yuksek Skorlar", display.contentCenterX, 100, native.systemFont, 44)
    for i = 1, 10 do
        if (skorTablosu[i]) then
            local yPozisyon = 150 + ( i * 56)

            local rakamSiralamasi = display.newText(sceneGroup, i .. ")", display.contentCenterX - 50, yPozisyon, native.systemFont, 36)
            rakamSiralamasi:setFillColor(0.8)
            rakamSiralamasi.anchorX = 1

            local buSkor = display.newText(sceneGroup, skorTablosu[i], display.contentCenterX - 30, yPozisyon,native.systemFont,36)
            buSkor.anchorX = 0
        end
    end

    local menuButon = display.newText(sceneGroup, "Menu", display.contentCenterX, 810, native.systemFont,44)
    menuButon:setFillColor(0.75, 0.78,1)
    menuButon:addEventListener( "tap", gotoMenu)

    yuksekSkorSes = audio.loadStream("audio/Midnight-Crawlers_Looping.wav")
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
        --müzik
        audio.play( yuksekSkorSes, { channel = 1, loops = -1})

	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
        sahne_degis.removeScene("yuksek_skor")
        audio.stop( 1 )

	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

    audio.dispose(yuksekSkorSes)

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
