local sahne_degis = require("composer")
local oyunKayit = require("oyun_kayit")
local safeArea = require("safe_area")

local scene = sahne_degis.newScene()
local fizikler = require("physics")
fizikler.start()
fizikler.setGravity(0, 0)

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

local canlar = 5
local skor = 0
local olum = false
local gemi
local canMetin
local skorMetin
local bolumMetin
local atesButonu

local arkaPlanGroup
local anaGroup
local uiGroup
local asteroidTable = {}
local duvarTable = {}

local patlamaSesi
local lazerAtesSesi
local muzikYukleme

local duvarHizi = 190 * 0.6 -- önceki hızın %40 azaltılmış hali: 114 px/sn
local duvarAraligi = 2600 -- duvarlar arasında daha geniş dikey mesafe
local duvarSayac = 0
local sonrakiDuvar = "sol"
local meteorAraligi = 650
local sonMeteorZamani = 0

local oyunBittiZamanlayici
local tamirZamanlayici
local bolumGecisZamanlayici
local aktif = true
local yapilanVurus = 0
local hedefVurus = 125
local oncekiKareZamani
local sesAcik = true
local bolumTamamlandi

local lazerSoGuk = 300
local sonLazerZamani = 0

local GEMI_KATEGORI = 1
local DUVAR_KATEGORI = 2
local METEOR_KATEGORI = 4
local LAZER_KATEGORI = 8

local function gotoMenu()
    oyunKayit.saveCurrent()
    sahne_degis.gotoScene("menu", { time = 800, effect = "crossFade" })
end

local function metniGuncelle()
    canMetin.text = "Canlar: " .. canlar
    skorMetin.text = "Skorunuz: " .. skor
    bolumMetin.text = "Bölüm 4  •  Meteor: " .. yapilanVurus .. "/" .. hedefVurus
end

local function gorunurSinirlar()
    local gorunurSol = (display.contentWidth - display.viewableContentWidth) / 2
    local gorunurSag = display.contentWidth - gorunurSol
    return gorunurSol, gorunurSag
end

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

local function duvarOlustur()
    local gorunurSol, gorunurSag = gorunurSinirlar()
    local ekranGenisligi = gorunurSag - gorunurSol
    local duvarGenisligi = ekranGenisligi * 0.56
    local duvarYuksekligi = 34
    local x

    if sonrakiDuvar == "sol" then
        x = gorunurSol + duvarGenisligi / 2
        sonrakiDuvar = "sag"
    else
        x = gorunurSag - duvarGenisligi / 2
        sonrakiDuvar = "sol"
    end

    local duvar = display.newRect(anaGroup, x, -duvarYuksekligi, duvarGenisligi, duvarYuksekligi)
    duvar:setFillColor(0.25, 0.35, 0.6)
    -- Duvar ekranda aşağı hareket ettiği için kinematic gövde kullanılır;
    -- static gövdeyi her karede taşımak çarpışma süpürmesini atlayabilir.
    fizikler.addBody(duvar, "kinematic", {
        halfWidth = duvarGenisligi / 2,
        halfHeight = duvarYuksekligi / 2,
        filter = { categoryBits = DUVAR_KATEGORI, maskBits = GEMI_KATEGORI + LAZER_KATEGORI },
    })
    duvar.myName = "duvar"
    table.insert(duvarTable, duvar)
end

local function lazeriAtesle()
    if not aktif or not gemi or not gemi.parent then return true end
    local simdi = system.getTimer()
    if (simdi - sonLazerZamani) < lazerSoGuk then return true end
    sonLazerZamani = simdi

    audio.play(lazerAtesSesi, { channel = 2 })
    local yeniLazer = display.newImageRect(anaGroup, resimLevha, 5, 14, 40)
    fizikler.addBody(yeniLazer, "dynamic", {
        radius = 7,
        isSensor = true,
        filter = { categoryBits = LAZER_KATEGORI, maskBits = METEOR_KATEGORI + DUVAR_KATEGORI },
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
            if yeniLazer.parent then display.remove(yeniLazer) end
        end,
    })
    return true
end

local function hareketGemi(event)
    local hedef = event.target
    if event.phase == "began" then
        display.currentStage:setFocus(hedef)
        hedef.touchOffsetX = event.x - hedef.x
        hedef.touchOffsetY = event.y - hedef.y
    elseif event.phase == "moved" then
        if hedef.touchOffsetX == nil then hedef.touchOffsetX = event.x - hedef.x end
        if hedef.touchOffsetY == nil then hedef.touchOffsetY = event.y - hedef.y end
        local yariGenislik = hedef.contentWidth / 2
        local gorunurSol = (display.contentWidth - display.viewableContentWidth) / 2 + yariGenislik
        local gorunurSag = (display.contentWidth + display.viewableContentWidth) / 2 - yariGenislik
        hedef.x = math.max(gorunurSol, math.min(gorunurSag, event.x - hedef.touchOffsetX))
        local ustSinir = display.contentHeight - 600
        local altSinir = display.contentHeight - 250
        hedef.y = math.max(ustSinir, math.min(altSinir, event.y - hedef.touchOffsetY))
    elseif event.phase == "ended" or event.phase == "cancelled" then
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

    if simdi - sonMeteorZamani >= meteorAraligi then
        meteorOlustur()
        sonMeteorZamani = simdi
    end

    duvarSayac = duvarSayac + dt * 1000
    if #duvarTable == 0 or duvarSayac >= duvarAraligi then
        duvarOlustur()
        duvarSayac = 0
    end

    for i = #duvarTable, 1, -1 do
        local duvar = duvarTable[i]
        if not duvar.parent or duvar.y > display.contentHeight + 100 then
            display.remove(duvar)
            table.remove(duvarTable, i)
        else
            duvar.y = duvar.y + duvarHizi * dt
        end
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
    if not gemi or not gemi.parent then return end
    gemi.isBodyActive = true
    gemi.alpha = 1
    olum = false
end

local function oyunBitti()
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
    audio.play(patlamaSesi, { channel = 3 })
    canlar = canlar - 1
    canMetin.text = "Canlar: " .. canlar
    if canlar > 0 then oyunKayit.saveCurrent() end
    if canlar <= 0 then
        display.remove(gemi)
        oyunBittiZamanlayici = timer.performWithDelay(2000, oyunBitti)
    else
        gemi.alpha = 0.3
        timer.performWithDelay(0, function()
            if gemi then gemi.isBodyActive = false end
        end)
        tamirZamanlayici = timer.performWithDelay(1200, gemiTamir)
    end
end

local function listedenCikar(liste, nesne)
    for i = #liste, 1, -1 do
        if liste[i] == nesne then
            table.remove(liste, i)
            return
        end
    end
end

local function carpisma(event)
    if not aktif or event.phase ~= "began" then return end
    local obj1 = event.object1
    local obj2 = event.object2
    local isim1 = obj1.myName
    local isim2 = obj2.myName

    if ((isim1 == "lazer" and isim2 == "asteroid") or (isim1 == "asteroid" and isim2 == "lazer")) then
        local lazer = isim1 == "lazer" and obj1 or obj2
        local asteroid = isim1 == "asteroid" and obj1 or obj2
        if lazer.parent then display.remove(lazer) end
        if asteroid.parent then display.remove(asteroid) end
        listedenCikar(asteroidTable, asteroid)
        audio.play(patlamaSesi, { channel = 3 })
        skor = skor + 100
        yapilanVurus = yapilanVurus + 1
        metniGuncelle()
        oyunKayit.saveCurrent()
        if yapilanVurus >= hedefVurus then bolumTamamlandi() end
    elseif ((isim1 == "gemi" and isim2 == "asteroid") or (isim1 == "asteroid" and isim2 == "gemi")) then
        local asteroid = isim1 == "asteroid" and obj1 or obj2
        if asteroid.parent then display.remove(asteroid) end
        listedenCikar(asteroidTable, asteroid)
        gemiHasar()
    elseif ((isim1 == "lazer" and isim2 == "duvar") or (isim1 == "duvar" and isim2 == "lazer")) then
        local lazer = isim1 == "lazer" and obj1 or obj2
        if lazer.parent then display.remove(lazer) end
    elseif ((isim1 == "gemi" and isim2 == "duvar") or (isim1 == "duvar" and isim2 == "gemi")) then
        local duvar = isim1 == "duvar" and obj1 or obj2
        if duvar.parent then display.remove(duvar) end
        listedenCikar(duvarTable, duvar)
        gemiHasar()
    end
end

function scene:create(event)
    local sceneGroup = self.view
    local devamKaydi = sahne_degis.getVariable("devamKaydi")
    sahne_degis.setVariable("devamKaydi", nil)
    local aktarilanSkor = sahne_degis.getVariable("aktarilanSkor")
    sahne_degis.setVariable("aktarilanSkor", nil)

    if type(devamKaydi) == "table" and devamKaydi.level == 4 then
        skor = devamKaydi.score or 0
        canlar = devamKaydi.lives or 5
        yapilanVurus = math.min(devamKaydi.progress or 0, hedefVurus - 1)
        sesAcik = devamKaydi.soundEnabled ~= false
    else
        skor = aktarilanSkor or 0
        canlar = aktarilanSkor and 5 or 3
        yapilanVurus = 0
        sesAcik = oyunKayit.load().soundEnabled
    end

    asteroidTable = {}
    duvarTable = {}
    duvarSayac = 0
    sonrakiDuvar = "sol"
    sonMeteorZamani = 0
    oncekiKareZamani = nil
    aktif = true
    olum = false
    oyunKayit.setProvider(function()
        return { version = 1, valid = aktif or bolumGecisZamanlayici ~= nil, score = skor, level = 4, lives = canlar, progress = yapilanVurus, soundEnabled = sesAcik }
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

    gemi = display.newImageRect(anaGroup, resimLevha, 4, 98, 79)
    gemi.x = display.contentCenterX
    gemi.y = display.contentHeight - 250
    fizikler.addBody(gemi, {
        radius = 30,
        isSensor = true,
        filter = { categoryBits = GEMI_KATEGORI, maskBits = METEOR_KATEGORI + DUVAR_KATEGORI },
    })
    gemi.myName = "gemi"
    gemi:setFillColor(1, 0.6, 0)

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

function scene:show(event)
    if event.phase == "did" then
        fizikler.start()
        Runtime:addEventListener("collision", carpisma)
        Runtime:addEventListener("enterFrame", oyunDongu)
        audio.play(muzikYukleme, { channel = 1, loops = -1 })
    end
end

function scene:hide(event)
    if event.phase == "will" then
        Runtime:removeEventListener("enterFrame", oyunDongu)
        display.currentStage:setFocus(nil)
        if oyunBittiZamanlayici then timer.cancel(oyunBittiZamanlayici); oyunBittiZamanlayici = nil end
        if tamirZamanlayici then timer.cancel(tamirZamanlayici); tamirZamanlayici = nil end
        if bolumGecisZamanlayici then timer.cancel(bolumGecisZamanlayici); bolumGecisZamanlayici = nil end
        if gemi then transition.cancel(gemi) end
    elseif event.phase == "did" then
        Runtime:removeEventListener("collision", carpisma)
        fizikler.pause()
        audio.stop(1)
        audio.stop(2)
        audio.stop(3)
        sahne_degis.removeScene("oyun4")
    end
end

function scene:destroy(event)
    oyunKayit.saveCurrent()
    oyunKayit.setProvider(nil)
    audio.stop(1)
    audio.stop(2)
    audio.stop(3)
    if patlamaSesi then audio.dispose(patlamaSesi); patlamaSesi = nil end
    if lazerAtesSesi then audio.dispose(lazerAtesSesi); lazerAtesSesi = nil end
    if muzikYukleme then audio.dispose(muzikYukleme); muzikYukleme = nil end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
