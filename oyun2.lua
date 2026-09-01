local sahne_degis = require("composer")
local oyunKayit = require("oyun_kayit")
local safeArea = require("safe_area")

local scene = sahne_degis.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local function gotoMenu()
    oyunKayit.saveCurrent()
    sahne_degis.gotoScene("menu", { time = 800, effect = "crossFade" })
end

local fizikler = require("physics")
fizikler.start()
fizikler.setGravity(0, 0)

--levha resimlerinin alınması
local levhaResimleriAl =
{
    frames =
    {
        { -- 1) asteroid 1
            x = 0,
            y = 0,
            width = 102,
            height = 85
        },
        { -- 2) asteroid 2
            x = 0,
            y = 85,
            width = 90,
            height = 83
        },
        { -- 3) asteroid 3
            x = 0,
            y = 168,
            width = 100,
            height = 97
        },
        { -- 4) gemi
            x = 0,
            y = 265,
            width = 98,
            height = 79
        },
        { -- 5) lazer
            x = 98,
            y = 265,
            width = 14,
            height = 40
        },
    },
}
local resimLevha = graphics.newImageSheet("gameObjects.png", levhaResimleriAl)

--başlangıç verileri
local canlar = 3
local skor = 0
local olum = false
local asteroidTable = {}
local gemi
local oyundonguzamani
local oyunBittiZamanlayici
local tamirZamanlayici
local canMetin
local skorMetin
local bolumMetin
local atesButonu
local bolumGecisZamanlayici
local aktif = true
local yapilanVurus = 0
local hedefVurus = 15
local sesAcik = true

--oyun gruplarının oluşturulması
local arkaPlanGroup --arkaplan resimlerinin gurubu
local anaGroup      -- gemi,asteroid,lazerlerin vb gurubu
local uiGroup       --ara yuz gurubu

local patlamaSesi
local lazerAtesSesi
local muzikYukleme





--kullanıcı arayüzü textin güncellenmesi
local function metniGuncelle()
    canMetin.text = "Canlar: " .. canlar
    skorMetin.text = "Skorunuz: " .. skor
    bolumMetin.text = "Bölüm 2  •  Hedef: " .. yapilanVurus .. "/" .. hedefVurus
end

local asteroidTipleri =
{
    { frame = 1, genislik = 102, yukseklik = 85, renk = {1, 0.3, 0.3} },
    { frame = 2, genislik = 90, yukseklik = 83, renk = {0.3, 1, 0.35} },
    { frame = 3, genislik = 100, yukseklik = 97, renk = {0.35, 0.55, 1} },
}

--hız baştan itibaren giderek artar
local hizCarpani = 1

local function asteroidOlustur()
    local olusmaYeri = math.random(3)
    -- Her giriş yönü kendi meteor şeklini kullanır: sol=1, üst=2, sağ=3.
    local tip = asteroidTipleri[olusmaYeri]

    local yeniAsteroid = display.newImageRect(anaGroup, resimLevha, tip.frame, tip.genislik, tip.yukseklik)
    table.insert(asteroidTable, yeniAsteroid)
    fizikler.addBody(yeniAsteroid, "dynamic", { radius = math.max(tip.genislik, tip.yukseklik) / 2, bounce = 0.8 })
    yeniAsteroid.myName = "asteroid"
    --kırmızı/yeşil/mavi renklendirme
    yeniAsteroid:setFillColor(tip.renk[1], tip.renk[2], tip.renk[3])
    --baştan itibaren hızlı dönüş (torque yerine doğrudan açısal hız)
    yeniAsteroid.angularVelocity = math.random(2, 6) * (math.random(2) == 1 and 1 or -1)

    if (olusmaYeri == 1) then
        --soldan, tamamen ekran dışından oluşma
        yeniAsteroid.x = -tip.genislik - 20
        yeniAsteroid.y = math.random(200, display.contentHeight - 400)
        yeniAsteroid:setLinearVelocity(math.random(40, 120) * hizCarpani, math.random(-40, 40) * hizCarpani)
    elseif (olusmaYeri == 2) then
        --üstten, tamamen ekran dışından oluşma
        yeniAsteroid.x = math.random(display.contentWidth)
        yeniAsteroid.y = -tip.yukseklik - 20
        yeniAsteroid:setLinearVelocity(math.random(-40, 40) * hizCarpani, math.random(40, 120) * hizCarpani)
    else
        --sağdan, tamamen ekran dışından oluşma
        yeniAsteroid.x = display.contentWidth + tip.genislik + 20
        yeniAsteroid.y = math.random(200, display.contentHeight - 400)
        yeniAsteroid:setLinearVelocity(math.random(-120, -40) * hizCarpani, math.random(-40, 40) * hizCarpani)
    end
end

local lazerSoGuk = 300
local sonLazerZamani = 0

local function lazeriAtesle()
    if not aktif or not gemi or not gemi.parent then return true end
    local simdi = system.getTimer()
    if (simdi - sonLazerZamani) < lazerSoGuk then
        return
    end
    sonLazerZamani = simdi

    --lazer sesi
    audio.play(lazerAtesSesi, { channel = 2 })

    local yeniLazer = display.newImageRect(anaGroup, resimLevha, 5, 14, 40)
    fizikler.addBody(yeniLazer, "dynamic", { isSensor = true })
    yeniLazer.isBullet = true
    yeniLazer.myName = "lazer"

    yeniLazer.x = gemi.x
    yeniLazer.y = gemi.y
    yeniLazer:toFront()

    transition.to(yeniLazer, {
        y = -40,
        time = 500,
        onComplete = function()
            if yeniLazer.parent then
                display.remove(yeniLazer)
            end
        end
    })
end

local function hareketGemi(event)
    local gemi = event.target
    local faz = event.phase
    --dokunma odaklanması
    if ("began" == faz) then
        --dokunma odaklanması
        display.currentStage:setFocus(gemi)
        --başlangıç ofset pozisyonu
        gemi.touchOffsetX = event.x - gemi.x
        --gemi.touchOffset = event.y - gemi.y
    elseif ("moved" == faz) then
        -- Bazı cihazlar/fokus değişimlerinde ilk gelen olay "moved" olabilir.
        -- Ofset yoksa bu hareketi başlangıç noktası kabul ederek çökmeden devam et.
        if gemi.touchOffsetX == nil then
            gemi.touchOffsetX = event.x - gemi.x
        end
        local yariGenislik = gemi.contentWidth / 2
        local gorunurSol = (display.contentWidth - display.viewableContentWidth) / 2 + yariGenislik
        local gorunurSag = (display.contentWidth + display.viewableContentWidth) / 2 - yariGenislik
        gemi.x = math.max(gorunurSol, math.min(gorunurSag, event.x - gemi.touchOffsetX))
        --gemi.y= event.y - gemi.touchOffsetY
    elseif ("ended" == faz or "cancelled" == faz) then
        --odaklanmanın boşa çıkması
        display.currentStage:setFocus(nil)
    end
    return true
end

local function oyunDongu()
    if not aktif then return end
    --hız baştan itibaren giderek artar
    hizCarpani = hizCarpani + 0.05
    --yeni asteroid fonksiyonunu çağır
    asteroidOlustur()
    for i = #asteroidTable, 1, -1 do
        local buAsteroid = asteroidTable[i]
        if (buAsteroid.x < -200 or
                buAsteroid.x > display.contentWidth + 200 or
                buAsteroid.y < -200 or
                buAsteroid.y > display.contentHeight + 200)
        then
            display.remove(buAsteroid)
            table.remove(asteroidTable, i)
        end
    end
end

local function gemiTamir()
    if not gemi or not gemi.parent then return end
    gemi.isBodyActive = false
    gemi.x = display.contentCenterX
    gemi.y = display.contentHeight - 100

    transition.to(gemi, {
        alpha = 1,
        time = 4000,
        onComplete = function()
            gemi.isBodyActive = true
            olum = false
        end
    })
end

local function oyun2Bitti()
    if not aktif then return end
    aktif = false
    oyunKayit.clear()
    sahne_degis.setVariable("finalSkor", skor)
    sahne_degis.gotoScene("yuksek_skor", { time = 800, effect = "crossFade" })
end

local function bolumTamamlandi()
    if not aktif then return end
    aktif = false
    bolumMetin.text = "Bölüm tamamlandı!"
    local kayit = { version = 1, valid = true, score = skor, level = 3, lives = 5, progress = 0, soundEnabled = sesAcik }
    oyunKayit.save(kayit)
    bolumGecisZamanlayici = timer.performWithDelay(1200, function()
        sahne_degis.setVariable("devamKaydi", kayit)
        sahne_degis.gotoScene("oyun3", { time = 800, effect = "crossFade" })
    end)
end

local function carpisma(event)
    if not aktif then return end
    if (event.phase == "began") then
        local obj1 = event.object1
        local obj2 = event.object2
        if ((obj1.myName == "lazer" and obj2.myName == "asteroid") or
                (obj1.myName == "asteroid" and obj2.myName == "lazer"))
        then
            display.remove(obj1)
            display.remove(obj2)

            --patlama sesi
            audio.play(patlamaSesi, { channel = 3 })

            for i = #asteroidTable, 1, -1 do
                if (asteroidTable[i] == obj1 or asteroidTable[i] == obj2) then
                    table.remove(asteroidTable, i)
                    break
                end
            end
            skor = skor + 100
            yapilanVurus = yapilanVurus + 1
            metniGuncelle()
            oyunKayit.saveCurrent()
            if yapilanVurus >= hedefVurus then bolumTamamlandi() end
        elseif ((obj1.myName == "gemi" and obj2.myName == "asteroid") or
                (obj1.myName == "asteroid" and obj2.myName == "gemi"))

        then
            if (olum == false) then
                olum = true

                --patlama sesi
                audio.play(patlamaSesi, { channel = 3 })

                --canı güncelle
                canlar = canlar - 1
                canMetin.text = "Canlar: " .. canlar
                if canlar > 0 then oyunKayit.saveCurrent() end
                if canlar == 1 then
                    gemi:setFillColor(1, 0, 0)
                end
                if (canlar == 0) then
                    display.remove(gemi)
                    oyunBittiZamanlayici = timer.performWithDelay(2000, oyun2Bitti)
                else
                    gemi.alpha = 0
                    tamirZamanlayici = timer.performWithDelay(1000, gemiTamir)
                end
            end
        end
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)
    local sceneGroup = self.view
    local devamKaydi = sahne_degis.getVariable("devamKaydi")
    sahne_degis.setVariable("devamKaydi", nil)
    local aktarilanSkor = sahne_degis.getVariable("aktarilanSkor")
    sahne_degis.setVariable("aktarilanSkor", nil)
    if type(devamKaydi) == "table" and devamKaydi.level == 2 then
        skor = devamKaydi.score or 0
        canlar = devamKaydi.lives or 5
        yapilanVurus = math.min(devamKaydi.progress or 0, hedefVurus - 1)
        sesAcik = devamKaydi.soundEnabled ~= false
    else
        skor = aktarilanSkor or 0
        canlar = aktarilanSkor and 5 or 3
        sesAcik = oyunKayit.load().soundEnabled
    end
    if type(devamKaydi) ~= "table" or devamKaydi.level ~= 2 then yapilanVurus = 0 end
    aktif = true
    oyunKayit.setProvider(function()
        return { version = 1, valid = aktif or bolumGecisZamanlayici ~= nil, score = skor, level = 2, lives = canlar, progress = yapilanVurus, soundEnabled = sesAcik }
    end)

    fizikler.pause()

    arkaPlanGroup = display.newGroup()
    sceneGroup:insert(arkaPlanGroup)
    anaGroup = display.newGroup()
    sceneGroup:insert(anaGroup)
    uiGroup = display.newGroup()
    sceneGroup:insert(uiGroup)

    local arkaPlan = display.newImageRect(arkaPlanGroup, "background.png", 800, 1400)
    arkaPlan.x = display.contentCenterX
    arkaPlan.y = display.contentCenterY

    --geminin yüklenmesi
    gemi = display.newImageRect(anaGroup, resimLevha, 4, 98, 79)
    gemi.x = display.contentCenterX
    gemi.y = display.contentHeight - 100
    fizikler.addBody(gemi, { radius = 30, isSensor = true })
    gemi.myName = "gemi"
    gemi:setFillColor(0, 0, 1)

    local left, top, width, height = safeArea.bounds()
    canMetin = display.newText(uiGroup, "", left + 12, top + 48, native.systemFont, 26)
    canMetin.anchorX = 0
    skorMetin = display.newText(uiGroup, "", left + width - 12, top + 48, native.systemFont, 22)
    skorMetin.anchorX = 1
    bolumMetin = display.newText(uiGroup, "", left + width * 0.5, top + 92, native.systemFont, 20)
    local geriButon = display.newRoundedRect(uiGroup, left + 58, top + 92, 100, 52, 14)
    geriButon:setFillColor(0.16, 0.24, 0.38, 0.92)
    geriButon:addEventListener("tap", gotoMenu)
    local geriMetin = display.newText(uiGroup, "Geri", geriButon.x, geriButon.y, native.systemFont, 24)
    geriMetin:addEventListener("tap", gotoMenu)
    atesButonu = display.newRoundedRect(uiGroup, left + width - 78, top + height - 70, 132, 64, 16)
    atesButonu:setFillColor(0.55, 0.16, 0.18, 0.95)
    atesButonu:addEventListener("tap", lazeriAtesle)
    local atesMetin = display.newText(uiGroup, "ATEŞ", atesButonu.x, atesButonu.y, native.systemFont, 26)
    atesMetin:addEventListener("tap", lazeriAtesle)

    metniGuncelle()

    gemi:addEventListener("touch", hareketGemi)

    patlamaSesi = audio.loadSound("audio/explosion.wav")
    lazerAtesSesi = audio.loadSound("audio/fire.wav")
    muzikYukleme = audio.loadStream("audio/80s-Space-Game_Looping.wav")
end

-- show()
function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen
        fizikler.start()
        Runtime:addEventListener("collision", carpisma)
        oyundonguzamani = timer.performWithDelay(500, oyunDongu, 0)

        --start müzik
        audio.play(muzikYukleme, { channel = 1, loops = -1 })
    end
end

-- hide()
function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        if oyundonguzamani then timer.cancel(oyundonguzamani) end
        if oyunBittiZamanlayici then
            timer.cancel(oyunBittiZamanlayici)
            oyunBittiZamanlayici = nil
        end
        if tamirZamanlayici then
            timer.cancel(tamirZamanlayici)
            tamirZamanlayici = nil
        end
        if gemi then
            transition.cancel(gemi)
        end
        display.currentStage:setFocus(nil)
        if bolumGecisZamanlayici then timer.cancel(bolumGecisZamanlayici); bolumGecisZamanlayici = nil end
    elseif (phase == "did") then
        -- Code here runs immediately after the scene goes entirely off screen
        Runtime:removeEventListener("collision", carpisma)
        fizikler.pause()
        audio.stop(1)
        audio.stop(2)
        audio.stop(3)
        sahne_degis.removeScene("oyun2")
    end
end

-- destroy()
function scene:destroy(event)
    local sceneGroup = self.view
    oyunKayit.saveCurrent()
    oyunKayit.setProvider(nil)
    -- Code here runs prior to the removal of scene's view
    --sesi oyundan çıktıktansonra atmak
    audio.stop(1)
    audio.stop(2)
    audio.stop(3)
    if patlamaSesi then audio.dispose(patlamaSesi); patlamaSesi = nil end
    if lazerAtesSesi then audio.dispose(lazerAtesSesi); lazerAtesSesi = nil end
    if muzikYukleme then audio.dispose(muzikYukleme); muzikYukleme = nil end
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
