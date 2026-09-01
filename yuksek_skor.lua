local sahne_degis = require("composer")
local safeArea = require("safe_area")
local json = require("json")

local scene = sahne_degis.newScene()
local skorTablosu = {}
local yuksekSkorSes
local dosyaYolu = system.pathForFile("skor.json", system.DocumentsDirectory)

local function skorGecerli(value)
    return type(value) == "number" and value >= 0 and value <= 1000000000 and value == math.floor(value)
end

local function varsayilanSkorlar()
    local result = {}
    for i = 1, 10 do result[i] = 0 end
    return result
end

local function skoruYukle()
    skorTablosu = {}
    local file = dosyaYolu and io.open(dosyaYolu, "r")
    if file then
        local contents = file:read("*a")
        file:close()
        local ok, decoded = pcall(json.decode, contents or "")
        if ok and type(decoded) == "table" then
            for _, value in ipairs(decoded) do
                if skorGecerli(value) then table.insert(skorTablosu, value) end
            end
        else
            print("[yuksek_skor] Skor JSON'u bozuk; varsayılan liste kullanılıyor.")
        end
    end
    if #skorTablosu == 0 then skorTablosu = varsayilanSkorlar() end
    table.sort(skorTablosu, function(a, b) return a > b end)
end

local function skoruKaydet()
    if not dosyaYolu then
        print("[yuksek_skor] Skor kayıt yolu alınamadı.")
        return false
    end
    local ok, encoded = pcall(json.encode, skorTablosu)
    if not ok or type(encoded) ~= "string" then
        print("[yuksek_skor] Skor JSON'u kodlanamadı.")
        return false
    end
    local temporaryPath = dosyaYolu .. ".tmp"
    local file, openError = io.open(temporaryPath, "w")
    if not file then
        print("[yuksek_skor] Geçici skor dosyası açılamadı: " .. tostring(openError))
        return false
    end
    local wrote = file:write(encoded)
    local flushed = file:flush()
    local closed = file:close()
    if not wrote or not flushed or not closed then
        print("[yuksek_skor] Skor dosyası yazılamadı.")
        os.remove(temporaryPath)
        return false
    end
    local renamed, renameError = os.rename(temporaryPath, dosyaYolu)
    if not renamed then
        print("[yuksek_skor] Skor dosyası değiştirilemedi: " .. tostring(renameError))
        os.remove(temporaryPath)
        return false
    end
    return true
end

local function gotoMenu()
    sahne_degis.gotoScene("menu", { time = 500, effect = "crossFade" })
    return true
end

function scene:create(event)
    local sceneGroup = self.view
    local left, top, width, height = safeArea.bounds()
    local centerX = left + width * 0.5
    skoruYukle()

    local finalSkor = sahne_degis.getVariable("finalSkor")
    sahne_degis.setVariable("finalSkor", nil)
    if skorGecerli(finalSkor) then
        table.insert(skorTablosu, finalSkor)
        table.sort(skorTablosu, function(a, b) return a > b end)
    end
    while #skorTablosu > 10 do table.remove(skorTablosu) end
    skoruKaydet()

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
