

local ENV = _G
pcall(function()
    if getgenv then
        ENV = getgenv()
    end
end)

if ENV.__ONIUM_RECORDER_CLEANUP then
    pcall(ENV.__ONIUM_RECORDER_CLEANUP)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local m_ = "ONIUM_RECORDER"
local ww = "rbxassetid://130280202431400"
local fl = true
local ph = true
local xguu = true
local iy = 0.004

local rmh = true
local ejd = true
local trxt = false
local gf = true
local ex = 0.001

local rk = true
local sli = true
local dxps = 6
local jpm = 0.94
local qeuz = 1.10
local sygc = 0.045
local eu = true
local uek_ = 0.0065
local mjr = 0.140

local fdfs = true
local fy = 0.0085
local uc = 0.0045
local _sj = 0.10
local dw = 0.055
local _gmw = 0.15

local rp = true
local vgol = 0.010
local f_jr = 0.045
local klt = 0.0085
local mdld = 0.030
local azq = 0.055
local zv = 0.85
local qfq = 7.5
local mak = -5.5
local va = 2

local mpm = 8
local slw = 500000
local zudm = 16

local _d = 45
local wz = 5.331189155578613

local akoq = 0.09
local ymaz = 0.02
local ug_y = 0.15

local ax = 0.07
local urke = 0.10

local l_ = 0.85
local lmg = 0.04

local kkuq = 18
local _lc = 0.12

local df_u = 1.12

local ierz = 0.006
local gxt = 0.18

local wnw = 0.12
local feb = 0.035
local wcpy = 2.5

local tuxi = 10
local xil = 0.35
local vqo = 10
local zhf = 80

local io = 9

local wq = 2.5
local ofya = math.max(5, math.floor(wq / iy))

local iri
local _px
local MiniLogo
local sw
local moq

local chnu
local dxay
local speedBox
local iq
local fzr
local wm
local fft
local w_uw
local fqh

local bu = {}
local obr = 1

local lqxi = nil
local snvn = true
local rc = 12
local _s = 0.46
local xw = 0.35

local wb = false
local xu = nil
local qtjy = 0
local pdd = 6
local ipr = 0.42
local da = 1.25
local rf = 8

CP_MARKER_LABEL_MAX_DISTANCE = 45
CP_MARKER_VISIBLE_DISTANCE = 70
CP_MARKER_CULL_INTERVAL = 0.35

local xbk = {}
local bzg_ = {}

local zd = false
local vft = false
local cek = false
local pa = 0
local ku = false
local fg = 0

local nee = 0
local bmj = true
local ucuz = false

local jckq = zudm
local hjo = zudm

local zu = nil
local eh = {}

local ye = nil
local duma = 0

local avbq = nil
local kkvu = nil
local pc = ""

local tgb = nil
local gktx = false

function hasEquippedToolSafe(char)
    char = char or LocalPlayer.Character
    if not char then
        return false
    end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            pc = obj.Name
            return true
        end
    end

    return false
end

function captureMapSpeedBeforePlayback()
    local char, hum = getCharacter()
    if not hum then
        return
    end

    tgb = tonumber(hum.WalkSpeed) or zudm
    gktx = hasEquippedToolSafe(char)
end

local yc
local ky
local wf
local brd
local le
local on
local mq
local ix
local _l
local zkk

function addConnection(c)
    if c then
        table.insert(eh, c)
    end
    return c
end

function cleanup()
    pcall(function()
        if zu then
            zu:Disconnect()
            zu = nil
        end
    end)

    for _, c in ipairs(eh) do
        pcall(function()
            c:Disconnect()
        end)
    end

    fg = fg + 1
    ku = false
    zd = false
    vft = false

    nee = 0
    bmj = true
    ucuz = false

    pcall(function()
        if lqxi then
            lqxi:Destroy()
            lqxi = nil
        end

        local old = workspace:FindFirstChild("ONIUM_MERGE_DOTS")
        if old then
            old:Destroy()
        end

        local oldCp = workspace:FindFirstChild("ONIUM_CP_MARKERS")
        if oldCp then
            oldCp:Destroy()
        end
    end)

    pcall(function()
        if iri then
            iri:Destroy()
        end
    end)
end

ENV.__ONIUM_RECORDER_CLEANUP = cleanup

function roundNumber(n, dec)
    dec = dec or 3
    local mult = 10 ^ dec
    return math.floor((tonumber(n) or 0) * mult + 0.5) / mult
end

function parseSpeedValue(raw, fallback)
    raw = tostring(raw or fallback or zudm)
    raw = raw:gsub(",", ".")
    raw = raw:gsub("[^%d%.%-]", "")

    local spd = tonumber(raw) or tonumber(fallback) or zudm
    spd = math.clamp(spd, mpm, slw)

    return roundNumber(spd, 1)
end

function setSyncBaseSpeed(value, updateBox)
    local spd = parseSpeedValue(value, hjo or jckq or zudm)

    jckq = spd
    hjo = spd

    if updateBox and speedBox then
        speedBox.Text = tostring(spd)
    end

    return spd
end

function trimText(s)
    s = tostring(s or "")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

function cleanFileName(s)
    s = trimText(s)
    s = s:gsub("[^%w_%-]", "_")
    if s == "" then
        s = "checkpoint"
    end
    return s
end

function vecToTable(v)

    return {
        x = roundNumber(v.X, 9),
        y = roundNumber(v.Y, 9),
        z = roundNumber(v.Z, 9)
    }
end

function tableToVec(t)
    if type(t) ~= "table" then
        return Vector3.new(0, 0, 0)
    end

    return Vector3.new(
        tonumber(t.x) or 0,
        tonumber(t.y) or 0,
        tonumber(t.z) or 0
    )
end

function horizontalDistance(a, b)
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function deepCopy(t)
    if type(t) ~= "table" then
        return t
    end

    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

function getCharacter()
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hum then
        hum = char:WaitForChild("Humanoid", 5)
    end

    if not hrp then
        hrp = char:WaitForChild("HumanoidRootPart", 5)
    end

    return char, hum, hrp
end

function restoreCharacterControl(speedOverride)
    local char, hum, hrp = getCharacter()

    local uro = tonumber(speedOverride)
        or tonumber(tgb)
        or tonumber(avbq)
        or tonumber(hum and hum.WalkSpeed)
        or zudm

    local toolNow = hasEquippedToolSafe(char)

    if toolNow then
        if tonumber(hum and hum.WalkSpeed) then
            uro = math.max(uro, tonumber(hum.WalkSpeed))
        end

        if tonumber(kkvu) then
            uro = math.max(uro, tonumber(kkvu))
        end
    else
        uro = tonumber(speedOverride)
            or tonumber(tgb)
            or tonumber(avbq)
            or zudm
    end

    uro = math.clamp(uro, mpm, slw)

    local function applyRestore()
        char, hum, hrp = getCharacter()
        local wsyn = hasEquippedToolSafe(char)

        if hum then
            pcall(function()
                hum.AutoRotate = true
                hum.PlatformStand = false
                hum.Sit = false

                if wsyn then

                    if (tonumber(hum.WalkSpeed) or 0) < uro - 0.1 then
                        hum.WalkSpeed = uro
                    end
                else

                    hum.WalkSpeed = uro
                end

                hum:Move(Vector3.new(0, 0, 0), true)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end

        if hrp then
            pcall(function()
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end

    applyRestore()

    task.delay(0.05, applyRestore)
    task.delay(0.15, applyRestore)

    if toolNow then
        task.delay(0.35, applyRestore)
    end
end
function getEquippedToolName(char)
    char = char or LocalPlayer.Character
    if not char then
        return ""
    end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            return obj.Name
        end
    end

    return ""
end

function getHumanoidStateName(hum)
    local state = "Unknown"

    pcall(function()
        state = tostring(hum:GetState())
        state = state:gsub("Enum.HumanoidStateType.", "")
    end)

    return state
end

function xswd(state)
    state = tostring(state or "")
    return state == "Jumping"
        or state == "Freefall"
        or state == "FallingDown"
        or state == "Climbing"
        or state == "Swimming"
end

function isMobileTouchDeviceSafe()
    local ok, result = pcall(function()
        local UIS = game:GetService("UserInputService")
        return UIS.TouchEnabled and not UIS.KeyboardEnabled
    end)
    return ok and result == true
end

function getHumanoidFloorMaterialNameSafe(hum)
    local ok, mat = pcall(function()
        return hum and hum.FloorMaterial
    end)

    if ok and mat then
        return tostring(mat):gsub("Enum.Material.", "")
    end

    return "Unknown"
end

function isGroundFloorMaterialName(name)
    name = tostring(name or "")
    name = name:gsub("Enum.Material.", "")
    return name ~= "" and name ~= "Air" and name ~= "Unknown" and name ~= "nil"
end

function mobileDeltaFrameHasGroundData(fr)
    if type(fr) ~= "table" or type(fr.ground) ~= "table" then
        return false
    end

    local g = fr.ground
    local key = tostring(g.path or g.name or "")
    return key ~= ""
end

function mobileDeltaFrameHasGroundContact(fr)
    if type(fr) ~= "table" then
        return false
    end

    if fr.grounded == true or fr.isGrounded == true then
        return true
    end

    if isGroundFloorMaterialName(fr.floorMaterial or fr.floor or fr.floorMat) then
        return true
    end

    local st = tostring(fr.states or fr.state or "")
    if mobileDeltaFrameHasGroundData(fr)
        and (st == "" or st == "Running" or st == "Landed" or st == "Walking" or st == "Standing" or st == "None" or st == "Unknown")
    then
        return true
    end

    return false
end

function mobileDeltaVelocityConfirmedAir(frames, index, yv)
    if type(frames) ~= "table" then
        return false
    end

    local need = math.max(1, tonumber(va) or 2)
    local upward = (tonumber(yv) or 0) >= (qfq or 7.5)
    local downward = (tonumber(yv) or 0) <= (mak or -5.5)

    if not upward and not downward then
        return false
    end

    local count = 0
    for j = math.max(1, index - 1), math.min(#frames, index + 1) do
        local fr = frames[j]
        if type(fr) == "table" and not mobileDeltaFrameHasGroundContact(fr) then
            local vy = tableToVec(fr.city).Y
            if upward and vy >= (qfq or 7.5) then
                count = count + 1
            elseif downward and vy <= (mak or -5.5) then
                count = count + 1
            end
        end
    end

    return count >= need
end

function frameIsMobileDeltaSafe(fr)
    if type(fr) ~= "table" then
        return false
    end

    return fr.mvi == true
        or fr.isMobileRecord == true
        or tostring(fr.inputDevice or "") == "MobileDelta"
        or tostring(fr.executorDevice or "") == "DeltaAndroid"
end

function framesLookMobileDeltaSafe(frames)
    if type(frames) ~= "table" or #frames <= 0 then
        return false
    end

    local btcg = 0
    local noShift = 0
    local total = 0
    local dtSum = 0
    local dtCount = 0
    local lastT = nil

    for _, fr in ipairs(frames) do
        if type(fr) == "table" then
            total = total + 1
            if frameIsMobileDeltaSafe(fr) then
                btcg = btcg + 1
            end
            if fr.sxzf == true or tostring(fr.ybk or "") == "AutoRotate" then
                noShift = noShift + 1
            end

            local t = tonumber(fr.times) or tonumber(fr.t)
            if t and lastT then
                local dt = t - lastT
                if dt > 0 and dt < 0.25 then
                    dtSum = dtSum + dt
                    dtCount = dtCount + 1
                end
            end
            if t then
                lastT = t
            end
        end
    end

    if total <= 0 then
        return false
    end

    if btcg >= math.max(1, math.floor(total * 0.10)) then
        return true
    end

    local avgDt = dtCount > 0 and (dtSum / dtCount) or 0
    return noShift >= math.max(5, math.floor(total * 0.72)) and avgDt >= 0.018
end

function mobileDeltaFixAirStateByVelocity(frames)
    if not rp or not framesLookMobileDeltaSafe(frames) then
        return frames or {}
    end

    local out = deepCopy(frames or {})
    for i, fr in ipairs(out) do
        if type(fr) == "table" then
            local st = tostring(fr.states or fr.state or "")
            local yv = tableToVec(fr.city).Y
            local grounded = mobileDeltaFrameHasGroundContact(fr)

            if st ~= "Climbing" and st ~= "Swimming" then
                if grounded then

                    if st == "Jumping" or st == "Freefall" or st == "FallingDown" or fr.jump == true then
                        fr.states = "Running"
                        fr.jump = false
                    end
                else

                    local snca = st == "Jumping" or st == "Freefall" or st == "FallingDown"
                    local pgb = mobileDeltaVelocityConfirmedAir(out, i, yv)

                    if snca or pgb then
                        if yv >= (qfq or 7.5) then
                            fr.states = "Jumping"
                            fr.jump = true
                        elseif yv <= (mak or -5.5) then
                            fr.states = "Freefall"
                            fr.jump = false
                        elseif snca then
                            if st == "FallingDown" then
                                fr.states = "Freefall"
                            end
                        end
                    end
                end
            end
        end
    end

    return out
end

function getSafeFullName(inst)
    local ok, result = pcall(function()
        return inst:GetFullName()
    end)

    if ok and result then
        return tostring(result)
    end

    return tostring(inst and inst.Name or "Unknown")
end

function normalizeGroundInfo(g)
    if type(g) ~= "table" then
        return nil
    end

    return {
        name = tostring(g.name or ""),
        class = tostring(g.class or ""),
        path = tostring(g.path or g.name or ""),
        position = {
            x = tonumber(g.position and g.position.x) or 0,
            y = tonumber(g.position and g.position.y) or 0,
            z = tonumber(g.position and g.position.z) or 0
        },
        hitPosition = {
            x = tonumber(g.hitPosition and g.hitPosition.x) or 0,
            y = tonumber(g.hitPosition and g.hitPosition.y) or 0,
            z = tonumber(g.hitPosition and g.hitPosition.z) or 0
        }
    }
end

function getGroundInfo(hrp)
    if not hrp then
        return nil
    end

    local char = LocalPlayer.Character
    local params = RaycastParams.new()

    pcall(function()
        params.FilterType = Enum.RaycastFilterType.Blacklist
    end)

    pcall(function()
        params.FilterDescendantsInstances = char and { char } or {}
    end)

    pcall(function()
        params.IgnoreWater = true
    end)

    local ok, result = pcall(function()
        return workspace:Raycast(
            hrp.Position,
            Vector3.new(0, -io, 0),
            params
        )
    end)

    if not ok or not result or not result.Instance then
        return nil
    end

    local inst = result.Instance
    local instPos = Vector3.new(0, 0, 0)

    pcall(function()
        instPos = inst.Position
    end)

    return {
        name = tostring(inst.Name),
        class = tostring(inst.ClassName),
        path = getSafeFullName(inst),
        position = vecToTable(instPos),
        hitPosition = vecToTable(result.Position)
    }
end

function groundKeyFromFrame(fr)
    if type(fr) ~= "table" or type(fr.ground) ~= "table" then
        return nil
    end

    local key = tostring(fr.ground.path or fr.ground.name or "")
    if key == "" then
        return nil
    end

    return key
end

local yfsq = 2

function getFrameYVelocity(fr)
    if type(fr) ~= "table" then
        return 0
    end

    local city = tableToVec(fr.city)
    return city.Y or 0
end

function isRollbackAirFrame(fr)
    if type(fr) ~= "table" then
        return false
    end

    local st = tostring(fr.states or fr.state or "")
    local yVel = getFrameYVelocity(fr)
    local fbv = groundKeyFromFrame(fr) ~= nil

    if fr.jump == true
        or st == "Jumping"
        or st == "Freefall"
        or st == "FallingDown"
    then
        return true
    end

    if not fbv and math.abs(yVel) > 1.5 then
        return true
    end

    return false
end

function isRollbackGroundFrame(fr)
    if type(fr) ~= "table" then
        return false
    end

    if isRollbackAirFrame(fr) then
        return false
    end

    local st = tostring(fr.states or fr.state or "")

    if st == "Climbing" or st == "Swimming" then
        return false
    end

    if groundKeyFromFrame(fr) ~= nil then
        return true
    end

    if st == "Running" or st == "Landed" then
        return true
    end

    return false
end

function findRollbackBeforeJumpIndex()
    local n = #xbk
    if n <= 2 then
        return nil, nil
    end

    local lu = nil
    for i = n, 1, -1 do
        if isRollbackAirFrame(xbk[i]) then
            lu = i
            break
        end
    end

    if not lu then
        return nil, nil
    end

    local airStart = lu
    while airStart > 1 and isRollbackAirFrame(xbk[airStart - 1]) do
        airStart = airStart - 1
    end

    local jy = nil
    for i = airStart - 1, 1, -1 do
        if isRollbackGroundFrame(xbk[i]) then
            jy = i
            break
        end
    end

    if not jy then
        return nil, nil
    end

    local zrar = math.max(1, jy - yfsq)

    for i = zrar, jy do
        if isRollbackGroundFrame(xbk[i]) then
            return i, "sebelum_lompat"
        end
    end

    return jy, "sebelum_lompat"
end

function formatTime(t)
    t = tonumber(t) or 0
    local minutes = math.floor(t / 60)
    local seconds = t - (minutes * 60)
    return string.format("%02d:%05.2f", minutes, seconds)
end

function notify(title, text, sec)
    title = tostring(title or "ONIUM")
    text = tostring(text or "")
    sec = sec or 2

    warn("[ONIUM Recorder] " .. title .. " - " .. text)

    if not moq then
        return
    end

    moq.Text = title .. " | " .. text
    moq.Visible = true

    task.delay(sec, function()
        if moq and moq.Text == title .. " | " .. text then
            moq.Visible = false
        end
    end)
end

function clearMergeDots()
    pcall(function()
        if lqxi then
            lqxi:Destroy()
            lqxi = nil
        end

        local old = workspace:FindFirstChild("ONIUM_MERGE_DOTS")
        if old then
            old:Destroy()
        end
    end)
end

function getMergeDotFolder()
    if lqxi and lqxi.Parent then
        return lqxi
    end

    local old = workspace:FindFirstChild("ONIUM_MERGE_DOTS")
    if old then
        old:Destroy()
    end

    lqxi = Instance.new("Folder")
    lqxi.Name = "ONIUM_MERGE_DOTS"
    lqxi.Parent = workspace

    return lqxi
end

function groundPositionForDot(pos)
    local origin = pos + Vector3.new(0, 8, 0)
    local cnd = Vector3.new(0, -60, 0)

    local params = RaycastParams.new()
    pcall(function()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
        params.IgnoreWater = true
    end)

    local ok, result = pcall(function()
        return workspace:Raycast(origin, cnd, params)
    end)

    if ok and result and result.Position then
        return result.Position + Vector3.new(0, xw, 0)
    end

    return pos + Vector3.new(0, xw, 0)
end

function makeBillboardLabel(parent, text, color)
    local bill = Instance.new("BillboardGui")
    bill.Name = "ONIUM_Label"
    bill.Size = UDim2.fromOffset(105, 26)
    bill.StudsOffset = Vector3.new(0, 1.7, 0)
    bill.AlwaysOnTop = false
    bill.MaxDistance = CP_MARKER_LABEL_MAX_DISTANCE
    bill.Parent = parent

    local bg = Instance.new("Frame")
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    bg.BackgroundTransparency = 0.15
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Parent = bill
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = bg
        local st = Instance.new("UIStroke")
        st.Color = color or Color3.fromRGB(255, 230, 60)
        st.Thickness = 1
        st.Transparency = 0.1
        st.Parent = bg
    end)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text = tostring(text or "CP")
    lbl.TextColor3 = color or Color3.fromRGB(255, 230, 60)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextStrokeTransparency = 0.25
    lbl.Size = UDim2.new(1, -8, 1, 0)
    lbl.Position = UDim2.fromOffset(4, 0)
    lbl.Parent = bg

    return bill
end

function createMarkerPart(folder, name, pos, color, size, shape)
    local p = Instance.new("Part")
    p.Name = tostring(name or "ONIUM_MARK")
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.Material = Enum.Material.Neon
    p.Color = color or Color3.fromRGB(255, 230, 60)
    p.Size = size or Vector3.new(ipr, ipr, ipr)
    p.Shape = shape or Enum.PartType.Ball
    p.CFrame = CFrame.new(pos)
    pcall(function() p:SetAttribute("BaseTransparency", p.Transparency) end)
    p.Parent = folder
    pcall(function()
        p.CanQuery = false
    end)
    return p
end

function createMergeDotPath(joinNumber, cpName, previousPos, joinPos)
    if not snvn then
        return
    end

    if typeof(previousPos) ~= "Vector3" then
        previousPos = tableToVec(previousPos)
    end

    if typeof(joinPos) ~= "Vector3" then
        joinPos = tableToVec(joinPos)
    end

    if previousPos.Magnitude <= 0 or joinPos.Magnitude <= 0 then
        return
    end

    local folder = getMergeDotFolder()
    local dist = (joinPos - previousPos).Magnitude

    local dotCount = rc
    if dist < 1 then
        dotCount = 2
    elseif dist > 30 then
        dotCount = 18
    end

    local firstDot = nil
    local lastDot = nil

    for n = 1, dotCount do
        local alpha = n / dotCount
        local rawPos = previousPos:Lerp(joinPos, alpha)
        local dotPos = groundPositionForDot(rawPos)
        local sizeMul = (n == 1 or n == dotCount) and 1.35 or 1

        local dot = createMarkerPart(
            folder,
            "JOIN_DOT_CP_" .. tostring(joinNumber) .. "_" .. tostring(n),
            dotPos,
            Color3.fromRGB(255, 230, 60),
            Vector3.new(_s * sizeMul, _s * sizeMul, _s * sizeMul),
            Enum.PartType.Ball
        )

        if not firstDot then
            firstDot = dot
        end
        lastDot = dot
    end

    if lastDot then
        makeBillboardLabel(
            lastDot,
            "SAMBUNG CP " .. tostring(joinNumber) .. "\n" .. tostring(cpName or "checkpoint"),
            Color3.fromRGB(255, 230, 60)
        )
    end

    if firstDot and lastDot and firstDot ~= lastDot then
        pcall(function()
            local a0 = Instance.new("Attachment")
            a0.Name = "ONIUM_BEAM_A"
            a0.Parent = firstDot
            local a1 = Instance.new("Attachment")
            a1.Name = "ONIUM_BEAM_B"
            a1.Parent = lastDot
            local beam = Instance.new("Beam")
            beam.Name = "ONIUM_JOIN_BEAM"
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.Width0 = 0.12
            beam.Width1 = 0.12
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.Transparency = NumberSequence.new(0.2)
            beam.Color = ColorSequence.new(Color3.fromRGB(255, 230, 60))
            beam.Parent = firstDot
        end)
    end
end

function clearCheckpointMarkers()

    qtjy = qtjy + 1

    pcall(function()
        local old = workspace:FindFirstChild("ONIUM_CP_MARKERS")
        if old then
            old:Destroy()
        end
    end)
end

function getCheckpointMarkerFolder()
    local old = workspace:FindFirstChild("ONIUM_CP_MARKERS")
    if old then
        return old
    end

    local folder = Instance.new("Folder")
    folder.Name = "ONIUM_CP_MARKERS"
    folder.Parent = workspace
    return folder
end

function getFramePosSafe(fr)
    if type(fr) ~= "table" then
        return nil
    end
    local pos = tableToVec(fr.position)
    if pos.Magnitude <= 0 then
        return nil
    end
    return pos
end

function startCheckpointMarkerDistanceCuller(folder)
    if not folder then
        return
    end

    qtjy = qtjy + 1
    local myToken = qtjy

    task.spawn(function()
        local bcbn = folder
        while myToken == qtjy and bcbn and bcbn.Parent do
            local _, _, hrp = getCharacter()
            if hrp then
                local myPos = hrp.Position
                for _, obj in ipairs(bcbn:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local visible = (obj.Position - myPos).Magnitude <= CP_MARKER_VISIBLE_DISTANCE
                        obj.Transparency = visible and (tonumber(obj:GetAttribute("BaseTransparency")) or 0) or 1
                    elseif obj:IsA("Beam") then
                        local a0 = obj.Attachment0
                        local a1 = obj.Attachment1
                        local p0 = a0 and a0.WorldPosition
                        local p1 = a1 and a1.WorldPosition
                        local visible = false
                        if p0 and p1 then
                            local mid = (p0 + p1) * 0.5
                            visible = (p0 - myPos).Magnitude <= CP_MARKER_VISIBLE_DISTANCE
                                or (p1 - myPos).Magnitude <= CP_MARKER_VISIBLE_DISTANCE
                                or (mid - myPos).Magnitude <= CP_MARKER_VISIBLE_DISTANCE
                        end
                        obj.Enabled = visible
                    end
                end
            end
            task.wait(CP_MARKER_CULL_INTERVAL)
        end
    end)
end

function createCheckpointMarker(cp, cpIndex)
    if not wb or not cp or type(cp.frames) ~= "table" or #cp.frames <= 0 then
        return
    end

    local folder = getCheckpointMarkerFolder()
    local frames = cp.frames
    local cpName = tostring(cp.name or ("checkpoint_" .. tostring(cpIndex)))
    local startPos = getFramePosSafe(frames[1])
    local endPos = getFramePosSafe(frames[#frames])

    if not startPos or not endPos then
        return
    end

    local uoe = groundPositionForDot(startPos) + Vector3.new(0, da, 0)
    local kf = groundPositionForDot(endPos) + Vector3.new(0, da, 0)

    local zfz = createMarkerPart(
        folder,
        "CP_" .. tostring(cpIndex) .. "_START",
        uoe,
        Color3.fromRGB(70, 255, 130),
        Vector3.new(ipr, ipr, ipr),
        Enum.PartType.Ball
    )
    makeBillboardLabel(zfz, "CP " .. tostring(cpIndex) .. " START\n" .. cpName, Color3.fromRGB(70, 255, 130))

    local endPart = createMarkerPart(
        folder,
        "CP_" .. tostring(cpIndex) .. "_END",
        kf,
        Color3.fromRGB(255, 95, 95),
        Vector3.new(ipr, ipr, ipr),
        Enum.PartType.Ball
    )
    makeBillboardLabel(endPart, "CP " .. tostring(cpIndex) .. " END", Color3.fromRGB(255, 95, 95))

    local count = math.min(rf, math.max(2, pdd))
    for n = 1, count do
        local idx = math.floor(1 + ((#frames - 1) * (n - 1) / math.max(count - 1, 1)))
        local pos = getFramePosSafe(frames[idx])
        if pos then
            local dotPos = groundPositionForDot(pos) + Vector3.new(0, 0.2, 0)
            local dot = createMarkerPart(
                folder,
                "CP_" .. tostring(cpIndex) .. "_PATH_" .. tostring(n),
                dotPos,
                Color3.fromRGB(80, 170, 255),
                Vector3.new(ipr * 0.62, ipr * 0.62, ipr * 0.62),
                Enum.PartType.Ball
            )
            if n == math.ceil(count / 2) then
                makeBillboardLabel(dot, "PATH CP " .. tostring(cpIndex), Color3.fromRGB(80, 170, 255))
            end
        end
    end
end

function refreshCheckpointMarkers()
    clearCheckpointMarkers()

    if not wb then
        return
    end

    local h_a = xu and tostring(xu) or nil
    local normal = {}

    for _, cp in ipairs(bu or {}) do
        if cp and not cp.isMerged and type(cp.frames) == "table" and #cp.frames > 0 then
            local cpName = tostring(cp.name or "")
            if not h_a or h_a == "" or cpName == h_a then
                table.insert(normal, cp)
            end
        end
    end

    if #normal <= 0 then
        return
    end

    table.sort(normal, function(a, b)
        return (a.order or 9999) < (b.order or 9999)
    end)

    for i, cp in ipairs(normal) do
        createCheckpointMarker(cp, i)

        if i % 2 == 0 then
            task.wait()
        end
    end

    startCheckpointMarkerDistanceCuller(workspace:FindFirstChild("ONIUM_CP_MARKERS"))
end

function updateCpMarkerToggleButton()
    if not fqh then
        return
    end

    if wb then
        if xu then
            fqh.Text = "CP 1"
        else
            fqh.Text = "CP ON"
        end
        fqh.BackgroundColor3 = Color3.fromRGB(55, 120, 80)
    else
        fqh.Text = "CP OFF"
        fqh.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    end
end

function setCheckpointMarkerMode(enabled, h_a, quiet)
    wb = enabled == true

    if wb then
        xu = h_a and tostring(h_a) or nil
        task.defer(refreshCheckpointMarkers)
    else
        xu = nil
        clearCheckpointMarkers()
    end

    updateCpMarkerToggleButton()

    if not quiet then
        if wb then
            if xu then
                notify("CP Marker", "ON hanya: " .. tostring(xu), 2)
            else
                notify("CP Marker", "ON semua checkpoint", 2)
            end
        else
            notify("CP Marker", "OFF. Save jadi lebih ringan.", 2)
        end
    end
end

function toggleCheckpointMarkersAll()
    if wb and not xu then
        setCheckpointMarkerMode(false, nil, false)
    else
        setCheckpointMarkerMode(true, nil, false)
    end
end

function toggleSingleCheckpointMarker(cp)
    local name = tostring(cp and cp.name or "")
    if name == "" then
        return
    end

    if wb and xu == name then
        setCheckpointMarkerMode(false, nil, false)
    else
        setCheckpointMarkerMode(true, name, false)
    end
end

function countMergeDots()
    local folder = workspace:FindFirstChild("ONIUM_MERGE_DOTS")
    local count = 0

    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            if tostring(obj.Name):find("JOIN_DOT_CP_") then
                count = count + 1
            end
        end
    end

    return count
end

function smoothStep(a)
    a = math.clamp(a, 0, 1)
    return a * a * (3 - 2 * a)
end

function lerpAngle(a, b, t)
    local delta = b - a
    delta = math.atan(math.sin(delta), math.cos(delta))
    return a + delta * t
end

function detectNoShiftLockRecord(hum, hrp)

    if not hum or not hrp then
        return false
    end

    local UIS = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer

    local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled and not UIS.KeyboardEnabled

    if isMobile then

        local mapLocks = false
        pcall(function()
            if lp and lp.DevEnableMouseLock then mapLocks = true end
            if hum.CameraOffset and hum.CameraOffset.Magnitude > 0.5 then mapLocks = true end
        end)

        return not mapLocks
    end

    local moveDir = hum.MoveDirection
    if moveDir.Magnitude < 0.05 then
        return false
    end

    local look = hrp.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z)

    if flatLook.Magnitude < 0.05 or flatMove.Magnitude < 0.05 then
        return false
    end

    local dot = flatLook.Unit:Dot(flatMove.Unit)
    return dot > 0.72
end

function isNoShiftLockFrame(fr)
    if type(fr) ~= "table" then
        return false
    end

    return fr.sxzf == true
        or fr.ybk == "AutoRotate"
end

function safeFunc(fn)
    return type(fn) == "function"
end

function ensureFolder()
    if safeFunc(isfolder) and safeFunc(makefolder) then
        local ok, exists = pcall(function()
            return isfolder(m_)
        end)

        if ok and not exists then
            pcall(function()
                makefolder(m_)
            end)
        elseif not ok then
            pcall(function()
                makefolder(m_)
            end)
        end
    elseif safeFunc(makefolder) then
        pcall(function()
            makefolder(m_)
        end)
    end
end

function decodeJSON(str)
    local ok, result = pcall(function()
        return HttpService:JSONDecode(str)
    end)

    if ok then
        return result
    end

    return nil
end

function filePathForName(name)
    return m_ .. "/" .. cleanFileName(name) .. ".json"
end

function retimeFramesForExport(frames)

    local source = basicNormalizeFrames(frames) or frames or {}
    local result = {}
    local wywl = nil
    local lastTime = nil
    local minDt = tonumber(ex) or 0.001

    for _, fr in ipairs(source) do
        if type(fr) == "table" then
            local copy = deepCopy(fr)
            local rawTime = tonumber(copy.times) or tonumber(copy.t) or 0

            if wywl == nil then
                wywl = rawTime
            end

            local t = rawTime - wywl

            if lastTime ~= nil and t <= lastTime then
                t = lastTime + minDt
            end

            copy.times = roundNumber(t, 9)
            copy.t = copy.times

            if copy.jqa == nil and copy.ws ~= nil then
                copy.jqa = copy.ws
            end
            if copy.ws == nil and copy.jqa ~= nil then
                copy.ws = copy.jqa
            end
            if type(copy.city) ~= "table" then
                copy.city = { x = 0, y = 0, z = 0 }
            end
            if type(copy.moveDirection) ~= "table" then
                copy.moveDirection = { x = 0, y = 0, z = 0 }
            end

            table.insert(result, copy)
            lastTime = copy.times
        end
    end

    return result
end

function prepareRawExactFramesForSave(frames)

    return retimeFramesForExport(frames), 0
end

function getFrameHorizontalCitySpeedForBitwise(fr)
    local city = tableToVec(fr and fr.city)
    return Vector3.new(city.X, 0, city.Z).Magnitude
end

function detectBitwiseBaseSpeed(frames)
    local wyf = {}
    local ll_ = {}

    for _, fr in ipairs(frames or {}) do
        if type(fr) == "table" then
            local ba = tostring(fr.states or fr.state or "Running")
            local hSpeed = getFrameHorizontalCitySpeedForBitwise(fr)
            local ws = tonumber(fr.jqa) or tonumber(fr.ws) or 0
            local nw = math.max(hSpeed, ws)

            if nw >= mpm then
                table.insert(ll_, nw)

                if ba == "Running" or ba == "Landed" then
                    table.insert(wyf, nw)
                end
            end
        end
    end

    local values = (#wyf >= 3) and wyf or ll_

    if #values <= 0 then
        return parseSpeedValue(hjo or jckq or zudm, zudm)
    end

    table.sort(values)

    local xlnp = math.max(1, math.floor(#values * 0.35))
    local endIndex = math.max(xlnp, math.ceil(#values * 0.75))
    local sum = 0
    local count = 0

    for i = xlnp, endIndex do
        sum = sum + (tonumber(values[i]) or 0)
        count = count + 1
    end

    local base = sum / math.max(count, 1)
    return math.clamp(roundNumber(base, 1), mpm, slw)
end

function autoMapIsGroundRunFrame(fr)
    if type(fr) ~= "table" then
        return false
    end

    local st = tostring(fr.states or fr.state or "Running")

    if st == "Jumping" or st == "Freefall" or st == "FallingDown" or st == "Climbing" or st == "Swimming" then
        return false
    end

    return st == "Running" or st == "Landed" or st == "RunningNoPhysics" or st == "Walking" or st == "None" or st == "Unknown" or st == ""
end

function autoMapFlatVecFromTable(t)
    local v = tableToVec(t)
    return Vector3.new(v.X, 0, v.Z)
end

function autoMapHorizontalCitySpeed(fr)
    return autoMapFlatVecFromTable(fr and fr.city).Magnitude
end

function autoMapMoveMagnitude(fr)
    return autoMapFlatVecFromTable(fr and fr.moveDirection).Magnitude
end

function autoMapFramePos(fr)
    return tableToVec(fr and fr.position)
end

function autoMapPercentile(values, q)
    if type(values) ~= "table" or #values <= 0 then
        return nil
    end

    table.sort(values)
    q = math.clamp(tonumber(q) or 0.5, 0, 1)
    local idx = math.floor(1 + (#values - 1) * q + 0.5)
    idx = math.clamp(idx, 1, #values)
    return tonumber(values[idx])
end

function autoMapAverageMiddle(values, q1, q2)
    if type(values) ~= "table" or #values <= 0 then
        return nil
    end

    table.sort(values)
    local s = math.clamp(math.floor(1 + (#values - 1) * (q1 or 0.55)), 1, #values)
    local e = math.clamp(math.ceil(1 + (#values - 1) * (q2 or 0.88)), s, #values)
    local sum = 0
    local count = 0

    for i = s, e do
        sum = sum + (tonumber(values[i]) or 0)
        count = count + 1
    end

    if count <= 0 then
        return nil
    end

    return sum / count
end

function autoMapDetectNormalRunSpeed(frames)
    local wsValues = {}
    local hValues = {}
    local fgcg = {}

    for _, fr in ipairs(frames or {}) do
        if autoMapIsGroundRunFrame(fr) then
            local ws = tonumber(fr.jqa) or tonumber(fr.ws) or 0
            local hs = autoMapHorizontalCitySpeed(fr)
            local md = autoMapMoveMagnitude(fr)

            if md >= (sygc or 0.045) or hs >= mpm then
                if ws >= mpm then
                    table.insert(wsValues, ws)
                    table.insert(fgcg, ws)
                end

                if hs >= mpm then
                    table.insert(hValues, hs)
                    table.insert(fgcg, hs)
                end
            end
        end
    end

    local _by = tonumber(dxps) or 6
    local wsBase = nil
    local hBase = nil

    if #wsValues >= _by then

        local wsMedian = autoMapPercentile(wsValues, 0.50)
        local wsHigh = autoMapPercentile(wsValues, 0.75)
        if wsMedian and wsHigh then
            wsBase = math.max(wsMedian, wsHigh)
        end
    end

    if #hValues >= _by then

        local q50 = autoMapPercentile(hValues, 0.50) or 0
        local q90 = autoMapPercentile(hValues, 0.90) or q50

        local filtered = {}
        local cap = math.max(mpm, q90 * 1.08)
        for _, v in ipairs(hValues) do
            v = tonumber(v) or 0
            if v >= mpm and v <= cap then
                table.insert(filtered, v)
            end
        end

        if #filtered >= math.max(3, math.floor(_by * 0.5)) then
            hBase = autoMapAverageMiddle(filtered, 0.58, 0.88) or autoMapPercentile(filtered, 0.75)
        else
            hBase = autoMapPercentile(hValues, 0.70)
        end
    end

    local base = nil
    if wsBase and hBase then

        base = math.max(wsBase, hBase)
    else
        base = wsBase or hBase
    end

    if not base and #fgcg > 0 then
        base = autoMapPercentile(fgcg, 0.75)
    end

    if not base or base < mpm then
        base = parseSpeedValue(hjo or jckq or zudm, zudm)
    end

    return math.clamp(roundNumber(base, 2), mpm, slw)
end

function autoMapDirectionFromAround(frames, index)
    local fr = frames and frames[index]
    if type(fr) ~= "table" then
        return Vector3.new(0, 0, 0)
    end

    local city = autoMapFlatVecFromTable(fr.city)
    if city.Magnitude > 0.05 then
        return city.Unit
    end

    local move = autoMapFlatVecFromTable(fr.moveDirection)
    if move.Magnitude > 0.05 then
        return move.Unit
    end

    local pos = autoMapFramePos(fr)
    local nextF = frames[index + 1]
    local prev = frames[index - 1]

    if nextF then
        local d = autoMapFramePos(nextF) - pos
        local flat = Vector3.new(d.X, 0, d.Z)
        if flat.Magnitude > 0.01 then
            return flat.Unit
        end
    end

    if prev then
        local d = pos - autoMapFramePos(prev)
        local flat = Vector3.new(d.X, 0, d.Z)
        if flat.Magnitude > 0.01 then
            return flat.Unit
        end
    end

    return Vector3.new(0, 0, 0)
end

function autoMapApplyNormalRunSpeed(frames, normalSpeed)
    if not rk or not sli then
        return frames, 0, normalSpeed
    end

    frames = basicNormalizeFrames(frames) or frames or {}
    if type(frames) ~= "table" or #frames <= 0 then
        return frames, 0, normalSpeed
    end

    normalSpeed = tonumber(normalSpeed) or autoMapDetectNormalRunSpeed(frames)
    normalSpeed = math.clamp(tonumber(normalSpeed) or zudm, mpm, slw)

    local changed = 0
    local gnp = normalSpeed * (tonumber(jpm) or 0.94)
    local bb = normalSpeed * (tonumber(qeuz) or 1.10)

    for i, fr in ipairs(frames) do
        if autoMapIsGroundRunFrame(fr) then
            local md = autoMapMoveMagnitude(fr)
            local hs = autoMapHorizontalCitySpeed(fr)
            local isMoving = md >= (sygc or 0.045) or hs >= (mpm * 0.45)

            if isMoving then
                local needFix = false

                if hs <= 0.05 or hs < gnp then
                    needFix = true
                end

                if hs > bb then
                    needFix = true
                end

                if needFix then
                    local dir = autoMapDirectionFromAround(frames, i)
                    if dir.Magnitude > 0.05 then
                        local oldCity = tableToVec(fr.city)
                        local newFlat = dir.Unit * normalSpeed
                        fr.city = {
                            x = roundNumber(newFlat.X, 9),
                            y = roundNumber(oldCity.Y, 9),
                            z = roundNumber(newFlat.Z, 9)
                        }
                        changed = changed + 1
                    end
                end

                local ws = tonumber(fr.jqa) or tonumber(fr.ws) or 0
                if ws < gnp or ws > bb then
                    fr.jqa = roundNumber(normalSpeed, 9)
                    fr.ws = fr.jqa
                else
                    fr.jqa = roundNumber(math.max(ws, normalSpeed), 9)
                    fr.ws = fr.jqa
                end
            end
        end
    end

    return frames, changed, normalSpeed
end

function autoMapRetuneRunTimes(frames, normalSpeed)
    if not eu then
        return frames
    end

    frames = frames or {}
    if #frames <= 1 then
        return frames
    end

    normalSpeed = tonumber(normalSpeed) or autoMapDetectNormalRunSpeed(frames)
    normalSpeed = math.max(tonumber(normalSpeed) or zudm, mpm)

    local out = {}
    local pdq = 0

    for i, fr in ipairs(frames) do
        local copy = deepCopy(fr)

        if i == 1 then
            pdq = 0
        else
            local prev = out[#out]
            local rawDt = (tonumber(fr.times) or tonumber(fr.t) or 0) - (tonumber(frames[i - 1].times) or tonumber(frames[i - 1].t) or 0)
            local dt = rawDt

            if autoMapIsGroundRunFrame(prev) and autoMapIsGroundRunFrame(fr) then
                local a = autoMapFramePos(prev)
                local b = autoMapFramePos(fr)
                local delta = b - a
                local hd = Vector3.new(delta.X, 0, delta.Z).Magnitude
                local md = math.max(autoMapMoveMagnitude(prev), autoMapMoveMagnitude(fr))

                if hd > 0.01 and md >= (sygc or 0.045) then
                    local bySpeed = hd / normalSpeed
                    local speedCap = normalSpeed * (tonumber(qeuz) or 1.10)
                    local ako = hd / math.max(speedCap, 1)

                    if dt <= 0 then
                        dt = bySpeed
                    elseif dt < ako then
                        dt = ako
                    elseif dt > (bySpeed * 1.18) then
                        dt = bySpeed
                    end
                end
            end

            if dt <= 0 then
                dt = tonumber(ex) or 0.001
            end

            local minDt = tonumber(uek_) or 0.0065
            local maxDt = tonumber(mjr) or 0.140
            dt = math.max(dt, minDt)
            dt = math.min(dt, maxDt)
            pdq = pdq + dt
        end

        copy.times = roundNumber(pdq, 9)
        copy.t = copy.times
        table.insert(out, copy)
    end

    return out
end

function autoMapCleanSpeedForSave(frames)
    if not rk then
        return frames, 0, nil
    end

    local normal = autoMapDetectNormalRunSpeed(frames)
    local changed = 0
    frames, changed, normal = autoMapApplyNormalRunSpeed(frames, normal)
    frames = autoMapRetuneRunTimes(frames, normal)
    frames, changed = autoMapApplyNormalRunSpeed(frames, normal)
    return frames, changed or 0, normal
end

function exportFrameForOniumRace(fr)
    fr = fr or {}

    local pos = tableToVec(fr.position)
    local yaw = tonumber(fr.rotation) or 0
    local moveDir = tableToVec(fr.moveDirection)
    local cityVec = tableToVec(fr.city)
    local ba = tostring(fr.states or fr.state or "Running")
    local ws
    if rmh and ejd then

        ws = tonumber(fr.jqa)
            or tonumber(fr.ws)
            or zudm
    else
        ws = tonumber(fr.__bitwiseBaseSpeed)
            or tonumber(fr.jqa)
            or tonumber(fr.ws)
            or zudm
    end
    local hip = tonumber(fr.hipHeight) or wz

    local naf = mobileDeltaFrameHasGroundContact(fr)
    local jumpFlag = (not naf) and (fr.jump == true or ba == "Jumping")

    if naf and (ba == "Jumping" or ba == "Freefall" or ba == "FallingDown") then
        ba = "Running"
    elseif ba == "FallingDown" then
        ba = "Freefall"
    end

    return {
        jump = jumpFlag == true,

        hipHeight = roundNumber(hip, 9),

        rotation = roundNumber(yaw, 9),

        moveDirection = {
            y = roundNumber(moveDir.Y, 9),
            x = roundNumber(moveDir.X, 9),
            z = roundNumber(moveDir.Z, 9)
        },

        city = {
            y = roundNumber(cityVec.Y, 9),
            x = roundNumber(cityVec.X, 9),
            z = roundNumber(cityVec.Z, 9)
        },

        position = {
            y = roundNumber(pos.Y, 9),
            x = roundNumber(pos.X, 9),
            z = roundNumber(pos.Z, 9)
        },

        times = roundNumber(fr.times or fr.t or 0, 9),

        jqa = roundNumber(ws, 9),

        tool = tostring(fr.tool or ""),

        states = ba
    }
end

function buildOniumRacePayload(name, frames)
    local p_ = {}
    local xxhu = retimeFramesForExport(frames or {})

    local bimc = nil
    if not rmh then
        bimc = detectBitwiseBaseSpeed(xxhu)
    end

    for i, fr in ipairs(xxhu) do
        local copy = deepCopy(fr)

        if not rmh then
            copy.__bitwiseBaseSpeed = bimc
        else
            copy.__bitwiseBaseSpeed = nil
        end

        p_[i] = exportFrameForOniumRace(copy)

        if i % 5000 == 0 then
            task.wait()
        end
    end

    return p_
end

function oniumJsonStringFast(v)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(tostring(v or ""))
    end)
    if ok and encoded then
        return encoded
    end
    return '""'
end

function oniumJsonNumberFast(v)
    return tostring(tonumber(v) or 0)
end

function oniumPayloadFrameToJson(fr)
    fr = fr or {}

    local md = fr.moveDirection or {}
    local cv = fr.city or {}
    local ps = fr.position or {}

    return "{"
        .. '"jump":' .. ((fr.jump == true) and "true" or "false")
        .. ',"hipHeight":' .. oniumJsonNumberFast(fr.hipHeight)
        .. ',"rotation":' .. oniumJsonNumberFast(fr.rotation)
        .. ',"moveDirection":{'
            .. '"y":' .. oniumJsonNumberFast(md.y)
            .. ',"x":' .. oniumJsonNumberFast(md.x)
            .. ',"z":' .. oniumJsonNumberFast(md.z)
        .. '}'
        .. ',"city":{'
            .. '"y":' .. oniumJsonNumberFast(cv.y)
            .. ',"x":' .. oniumJsonNumberFast(cv.x)
            .. ',"z":' .. oniumJsonNumberFast(cv.z)
        .. '}'
        .. ',"position":{'
            .. '"y":' .. oniumJsonNumberFast(ps.y)
            .. ',"x":' .. oniumJsonNumberFast(ps.x)
            .. ',"z":' .. oniumJsonNumberFast(ps.z)
        .. '}'
        .. ',"times":' .. oniumJsonNumberFast(fr.times)
        .. ',"jqa":' .. oniumJsonNumberFast(fr.jqa)
        .. ',"tool":' .. oniumJsonStringFast(fr.tool)
        .. ',"states":' .. oniumJsonStringFast(fr.states)
        .. "}"
end
function encodeOniumPayloadFast(payload)
    local chunks = {"["}
    for i, fr in ipairs(payload or {}) do
        if i > 1 then
            chunks[#chunks + 1] = ","
        end
        chunks[#chunks + 1] = oniumPayloadFrameToJson(fr)
        if i % 1800 == 0 then
            task.wait()
        end
    end
    chunks[#chunks + 1] = "]"
    return table.concat(chunks)
end

function saveFramesToFile(name, frames)
    ensureFolder()

    local path = filePathForName(name)
    local payload = buildOniumRacePayload(name, frames)
    local json = encodeOniumPayloadFast(payload)

    if not json then
        return false, "JSON encode cepat gagal", path
    end

    if not safeFunc(writefile) then
        return false, "writefile tidak tersedia, data disimpan memory saja", path
    end

    local ok, err = pcall(function()
        writefile(path, json)
    end)

    if ok then
        return true, "tersimpan", path
    end

    return false, tostring(err or "writefile error"), path
end

function readTextFile(path)
    if not safeFunc(readfile) then
        return nil
    end

    local ok, content = pcall(function()
        return readfile(path)
    end)

    if ok then
        return content
    end

    return nil
end

function deleteFile(path)
    if not safeFunc(delfile) then
        return false
    end

    local ok = pcall(function()
        delfile(path)
    end)

    return ok
end

function listSavedFiles()
    if not safeFunc(listfiles) then
        return nil
    end

    ensureFolder()

    local ok, files = pcall(function()
        return listfiles(m_)
    end)

    if ok and type(files) == "table" then
        return files
    end

    return nil
end

function basicNormalizeFrames(decoded)
    if type(decoded) ~= "table" then
        return nil
    end

    if type(decoded.frames) == "table" then
        decoded = decoded.frames
    elseif type(decoded.data) == "table" then
        if type(decoded.data.frames) == "table" then
            decoded = decoded.data.frames
        else
            decoded = decoded.data
        end
    end

    local frames = {}

    local function readPos(fr)
        if type(fr.position) == "table" then
            return {
                x = tonumber(fr.position.x or fr.position[1]) or 0,
                y = tonumber(fr.position.y or fr.position[2]) or 0,
                z = tonumber(fr.position.z or fr.position[3]) or 0
            }
        end

        if type(fr.pos) == "table" then
            return {
                x = tonumber(fr.pos.x or fr.pos[1]) or 0,
                y = tonumber(fr.pos.y or fr.pos[2]) or 0,
                z = tonumber(fr.pos.z or fr.pos[3]) or 0
            }
        end

        if fr.x ~= nil or fr.y ~= nil or fr.z ~= nil then
            return {
                x = tonumber(fr.x) or 0,
                y = tonumber(fr.y) or 0,
                z = tonumber(fr.z) or 0
            }
        end

        return nil
    end

    local function readYaw(fr)
        if fr.rotation ~= nil then
            return tonumber(fr.rotation) or 0
        end

        if fr.rot ~= nil then
            return tonumber(fr.rot) or 0
        end

        if fr.r00 ~= nil and fr.r20 ~= nil then
            local r00 = tonumber(fr.r00) or 1
            local r20 = tonumber(fr.r20) or 0
            return math.atan(-r20, r00)
        end

        return 0
    end

    local function readMoveDir(fr)
        if type(fr.moveDirection) == "table" then
            return {
                x = tonumber(fr.moveDirection.x or fr.moveDirection[1]) or 0,
                y = tonumber(fr.moveDirection.y or fr.moveDirection[2]) or 0,
                z = tonumber(fr.moveDirection.z or fr.moveDirection[3]) or 0
            }
        end

        return { x = 0, y = 0, z = 0 }
    end

    local function readCity(fr)
        if type(fr.city) == "table" then
            return {
                x = tonumber(fr.city.x or fr.city[1]) or 0,
                y = tonumber(fr.city.y or fr.city[2]) or 0,
                z = tonumber(fr.city.z or fr.city[3]) or 0
            }
        end

        if type(fr.velocity) == "table" then
            return {
                x = tonumber(fr.velocity.x or fr.velocity[1]) or 0,
                y = tonumber(fr.velocity.y or fr.velocity[2]) or 0,
                z = tonumber(fr.velocity.z or fr.velocity[3]) or 0
            }
        end

        return { x = 0, y = 0, z = 0 }
    end

    for _, fr in ipairs(decoded) do
        if type(fr) == "table" then
            local pos = readPos(fr)

            if pos then
                local ubo = tonumber(fr.times) or tonumber(fr.t) or tonumber(fr.time) or tonumber(fr.timestamp) or 0
                local rukf = tonumber(fr.ws) or tonumber(fr.jqa) or zudm
                local ba = tostring(fr.states or fr.state or "Running")

                local newFrame = {
                    jump = fr.jump == true or fr.jumping == true,
                    sxzf = fr.sxzf == true or fr.ybk == "AutoRotate",
                    ybk = tostring(fr.ybk or ((fr.sxzf == true) and "AutoRotate" or "ShiftLock")),
                    mvi = fr.mvi == true or fr.isMobileRecord == true or tostring(fr.inputDevice or "") == "MobileDelta",
                    inputDevice = tostring(fr.inputDevice or (fr.mvi == true and "MobileDelta" or "")),
                    executorDevice = tostring(fr.executorDevice or ""),
                    grounded = fr.grounded == true or fr.isGrounded == true,
                    floorMaterial = tostring(fr.floorMaterial or fr.floor or fr.floorMat or ""),
                    rawState = tostring(fr.rawState or fr.rawHumanoidState or ""),
                    hipHeight = tonumber(fr.hipHeight) or 2,
                    rotation = readYaw(fr),
                    ground = normalizeGroundInfo(fr.ground),
                    moveDirection = readMoveDir(fr),
                    city = readCity(fr),
                    position = pos,
                    times = ubo,
                    t = ubo,
                    jqa = rukf,
                    ws = rukf,
                    v = tonumber(fr.v) or nil,
                    tool = tostring(fr.tool or ""),
                    states = ba,
                    r00 = tonumber(fr.r00),
                    r01 = tonumber(fr.r01),
                    r02 = tonumber(fr.r02),
                    r10 = tonumber(fr.r10),
                    r11 = tonumber(fr.r11),
                    r12 = tonumber(fr.r12),
                    r20 = tonumber(fr.r20),
                    r21 = tonumber(fr.r21),
                    r22 = tonumber(fr.r22),
                    seam = fr.seam == true or fr._seam == true,
                    cutNext = fr.cutNext == true or fr._cutNext == true
                }

                table.insert(frames, newFrame)
            end
        end
    end

    if #frames <= 0 then
        return nil
    end

    table.sort(frames, function(a, b)
        return (tonumber(a.times) or 0) < (tonumber(b.times) or 0)
    end)

    return frames
end

function framePos(fr)
    return tableToVec(fr.position)
end

function frameMovedEnough(a, b)
    if not a or not b then
        return false
    end

    local pa = framePos(a)
    local pb = framePos(b)

    local hd = horizontalDistance(pa, pb)
    local vd = math.abs(pa.Y - pb.Y)

    return hd >= ax or vd >= urke
end

function hasRotationChange(a, b)
    if not a or not b then
        return false
    end

    local rotA = tonumber(a.rotation) or 0
    local rotB = tonumber(b.rotation) or 0
    local diff = math.abs(rotA - rotB)

    diff = math.min(diff, 2 * math.pi - diff)

    return diff > 0.12
end

function shouldKeepFrame(frames, i)
    local fr = frames[i]
    if not fr then
        return false
    end

    if fr.seam == true or fr.cutNext == true then
        return true
    end

    if fr.jump == true then
        return true
    end

    local prev = frames[i - 1]
    local nextF = frames[i + 1]

    if hasRotationChange(prev, fr) or hasRotationChange(fr, nextF) then
        return true
    end

    if xswd(fr.states) then
        local lpi = tostring(fr.states)

        if lpi == "Jumping" or lpi == "Freefall" or lpi == "FallingDown" then
            return true
        end

        if lpi == "Climbing" or lpi == "Swimming" then
            return true
        end

        if frameMovedEnough(prev, fr) or frameMovedEnough(fr, nextF) then
            return true
        end
    end

    if frameMovedEnough(prev, fr) then
        return true
    end

    if frameMovedEnough(fr, nextF) then
        return true
    end

    return false
end

function sanitizeFrames(decoded, retime)
    local frames = basicNormalizeFrames(decoded)
    if not frames then
        return nil
    end

    local cleaned = {}

    for i = 1, #frames do
        if shouldKeepFrame(frames, i) then
            local fr = deepCopy(frames[i])
            table.insert(cleaned, fr)
        end
    end

    local final = {}
    local lastKept = nil

    for _, fr in ipairs(cleaned) do
        if not lastKept then
            table.insert(final, fr)
            lastKept = fr
        else
            local keep = fr.seam == true or fr.cutNext == true or frameMovedEnough(lastKept, fr) or fr.jump == true or xswd(fr.states)

            if keep then
                table.insert(final, fr)
                lastKept = fr
            end
        end
    end

    if #final <= 0 then
        return nil
    end

    if retime then
        for i, fr in ipairs(final) do
            fr.times = roundNumber((i - 1) * iy, 4)
            fr.t = fr.times
        end
    end

    return final
end

function findCheckpointByName(name)
    name = tostring(name or "")

    for _, cp in ipairs(bu) do
        if cp.name == name then
            return cp
        end
    end

    return nil
end

function parseCheckpointNumber(name)
    local n = tostring(name or ""):match("^checkpoint_(%d+)$")
    if n then
        return tonumber(n)
    end
    return nil
end

function getNextDefaultName()
    local i = 1

    while findCheckpointByName("checkpoint_" .. tostring(i)) do
        i = i + 1
    end

    return "checkpoint_" .. tostring(i)
end

function upsertCheckpoint(name, frames, isMerged, path)
    name = cleanFileName(name)

    frames = basicNormalizeFrames(frames) or frames

    if type(frames) ~= "table" or #frames <= 0 then
        return false
    end

    local existing = findCheckpointByName(name)

    if existing then
        existing.frames = deepCopy(frames)
        existing.isMerged = isMerged == true
        existing.path = path or existing.path
    else
        local _osw = parseCheckpointNumber(name)
        local nk = _osw or obr

        table.insert(bu, {
            name = name,
            frames = deepCopy(frames),
            isMerged = isMerged == true,
            path = path or filePathForName(name),
            order = nk
        })

        if nk >= obr then
            obr = nk + 1
        else
            obr = obr + 1
        end
    end

    if yc then
        yc()
    end

    return true
end

function addCorner(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = obj
    return corner
end

function addStroke(obj, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(80, 80, 95)
    stroke.Transparency = transparency or 0.25
    stroke.Thickness = 1
    stroke.Parent = obj
    return stroke
end

function makeLabel(parent, text, size, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.TextSize = size or 13
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

function makeButton(parent, text, color)
    local btn = Instance.new("TextButton")
    btn.AutoButtonColor = true
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 58)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text or "Button"
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.Parent = parent
    addCorner(btn, 6)
    addStroke(btn, Color3.fromRGB(90, 90, 115), 0.45)
    return btn
end

function makeTextBox(parent, placeholder, defaultText)
    local box = Instance.new("TextBox")
    box.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
    box.PlaceholderText = placeholder or ""
    box.Text = defaultText or ""
    box.ClearTextOnFocus = false
    box.TextSize = 9
    box.Font = Enum.Font.Gotham
    box.Size = UDim2.new(1, 0, 0, 20)
    box.Parent = parent
    addCorner(box, 6)
    addStroke(box, Color3.fromRGB(75, 75, 95), 0.45)
    return box
end

function addSection(parent, text)
    local label = makeLabel(parent, text, 9, true)
    label.TextColor3 = Color3.fromRGB(160, 170, 255)
    label.Size = UDim2.new(1, 0, 0, 16)
    return label
end

function makeDraggable(frame, handle)
    local dragging = false
    local ay_e
    local startPos

    handle = handle or frame

    addConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            ay_e = input.Position
            startPos = frame.Position

            addConnection(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end))
        end
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - ay_e

        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end))
end

function bindButton(btn, callback)
    local debounce = false

    local function run()
        if debounce then
            return
        end

        debounce = true

        task.delay(0.18, function()
            debounce = false
        end)

        callback()
    end

    pcall(function()
        addConnection(btn.Activated:Connect(run))
    end)

    pcall(function()
        addConnection(btn.MouseButton1Click:Connect(run))
    end)
end

iri = Instance.new("iri")
iri.Name = "ONIUM Recorder"
iri.ResetOnSpawn = false
iri.IgnoreGuiInset = true
iri.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(iri)
    end
end)

local parentOk = pcall(function()
    iri.Parent = CoreGui
end)

if not parentOk or not iri.Parent then
    iri.Parent = PlayerGui
end

_px = Instance.new("Frame")
_px.Name = "MainWindow"
_px.Size = UDim2.fromOffset(410, 250)
_px.Position = UDim2.new(0.5, -205, 0.5, -125)
_px.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
_px.Parent = iri
addCorner(_px, 14)
addStroke(_px, Color3.fromRGB(105, 105, 150), 0.25)

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
Header.Parent = _px
addCorner(Header, 14)

local kdy = Instance.new("Frame")
kdy.BackgroundColor3 = Color3.fromRGB(36, 36, 52)
kdy.Size = UDim2.fromOffset(20, 20)
kdy.Position = UDim2.fromOffset(6, 5)
kdy.Parent = Header
addCorner(kdy, 10)
addStroke(kdy, Color3.fromRGB(110, 110, 160), 0.25)

local Logo = Instance.new("ImageLabel")
Logo.Name = "HeaderLogo"
Logo.BackgroundTransparency = 1
Logo.Image = ww
Logo.ScaleType = Enum.ScaleType.Fit
Logo.Size = UDim2.new(1, -4, 1, -4)
Logo.Position = UDim2.fromOffset(2, 2)
Logo.Parent = kdy

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Text = "ONIUM Recorder | BitWise Play"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextColor3 = Color3.fromRGB(245, 245, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Size = UDim2.new(1, -112, 1, 0)
Title.Position = UDim2.fromOffset(31, 0)
Title.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
MinBtn.Text = "–"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 15
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Size = UDim2.fromOffset(24, 20)
MinBtn.Position = UDim2.new(1, -54, 0, 5)
MinBtn.Parent = Header
addCorner(MinBtn, 8)

local CloseBtn = Instance.new("TextButton")
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 65)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Size = UDim2.fromOffset(24, 20)
CloseBtn.Position = UDim2.new(1, -27, 0, 5)
CloseBtn.Parent = Header
addCorner(CloseBtn, 8)

makeDraggable(_px, Header)

local Body = Instance.new("Frame")
Body.BackgroundTransparency = 1
Body.Size = UDim2.new(1, -10, 1, -38)
Body.Position = UDim2.fromOffset(5, 35)
Body.Parent = _px

local _w = Instance.new("Frame")
_w.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
_w.Size = UDim2.new(0, 138, 1, 0)
_w.Parent = Body
addCorner(_w, 12)
addStroke(_w, Color3.fromRGB(70, 70, 95), 0.45)

local LeftPad = Instance.new("UIPadding")
LeftPad.PaddingTop = UDim.new(0, 4)
LeftPad.PaddingBottom = UDim.new(0, 4)
LeftPad.PaddingLeft = UDim.new(0, 4)
LeftPad.PaddingRight = UDim.new(0, 4)
LeftPad.Parent = _w

local LeftList = Instance.new("UIListLayout")
LeftList.SortOrder = Enum.SortOrder.LayoutOrder
LeftList.Padding = UDim.new(0, 3)
LeftList.Parent = _w

addSection(_w, "CONTROLS")
local z_t = makeButton(_w, "● RECORD", Color3.fromRGB(180, 55, 70))
local _dqf = makeButton(_w, "SET SPEED", Color3.fromRGB(60, 65, 95))

addSection(_w, "PLAYBACK")
speedBox = makeTextBox(_w, "AUTO / isi speed", "AUTO")
local eggg = makeButton(_w, "STOP PLAY", Color3.fromRGB(155, 60, 65))

addSection(_w, "SAVE")
dxay = makeTextBox(_w, "name", "")
local SaveBtn = makeButton(_w, "SAVE", Color3.fromRGB(55, 110, 75))

local ke = Instance.new("Frame")
ke.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
ke.Size = UDim2.new(1, -144, 1, 0)
ke.Position = UDim2.fromOffset(144, 0)
ke.Parent = Body
addCorner(ke, 12)
addStroke(ke, Color3.fromRGB(70, 70, 95), 0.45)

local RightPad = Instance.new("UIPadding")
RightPad.PaddingTop = UDim.new(0, 4)
RightPad.PaddingBottom = UDim.new(0, 4)
RightPad.PaddingLeft = UDim.new(0, 4)
RightPad.PaddingRight = UDim.new(0, 4)
RightPad.Parent = ke

local rh = makeLabel(ke, "FOLDER", 12, true)
rh.TextColor3 = Color3.fromRGB(160, 170, 255)
rh.Size = UDim2.new(1, 0, 0, 14)
rh.Position = UDim2.fromOffset(0, 0)

local rt_ = Instance.new("Frame")
rt_.BackgroundTransparency = 1
rt_.Size = UDim2.new(1, 0, 0, 20)
rt_.Position = UDim2.fromOffset(0, 16)
rt_.Parent = ke

local ydhx = Instance.new("UIListLayout")
ydhx.FillDirection = Enum.FillDirection.Horizontal
ydhx.SortOrder = Enum.SortOrder.LayoutOrder
ydhx.Padding = UDim.new(0, 3)
ydhx.Parent = rt_

local utr = makeButton(rt_, "Del All", Color3.fromRGB(145, 55, 60))
utr.Size = UDim2.new(0.2, -4, 1, 0)

local ozd = makeButton(rt_, "Load", Color3.fromRGB(55, 80, 130))
ozd.Size = UDim2.new(0.2, -4, 1, 0)

local w_ct = makeButton(rt_, "Refresh", Color3.fromRGB(55, 95, 105))
w_ct.Size = UDim2.new(0.2, -4, 1, 0)

local MergeBtn = makeButton(rt_, "Merge", Color3.fromRGB(95, 70, 150))
MergeBtn.Size = UDim2.new(0.2, -4, 1, 0)

fqh = makeButton(rt_, "CP OFF", Color3.fromRGB(55, 55, 70))
fqh.Size = UDim2.new(0.2, -4, 1, 0)
updateCpMarkerToggleButton()

chnu = makeTextBox(ke, "Search checkpoint...", "")
chnu.Size = UDim2.new(1, 0, 0, 20)
chnu.Position = UDim2.fromOffset(0, 40)

iq = Instance.new("ScrollingFrame")
iq.Name = "CheckpointList"
iq.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
iq.Size = UDim2.new(1, 0, 1, -64)
iq.Position = UDim2.fromOffset(0, 62)
iq.ScrollBarThickness = 4
iq.CanvasSize = UDim2.fromOffset(0, 0)
iq.Parent = ke
addCorner(iq, 10)
addStroke(iq, Color3.fromRGB(65, 65, 90), 0.55)

local ListPad = Instance.new("UIPadding")
ListPad.PaddingTop = UDim.new(0, 4)
ListPad.PaddingBottom = UDim.new(0, 4)
ListPad.PaddingLeft = UDim.new(0, 4)
ListPad.PaddingRight = UDim.new(0, 4)
ListPad.Parent = iq

fzr = Instance.new("UIListLayout")
fzr.SortOrder = Enum.SortOrder.LayoutOrder
fzr.Padding = UDim.new(0, 4)
fzr.Parent = iq

addConnection(fzr:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    iq.CanvasSize = UDim2.fromOffset(0, fzr.AbsoluteContentSize.Y + 14)
end))

moq = Instance.new("TextLabel")
moq.Visible = false
moq.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
moq.TextColor3 = Color3.fromRGB(255, 255, 255)
moq.Font = Enum.Font.GothamBold
moq.TextSize = 9
moq.Size = UDim2.new(1, -10, 0, 18)
moq.Position = UDim2.new(0, 5, 1, -21)
moq.Parent = _px
addCorner(moq, 8)
addStroke(moq, Color3.fromRGB(90, 90, 130), 0.35)

MiniLogo = Instance.new("ImageButton")
MiniLogo.Name = "MiniLogo"
MiniLogo.Visible = false
MiniLogo.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
MiniLogo.Image = ww
MiniLogo.ScaleType = Enum.ScaleType.Fit
MiniLogo.Size = UDim2.fromOffset(38, 38)
MiniLogo.Position = UDim2.fromOffset(25, 170)
MiniLogo.Parent = iri
addCorner(MiniLogo, 19)
addStroke(MiniLogo, Color3.fromRGB(135, 135, 190), 0.2)
makeDraggable(MiniLogo, MiniLogo)

sw = Instance.new("Frame")
sw.Visible = false
sw.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
sw.Size = UDim2.fromOffset(154, 50)
sw.Position = UDim2.new(0.5, -77, 0.12, 0)
sw.Parent = iri
addCorner(sw, 8)
addStroke(sw, Color3.fromRGB(200, 65, 80), 0.15)

local meei = Instance.new("Frame")
meei.BackgroundColor3 = Color3.fromRGB(130, 35, 50)
meei.Size = UDim2.new(1, 0, 0, 16)
meei.Parent = sw
addCorner(meei, 8)
makeDraggable(sw, meei)

fft = Instance.new("TextLabel")
fft.BackgroundTransparency = 1
fft.Text = "● REC"
fft.TextColor3 = Color3.fromRGB(255, 255, 255)
fft.Font = Enum.Font.GothamBold
fft.TextSize = 9
fft.Size = UDim2.new(1, -12, 1, 0)
fft.Position = UDim2.fromOffset(6, 0)
fft.Parent = meei

wm = makeLabel(sw, "Timer: 00:00.00", 13, true)
wm.Size = UDim2.new(1, -20, 0, 0)
wm.Position = UDim2.fromOffset(10, 30)
wm.Visible = false

w_uw = makeLabel(sw, "Frames: 0", 12, false)
w_uw.Size = UDim2.new(1, -20, 0, 0)
w_uw.Position = UDim2.fromOffset(10, 30)
w_uw.Visible = false

local bcjk = Instance.new("Frame")
bcjk.BackgroundTransparency = 1
bcjk.Size = UDim2.new(1, -10, 0, 22)
bcjk.Position = UDim2.fromOffset(5, 23)
bcjk.Parent = sw

local qssy = Instance.new("UIListLayout")
qssy.FillDirection = Enum.FillDirection.Horizontal
qssy.Padding = UDim.new(0, 4)
qssy.Parent = bcjk

local StopBtn = makeButton(bcjk, "STOP", Color3.fromRGB(180, 55, 70))
StopBtn.Size = UDim2.new(0.5, -2, 1, 0)

local qpw = makeButton(bcjk, "ROLL", Color3.fromRGB(80, 95, 170))
qpw.Size = UDim2.new(0.5, -2, 1, 0)

local slv = -999
local ul = 0
local wsr = -999
local mnxl = nil
local pi = -999
local m_m = ""

function recordIsAirStateText(lpi)
    lpi = tostring(lpi or "")
    return lpi == "Jumping"
        or lpi == "Freefall"
        or lpi == "FallingDown"
end

function getRecordToolNameFast(char)
    if not fdfs then
        return getEquippedToolName(char)
    end

    local now = os.clock()
    if now - pi >= _gmw then
        m_m = getEquippedToolName(char)
        pi = now
    end

    return m_m or ""
end

function getRecordGroundInfoFast(hrp, ubo, lpi)
    if not fdfs then
        return getGroundInfo(hrp)
    end

    local t = tonumber(ubo) or os.clock()
    local st = tostring(lpi or "")
    local air = recordIsAirStateText(st)

    if (not air) and (not mnxl or (t - wsr) >= dw) then
        mnxl = getGroundInfo(hrp)
        wsr = t
    end

    if air then

        if (t - wsr) <= 0.14 then
            return mnxl
        end
        return nil
    end

    return mnxl
end

function getRecordDuration()
    if #xbk <= 0 then
        return 0
    end

    return tonumber(xbk[#xbk].times) or 0
end

function updateOverlay(p_u, force)
    local now = os.clock()

    if fdfs and zd and not force then
        if now - ul < _sj then
            return
        end
    end

    ul = now

    if wm then
        wm.Text = "Timer: " .. formatTime(p_u or getRecordDuration())
    end

    if w_uw then
        w_uw.Text = "Frames: " .. tostring(#xbk)
    end
end

function makeFrame(ubo, hum, hrp)
    local pos = hrp.Position
    local vel = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection

    local _, yaw, _ = hrp.CFrame:ToOrientation()
    local lpi = getHumanoidStateName(hum)
    local iqw = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local g_b = tonumber(hum.WalkSpeed) or zudm
    local mvi = isMobileTouchDeviceSafe()

    local sxzf = detectNoShiftLockRecord(hum, hrp)
    local ybk = sxzf and "AutoRotate" or "ShiftLock"

    local yo = lpi
    local zqu = getHumanoidFloorMaterialNameSafe(hum)
    local hx = isGroundFloorMaterialName(zqu)
    local jumpFlag = false
    local yVel = tonumber(vel.Y) or 0

    if lpi == "Climbing" or lpi == "Swimming" then
        jumpFlag = false
    elseif hx then

        if lpi == "Jumping" or lpi == "Freefall" or lpi == "FallingDown" then
            lpi = "Running"
        end
        jumpFlag = false
    elseif lpi == "Jumping" or lpi == "Freefall" or lpi == "FallingDown" then
        if yVel > 4 then
            lpi = "Jumping"
            jumpFlag = true
        else
            lpi = "Freefall"
            jumpFlag = false
        end
    elseif mvi and (not hx) and yVel >= (qfq or 7.5) then

        lpi = "Jumping"
        jumpFlag = true
    elseif mvi and (not hx) and yVel <= (mak or -5.5) then
        lpi = "Freefall"
        jumpFlag = false
    elseif lpi == "FallingDown" then
        lpi = "Freefall"
        jumpFlag = false
    end

    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = hrp.CFrame:GetComponents()

    return {
        jump = jumpFlag == true,
        sxzf = sxzf,
        ybk = ybk,
        mvi = mvi == true,
        inputDevice = mvi and "MobileDelta" or "PC",
        executorDevice = mvi and "DeltaAndroid" or "Desktop",
        grounded = hx == true,
        floorMaterial = zqu,
        rawState = yo,
        hipHeight = roundNumber(tonumber(hum.HipHeight) or wz, 9),
        rotation = roundNumber(yaw, 9),
        moveDirection = vecToTable(moveDir),
        city = vecToTable(vel),
        position = vecToTable(pos),
        times = roundNumber(ubo, 9),
        jqa = roundNumber(g_b, 9),
        tool = getRecordToolNameFast(LocalPlayer.Character),
        states = lpi,
        ground = getRecordGroundInfoFast(hrp, ubo, lpi),
        t = roundNumber(ubo, 9),
        x = roundNumber(x, 9),
        y = roundNumber(y, 9),
        z = roundNumber(z, 9),
        r00 = roundNumber(r00, 9),
        r01 = roundNumber(r01, 9),
        r02 = roundNumber(r02, 9),
        r10 = roundNumber(r10, 9),
        r11 = roundNumber(r11, 9),
        r12 = roundNumber(r12, 9),
        r20 = roundNumber(r20, 9),
        r21 = roundNumber(r21, 9),
        r22 = roundNumber(r22, 9),
        v = roundNumber(iqw, 9),
        ws = roundNumber(g_b, 9)
    }
end

local xsi_ = 0.1
local aqn = nil

function isRealMovement(hum, hrp, lastSavedPos)
    local pos = hrp.Position
    local vel = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection
    local lpi = getHumanoidStateName(hum)

    local hd = horizontalDistance(pos, lastSavedPos)
    local vd = math.abs(pos.Y - lastSavedPos.Y)
    local hv = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local vv = math.abs(vel.Y)

    local _, currentYaw, _ = hrp.CFrame:ToOrientation()
    local fhn = false
    if aqn then
        local diff = math.abs(currentYaw - aqn)
        diff = math.min(diff, 2 * math.pi - diff)
        fhn = diff > xsi_
    end
    aqn = currentYaw

    local ljn = hd >= akoq or vd >= 0.03
    local walking = moveDir.Magnitude >= ymaz and ljn
    local poo = hv >= ug_y and ljn

    local qwi =
        lpi == "Jumping"
        or lpi == "Freefall"
        or lpi == "FallingDown"
        or lpi == "Climbing"
        or lpi == "Swimming"

    local xwh = qwi and (
        ljn
        or vv >= 0.15
        or moveDir.Magnitude >= 0.01
    )

    return walking or poo or xwh or fhn
end

brd = function()
    if zd then
        notify("Record", "Recording sudah berjalan", 2)
        return
    end

    local char, hum, hrp = getCharacter()
    if not char or not hum or not hrp then
        notify("Record", "Character belum siap / belum spawn", 3)
        return
    end

    pcall(function()
        hum.Jump = false
        hum.PlatformStand = false
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)
    pcall(function()
        local v = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    avbq = tonumber(hum.WalkSpeed) or avbq
    kkvu = avbq
    pc = getEquippedToolName(char)

    local wj = tonumber(hum.WalkSpeed) or zudm
    jckq = wj
    hjo = wj

    if speedBox then
        speedBox.Text = tostring(roundNumber(wj, 3))
    end

    fg = fg + 1
    ku = false
    zd = true
    vft = false
    cek = false
    pa = pa + 1

    nee = 0
    bmj = true
    ucuz = false

    xbk = {}
    bzg_ = {}

    _px.Visible = false
    MiniLogo.Visible = false
    sw.Visible = true

    fft.Text = "● REC LIVE"
    wm.Text = "Timer: 00:00.00"
    w_uw.Text = "Frames: 0"

    duma = os.clock()
    ye = hrp.Position
    aqn = nil
    slv = -999
    ul = 0
    wsr = -999
    mnxl = nil
    pi = -999
    m_m = getEquippedToolName(char)

    local _of = getHumanoidStateName(hum)
    local hkam = wj
    local ef = m_m or ""
    local suc = duma

    local nhx = os.clock() + 0.35
    local vx
    vx = addConnection(RunService.Heartbeat:Connect(function()
        if not zd or os.clock() >= nhx then
            if vx then vx:Disconnect() vx = nil end
            return
        end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if h and r then
            pcall(function()
                h.Jump = false
                local v = r.AssemblyLinearVelocity
                if v.Y > 0 then
                    r.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                end
                local s = getHumanoidStateName(h)
                if s == "Jumping" or s == "Freefall" then
                    h:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end
    end))

    if zu then
        zu:Disconnect()
        zu = nil
    end

    zu = RunService.Heartbeat:Connect(function(dt)
        if not zd then return end
        if vft then return end

        local gh = LocalPlayer.Character
        if not gh then return end

        local dl = gh:FindFirstChildOfClass("Humanoid")
        local rim = gh:FindFirstChild("HumanoidRootPart")
        if not dl or not rim then return end

        local xf = tonumber(dl.WalkSpeed) or 0
        if xf > 0 then
            local vab = getRecordToolNameFast(gh)
            if vab ~= "" then
                pc = vab
                kkvu = math.max(tonumber(kkvu) or 0, xf)
            elseif not kkvu then
                kkvu = xf
            end
        end

        local p_u = os.clock() - suc

        local stNow = getHumanoidStateName(dl)
        local toolNow = getRecordToolNameFast(gh) or ""
        local wsNow = xf
        local floorNow = getHumanoidFloorMaterialNameSafe(dl)
        local hx = isGroundFloorMaterialName(floorNow)
        local isAir = recordIsAirStateText(stNow) and not hx

        local esq = (stNow ~= _of)
        local kqpy = (toolNow ~= ef)
        local afe = math.abs(wsNow - hkam) >= 0.5
        local jnza = esq or kqpy or afe

        local sampleDt = isAir and uc or fy
        local rdr = p_u - slv

        if not jnza and rdr < sampleDt then
            updateOverlay(p_u, false)
            return
        end

        if not jnza and not isAir then
            local moving = isRealMovement(dl, rim, ye)
            if not moving then

                if (p_u - slv) < 0.5 then
                    updateOverlay(p_u, false)
                    return
                end
            end
        end

        local fr = makeFrame(p_u, dl, rim)
        table.insert(xbk, fr)

        slv = p_u
        ye = rim.Position
        _of = stNow
        hkam = wsNow
        ef = toolNow

        updateOverlay(p_u, false)
    end)

    notify("Record", "LIVE record aktif: Delta no false jump gundukan + anti speed spike.", 3)
end

le = function()
    cek = true
    pa = pa + 1
    vft = false

    if qpw then
        qpw.Text = "ROLL"
        qpw.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
    end

    if not zd then
        sw.Visible = false
        _px.Visible = true
        restoreCharacterControl()
        return
    end

    zd = false

    if zu then
        zu:Disconnect()
        zu = nil
    end

    bzg_ = deepCopy(xbk) or {}

    sw.Visible = false
    _px.Visible = true

    restoreCharacterControl()

    if #bzg_ > 0 then
        if dxay and trimText(dxay.Text) == "" then
            dxay.Text = getNextDefaultName()
        end

        notify("Stop", "Record selesai. Frame bersih: " .. tostring(#bzg_), 3)
    else
        notify("Stop", "Tidak ada gerakan yang terekam", 3)
    end
end

function getFrameCFrame(fr)
    local pos = tableToVec(fr.position)
    local yaw = tonumber(fr.rotation) or 0
    return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

function applyFrameMeta(fr, hum)
    if not fr or not hum then
        return
    end

    if not ph then
        pcall(function()
            local ws = tonumber(fr.jqa)
            if ws and ws > 0 and ws > (tonumber(hum.WalkSpeed) or 0) then
                hum.WalkSpeed = ws
            end
        end)
    end

    if not xguu then
        pcall(function()
            hum.HipHeight = tonumber(fr.hipHeight) or hum.HipHeight
        end)
    end

    if fr.jump == true and not fl then
        pcall(function()
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end

    local st = tostring(fr.states or "")
    local now = os.clock()

    pcall(function()
        local xswd = (st == "Jumping" or st == "Freefall")
        local xc = now - nee

        if st == "Jumping" then

            if xc >= wnw then
                nee = now
                bmj = false

                if not ucuz then
                    ucuz = true
                    task.delay(feb, function()
                        pcall(function()
                            hum.Jump = true
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            ucuz = false
                        end)
                    end)
                end
            end
        elseif st == "Freefall" then
            if xc >= wnw then
                nee = now
                bmj = false
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        elseif st == "Climbing" then
            bmj = false
            hum:ChangeState(Enum.HumanoidStateType.Climbing)
        elseif st == "Swimming" then
            bmj = false
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
        elseif st == "Running" then

            if not bmj then
                nee = now
                bmj = true
            end
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

function equipFrameTool(fr, char, hum)
    if not fr or not fr.tool or fr.tool == "" then
        return
    end

    pcall(function()
        local toolName = tostring(fr.tool)

        if getEquippedToolName(char) ~= toolName then
            local tool = char:FindFirstChild(toolName)

            if not tool and LocalPlayer:FindFirstChild("Backpack") then
                tool = LocalPlayer.Backpack:FindFirstChild(toolName)
            end

            if tool and tool:IsA("Tool") then
                hum:EquipTool(tool)
            end
        end
    end)
end

function applyFrameInstant(fr)
    local char, hum, hrp = getCharacter()
    if not hum or not hrp or type(fr) ~= "table" then
        return
    end

    local sxzf = isNoShiftLockFrame(fr)

    pcall(function()
        hum.AutoRotate = false
    end)

    applyFrameMeta(fr, hum)
    equipFrameTool(fr, char, hum)

    local moveDir = tableToVec(fr.moveDirection)
    if moveDir.Magnitude > 0.01 then
        pcall(function()
            hum:Move(moveDir.Unit, true)
        end)
    end

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    pcall(function()
        local pos = tableToVec(fr.position)

        hrp.CFrame = getFrameCFrame(fr)
    end)
end

function getPlaybackFrameHorizontalSpeed(fr)
    if type(fr) ~= "table" then
        return 0
    end

    local city = tableToVec(fr.city)
    local h = Vector3.new(city.X, 0, city.Z).Magnitude
    if h > 0.05 then
        return h
    end

    local ws = tonumber(fr.jqa) or tonumber(fr.ws) or 0
    if ws > 0 then
        return ws
    end

    return 0
end

function isIdlePlaybackSegment(a, b)
    if not a or not b then return false end
    local sa = tostring(a.states or "")
    local sb = tostring(b.states or "")
    if sa == "Jumping" or sa == "Freefall" or sa == "FallingDown"
        or sb == "Jumping" or sb == "Freefall" or sb == "FallingDown"
        or a.jump == true or b.jump == true then
        return false
    end
    local pa = tableToVec(a.position)
    local pb = tableToVec(b.position)
    local hd = Vector3.new(pa.X - pb.X, 0, pa.Z - pb.Z).Magnitude
    local vd = math.abs(pa.Y - pb.Y)
    if hd > 0.18 or vd > 0.18 then return false end
    local ca = tableToVec(a.city); local cb = tableToVec(b.city)
    if Vector3.new(ca.X,0,ca.Z).Magnitude > 0.6 then return false end
    if Vector3.new(cb.X,0,cb.Z).Magnitude > 0.6 then return false end
    return true
end

function getCurrentHorizontalSpeed()
    local _, hum, hrp = getCharacter()
    if not hrp then
        return 0
    end

    local ok, vel = pcall(function()
        return hrp.AssemblyLinearVelocity
    end)

    if ok and vel then
        local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        if speed > 0.2 then
            return speed
        end
    end

    if hum then
        return tonumber(hum.WalkSpeed) or zudm
    end

    return zudm
end

function setSpeedFromCurrent()
    local spd = getCurrentHorizontalSpeed()

    if spd <= 0 then
        notify("Speed", "Speed tidak terdeteksi. Jalan dulu lalu pencet lagi.", 3)
        return
    end

    spd = setSyncBaseSpeed(spd, true)

    notify("Speed", "PLAYBACK SPEED diset: " .. tostring(spd) .. " stud/s", 3)
end

function buildBridgeFramesBetween(cst, nextFrame, stepDistance, maxFrames, maxDistance)
    local result = {}

    if not cst or not nextFrame then
        return result
    end

    stepDistance = tonumber(stepDistance) or l_
    maxFrames = tonumber(maxFrames) or zhf
    maxDistance = tonumber(maxDistance) or tuxi

    local p1 = tableToVec(cst.position)
    local p2 = tableToVec(nextFrame.position)
    local dist = (p2 - p1).Magnitude

    if dist > maxDistance then
        return result
    end

    if dist <= stepDistance then
        return result
    end

    local steps = math.ceil(dist / stepDistance)

    if steps < 2 then
        steps = 2
    end

    if steps > maxFrames then
        steps = maxFrames
    end

    local r1 = tonumber(cst.rotation) or 0
    local r2 = tonumber(nextFrame.rotation) or r1

    local t1 = tonumber(cst.times) or tonumber(cst.t) or 0
    local t2 = tonumber(nextFrame.times) or tonumber(nextFrame.t) or (t1 + iy * (steps + 1))
    if t2 <= t1 then
        t2 = t1 + iy * (steps + 1)
    end

    local dir = p2 - p1
    local moveDir = Vector3.new(0, 0, 0)
    if dir.Magnitude > 0.01 then
        moveDir = dir.Unit
    end

    local yud = math.clamp(dist / math.max(t2 - t1, iy), 8, slw)

    for i = 1, steps do
        local alpha = i / (steps + 1)
        local eased = smoothStep(alpha)
        local pos = p1:Lerp(p2, eased)
        local rot = lerpAngle(r1, r2, eased)

        local fr = deepCopy(nextFrame)
        fr.jump = false
        fr.states = "Running"
        fr.position = vecToTable(pos)
        fr.rotation = roundNumber(rot, 5)
        fr.moveDirection = vecToTable(moveDir)
        fr.city = vecToTable(moveDir * yud)
        fr.ground = nil
        fr.times = roundNumber(t1 + ((t2 - t1) * alpha), 9)
        fr.t = fr.times

        table.insert(result, fr)
    end

    return result
end

function normalizePlaybackTimesKeepOriginal(frames)
    local result = {}
    local baseT = nil
    local lastT = 0

    for i, fr in ipairs(frames or {}) do
        local copy = deepCopy(fr)
        local rawT = tonumber(copy.times) or tonumber(copy.t) or 0

        if not baseT then
            baseT = rawT
        end

        local t = rawT - baseT
        if i == 1 then
            t = 0
        elseif t <= lastT then
            local prev = result[#result]
            local hd = prev and horizontalDistance(tableToVec(prev.position), tableToVec(copy.position)) or 0
            local spd = math.max(getPlaybackFrameHorizontalSpeed(prev), getPlaybackFrameHorizontalSpeed(copy), zudm)
            t = lastT + math.clamp(hd / math.max(spd, 1), ierz, gxt)
        end

        copy.times = roundNumber(t, 9)
        copy.t = copy.times
        table.insert(result, copy)
        lastT = t
    end

    return result
end

function preparePlaybackFrames(rawFrames)

    local clean = sanitizeFrames(rawFrames, false)
    if not clean or #clean <= 0 then
        return nil
    end

    local result = {}
    local cst = nil

    for _, fr in ipairs(clean) do
        local newFrame = deepCopy(fr)

        if not cst then
            table.insert(result, newFrame)
            cst = newFrame
        else
            local lastPos = tableToVec(cst.position)
            local newPos = tableToVec(newFrame.position)
            local dist = (newPos - lastPos).Magnitude
            local forceCut = newFrame.seam == true or cst.cutNext == true or dist > tuxi

            if forceCut then
                newFrame.seam = true
                table.insert(result, newFrame)
                cst = newFrame
            elseif dist < lmg and newFrame.jump ~= true and not xswd(newFrame.states) then

            else
                if dist > (l_ * 2.4) then
                    local bridge = buildBridgeFramesBetween(cst, newFrame, l_, zhf, tuxi)

                    for _, bridgeFrame in ipairs(bridge) do
                        table.insert(result, bridgeFrame)
                        cst = bridgeFrame
                    end
                end

                table.insert(result, newFrame)
                cst = newFrame
            end
        end
    end

    if #result <= 0 then
        return nil
    end

    return normalizePlaybackTimesKeepOriginal(result)
end

function setPlaybackButtonState(active)
    if not eggg then
        return
    end

    if active then
        eggg.Text = "STOP PLAY"
        eggg.BackgroundColor3 = Color3.fromRGB(190, 70, 75)
    else
        eggg.Text = "STOP PLAY"
        eggg.BackgroundColor3 = Color3.fromRGB(155, 60, 65)
    end
end

wf = function(showMsg)
    if not ku then
        if showMsg then
            notify("Playback", "Tidak ada playback yang berjalan", 2)
        end
        return
    end

    fg = fg + 1
    ku = false
    setPlaybackButtonState(false)

    local _, hum, hrp = getCharacter()
    if hrp then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end

    if hum then
        pcall(function()
            hum:Move(Vector3.new(0, 0, 0), true)
        end)
    end

    restoreCharacterControl()

    if showMsg then
        notify("Playback", "Playback distop", 2)
    end
end

function getFrameStateText(fr)
    return tostring((fr and (fr.states or fr.state)) or "Running")
end

function isJumpStateText(st)
    st = tostring(st or "")
    return st == "Jumping" or st == "Freefall" or st == "FallingDown"
end

function getFrameVelocityVector(fr)
    if type(fr) ~= "table" then
        return Vector3.new(0, 0, 0)
    end

    local city = tableToVec(fr.city)
    if city.Magnitude > 0.05 then
        return city
    end

    if type(fr.velocity) == "table" then
        local v = tableToVec(fr.velocity)
        if v.Magnitude > 0.05 then
            return v
        end
    end

    return Vector3.new(0, 0, 0)
end

function getFrameHorizontalVelocity(fr)
    local v = getFrameVelocityVector(fr)
    return Vector3.new(v.X, 0, v.Z).Magnitude
end

function estimateRecordedPlaybackSpeedBitwise(frames)
    local values = {}

    for i, fr in ipairs(frames or {}) do
        local nn = getFrameHorizontalVelocity(fr)
        local jqa = tonumber(fr.jqa) or tonumber(fr.ws) or 0
        local value = math.max(nn, jqa)

        if value >= mpm and value <= slw then
            table.insert(values, value)
        end

        if i > 1 then
            local prev = frames[i - 1]
            local dt = (tonumber(fr.times) or tonumber(fr.t) or 0) - (tonumber(prev.times) or tonumber(prev.t) or 0)
            if dt > 0.002 then
                local hd = horizontalDistance(tableToVec(prev.position), tableToVec(fr.position))
                local spd = hd / dt
                if spd >= mpm and spd <= slw then
                    table.insert(values, spd)
                end
            end
        end
    end

    if #values <= 0 then
        return zudm
    end

    table.sort(values)

    local idx = math.floor(#values * 0.75)
    if idx < 1 then
        idx = 1
    end

    return roundNumber(math.clamp(values[idx] or zudm, mpm, slw), 1)
end

function getPlaybackSpeedForFrames(frames)
    local vael = estimateRecordedPlaybackSpeedBitwise(frames)
    local raw = tostring(speedBox and speedBox.Text or "AUTO")
    raw = raw:gsub(",", ".")
    raw = raw:gsub("^%s+", "")
    raw = raw:gsub("%s+$", "")

    local manual = tonumber(raw)
    if manual and manual > 0 then
        manual = math.clamp(manual, mpm, slw)
        jckq = manual

        hjo = vael
        return roundNumber(manual, 1), true, vael
    end

    jckq = vael
    hjo = vael

    if speedBox then
        speedBox.Text = "AUTO"
    end

    return vael, false, vael
end

function findPreparedFrameAtTimeFast(frames, ubo)
    if not frames or #frames <= 1 then
        return 1
    end

    local left = 1
    local right = #frames - 1

    while left <= right do
        local mid = math.floor((left + right) / 2)
        local a = frames[mid]
        local b = frames[mid + 1]
        local ta = tonumber(a.times) or tonumber(a.t) or 0
        local tb = tonumber(b.times) or tonumber(b.t) or ta

        if ubo >= ta and ubo <= tb then
            return mid
        elseif ubo < ta then
            right = mid - 1
        else
            left = mid + 1
        end
    end

    if ubo <= 0 then
        return 1
    end

    return math.max(1, #frames - 1)
end

function applyFrameBitwiseStyle(a, b, alpha, hum, hrp, sjt, mi)
    if not a or not b or not hum or not hrp then
        return
    end

    local pa = tableToVec(a.position)
    local pb = tableToVec(b.position)

    local ra = tonumber(a.rotation) or 0
    local rb = tonumber(b.rotation) or ra

    local eased = math.clamp(alpha or 0, 0, 1)
    local tq = pa:Lerp(pb, eased)
    local yaw = lerpAngle(ra, rb, eased)

    local st = getFrameStateText(b)

    if isIdlePlaybackSegment(a, b) then
        pcall(function()
            hum.AutoRotate = false
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.CFrame = CFrame.new(pa) * CFrame.Angles(0, ra, 0)
            hum:ChangeState(Enum.HumanoidStateType.Standing)
            hum.Sit = false
            hum.PlatformStand = false
        end)
        return
    end

    if RUN_PLAYBACK_VISUAL_GUARD
        and not isJumpStateText(st)
        and st ~= "Freefall"
        and st ~= "FallingDown"
        and st ~= "Climbing"
        and st ~= "Swimming"
        and b.seam ~= true
        and a.cutNext ~= true
        and hrp
    then
        local nowPos = hrp.Position
        local kzq = (tq - nowPos).Magnitude
        if kzq > (RUN_PLAYBACK_BIG_GAP_DISTANCE or 6.2) then
            local step = math.max(RUN_PLAYBACK_MAX_VISUAL_STEP or 4.25, 1)
            tq = nowPos:Lerp(tq, math.clamp(step / kzq, 0.05, 1))
        end
    end

    local timeDiff = (tonumber(b.times) or tonumber(b.t) or 0) - (tonumber(a.times) or tonumber(a.t) or 0)
    if timeDiff <= 0.001 then
        timeDiff = iy
    end

    local mapVel = getFrameVelocityVector(b)
    if mapVel.Magnitude < 0.05 then
        mapVel = (pb - pa) / math.max(timeDiff, 0.001)
    end

    local spdMul = math.clamp(tonumber(sjt) or 1, 0.05, 25)
    mapVel = mapVel * spdMul

    local sr = (pb - pa) / math.max(timeDiff, 0.001)
    sr = sr * spdMul

    local moveDir = tableToVec(b.moveDirection)
    if moveDir.Magnitude > 0.01 then
        pcall(function()
            hum:Move(moveDir.Unit, true)
        end)
    end

    pcall(function()
        local targetWs = tonumber(mi) or tonumber(b.jqa) or zudm
        hum.WalkSpeed = math.clamp(targetWs, mpm, slw)
        hum.Sit = false
        hum.PlatformStand = false

        if not xguu then
            hum.HipHeight = tonumber(b.hipHeight) or hum.HipHeight
        end
    end)

    local kdob = (b.jump == true) or isJumpStateText(st)
    local uofn = st == "Freefall" or st == "FallingDown" or sr.Y < -2 or mapVel.Y < -2
    local hs = st == "Climbing"
    local hf = st == "Swimming"

    if bmj and math.abs(sr.Y) < wcpy then

        kdob = false
        uofn = false
    end

    pcall(function()

        hum.AutoRotate = false
        hrp.CFrame = CFrame.new(tq) * CFrame.Angles(0, yaw, 0)

        local hVel = Vector3.new(mapVel.X, 0, mapVel.Z)

        local mnf = math.max(
            getFrameHorizontalVelocity(a),
            getFrameHorizontalVelocity(b),
            tonumber(mi) or zudm,
            mpm
        )
        local dv = math.max(mnf * df_u, mpm)

        if hVel.Magnitude > dv then
            hVel = hVel.Unit * dv
        end

        local yVel = math.clamp(mapVel.Y, -220, 170)

        if kdob then

            local fhX = sr.X
            local fhZ = sr.Z
            local fhMag = math.sqrt(fhX * fhX + fhZ * fhZ)
            if fhMag > dv and fhMag > 0 then
                local k = dv / fhMag
                fhX, fhZ = fhX * k, fhZ * k
            end
            local fyVel = math.clamp(sr.Y, -500, 300)

            hrp.AssemblyLinearVelocity = Vector3.new(fhX, fyVel, fhZ)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

            if uofn then
                hum.Jump = false
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            else
                hum.Jump = true
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end

        elseif hs then
            hrp.AssemblyLinearVelocity = Vector3.new(hVel.X * 0.25, math.clamp(yVel, -50, 50), hVel.Z * 0.25)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hum:ChangeState(Enum.HumanoidStateType.Climbing)

        elseif hf then
            hrp.AssemblyLinearVelocity = Vector3.new(hVel.X, yVel, hVel.Z)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hum:ChangeState(Enum.HumanoidStateType.Swimming)

        else

            hrp.AssemblyLinearVelocity = Vector3.new(hVel.X, math.clamp(yVel, -80, 80), hVel.Z)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

            if hVel.Magnitude > 0.45 then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            else
                hum:ChangeState(Enum.HumanoidStateType.Standing)
            end
        end
    end)
end

function findNearestPreparedFrameToPosition(frames, position)
    if not frames or #frames <= 0 or typeof(position) ~= "Vector3" then
        return 1, 0
    end

    local bfu = 1
    local hp = (tableToVec(frames[1].position) - position).Magnitude
    local step = math.max(1, math.floor(#frames / 500))

    for i = 1, #frames, step do
        local pos = tableToVec(frames[i].position)
        local distance = (pos - position).Magnitude
        if distance < hp then
            hp = distance
            bfu = i
        end
    end

    local dc = math.min(step, 50)
    for i = math.max(1, bfu - dc), math.min(#frames, bfu + dc) do
        local pos = tableToVec(frames[i].position)
        local distance = (pos - position).Magnitude
        if distance < hp then
            hp = distance
            bfu = i
        end
    end

    return bfu, hp
end

function getBitwiseSmartStartForOnium(frames)
    local _, hum, hrp = getCharacter()
    if not hrp or not frames or #frames < 2 then
        return 1, tonumber(frames and frames[1] and (frames[1].times or frames[1].t)) or 0
    end

    local firstT = tonumber(frames[1].times) or tonumber(frames[1].t) or 0
    local lastT = tonumber(frames[#frames].times) or tonumber(frames[#frames].t) or firstT
    local gam = math.max(lastT - _lc, firstT)

    local startPos = tableToVec(frames[1].position)
    local ek = tableToVec(frames[#frames].position)
    local ftnt = (ek - hrp.Position).Magnitude

    local bfu, distanceTo = findNearestPreparedFrameToPosition(frames, hrp.Position)
    bfu = math.clamp(tonumber(bfu) or 1, 1, #frames - 1)
    local reog = tonumber(frames[bfu] and (frames[bfu].times or frames[bfu].t)) or firstT

    if ftnt <= kkuq and reog >= gam then
        notify("Smart Resume", "Masih di FINISH, balik ke START", 1)
        return 1, firstT
    end

    if distanceTo > 50 then
        notify("Smart Resume", "Jauh dari path, mulai dari START", 1)
        return 1, firstT
    end

    if reog >= gam then
        notify("Smart Resume", "Dekat akhir, lanjut dari titik terdekat", 1)
        return bfu, reog
    end

    notify("Smart Resume", "Mulai dari titik terdekat", 1)
    return bfu, reog
end

function playFrames(frames, checkpointName)
    frames = preparePlaybackFrames(frames)

    if not frames or #frames <= 1 then
        notify("Playback", "Data checkpoint kosong/rusak", 3)
        return
    end

    captureMapSpeedBeforePlayback()

    fg = fg + 1
    local myToken = fg
    ku = true
    setPlaybackButtonState(true)

    local mi, manualMode, recordedBaseSpeed = getPlaybackSpeedForFrames(frames)
    local sjt = math.clamp((tonumber(mi) or recordedBaseSpeed) / math.max(tonumber(recordedBaseSpeed) or zudm, 1), 0.05, 25)

    local tbq = sjt
    local wx = sjt
    local modeText = manualMode and "MANUAL" or "AUTO MAP"

    if rmh and gf then
        tbq = 1
        wx = 1
        sjt = 1
        modeText = "RAW MAP"
    end

    task.spawn(function()
        notify(
            "Playback",
            "Play " .. tostring(checkpointName) .. " | " .. modeText .. " | speed " .. tostring(mi),
            3
        )

        local char, hum, hrp = getCharacter()
        if not hum or not hrp then
            ku = false
            setPlaybackButtonState(false)
            return
        end

        local cmev = hum.AutoRotate
        local ta = hum.WalkSpeed
        local vm = hum.JumpPower

        pcall(function()

            hum.AutoRotate = false
            hum.PlatformStand = false
            hum.Sit = false
            hum.Jump = false
            hum.WalkSpeed = math.clamp(mi, mpm, slw)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)

        local xlnp, startTime = getBitwiseSmartStartForOnium(frames)
        local uo = frames[xlnp] or frames[1]
        equipFrameTool(uo, char, hum)
        applyFrameInstant(uo)
        task.wait(0.02)

        local firstT = tonumber(frames[1].times) or tonumber(frames[1].t) or 0
        local lastT = tonumber(frames[#frames].times) or tonumber(frames[#frames].t) or firstT
        local gcuh = math.max(lastT - firstT, 0.001)
        local pdq = math.clamp((tonumber(startTime) or firstT) - firstT, 0, gcuh)
        local za = os.clock()

        while myToken == fg and ku and pdq < gcuh do
            char, hum, hrp = getCharacter()
            if not hum or not hrp then
                break
            end

            local now = os.clock()
            local realDt = now - za
            za = now

            if realDt <= 0 then
                realDt = 0.016
            elseif realDt > 0.2 then
                realDt = 0.1
            end

            pdq = pdq + (realDt * tbq)

            local ulgh = firstT + pdq
            local idx = findPreparedFrameAtTimeFast(frames, ulgh)
            local a = frames[idx]
            local b = frames[idx + 1]

            if not a or not b then
                break
            end

            local ta = tonumber(a.times) or tonumber(a.t) or 0
            local tb = tonumber(b.times) or tonumber(b.t) or ta
            local dt = tb - ta
            if dt <= 0.001 then
                dt = iy
            end

            local alpha = math.clamp((ulgh - ta) / dt, 0, 1)

            if b.seam == true or a.cutNext == true then
                equipFrameTool(b, char, hum)
                applyFrameInstant(b)
            else
                equipFrameTool(b, char, hum)
                applyFrameMeta(b, hum)
                applyFrameBitwiseStyle(a, b, alpha, hum, hrp, wx, mi)
            end

            RunService.Heartbeat:Wait()
        end

        if myToken == fg and ku then
            local ybe_ = frames[#frames]
            applyFrameInstant(ybe_)
        end

        local _, finalHum, finalHrp = getCharacter()
        if finalHrp then
            pcall(function()
                finalHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                finalHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end

        if finalHum then
            pcall(function()
                finalHum.AutoRotate = cmev
                finalHum.PlatformStand = false
                finalHum.Sit = false
                finalHum.Jump = false
                finalHum.WalkSpeed = math.max(tonumber(ta) or 0, mpm)
                finalHum.JumpPower = vm or finalHum.JumpPower
                finalHum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end

        restoreCharacterControl()

        ku = false
        setPlaybackButtonState(false)
        notify("Playback", "Selesai. Mode " .. modeText .. ", speed " .. tostring(mi), 2)
    end)
end

ky = function(cp)
    if not cp or not cp.frames then
        return
    end

    playFrames(cp.frames, cp.name)
end

function findRollbackTargetObjectIndex()
    if #xbk <= 2 then
        return nil, nil
    end

    local dk = nil

    for i = #xbk, 1, -1 do
        local key = groundKeyFromFrame(xbk[i])
        if key then
            dk = key
            break
        end
    end

    if not dk then
        return nil, nil
    end

    local _xi = false

    for i = #xbk, 1, -1 do
        local key = groundKeyFromFrame(xbk[i])

        if key then
            if key == dk then
                _xi = true
            elseif _xi then
                return i, key
            end
        end
    end

    for i = 1, #xbk do
        if groundKeyFromFrame(xbk[i]) == dk then
            return i, dk
        end
    end

    return nil, nil
end

ROLLBACK_GROUND_RAY_UP = 10
ROLLBACK_GROUND_RAY_DOWN = 45
ROLLBACK_MAX_GROUND_Y_DIFF = 8
ROLLBACK_STAND_EXTRA_Y = 0.12
ROLLBACK_MIN_HRP_GROUND_OFFSET = 2.2
ROLLBACK_MAX_HRP_GROUND_OFFSET = 12

function isRollbackPartValid(inst)
    if not inst then
        return false
    end

    if inst == workspace.Terrain then
        return true
    end

    local ok, canCollide = pcall(function()
        return inst.CanCollide
    end)

    if not ok then
        return false
    end

    if canCollide ~= true then
        return false
    end

    local char = LocalPlayer and LocalPlayer.Character
    if char and inst:IsDescendantOf(char) then
        return false
    end

    return true
end

ROLLBACK_CEILING_SKIP_MARGIN = 1.15
ROLLBACK_GROUND_SCAN_LIMIT = 12
ROLLBACK_HEAD_CHECK_UP = 5.5

function makeRollbackRaycastParams(extraIgnore)
    local char = LocalPlayer and LocalPlayer.Character
    local svq = {}

    if char then
        table.insert(svq, char)
    end

    if type(extraIgnore) == "table" then
        for _, inst in ipairs(extraIgnore) do
            if inst then
                table.insert(svq, inst)
            end
        end
    end

    local params = RaycastParams.new()

    pcall(function()
        params.FilterType = Enum.RaycastFilterType.Blacklist
    end)

    pcall(function()
        params.FilterDescendantsInstances = svq
    end)

    pcall(function()
        params.IgnoreWater = true
    end)

    return params
end

function raycastRollbackGround(pos)
    if typeof(pos) ~= "Vector3" then
        return nil
    end

    local qhix = {}
    local origin = pos + Vector3.new(0, ROLLBACK_GROUND_RAY_UP, 0)
    local cnd = Vector3.new(0, -(ROLLBACK_GROUND_RAY_UP + ROLLBACK_GROUND_RAY_DOWN), 0)

    for _ = 1, ROLLBACK_GROUND_SCAN_LIMIT do
        local params = makeRollbackRaycastParams(qhix)
        local ok, result = pcall(function()
            return workspace:Raycast(origin, cnd, params)
        end)

        if not ok or not result or not result.Instance then
            return nil
        end

        local inst = result.Instance
        local hitY = result.Position and result.Position.Y or -math.huge
        local fudo = hitY > (pos.Y - ROLLBACK_CEILING_SKIP_MARGIN)

        if fudo or not isRollbackPartValid(inst) then
            table.insert(qhix, inst)
        else
            return result
        end
    end

    return nil
end

function raycastRollbackCeiling(pos, hum)
    if typeof(pos) ~= "Vector3" then
        return nil
    end

    local params = makeRollbackRaycastParams()
    local hip = tonumber(hum and hum.HipHeight) or 2
    local origin = pos + Vector3.new(0, 1.0, 0)
    local cnd = Vector3.new(0, math.max(ROLLBACK_HEAD_CHECK_UP, hip + 3.2), 0)

    local ok, result = pcall(function()
        return workspace:Raycast(origin, cnd, params)
    end)

    if ok and result and result.Instance and isRollbackPartValid(result.Instance) then
        return result
    end

    return nil
end

function getRollbackHoldCFrame(targetCF, hum)

    if targetCF and raycastRollbackCeiling(targetCF.Position, hum) then
        return targetCF
    end

    return targetCF + Vector3.new(0, 0.85, 0)
end

function getRollbackRecordedGroundOffset(fr, hum)
    local pos = tableToVec(fr and fr.position)
    local offset = nil

    if type(fr) == "table" and type(fr.ground) == "table" and type(fr.ground.hitPosition) == "table" then
        local hit = tableToVec(fr.ground.hitPosition)
        offset = pos.Y - hit.Y
    end

    if not offset or offset ~= offset or offset < ROLLBACK_MIN_HRP_GROUND_OFFSET or offset > ROLLBACK_MAX_HRP_GROUND_OFFSET then
        offset = (tonumber(hum and hum.HipHeight) or tonumber(fr and fr.hipHeight) or 2) + 2
    end

    return math.clamp(offset, ROLLBACK_MIN_HRP_GROUND_OFFSET, ROLLBACK_MAX_HRP_GROUND_OFFSET)
end

function getSafeRollbackCFrame(fr, hum)
    if type(fr) ~= "table" then
        return nil, nil, "no_frame"
    end

    if isRollbackAirFrame(fr) then
        return nil, nil, "air_frame"
    end

    local rawCF = getFrameCFrame(fr)
    local rawPos = rawCF.Position
    local hit = raycastRollbackGround(rawPos)

    if not hit then
        return nil, nil, "no_ground_now"
    end

    local offset = getRollbackRecordedGroundOffset(fr, hum)
    local safePos = Vector3.new(
        rawPos.X,
        hit.Position.Y + offset + ROLLBACK_STAND_EXTRA_Y,
        rawPos.Z
    )

    if math.abs(safePos.Y - rawPos.Y) > ROLLBACK_MAX_GROUND_Y_DIFF then
        return nil, nil, "wrong_ground_y"
    end

    local _, yaw, _ = rawCF:ToOrientation()
    local safeCF = CFrame.new(safePos) * CFrame.Angles(0, yaw, 0)

    return safeCF, safePos, "ok"
end

function isSafeRollbackFrameIndex(index)
    local _, hum = getCharacter()
    local fr = xbk[index]
    local cf = nil

    if not fr then
        return false
    end

    cf = select(1, getSafeRollbackCFrame(fr, hum))
    return cf ~= nil
end

function findSafeRollbackIndex(xlnp)
    xlnp = math.clamp(tonumber(xlnp) or #xbk, 1, #xbk)

    for i = xlnp, 1, -1 do
        if isSafeRollbackFrameIndex(i) then
            return i
        end
    end

    return nil
end

function isRollbackStillGrounded(pos, fr, hum)
    local hit = raycastRollbackGround(pos)
    if not hit then
        return false
    end

    local offset = getRollbackRecordedGroundOffset(fr, hum)
    local az = pos.Y - hit.Position.Y

    return az >= (ROLLBACK_MIN_HRP_GROUND_OFFSET - 0.5)
        and az <= (offset + 3.5)
end

function applyRollbackSmoothToFrame(ujjg, gjl)
    local char, hum, hrp = getCharacter()
    if not hum or not hrp or type(ujjg) ~= "table" then
        return false
    end

    if not zd or not vft or cek or gjl ~= pa then
        return false
    end

    local targetCF, tq, safeReason = getSafeRollbackCFrame(ujjg, hum)
    if not targetCF or not tq then

        return false
    end

    local cmev = hum.AutoRotate
    local qyz = hum.PlatformStand

    pcall(function()
        hum.AutoRotate = false
        hum.PlatformStand = true
        hum:Move(Vector3.new(0, 0, 0), true)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)

    pcall(function()
        hrp.Anchored = true
    end)

    local holdCF = getRollbackHoldCFrame(targetCF, hum)

    for i = 1, 10 do
        if not zd or not vft or cek or gjl ~= pa then
            pcall(function() hrp.Anchored = false end)
            pcall(function()
                hum.PlatformStand = qyz
                hum.AutoRotate = cmev
            end)
            return false
        end

        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.CFrame = holdCF
        end)

        RunService.Heartbeat:Wait()
    end

    pcall(function()
        hrp.CFrame = targetCF
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    task.wait(0.08)

    pcall(function()
        hrp.Anchored = false
    end)

    pcall(function()
        hum.PlatformStand = qyz
        hum.AutoRotate = cmev
        hum.HipHeight = tonumber(ujjg.hipHeight) or hum.HipHeight
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum:Move(Vector3.new(0, 0, 0), true)
    end)

    for _ = 1, 3 do
        RunService.Heartbeat:Wait()
    end

    local ebt = false
    local okGround = false

    pcall(function()
        ebt = (hrp.Position - tq).Magnitude <= 7
        okGround = isRollbackStillGrounded(hrp.Position, ujjg, hum)
    end)

    if ebt and okGround then
        ye = hrp.Position
        return true
    end

    return false
end

on = function()
    if not zd then
        notify("Rollback", "Recording belum berjalan", 2)
        return
    end

    if vft then
        cek = true
        pa = pa + 1
        vft = false

        if qpw then
            qpw.Text = "ROLL"
            qpw.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
        end

        if fft then
            fft.Text = "● REC"
        end

        restoreCharacterControl()

        local _, _, hrp = getCharacter()
        if hrp then
            ye = hrp.Position
        end

        updateOverlay()
        notify("Rollback", "Rollback distop. Record lanjut dari posisi ini.", 2)
        return
    end

    if #xbk <= 2 then
        notify("Rollback", "Frame masih terlalu sedikit", 2)
        return
    end

    vft = true
    cek = false
    pa = pa + 1

    local gjl = pa

    if fft then
        fft.Text = "↶ ROLLBACK. klik lagi untuk STOP"
    end

    if qpw then
        qpw.Text = "STOP ROLL"
        qpw.BackgroundColor3 = Color3.fromRGB(190, 80, 55)
    end

    task.spawn(function()
        local char, hum, hrp = getCharacter()
        local cmev = nil

        if hum then
            cmev = hum.AutoRotate
            pcall(function()
                hum.AutoRotate = false
            end)
        end

        local kg, targetReason = findRollbackBeforeJumpIndex()
        local lrej = kg ~= nil and kg < #xbk

        local nhay = nil
        local jjb = false

        if not lrej then
            kg, nhay = findRollbackTargetObjectIndex()
            jjb = kg ~= nil and kg < #xbk
        end

        local removed = 0

        if lrej or jjb then

            local zrar = findSafeRollbackIndex(kg)
            if zrar then
                kg = zrar
            end

            local ujjg = zrar and xbk[kg] or nil

            local okMove = false
            if ujjg
                and zd
                and vft
                and not cek
                and gjl == pa
            then
                okMove = applyRollbackSmoothToFrame(ujjg, gjl)
            end

            if okMove then
                while #xbk > kg do
                    table.remove(xbk, #xbk)
                    removed = removed + 1
                end
            else
                notify("Rollback", "Gagal balik: map menarik avatar. Frame tidak dihapus.", 3)
            end

            updateOverlay()
        else

            local okry = math.min(ofya, math.max(0, #xbk - 1))
            local tryIndex = #xbk - 1

            while zd
                and vft
                and not cek
                and gjl == pa
                and tryIndex >= 1
                and removed < okry do

                local ujjg = xbk[tryIndex]
                if not ujjg then
                    break
                end

                local okMove = applyRollbackSmoothToFrame(ujjg, gjl)
                if okMove then
                    while #xbk > tryIndex do
                        table.remove(xbk, #xbk)
                        removed = removed + 1
                    end
                    updateOverlay()
                    break
                end

                tryIndex = tryIndex - 1
            end

            if removed <= 0 then
                notify("Rollback", "Tidak ada posisi rollback yang aman. Frame tidak dihapus.", 3)
            end
        end

        local _, finalHum, finalHrp = getCharacter()

        if finalHum and cmev ~= nil then
            pcall(function()
                finalHum.AutoRotate = cmev
            end)
        end

        if finalHrp then
            pcall(function()
                finalHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                finalHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)

            ye = finalHrp.Position
        end

        restoreCharacterControl()

        if gjl == pa then

            xbk = basicNormalizeFrames(xbk) or xbk
            vft = false
            cek = false

            if qpw then
                qpw.Text = "ROLL"
                qpw.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
            end

            if zd and fft then
                fft.Text = "● REC"
            end

            updateOverlay()

            if removed > 0 then
                if lrej then
                    notify("Rollback", "Balik ke posisi sebelum lompat | " .. tostring(removed) .. " frame dihapus", 3)
                elseif jjb then
                    notify("Rollback", "Balik ke object terakhir: " .. tostring(nhay or "object") .. " | " .. tostring(removed) .. " frame", 3)
                else
                    notify("Rollback", "Fallback mundur " .. tostring(removed) .. " frame", 3)
                end
            else
                notify("Rollback", "Rollback berhenti", 2)
            end
        else
            vft = false
            cek = false

            if qpw then
                qpw.Text = "ROLL"
                qpw.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
            end

            if zd and fft then
                fft.Text = "● REC"
            end

            xbk = basicNormalizeFrames(xbk) or xbk
            updateOverlay()
        end
    end)
end

local hjh = 0.14
local fnsv = 2.25
local yuz = 0.08
local x_zu = 0.035
local jj = 0.035
local cv = 0.055
local pw = 0.004

function getFrameState(fr)
    return tostring(fr and (fr.states or fr.state) or "Running")
end

function getFramePosVector(fr)
    return tableToVec(fr and fr.position)
end

function getFrameCityVector(fr)
    return tableToVec(fr and fr.city)
end

function getFrameMoveVector(fr)
    return tableToVec(fr and fr.moveDirection)
end

function getFrameHorizontalSpeed(fr)
    local c = getFrameCityVector(fr)
    return Vector3.new(c.X, 0, c.Z).Magnitude
end

function getFrameMoveMagnitude(fr)
    local m = getFrameMoveVector(fr)
    return Vector3.new(m.X, 0, m.Z).Magnitude
end

function getYawDiff(a, b)
    local ay = tonumber(a and a.rotation) or 0
    local by = tonumber(b and b.rotation) or ay
    local d = by - ay
    return math.abs(math.atan(math.sin(d), math.cos(d)))
end

function isMotionProtectedFrame(fr)
    if not fr then
        return false
    end

    local st = getFrameState(fr)

    if mobileDeltaFrameHasGroundContact(fr) and st ~= "Climbing" and st ~= "Swimming" then
        return false
    end

    if fr.jump == true then
        return true
    end

    return st == "Jumping"
        or st == "Freefall"
        or st == "FallingDown"
        or st == "Climbing"
        or st == "Swimming"
end

function frameDistance(a, b)
    if not a or not b then
        return 0, 0, 0
    end

    local pa = getFramePosVector(a)
    local pb = getFramePosVector(b)
    local diff = pb - pa
    local hd = Vector3.new(diff.X, 0, diff.Z).Magnitude
    local vd = math.abs(diff.Y)
    return diff.Magnitude, hd, vd
end

function isFrameIdleBetween(prev, fr, nextF, edgeMode)
    if not fr then
        return true
    end

    if isMotionProtectedFrame(fr) then
        return false
    end

    local hv = getFrameHorizontalSpeed(fr)
    local md = getFrameMoveMagnitude(fr)
    local rotA = prev and getYawDiff(prev, fr) or 0
    local rotB = nextF and getYawDiff(fr, nextF) or 0

    if rotA >= jj or rotB >= jj then
        return false
    end

    local dPrev = prev and select(1, frameDistance(prev, fr)) or 999
    local dNext = nextF and select(1, frameDistance(fr, nextF)) or 999
    local minDist = math.min(dPrev, dNext)

    if edgeMode then
        return minDist <= hjh
            and hv <= fnsv
            and md <= yuz
    end

    return minDist <= x_zu
        and hv <= fnsv
        and md <= yuz
end

function trimIdleStartEnd(frames)
    if not frames or #frames <= 2 then
        return frames or {}
    end

    local first = 1
    local last = #frames

    while first < last and isFrameIdleBetween(nil, frames[first], frames[first + 1], true) do
        first = first + 1
    end

    while last > first and isFrameIdleBetween(frames[last - 1], frames[last], nil, true) do
        last = last - 1
    end

    local out = {}
    for i = first, last do
        table.insert(out, deepCopy(frames[i]))
    end

    if #out <= 0 then
        return frames
    end

    return out
end

function estimateCleanDt(prev, fr)
    if not prev or not fr then
        return 0
    end

    local rawDt = (tonumber(fr.times) or tonumber(fr.t) or 0) - (tonumber(prev.times) or tonumber(prev.t) or 0)
    local _, hd, vd = frameDistance(prev, fr)
    local c1 = getFrameCityVector(prev)
    local c2 = getFrameCityVector(fr)
    local hSpeed = math.max(
        Vector3.new(c1.X, 0, c1.Z).Magnitude,
        Vector3.new(c2.X, 0, c2.Z).Magnitude
    )
    local ySpeed = math.max(math.abs(c1.Y), math.abs(c2.Y))

    local ytyd = nil
    if hSpeed > 1 and hd > 0.005 then
        ytyd = hd / hSpeed
    end

    if ySpeed > 1 and vd > 0.005 then
        local yDt = vd / ySpeed
        if ytyd then
            ytyd = math.max(ytyd, yDt)
        else
            ytyd = yDt
        end
    end

    local dt = rawDt

    if dt <= 0 or dt > cv then
        dt = ytyd or iy
    end

    if ytyd and dt > cv then
        dt = ytyd
    end

    return math.clamp(dt, pw, cv)
end

function compactCleanTimes(frames)
    local out = {}
    local pdq = 0
    local ewg = nil

    for i, fr in ipairs(frames or {}) do
        local copy = deepCopy(fr)
        if i == 1 then
            pdq = 0
        else
            pdq = pdq + estimateCleanDt(ewg or frames[i - 1], fr)
        end

        copy.times = roundNumber(pdq, 9)
        copy.t = copy.times
        table.insert(out, copy)
        ewg = fr
    end

    return out
end

ANTI_KEDUT_EDGE_RATIO = 0.62
ANTI_KEDUT_INTERNAL_RATIO = 0.38
ANTI_KEDUT_DUP_DIST = 0.22
ANTI_KEDUT_KEEP_DIST = 0.32
ANTI_KEDUT_MIN_RUN_SPEED = 8
ANTI_KEDUT_MIN_DT = 0.004
ANTI_KEDUT_MAX_DT = 0.038
ANTI_KEDUT_ROT_PROTECT = 0.20

function antiKedutIsAir(fr)
    if not fr then return false end
    local st = tostring(fr.states or fr.state or "")
    if mobileDeltaFrameHasGroundContact(fr) and st ~= "Climbing" and st ~= "Swimming" then
        return false
    end
    if fr.jump == true then return true end
    return st == "Jumping" or st == "Freefall" or st == "FallingDown" or st == "Climbing" or st == "Swimming"
end

function antiKedutPos(fr)
    return tableToVec(fr and fr.position)
end

function antiKedutCity(fr)
    return tableToVec(fr and fr.city)
end

function antiKedutMove(fr)
    return tableToVec(fr and fr.moveDirection)
end

function antiKedutHDist(a, b)
    if not a or not b then return 0 end
    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    return Vector3.new(pb.X - pa.X, 0, pb.Z - pa.Z).Magnitude
end

function antiKedutVDist(a, b)
    if not a or not b then return 0 end
    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    return math.abs(pb.Y - pa.Y)
end

function antiKedutDist(a, b)
    if not a or not b then return 0 end
    return (antiKedutPos(b) - antiKedutPos(a)).Magnitude
end

function antiKedutHSpeed(fr)
    local c = antiKedutCity(fr)
    return Vector3.new(c.X, 0, c.Z).Magnitude
end

function antiKedutMoveMag(fr)
    local m = antiKedutMove(fr)
    return Vector3.new(m.X, 0, m.Z).Magnitude
end

function antiKedutYawDiff(a, b)
    if not a or not b then return 0 end
    local ay = tonumber(a.rotation) or 0
    local by = tonumber(b.rotation) or ay
    local d = by - ay
    return math.abs(math.atan(math.sin(d), math.cos(d)))
end

function antiKedutBaseSpeed(frames)
    local speeds = {}
    for _, fr in ipairs(frames or {}) do
        if fr and not antiKedutIsAir(fr) then
            local h = antiKedutHSpeed(fr)
            if h > 3 then
                table.insert(speeds, h)
            end
        end
    end
    if #speeds <= 0 then
        for _, fr in ipairs(frames or {}) do
            local h = antiKedutHSpeed(fr)
            if h > 3 then table.insert(speeds, h) end
        end
    end
    if #speeds <= 0 then
        return tonumber(hjo) or tonumber(jckq) or _d or zudm
    end
    table.sort(speeds)
    local mid = math.floor((#speeds + 1) / 2)
    local base = tonumber(speeds[mid]) or _d or zudm
    return math.max(base, ANTI_KEDUT_MIN_RUN_SPEED)
end

function antiKedutTrimEdges(frames)
    frames = frames or {}
    if #frames <= 2 then return frames end
    local base = antiKedutBaseSpeed(frames)
    local first = 1
    local last = #frames
    while first < last do
        local fr = frames[first]
        local nxt = frames[first + 1]
        if antiKedutIsAir(fr) then break end
        local hv = antiKedutHSpeed(fr)
        local md = antiKedutMoveMag(fr)
        local d = antiKedutDist(fr, nxt)
        local slow = hv < math.max(ANTI_KEDUT_MIN_RUN_SPEED, base * ANTI_KEDUT_EDGE_RATIO)
        local tiny = d < ANTI_KEDUT_KEEP_DIST
        if slow or md < 0.08 or tiny then first = first + 1 else break end
    end
    while last > first do
        local fr = frames[last]
        local prv = frames[last - 1]
        if antiKedutIsAir(fr) then break end
        local hv = antiKedutHSpeed(fr)
        local md = antiKedutMoveMag(fr)
        local d = antiKedutDist(prv, fr)
        local slow = hv < math.max(ANTI_KEDUT_MIN_RUN_SPEED, base * ANTI_KEDUT_EDGE_RATIO)
        local tiny = d < ANTI_KEDUT_KEEP_DIST
        if slow or md < 0.08 or tiny then last = last - 1 else break end
    end
    local out = {}
    for i = first, last do table.insert(out, deepCopy(frames[i])) end
    if #out <= 0 then return frames end
    return out
end

function antiKedutDirectionBetween(a, b)
    if not a or not b then return Vector3.new(0, 0, 0) end
    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    local flat = Vector3.new(pb.X - pa.X, 0, pb.Z - pa.Z)
    if flat.Magnitude <= 0.001 then return Vector3.new(0, 0, 0) end
    return flat.Unit
end

function antiKedutStabilizeRun(prev, fr, nextF, f_)
    if rmh then

        return fr
    end
    if not fr or antiKedutIsAir(fr) then return fr end
    local dir = nil
    if prev then dir = antiKedutDirectionBetween(prev, fr) end
    if (not dir or dir.Magnitude <= 0.01) and nextF then dir = antiKedutDirectionBetween(fr, nextF) end
    if dir and dir.Magnitude > 0.01 then
        local hv = antiKedutHSpeed(fr)
        local ws = tonumber(fr.jqa) or 0
        local speed = math.max(hv, ws, tonumber(f_) or 0, ANTI_KEDUT_MIN_RUN_SPEED)
        speed = math.clamp(speed, ANTI_KEDUT_MIN_RUN_SPEED, slw or 500000)
        fr.moveDirection = vecToTable(dir)
        fr.city = vecToTable(dir * speed)
        fr.states = "Running"
        fr.jump = false
    end
    return fr
end

function antiKedutCleanInternal(frames)
    frames = frames or {}
    if #frames <= 2 then return frames, 0 end
    local base = antiKedutBaseSpeed(frames)
    local out = {}
    local removed = 0
    for i = 1, #frames do
        local fr = deepCopy(frames[i])
        local prevRaw = frames[i - 1]
        local nextRaw = frames[i + 1]
        local last = out[#out]
        local keep = true
        if #out <= 0 or i == #frames then
            keep = true
        elseif antiKedutIsAir(fr) then
            keep = true
        else
            local dLast = antiKedutDist(last, fr)
            local hdLast = antiKedutHDist(last, fr)
            local vdLast = antiKedutVDist(last, fr)
            local hv = antiKedutHSpeed(fr)
            local md = antiKedutMoveMag(fr)
            local rot = math.max(antiKedutYawDiff(prevRaw, fr), antiKedutYawDiff(fr, nextRaw))
            local twc = hv < math.max(ANTI_KEDUT_MIN_RUN_SPEED, base * ANTI_KEDUT_INTERNAL_RATIO)
            if dLast < ANTI_KEDUT_DUP_DIST and vdLast < 0.08 then
                keep = false
            elseif twc and hdLast < ANTI_KEDUT_KEEP_DIST and md < 0.18 then
                keep = false
            elseif rot > ANTI_KEDUT_ROT_PROTECT and hdLast < ANTI_KEDUT_DUP_DIST and hv < base * 0.55 then
                keep = false
            else
                keep = true
            end
        end
        if keep then
            fr = antiKedutStabilizeRun(out[#out], fr, nextRaw, base)
            table.insert(out, fr)
        else
            removed = removed + 1
        end
    end
    if #out <= 0 then return frames, removed end
    return out, removed
end

function antiKedutCompactTimes(frames)
    frames = frames or {}
    if #frames <= 0 then return frames end
    local base = antiKedutBaseSpeed(frames)
    local out = {}
    local t = 0
    for i = 1, #frames do
        local fr = deepCopy(frames[i])
        if i == 1 then
            t = 0
        else
            local prev = out[#out]
            local d = antiKedutDist(prev, fr)
            local hd = antiKedutHDist(prev, fr)
            local vd = antiKedutVDist(prev, fr)
            local hv = math.max(antiKedutHSpeed(prev), antiKedutHSpeed(fr), base)
            local yv = math.max(math.abs(antiKedutCity(prev).Y), math.abs(antiKedutCity(fr).Y), 1)
            local dt = 0
            if antiKedutIsAir(prev) or antiKedutIsAir(fr) then
                local hdt = 0
                local vdt = 0
                if hd > 0.005 then hdt = hd / math.max(hv, 1) end
                if vd > 0.005 then vdt = vd / math.max(yv, 1) end
                dt = math.max(hdt, vdt, ANTI_KEDUT_MIN_DT)
                dt = math.clamp(dt, ANTI_KEDUT_MIN_DT, 0.055)
            else
                if d > 0.005 then dt = d / math.max(hv, 1) else dt = ANTI_KEDUT_MIN_DT end
                dt = math.clamp(dt, ANTI_KEDUT_MIN_DT, ANTI_KEDUT_MAX_DT)
            end
            t = t + dt
        end
        fr.times = roundNumber(t, 9)
        fr.t = fr.times
        table.insert(out, fr)
    end
    return out
end

NO_IDLE_TURN_SMOOTH = true
NO_IDLE_TURN_MIN_GAP = 0.10
NO_IDLE_TURN_MIN_YAW = math.rad(18)
NO_IDLE_TURN_MIN_FRAMES = 5
NO_IDLE_TURN_MAX_FRAMES = 18
NO_IDLE_TURN_MAX_DIST = 18

function antiKedutSmoothIdleRotation(frames)
    if not NO_IDLE_TURN_SMOOTH then
        return frames
    end

    if type(frames) ~= "table" or #frames <= 2 then
        return frames
    end

    local out = deepCopy(frames)

    for i = 1, #out - 1 do
        local a = out[i]
        local b = out[i + 1]

        if a and b and not antiKedutIsAir(a) and not antiKedutIsAir(b) then
            local ta = tonumber(a.times) or tonumber(a.t) or 0
            local tb = tonumber(b.times) or tonumber(b.t) or ta
            local gap = tb - ta

            local yawA = tonumber(a.rotation) or 0
            local yawB = tonumber(b.rotation) or yawA
            local delta = yawB - yawA
            delta = math.atan(math.sin(delta), math.cos(delta))

            local dist = antiKedutDist(a, b)

            if gap >= NO_IDLE_TURN_MIN_GAP
                and math.abs(delta) >= NO_IDLE_TURN_MIN_YAW
                and dist <= NO_IDLE_TURN_MAX_DIST
            then
                local count = math.floor(math.abs(delta) / math.rad(7))
                count = math.clamp(count, NO_IDLE_TURN_MIN_FRAMES, NO_IDLE_TURN_MAX_FRAMES)

                local endIndex = math.min(#out, i + count)

                if endIndex > i + 1 then
                    for j = i + 1, endIndex do
                        local alpha = (j - i) / math.max(endIndex - i, 1)
                        local eased = smoothStep(alpha)

                        out[j].rotation = roundNumber(yawA + (delta * eased), 9)

                    end
                end
            end
        end
    end

    return out
end

ANTI_KEDUT_REFERENCE_JUMP_ENABLED = true

REF_JUMP_TARGET_GROUND_FRAMES = 7
REF_JUMP_MAX_SCAN_GROUND_FRAMES = 18
REF_JUMP_GAP_MAX_TIME = 0.20
REF_JUMP_GAP_MAX_DISTANCE = 13

REF_JUMP_MIN_DT = 0.004
REF_JUMP_AIR_MAX_DT = 0.0195
REF_JUMP_GROUND_MAX_DT = 0.0145
REF_JUMP_NORMAL_MAX_DT = 0.034

REF_JUMP_MIN_AIR_HSPEED_RATIO = 0.86
REF_JUMP_MAX_AIR_HSPEED_RATIO = 1.24
REF_JUMP_MIN_GROUND_HSPEED_RATIO = 0.82
REF_JUMP_MIN_JUMP_Y_SPEED = 18

REF_JUMP_SMOOTH_PASSES = 3
REF_JUMP_SMOOTH_NEIGHBOR_MAX_DIST = 6.5
REF_JUMP_ROT_SMOOTH_LIMIT = math.rad(70)

REF_JUMP_ULTRA_SMOOTH_ENABLED = true
REF_JUMP_ULTRA_SMOOTH_PASSES = 1
REF_JUMP_ULTRA_POS_ALPHA = 0.16
REF_JUMP_ULTRA_Y_ALPHA_AIR = 0.06
REF_JUMP_ULTRA_ROT_ALPHA = 0.00
REF_JUMP_ULTRA_MAX_STEP_DIST = 7.5

REF_JUMP_KEEP_MAP_AIR_CONTROL = true
REF_JUMP_KEEP_ORIGINAL_ROTATION = true
REF_JUMP_KEEP_ORIGINAL_CITY_DIR = true
REF_JUMP_MIN_MOTION_SPEED_KEEP = 8

RUN_ANTI_BLING_ENABLED = true
RUN_ANTI_BLING_MAX_STEP = 2.65
RUN_ANTI_BLING_MAX_BRIDGE_DISTANCE = 18
RUN_ANTI_BLING_INSERT_MAX = 10
RUN_ANTI_BLING_MIN_DT = 0.0085
RUN_ANTI_BLING_MAX_DT = 0.050
RUN_ANTI_BLING_SPEED_CAP_MULT = 1.16
RUN_ANTI_BLING_KEEP_ROTATION = true

RUN_PLAYBACK_VISUAL_GUARD = true
RUN_PLAYBACK_BIG_GAP_DISTANCE = 6.2
RUN_PLAYBACK_MAX_VISUAL_STEP = 4.25

function refJumpIsAir(fr)
    if type(fr) ~= "table" then return false end
    local st = tostring(fr.states or fr.state or "")
    if mobileDeltaFrameHasGroundContact(fr) then
        return false
    end
    if fr.jump == true then return true end
    return st == "Jumping" or st == "Freefall" or st == "FallingDown"
end

function refJumpIsHardProtected(fr)
    if type(fr) ~= "table" then return false end
    if fr.seam == true or fr.cutNext == true then return true end
    local st = tostring(fr.states or fr.state or "")
    return st == "Climbing" or st == "Swimming"
end

function refJumpTime(fr)
    return tonumber(fr and (fr.times or fr.t)) or 0
end

function refJumpFlatDirFromPos(a, b)
    if not a or not b then return nil end
    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    local flat = Vector3.new(pb.X - pa.X, 0, pb.Z - pa.Z)
    if flat.Magnitude <= 0.001 then return nil end
    return flat.Unit
end

function refJumpDirAround(frames, i)
    local dir = nil
    if frames[i - 1] and frames[i + 1] then
        dir = refJumpFlatDirFromPos(frames[i - 1], frames[i + 1])
    end
    if not dir and frames[i - 1] then
        dir = refJumpFlatDirFromPos(frames[i - 1], frames[i])
    end
    if not dir and frames[i + 1] then
        dir = refJumpFlatDirFromPos(frames[i], frames[i + 1])
    end
    return dir
end

function refJumpIsShortGroundGap(frames, xlnp, endIndex, nextAirIndex)
    if not frames or not frames[xlnp] or not frames[endIndex] or not frames[nextAirIndex] then
        return false
    end

    local prevAir = frames[xlnp - 1]
    local nextAir = frames[nextAirIndex]
    if not prevAir or not refJumpIsAir(prevAir) or not refJumpIsAir(nextAir) then
        return false
    end

    local count = endIndex - xlnp + 1
    if count <= REF_JUMP_TARGET_GROUND_FRAMES then
        return false
    end
    if count > REF_JUMP_MAX_SCAN_GROUND_FRAMES then
        return false
    end

    for k = xlnp, endIndex do
        if refJumpIsHardProtected(frames[k]) then
            return false
        end
    end

    local gapTime = math.max(0, refJumpTime(nextAir) - refJumpTime(prevAir))
    local gapDist = antiKedutDist(prevAir, nextAir)

    return gapTime <= REF_JUMP_GAP_MAX_TIME and gapDist <= REF_JUMP_GAP_MAX_DISTANCE
end

function refJumpSampleGroundBlock(frames, xlnp, endIndex)
    local count = endIndex - xlnp + 1
    local wrfa = math.min(count, REF_JUMP_TARGET_GROUND_FRAMES)
    local selected = {}
    local mzo = {}

    local function addIndex(idx)
        idx = math.clamp(math.floor(idx + 0.5), xlnp, endIndex)
        if not mzo[idx] then
            mzo[idx] = true
            table.insert(selected, idx)
        end
    end

    if wrfa <= 1 then
        addIndex(endIndex)
    else
        for n = 1, wrfa do
            local alpha = (n - 1) / math.max(wrfa - 1, 1)
            addIndex(xlnp + ((count - 1) * alpha))
        end
    end

    local bestRot = 0
    local obu = nil
    for i = xlnp + 1, endIndex - 1 do
        local rot = math.max(antiKedutYawDiff(frames[i - 1], frames[i]), antiKedutYawDiff(frames[i], frames[i + 1]))
        if rot > bestRot then
            bestRot = rot
            obu = i
        end
    end
    if obu and bestRot > math.rad(9) and #selected < REF_JUMP_TARGET_GROUND_FRAMES + 1 then
        addIndex(obu)
    end

    table.sort(selected)

    local out = {}
    for _, idx in ipairs(selected) do
        table.insert(out, deepCopy(frames[idx]))
    end
    return out
end

function refJumpCompressGroundGaps(frames)
    frames = frames or {}
    if #frames <= 3 then return frames, 0 end

    local out = {}
    local removed = 0
    local i = 1

    while i <= #frames do
        local fr = frames[i]

        if i > 1 and fr and not refJumpIsAir(fr) and refJumpIsAir(frames[i - 1]) then
            local xlnp = i
            local j = i
            while j <= #frames and frames[j] and not refJumpIsAir(frames[j]) do
                j = j + 1
            end

            if j <= #frames and refJumpIsShortGroundGap(frames, xlnp, j - 1, j) then
                local kept = refJumpSampleGroundBlock(frames, xlnp, j - 1)
                for _, item in ipairs(kept) do
                    table.insert(out, item)
                end
                removed = removed + ((j - xlnp) - #kept)
                i = j
            else
                table.insert(out, deepCopy(fr))
                i = i + 1
            end
        else
            table.insert(out, deepCopy(fr))
            i = i + 1
        end
    end

    if #out <= 0 then return frames, removed end
    return out, removed
end

function refJumpMarkChain(frames)
    frames = frames or {}
    local mark = {}
    for i, fr in ipairs(frames) do
        if refJumpIsAir(fr) then
            mark[i] = true
        end
    end

    local i = 1
    while i <= #frames do
        if frames[i] and not refJumpIsAir(frames[i]) and i > 1 and refJumpIsAir(frames[i - 1]) then
            local xlnp = i
            local j = i
            while j <= #frames and frames[j] and not refJumpIsAir(frames[j]) do
                j = j + 1
            end

            if j <= #frames then
                local prevAir = frames[xlnp - 1]
                local nextAir = frames[j]
                local gapTime = math.max(0, refJumpTime(nextAir) - refJumpTime(prevAir))
                local gapDist = antiKedutDist(prevAir, nextAir)
                if gapTime <= REF_JUMP_GAP_MAX_TIME and gapDist <= REF_JUMP_GAP_MAX_DISTANCE then
                    for k = xlnp, j - 1 do
                        mark[k] = true
                    end
                end
            end
            i = j
        else
            i = i + 1
        end
    end

    return mark
end

function refJumpSmoothPositions(frames)
    frames = frames or {}
    if #frames <= 3 then return frames end

    local out = deepCopy(frames)

    for _ = 1, REF_JUMP_SMOOTH_PASSES do
        local src = deepCopy(out)
        local mark = refJumpMarkChain(src)

        for i = 2, #src - 1 do
            local fr = src[i]
            local prev = src[i - 1]
            local nextF = src[i + 1]

            if mark[i] and not refJumpIsHardProtected(fr) and prev and nextF then
                local d1 = antiKedutDist(prev, fr)
                local d2 = antiKedutDist(fr, nextF)

                if d1 <= REF_JUMP_SMOOTH_NEIGHBOR_MAX_DIST and d2 <= REF_JUMP_SMOOTH_NEIGHBOR_MAX_DIST then
                    local pp = antiKedutPos(prev)
                    local cp = antiKedutPos(fr)
                    local np = antiKedutPos(nextF)
                    local sm = (pp * 0.18) + (cp * 0.64) + (np * 0.18)

                    if refJumpIsAir(fr) then

                        local y = cp.Y + ((sm.Y - cp.Y) * 0.18)
                        out[i].position = vecToTable(Vector3.new(sm.X, y, sm.Z))
                    else

                        out[i].position = vecToTable(Vector3.new(sm.X, cp.Y, sm.Z))
                    end

                end
            end
        end
    end

    return out
end

function refJumpUltraSmoothChains(frames)
    frames = frames or {}
    if not REF_JUMP_ULTRA_SMOOTH_ENABLED or #frames <= 4 then
        return frames
    end

    local out = deepCopy(frames)

    for _ = 1, REF_JUMP_ULTRA_SMOOTH_PASSES do
        local src = deepCopy(out)
        local mark = refJumpMarkChain(src)

        for i = 2, #src - 1 do
            local fr = src[i]
            local prev = src[i - 1]
            local nextF = src[i + 1]

            if mark[i] and fr and prev and nextF and not refJumpIsHardProtected(fr) then
                local d1 = antiKedutDist(prev, fr)
                local d2 = antiKedutDist(fr, nextF)

                if d1 <= REF_JUMP_ULTRA_MAX_STEP_DIST and d2 <= REF_JUMP_ULTRA_MAX_STEP_DIST then
                    local pp = antiKedutPos(prev)
                    local cp = antiKedutPos(fr)
                    local np = antiKedutPos(nextF)
                    local mid = (pp + np) * 0.5

                    local nx = cp.X + ((mid.X - cp.X) * REF_JUMP_ULTRA_POS_ALPHA)
                    local nz = cp.Z + ((mid.Z - cp.Z) * REF_JUMP_ULTRA_POS_ALPHA)
                    local ny = cp.Y

                    if refJumpIsAir(fr) then
                        ny = cp.Y + ((mid.Y - cp.Y) * REF_JUMP_ULTRA_Y_ALPHA_AIR)
                    end

                    out[i].position = vecToTable(Vector3.new(nx, ny, nz))

                end
            end
        end
    end

    return out
end

function refJumpRebuildMoveDirectionFromPath(frames)

    return frames or {}
end

function refJumpMotionDirFromOriginal(fr, fallbackDir)
    if type(fr) ~= "table" then
        return fallbackDir, 0
    end

    local city = antiKedutCity(fr)
    local cflat = Vector3.new(city.X, 0, city.Z)
    if cflat.Magnitude >= REF_JUMP_MIN_MOTION_SPEED_KEEP then
        return cflat.Unit, cflat.Magnitude
    end

    local md = tableToVec(fr.moveDirection)
    local mflat = Vector3.new(md.X, 0, md.Z)
    if mflat.Magnitude >= 0.03 then
        return mflat.Unit, 0
    end

    return fallbackDir, 0
end

function refJumpStabilizeMomentum(frames)
    frames = frames or {}
    if #frames <= 1 then return frames end

    local cebj = rp and framesLookMobileDeltaSafe(frames)
    local base = antiKedutBaseSpeed(frames)
    local mark = refJumpMarkChain(frames)
    local out = deepCopy(frames)

    for i, fr in ipairs(out) do
        if mark[i] and not refJumpIsHardProtected(fr) then
            local pathDir = refJumpDirAround(out, i)
            local dir, originalH = refJumpMotionDirFromOriginal(fr, pathDir)

            if dir and dir.Magnitude > 0.01 then
                local city = antiKedutCity(fr)
                local hv = Vector3.new(city.X, 0, city.Z).Magnitude
                local h = math.max(originalH or 0, hv)

                local minRatio = refJumpIsAir(fr) and REF_JUMP_MIN_AIR_HSPEED_RATIO or REF_JUMP_MIN_GROUND_HSPEED_RATIO
                local minH = math.max(base * minRatio, ANTI_KEDUT_MIN_RUN_SPEED)
                local maxH = math.max(base * REF_JUMP_MAX_AIR_HSPEED_RATIO, minH)

                if cebj then

                    if h <= 0.05 then
                        h = math.max(base * 0.72, ANTI_KEDUT_MIN_RUN_SPEED)
                    elseif h > maxH then
                        h = math.min(h, maxH)
                    end
                else
                    if h < minH then
                        h = minH
                    elseif h > maxH then

                        h = math.min(h, maxH)
                    end
                end

                local y = city.Y
                if refJumpIsAir(fr) then
                    local st = tostring(fr.states or fr.state or "")
                    if st == "Jumping" or fr.jump == true then

                        if (not cebj) and y > 0 and y < REF_JUMP_MIN_JUMP_Y_SPEED then
                            y = REF_JUMP_MIN_JUMP_Y_SPEED
                        end
                        fr.jump = true
                        fr.states = "Jumping"
                    elseif st == "FallingDown" then
                        fr.states = "Freefall"
                    end
                else

                    y = 0
                    fr.jump = false
                    fr.states = "Running"
                end

                local md = tableToVec(fr.moveDirection)
                local mflat = Vector3.new(md.X, 0, md.Z)
                if mflat.Magnitude >= 0.03 then
                    fr.moveDirection = vecToTable(mflat.Unit)
                else
                    fr.moveDirection = vecToTable(dir)
                end

                fr.city = vecToTable(Vector3.new(dir.X * h, y, dir.Z * h))
            end
        end
    end

    return out
end

function refJumpCompactTimes(frames)
    frames = frames or {}
    if #frames <= 0 then return frames end

    local cebj = rp and framesLookMobileDeltaSafe(frames)
    local base = antiKedutBaseSpeed(frames)
    local mark = refJumpMarkChain(frames)
    local out = {}
    local t = 0

    for i = 1, #frames do
        local fr = deepCopy(frames[i])

        if i == 1 then
            t = 0
        else
            local prev = out[#out]
            local yv = frames[i - 1]
            local hd = antiKedutHDist(prev, fr)
            local vd = antiKedutVDist(prev, fr)
            local d = antiKedutDist(prev, fr)
            local hv = math.max(antiKedutHSpeed(prev), antiKedutHSpeed(fr), base)
            local yv = math.max(math.abs(antiKedutCity(prev).Y), math.abs(antiKedutCity(fr).Y), REF_JUMP_MIN_JUMP_Y_SPEED)
            local rawDt = (tonumber(frames[i].times) or tonumber(frames[i].t) or 0) - (tonumber(yv and (yv.times or yv.t)) or 0)
            local dt

            if mark[i] or mark[i - 1] or refJumpIsAir(prev) or refJumpIsAir(fr) then
                local hdt = (hd > 0.005) and (hd / math.max(hv, 1)) or REF_JUMP_MIN_DT
                local vdt = (vd > 0.005) and (vd / math.max(yv, 1)) or REF_JUMP_MIN_DT
                dt = math.max(hdt, vdt, REF_JUMP_MIN_DT)

                if cebj then

                    local rawSafe = rawDt > 0 and (rawDt * (zv or 0.85)) or dt
                    dt = math.max(dt, rawSafe)

                    if refJumpIsAir(prev) or refJumpIsAir(fr) then
                        dt = math.clamp(dt, vgol or 0.010, f_jr or 0.045)
                    else
                        dt = math.clamp(dt, klt or 0.0085, mdld or 0.030)
                    end
                else
                    if refJumpIsAir(prev) or refJumpIsAir(fr) then
                        dt = math.clamp(dt, REF_JUMP_MIN_DT, REF_JUMP_AIR_MAX_DT)
                    else
                        dt = math.clamp(dt, REF_JUMP_MIN_DT, REF_JUMP_GROUND_MAX_DT)
                    end
                end
            else
                dt = (d > 0.005) and (d / math.max(hv, 1)) or ANTI_KEDUT_MIN_DT
                if cebj and rawDt > 0 then
                    dt = math.max(dt, rawDt * (zv or 0.85))
                    dt = math.clamp(dt, ANTI_KEDUT_MIN_DT, azq or 0.055)
                else
                    dt = math.clamp(dt, ANTI_KEDUT_MIN_DT, REF_JUMP_NORMAL_MAX_DT)
                end
            end

            t = t + dt
        end

        fr.times = roundNumber(t, 9)
        fr.t = fr.times
        table.insert(out, fr)
    end

    return out
end

function runAntiBlingIsRunning(fr)
    if type(fr) ~= "table" then return false end
    if refJumpIsAir(fr) or refJumpIsHardProtected(fr) then return false end
    if fr.jump == true then return false end

    local st = tostring(fr.states or fr.state or "")
    if st == "" or st == "Running" or st == "Landed" or st == "Walking" or st == "Standing" then
        return true
    end

    return false
end

function runAntiBlingFlatDir(a, b)
    if not a or not b then return nil end
    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    local flat = Vector3.new(pb.X - pa.X, 0, pb.Z - pa.Z)
    if flat.Magnitude <= 0.001 then return nil end
    return flat.Unit
end

function runAntiBlingBaseSpeedFromPair(a, b, fallback)
    local speed = math.max(
        antiKedutHSpeed(a),
        antiKedutHSpeed(b),
        tonumber(a and a.jqa) or 0,
        tonumber(b and b.jqa) or 0,
        tonumber(fallback) or 0,
        ANTI_KEDUT_MIN_RUN_SPEED or 8
    )
    return math.clamp(speed, ANTI_KEDUT_MIN_RUN_SPEED or 8, slw or 500000)
end

function runAntiBlingInterpolateFrame(a, b, alpha, f_)
    local copy = deepCopy((alpha < 0.5 and a) or b)
    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    local pos = pa:Lerp(pb, alpha)

    local yawA = tonumber(a and a.rotation) or 0
    local yawB = tonumber(b and b.rotation) or yawA
    local yaw = lerpAngle(yawA, yawB, alpha)

    local dir = runAntiBlingFlatDir(a, b)
    local speed = runAntiBlingBaseSpeedFromPair(a, b, f_)

    copy.position = vecToTable(pos)
    copy.rotation = roundNumber(yaw, 9)

    if dir then
        copy.moveDirection = vecToTable(dir)
        copy.city = vecToTable(Vector3.new(dir.X * speed, 0, dir.Z * speed))
    else
        copy.city = vecToTable(Vector3.new(0, 0, 0))
    end

    copy.jump = false
    copy.states = "Running"
    copy.seam = false
    copy.cutNext = false
    copy.ground = nil
    return copy
end

function runAntiBlingInsertBridges(frames)
    frames = frames or {}
    if not RUN_ANTI_BLING_ENABLED or #frames <= 1 then
        return frames, 0
    end

    local base = antiKedutBaseSpeed(frames)
    local out = {}
    local added = 0

    for i = 1, #frames do
        local a = frames[i]
        table.insert(out, deepCopy(a))

        local b = frames[i + 1]
        if a and b
            and runAntiBlingIsRunning(a)
            and runAntiBlingIsRunning(b)
            and a.cutNext ~= true
            and b.seam ~= true
        then
            local hd = antiKedutHDist(a, b)
            local vd = antiKedutVDist(a, b)

            if hd > RUN_ANTI_BLING_MAX_STEP
                and hd <= RUN_ANTI_BLING_MAX_BRIDGE_DISTANCE
                and vd <= 1.25
            then
                local parts = math.ceil(hd / RUN_ANTI_BLING_MAX_STEP)
                parts = math.clamp(parts, 2, RUN_ANTI_BLING_INSERT_MAX + 1)

                for n = 1, parts - 1 do
                    local alpha = n / parts
                    table.insert(out, runAntiBlingInterpolateFrame(a, b, alpha, base))
                    added = added + 1
                end
            end
        end
    end

    return out, added
end

function runAntiBlingRetuneTimes(frames)
    frames = frames or {}
    if not RUN_ANTI_BLING_ENABLED or #frames <= 0 then
        return frames
    end

    local base = antiKedutBaseSpeed(frames)
    local out = {}
    local t = 0

    for i = 1, #frames do
        local fr = deepCopy(frames[i])
        if i == 1 then
            t = 0
        else
            local prevSrc = frames[i - 1]
            local prevOut = out[#out]
            local oldDt = (tonumber(fr.times) or tonumber(fr.t) or 0) - (tonumber(prevSrc.times) or tonumber(prevSrc.t) or 0)
            if oldDt <= 0 then oldDt = iy or 0.004 end

            local dt = oldDt

            if runAntiBlingIsRunning(prevOut) and runAntiBlingIsRunning(fr) then
                local hd = antiKedutHDist(prevOut, fr)
                local jon = runAntiBlingBaseSpeedFromPair(prevOut, fr, base) * (RUN_ANTI_BLING_SPEED_CAP_MULT or 1.16)
                local needDt = (hd > 0.005) and (hd / math.max(jon, 1)) or (RUN_ANTI_BLING_MIN_DT or 0.0085)

                dt = math.max(oldDt, needDt, RUN_ANTI_BLING_MIN_DT or 0.0085)
                dt = math.clamp(dt, RUN_ANTI_BLING_MIN_DT or 0.0085, RUN_ANTI_BLING_MAX_DT or 0.05)
            else

                dt = oldDt
            end

            t = t + dt
        end

        fr.times = roundNumber(t, 9)
        fr.t = fr.times
        table.insert(out, fr)
    end

    return out
end

function refJumpOptimizer(frames, compactTime)
    if not ANTI_KEDUT_REFERENCE_JUMP_ENABLED then
        if compactTime ~= false then
            return antiKedutCompactTimes(frames), 0
        end
        return frames, 0
    end

    frames = basicNormalizeFrames(frames) or frames
    if type(frames) ~= "table" or #frames <= 2 then return frames, 0 end

    local ilhu = 0
    frames, ilhu = refJumpCompressGroundGaps(frames)
    frames = refJumpSmoothPositions(frames)
    frames = refJumpUltraSmoothChains(frames)
    frames = refJumpStabilizeMomentum(frames)

    if compactTime ~= false then
        frames = refJumpCompactTimes(frames)
    end

    frames = refJumpRebuildMoveDirectionFromPath(frames)

    return frames, ilhu
end

function cleanFramesForSaveMerge(inputFrames, compactTime)
    local frames = basicNormalizeFrames(inputFrames) or inputFrames
    if type(frames) ~= "table" or #frames <= 0 then return {}, 0 end

    if rmh and trxt then
        return prepareRawExactFramesForSave(frames)
    end

    local before = #frames
    local removedA = 0
    local removedB = 0
    local thv_ = 0

    frames = mobileDeltaFixAirStateByVelocity(frames)

    frames = antiKedutTrimEdges(frames)
    frames, removedA = antiKedutCleanInternal(frames)

    frames = antiKedutTrimEdges(frames)
    frames, removedB = antiKedutCleanInternal(frames)

    frames = antiKedutSmoothIdleRotation(frames)

    frames, thv_ = refJumpOptimizer(frames, compactTime)

    local oa = 0
    frames, oa = runAntiBlingInsertBridges(frames)
    if compactTime ~= false then
        frames = runAntiBlingRetuneTimes(frames)
    end

    local _ey = 0
    local buyx = nil
    frames, _ey, buyx = autoMapCleanSpeedForSave(frames)

    local removed = math.max(0, before - #frames)
        + (tonumber(removedA) or 0)
        + (tonumber(removedB) or 0)
        + (tonumber(thv_) or 0)

    return frames, removed
end

mq = function()

    if not bzg_ or #bzg_ <= 0 then
        notify("Save", "Belum ada record. Tekan RECORD lalu STOP dulu.", 3)
        return
    end

    local name = cleanFileName(dxay and dxay.Text or "")

    if name == "" or name == "checkpoint" then
        name = getNextDefaultName()
    end

    local frames, removed = cleanFramesForSaveMerge(bzg_, true)

    if not frames or #frames <= 0 then
        notify("Save", "Frame kosong setelah clean", 3)
        return
    end

    local ok, msg, path = saveFramesToFile(name, frames)

    local added = upsertCheckpoint(name, frames, false, path)

    if wb then
        task.defer(refreshCheckpointMarkers)
    end

    bzg_ = {}

    if dxay then
        dxay.Text = ""
    end

    if chnu then
        chnu.Text = ""
    end

    if yc then
        yc()
        task.defer(function()
            yc()
        end)
    end

    if ok then
        notify("Save", name .. ".json tersimpan | DELTA NO FALSE JUMP | AUTO MAP SPEED | hapus " .. tostring(removed or 0), 3)
    else
        notify("Save", name .. " masuk memory. " .. tostring(msg), 4)
    end

    if not added then
        notify("Save", "Warning: gagal masuk list checkpoint", 3)
    end
end

function loadOneFile(path)
    local content = readTextFile(path)
    if not content then
        return false
    end

    local decoded = decodeJSON(content)
    local frames = basicNormalizeFrames(decoded)

    if not frames then
        return false
    end

    local fileName = tostring(path):match("([^/\\]+)$") or tostring(path)
    local name = fileName:gsub("%.json$", "")
    local isMerged = name == "merged_record" or name:lower():find("merged", 1, true) ~= nil

    upsertCheckpoint(name, frames, isMerged, path)
    return true
end

function refreshFromFiles()
    local files = listSavedFiles()

    if not files then
        notify("Refresh", "listfiles/readfile tidak tersedia, refresh memory saja", 3)
        return 0
    end

    local count = 0

    for _, path in ipairs(files) do
        local p = tostring(path)

        if p:lower():sub(-5) == ".json" then
            if loadOneFile(p) then
                count = count + 1
            end
        end
    end

    refreshCheckpointMarkers()
    return count
end

ix = function()
    local eth_ = 0

    if safeFunc(listfiles) and safeFunc(readfile) then
        eth_ = refreshFromFiles()
    end

    local clipFunc = nil

    if safeFunc(getclipboard) then
        clipFunc = getclipboard
    elseif safeFunc(readclipboard) then
        clipFunc = readclipboard
    end

    if clipFunc then
        local ok, clip = pcall(function()
            return clipFunc()
        end)

        if ok and type(clip) == "string" and #clip > 10 then
            local decoded = decodeJSON(clip)
            local frames = basicNormalizeFrames(decoded)

            if frames then
                local name = getNextDefaultName()
                upsertCheckpoint(name, frames, false, filePathForName(name))
                eth_ = eth_ + 1
                notify("Import", "JSON clipboard masuk sebagai " .. name, 3)
            end
        end
    end

    yc()

    if eth_ > 0 then
        notify("Load", "Berhasil load " .. tostring(eth_) .. " JSON", 3)
    else
        notify("Load", "Tidak ada JSON valid ditemukan", 3)
    end
end

_l = function()
    for _, cp in ipairs(bu) do
        if cp.path then
            deleteFile(cp.path)
        else
            deleteFile(filePathForName(cp.name))
        end
    end

    if safeFunc(listfiles) and safeFunc(delfile) then
        local files = listSavedFiles()

        if files then
            for _, path in ipairs(files) do
                local p = tostring(path)

                if p:lower():sub(-5) == ".json" then
                    deleteFile(p)
                end
            end
        end
    end

    bu = {}
    obr = 1
    clearMergeDots()
    clearCheckpointMarkers()
    yc()
    notify("Del All", "Semua checkpoint dihapus", 3)
end
yc = function()
    if not iq then
        return
    end

    for _, child in ipairs(iq:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local keyword = ""
    if chnu then
        keyword = tostring(chnu.Text or ""):lower()
    end

    table.sort(bu, function(a, b)
        return (a.order or 9999) < (b.order or 9999)
    end)

    local shown = 0

    for _, cp in ipairs(bu) do
        local name = tostring(cp.name or "checkpoint")
        local acs = 0

        if type(cp.frames) == "table" then
            acs = #cp.frames
        end

        local match = keyword == "" or name:lower():find(keyword, 1, true) ~= nil

        if match then
            shown = shown + 1

            local row = Instance.new("Frame")
            row.Name = "CheckpointItem_" .. name
            row.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
            row.Size = UDim2.new(1, -2, 0, 30)
            row.LayoutOrder = shown
            row.Parent = iq
            addCorner(row, 10)
            addStroke(row, Color3.fromRGB(70, 70, 95), 0.35)

            local playBtn = Instance.new("TextButton")
            playBtn.Name = "Play_" .. name
            playBtn.BackgroundTransparency = 1
            playBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
            playBtn.Font = Enum.Font.GothamBold
            playBtn.TextSize = 9
            playBtn.TextXAlignment = Enum.TextXAlignment.Left
            playBtn.Text = name .. " (" .. tostring(acs) .. " frame)"
            playBtn.Size = UDim2.new(1, -64, 1, 0)
            playBtn.Position = UDim2.fromOffset(10, 0)
            playBtn.Parent = row

            local markBtn = Instance.new("TextButton")
            markBtn.Name = "Marker_" .. name
            markBtn.BackgroundColor3 = (wb and xu == name)
                and Color3.fromRGB(55, 120, 80)
                or Color3.fromRGB(55, 55, 75)
            markBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            markBtn.Font = Enum.Font.GothamBold
            markBtn.TextSize = 9
            markBtn.Text = (wb and xu == name) and "✓" or "M"
            markBtn.Size = UDim2.fromOffset(24, 22)
            markBtn.Position = UDim2.new(1, -56, 0.5, -11)
            markBtn.Parent = row
            addCorner(markBtn, 10)

            local delBtn = Instance.new("TextButton")
            delBtn.Name = "Delete_" .. name
            delBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 70)
            delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 10
            delBtn.Text = "X"
            delBtn.Size = UDim2.fromOffset(24, 22)
            delBtn.Position = UDim2.new(1, -28, 0.5, -11)
            delBtn.Parent = row
            addCorner(delBtn, 10)

            bindButton(playBtn, function()
                ky(cp)
            end)

            bindButton(markBtn, function()
                toggleSingleCheckpointMarker(cp)
                yc()
            end)

            bindButton(delBtn, function()

                if cp.path then
                    deleteFile(cp.path)
                else
                    deleteFile(filePathForName(cp.name))
                end

                for i = #bu, 1, -1 do
                    if bu[i] == cp or bu[i].name == cp.name then
                        table.remove(bu, i)
                        break
                    end
                end

                if wb then
                    task.defer(refreshCheckpointMarkers)
                end

                yc()
                notify("Delete", name .. " dihapus", 2)
            end)
        end
    end

    if iq and fzr then
        iq.CanvasSize = UDim2.fromOffset(0, fzr.AbsoluteContentSize.Y + 14)
    end
end

local janp = true
local zjv = 1.08
local vdq = 0.0065
local zuj = 0.180
local gm = 1.250

function mergeAntiSpikeFrameTime(fr)
    return tonumber(fr and fr.times) or tonumber(fr and fr.t) or 0
end

function mergeAntiSpikePairSpeed(a, b, fallback)
    local spd = math.max(
        antiKedutHSpeed(a),
        antiKedutHSpeed(b),
        tonumber(a and a.jqa) or 0,
        tonumber(b and b.jqa) or 0,
        tonumber(a and a.ws) or 0,
        tonumber(b and b.ws) or 0,
        tonumber(fallback) or 0,
        mpm or 8
    )

    if spd <= 0 then
        spd = autoMapDetectNormalRunSpeed({ a, b }) or zudm
    end

    return math.clamp(spd, mpm or 8, slw or 500000)
end

function mergeAntiSpikeDistance(a, b)
    if not a or not b then
        return 0, 0, 0
    end

    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    local d = pb - pa
    local hd = Vector3.new(d.X, 0, d.Z).Magnitude
    local vd = math.abs(d.Y)
    return d.Magnitude, hd, vd
end

function estimateMergeJoinDt(js, newFrame, distOverride)
    if not janp then
        return pw or 0.004
    end

    local dist, hd = mergeAntiSpikeDistance(js, newFrame)
    dist = tonumber(distOverride) or dist or 0

    if dist <= (xil or 0.35) then
        return pw or 0.004
    end

    local f_ = mergeAntiSpikePairSpeed(js, newFrame, nil)
    local jon = math.max(f_ * (zjv or 1.08), 1)
    local needDt = math.max(dist, hd or 0) / jon

    return math.clamp(needDt, vdq or 0.0065, gm or 1.25)
end

function mergeAntiSpikeRetuneTimes(frames)
    if not janp then
        return frames
    end

    frames = basicNormalizeFrames(frames) or frames or {}
    if #frames <= 1 then
        return frames
    end

    local f_ = autoMapDetectNormalRunSpeed(frames) or antiKedutBaseSpeed(frames) or zudm
    local out = {}
    local t = 0

    for i, src in ipairs(frames) do
        local fr = deepCopy(src)

        if i == 1 then
            t = 0
        else
            local prevSrc = frames[i - 1]
            local prevOut = out[#out]
            local rawDt = mergeAntiSpikeFrameTime(src) - mergeAntiSpikeFrameTime(prevSrc)
            local dt = rawDt
            local dist, hd, vd = mergeAntiSpikeDistance(prevOut, fr)
            local isJoin = fr.__mergeJoin == true
            local isRunGap = runAntiBlingIsRunning(prevOut) and runAntiBlingIsRunning(fr)

            if dt <= 0 then
                dt = vdq or 0.0065
            end

            if (isJoin or isRunGap) and dist > 0.005 then
                local _nes = mergeAntiSpikePairSpeed(prevOut, fr, f_)
                local jon = math.max(_nes * (zjv or 1.08), 1)
                local needDt = hd / jon

                if isJoin then
                    needDt = math.max(needDt, dist / jon)
                end

                if dt < needDt then
                    dt = needDt
                end

                if isJoin then
                    dt = math.min(dt, math.max(gm or 1.25, needDt))
                elseif vd <= 1.5 then
                    dt = math.min(dt, math.max(zuj or 0.18, needDt))
                end
            end

            dt = math.max(dt, vdq or 0.0065)
            t = t + dt
        end

        fr.times = roundNumber(t, 9)
        fr.t = fr.times
        table.insert(out, fr)
    end

    return out
end

zkk = function()
    local normal = {}

    for _, cp in ipairs(bu) do
        if not cp.isMerged and cp.frames and #cp.frames > 0 then
            table.insert(normal, cp)
        end
    end

    if #normal <= 0 then
        notify("Merge", "Tidak ada checkpoint untuk digabung", 3)
        return
    end

    table.sort(normal, function(a, b)
        return (a.order or 9999) < (b.order or 9999)
    end)

    local merged = {}
    local yk_ = 0
    local cutJoin = 0
    local uy = 0
    local r_ = 0
    local js = nil

    clearMergeDots()

    for _, cp in ipairs(normal) do
        local frames, removed = cleanFramesForSaveMerge(cp.frames, true)
        uy = uy + (removed or 0)

        if frames and #frames > 0 then
            yk_ = yk_ + 1

            frames = trimIdleStartEnd(frames)
            frames = compactCleanTimes(frames)

            local firstT = tonumber(frames[1].times) or tonumber(frames[1].t) or 0
            local mz = 0

            for i = 1, #frames do
                local newFrame = deepCopy(frames[i])
                local rawT = tonumber(newFrame.times) or tonumber(newFrame.t) or 0
                local localT = rawT - firstT

                if i > 1 and localT <= mz then
                    localT = mz + pw
                end

                if js and i == 1 then
                    createMergeDotPath(
                        yk_,
                        cp.name or ("checkpoint_" .. tostring(yk_)),
                        tableToVec(js.position),
                        tableToVec(newFrame.position)
                    )

                    local dist = (tableToVec(newFrame.position) - tableToVec(js.position)).Magnitude
                    newFrame.__mergeJoin = true
                    newFrame.__mergeJoinDistance = roundNumber(dist, 9)

                    local prevTime = tonumber(js.times) or tonumber(js.t) or (r_ - (pw or 0.004))
                    local joinDt = estimateMergeJoinDt(js, newFrame, dist)
                    r_ = prevTime + math.max(joinDt, pw or 0.004)
                    localT = 0

                    if dist > vqo then

                        newFrame.seam = true
                        cutJoin = cutJoin + 1
                    else

                        newFrame.seam = false
                        newFrame.cutNext = false
                    end
                end

                newFrame.times = roundNumber(r_ + localT, 9)
                newFrame.t = newFrame.times

                table.insert(merged, newFrame)
                js = newFrame
                mz = localT
            end

            r_ = (tonumber(merged[#merged].times) or r_) + pw
        end
    end

    if #merged <= 0 then
        notify("Merge", "Merge gagal, frame kosong", 3)
        return
    end

    merged = cleanFramesForSaveMerge(merged, true)

    merged = mergeAntiSpikeRetuneTimes(merged)

    local ok, msg, path = saveFramesToFile("merged_record", merged)
    upsertCheckpoint("merged_record", merged, true, path)

    if wb then
        task.defer(refreshCheckpointMarkers)
    end

    local dotCount = countMergeDots()

    if ok then
        notify(
            "Merge",
            "merged_record bersih: " .. tostring(yk_)
                .. " file | hapus " .. tostring(uy)
                .. " idle/kedut | cut " .. tostring(cutJoin)
                .. " | titik " .. tostring(dotCount),
            4
        )
    else
        notify("Merge", "Merge masuk memory. " .. tostring(msg) .. " | titik " .. tostring(dotCount), 4)
    end
end

bindButton(z_t, function()

    local ddlg = true
    local feof = false

    pcall(function()
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        local char = lp and lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum then

                feof = (hum.AutoRotate == false)

                hum.Jump = false
                hum.PlatformStand = false
                hum.AutoRotate = true
                local stName = tostring(hum:GetState().Name or "")
                if stName == "Freefall" or stName == "Jumping" or stName == "FallingDown" then
                    ddlg = false
                end
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)

    local waitTime = feof and 0.18 or 0.05
    task.wait(waitTime)
    brd()

    pcall(function()
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        local ji = feof and 0.65 or 0.35
        local zfjf = os.clock() + ji
        local conn
        conn = addConnection(RunService.Heartbeat:Connect(function()
            if os.clock() >= zfjf or not zd then
                if conn then conn:Disconnect() conn = nil end
                return
            end
            local char = lp and lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum then
                if hum.Jump then hum.Jump = false end
                local stName = tostring(hum:GetState().Name or "")
                if ddlg and (stName == "Jumping" or stName == "Freefall") then
                    pcall(function()
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                end
            end
            if hrp and ddlg then
                local v = hrp.AssemblyLinearVelocity
                if v.Y > 0 then
                    hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                end
            end
        end))
    end)
end)

bindButton(_dqf, function()
    setSpeedFromCurrent()
end)

bindButton(eggg, function()
    wf(true)
end)

bindButton(SaveBtn, function()
    mq()
end)

bindButton(fqh, function()
    toggleCheckpointMarkersAll()
    yc()
end)

bindButton(utr, function()
    _l()
end)

bindButton(ozd, function()
    ix()
end)

bindButton(w_ct, function()
    local count = refreshFromFiles()
    yc()
    notify("Refresh", "Refresh selesai. File terbaca: " .. tostring(count), 3)
end)

bindButton(MergeBtn, function()
    zkk()
end)

addConnection(chnu:GetPropertyChangedSignal("Text"):Connect(function()
    yc()
end))

addConnection(speedBox.FocusLost:Connect(function()
    local raw = tostring(speedBox and speedBox.Text or "")
    raw = raw:gsub(",", ".")
    raw = raw:gsub("^%s+", "")
    raw = raw:gsub("%s+$", "")

    if raw == "" or raw:lower() == "auto" then
        if speedBox then
            speedBox.Text = "AUTO"
        end
        notify("Speed", "AUTO MAP aktif. Playback ikut speed asli JSON/map.", 2)
        return
    end

    local spd = setSyncBaseSpeed(raw, true)
    notify("Speed", "MANUAL speed: " .. tostring(spd) .. " stud/s", 2)
end))

bindButton(StopBtn, function()
    le()
end)

bindButton(qpw, function()
    on()
end)

bindButton(MinBtn, function()
    _px.Visible = false
    MiniLogo.Visible = true
end)

bindButton(MiniLogo, function()
    MiniLogo.Visible = false
    _px.Visible = true
end)

bindButton(CloseBtn, function()
    cleanup()
end)

if yc then
    yc()
end

task.spawn(function()
    task.wait(0.5)

    ensureFolder()

    if safeFunc(listfiles) and safeFunc(readfile) then
        local count = refreshFromFiles()

        if yc then
            yc()
        end

        if count > 0 then
            notify("ONIUM Recorder", "Auto load " .. tostring(count) .. " JSON", 3)
        else
            notify("ONIUM Recorder", "Siap digunakan", 2)
        end
    else
        notify("ONIUM Recorder", "Siap. File API tidak lengkap, memory mode aktif.", 4)
    end
end)