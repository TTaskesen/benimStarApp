local sahne_degis = require("composer")
local oyunKayit = require("oyun_kayit")
local safeArea = require("safe_area")

local scene = sahne_degis.newScene()
local menuSesi
local sesAcik = true
local sesMetni
local devamButonu
local devamButonMetni

local GIZLILIK_URL = "https://ttaskesen.github.io/benimStarApp/privacy-policy/"
local DESTEK_URL = "https://github.com/TTaskesen/benimStarApp/issues"

local function makeButton(group, label, y, handler)
    local left, _, width = safeArea.bounds()
    local button = display.newRoundedRect(group, left + width * 0.5, y, math.min(360, width - 32), 64, 16)
    button:setFillColor(0.16, 0.24, 0.38, 0.92)
    button.strokeWidth = 2
    button:setStrokeColor(0.45, 0.65, 0.95, 0.9)
    local text = display.newText(group, label, button.x, button.y, native.systemFont, 30)
    text:setFillColor(0.85, 0.92, 1)
    button:addEventListener("tap", handler)
    text:addEventListener("tap", handler)
    return button, text
end

local function yeniOyun()
    oyunKayit.clear()
    sahne_degis.setVariable("devamKaydi", nil)
    sahne_degis.gotoScene("oyun", { time = 500, effect = "crossFade" })
    return true
end

local function devamEt()
    local kayit = oyunKayit.load()
    if not kayit.valid then return true end
    sahne_degis.setVariable("devamKaydi", kayit)
    local sahne = kayit.level == 1 and "oyun" or ("oyun" .. tostring(kayit.level))
    sahne_degis.gotoScene(sahne, { time = 500, effect = "crossFade" })
    return true
end

local function gotoYuksekSkor()
    sahne_degis.gotoScene("yuksek_skor", { time = 500, effect = "crossFade" })
    return true
end

local function sesiDegistir()
    sesAcik = not sesAcik
    local seviye = sesAcik and 0.5 or 0
    audio.setVolume(seviye, { channel = 1 })
    audio.setVolume(seviye, { channel = 2 })
    audio.setVolume(seviye, { channel = 3 })
    sesMetni.text = sesAcik and "Ses: Açık" or "Ses: Kapalı"
    local kayit = oyunKayit.load()
    kayit.soundEnabled = sesAcik
    oyunKayit.save(kayit)
    return true
end

local function gizlilikPolitikasi()
    system.openURL(GIZLILIK_URL)
    return true
end

local function destekVeIletisim()
    system.openURL(DESTEK_URL)
    return true
end

function scene:create(event)
    local sceneGroup = self.view
    local left, top, width, height = safeArea.bounds()
    local centerX = left + width * 0.5
    local arkaPlan = display.newImageRect(sceneGroup, "background.png", 800, 1400)
    arkaPlan.x = display.contentCenterX
    arkaPlan.y = display.contentCenterY

    local titleWidth = math.min(500, width - 32)
    local title = display.newImageRect(sceneGroup, "title.png", titleWidth, 80 * titleWidth / 500)
    title.x = centerX
    title.y = top + 150

    local logoSize = math.min(180, width * 0.42, height * 0.18)
    local logo = display.newImageRect(sceneGroup, "benimStarApp-logo.png", logoSize, logoSize)
    logo.x = centerX
    logo.y = title.y + title.height * 0.5 + logoSize * 0.5 + 22

    -- Alt düğmelerin güvenli alanda kalması için ilk düğmeyi toplam menü
    -- yüksekliğine göre sınırla. Bu, kısa ekranlarda destek bağlantılarının
    -- ekran dışına taşmasını önler.
    local sonDugmeOfseti = 410
    local maxFirstY = top + height - 32 - 64 * 0.5 - sonDugmeOfseti
    local firstY = math.min(top + math.min(520, height * 0.50), maxFirstY)
    makeButton(sceneGroup, "Yeni Oyun", firstY, yeniOyun)
    devamButonu, devamButonMetni = makeButton(sceneGroup, "Devam Et", firstY + 82, devamEt)
    makeButton(sceneGroup, "Yüksek Skor", firstY + 164, gotoYuksekSkor)
    local _, soundText = makeButton(sceneGroup, "Ses: Açık", firstY + 246, sesiDegistir)
    makeButton(sceneGroup, "Gizlilik Politikası", firstY + 328, gizlilikPolitikasi)
    makeButton(sceneGroup, "Destek / İletişim", firstY + 410, destekVeIletisim)
    sesMetni = soundText
    menuSesi = audio.loadStream("audio/Escape_Looping.wav")
end

function scene:show(event)
    if event.phase == "will" then
        local kayit = oyunKayit.load()
        sesAcik = kayit.soundEnabled
        sesMetni.text = sesAcik and "Ses: Açık" or "Ses: Kapalı"
        devamButonu.isVisible = kayit.valid
        devamButonu.isHitTestable = kayit.valid
        devamButonMetni.isVisible = kayit.valid
    elseif event.phase == "did" then
        local seviye = sesAcik and 0.5 or 0
        audio.setVolume(seviye, { channel = 1 })
        audio.setVolume(seviye, { channel = 2 })
        audio.setVolume(seviye, { channel = 3 })
        audio.play(menuSesi, { channel = 1, loops = -1 })
    end
end

function scene:hide(event)
    if event.phase == "did" then
        audio.stop(1)
    end
end

function scene:destroy(event)
    audio.stop(1)
    if menuSesi then
        audio.dispose(menuSesi)
        menuSesi = nil
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
