local sw, sh = getScreenResolution()
require "lib.moonloader"
local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local sampev = require 'lib.samp.events'

font = renderCreateFont('Arial', 8, 5)

local state = true

local mp = {
    airbreak = false,
    airbreakSpeed = 1.0,
    ------------
    lastObjectClone = 0,
    lastObject = 0,
    ------------
    objRender = false,
    ------------
    rotation = 0
}

local backgroundDraw = imgui.OnFrame(
    function() return true end,
    function(self)
        if state == false then return end
        self.HideCursor = true
        local dl = imgui.GetBackgroundDrawList()
        local p = imgui.GetCursorScreenPos()
        renderDrawBoxWithBorder(-2, sh - 30, sw + 3, 30, 0x8F000000, 2, 0xFF000000)
        dl:AddText(imgui.ImVec2(13, sh - 22), 0xFFFFFFFF, 'MULTI-MAPPING Build #0002');
        local x, y, z = getCharCoordinates(PLAYER_PED)
        local angle = math.ceil(getCharHeading(PLAYER_PED))
        if mp.airbreak then dl:AddText(imgui.ImVec2(330, sh - 22), 0xFF32CD32, '[ AirBreak ]') else dl:AddText(imgui.ImVec2(330, sh - 22), 0xFFC0C0C0, '[ AirBreak ]') end
        if mp.objRender then dl:AddText(imgui.ImVec2(573, sh - 22), 0xFF32CD32, '[ Object ID Render ]') else dl:AddText(imgui.ImVec2(573, sh - 22), 0xFFC0C0C0, '[ Object ID Render ]') end
        if mp.rotation == 0 then dl:AddText(imgui.ImVec2(695, sh - 22), 0xFFC0C0C0, '[    90* Rotation   ]') elseif mp.rotation == 1 then dl:AddText(imgui.ImVec2(695, sh - 22), 0xFF32CD32, '[ 90* Rotation RZ ]') elseif mp.rotation == 2 then dl:AddText(imgui.ImVec2(695, sh - 22), 0xFF32CD32, '[ 90* Rotation RX ]') elseif mp.rotation == 3 then dl:AddText(imgui.ImVec2(695, sh - 22), 0xFF32CD32, '[ 90* Rotation RY ]') end
        if mp.lastObjectClone == 0 then dl:AddText(imgui.ImVec2(400, sh - 22), 0xFFC0C0C0, '[       Last Object Clone        ]') elseif mp.lastObjectClone == 1 then dl:AddText(imgui.ImVec2(400, sh - 22), 0xFF32CD32, '[ Last Object Clone (MOUSE) ]') elseif mp.lastObjectClone == 2 then dl:AddText(imgui.ImVec2(400, sh - 22), 0xFF32CD32, '[ Last Object Clone (    ID    ) ]') end
        dl:AddText(imgui.ImVec2(180, sh - 22), 0xFFFFFF66, math.round(x, 1)..' '..math.round(y, 1)..' '..math.round(z, 1)..' '..angle)
        if isKeyDown(VK_F9) then setClipboardText(math.round(x, 1)..' '..math.round(y, 1)..' '..math.round(z, 1)) end
        if isKeyDown(VK_F10) then setClipboardText(math.round(x, 1)..' '..math.round(y, 1)..' '..math.round(z, 1)..' '..angle) end
        if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not isPauseMenuActive() and not sampIsDialogActive() then
            if isKeyJustPressed(VK_Z) then
                if mp.lastObjectClone == 2 then
                    mp.lastObjectClone = 0
                    return end
                mp.lastObjectClone = mp.lastObjectClone + 1
             end
             if isKeyJustPressed(VK_O) then
                mp.objRender = not mp.objRender
             end
             if isKeyJustPressed(VK_B) then sampSendChat('/oedit') end
             if isKeyJustPressed(VK_M) then sampSendChat('/odell') end
             if isKeyJustPressed(VK_OEM_4) then
                if mp.rotation == 3 then
                    mp.rotation = 0
                return end
                mp.rotation = mp.rotation + 1
             end
        end
    end
)

function main()
    while not isSampAvailable() do wait(0) end
    imgui.Process = true
    sampRegisterChatCommand('lastobject', function(arg)
        mp.lastobject = arg
    end)
    while true do wait(0)
        if state then
            if isKeyJustPressed(VK_RSHIFT) then
                if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not isPauseMenuActive() and not sampIsDialogActive() then
                    mp.airbreak = not mp.airbreak
                    if mp.airbreak then
                        local posX, posY, posZ = getCharCoordinates(playerPed)
                        airBrkCoords = {posX, posY, posZ, 0.0, 0.0, getCharHeading(playerPed)}
                    end
                end
            end
            if isKeyJustPressed(VK_X) then
                if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not isPauseMenuActive() and not sampIsDialogActive() then
                    if mp.lastObjectClone == 1 then sampSendChat('/clone') end
                    if mp.lastObjectClone == 2 then sampSendChat('/clone '..mp.lastObject) end
                end
            end
            if mp.airbreak == true then
                al()
            end
            if mp.objRender then
                for _, v in pairs(getAllObjects()) do
                    if isObjectOnScreen(v) then
                        local _, x, y, z = getObjectCoordinates(v)
                        local x1, y1 = convert3DCoordsToScreen(x,y,z)
                        local model = getObjectModel(v)
                        renderFontDrawText(font, model, x1, y1, -1)
                    end
                end
            end
            if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not isPauseMenuActive() and not sampIsDialogActive() then
                if isKeyJustPressed(VK_R) then 
                    if mp.rotation == 1 then sampSendChat('/rz '..mp.lastObject..' 90')
                    elseif mp.rotation == 2 then sampSendChat('/rx '..mp.lastObject..' 90')
                    elseif mp.rotation == 3 then sampSendChat('/ry '..mp.lastObject..' 90') end
                end
                if isKeyJustPressed(VK_J) then sampSendChat('/ocolor '..mp.lastObject..' 0 0xFFFFFFFF') end
                if isKeyJustPressed(VK_E) then
                    clipboardText = getClipboardText()
                    if clipboardText:find('(%d+)') then
                        sampSendChat('/oa '..clipboardText)
                    end
                end
            end
        end
        if isKeyJustPressed(VK_F3) then
            state = not state
            imgui.Process = state
            mp.airbreak = false
        end
    end
end

function al()
    if state == false then return end
    if mp.airbreak then
        if isCharInAnyCar(playerPed) then heading = getCarHeading(storeCarCharIsInNoSave(playerPed))
        else heading = getCharHeading(playerPed) end
        local camCoordX, camCoordY, camCoordZ = getActiveCameraCoordinates()
        local targetCamX, targetCamY, targetCamZ = getActiveCameraPointAt()
        local angle = getHeadingFromVector2d(targetCamX - camCoordX, targetCamY - camCoordY)
        if isCharInAnyCar(playerPed) then difference = 0.79 else difference = 1.0 end
        setCharCoordinates(playerPed, airBrkCoords[1], airBrkCoords[2], airBrkCoords[3] - difference)
        if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not isPauseMenuActive() then
            if isKeyDown(VK_W) then
                airBrkCoords[1] = airBrkCoords[1] + mp.airbreakSpeed * math.sin(-math.rad(angle))
                airBrkCoords[2] = airBrkCoords[2] + mp.airbreakSpeed * math.cos(-math.rad(angle))
                if not isCharInAnyCar(playerPed) then setCharHeading(playerPed, angle)
                else setCarHeading(storeCarCharIsInNoSave(playerPed), angle) end
            elseif isKeyDown(VK_S) then
                airBrkCoords[1] = airBrkCoords[1] - mp.airbreakSpeed * math.sin(-math.rad(heading))
                airBrkCoords[2] = airBrkCoords[2] - mp.airbreakSpeed * math.cos(-math.rad(heading))
            end
            if isKeyDown(VK_A) then
                airBrkCoords[1] = airBrkCoords[1] - mp.airbreakSpeed * math.sin(-math.rad(heading - 90))
                airBrkCoords[2] = airBrkCoords[2] - mp.airbreakSpeed * math.cos(-math.rad(heading - 90))
            elseif isKeyDown(VK_D) then
                airBrkCoords[1] = airBrkCoords[1] - mp.airbreakSpeed * math.sin(-math.rad(heading + 90))
                airBrkCoords[2] = airBrkCoords[2] - mp.airbreakSpeed * math.cos(-math.rad(heading + 90))
            end
            if isKeyDown(VK_SPACE) or isKeyDown(VK_UP) then airBrkCoords[3] = airBrkCoords[3] + mp.airbreakSpeed / 2.0 end
            if isKeyDown(VK_LSHIFT) or isKeyDown(VK_DOWN) and airBrkCoords[3] > -95.0 then airBrkCoords[3] = airBrkCoords[3] - mp.airbreakSpeed / 2.0 end
            if isKeyDown(VK_ADD) then if mp.airbreakSpeed < 3.0 then mp.airbreakSpeed = mp.airbreakSpeed + 0.1 else mp.airbreakSpeed = 3.0 end end
            if isKeyDown(VK_SUBTRACT) then if mp.airbreakSpeed > 0.1 then mp.airbreakSpeed = mp.airbreakSpeed - 0.1 else mp.airbreakSpeed = 0.1 end end
        end
    end
end

function math.round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function sampev.onServerMessage(color, text)
    if state == false then return end
    if text:find('Создан объект: (%d+)') then
        mp.lastObject = text:match('Создан объект: (%d+)')
    end
end

function sampev.onSendCommand(command)
    if state == false then return end
    if command:find('oedit (%d+)') then
        mp.lastObject = command:match('oedit (%d+)')
    end
end