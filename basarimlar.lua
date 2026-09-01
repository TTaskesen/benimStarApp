local composer = require("composer")
local safeArea = require("safe_area")
local meta = require("oyun_meta")

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

    local title = display.newText(group, "Başarımlar", centerX, top + 62, native.systemFontBold, 34)
    title:setFillColor(0.9, 0.95, 1)
    local daily = meta.ensureDaily()
    local dailyBaslik = "Hazırlanıyor"
    local dailyHedef = 1
    for _, task in ipairs(meta.dailyTasks()) do
        if task.id == daily.taskId then dailyBaslik, dailyHedef = task.title, task.target; break end
    end
    local dailyText = display.newText(group, "Günlük: " .. dailyBaslik .. " (" .. tostring(daily.progress or 0) .. "/" .. tostring(dailyHedef) .. ")", centerX, top + 105, native.systemFont, 19)
    dailyText:setFillColor(0.55, 0.8, 1)

    local saved = meta.load().achievements
    local items = meta.achievements()
    for i, item in ipairs(items) do
        local unlocked = saved[item.id] == true
        local y = top + 145 + (i - 1) * 48
        local prefix = unlocked and "✓ " or "○ "
        local text = display.newText(group, prefix .. item.title .. " — " .. item.description, centerX, y, native.systemFont, 17)
        text:setFillColor(unlocked and 0.55 or 0.7, unlocked and 1 or 0.75, unlocked and 0.6 or 0.85)
    end

    local button = display.newRoundedRect(group, centerX, top + height - 60, math.min(260, width - 32), 56, 14)
    button:setFillColor(0.16, 0.24, 0.38, 0.95)
    button:addEventListener("tap", menuyeDon)
    local buttonText = display.newText(group, "Menü", button.x, button.y, native.systemFont, 26)
    buttonText:addEventListener("tap", menuyeDon)
end

function scene:show(event) end
function scene:hide(event) end
function scene:destroy(event) end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
