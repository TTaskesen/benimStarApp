-- On saniyede bir gelen, aşağı hareket edip ateş eden küçük düşman gemileri.
local M = {}

local BONUSLAR = {
    { tur = "hiz", renk = { 0.25, 0.75, 1.0 } },
    { tur = "can", renk = { 0.25, 1.0, 0.35 } },
    { tur = "kalkan", renk = { 1.0, 0.78, 0.12 } },
}

function M.olustur(group, imageSheet, physics, ekranGenisligi, kategoriBits)
    local dusman = display.newImageRect(group, imageSheet, 4, 54, 44)
    dusman.x = math.random(70, math.max(71, ekranGenisligi - 70))
    dusman.y = -50
    -- Yukarıdan gelen düşman, hareket yönüne bakacak şekilde aşağı dönük görünür.
    dusman.rotation = 180
    dusman:setFillColor(0.95, 0.18, 0.18)
    local govde = { isSensor = true }
    if kategoriBits then govde.filter = { categoryBits = kategoriBits, maskBits = 1 } end
    physics.addBody(dusman, "kinematic", govde)
    dusman.myName = "dusmanGemi"
    dusman.hiz = 95
    dusman.atesEdildi = false
    return dusman
end

function M.atesle(group, imageSheet, physics, dusman, kategoriBits)
    local mermi = display.newImageRect(group, imageSheet, 5, 10, 28)
    mermi.x = dusman.x
    mermi.y = dusman.y + 28
    mermi:setFillColor(1, 0.3, 0.12)
    local govde = { isSensor = true }
    if kategoriBits then govde.filter = { categoryBits = kategoriBits, maskBits = 1 } end
    physics.addBody(mermi, "kinematic", govde)
    mermi.myName = "dusmanMermisi"
    mermi.hiz = 280
    return mermi
end

function M.bonusOlustur(group, physics, x, y, kategoriBits)
    local secim = BONUSLAR[math.random(#BONUSLAR)]
    local bonus = display.newText(group, "+", x, y, native.systemFontBold, 42)
    bonus:setFillColor(secim.renk[1], secim.renk[2], secim.renk[3])
    local govde = { isSensor = true, radius = 22 }
    if kategoriBits then govde.filter = { categoryBits = kategoriBits, maskBits = 1 } end
    physics.addBody(bonus, "kinematic", govde)
    bonus.myName = "bonus"
    bonus.tur = secim.tur
    bonus.hiz = 100
    return bonus
end

function M.guncelle(dusmanlar, mermiler, group, imageSheet, physics, dt, ekranGenisligi, ekranYuksekligi, kategoriBits)
    for i = #dusmanlar, 1, -1 do
        local dusman = dusmanlar[i]
        if not dusman.parent or dusman.y > ekranYuksekligi + 100 then
            if dusman.parent then display.remove(dusman) end
            table.remove(dusmanlar, i)
        else
            dusman.y = dusman.y + dusman.hiz * dt
            if not dusman.atesEdildi and dusman.y >= 120 then
                mermiler[#mermiler + 1] = M.atesle(group, imageSheet, physics, dusman, kategoriBits)
                dusman.atesEdildi = true
            end
        end
    end

    for i = #mermiler, 1, -1 do
        local mermi = mermiler[i]
        if not mermi.parent or mermi.y > ekranYuksekligi + 60 then
            if mermi.parent then display.remove(mermi) end
            table.remove(mermiler, i)
        else
            mermi.y = mermi.y + mermi.hiz * dt
        end
    end
end

function M.bonusGuncelle(bonuslar, dt, ekranYuksekligi)
    for i = #bonuslar, 1, -1 do
        local bonus = bonuslar[i]
        if not bonus.parent or bonus.y > ekranYuksekligi + 70 then
            if bonus.parent then display.remove(bonus) end
            table.remove(bonuslar, i)
        else
            bonus.y = bonus.y + bonus.hiz * dt
        end
    end
end

function M.listeCikar(liste, nesne)
    for i = #liste, 1, -1 do
        if liste[i] == nesne then
            table.remove(liste, i)
            return
        end
    end
end

function M.temizle(liste)
    for i = #liste, 1, -1 do
        if liste[i] and liste[i].parent then display.remove(liste[i]) end
        table.remove(liste, i)
    end
end

return M
