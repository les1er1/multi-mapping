local sw, sh = getScreenResolution()
require"lib.moonloader"
require"lib.sampfuncs"
local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local sampev = require 'lib.samp.events'

font = renderCreateFont('Arial', 8, 5)

local state = true

local mp = {
    notepad = imgui.new.char[65535](''),

    airbreak = false,
    airbreakSpeed = 0.76,
    ------------
    lastObjectClone = 0,
    lastObject = 0,
    ------------
    objRender = false,
    ------------
    rotation = 0
}

local renderWindow = imgui.new.bool(false)

local backgroundDraw = imgui.OnFrame(
    function() return true end,
    function(self)
        if state == false or isPauseMenuActive() then return end
        self.HideCursor = true
        local dl = imgui.GetBackgroundDrawList()

        local x, y, z = getCharCoordinates(PLAYER_PED)
        local angle = math.ceil(getCharHeading(PLAYER_PED))

        renderDrawBoxWithBorder(-2, sh - 30, sw + 3, 30, 0x8F000000, 2, 0xFF000000)

        dl:AddText(imgui.ImVec2(13, sh - 22), 0xFFFFFFFF, 'MULTI-MAPPING Build #0003');

        local locList = {
            {'[       Last Object Clone        ]', 0xFFC0C0C0},
            {'[ Last Object Clone (MOUSE) ]', 0xFF32CD32},
            {'[ Last Object Clone (    ID    ) ]', 0xFF32CD32}
        }

        local rotList = {
            {'[    90* Rotation   ]', 0xFFC0C0C0},
            {'[ 90* Rotation RZ ]', 0xFF32CD32},
            {'[ 90* Rotation RX ]', 0xFF32CD32},
            {'[ 90* Rotation RY ]', 0xFF32CD32}
        }

        dl:AddText(imgui.ImVec2(330, sh - 22), (mp.airbreak and 0xFF32CD32 or 0xFFC0C0C0), '[ AirBreak ]') -- airbreak
        dl:AddText(imgui.ImVec2(400, sh - 22), locList[mp.lastObjectClone+1][2], locList[mp.lastObjectClone+1][1]) -- last object clone
        dl:AddText(imgui.ImVec2(573, sh - 22), (mp.objRender and 0xFF32CD32 or 0xFFC0C0C0), '[ Object ID Render ]') -- obj render
        dl:AddText(imgui.ImVec2(695, sh - 22), rotList[mp.rotation+1][2], rotList[mp.rotation+1][1]) -- 90 rotation
        dl:AddText(imgui.ImVec2(180, sh - 22), 0xFFFFFF66, math.round(x, 1)..' '..math.round(y, 1)..' '..math.round(z, 1)..' '..angle)
        dl:AddText(imgui.ImVec2(sw - 108, sh - 22), 0xFF80BCFF, 'Last object: '..mp.lastObject)
        if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not isPauseMenuActive() and not sampIsDialogActive() then
            ------------------------ function switch block --------------------------

            if isKeyJustPressed(VK_Z) then -- last object clone switch
                if mp.lastObjectClone == 2 then mp.lastObjectClone = 0 return end
                mp.lastObjectClone = mp.lastObjectClone + 1
            end

            if isKeyJustPressed(VK_O) then -- obj render switch
                mp.objRender = not mp.objRender
            end

            if isKeyJustPressed(VK_OEM_4) then  -- 90 rotation switch
                if mp.rotation == 3 then mp.rotation = 0 return end
                mp.rotation = mp.rotation + 1
            end

            ------------------------------------------------------------------------

            if isKeyJustPressed(VK_J) then sampSendChat('/ocolor '..mp.lastObject..' 0 0xFFFFFFFF') end -- last object blackout

            if isKeyJustPressed(VK_B) then if not lastObject then sampSendChat('/oedit '..mp.lastObject) end end -- last object oedit
            if isKeyJustPressed(VK_M) then sampSendChat('/odell') end -- mouse odell

            if isKeyJustPressed(VK_OEM_1) then
                if mp.lastObject == 0 then return end
                sampSetChatInputEnabled(true)                         -- ; texture
                sampSetChatInputText('/texture '..mp.lastObject..' ')
            end

            if isKeyJustPressed(VK_OEM_7) then
                if mp.lastObject == nil then return end
                sampSetChatInputEnabled(true)                         -- ' stexture
                sampSetChatInputText('/stexture '..mp.lastObject..' ')
            end

            local rotationList = {
                {'/rz ', '/rx ', '/ry '}
            }
            if isKeyJustPressed(VK_R) then -- rotation
                if mp.lastObject == 0 or mp.rotation == 0 then return end
                sampSendChat(rotationList[mp.rotation]..mp.lastObject..' 90')
             end

            if isKeyJustPressed(VK_E) then -- create clipboard object
                if getClipboardText() == nil or string.len(getClipboardText()) > 5 then return end
                if getClipboardText():find('(%d+)') then
                    sampSendChat('/oa '..getClipboardText())
                end
            end

        end
    end
)


function main()
    while not isSampAvailable() do wait(0) end
    imgui.Process = true
    sampRegisterChatCommand('lo', function(arg)
        if tonumber(arg) == nil then
            mp.lastObject = 0
        elseif tonumber(arg) >= 1 and tonumber(arg) < 15000 then
            mp.lastObject = arg
        end
    end)
    sampRegisterChatCommand('note', function()
        renderWindow[0] = not renderWindow[0]
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
            if mp.airbreak then
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
        end
        if isKeyJustPressed(VK_F3) then
            state = not state
            imgui.Process = state
            mp.airbreak = false
        end
    end
end

function al()
    if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not isPauseMenuActive() then
        if isCharInAnyCar(PLAYER_PED) then setCarHeading(getCarCharIsUsing(PLAYER_PED), getHeadingFromVector2d(select(1, getActiveCameraPointAt()) - select(1, getActiveCameraCoordinates()), select(2, getActiveCameraPointAt()) - select(2, getActiveCameraCoordinates()))) if getDriverOfCar(getCarCharIsUsing(PLAYER_PED)) == -1 then speed = getFullSpeed(mp.airbreakSpeed, 0, 0) else speed = getFullSpeed(mp.airbreakSpeed, 0, 0) end else speed = getFullSpeed(mp.airbreakSpeed, 0, 0) setCharHeading(PLAYER_PED, getHeadingFromVector2d(select(1, getActiveCameraPointAt()) - select(1, getActiveCameraCoordinates()), select(2, getActiveCameraPointAt()) - select(2, getActiveCameraCoordinates()))) end

        if sampIsCursorActive() then goto mark end

        if isKeyDown(VK_SPACE) then airBrkCoords[3] = airBrkCoords[3] + speed / 2 elseif isKeyDown(VK_LSHIFT) and airBrkCoords[3] > -95.0 then airBrkCoords[3] = airBrkCoords[3] - speed / 2 end

        if isKeyDown(VK_W) then airBrkCoords[1] = airBrkCoords[1] + speed * math.sin(-math.rad(getCharHeading(PLAYER_PED))) airBrkCoords[2] = airBrkCoords[2] + speed * math.cos(-math.rad(getCharHeading(PLAYER_PED))) elseif isKeyDown(VK_S) then airBrkCoords[1] = airBrkCoords[1] - speed * math.sin(-math.rad(getCharHeading(PLAYER_PED))) airBrkCoords[2] = airBrkCoords[2] - speed * math.cos(-math.rad(getCharHeading(PLAYER_PED))) end
        if isKeyDown(VK_A) then airBrkCoords[1] = airBrkCoords[1] - speed * math.sin(-math.rad(getCharHeading(PLAYER_PED) - 90)) airBrkCoords[2] = airBrkCoords[2] - speed * math.cos(-math.rad(getCharHeading(PLAYER_PED) - 90)) elseif isKeyDown(VK_D) then airBrkCoords[1] = airBrkCoords[1] + speed * math.sin(-math.rad(getCharHeading(PLAYER_PED) - 90)) airBrkCoords[2] = airBrkCoords[2] + speed * math.cos(-math.rad(getCharHeading(PLAYER_PED) - 90)) end

        if isKeyDown(VK_ADD) then if mp.airbreakSpeed < 1.95 then mp.airbreakSpeed = mp.airbreakSpeed+0.01 end end
        if isKeyDown(0x6D) then if mp.airbreakSpeed > 0.1 then mp.airbreakSpeed = mp.airbreakSpeed-0.01 end end

        ::mark::
        setCharCoordinates(PLAYER_PED, airBrkCoords[1], airBrkCoords[2], airBrkCoords[3])

    end
end

function getMoveSpeed(heading, speed)
    moveSpeed = {x = math.sin(-math.rad(heading)) * (speed), y = math.cos(-math.rad(heading)) * (speed), z = 0} 
    return moveSpeed
end

function math.round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function sampev.onServerMessage(color, text)
    if state == false then return end
    if text:find('������ ������: (%d+)') then
        mp.lastObject = text:match('������ ������: (%d+)')
    end
end

function sampev.onSendCommand(command)
    if state == false then return end
    if command:find('oedit (%d+)') or command:find('oe (%d+)') then
        mp.lastObject = command:match('(%d+)')
        print(mp.lastObject)
    end
end

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 500, 500
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.Begin('Notepad', renderWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.InputTextMultiline('##notepad', mp.notepad, 65535, imgui.ImVec2(-0.1, -0.1))
        imgui.End()
   end
)

function getFullSpeed(speed, ping, min_ping) local fps = require('memory').getfloat(0xB7CB50, true) local result = (speed / (fps / 60)) if ping == 1 then local ping = sampGetPlayerPing(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) if min_ping < ping then result = (result / (min_ping / ping)) end end return result end function onWindowMessage(msg, wparam, lparam) if(msg == 0x100 or msg == 0x101) then if lparam == 3538945 and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsCursorActive() then airBrkCoords = {getCharCoordinates(PLAYER_PED)} if not isCharInAnyCar(PLAYER_PED) then airBrkCoords[3] = airBrkCoords[3] - 1 end lua_thread.create(al) end end end