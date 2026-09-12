local json = require("json")

local M = {}
local MAX_SKOR = 10
local path = system.pathForFile("skor.json", system.DocumentsDirectory)
local temporaryPath = path and (path .. ".tmp") or nil

local function varsayilanSkorlar()
    return { 10000, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
end

local function skorGecerli(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value >= 0
        and value <= 1000000000
        and value == math.floor(value)
end

local function normalize(liste)
    local temiz = {}
    if type(liste) == "table" then
        for i = 1, #liste do
            if skorGecerli(liste[i]) then
                temiz[#temiz + 1] = liste[i]
            end
        end
    end

    table.sort(temiz, function(a, b) return a > b end)
    while #temiz > MAX_SKOR do table.remove(temiz) end
    if #temiz == 0 then return varsayilanSkorlar(), true end
    while #temiz < MAX_SKOR do temiz[#temiz + 1] = 0 end

    local degisti = type(liste) ~= "table" or #liste ~= #temiz
    if not degisti then
        for i = 1, #temiz do
            if liste[i] ~= temiz[i] then degisti = true; break end
        end
    end
    return temiz, degisti
end

local function guvenliYaz(liste, islem)
    if not path or not temporaryPath then
        print("[skor_kayit] " .. islem .. " başarısız: skor dosyası yolu alınamadı.")
        return false
    end

    local encodedOk, encoded = pcall(json.encode, liste)
    if not encodedOk or type(encoded) ~= "string" then
        print("[skor_kayit] " .. islem .. " başarısız: JSON kodlanamadı (" .. path .. ").")
        return false
    end

    local file, openError = io.open(temporaryPath, "w")
    if not file then
        print("[skor_kayit] " .. islem .. " başarısız: geçici dosya açılamadı (" .. temporaryPath .. "): " .. tostring(openError))
        return false
    end

    local wrote, writeError = file:write(encoded)
    local flushed, flushError = file:flush()
    local closed, closeError = file:close()
    if not wrote or not flushed or not closed then
        print("[skor_kayit] " .. islem .. " başarısız: yazma/kapatma hatası (" .. temporaryPath .. "): " .. tostring(writeError or flushError or closeError))
        os.remove(temporaryPath)
        return false
    end

    local renamed, renameError = os.rename(temporaryPath, path)
    if not renamed then
        print("[skor_kayit] " .. islem .. " başarısız: geçici dosya taşınamadı (" .. path .. "): " .. tostring(renameError))
        os.remove(temporaryPath)
        return false
    end
    return true
end

function M.load()
    local varsayilan = varsayilanSkorlar()
    if not path then
        print("[skor_kayit] Okuma başarısız: DocumentsDirectory yolu alınamadı; başlangıç listesi kullanılıyor.")
        return varsayilan
    end

    local file, openError = io.open(path, "r")
    if not file then
        if openError then
            print("[skor_kayit] Okuma: dosya yok veya açılamadı (" .. path .. "): " .. tostring(openError) .. "; başlangıç listesi oluşturuluyor.")
        end
        guvenliYaz(varsayilan, "başlangıç skorunu oluşturma")
        return varsayilan
    end

    local contents = file:read("*a")
    local closed, closeError = file:close()
    if not closed and closeError then
        print("[skor_kayit] Okuma başarısız: dosya kapatılamadı (" .. path .. "): " .. tostring(closeError))
    end

    if type(contents) ~= "string" or contents == "" then
        print("[skor_kayit] Okuma: dosya boş (" .. path .. "); başlangıç listesi oluşturuluyor.")
        guvenliYaz(varsayilan, "boş dosyayı yenileme")
        return varsayilan
    end

    local decodedOk, decoded = pcall(json.decode, contents)
    if not decodedOk or type(decoded) ~= "table" then
        print("[skor_kayit] Okuma: bozuk veya tablo olmayan JSON (" .. path .. "); başlangıç listesi oluşturuluyor.")
        guvenliYaz(varsayilan, "bozuk dosyayı yenileme")
        return varsayilan
    end

    local temiz, degisti = normalize(decoded)
    if degisti then guvenliYaz(temiz, "skor listesini normalleştirme") end
    return temiz
end

function M.save(liste)
    local temiz = normalize(liste)
    return guvenliYaz(temiz, "skor listesini kaydetme")
end

function M.add(score)
    if not skorGecerli(score) then
        print("[skor_kayit] Final skor reddedildi: geçersiz değer (" .. tostring(score) .. ").")
        return false
    end

    local liste = M.load()
    liste[#liste + 1] = score
    local temiz = normalize(liste)
    return guvenliYaz(temiz, "final skoru kaydetme")
end

function M.isValid(score)
    return skorGecerli(score)
end

return M
