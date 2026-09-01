local composer = require("composer")
local safeArea = require("safe_area")
local oyunKayit = require("oyun_kayit")

local scene = composer.newScene()
local veri

local function dugme(group, y, yazi, handler)
    local left, _, width = safeArea.bounds()
    local button = display.newRoundedRect(group, left + width * 0.5, y, math.min(340, width - 32), 58, 14)
    button:setFillColor(0.16, 0.24, 0.38, 0.95)
    button.strokeWidth = 2
    button:setStrokeColor(0.45, 0.65, 0.95, 0.9)
    button:addEventListener("tap", handler)
    local text = display.newText(group, yazi, button.x, button.y, native.systemFont, 26)
    text:setFillColor(0.9, 0.95, 1)
    text:addEventListener("tap", handler)
    return button, text
end

local function anaMenu()
    composer.setVariable("sonucVeri", nil)
    composer.gotoScene("menu", { time = 500, effect = "crossFade" })
    return true
end

local function tekrarOyna()
    oyunKayit.clear()
    composer.setVariable("devamKaydi", nil)
    composer.setVariable("sonucVeri", nil)
    composer.gotoScene("oyun", { time = 500, effect = "crossFade" })
    return true
end

local function yuksekSkor()
    local skor = veri and tonumber(veri.score) or 0
    composer.setVariable("finalSkor", skor)
    composer.setVariable("sonucVeri", nil)
    composer.gotoScene("yuksek_skor", { time = 500, effect = "crossFade" })
    return true
end

function scene:create(event)
    local group = self.view
    local left, top, width, height = safeArea.bounds()
    veri = composer.getVariable("sonucVeri") or {}
    composer.setVariable("sonucVeri", nil)

    local bg = display.newImageRect(group, "background1.png", 800, 1400)
    bg.x, bg.y = display.contentCenterX, display.contentCenterY
    local baslik = veri.victory and "Bölüm 4 Tamamlandı!" or "Oyun Bitti"
    local baslikMetni = display.newText(group, baslik, left + width * 0.5, top + 100, native.systemFontBold, 32)
    baslikMetni:setFillColor(veri.victory and 1 or 0.95, veri.victory and 0.82 or 0.95, 0.35)
    local alt = display.newText(group, veri.victory and "Yıldız Savaşı'nı tamamladın" or "Bir sonraki denemede daha ileri git!", left + width * 0.5, top + 145, native.systemFont, 20)
    alt:setFillColor(0.75, 0.85, 1)

    local satirlar = {
        "Skor: " .. tostring(veri.score or 0),
        "Ulaşılan bölüm: " .. tostring(veri.level or 1),
        "Tamamlanan dalga: " .. tostring(veri.wave or 0),
        "Vurulan meteor: " .. tostring(veri.meteor or 0),
        "İsabet oranı: %" .. tostring(veri.accuracy or 0),
        "Kaybedilen can: " .. tostring(veri.lostLives or 0),
        "En yüksek kombo: " .. tostring(veri.maxCombo or 1),
    }
    for i, satir in ipairs(satirlar) do
        local metin = display.newText(group, satir, left + width * 0.5, top + 205 + (i - 1) * 34, native.systemFont, 22)
        metin:setFillColor(0.85, 0.91, 1)
    end

    local ilkDugme = top + height - 230
    dugme(group, ilkDugme, "Tekrar Oyna", tekrarOyna)
    dugme(group, ilkDugme + 68, "Ana Menü", anaMenu)
    dugme(group, ilkDugme + 136, "En Yüksek Skorlar", yuksekSkor)
end

function scene:show(event) end
function scene:hide(event) end
function scene:destroy(event) veri = nil end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
