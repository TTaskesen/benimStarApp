-- Yeni oyun ekranındaki gemi seçenekleri ve oynanış farkları.
local M = {}

local GEMILER = {
    { id = "avci", ad = "Hız Avcısı", aciklama = "Daha hızlı lazer doldurur.", renk = { 0.15, 0.65, 1 }, lazerAraligi = 240, olcek = 1.0 },
    { id = "muhafiz", ad = "Yıldız Muhafızı", aciklama = "Dengeli ve dayanıklı lazer atışı.", renk = { 0.2, 1, 0.3 }, lazerAraligi = 300, olcek = 1.08 },
    { id = "komutan", ad = "Kozmik Komutan", aciklama = "Y ekseninde düz ve hızlı lazer atışı.", renk = { 1, 0.55, 0.12 }, lazerAraligi = 240, olcek = 1.16 },
}

local INDEX = {}
for _, gemi in ipairs(GEMILER) do INDEX[gemi.id] = gemi end

function M.list()
    return GEMILER
end

function M.defaultId()
    return GEMILER[1].id
end

function M.normalize(id)
    return INDEX[id] and id or M.defaultId()
end

function M.get(id)
    return INDEX[M.normalize(id)]
end

function M.apply(object, id)
    local gemi = M.get(id)
    object.shipId = gemi.id
    object:setFillColor(gemi.renk[1], gemi.renk[2], gemi.renk[3])
    object.xScale = gemi.olcek
    object.yScale = gemi.olcek
    return gemi
end

function M.bombaMi(id, atisSayisi)
    return false
end

function M.enYakin(liste, x, y, ekHedef)
    local hedef
    local enKisa = math.huge
    for i = #liste, 1, -1 do
        local aday = liste[i]
        if aday and aday.parent then
            local dx, dy = aday.x - x, aday.y - y
            local uzaklik = dx * dx + dy * dy
            if uzaklik < enKisa then
                hedef, enKisa = aday, uzaklik
            end
        end
    end
    if ekHedef and ekHedef.parent then
        local dx, dy = ekHedef.x - x, ekHedef.y - y
        local uzaklik = dx * dx + dy * dy
        if uzaklik < enKisa then hedef = ekHedef end
    end
    return hedef
end

function M.alandakiHedefler(liste, x, y, yaricap, merkez)
    local bulunanlar = {}
    local yaricapKaresi = yaricap * yaricap
    for i = #liste, 1, -1 do
        local aday = liste[i]
        if aday ~= merkez and aday and aday.parent then
            local dx, dy = aday.x - x, aday.y - y
            if dx * dx + dy * dy <= yaricapKaresi then
                table.remove(liste, i)
                bulunanlar[#bulunanlar + 1] = aday
            end
        end
    end
    return bulunanlar
end

function M.hedefeYonelt(projectile, hedefler, dt, hiz, ekHedef)
    local hedef = projectile.hedef
    if not hedef or not hedef.parent then
        hedef = M.enYakin(hedefler, projectile.x, projectile.y, ekHedef)
        projectile.hedef = hedef
    end
    if not hedef then
        projectile.y = projectile.y - hiz * dt
        return
    end
    local dx, dy = hedef.x - projectile.x, hedef.y - projectile.y
    local uzaklik = math.sqrt(dx * dx + dy * dy)
    if uzaklik < 0.001 then return end
    local adim = math.min(hiz * dt, uzaklik)
    projectile.x = projectile.x + dx / uzaklik * adim
    projectile.y = projectile.y + dy / uzaklik * adim
end

function M.projeyiKaldir(projectile)
    if not projectile then return end
    if projectile.hedefTakip then
        Runtime:removeEventListener("enterFrame", projectile.hedefTakip)
        projectile.hedefTakip = nil
    end
    if projectile.parent then display.remove(projectile) end
end

return M
