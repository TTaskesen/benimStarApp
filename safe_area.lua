local M = {}

function M.bounds()
    local left = display.safeScreenOriginX or display.screenOriginX or 0
    local top = display.safeScreenOriginY or display.screenOriginY or 0
    local width = display.safeActualContentWidth or display.contentWidth
    local height = display.safeActualContentHeight or display.contentHeight
    -- zoomEven'de uzun ekranlar içeriğin yatay kenarlarını kırpar; yerleşimi
    -- gerçekten görünen içerik genişliğine göre ortala.
    if display.viewableContentWidth and display.viewableContentWidth < width then
        width = display.viewableContentWidth
        left = display.contentCenterX - width * 0.5
    end
    return left, top, width, height
end

function M.center()
    local left, top, width, height = M.bounds()
    return left + width * 0.5, top + height * 0.5
end

return M
