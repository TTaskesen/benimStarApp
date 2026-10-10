local composer = require("composer")
local safeArea = require("safe_area")
local gemiSecimi = require("gemi_secimi")

local scene = composer.newScene()

local frames = {
    frames = {
        { x = 0, y = 265, width = 98, height = 79 },
    },
}
local resimLevha = graphics.newImageSheet("gameObjects.png", frames)

local function menuyeDon()
    composer.gotoScene("menu", { time = 400, effect = "crossFade" })
    return true
end

local function secimiBaslat(id)
    -- Gemi seçimi her zaman temiz bir Bölüm 1 sahnesi açmalı; aksi halde
    -- Composer önbelleğindeki eski gemi ve skor görünümde kalabilir.
    for _, sceneName in ipairs({ "oyun", "oyun2", "oyun3", "oyun4" }) do
        composer.removeScene(sceneName)
    end
    composer.setVariable("gemiSecimi", gemiSecimi.normalize(id))
    composer.setVariable("devamKaydi", nil)
    composer.setVariable("aktarilanSkor", nil)
    composer.gotoScene("oyun", { time = 500, effect = "crossFade" })
    return true
end

local function secimKarti(group, gemi, y, width)
    local left, _, _, _ = safeArea.bounds()
    local kart = display.newRoundedRect(group, left + width * 0.5, y, math.min(390, width - 28), 128, 18)
    kart:setFillColor(0.08, 0.15, 0.28, 0.96)
    kart.strokeWidth = 2
    kart:setStrokeColor(gemi.renk[1], gemi.renk[2], gemi.renk[3], 0.9)

    local gemiGorsel = display.newImageRect(group, resimLevha, 1, 78, 63)
    gemiGorsel.x, gemiGorsel.y = kart.x - kart.width * 0.34, kart.y
    gemiGorsel:setFillColor(gemi.renk[1], gemi.renk[2], gemi.renk[3])

    local baslik = display.newText(group, gemi.ad, kart.x - kart.width * 0.04, kart.y - 22, native.systemFontBold, 22)
    baslik.anchorX = 0
    baslik:setFillColor(0.9, 0.95, 1)
    local aciklama = display.newText(group, gemi.aciklama, baslik.x, kart.y + 14, native.systemFont, 16)
    aciklama.anchorX = 0
    aciklama:setFillColor(0.65, 0.78, 0.95)

    local function sec()
        return secimiBaslat(gemi.id)
    end
    kart:addEventListener("tap", sec)
    gemiGorsel:addEventListener("tap", sec)
    baslik:addEventListener("tap", sec)
    aciklama:addEventListener("tap", sec)
end

function scene:create(event)
    local group = self.view
    local left, top, width, height = safeArea.bounds()
    local centerX = left + width * 0.5

    local arkaPlan = display.newImageRect(group, "background.png", 800, 1400)
    arkaPlan.x, arkaPlan.y = display.contentCenterX, display.contentCenterY

    local baslik = display.newText(group, "Gemi Seç", centerX, top + 86, native.systemFontBold, 36)
    baslik:setFillColor(0.55, 0.75, 1)
    local altBaslik = display.newText(group, "Yeni maceran için bir gemi seç", centerX, top + 132, native.systemFont, 18)
    altBaslik:setFillColor(0.75, 0.85, 1)

    local gemiler = gemiSecimi.list()
    local ilkY = top + math.min(250, height * 0.23)
    for i, gemi in ipairs(gemiler) do
        secimKarti(group, gemi, ilkY + (i - 1) * 150, width)
    end

    local geri = display.newRoundedRect(group, centerX, top + height - 62, math.min(250, width - 32), 54, 14)
    geri:setFillColor(0.16, 0.24, 0.38, 0.95)
    geri.strokeWidth = 2
    geri:setStrokeColor(0.45, 0.65, 0.95, 0.9)
    geri:addEventListener("tap", menuyeDon)
    local geriMetin = display.newText(group, "Menüye Dön", geri.x, geri.y, native.systemFont, 24)
    geriMetin:setFillColor(0.9, 0.95, 1)
    geriMetin:addEventListener("tap", menuyeDon)
end

scene:addEventListener("create", scene)
return scene
