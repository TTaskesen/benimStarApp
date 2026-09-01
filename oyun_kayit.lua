local json = require("json")

local M = {}
local VERSION = 1
local path = system.pathForFile("oyun_kaydi.json", system.DocumentsDirectory)
local temporaryPath = path and (path .. ".tmp") or nil
local provider

local function varsayilan()
    return {
        version = VERSION,
        valid = false,
        score = 0,
        level = 1,
        lives = 3,
        progress = 0,
        soundEnabled = true,
    }
end

local function sayi(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    value = math.floor(value)
    if value < minimum or value > maximum then
        return fallback
    end
    return value
end

local function dogrula(data)
    if type(data) ~= "table" or data.version ~= VERSION then
        return nil
    end
    local temiz = varsayilan()
    temiz.valid = data.valid == true
    temiz.score = sayi(data.score, 0, 0, 1000000000)
    temiz.level = sayi(data.level, 1, 1, 4)
    temiz.lives = sayi(data.lives, 3, 0, 9)
    temiz.progress = sayi(data.progress, 0, 0, 200)
    if type(data.soundEnabled) == "boolean" then
        temiz.soundEnabled = data.soundEnabled
    end
    if temiz.valid and temiz.lives == 0 then
        return nil
    end
    return temiz
end

function M.default()
    return varsayilan()
end

function M.load()
    if not path then
        print("[oyun_kayit] DocumentsDirectory yolu alınamadı; varsayılan kayıt kullanılıyor.")
        return varsayilan()
    end
    local file, openError = io.open(path, "r")
    if not file then
        if openError and not tostring(openError):match("No such file") then
            print("[oyun_kayit] Kayıt okunamadı: " .. tostring(openError))
        end
        return varsayilan()
    end
    local contents = file:read("*a")
    local closed, closeError = file:close()
    if not closed and closeError then
        print("[oyun_kayit] Kayıt dosyası kapatılamadı: " .. tostring(closeError))
    end
    if type(contents) ~= "string" or contents == "" then
        return varsayilan()
    end
    local ok, decoded = pcall(json.decode, contents)
    local data = ok and dogrula(decoded) or nil
    if not data then
        print("[oyun_kayit] Bozuk veya uyumsuz kayıt; varsayılan değerler kullanılıyor.")
        return varsayilan()
    end
    return data
end

function M.save(data)
    local temiz = dogrula(data) or varsayilan()
    if not path or not temporaryPath then
        print("[oyun_kayit] Kayıt yolu yok; kayıt yazılamadı.")
        return false
    end
    local encodedOk, encoded = pcall(json.encode, temiz)
    if not encodedOk or type(encoded) ~= "string" then
        print("[oyun_kayit] JSON kodlanamadı: " .. tostring(encoded))
        return false
    end
    local file, openError = io.open(temporaryPath, "w")
    if not file then
        print("[oyun_kayit] Geçici kayıt açılamadı: " .. tostring(openError))
        return false
    end
    local wrote, writeError = file:write(encoded)
    local flushed, flushError = file:flush()
    local closed, closeError = file:close()
    if not wrote or not flushed or not closed then
        print("[oyun_kayit] Kayıt yazılamadı: " .. tostring(writeError or flushError or closeError))
        os.remove(temporaryPath)
        return false
    end
    local renamed, renameError = os.rename(temporaryPath, path)
    if not renamed then
        print("[oyun_kayit] Geçici kayıt ana dosyaya taşınamadı: " .. tostring(renameError))
        os.remove(temporaryPath)
        return false
    end
    return true
end

function M.clear()
    local kayit = M.load()
    kayit.valid = false
    kayit.score = 0
    kayit.level = 1
    kayit.lives = 3
    kayit.progress = 0
    return M.save(kayit)
end

function M.setProvider(callback)
    provider = callback
end

function M.saveCurrent()
    if not provider then
        return false
    end
    local ok, data = pcall(provider)
    if not ok then
        print("[oyun_kayit] Durum sağlayıcısı hata verdi: " .. tostring(data))
        return false
    end
    return M.save(data)
end

return M
