local json = require("json")

local M = {}
local VERSION = 1
local path = system.pathForFile("oyun_meta.json", system.DocumentsDirectory)
local temporaryPath = path and (path .. ".tmp") or nil

local ACHIEVEMENTS = {
    { id = "meteor_10", title = "İlk Seri", description = "10 meteor vur." },
    { id = "meteor_50", title = "Meteor Avcısı", description = "50 meteor vur." },
    { id = "meteor_100", title = "Yıldız Muhafızı", description = "100 meteor vur." },
    { id = "wave_1", title = "İlk Dalga", description = "İlk dalgayı tamamla." },
    { id = "score_1000", title = "Binlik Başlangıç", description = "1.000 puan kazan." },
    { id = "combo_3", title = "Üçlü Seri", description = "3x kombo yap." },
    { id = "no_damage_wave", title = "Hasarsız Geçiş", description = "Hasar almadan bir dalga tamamla." },
    { id = "reach_level_4", title = "Duvarların Ötesi", description = "Bölüm 4'e ulaş." },
    { id = "complete_game", title = "Yıldız Savaşı Ustası", description = "Oyunu tamamla." },
    { id = "daily_done", title = "Günlük Görev", description = "Bir günlük görevi tamamla." },
}

local DAILY_TASKS = {
    { id = "daily_meteor_10", title = "10 meteor vur", kind = "meteor", target = 10 },
    { id = "daily_score_500", title = "500 puan kazan", kind = "score", target = 500 },
    { id = "daily_wave_1", title = "Bir dalga tamamla", kind = "wave", target = 1 },
}

local function varsayilan()
    return { version = VERSION, tutorialSeen = false, achievements = {}, daily = {}, meteor = 0, score = 0 }
end

local function temizle(data)
    local result = varsayilan()
    if type(data) ~= "table" or data.version ~= VERSION then return result end
    result.tutorialSeen = data.tutorialSeen == true
    result.meteor = math.max(0, math.floor(tonumber(data.meteor) or 0))
    result.score = math.max(0, math.floor(tonumber(data.score) or 0))
    if type(data.achievements) == "table" then
        for id, unlocked in pairs(data.achievements) do
            if unlocked == true then result.achievements[tostring(id)] = true end
        end
    end
    if type(data.daily) == "table" then
        result.daily.date = type(data.daily.date) == "string" and data.daily.date or ""
        result.daily.taskId = type(data.daily.taskId) == "string" and data.daily.taskId or ""
        result.daily.progress = math.max(0, math.floor(tonumber(data.daily.progress) or 0))
        result.daily.completed = data.daily.completed == true
    end
    return result
end

local function kaydet(data)
    if not path or not temporaryPath then
        print("[oyun_meta] Meta kayıt yolu alınamadı.")
        return false
    end
    local ok, encoded = pcall(json.encode, temizle(data))
    if not ok or type(encoded) ~= "string" then
        print("[oyun_meta] Meta kayıt JSON'u kodlanamadı.")
        return false
    end
    local file, openError = io.open(temporaryPath, "w")
    if not file then
        print("[oyun_meta] Geçici meta kayıt açılamadı: " .. tostring(openError))
        return false
    end
    local wrote = file:write(encoded)
    local flushed = file:flush()
    local closed = file:close()
    if not wrote or not flushed or not closed then
        print("[oyun_meta] Meta kayıt yazılamadı.")
        os.remove(temporaryPath)
        return false
    end
    local renamed, renameError = os.rename(temporaryPath, path)
    if not renamed then
        print("[oyun_meta] Meta kayıt taşınamadı: " .. tostring(renameError))
        os.remove(temporaryPath)
        return false
    end
    return true
end

function M.load()
    if not path then return varsayilan() end
    local file = io.open(path, "r")
    if not file then return varsayilan() end
    local contents = file:read("*a")
    file:close()
    local ok, decoded = pcall(json.decode, contents or "")
    return ok and temizle(decoded) or varsayilan()
end

function M.save(data)
    return kaydet(data)
end

function M.setTutorialSeen(seen)
    local data = M.load()
    data.tutorialSeen = seen == true
    return kaydet(data)
end

function M.tutorialSeen()
    return M.load().tutorialSeen == true
end

function M.achievements()
    return ACHIEVEMENTS
end

function M.dailyTasks()
    return DAILY_TASKS
end

function M.unlock(id)
    local data = M.load()
    if data.achievements[id] then return false end
    data.achievements[id] = true
    return kaydet(data)
end

function M.isUnlocked(id)
    return M.load().achievements[id] == true
end

function M.ensureDaily()
    local data = M.load()
    local today = os.date("%Y-%m-%d")
    if data.daily.date ~= today then
        local index = (tonumber(os.date("%j")) or 1) % #DAILY_TASKS + 1
        data.daily = { date = today, taskId = DAILY_TASKS[index].id, progress = 0, completed = false }
        kaydet(data)
    end
    return data.daily
end

function M.record(eventName, amount)
    local data = M.load()
    amount = tonumber(amount) or 1
    local total = tonumber(data[eventName]) or 0
    data[eventName] = total + amount
    local newly = {}
    local thresholds = { meteor = {10, 50, 100}, score = {1000} }
    for _, threshold in ipairs(thresholds[eventName] or {}) do
        local id = eventName == "meteor" and ({[10]="meteor_10",[50]="meteor_50",[100]="meteor_100"})[threshold] or "score_1000"
        if total < threshold and data[eventName] >= threshold and not data.achievements[id] then
            data.achievements[id] = true
            table.insert(newly, id)
        end
    end
    local daily = data.daily
    if daily and daily.date == os.date("%Y-%m-%d") and not daily.completed then
        local task = nil
        for _, candidate in ipairs(DAILY_TASKS) do if candidate.id == daily.taskId then task = candidate break end end
        if task and ((task.kind == eventName) or (task.kind == "score" and eventName == "score")) then
            daily.progress = math.min(task.target, (daily.progress or 0) + amount)
            if daily.progress >= task.target then
                daily.completed = true
                data.achievements.daily_done = true
                table.insert(newly, "daily_done")
            end
        end
    end
    kaydet(data)
    return newly
end

function M.markWaveCompleted(noDamage)
    local data = M.load()
    local newly = {}
    if not data.achievements.wave_1 then data.achievements.wave_1 = true; table.insert(newly, "wave_1") end
    if noDamage and not data.achievements.no_damage_wave then data.achievements.no_damage_wave = true; table.insert(newly, "no_damage_wave") end
    local daily = data.daily
    if daily and daily.date == os.date("%Y-%m-%d") and daily.taskId == "daily_wave_1" and not daily.completed then
        daily.progress = 1
        daily.completed = true
        data.achievements.daily_done = true
        table.insert(newly, "daily_done")
    end
    kaydet(data)
    return newly
end

function M.markLevel4()
    local newly = {}
    if not M.isUnlocked("reach_level_4") then M.unlock("reach_level_4"); table.insert(newly, "reach_level_4") end
    return newly
end

function M.markComplete()
    if M.isUnlocked("complete_game") then return {} end
    M.unlock("complete_game")
    return { "complete_game" }
end

return M
