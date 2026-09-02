local composer = require("composer")
local safeArea = require("safe_area")

local scene = composer.newScene()

local function menuyeDon()
    composer.gotoScene("menu", { time = 400, effect = "crossFade" })
    return true
end

function scene:create(event)
    local group = self.view
    local left, top, width, height = safeArea.bounds()
    local centerX = left + width * 0.5

    local bg = display.newImageRect(group, "background1.png", 800, 1400)
    bg.x, bg.y = display.contentCenterX, display.contentCenterY

    local title = display.newText(group, "Destek / İletişim", centerX, top + 68, native.systemFontBold, 32)
    title:setFillColor(0.9, 0.95, 1)

    local logoSize = math.min(150, width * 0.34, height * 0.16)
    local logo = display.newImageRect(group, "benimStarApp-logo.png", logoSize, logoSize)
    logo.x, logo.y = centerX, top + 165

    local function bilgi(y, baslik, metin, renk)
        local baslikMetni = display.newText(group, baslik, centerX, y, native.systemFontBold, 22)
        baslikMetni:setFillColor(0.55, 0.8, 1)
        local icerik = display.newText({
            parent = group,
            text = metin,
            x = centerX,
            y = y + 34,
            width = width - 44,
            font = native.systemFont,
            fontSize = 22,
            align = "center",
        })
        icerik:setFillColor(unpack(renk or {0.85, 0.91, 1}))
    end

    bilgi(top + 252, "Geliştirici", "Taskesen")
    bilgi(top + 342, "Çalışma alanı", "Mobil oyun geliştirme • Solar2D")
    bilgi(top + 432, "E-posta", "taskesen@msn.com", {0.55, 0.8, 1})

    local aciklama = display.newText({
        parent = group,
        text = "Destek ve geri bildirim için bu adresi kullanabilirsiniz.",
        x = centerX,
        y = top + 540,
        width = width - 44,
        font = native.systemFont,
        fontSize = 18,
        align = "center",
    })
    aciklama:setFillColor(0.72, 0.82, 0.95)

    local menuButton = display.newRoundedRect(group, centerX, top + height - 64, math.min(260, width - 32), 58, 14)
    menuButton:setFillColor(0.16, 0.24, 0.38, 0.95)
    menuButton.strokeWidth = 2
    menuButton:setStrokeColor(0.45, 0.65, 0.95, 0.9)
    menuButton:addEventListener("tap", menuyeDon)
    local menuText = display.newText(group, "Menü", menuButton.x, menuButton.y, native.systemFont, 28)
    menuText:setFillColor(0.9, 0.95, 1)
    menuText:addEventListener("tap", menuyeDon)
end

function scene:show(event) end
function scene:hide(event) end
function scene:destroy(event) end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
