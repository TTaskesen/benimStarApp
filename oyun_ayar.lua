-- Dört bölümün oynanış dengesi tek yerde tutulur.
local M = {}

M.levels = {
    [1] = {
        hedef = 30, dalgaSayisi = 3, dalgaBasina = 10,
        hizBaslangic = 1.0, hizArtis = 0.02, hizTavan = 1.8,
        meteorAraligi = 500,
    },
    [2] = {
        hedef = 45, dalgaSayisi = 3, dalgaBasina = 15,
        hizBaslangic = 1.15, hizArtis = 0.025, hizTavan = 2.0,
        meteorAraligi = 470,
    },
    [3] = {
        hedef = 60, dalgaSayisi = 4, dalgaBasina = 15,
        meteorAraligi = 650,
    },
    [4] = {
        hedef = 75, dalgaSayisi = 5, dalgaBasina = 15,
        meteorAraligi = 650, duvarAraligi = 2600, duvarHizi = 114,
        gucAraligi = 8000, gucSuresi = 8000, cokluLazerAtis = 8, yavaslatmaCarpani = 0.55,
    },
}

function M.level(level)
    return M.levels[level] or M.levels[1]
end

function M.dalgaIlerlemesi(vurus, level)
    local ayar = M.level(level)
    local tamamlanan = math.min(ayar.dalgaSayisi - 1, math.floor((vurus or 0) / ayar.dalgaBasina))
    local icerde = (vurus or 0) - tamamlanan * ayar.dalgaBasina
    if icerde == 0 and vurus and vurus > 0 then icerde = ayar.dalgaBasina end
    return tamamlanan + 1, math.min(icerde, ayar.dalgaBasina)
end

return M
