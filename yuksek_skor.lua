local sahne_degis = require("composer")
local safeArea = require("safe_area")
local skorKayit = require("skor_kayit")

local scene = sahne_degis.newScene()
local skorTablosu = {}
local yuksekSkorSes

local function gotoMenu()
    sahne_degis.gotoScene("menu", { time = 500, effect = "crossFade" })
    return true
end

function scene:create(event)
    local sceneGroup = self.view
    local left, top, width, height = safeArea.bounds()
    local centerX = left + width * 0.5
    skorTablosu = skorKayit.load()

    local arkaPlan = display.newImageRect(sceneGroup, "background1.png", 800, 1400)
    arkaPlan.x = display.contentCenterX
    arkaPlan.y = display.contentCenterY
    local baslik = display.newText(sceneGroup, "En Yüksek Skorlar", centerX, top + 80, native.systemFont, 34)
    baslik:setFillColor(0.9, 0.95, 1)
    for i = 1, 10 do
        local y = top + 135 + i * 48
        local rank = display.newText(sceneGroup, i .. ")", centerX - 60, y, native.systemFont, 28)
        rank.anchorX = 1
        rank:setFillColor(0.8)
        local value = display.newText(sceneGroup, tostring(skorTablosu[i] or 0), centerX - 40, y, native.systemFont, 28)
        value.anchorX = 0
    end
    local menuButton = display.newRoundedRect(sceneGroup, centerX, top + height - 72, math.min(260, width - 32), 58, 14)
    menuButton:setFillColor(0.16, 0.24, 0.38, 0.92)
    menuButton:addEventListener("tap", gotoMenu)
    local menuText = display.newText(sceneGroup, "Menü", centerX, menuButton.y, native.systemFont, 30)
    menuText:addEventListener("tap", gotoMenu)
    yuksekSkorSes = audio.loadStream("audio/Midnight-Crawlers_Looping.wav")
end

function scene:show(event)
    if event.phase == "did" then
        audio.play(yuksekSkorSes, { channel = 1, loops = -1 })
    end
end

function scene:hide(event)
    if event.phase == "did" then
        audio.stop(1)
        sahne_degis.removeScene("yuksek_skor")
    end
end

function scene:destroy(event)
    audio.stop(1)
    if yuksekSkorSes then
        audio.dispose(yuksekSkorSes)
        yuksekSkorSes = nil
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
