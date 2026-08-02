-----------------------------------------------------------------------------------------
--
-- main_original.lua
--
-----------------------------------------------------------------------------------------

local fizikler = require( "physics" )
fizikler.start()
fizikler.setGravity( 0, 0 )

--Rastgele sayı üretme tohumu
math.randomseed(os.time())

--levha resimlerinin alınması
local levhaResimleriAl=
{
    frames = 
    {
        {-- 1) asteroid 1
            x= 0,
            y = 0,
            width = 102,
            height = 85
        },
        {-- 2) asteroid 2
            x= 0,
            y = 85,
            width = 90,
            height = 83
        },
        {-- 3) asteroid 3
            x= 0,
            y = 168,
            width = 100,
            height = 97
        },
        {-- 4) gemi
            x= 0,
            y = 265,
            width = 98,
            height = 79
        },
        {-- 5) lazer
            x= 98,
            y = 265,
            width = 14,
            height = 40
        },

    },
}
local resimLevha = graphics.newImageSheet("gameObjects.png",levhaResimleriAl)

--başlangıç verileri
local canlar = 3
local skor = 0
local olum = false
local asteroidTable = {}
local gemi
local oyundonguzamani
local canMetin
local skorMetin

--oyun gruplarının oluşturulması
local arkaPlanGroup = display.newGroup() --arkaplan resimlerinin gurubu
local anaGroup = display.newGroup()     -- gemi,asteroid,lazerlerin vb gurubu
local uiGroup = display.newGroup()      --ara yuz gurubu

--arkaplanın yüklenmesi
local arkaPlan = display.newImageRect(arkaPlanGroup, "background.png", 800, 1400)
arkaPlan.x = display.contentCenterX
arkaPlan.y = display.contentCenterY

--geminin yüklenmesi
gemi = display.newImageRect(anaGroup, resimLevha, 4, 98, 79)
gemi.x = display.contentCenterX
gemi.y = display.contentHeight - 100
fizikler.addBody(gemi, { radius = 30, isSensor = true } )
gemi.myName = "gemi"

-- Can ve skorların Eklenmesi
canMetin = display.newText(uiGroup, "Canlar: " .. canlar, 200, 80, native.systemFont, 40)
skorMetin = display.newText(uiGroup, "Skorunuz: " .. skor, 500, 80, native.systemFont, 40)

--tabletteki status barın gizlenmesi
display.setStatusBar(display.HiddenStatusBar)

--kullanıcı arayüzü textin güncellenmesi
local function metniGuncelle()
    canMetin.text = "Canlar: " ..canlar
    skorMetin.text = "Skorunuz: " ..skor
end

local function asteroidOlustur()

    local olusmaYeri = math.random(3)

    local yaniAsteroid_1 = display.newImageRect(anaGroup, resimLevha, 1, 102,85 )
    table.insert(asteroidTable, yaniAsteroid_1)
    fizikler.addBody(yaniAsteroid_1, "dynamic",{radius = 40, bounce = 0.8})
    yaniAsteroid_1.myName = "asteroid_1"
    yaniAsteroid_1:applyTorque(math.random(-6,6))
    

    --local yaniAsteroid_2 = display.newImageRect(anaGroup, resimLevha, 2, 90,83 )
    --table.insert(asteroidTable, yaniAsteroid_2)
    --fizikler.addBody(yaniAsteroid_2, "dynamic",{radius = 40, bounce = 0.8})
   -- yaniAsteroid_2.myName = "asteroid_2"
    --yaniAsteroid_2:applyTorque(math.random(-6,6))

    --local yaniAsteroid_3 = display.newImageRect(anaGroup, resimLevha, 3, 100,97 )
    --table.insert(asteroidTable, yaniAsteroid_3)
    --fizikler.addBody(yaniAsteroid_3, "dynamic",{radius = 40, bounce = 0.8})
    --yaniAsteroid_3.myName = "asteroid_3"
    --yaniAsteroid_3:applyTorque(math.random(-6,6))

    if (olusmaYeri == 1) then
        --soltraftan oluşma
        yaniAsteroid_1.x = -60
        yaniAsteroid_1.y = math.random( 500 )
        yaniAsteroid_1:setLinearVelocity(math.random(40,120), math.random(20,60))
    elseif ( olusmaYeri == 2) then
        --üstten oluşma
        yaniAsteroid_1.x = math.random(display.contentWidth)
        yaniAsteroid_1.y = -100
        yaniAsteroid_1:setLinearVelocity(math.random(-40,40), math.random(40,120))
    elseif ( olusmaYeri == 3) then
        --sağdan oluşma
        yaniAsteroid_1.x = display.contentWidth +60
        yaniAsteroid_1.y = math.random( 500 )
        yaniAsteroid_1:setLinearVelocity(math.random(-120,-40), math.random(20,60))
    end
    
end

local function lazeriAtesle()
    local yeniLazer = display.newImageRect(anaGroup, resimLevha, 5, 14,40)
    fizikler.addBody(yeniLazer, "dynamic", {isSensor = true})
    yeniLazer.isBullet = true
    yeniLazer.myName = "lazer"

    yeniLazer.x = gemi.x
    yeniLazer.y = gemi.y
    yeniLazer:toBack()

    transition.to(yeniLazer, {y = -40, time =500,
        onComplete = function() display.remove(yeniLazer)end
    })
end
gemi:addEventListener( "tap", lazeriAtesle)

local function hareketGemi(event)
    local gemi = event.target
    local faz = event.phase
    --dokunma odaklanması
    if( "began" == faz) then
        --dokunma odaklanması
        display.currentStage:setFocus(gemi)
        --başlangıç ofset pozisyonu
        gemi.touchOffsetX = event.x - gemi.x
        --gemi.touchOffset = event.y - gemi.y

    elseif("moved" == faz) then
        gemi.x= event.x - gemi.touchOffsetX
        --gemi.y= event.y - gemi.touchOffsetY
    
    elseif("ended" == faz or "cancelled" == faz) then
        --odaklanmanın boşa çıkması
        display.currentStage:setFocus(nil)
    end
    return true
end
gemi:addEventListener("touch", hareketGemi)

local function oyunDongu()
    --yeni asteroid fonksiyonunu çağır
    asteroidOlustur()
    for i = #asteroidTable, 1, -1 do
        local buAsteroid = asteroidTable[i]
        if(buAsteroid.x < -100 or
            buAsteroid.x > display.contentWidth + 100 or 
            buAsteroid.y < -100 or 
            buAsteroid.y > display.contentHeight +100)
        then
            display.remove(buAsteroid)
            table.remove(asteroidTable, i)

        end
    end
end
oyundonguzamani = timer.performWithDelay(500, oyunDongu, 0)

local function gemiTamir()
    gemi.isBodyActive = false
    gemi.x =display.contentCenterX
    gemi.y = display.contentHeight -100

    transition.to(gemi, { alpha = 1, time = 4000,
        onComplete = function()
            gemi.isBodyActive = true
            olum = false
        end
        })
end

local function carpisma(event)
    if(event.phase == "began") then
        local obj1 = event.object1
        local obj2 = event.object2
        if ((obj1.myName == "lazer" and obj2.myName == "asteroid_1") or
            (obj1.myName == "asteroid_1" and obj2.myName == "lazer"))
            then
            display.remove(obj1)
            display.remove(obj2)
            for i = #asteroidTable, 1, -1 do
                if (asteroidTable[i] == obj1 or asteroidTable[i] == obj2 ) then
                    table.remove(asteroidTable,i)
                    break
                end
            end
            skor = skor + 100
            skorMetin.text = "Skorunuz: " .. skor
        elseif ((obj1.myName == "gemi" and obj2.myName == "asteroid_1") or
                (obj1.myName == "asteroid_1" and obj2.myName == "gemi"))

        then
            if(olum == false) then
                olum = true
                --canı güncelle
                canlar = canlar - 1
                canMetin.text = "Canlar: " .. canlar
                if(canlar == 0) then
                    display.remove(gemi)
                else
                    gemi.alpha = 0
                    timer.performWithDelay(1000, gemiTamir)
                end
            end
        end
    end
end
Runtime:addEventListener ("collision", carpisma)