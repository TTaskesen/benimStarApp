local sahne_degis = require("composer")
local oyunKayit = require("oyun_kayit")
local safeArea = require("safe_area")
local oyunAyar = require("oyun_ayar")
local oyunMeta = require("oyun_meta")

local scene = sahne_degis.newScene()
local bolumGecisiAktif = false

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local function gotoMenu()
    if bolumGecisiAktif then return true end
    oyunKayit.saveCurrent()
    sahne_degis.gotoScene("menu", { time = 800, effect = "crossFade" })
    return true
end

local fizikler = require("physics")
fizikler.start()
fizikler.setGravity(0, 0)

--levha resimlerinin alınması
local levhaResimleriAl =
{
    frames =
    {
        { x = 0, y = 0, width = 102, height = 85 },
        { x = 0, y = 85, width = 90, height = 83 },
        { x = 0, y = 168, width = 100, height = 97 },
        { x = 0, y = 265, width = 98, height = 79 },
        { x = 98, y = 265, width = 14, height = 40 },
    },
}
local resimLevha = graphics.newImageSheet("gameObjects.png", levhaResimleriAl)

--başlangıç verileri
local canlar = 3
local skor = 0
local olum = false
local gemi
local canMetin
local skorMetin
local bolumMetin
local atesButonu

--oyun gruplarının oluşturulması
local arkaPlanGroup
local anaGroup
local uiGroup

local patlamaSesi
local lazerAtesSesi
local muzikYukleme

local asteroidTable = {}
local meteorAraligi = 650
local sonMeteorZamani = 0
local ayar = oyunAyar.level(3)

local oyunBittiZamanlayici
local tamirZamanlayici
local bolumGecisZamanlayici
local aktif = true
local yapilanVurus = 0
local hedefVurus = ayar.hedef
local atisSayisi = 0
local baslangicCan = 3
local dalgaNo = 1
local dalgaVurus = 0
local combo = 0
local maxCombo = 1
local sonIsabetZamani = 0
local comboPenceresi = 1.5
local geriButon
local geriMetin
local atesMetni
local atesDolumZamanlayici
local ertelenmisHasarTimer
local oncekiKareZamani
local sesAcik = true
local bolumTamamlandi

local lazerSoGuk = 300
local sonLazerZamani = 0

local GEMI_KATEGORI = 1
local METEOR_KATEGORI = 4
local LAZER_KATEGORI = 8

--kullanıcı arayüzü textin güncellenmesi
local function metniGuncelle()
    canMetin.text = "Canlar: " .. canlar
    skorMetin.text = "Skorunuz: " .. skor
    bolumMetin.text = "Bölüm 3 • Meteorları vur • Dalga " .. dalgaNo .. "/" .. ayar.dalgaSayisi .. " • " .. dalgaVurus .. "/" .. ayar.dalgaBasina .. " • " .. combo .. "x"
end

local function dalgaGuncelle()
    dalgaNo = math.min(ayar.dalgaSayisi, math.floor(yapilanVurus / ayar.dalgaBasina) + 1)
    dalgaVurus = yapilanVurus - (dalgaNo - 1) * ayar.dalgaBasina
    if yapilanVurus > 0 and dalgaVurus == 0 then dalgaVurus = ayar.dalgaBasina end
end

local function komboSifirla()
    combo = 0
    metniGuncelle()
end

local function komboGuncelle()
    local simdi = system.getTimer() / 1000
    if simdi - sonIsabetZamani > comboPenceresi then combo = 0 end
    combo = combo + 1
    maxCombo = math.max(maxCombo, combo)
    sonIsabetZamani = simdi
    if combo >= 3 then oyunMeta.unlock("combo_3") end
    return math.min(3, math.floor((combo - 1) / 3) + 1)
end

--zoomEven kırpmasında görünür ekran sınırları
local asteroidTipleri =
{
    { frame = 1, genislik = 102, yukseklik = 85, renk = {1, 0.3, 0.3} },
    { frame = 2, genislik = 90, yukseklik = 83, renk = {0.3, 1, 0.35} },
    { frame = 3, genislik = 100, yukseklik = 97, renk = {0.35, 0.55, 1} },
}

local function meteorOlustur()
    local olusmaYeri = math.random(3)
    -- Her giriş yönü kendi meteor şeklini kullanır: sol=1, üst=2, sağ=3.
    local tip = asteroidTipleri[olusmaYeri]
    local yeniAsteroid = display.newImageRect(anaGroup, resimLevha, tip.frame, tip.genislik, tip.yukseklik)
    table.insert(asteroidTable, yeniAsteroid)
    fizikler.addBody(yeniAsteroid, "dynamic", {
        radius = math.max(tip.genislik, tip.yukseklik) / 2,
        bounce = 0.8,
        filter = { categoryBits = METEOR_KATEGORI, maskBits = GEMI_KATEGORI + LAZER_KATEGORI },
    })
    yeniAsteroid.myName = "asteroid"
    yeniAsteroid:setFillColor(tip.renk[1], tip.renk[2], tip.renk[3])
    yeniAsteroid.angularVelocity = math.random(2, 8) * (math.random(2) == 1 and 1 or -1)

    if olusmaYeri == 1 then
        yeniAsteroid.x = -tip.genislik - 20
        yeniAsteroid.y = math.random(200, display.contentHeight - 400)
        yeniAsteroid:setLinearVelocity(math.random(40, 120), math.random(-40, 40))
    elseif olusmaYeri == 2 then
        yeniAsteroid.x = math.random(display.contentWidth)
        yeniAsteroid.y = -tip.yukseklik - 20
        yeniAsteroid:setLinearVelocity(math.random(-40, 40), math.random(40, 120))
    else
        yeniAsteroid.x = display.contentWidth + tip.genislik + 20
        yeniAsteroid.y = math.random(200, display.contentHeight - 400)
        yeniAsteroid:setLinearVelocity(math.random(-120, -40), math.random(-40, 40))
    end
end

local function lazeriAtesle()
    if not aktif or bolumGecisiAktif or not gemi or not gemi.parent then return true end
    local simdi = system.getTimer()
    if (simdi - sonLazerZamani) < lazerSoGuk then
        return true
    end
    sonLazerZamani = simdi
    atisSayisi = atisSayisi + 1
    if atesButonu then atesButonu.alpha = 0.45 end
    if atesDolumZamanlayici then timer.cancel(atesDolumZamanlayici) end
    atesDolumZamanlayici = timer.performWithDelay(lazerSoGuk, function()
        if atesButonu and atesButonu.parent then atesButonu.alpha = 1 end
        atesDolumZamanlayici = nil
    end)

    --lazer sesi
    audio.play(lazerAtesSesi, { channel = 2 })

    local yeniLazer = display.newImageRect(anaGroup, resimLevha, 5, 14, 40)
    fizikler.addBody(yeniLazer, "dynamic", {
        radius = 7,
        isSensor = true,
        filter = { categoryBits = LAZER_KATEGORI, maskBits = METEOR_KATEGORI },
    })
    yeniLazer.isBullet = true
    yeniLazer.myName = "lazer"

    yeniLazer.x = gemi.x
    yeniLazer.y = gemi.y - 50
    yeniLazer:toFront()

    transition.to(yeniLazer, {
        y = -60,
        time = 700,
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
    if bolumGecisiAktif then return true end
    if ("began" == faz) then
        --dokunma odaklanması
        display.currentStage:setFocus(gemi)
        gemi.touchOffsetX = event.x - gemi.x
        gemi.touchOffsetY = event.y - gemi.y
    elseif ("moved" == faz) then
        -- Bazı cihazlar/fokus değişimlerinde ilk gelen olay "moved" olabilir.
        -- Ofset yoksa bu hareketi başlangıç noktası kabul ederek çökmeden devam et.
        if gemi.touchOffsetX == nil then
            gemi.touchOffsetX = event.x - gemi.x
        end
        if gemi.touchOffsetY == nil then
            gemi.touchOffsetY = event.y - gemi.y
        end
        local yariGenislik = gemi.contentWidth / 2
        local gorunurSol = (display.contentWidth - display.viewableContentWidth) / 2 + yariGenislik
        local gorunurSag = (display.contentWidth + display.viewableContentWidth) / 2 - yariGenislik
        gemi.x = math.max(gorunurSol, math.min(gorunurSag, event.x - gemi.touchOffsetX))
        --y ekseninde de hareket (kamera gemiyi takip eder, dünya kayar)
        local ustSinir = display.contentHeight - 600
        local altSinir = display.contentHeight - 250
        gemi.y = math.max(ustSinir, math.min(altSinir, event.y - gemi.touchOffsetY))
    elseif ("ended" == faz or "cancelled" == faz) then
        display.currentStage:setFocus(nil)
    end
    return true
end

local function oyunDongu(event)
    if not aktif or bolumGecisiAktif then return end
    local simdi = event.time or system.getTimer()
    local dt = oncekiKareZamani and (simdi - oncekiKareZamani) / 1000 or (1 / 60)
    oncekiKareZamani = simdi
    dt = math.max(0.001, math.min(dt, 0.05))
    if combo > 0 and simdi / 1000 - sonIsabetZamani > comboPenceresi then
        komboSifirla()
    end

    if simdi - sonMeteorZamani >= meteorAraligi then
        meteorOlustur()
        sonMeteorZamani = simdi
    end

    for i = #asteroidTable, 1, -1 do
        local asteroid = asteroidTable[i]
        if not asteroid.parent or asteroid.x < -200 or asteroid.x > display.contentWidth + 200 or
                asteroid.y < -200 or asteroid.y > display.contentHeight + 200 then
            display.remove(asteroid)
            table.remove(asteroidTable, i)
        end
    end
end

local function gemiTamir()
    if not gemi then return end
    gemi.isBodyActive = true
    gemi.alpha = 1
    olum = false
end

local function oyun3Bitti()
    if not aktif then return end
    aktif = false
    oyunKayit.clear()
    sahne_degis.setVariable("sonucVeri", { victory = false, score = skor, level = 3, wave = math.max(1, dalgaNo - 1), meteor = yapilanVurus, accuracy = atisSayisi > 0 and math.min(100, math.floor(yapilanVurus / atisSayisi * 100)) or 0, lostLives = baslangicCan - canlar, maxCombo = maxCombo })
    sahne_degis.gotoScene("sonuc", { time = 800, effect = "crossFade" })
end

bolumTamamlandi = function()
    if not aktif then return end
    aktif = false
    bolumGecisiAktif = true
    if geriButon then geriButon.isHitTestable = false; geriButon.alpha = 0.45 end
    if geriMetin then geriMetin.alpha = 0.45 end
    if atesButonu then atesButonu.isHitTestable = false; atesButonu.alpha = 0.45 end
    if atesMetni then atesMetni.alpha = 0.45 end
    bolumMetin.text = "Bölüm tamamlandı!"
    oyunMeta.markLevel4()
    oyunMeta.markWaveCompleted(canlar == baslangicCan)
    local kayit = { version = 1, valid = true, score = skor, level = 4, lives = 5, progress = 0, soundEnabled = sesAcik }
    oyunKayit.save(kayit)
    bolumGecisZamanlayici = timer.performWithDelay(1200, function()
        sahne_degis.setVariable("devamKaydi", kayit)
        sahne_degis.gotoScene("oyun4", { time = 800, effect = "crossFade" })
    end)
end

local function gemiHasar()
    if olum then return end
    olum = true

    --patlama sesi
    audio.play(patlamaSesi, { channel = 3 })

    --canı güncelle
    canlar = canlar - 1
    komboSifirla()
    canMetin.text = "Canlar: " .. canlar
    if canlar > 0 then oyunKayit.saveCurrent() end
    if (canlar <= 0) then
        display.remove(gemi)
        oyunBittiZamanlayici = timer.performWithDelay(2000, oyun3Bitti)
    else
        gemi.alpha = 0.3
        -- isBodyActive çarpışma olayı sırasında (dünya kilitli) set edilemez,
        -- bu yüzden bir sonraki kareye ertelenir
        ertelenmisHasarTimer = timer.performWithDelay(0, function()
            if gemi and gemi.parent then gemi.isBodyActive = false end
            ertelenmisHasarTimer = nil
        end)
        tamirZamanlayici = timer.performWithDelay(1200, gemiTamir)
    end
end

local function carpisma(event)
    if not aktif then return end
    if (event.phase ~= "began") then return end
    local obj1 = event.object1
    local obj2 = event.object2
    local isim1 = obj1.myName
    local isim2 = obj2.myName

    if ((isim1 == "lazer" and isim2 == "asteroid") or (isim1 == "asteroid" and isim2 == "lazer")) then
        local lazer = isim1 == "lazer" and obj1 or obj2
        local asteroid = isim1 == "asteroid" and obj1 or obj2
        if lazer.parent then display.remove(lazer) end
        if asteroid.parent then display.remove(asteroid) end
        for i = #asteroidTable, 1, -1 do
            if asteroidTable[i] == asteroid then
                table.remove(asteroidTable, i)
                break
            end
        end
        audio.play(patlamaSesi, { channel = 3 })
        local carpani = komboGuncelle()
        local puan = 100 * carpani
        skor = skor + puan
        yapilanVurus = yapilanVurus + 1
        dalgaGuncelle()
        metniGuncelle()
        if dalgaVurus == ayar.dalgaBasina and yapilanVurus < hedefVurus then
            bolumMetin.text = "Dalga " .. dalgaNo .. " tamamlandı!"
            oyunMeta.markWaveCompleted(canlar == baslangicCan)
        end
        oyunMeta.record("meteor", 1)
        oyunMeta.record("score", puan)
        oyunKayit.saveCurrent()
        if yapilanVurus >= hedefVurus then bolumTamamlandi() end
    elseif ((isim1 == "gemi" and isim2 == "asteroid") or (isim1 == "asteroid" and isim2 == "gemi")) then
        local asteroid = isim1 == "asteroid" and obj1 or obj2
        if asteroid.parent then display.remove(asteroid) end
        for i = #asteroidTable, 1, -1 do
            if asteroidTable[i] == asteroid then
                table.remove(asteroidTable, i)
                break
            end
        end
        gemiHasar()
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
    if type(devamKaydi) == "table" and devamKaydi.level == 3 then
        skor = devamKaydi.score or 0
        canlar = devamKaydi.lives or 5
        yapilanVurus = math.min(devamKaydi.progress or 0, hedefVurus - 1)
        sesAcik = devamKaydi.soundEnabled ~= false
    else
        skor = aktarilanSkor or 0
        canlar = aktarilanSkor and 5 or 3
        sesAcik = oyunKayit.load().soundEnabled
    end
    if type(devamKaydi) ~= "table" or devamKaydi.level ~= 3 then yapilanVurus = 0 end
    ayar = oyunAyar.level(3)
    hedefVurus = ayar.hedef
    sonLazerZamani = 0
    atisSayisi = 0
    combo = 0
    maxCombo = 1
    sonIsabetZamani = 0
    bolumGecisiAktif = false
    dalgaGuncelle()
    baslangicCan = canlar
    asteroidTable = {}
    sonMeteorZamani = 0
    oncekiKareZamani = nil
    aktif = true
    oyunKayit.setProvider(function()
        return { version = 1, valid = aktif or bolumGecisZamanlayici ~= nil, score = skor, level = 3, lives = canlar, progress = yapilanVurus, soundEnabled = sesAcik }
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
    gemi.y = display.contentHeight - 250
    fizikler.addBody(gemi, {
        radius = 30,
        isSensor = true,
        filter = { categoryBits = GEMI_KATEGORI, maskBits = METEOR_KATEGORI },
    })
    gemi.myName = "gemi"
    gemi:setFillColor(0, 0.6, 1)

    local left, top, width, height = safeArea.bounds()
    canMetin = display.newText(uiGroup, "", left + 12, top + 48, native.systemFont, 26)
    canMetin.anchorX = 0
    skorMetin = display.newText(uiGroup, "", left + width - 12, top + 48, native.systemFont, 22)
    skorMetin.anchorX = 1
    bolumMetin = display.newText(uiGroup, "", left + width * 0.5, top + 126, native.systemFont, 18)
    geriButon = display.newRoundedRect(uiGroup, left + 58, top + 92, 100, 52, 14)
    geriButon:setFillColor(0.16, 0.24, 0.38, 0.92)
    geriButon:addEventListener("tap", gotoMenu)
    geriMetin = display.newText(uiGroup, "Geri", geriButon.x, geriButon.y, native.systemFont, 24)
    geriMetin:addEventListener("tap", gotoMenu)
    atesButonu = display.newRoundedRect(uiGroup, left + width - 78, top + height - 70, 132, 64, 16)
    atesButonu:setFillColor(0.55, 0.16, 0.18, 0.95)
    atesButonu:addEventListener("tap", lazeriAtesle)
    atesMetni = display.newText(uiGroup, "ATEŞ", atesButonu.x, atesButonu.y, native.systemFont, 26)
    atesMetni:addEventListener("tap", lazeriAtesle)

    metniGuncelle()

    gemi:addEventListener("touch", hareketGemi)

    patlamaSesi = audio.loadSound("audio/explosion.wav")
    lazerAtesSesi = audio.loadSound("audio/fire.wav")
    muzikYukleme = audio.loadStream("audio/80s-Space-Game_Looping.wav")
end

-- show()
function scene:show(event)
    local phase = event.phase
    if (phase == "did") then
        fizikler.start()
        Runtime:addEventListener("collision", carpisma)
        Runtime:addEventListener("enterFrame", oyunDongu)

        --start müzik
        audio.play(muzikYukleme, { channel = 1, loops = -1 })
    end
end

-- hide()
function scene:hide(event)
    local phase = event.phase
    if (phase == "will") then
        Runtime:removeEventListener("enterFrame", oyunDongu)
        oncekiKareZamani = nil
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
        if atesDolumZamanlayici then timer.cancel(atesDolumZamanlayici); atesDolumZamanlayici = nil end
        if ertelenmisHasarTimer then timer.cancel(ertelenmisHasarTimer); ertelenmisHasarTimer = nil end
    elseif (phase == "did") then
        Runtime:removeEventListener("collision", carpisma)
        fizikler.pause()
        audio.stop(1)
        audio.stop(2)
        audio.stop(3)
        sahne_degis.removeScene("oyun3")
    end
end

-- destroy()
function scene:destroy(event)
    oyunKayit.saveCurrent()
    oyunKayit.setProvider(nil)
    --sesi oyundan çıktıktansonra atmak
    audio.stop(1)
    audio.stop(2)
    audio.stop(3)
    if patlamaSesi then audio.dispose(patlamaSesi); patlamaSesi = nil end
    if lazerAtesSesi then audio.dispose(lazerAtesSesi); lazerAtesSesi = nil end
    if muzikYukleme then audio.dispose(muzikYukleme); muzikYukleme = nil end
    if atesDolumZamanlayici then timer.cancel(atesDolumZamanlayici); atesDolumZamanlayici = nil end
    if ertelenmisHasarTimer then timer.cancel(ertelenmisHasarTimer); ertelenmisHasarTimer = nil end
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
