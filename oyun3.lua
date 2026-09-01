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

--dar kanal (koridor) ayarları
local kaymaHizi = 100 -- kanalların kayma hızı (px/sn)
local segmentAraligi = 360
local boslukGenisligi = 220

local kanalTable = {}
local toplamKanal = 0
local kayilanMesafe = 0
local oncekiGapYonu = "sag"

local oyunBittiZamanlayici
local tamirZamanlayici
local bolumGecisZamanlayici
local aktif = true
local gecilenKanal = 0
local hedefKanal = 10
local oncekiKareZamani
local sesAcik = true
local bolumTamamlandi

local lazerSoGuk = 300
local sonLazerZamani = 0

--kullanıcı arayüzü textin güncellenmesi
local function metniGuncelle()
    canMetin.text = "Canlar: " .. canlar
    skorMetin.text = "Skorunuz: " .. skor
    bolumMetin.text = "Bölüm 3  •  Hedef: " .. gecilenKanal .. "/" .. hedefKanal
end

--zoomEven kırpmasında görünür ekran sınırları
local function gorunurSinirlar()
    local gorunurSol = (display.contentWidth - display.viewableContentWidth) / 2
    local gorunurSag = display.contentWidth - gorunurSol
    return gorunurSol, gorunurSag
end

local function kanalSegmentiOlustur()
    local gorunurSol, gorunurSag = gorunurSinirlar()

    --boşluk solda ya da sağda dönüşümlü: kenarlara duvar, gemi sağa sola geçer
    local gapYonu = oncekiGapYonu == "sag" and "sol" or "sag"
    oncekiGapYonu = gapYonu

    local yukseklik = segmentAraligi + 120
    local baslangicY = -yukseklik / 2
    local genislik = gorunurSag - gorunurSol - boslukGenisligi
    local ortaX

    if gapYonu == "sol" then
        --duvar sağda: boşluğun sağından ekranın sağına kadar
        ortaX = gorunurSol + boslukGenisligi + genislik / 2
    else
        --duvar solda: ekranın solundan boşluğun soluna kadar
        ortaX = gorunurSol + genislik / 2
    end

    local duvar = display.newRect(anaGroup, ortaX, baslangicY, genislik, yukseklik)
    duvar:setFillColor(0.25, 0.35, 0.6)
    fizikler.addBody(duvar, "static", { halfWidth = genislik / 2, halfHeight = yukseklik / 2 })
    duvar.myName = "duvar"

    table.insert(kanalTable, { duvar = duvar, gecildi = false })
    toplamKanal = toplamKanal + 1
end

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
    fizikler.addBody(yeniLazer, "dynamic", { radius = 7, isSensor = true })
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
    if not aktif then return end
    local simdi = event.time or system.getTimer()
    local dt = oncekiKareZamani and (simdi - oncekiKareZamani) / 1000 or (1 / 60)
    oncekiKareZamani = simdi
    dt = math.max(0.001, math.min(dt, 0.05))

    --yeni kanal segmenti oluştur (sonsuz)
    if kayilanMesafe > toplamKanal * segmentAraligi then
        kanalSegmentiOlustur()
    end

    --gemi yukarıdayken dünya daha hızlı kayar (kamera gemiyi takip eder)
    local etkinKayma = kaymaHizi
    if gemi and gemi.parent then
        etkinKayma = kaymaHizi + math.max(0, (display.contentHeight - 250) - gemi.y) * 0.2
    end
    kayilanMesafe = kayilanMesafe + etkinKayma * dt

    --kanalları aşağı kaydır, geçilenleri ödüllendir, çıkanları sil
    for i = #kanalTable, 1, -1 do
        local s = kanalTable[i]
        local duvar = s.duvar
        if duvar.parent then
            duvar.y = duvar.y + etkinKayma * dt

            if (not s.gecildi) and gemi and gemi.parent and duvar.y > gemi.y + 60 then
                s.gecildi = true
                skor = skor + 100
                gecilenKanal = gecilenKanal + 1
                metniGuncelle()
                oyunKayit.saveCurrent()
                if gecilenKanal >= hedefKanal then bolumTamamlandi() end
            end

            if duvar.y > display.contentHeight + 200 then
                display.remove(duvar)
                table.remove(kanalTable, i)
            end
        else
            table.remove(kanalTable, i)
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
    sahne_degis.setVariable("finalSkor", skor)
    sahne_degis.gotoScene("yuksek_skor", { time = 800, effect = "crossFade" })
end

bolumTamamlandi = function()
    if not aktif then return end
    aktif = false
    bolumMetin.text = "Bölüm tamamlandı!"
    oyunKayit.clear()
    bolumGecisZamanlayici = timer.performWithDelay(1200, function()
        sahne_degis.setVariable("finalSkor", skor)
        sahne_degis.gotoScene("yuksek_skor", { time = 800, effect = "crossFade" })
    end)
end

local function gemiHasar()
    if olum then return end
    olum = true

    --patlama sesi
    audio.play(patlamaSesi, { channel = 3 })

    --canı güncelle
    canlar = canlar - 1
    canMetin.text = "Canlar: " .. canlar
    if canlar > 0 then oyunKayit.saveCurrent() end
    if (canlar <= 0) then
        display.remove(gemi)
        oyunBittiZamanlayici = timer.performWithDelay(2000, oyun3Bitti)
    else
        gemi.alpha = 0.3
        -- isBodyActive çarpışma olayı sırasında (dünya kilitli) set edilemez,
        -- bu yüzden bir sonraki kareye ertelenir
        timer.performWithDelay(0, function()
            if gemi then gemi.isBodyActive = false end
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

    if ((isim1 == "lazer" and isim2 == "duvar") or (isim1 == "duvar" and isim2 == "lazer")) then
        --lazer duvara çarptı
        local lazer = isim1 == "lazer" and obj1 or obj2
        if lazer.parent then display.remove(lazer) end
    elseif ((isim1 == "gemi" and isim2 == "duvar") or (isim1 == "duvar" and isim2 == "gemi")) then
        --gemi duvara çarptı, duvar kırılsın
        local duvar = isim1 == "duvar" and obj1 or obj2
        if duvar.parent then display.remove(duvar) end
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
        gecilenKanal = math.min(devamKaydi.progress or 0, hedefKanal - 1)
        sesAcik = devamKaydi.soundEnabled ~= false
    else
        skor = aktarilanSkor or 0
        canlar = aktarilanSkor and 5 or 3
        sesAcik = oyunKayit.load().soundEnabled
    end
    if type(devamKaydi) ~= "table" or devamKaydi.level ~= 3 then gecilenKanal = 0 end
    kanalTable = {}
    toplamKanal = 0
    kayilanMesafe = 0
    oncekiGapYonu = "sag"
    oncekiKareZamani = nil
    aktif = true
    oyunKayit.setProvider(function()
        return { version = 1, valid = aktif or bolumGecisZamanlayici ~= nil, score = skor, level = 3, lives = canlar, progress = gecilenKanal, soundEnabled = sesAcik }
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
    fizikler.addBody(gemi, { radius = 30, isSensor = true })
    gemi.myName = "gemi"
    gemi:setFillColor(0, 0.6, 1)

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
