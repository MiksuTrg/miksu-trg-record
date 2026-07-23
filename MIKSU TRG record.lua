--// =========================================================
--// GENERATED FULL FIX BY GPT - AUTO MAP CLEAN SPEED PATCH
--// File ini dibuat dari script yang kamu upload.
--// Fokus fix: SAVE tetap hapus kedut, tapi speed normal map/coil dikunci otomatis.
--// =========================================================

--// =========================================================
--// ONIUM Recorder / BittWise Recorder  
--// v1.5.1 SUPER SMOOTH - Bug fixes applied
--// Delta + Xeno Mobile Friendly
--// FULL BITWISE SUPPORT + RAW MOMENTUM + ANTI KEDUT + SAFE ROLLBACK + CP MARKER
--// PATCH: AUTO MAP CLEAN + ANTI KEDUT + NORMAL SPEED LOCK + MERGE ANTI SPEED SPIKE
--// =========================================================

--// Anti duplicate
local ENV = _G
pcall(function()
    if getgenv then
        ENV = getgenv()
    end
end)

if ENV.__ONIUM_RECORDER_CLEANUP then
    pcall(ENV.__ONIUM_RECORDER_CLEANUP)
end

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Config
local FOLDER_NAME = "ONIUM_RECORDER"
local CUSTOM_LOGO_ASSET = "rbxassetid://130280202431400"
local USE_NATURAL_MAP_JUMP = true
local USE_MAP_WALKSPEED_ON_PLAYBACK = true
local USE_MAP_HIPHEIGHT_ON_PLAYBACK = true
local SAMPLE_INTERVAL = 0.004 -- RAW recorder: sample rapat, times tetap waktu asli

--// =========================================================
--// AUTO MAP CLEAN SPEED FIX 2026-05-09
--// SAVE tetap menghapus kedut seperti versi lama, tetapi speed lari normal
--// dikunci otomatis mengikuti map/coil yang sedang dipakai.
--// Contoh: kalau map speed normal 51, frame belok/mundur yang turun jadi 30
--// akan dinaikkan kembali ke 51 tanpa hardcode angka 51.
--// =========================================================
local EXPORT_RAW_EXACT_MODE = true
local RAW_EXACT_KEEP_WALKSPEED = true
local RAW_EXACT_SAVE_WITHOUT_HEAVY_CLEANER = false
local RAW_EXACT_DISABLE_PREVIEW_SPEED_MULTIPLIER = true
local RAW_EXACT_MIN_DT = 0.001

local AUTO_MAP_CLEAN_SPEED_MODE = true
local AUTO_MAP_LOCK_RUN_SPEED = true
local AUTO_MAP_SPEED_MIN_SAMPLES = 6
local AUTO_MAP_SPEED_DROP_TOLERANCE = 0.94
local AUTO_MAP_SPEED_SPIKE_CAP_MULT = 1.10
local AUTO_MAP_SPEED_MIN_MOVEDIR = 0.045
local AUTO_MAP_SPEED_USE_TIMING_FIX = true
local AUTO_MAP_SPEED_MIN_DT = 0.0065
local AUTO_MAP_SPEED_MAX_DT = 0.085  -- v1.5.1: turun dari 0.140

--// PATCH LIGHT RECORD:
--// Record tetap akurat, tapi tidak lagi kerja berat setiap heartbeat.
--// 1) UI overlay di-update berkala, bukan 2x tiap frame.
--// 2) Ground raycast/cache tidak dipanggil setiap frame.
--// 3) Frame record dibatasi agar HP/Delta/Xeno tidak berat saat REC.
local RECORD_LIGHT_MODE = true
local RECORD_MIN_SAMPLE_DT = 0.0085      -- kira-kira max 117 fps; 60 fps tetap aman
local RECORD_AIR_SAMPLE_DT = 0.0045      -- saat jump/freefall boleh lebih rapat; mobile Delta butuh ambil tiap heartbeat
local RECORD_UI_UPDATE_INTERVAL = 0.10
local RECORD_GROUND_CACHE_INTERVAL = 0.025  -- v1.5.1: turun dari 0.055
local RECORD_TOOL_CACHE_INTERVAL = 0.15

--// PATCH MOBILE DELTA JUMP 2026-05-14:
--// Android + Delta sering FPS/tick lebih renggang dari PC Xeno.
--// Fix ini TIDAK lagi memaksa Running menjadi Jumping/Freefall hanya dari velocity Y.
--// Tujuan: record Delta tetap rapi seperti Xeno, tetapi lari di gundukan/jalan tidak rata
--// tetap dibaca Running, bukan lompat/terjun palsu.
local MOBILE_DELTA_JUMP_SAFE_MODE = true
local MOBILE_DELTA_AIR_MIN_DT = 0.010
local MOBILE_DELTA_AIR_MAX_DT = 0.045
local MOBILE_DELTA_GROUND_MIN_DT = 0.0085
local MOBILE_DELTA_GROUND_MAX_DT = 0.030
local MOBILE_DELTA_NORMAL_MAX_DT = 0.055
local MOBILE_DELTA_KEEP_RAW_DT_RATIO = 0.85
local MOBILE_DELTA_JUMP_Y_TRIGGER = 5.5  -- v1.5.1: turun dari 7.5
local MOBILE_DELTA_FALL_Y_TRIGGER = -5.5
local MOBILE_DELTA_VELOCITY_CONFIRM_FRAMES = 2

--// Playback speed mode dibuat sama seperti ONIUM Race:
--// angka speed = stud/s, bukan multiplier x.
local MIN_PLAYBACK_SPEED = 8
local MAX_PLAYBACK_SPEED = 500000
local DEFAULT_PLAYBACK_SPEED = 16

--// FORMAT JSON KHUSUS BITWISE
--// Samakan dengan JSON normal kedua.
local BITWISE_JSON_WALKSPEED = 45
local BITWISE_JSON_HIPHEIGHT = 5.331189155578613

--// Filter record agar avatar diam tidak masuk JSON
local MIN_RECORD_DISTANCE = 0.09
local MIN_MOVE_DIRECTION = 0.02
local MIN_HORIZONTAL_VELOCITY = 0.15

--// Filter merge agar idle frame dibuang
local CLEAN_DISTANCE_THRESHOLD = 0.07
local CLEAN_VERTICAL_THRESHOLD = 0.10

--// Smooth playback / merge anti-blink
--// v1.5.1: Adaptive step distance for smoother playback
local PLAYBACK_STEP_DISTANCE = 0.60  -- base, was 0.85
local PLAYBACK_STEP_DISTANCE_SLOW = 0.45  -- speed < 30
local PLAYBACK_STEP_DISTANCE_FAST = 0.75  -- speed > 70
local PLAYBACK_STEP_DISTANCE_AIR = 0.35   -- air movement
local PLAYBACK_MIN_STEP_DISTANCE = 0.04

--// FIX PLAY AFTER FINISH:
--// Kalau avatar masih berdiri di posisi FINISH lalu PLAY lagi, langsung balik ke START.
--// Kalau avatar sudah jauh dari FINISH, smart resume tetap mulai dari titik path terdekat.
local PLAY_AGAIN_FINISH_RESET_DISTANCE = 18
local PLAY_AGAIN_FINISH_TIME_WINDOW = 0.12

--// FIX LOOP SPEED:
--// Pengaman agar mode loop/toggle loop dari versi UI lain tidak membuat velocity dobel/kenceng.
local LOOP_SPEED_SAFE_CAP_MULTIPLIER = 1.12

--// Speed sync limiter:
--// Export JSON akan retime berdasarkan jarak / speed set, supaya saat di-load di ONIUM Race
--// speedometer tidak tembus jauh di atas angka yang kamu set.
local SPEED_TIMING_MIN_DT = 0.006
local SPEED_TIMING_MAX_DT = 0.18

--// Jangan tarik karakter untuk jarak jauh.
--// Kalau jarak antar frame/antar file terlalu jauh, playback akan cut/teleport sekali, bukan ditarik bolak-balik.
local PLAYBACK_MAX_SMOOTH_DISTANCE = 10
local MERGE_SKIP_JOIN_DISTANCE = 0.35
local MERGE_MAX_BRIDGE_DISTANCE = 10
local MAX_BRIDGE_FRAMES = 80

--// Ground / object detector untuk rollback ke object terakhir yang diinjak
local GROUND_RAY_DISTANCE = 9

--// Rollback
local ROLLBACK_SECONDS = 2.5
local ROLLBACK_MAX_FRAMES = math.max(5, math.floor(ROLLBACK_SECONDS / SAMPLE_INTERVAL))

--// UI Vars
local ScreenGui
local MainFrame
local MiniLogo
local RecordOverlay
local ToastLabel

local searchBox
local saveNameBox
local speedBox
local listFrame
local listLayout
local timerLabel
local overlayStatusLabel
local frameCountLabel
local cpMarkerToggleBtn

--// Data State
local checkpoints = {}
local nextOrder = 1

--// TITIK PETUNJUK SAMBUNGAN CP
local seamDotFolder = nil
local MERGE_DOT_ENABLED = true
local MERGE_DOT_COUNT = 12
local MERGE_DOT_SIZE = 0.46
local MERGE_DOT_HEIGHT = 0.35

--// TANDA PER CP + SAMBUNGAN MERGE
--// Default OFF supaya saat SAVE tidak freeze/render berat.
local CP_MARKER_ENABLED = false
local CP_MARKER_SELECTED_NAME = nil -- nil = semua CP, string = hanya 1 checkpoint
local CP_MARKER_CULLER_TOKEN = 0
local CP_MARKER_DOT_COUNT = 6
local CP_MARKER_SIZE = 0.42
local CP_MARKER_HEIGHT = 1.25
local CP_MARKER_MAX_PER_CP = 8
--// Marker CP jangan ganggu layar: hanya kelihatan kalau dekat.
CP_MARKER_LABEL_MAX_DISTANCE = 45
CP_MARKER_VISIBLE_DISTANCE = 70
CP_MARKER_CULL_INTERVAL = 0.35

local recordFrames = {}
local temporaryRecord = {}

local isRecording = false
local isRollbacking = false
local rollbackCancel = false
local rollbackToken = 0
local isPlaying = false
local playToken = 0

--// Speed sync seperti ONIUM Race
--// currentPlaybackSpeed = speed yang kamu set dari speedometer / manual.
--// syncBaseSpeed = speed dasar yang akan ditulis ke JSON sebagai ws.
--// ONIUM Race menghitung: speedMultiplier = currentPlaybackSpeed / recordedBaseSpeed.
--// Jadi kalau di ONIUM Race kamu Set Speed dari speedometer dengan angka yang sama,
--// replay akan jalan normal/sinkron.
local currentPlaybackSpeed = DEFAULT_PLAYBACK_SPEED
local syncBaseSpeed = DEFAULT_PLAYBACK_SPEED

local recordConnection = nil
local allConnections = {}

--// Record cursor position supaya setelah rollback record lanjut smooth
local lastRecordSavedPos = nil
local recordStartClock = 0

--// FIX COIL SPEED:
--// Jangan biarkan rollback / stop record menurunkan speed coil.
--// Kita simpan speed humanoid sebelum record dan speed tertinggi saat tool/coil dipakai.
local preRecordWalkSpeed = nil
local lastKnownToolWalkSpeed = nil
local lastKnownEquippedTool = ""
local savedMouseBehavior = nil
local savedMouseIconEnabled = nil

local function forceShiftLockOff()
    pcall(function()
        savedMouseBehavior = savedMouseBehavior or UserInputService.MouseBehavior
        savedMouseIconEnabled = savedMouseIconEnabled
            or UserInputService.MouseIconEnabled
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

local function restoreMouseLockState()
    pcall(function()
        if savedMouseBehavior ~= nil then
            UserInputService.MouseBehavior = savedMouseBehavior
        end
        if savedMouseIconEnabled ~= nil then
            UserInputService.MouseIconEnabled = savedMouseIconEnabled
        end
    end)
    savedMouseBehavior = nil
    savedMouseIconEnabled = nil
end

--// FIX MAP SPEED AFTER PREVIEW/PLAY STOP:
--// Setiap map bisa punya WalkSpeed berbeda.
--// Jadi speed asli map disimpan SEBELUM preview/playback, lalu dipakai lagi saat stop/finish.
--// Jangan memakai currentPlaybackSpeed/syncBaseSpeed sebagai speed normal map.
local prePlaybackMapWalkSpeed = nil
local prePlaybackHadTool = false

function hasEquippedToolSafe(char)
    char = char or LocalPlayer.Character
    if not char then
        return false
    end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            lastKnownEquippedTool = obj.Name
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

    --// Ambil speed asli sebelum playback mengubah Humanoid.WalkSpeed.
    prePlaybackMapWalkSpeed = tonumber(hum.WalkSpeed) or DEFAULT_PLAYBACK_SPEED
    prePlaybackHadTool = hasEquippedToolSafe(char)
end

--// Forward
local refreshList
local playCheckpoint
local stopPlayback
local startRecording
local stopRecording
local rollbackRecording
local saveTemporaryRecord
local importLoad
local deleteAllCheckpoints
local mergeCheckpoints

--// =========================================================
--// Utility
--// =========================================================

function addConnection(c)
    if c then
        table.insert(allConnections, c)
    end
    return c
end

function cleanup()
    pcall(function()
        if recordConnection then
            recordConnection:Disconnect()
            recordConnection = nil
        end
    end)

    for _, c in ipairs(allConnections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    playToken = playToken + 1
    isPlaying = false
    isRecording = false
    isRollbacking = false
    restoreMouseLockState()

    --// Hapus titik sambungan kalau script diexecute ulang / diclose
    pcall(function()
        if seamDotFolder then
            seamDotFolder:Destroy()
            seamDotFolder = nil
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
        if ScreenGui then
            ScreenGui:Destroy()
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
    raw = tostring(raw or fallback or DEFAULT_PLAYBACK_SPEED)
    raw = raw:gsub(",", ".")
    raw = raw:gsub("[^%d%.%-]", "")

    local spd = tonumber(raw) or tonumber(fallback) or DEFAULT_PLAYBACK_SPEED
    spd = math.clamp(spd, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)

    return roundNumber(spd, 1)
end

function setSyncBaseSpeed(value, updateBox)
    local spd = parseSpeedValue(value, syncBaseSpeed or currentPlaybackSpeed or DEFAULT_PLAYBACK_SPEED)

    currentPlaybackSpeed = spd
    syncBaseSpeed = spd

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
    -- RAW precision: jangan bulatkan 4 digit, karena city/position contoh JSON punya detail banyak.
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

    --// PRIORITAS RESTORE SPEED:
    --// 1) speedOverride kalau memang dikirim manual.
    --// 2) speed asli map yang disimpan sebelum preview/playback.
    --// 3) speed sebelum record.
    --// 4) WalkSpeed sekarang / default.
    local targetSpeed = tonumber(speedOverride)
        or tonumber(prePlaybackMapWalkSpeed)
        or tonumber(preRecordWalkSpeed)
        or tonumber(hum and hum.WalkSpeed)
        or DEFAULT_PLAYBACK_SPEED

    local toolNow = hasEquippedToolSafe(char)

    --// Kalau sedang pakai coil/tool, jangan turunkan speed tool.
    --// Kalau tidak pakai tool, PAKSA balik ke speed map asli, bukan speed playback.
    if toolNow then
        if tonumber(hum and hum.WalkSpeed) then
            targetSpeed = math.max(targetSpeed, tonumber(hum.WalkSpeed))
        end

        if tonumber(lastKnownToolWalkSpeed) then
            targetSpeed = math.max(targetSpeed, tonumber(lastKnownToolWalkSpeed))
        end
    else
        targetSpeed = tonumber(speedOverride)
            or tonumber(prePlaybackMapWalkSpeed)
            or tonumber(preRecordWalkSpeed)
            or DEFAULT_PLAYBACK_SPEED
    end

    targetSpeed = math.clamp(targetSpeed, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)

    local function applyRestore()
        char, hum, hrp = getCharacter()
        local stillTool = hasEquippedToolSafe(char)

        if hum then
            pcall(function()
                hum.AutoRotate = true
                hum.PlatformStand = false
                hum.Sit = false

                if stillTool then
                    --// Tool/coil: hanya naikkan kalau speed turun.
                    if (tonumber(hum.WalkSpeed) or 0) < targetSpeed - 0.1 then
                        hum.WalkSpeed = targetSpeed
                    end
                else
                    --// Non-tool: kembalikan tepat ke speed map asli.
                    hum.WalkSpeed = targetSpeed
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

    --// Beberapa map/game script menulis WalkSpeed ulang 1-3 frame setelah stop.
    --// Restore diulang sebentar agar tidak nyangkut ke speed preview/playback.
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

function isAirState(state)
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

    -- Untuk JSON lama yang belum punya floorMaterial/grounded, ground dipakai hanya sebagai
    -- pelindung agar Running di jalan miring/gundukan tidak dipaksa jadi Freefall.
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

    local need = math.max(1, tonumber(MOBILE_DELTA_VELOCITY_CONFIRM_FRAMES) or 2)
    local upward = (tonumber(yv) or 0) >= (MOBILE_DELTA_JUMP_Y_TRIGGER or 7.5)
    local downward = (tonumber(yv) or 0) <= (MOBILE_DELTA_FALL_Y_TRIGGER or -5.5)

    if not upward and not downward then
        return false
    end

    local count = 0
    for j = math.max(1, index - 1), math.min(#frames, index + 1) do
        local fr = frames[j]
        if type(fr) == "table" and not mobileDeltaFrameHasGroundContact(fr) then
            local vy = tableToVec(fr.city).Y
            if upward and vy >= (MOBILE_DELTA_JUMP_Y_TRIGGER or 7.5) then
                count = count + 1
            elseif downward and vy <= (MOBILE_DELTA_FALL_Y_TRIGGER or -5.5) then
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

    return fr.mobileRecord == true
        or fr.isMobileRecord == true
        or tostring(fr.inputDevice or "") == "MobileDelta"
        or tostring(fr.executorDevice or "") == "DeltaAndroid"
end

function framesLookMobileDeltaSafe(frames)
    if type(frames) ~= "table" or #frames <= 0 then
        return false
    end

    local mobileTagged = 0
    local noShift = 0
    local total = 0
    local dtSum = 0
    local dtCount = 0
    local lastT = nil

    for _, fr in ipairs(frames) do
        if type(fr) == "table" then
            total = total + 1
            if frameIsMobileDeltaSafe(fr) then
                mobileTagged = mobileTagged + 1
            end
            if fr.noShiftLock == true or tostring(fr.rotationMode or "") == "AutoRotate" then
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

    if mobileTagged >= math.max(1, math.floor(total * 0.10)) then
        return true
    end

    -- Fallback untuk record lama: mobile Delta biasanya AutoRotate/noShiftLock
    -- dan jarak timestamp lebih renggang daripada PC Xeno.
    local avgDt = dtCount > 0 and (dtSum / dtCount) or 0
    return noShift >= math.max(5, math.floor(total * 0.72)) and avgDt >= 0.018
end

function mobileDeltaFixAirStateByVelocity(frames)
    if not MOBILE_DELTA_JUMP_SAFE_MODE or not framesLookMobileDeltaSafe(frames) then
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
                    -- FIX UTAMA: lari di gundukan/jalan tidak rata bisa punya velocity Y,
                    -- tapi selama masih grounded jangan ditulis sebagai Jumping/Freefall.
                    if st == "Jumping" or st == "Freefall" or st == "FallingDown" or fr.jump == true then
                        fr.states = "Running"
                        fr.jump = false
                    end
                else
                    -- Delta support tetap ada, tapi hanya untuk frame yang benar-benar tidak menapak
                    -- dan velocity terkonfirmasi minimal beberapa frame, bukan 1 spike gundukan.
                    local explicitAir = st == "Jumping" or st == "Freefall" or st == "FallingDown"
                    local velocityAir = mobileDeltaVelocityConfirmedAir(out, i, yv)

                    if explicitAir or velocityAir then
                        if yv >= (MOBILE_DELTA_JUMP_Y_TRIGGER or 7.5) then
                            fr.states = "Jumping"
                            fr.jump = true
                        elseif yv <= (MOBILE_DELTA_FALL_Y_TRIGGER or -5.5) then
                            fr.states = "Freefall"
                            fr.jump = false
                        elseif explicitAir then
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
            Vector3.new(0, -GROUND_RAY_DISTANCE, 0),
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

--// =========================================================
--// ROLLBACK TARGET: BALIK KE POSISI SEBELUM LOMPAT
--// Cari frame terakhir yang masih grounded sebelum Jumping/Freefall
--// =========================================================

--// =========================================================
--// ROLLBACK TARGET: BALIK KE POSISI SEBELUM LOMPAT
--// Contoh: dari tangga A lompat ke tangga B gagal/jatuh,
--// pencet ROLL -> balik ke posisi terakhir sebelum kaki lepas dari tangga A.
--// =========================================================

local ROLLBACK_BEFORE_JUMP_BACKSTEP = 2 -- mundur 2 frame biar benar-benar sebelum lompat

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
    local hasGround = groundKeyFromFrame(fr) ~= nil

    --// State udara jelas
    if fr.jump == true
        or st == "Jumping"
        or st == "Freefall"
        or st == "FallingDown"
    then
        return true
    end

    --// Kalau tidak ada ground dan velocity Y bergerak, anggap udara
    if not hasGround and math.abs(yVel) > 1.5 then
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

    --// Jangan pilih climbing/swimming sebagai titik sebelum lompat biasa
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
    local n = #recordFrames
    if n <= 2 then
        return nil, nil
    end

    --// 1) Cari area udara terakhir dari belakang.
    --// Ini berarti kalau sudah jatuh/mendarat setelah gagal lompat,
    --// tetap balik ke lompatan terakhir, bukan ke tempat jatuh.
    local lastAirIndex = nil
    for i = n, 1, -1 do
        if isRollbackAirFrame(recordFrames[i]) then
            lastAirIndex = i
            break
        end
    end

    if not lastAirIndex then
        return nil, nil
    end

    --// 2) Cari awal area udara itu.
    local airStart = lastAirIndex
    while airStart > 1 and isRollbackAirFrame(recordFrames[airStart - 1]) do
        airStart = airStart - 1
    end

    --// 3) Cari frame ground terakhir sebelum udara.
    local groundIndex = nil
    for i = airStart - 1, 1, -1 do
        if isRollbackGroundFrame(recordFrames[i]) then
            groundIndex = i
            break
        end
    end

    if not groundIndex then
        return nil, nil
    end

    --// 4) Mundur sedikit supaya benar-benar sebelum loncat,
    --// bukan pas frame kaki hampir lepas.
    local safeIndex = math.max(1, groundIndex - ROLLBACK_BEFORE_JUMP_BACKSTEP)

    --// Cari lagi frame ground terdekat dari safeIndex.
    for i = safeIndex, groundIndex do
        if isRollbackGroundFrame(recordFrames[i]) then
            return i, "sebelum_lompat"
        end
    end

    return groundIndex, "sebelum_lompat"
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

    if not ToastLabel then
        return
    end

    ToastLabel.Text = title .. " | " .. text
    ToastLabel.Visible = true

    task.delay(sec, function()
        if ToastLabel and ToastLabel.Text == title .. " | " .. text then
            ToastLabel.Visible = false
        end
    end)
end

--// =========================================================
--// TITIK PATH KHUSUS SAMBUNGAN MERGE CP
--// =========================================================

--// =========================================================
--// TITIK PATH KHUSUS SAMBUNGAN MERGE CP
--// =========================================================

function clearMergeDots()
    pcall(function()
        if seamDotFolder then
            seamDotFolder:Destroy()
            seamDotFolder = nil
        end

        local old = workspace:FindFirstChild("ONIUM_MERGE_DOTS")
        if old then
            old:Destroy()
        end
    end)
end

function getMergeDotFolder()
    if seamDotFolder and seamDotFolder.Parent then
        return seamDotFolder
    end

    local old = workspace:FindFirstChild("ONIUM_MERGE_DOTS")
    if old then
        old:Destroy()
    end

    seamDotFolder = Instance.new("Folder")
    seamDotFolder.Name = "ONIUM_MERGE_DOTS"
    seamDotFolder.Parent = workspace

    return seamDotFolder
end

function groundPositionForDot(pos)
    local origin = pos + Vector3.new(0, 8, 0)
    local direction = Vector3.new(0, -60, 0)

    local params = RaycastParams.new()
    pcall(function()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
        params.IgnoreWater = true
    end)

    local ok, result = pcall(function()
        return workspace:Raycast(origin, direction, params)
    end)

    if ok and result and result.Position then
        return result.Position + Vector3.new(0, MERGE_DOT_HEIGHT, 0)
    end

    return pos + Vector3.new(0, MERGE_DOT_HEIGHT, 0)
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
    p.Size = size or Vector3.new(CP_MARKER_SIZE, CP_MARKER_SIZE, CP_MARKER_SIZE)
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
    if not MERGE_DOT_ENABLED then
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

    local dotCount = MERGE_DOT_COUNT
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
            Vector3.new(MERGE_DOT_SIZE * sizeMul, MERGE_DOT_SIZE * sizeMul, MERGE_DOT_SIZE * sizeMul),
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
    --// Stop culler lama supaya tidak ada task render jalan terus.
    CP_MARKER_CULLER_TOKEN = CP_MARKER_CULLER_TOKEN + 1

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

    --// Hanya 1 culler aktif. Kalau marker direfresh/clear, task lama otomatis berhenti.
    CP_MARKER_CULLER_TOKEN = CP_MARKER_CULLER_TOKEN + 1
    local myToken = CP_MARKER_CULLER_TOKEN

    task.spawn(function()
        local tokenFolder = folder
        while myToken == CP_MARKER_CULLER_TOKEN and tokenFolder and tokenFolder.Parent do
            local _, _, hrp = getCharacter()
            if hrp then
                local myPos = hrp.Position
                for _, obj in ipairs(tokenFolder:GetDescendants()) do
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
    if not CP_MARKER_ENABLED or not cp or type(cp.frames) ~= "table" or #cp.frames <= 0 then
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

    local startGround = groundPositionForDot(startPos) + Vector3.new(0, CP_MARKER_HEIGHT, 0)
    local endGround = groundPositionForDot(endPos) + Vector3.new(0, CP_MARKER_HEIGHT, 0)

    local startPart = createMarkerPart(
        folder,
        "CP_" .. tostring(cpIndex) .. "_START",
        startGround,
        Color3.fromRGB(70, 255, 130),
        Vector3.new(CP_MARKER_SIZE, CP_MARKER_SIZE, CP_MARKER_SIZE),
        Enum.PartType.Ball
    )
    makeBillboardLabel(startPart, "CP " .. tostring(cpIndex) .. " START\n" .. cpName, Color3.fromRGB(70, 255, 130))

    local endPart = createMarkerPart(
        folder,
        "CP_" .. tostring(cpIndex) .. "_END",
        endGround,
        Color3.fromRGB(255, 95, 95),
        Vector3.new(CP_MARKER_SIZE, CP_MARKER_SIZE, CP_MARKER_SIZE),
        Enum.PartType.Ball
    )
    makeBillboardLabel(endPart, "CP " .. tostring(cpIndex) .. " END", Color3.fromRGB(255, 95, 95))

    local count = math.min(CP_MARKER_MAX_PER_CP, math.max(2, CP_MARKER_DOT_COUNT))
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
                Vector3.new(CP_MARKER_SIZE * 0.62, CP_MARKER_SIZE * 0.62, CP_MARKER_SIZE * 0.62),
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

    if not CP_MARKER_ENABLED then
        return
    end

    local selectedName = CP_MARKER_SELECTED_NAME and tostring(CP_MARKER_SELECTED_NAME) or nil
    local normal = {}

    for _, cp in ipairs(checkpoints or {}) do
        if cp and not cp.isMerged and type(cp.frames) == "table" and #cp.frames > 0 then
            local cpName = tostring(cp.name or "")
            if not selectedName or selectedName == "" or cpName == selectedName then
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
        --// Jangan render semua dalam 1 frame kalau jumlah CP banyak.
        if i % 2 == 0 then
            task.wait()
        end
    end

    startCheckpointMarkerDistanceCuller(workspace:FindFirstChild("ONIUM_CP_MARKERS"))
end

function updateCpMarkerToggleButton()
    if not cpMarkerToggleBtn then
        return
    end

    if CP_MARKER_ENABLED then
        if CP_MARKER_SELECTED_NAME then
            cpMarkerToggleBtn.Text = "CP 1"
        else
            cpMarkerToggleBtn.Text = "CP ON"
        end
        cpMarkerToggleBtn.BackgroundColor3 = Color3.fromRGB(55, 120, 80)
    else
        cpMarkerToggleBtn.Text = "CP OFF"
        cpMarkerToggleBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    end
end

function setCheckpointMarkerMode(enabled, selectedName, quiet)
    CP_MARKER_ENABLED = enabled == true

    if CP_MARKER_ENABLED then
        CP_MARKER_SELECTED_NAME = selectedName and tostring(selectedName) or nil
        task.defer(refreshCheckpointMarkers)
    else
        CP_MARKER_SELECTED_NAME = nil
        clearCheckpointMarkers()
    end

    updateCpMarkerToggleButton()

    if not quiet then
        if CP_MARKER_ENABLED then
            if CP_MARKER_SELECTED_NAME then
                notify("CP Marker", "ON hanya: " .. tostring(CP_MARKER_SELECTED_NAME), 2)
            else
                notify("CP Marker", "ON semua checkpoint", 2)
            end
        else
            notify("CP Marker", "OFF. Save jadi lebih ringan.", 2)
        end
    end
end

function toggleCheckpointMarkersAll()
    if CP_MARKER_ENABLED and not CP_MARKER_SELECTED_NAME then
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

    if CP_MARKER_ENABLED and CP_MARKER_SELECTED_NAME == name then
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
    local diff = b - a
    diff = diff - math.floor((diff + math.pi) / (2 * math.pi)) * (2 * math.pi)
    return a + diff * t
end

--// v1.5.1: Cubic easing untuk smooth natural interpolation
function easeCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        return 1 - math.pow(-2 * t + 2, 3) / 2
    end
end
--// =========================================================
--// FIX NO SHIFT LOCK PLAYBACK
--// Kalau record tanpa shift lock, playback jangan paksa AutoRotate=false
--// =========================================================

function detectNoShiftLockRecord(hum, hrp)
    --// MOBILE-SAFE detection.
    --// Di mobile, MoveDirection selalu sejajar LookVector (thumbstick relatif kamera),
    --// jadi dot product TIDAK bisa dipakai -> dulu sering false-positive "no shift lock"
    --// yang menyebabkan bug jump/teleport saat Save -> Record lagi.
    if not hum or not hrp then
        return false
    end

    local UIS = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer

    local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled and not UIS.KeyboardEnabled

    if isMobile then
        --// Cek apakah map memaksa shift lock / lock kamera.
        local mapLocks = false
        pcall(function()
            if lp and lp.DevEnableMouseLock then mapLocks = true end
            if hum.CameraOffset and hum.CameraOffset.Magnitude > 0.5 then mapLocks = true end
        end)
        --// Default mobile tanpa lock = autoRotate (no shift lock).
        --// Map yang lock kamera = anggap shift lock (return false).
        return not mapLocks
    end

    --// PC path: pakai logic lama (dot product).
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

    return fr.noShiftLock == true
        or fr.rotationMode == "AutoRotate"
end

--// =========================================================
--// Safe File API
--// =========================================================

function safeFunc(fn)
    return type(fn) == "function"
end

function ensureFolder()
    if safeFunc(isfolder) and safeFunc(makefolder) then
        local ok, exists = pcall(function()
            return isfolder(FOLDER_NAME)
        end)

        if ok and not exists then
            pcall(function()
                makefolder(FOLDER_NAME)
            end)
        elseif not ok then
            pcall(function()
                makefolder(FOLDER_NAME)
            end)
        end
    elseif safeFunc(makefolder) then
        pcall(function()
            makefolder(FOLDER_NAME)
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
    return FOLDER_NAME .. "/" .. cleanFileName(name) .. ".json"
end

--// =========================================================
--// PERBAIKAN UTAMA: Ekspor JSON dan Timing
--// =========================================================

-- Fungsi baru untuk retime, sekarang JAUH lebih sederhana.
-- Tujuannya hanya untuk menghitung `times` tanpa mengubah kecepatan (velocity/city).
function retimeFramesForExport(frames)
    -- RAW EXACT: timing tetap dari record asli.
    -- Hanya dinormalisasi supaya frame pertama mulai dari 0 dan time tidak mundur/duplikat.
    local source = basicNormalizeFrames(frames) or frames or {}
    local result = {}
    local firstTime = nil
    local lastTime = nil
    local minDt = tonumber(RAW_EXACT_MIN_DT) or 0.001

    for _, fr in ipairs(source) do
        if type(fr) == "table" then
            local copy = deepCopy(fr)
            local rawTime = tonumber(copy.times) or tonumber(copy.t) or 0

            if firstTime == nil then
                firstTime = rawTime
            end

            local t = rawTime - firstTime

            -- Kalau executor/HP memberi timestamp sama, jangan sampai 2 frame punya time sama.
            -- Ini mencegah replay membaca dt=0 yang sering terasa seperti bling speed.
            if lastTime ~= nil and t <= lastTime then
                t = lastTime + minDt
            end

            copy.times = roundNumber(t, 9)
            copy.t = copy.times

            -- Jaga field penting tetap ada tanpa mengganti isi aslinya.
            if copy.walkSpeed == nil and copy.ws ~= nil then
                copy.walkSpeed = copy.ws
            end
            if copy.ws == nil and copy.walkSpeed ~= nil then
                copy.ws = copy.walkSpeed
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
    -- Fallback raw-only. Mode utama sekarang memakai cleanFramesForSaveMerge + autoMapCleanSpeedForSave.
    return retimeFramesForExport(frames), 0
end

--// =========================================================
--// BITWISE SUPPORT SPEED DETECTOR
--// BitWise replay memakai walkSpeed frame pertama sebagai base speed.
--// Kalau Humanoid.WalkSpeed tetap 16 tetapi velocity/city map 50+,
--// JSON harus menulis base speed dari momentum asli agar manual speed tidak ngaco.
--// =========================================================
function getFrameHorizontalCitySpeedForBitwise(fr)
    local city = tableToVec(fr and fr.city)
    return Vector3.new(city.X, 0, city.Z).Magnitude
end

function detectBitwiseBaseSpeed(frames)
    local runValues = {}
    local allValues = {}

    for _, fr in ipairs(frames or {}) do
        if type(fr) == "table" then
            local stateText = tostring(fr.states or fr.state or "Running")
            local hSpeed = getFrameHorizontalCitySpeedForBitwise(fr)
            local ws = tonumber(fr.walkSpeed) or tonumber(fr.ws) or 0
            local candidate = math.max(hSpeed, ws)

            if candidate >= MIN_PLAYBACK_SPEED then
                table.insert(allValues, candidate)

                if stateText == "Running" or stateText == "Landed" then
                    table.insert(runValues, candidate)
                end
            end
        end
    end

    local values = (#runValues >= 3) and runValues or allValues

    if #values <= 0 then
        return parseSpeedValue(syncBaseSpeed or currentPlaybackSpeed or DEFAULT_PLAYBACK_SPEED, DEFAULT_PLAYBACK_SPEED)
    end

    table.sort(values)

    -- Pakai median/area tengah supaya frame awal pelan dan frame stop tidak bikin base speed salah.
    local startIndex = math.max(1, math.floor(#values * 0.35))
    local endIndex = math.max(startIndex, math.ceil(#values * 0.75))
    local sum = 0
    local count = 0

    for i = startIndex, endIndex do
        sum = sum + (tonumber(values[i]) or 0)
        count = count + 1
    end

    local base = sum / math.max(count, 1)
    return math.clamp(roundNumber(base, 1), MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)
end


--// =========================================================
--// AUTO MAP NORMAL SPEED LOCK
--// Masalah user: saat belok/mundur, hasil save kadang menulis speed/city lebih pelan
--// dari speed normal map. Fix ini mendeteksi normal speed per-record/per-map otomatis,
--// lalu menstabilkan frame Running/Landed saja. Angka 51 tidak di-hardcode.
--// =========================================================
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
    local mixedValues = {}

    for _, fr in ipairs(frames or {}) do
        if autoMapIsGroundRunFrame(fr) then
            local ws = tonumber(fr.walkSpeed) or tonumber(fr.ws) or 0
            local hs = autoMapHorizontalCitySpeed(fr)
            local md = autoMapMoveMagnitude(fr)

            if md >= (AUTO_MAP_SPEED_MIN_MOVEDIR or 0.045) or hs >= MIN_PLAYBACK_SPEED then
                if ws >= MIN_PLAYBACK_SPEED then
                    table.insert(wsValues, ws)
                    table.insert(mixedValues, ws)
                end

                if hs >= MIN_PLAYBACK_SPEED then
                    table.insert(hValues, hs)
                    table.insert(mixedValues, hs)
                end
            end
        end
    end

    local minSamples = tonumber(AUTO_MAP_SPEED_MIN_SAMPLES) or 6
    local wsBase = nil
    local hBase = nil

    if #wsValues >= minSamples then
        -- WalkSpeed biasanya paling akurat kalau coil/map memang mengubah Humanoid.WalkSpeed.
        local wsMedian = autoMapPercentile(wsValues, 0.50)
        local wsHigh = autoMapPercentile(wsValues, 0.75)
        if wsMedian and wsHigh then
            wsBase = math.max(wsMedian, wsHigh)
        end
    end

    if #hValues >= minSamples then
        -- Kalau WalkSpeed tetap 16 tetapi velocity/city map 50+, ambil speed normal dari momentum.
        local q50 = autoMapPercentile(hValues, 0.50) or 0
        local q90 = autoMapPercentile(hValues, 0.90) or q50

        -- Buang spike ekstrem supaya bling 200/300 tidak dianggap normal map.
        local filtered = {}
        local cap = math.max(MIN_PLAYBACK_SPEED, q90 * 1.08)
        for _, v in ipairs(hValues) do
            v = tonumber(v) or 0
            if v >= MIN_PLAYBACK_SPEED and v <= cap then
                table.insert(filtered, v)
            end
        end

        if #filtered >= math.max(3, math.floor(minSamples * 0.5)) then
            hBase = autoMapAverageMiddle(filtered, 0.58, 0.88) or autoMapPercentile(filtered, 0.75)
        else
            hBase = autoMapPercentile(hValues, 0.70)
        end
    end

    local base = nil
    if wsBase and hBase then
        -- Ambil yang lebih besar karena user ingin speed turun saat belok/mundur dihilangkan.
        base = math.max(wsBase, hBase)
    else
        base = wsBase or hBase
    end

    if not base and #mixedValues > 0 then
        base = autoMapPercentile(mixedValues, 0.75)
    end

    if not base or base < MIN_PLAYBACK_SPEED then
        base = parseSpeedValue(syncBaseSpeed or currentPlaybackSpeed or DEFAULT_PLAYBACK_SPEED, DEFAULT_PLAYBACK_SPEED)
    end

    return math.clamp(roundNumber(base, 2), MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)
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
    if not AUTO_MAP_CLEAN_SPEED_MODE or not AUTO_MAP_LOCK_RUN_SPEED then
        return frames, 0, normalSpeed
    end

    frames = basicNormalizeFrames(frames) or frames or {}
    if type(frames) ~= "table" or #frames <= 0 then
        return frames, 0, normalSpeed
    end

    normalSpeed = tonumber(normalSpeed) or autoMapDetectNormalRunSpeed(frames)
    normalSpeed = math.clamp(tonumber(normalSpeed) or DEFAULT_PLAYBACK_SPEED, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)

    local changed = 0
    local dropLimit = normalSpeed * (tonumber(AUTO_MAP_SPEED_DROP_TOLERANCE) or 0.94)
    local spikeLimit = normalSpeed * (tonumber(AUTO_MAP_SPEED_SPIKE_CAP_MULT) or 1.10)

    for i, fr in ipairs(frames) do
        if autoMapIsGroundRunFrame(fr) then
            local md = autoMapMoveMagnitude(fr)
            local hs = autoMapHorizontalCitySpeed(fr)
            local isMoving = md >= (AUTO_MAP_SPEED_MIN_MOVEDIR or 0.045) or hs >= (MIN_PLAYBACK_SPEED * 0.45)

            if isMoving then
                local needFix = false

                -- Hilangkan speed pelan saat belok/mundur.
                if hs <= 0.05 or hs < dropLimit then
                    needFix = true
                end

                -- Hilangkan spike/blink terlalu cepat juga.
                if hs > spikeLimit then
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

                -- WalkSpeed JSON juga dikunci ke speed normal map, bukan turun saat belok/mundur.
                local ws = tonumber(fr.walkSpeed) or tonumber(fr.ws) or 0
                if ws < dropLimit or ws > spikeLimit then
                    fr.walkSpeed = roundNumber(normalSpeed, 9)
                    fr.ws = fr.walkSpeed
                else
                    fr.walkSpeed = roundNumber(math.max(ws, normalSpeed), 9)
                    fr.ws = fr.walkSpeed
                end
            end
        end
    end

    return frames, changed, normalSpeed
end

function autoMapRetuneRunTimes(frames, normalSpeed)
    if not AUTO_MAP_SPEED_USE_TIMING_FIX then
        return frames
    end

    frames = frames or {}
    if #frames <= 1 then
        return frames
    end

    normalSpeed = tonumber(normalSpeed) or autoMapDetectNormalRunSpeed(frames)
    normalSpeed = math.max(tonumber(normalSpeed) or DEFAULT_PLAYBACK_SPEED, MIN_PLAYBACK_SPEED)

    local out = {}
    local currentTime = 0

    for i, fr in ipairs(frames) do
        local copy = deepCopy(fr)

        if i == 1 then
            currentTime = 0
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

                if hd > 0.01 and md >= (AUTO_MAP_SPEED_MIN_MOVEDIR or 0.045) then
                    local bySpeed = hd / normalSpeed
                    local speedCap = normalSpeed * (tonumber(AUTO_MAP_SPEED_SPIKE_CAP_MULT) or 1.10)
                    local minSafeDt = hd / math.max(speedCap, 1)

                    -- PATCH MERGE SPEED 2026-05-13:
                    -- Sebelumnya fungsi ini hanya mengompres timing yang terlalu lambat.
                    -- Kalau hasil merge punya dt terlalu kecil, replay membaca jarak antar-frame
                    -- sebagai speed super cepat sepersekian detik. Sekarang dt juga dinaikkan
                    -- sampai aman terhadap speed normal map/coil.
                    if dt <= 0 then
                        dt = bySpeed
                    elseif dt < minSafeDt then
                        dt = minSafeDt
                    elseif dt > (bySpeed * 1.18) then
                        dt = bySpeed
                    end
                end
            end

            if dt <= 0 then
                dt = tonumber(RAW_EXACT_MIN_DT) or 0.001
            end

            local minDt = tonumber(AUTO_MAP_SPEED_MIN_DT) or 0.0065
            local maxDt = tonumber(AUTO_MAP_SPEED_MAX_DT) or 0.140
            dt = math.max(dt, minDt)
            dt = math.min(dt, maxDt)
            currentTime = currentTime + dt
        end

        copy.times = roundNumber(currentTime, 9)
        copy.t = copy.times
        table.insert(out, copy)
    end

    return out
end

function autoMapCleanSpeedForSave(frames)
    if not AUTO_MAP_CLEAN_SPEED_MODE then
        return frames, 0, nil
    end

    local normal = autoMapDetectNormalRunSpeed(frames)
    local changed = 0
    frames, changed, normal = autoMapApplyNormalRunSpeed(frames, normal)
    frames = autoMapRetuneRunTimes(frames, normal)
    frames, changed = autoMapApplyNormalRunSpeed(frames, normal)
    return frames, changed or 0, normal
end

-- Fungsi baru untuk membuat 1 frame dalam format ONIUM Race.
-- Fungsi ini dibuat agar outputnya PERSIS seperti di file contoh Anda.
function exportFrameForOniumRace(fr)
    fr = fr or {}

    local pos = tableToVec(fr.position)
    local yaw = tonumber(fr.rotation) or 0
    local moveDir = tableToVec(fr.moveDirection)
    local cityVec = tableToVec(fr.city)
    local stateText = tostring(fr.states or fr.state or "Running")
    local ws
    if EXPORT_RAW_EXACT_MODE and RAW_EXACT_KEEP_WALKSPEED then
        -- Jangan timpa speed asli coil/map saat export upload.
        ws = tonumber(fr.walkSpeed)
            or tonumber(fr.ws)
            or DEFAULT_PLAYBACK_SPEED
    else
        ws = tonumber(fr.__bitwiseBaseSpeed)
            or tonumber(fr.walkSpeed)
            or tonumber(fr.ws)
            or DEFAULT_PLAYBACK_SPEED
    end
    local hip = tonumber(fr.hipHeight) or BITWISE_JSON_HIPHEIGHT

    -- RAW: jump ditentukan dari data asli record, tetapi frame grounded tidak boleh
    -- ikut kebawa sebagai jump palsu saat lari di gundukan/jalan tidak rata.
    local groundedExport = mobileDeltaFrameHasGroundContact(fr)
    local jumpFlag = (not groundedExport) and (fr.jump == true or stateText == "Jumping")

    if groundedExport and (stateText == "Jumping" or stateText == "Freefall" or stateText == "FallingDown") then
        stateText = "Running"
    elseif stateText == "FallingDown" then
        stateText = "Freefall"
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

        walkSpeed = roundNumber(ws, 9),

        tool = tostring(fr.tool or ""),

        states = stateText
    }
end

-- Fungsi utama untuk membangun payload yang akan disimpan ke JSON.
function buildOniumRacePayload(name, frames)
    local exportFrames = {}
    local timedFrames = retimeFramesForExport(frames or {})

    local bitwiseBaseSpeed = nil
    if not EXPORT_RAW_EXACT_MODE then
        bitwiseBaseSpeed = detectBitwiseBaseSpeed(timedFrames)
    end

    for i, fr in ipairs(timedFrames) do
        local copy = deepCopy(fr)

        -- RAW EXACT: jangan jadikan semua frame 1 base speed hasil deteksi.
        -- Biarkan walkSpeed asli per frame dari record yang dipakai.
        if not EXPORT_RAW_EXACT_MODE then
            copy.__bitwiseBaseSpeed = bitwiseBaseSpeed
        else
            copy.__bitwiseBaseSpeed = nil
        end

        exportFrames[i] = exportFrameForOniumRace(copy)

        if i % 5000 == 0 then
            task.wait()
        end
    end

    return exportFrames
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
        .. ',"walkSpeed":' .. oniumJsonNumberFast(fr.walkSpeed)
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
        return listfiles(FOLDER_NAME)
    end)

    if ok and type(files) == "table" then
        return files
    end

    return nil
end

--// =========================================================
--// JSON Frame Normalizer + Cleaner
--// =========================================================

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
                local timeValue = tonumber(fr.times) or tonumber(fr.t) or tonumber(fr.time) or tonumber(fr.timestamp) or 0
                local raceSpeed = tonumber(fr.ws) or tonumber(fr.walkSpeed) or DEFAULT_PLAYBACK_SPEED
                local stateText = tostring(fr.states or fr.state or "Running")

                local newFrame = {
                    jump = fr.jump == true or fr.jumping == true,
                    noShiftLock = fr.noShiftLock == true or fr.rotationMode == "AutoRotate",
                    rotationMode = tostring(fr.rotationMode or ((fr.noShiftLock == true) and "AutoRotate" or "ShiftLock")),
                    mobileRecord = fr.mobileRecord == true or fr.isMobileRecord == true or tostring(fr.inputDevice or "") == "MobileDelta",
                    inputDevice = tostring(fr.inputDevice or (fr.mobileRecord == true and "MobileDelta" or "")),
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
                    times = timeValue,
                    t = timeValue,
                    walkSpeed = raceSpeed,
                    ws = raceSpeed,
                    v = tonumber(fr.v) or nil,
                    tool = tostring(fr.tool or ""),
                    states = stateText,
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

    return hd >= CLEAN_DISTANCE_THRESHOLD or vd >= CLEAN_VERTICAL_THRESHOLD
end

-- =========================================================
-- Fungsi deteksi perubahan rotasi (untuk spinning jump)
-- =========================================================
function hasRotationChange(a, b)
    if not a or not b then 
        return false 
    end
    
    local rotA = tonumber(a.rotation) or 0
    local rotB = tonumber(b.rotation) or 0
    local diff = math.abs(rotA - rotB)
    
    -- Normalisasi selisih sudut (wrap around 0-2pi)
    diff = math.min(diff, 2 * math.pi - diff)
    
    return diff > 0.12  -- sekitar 7 derajat
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
    
    -- CEK PERUBAHAN ROTASI (PENTING UNTUK SPINNING JUMP!)
    if hasRotationChange(prev, fr) or hasRotationChange(fr, nextF) then
        return true
    end

    if isAirState(fr.states) then
        local stateName = tostring(fr.states)
        
        -- Jumping/Freefall/FallingDown jangan dibuang
        if stateName == "Jumping" or stateName == "Freefall" or stateName == "FallingDown" then
            return true
        end
        
        if stateName == "Climbing" or stateName == "Swimming" then
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
            local keep = fr.seam == true or fr.cutNext == true or frameMovedEnough(lastKept, fr) or fr.jump == true or isAirState(fr.states)

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
            fr.times = roundNumber((i - 1) * SAMPLE_INTERVAL, 4)
            fr.t = fr.times
        end
    end

    return final
end

function findCheckpointByName(name)
    name = tostring(name or "")

    for _, cp in ipairs(checkpoints) do
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

    -- RAW: masuk list tanpa sanitize/retime, supaya speed momentum dan rotasi tidak berubah.
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
        local numericOrder = parseCheckpointNumber(name)
        local orderValue = numericOrder or nextOrder

        table.insert(checkpoints, {
            name = name,
            frames = deepCopy(frames),
            isMerged = isMerged == true,
            path = path or filePathForName(name),
            order = orderValue
        })

        if orderValue >= nextOrder then
            nextOrder = orderValue + 1
        else
            nextOrder = nextOrder + 1
        end
    end

    if refreshList then
        refreshList()
    end

    return true
end

--// =========================================================
--// UI Helper
--// =========================================================

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
    local dragStart
    local startPos

    handle = handle or frame

    addConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
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

        local delta = input.Position - dragStart

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

--// =========================================================
--// Build UI
--// =========================================================

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ONIUM Recorder"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)

local parentOk = pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not parentOk or not ScreenGui.Parent then
    ScreenGui.Parent = PlayerGui
end

MainFrame = Instance.new("Frame")
MainFrame.Name = "MainWindow"
MainFrame.Size = UDim2.fromOffset(410, 250)
MainFrame.Position = UDim2.new(0.5, -205, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 14)
addStroke(MainFrame, Color3.fromRGB(105, 105, 150), 0.25)

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
Header.Parent = MainFrame
addCorner(Header, 14)

local LogoHolder = Instance.new("Frame")
LogoHolder.BackgroundColor3 = Color3.fromRGB(36, 36, 52)
LogoHolder.Size = UDim2.fromOffset(20, 20)
LogoHolder.Position = UDim2.fromOffset(6, 5)
LogoHolder.Parent = Header
addCorner(LogoHolder, 10)
addStroke(LogoHolder, Color3.fromRGB(110, 110, 160), 0.25)

local Logo = Instance.new("ImageLabel")
Logo.Name = "HeaderLogo"
Logo.BackgroundTransparency = 1
Logo.Image = CUSTOM_LOGO_ASSET
Logo.ScaleType = Enum.ScaleType.Fit
Logo.Size = UDim2.new(1, -4, 1, -4)
Logo.Position = UDim2.fromOffset(2, 2)
Logo.Parent = LogoHolder

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

makeDraggable(MainFrame, Header)

local Body = Instance.new("Frame")
Body.BackgroundTransparency = 1
Body.Size = UDim2.new(1, -10, 1, -38)
Body.Position = UDim2.fromOffset(5, 35)
Body.Parent = MainFrame

local LeftPanel = Instance.new("Frame")
LeftPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
LeftPanel.Size = UDim2.new(0, 138, 1, 0)
LeftPanel.Parent = Body
addCorner(LeftPanel, 12)
addStroke(LeftPanel, Color3.fromRGB(70, 70, 95), 0.45)

local LeftPad = Instance.new("UIPadding")
LeftPad.PaddingTop = UDim.new(0, 4)
LeftPad.PaddingBottom = UDim.new(0, 4)
LeftPad.PaddingLeft = UDim.new(0, 4)
LeftPad.PaddingRight = UDim.new(0, 4)
LeftPad.Parent = LeftPanel

local LeftList = Instance.new("UIListLayout")
LeftList.SortOrder = Enum.SortOrder.LayoutOrder
LeftList.Padding = UDim.new(0, 3)
LeftList.Parent = LeftPanel

addSection(LeftPanel, "CONTROLS")
local RecordBtn = makeButton(LeftPanel, "● RECORD", Color3.fromRGB(180, 55, 70))
local SetSpeedBtn = makeButton(LeftPanel, "SET SPEED", Color3.fromRGB(60, 65, 95))

addSection(LeftPanel, "PLAYBACK")
speedBox = makeTextBox(LeftPanel, "AUTO / isi speed", "AUTO")
local StopPlayBtn = makeButton(LeftPanel, "STOP PLAY", Color3.fromRGB(155, 60, 65))

addSection(LeftPanel, "SAVE")
saveNameBox = makeTextBox(LeftPanel, "name", "")
local SaveBtn = makeButton(LeftPanel, "SAVE", Color3.fromRGB(55, 110, 75))

local RightPanel = Instance.new("Frame")
RightPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
RightPanel.Size = UDim2.new(1, -144, 1, 0)
RightPanel.Position = UDim2.fromOffset(144, 0)
RightPanel.Parent = Body
addCorner(RightPanel, 12)
addStroke(RightPanel, Color3.fromRGB(70, 70, 95), 0.45)

local RightPad = Instance.new("UIPadding")
RightPad.PaddingTop = UDim.new(0, 4)
RightPad.PaddingBottom = UDim.new(0, 4)
RightPad.PaddingLeft = UDim.new(0, 4)
RightPad.PaddingRight = UDim.new(0, 4)
RightPad.Parent = RightPanel

local RightTitle = makeLabel(RightPanel, "FOLDER", 12, true)
RightTitle.TextColor3 = Color3.fromRGB(160, 170, 255)
RightTitle.Size = UDim2.new(1, 0, 0, 14)
RightTitle.Position = UDim2.fromOffset(0, 0)

local TopButtons = Instance.new("Frame")
TopButtons.BackgroundTransparency = 1
TopButtons.Size = UDim2.new(1, 0, 0, 20)
TopButtons.Position = UDim2.fromOffset(0, 16)
TopButtons.Parent = RightPanel

local TopLayout = Instance.new("UIListLayout")
TopLayout.FillDirection = Enum.FillDirection.Horizontal
TopLayout.SortOrder = Enum.SortOrder.LayoutOrder
TopLayout.Padding = UDim.new(0, 3)
TopLayout.Parent = TopButtons

local DeleteAllBtn = makeButton(TopButtons, "Del All", Color3.fromRGB(145, 55, 60))
DeleteAllBtn.Size = UDim2.new(0.2, -4, 1, 0)

local ImportBtn = makeButton(TopButtons, "Load", Color3.fromRGB(55, 80, 130))
ImportBtn.Size = UDim2.new(0.2, -4, 1, 0)

local RefreshBtn = makeButton(TopButtons, "Refresh", Color3.fromRGB(55, 95, 105))
RefreshBtn.Size = UDim2.new(0.2, -4, 1, 0)

local MergeBtn = makeButton(TopButtons, "Merge", Color3.fromRGB(95, 70, 150))
MergeBtn.Size = UDim2.new(0.2, -4, 1, 0)

cpMarkerToggleBtn = makeButton(TopButtons, "CP OFF", Color3.fromRGB(55, 55, 70))
cpMarkerToggleBtn.Size = UDim2.new(0.2, -4, 1, 0)
updateCpMarkerToggleButton()

searchBox = makeTextBox(RightPanel, "Search checkpoint...", "")
searchBox.Size = UDim2.new(1, 0, 0, 20)
searchBox.Position = UDim2.fromOffset(0, 40)

listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "CheckpointList"
listFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
listFrame.Size = UDim2.new(1, 0, 1, -64)
listFrame.Position = UDim2.fromOffset(0, 62)
listFrame.ScrollBarThickness = 4
listFrame.CanvasSize = UDim2.fromOffset(0, 0)
listFrame.Parent = RightPanel
addCorner(listFrame, 10)
addStroke(listFrame, Color3.fromRGB(65, 65, 90), 0.55)

local ListPad = Instance.new("UIPadding")
ListPad.PaddingTop = UDim.new(0, 4)
ListPad.PaddingBottom = UDim.new(0, 4)
ListPad.PaddingLeft = UDim.new(0, 4)
ListPad.PaddingRight = UDim.new(0, 4)
ListPad.Parent = listFrame

listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = listFrame

addConnection(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    listFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 14)
end))

ToastLabel = Instance.new("TextLabel")
ToastLabel.Visible = false
ToastLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
ToastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ToastLabel.Font = Enum.Font.GothamBold
ToastLabel.TextSize = 9
ToastLabel.Size = UDim2.new(1, -10, 0, 18)
ToastLabel.Position = UDim2.new(0, 5, 1, -21)
ToastLabel.Parent = MainFrame
addCorner(ToastLabel, 8)
addStroke(ToastLabel, Color3.fromRGB(90, 90, 130), 0.35)

MiniLogo = Instance.new("ImageButton")
MiniLogo.Name = "MiniLogo"
MiniLogo.Visible = false
MiniLogo.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
MiniLogo.Image = CUSTOM_LOGO_ASSET
MiniLogo.ScaleType = Enum.ScaleType.Fit
MiniLogo.Size = UDim2.fromOffset(38, 38)
MiniLogo.Position = UDim2.fromOffset(25, 170)
MiniLogo.Parent = ScreenGui
addCorner(MiniLogo, 19)
addStroke(MiniLogo, Color3.fromRGB(135, 135, 190), 0.2)
makeDraggable(MiniLogo, MiniLogo)

RecordOverlay = Instance.new("Frame")
RecordOverlay.Visible = false
RecordOverlay.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
RecordOverlay.Size = UDim2.fromOffset(154, 50)
RecordOverlay.Position = UDim2.new(0.5, -77, 0.12, 0)
RecordOverlay.Parent = ScreenGui
addCorner(RecordOverlay, 8)
addStroke(RecordOverlay, Color3.fromRGB(200, 65, 80), 0.15)

local OverlayHeader = Instance.new("Frame")
OverlayHeader.BackgroundColor3 = Color3.fromRGB(130, 35, 50)
OverlayHeader.Size = UDim2.new(1, 0, 0, 16)
OverlayHeader.Parent = RecordOverlay
addCorner(OverlayHeader, 8)
makeDraggable(RecordOverlay, OverlayHeader)

overlayStatusLabel = Instance.new("TextLabel")
overlayStatusLabel.BackgroundTransparency = 1
overlayStatusLabel.Text = "● REC"
overlayStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
overlayStatusLabel.Font = Enum.Font.GothamBold
overlayStatusLabel.TextSize = 9
overlayStatusLabel.Size = UDim2.new(1, -12, 1, 0)
overlayStatusLabel.Position = UDim2.fromOffset(6, 0)
overlayStatusLabel.Parent = OverlayHeader

timerLabel = makeLabel(RecordOverlay, "Timer: 00:00.00", 13, true)
timerLabel.Size = UDim2.new(1, -20, 0, 0)
timerLabel.Position = UDim2.fromOffset(10, 30)
timerLabel.Visible = false

frameCountLabel = makeLabel(RecordOverlay, "Frames: 0", 12, false)
frameCountLabel.Size = UDim2.new(1, -20, 0, 0)
frameCountLabel.Position = UDim2.fromOffset(10, 30)
frameCountLabel.Visible = false

local OverlayButtons = Instance.new("Frame")
OverlayButtons.BackgroundTransparency = 1
OverlayButtons.Size = UDim2.new(1, -10, 0, 22)
OverlayButtons.Position = UDim2.fromOffset(5, 23)
OverlayButtons.Parent = RecordOverlay

local OverlayLayout = Instance.new("UIListLayout")
OverlayLayout.FillDirection = Enum.FillDirection.Horizontal
OverlayLayout.Padding = UDim.new(0, 4)
OverlayLayout.Parent = OverlayButtons

local StopBtn = makeButton(OverlayButtons, "STOP", Color3.fromRGB(180, 55, 70))
StopBtn.Size = UDim2.new(0.5, -2, 1, 0)

local RollbackBtn = makeButton(OverlayButtons, "ROLL", Color3.fromRGB(80, 95, 170))
RollbackBtn.Size = UDim2.new(0.5, -2, 1, 0)

--// =========================================================
--// Light record runtime cache
--// =========================================================
local lastRecordFrameTime = -999
local lastOverlayUpdateClock = 0
local lastRecordGroundTime = -999
local lastRecordGroundInfo = nil
local lastRecordToolTime = -999
local lastRecordToolName = ""

function recordIsAirStateText(stateName)
    stateName = tostring(stateName or "")
    return stateName == "Jumping"
        or stateName == "Freefall"
        or stateName == "FallingDown"
end

function getRecordToolNameFast(char)
    if not RECORD_LIGHT_MODE then
        return getEquippedToolName(char)
    end

    local now = os.clock()
    if now - lastRecordToolTime >= RECORD_TOOL_CACHE_INTERVAL then
        lastRecordToolName = getEquippedToolName(char)
        lastRecordToolTime = now
    end

    return lastRecordToolName or ""
end

function getRecordGroundInfoFast(hrp, timeValue, stateName)
    if not RECORD_LIGHT_MODE then
        return getGroundInfo(hrp)
    end

    local t = tonumber(timeValue) or os.clock()
    local st = tostring(stateName or "")
    local air = recordIsAirStateText(st)

    -- Ground raycast itu yang paling berat saat record.
    -- Saat di udara, pakai cache sebentar saja; saat running/landed refresh berkala.
    if (not air) and (not lastRecordGroundInfo or (t - lastRecordGroundTime) >= RECORD_GROUND_CACHE_INTERVAL) then
        lastRecordGroundInfo = getGroundInfo(hrp)
        lastRecordGroundTime = t
    end

    if air then
        -- Jangan raycast tiap frame udara. Untuk rollback masih cukup karena frame sebelum lompat punya ground.
        if (t - lastRecordGroundTime) <= 0.14 then
            return lastRecordGroundInfo
        end
        return nil
    end

    return lastRecordGroundInfo
end

--// =========================================================
--// Recording
--// =========================================================

function getRecordDuration()
    if #recordFrames <= 0 then
        return 0
    end

    return tonumber(recordFrames[#recordFrames].times) or 0
end

function updateOverlay(actualDuration, force)
    local now = os.clock()

    if RECORD_LIGHT_MODE and isRecording and not force then
        if now - lastOverlayUpdateClock < RECORD_UI_UPDATE_INTERVAL then
            return
        end
    end

    lastOverlayUpdateClock = now

    if timerLabel then
        timerLabel.Text = "Timer: " .. formatTime(actualDuration or getRecordDuration())
    end

    if frameCountLabel then
        frameCountLabel.Text = "Frames: " .. tostring(#recordFrames)
    end
end

function makeFrame(timeValue, hum, hrp)
    local pos = hrp.Position
    local vel = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection

    local _, yaw, _ = hrp.CFrame:ToOrientation()
    local stateName = getHumanoidStateName(hum)
    local horizontalSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local realWalkSpeed = tonumber(hum.WalkSpeed) or DEFAULT_PLAYBACK_SPEED
    local mobileRecord = isMobileTouchDeviceSafe()

    -- Simpan mode record untuk playback internal, tapi field ini tidak ikut JSON export.
    local noShiftLock = detectNoShiftLockRecord(hum, hrp)
    local rotationMode = noShiftLock and "AutoRotate" or "ShiftLock"

    -- RAW state: Delta support tetap ada, tapi tidak lagi memaksa Jumping/Freefall
    -- hanya dari velocity Y saat avatar masih menapak di gundukan/jalan tidak rata.
    local rawStateName = stateName
    local floorMaterialName = getHumanoidFloorMaterialNameSafe(hum)
    local groundedNow = isGroundFloorMaterialName(floorMaterialName)
    local jumpFlag = false
    local yVel = tonumber(vel.Y) or 0

    if stateName == "Climbing" or stateName == "Swimming" then
        jumpFlag = false
    elseif groundedNow then
        -- FIX UTAMA: selama masih ada floor, lari di kontur naik/turun tetap Running.
        -- Ini mencegah gundukan terbaca terjun hanya karena velocity Y turun/naik.
        if stateName == "Jumping" or stateName == "Freefall" or stateName == "FallingDown" then
            stateName = "Running"
        end
        jumpFlag = false
    elseif stateName == "Jumping" or stateName == "Freefall" or stateName == "FallingDown" then
        if yVel > 4 then
            stateName = "Jumping"
            jumpFlag = true
        else
            stateName = "Freefall"
            jumpFlag = false
        end
    elseif mobileRecord and (not groundedNow) and yVel >= (MOBILE_DELTA_JUMP_Y_TRIGGER or 7.5) then
        -- Khusus Delta: state kadang telat, tapi hanya boleh dipromote kalau benar-benar airborne.
        stateName = "Jumping"
        jumpFlag = true
    elseif mobileRecord and (not groundedNow) and yVel <= (MOBILE_DELTA_FALL_Y_TRIGGER or -5.5) then
        stateName = "Freefall"
        jumpFlag = false
    elseif stateName == "FallingDown" then
        stateName = "Freefall"
        jumpFlag = false
    end

    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = hrp.CFrame:GetComponents()

    return {
        jump = jumpFlag == true,
        noShiftLock = noShiftLock,
        rotationMode = rotationMode,
        mobileRecord = mobileRecord == true,
        inputDevice = mobileRecord and "MobileDelta" or "PC",
        executorDevice = mobileRecord and "DeltaAndroid" or "Desktop",
        grounded = groundedNow == true,
        floorMaterial = floorMaterialName,
        rawState = rawStateName,
        hipHeight = roundNumber(tonumber(hum.HipHeight) or BITWISE_JSON_HIPHEIGHT, 9),
        rotation = roundNumber(yaw, 9),
        moveDirection = vecToTable(moveDir),
        city = vecToTable(vel),
        position = vecToTable(pos),
        times = roundNumber(timeValue, 9),
        walkSpeed = roundNumber(realWalkSpeed, 9),
        tool = getRecordToolNameFast(LocalPlayer.Character),
        states = stateName,
        ground = getRecordGroundInfoFast(hrp, timeValue, stateName),
        t = roundNumber(timeValue, 9),
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
        v = roundNumber(horizontalSpeed, 9),
        ws = roundNumber(realWalkSpeed, 9)
    }
end

-- TAMBAHKAN VARIABLE GLOBAL (di bagian Config, baris sekitar 50)
local MIN_ROTATION_RECORD = 0.1  -- radian (~5.7 derajat)
local lastRecordRotation = nil   -- simpan rotasi terakhir

-- UBAH FUNGSI isRealMovement
function isRealMovement(hum, hrp, lastSavedPos)
    local pos = hrp.Position
    local vel = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection
    local stateName = getHumanoidStateName(hum)

    local hd = horizontalDistance(pos, lastSavedPos)
    local vd = math.abs(pos.Y - lastSavedPos.Y)
    local hv = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local vv = math.abs(vel.Y)

    -- CEK PERUBAHAN ROTASI
    local _, currentYaw, _ = hrp.CFrame:ToOrientation()
    local rotChanged = false
    if lastRecordRotation then
        local diff = math.abs(currentYaw - lastRecordRotation)
        diff = math.min(diff, 2 * math.pi - diff)
        rotChanged = diff > MIN_ROTATION_RECORD
    end
    lastRecordRotation = currentYaw

    local positionMoved = hd >= MIN_RECORD_DISTANCE or vd >= 0.03
    local walking = moveDir.Magnitude >= MIN_MOVE_DIRECTION and positionMoved
    local physicsMove = hv >= MIN_HORIZONTAL_VELOCITY and positionMoved

    -- WAJIB REKAM GERAKAN KHUSUS AVATAR
    local specialState =
        stateName == "Jumping"
        or stateName == "Freefall"
        or stateName == "FallingDown"
        or stateName == "Climbing"
        or stateName == "Swimming"

    -- Climbing / Swimming kadang horizontal kecil, tapi Y/velocity berubah
    local specialMove = specialState and (
        positionMoved
        or vv >= 0.15
        or moveDir.Magnitude >= 0.01
    )

    -- KALAU ROTASI BERUBAH SIGNIFIKAN, REKAM!
    return walking or physicsMove or specialMove or rotChanged
end

startRecording = function()
    if isRecording then
        notify("Record", "Recording sudah berjalan", 2)
        return
    end

    local char, hum, hrp = getCharacter()
    if not char or not hum or not hrp then
        notify("Record", "Character belum siap / belum spawn", 3)
        return
    end

    -- Mouse lock must not remain active while recording or rollback is active.
    forceShiftLockOff()

    --// =====================================================
    --// MOBILE / PC SAFE START
    --// Reset state Humanoid biar tidak ada bug "kum tinggi"
    --// saat user pencet REC sambil ShiftLock di HP, atau saat
    --// user save lalu record lagi dengan state lama menumpuk.
    --// =====================================================
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

    preRecordWalkSpeed = tonumber(hum.WalkSpeed) or preRecordWalkSpeed
    lastKnownToolWalkSpeed = preRecordWalkSpeed
    lastKnownEquippedTool = getEquippedToolName(char)

    local liveBaseSpeed = tonumber(hum.WalkSpeed) or DEFAULT_PLAYBACK_SPEED
    currentPlaybackSpeed = liveBaseSpeed
    syncBaseSpeed = liveBaseSpeed

    if speedBox then
        speedBox.Text = tostring(roundNumber(liveBaseSpeed, 3))
    end

    playToken = playToken + 1
    isPlaying = false
    isRecording = true
    isRollbacking = false
    rollbackCancel = false
    rollbackToken = rollbackToken + 1

    recordFrames = {}
    temporaryRecord = {}

    MainFrame.Visible = false
    MiniLogo.Visible = false
    RecordOverlay.Visible = true

    overlayStatusLabel.Text = "● REC LIVE"
    timerLabel.Text = "Timer: 00:00.00"
    frameCountLabel.Text = "Frames: 0"

    recordStartClock = os.clock()
    lastRecordSavedPos = hrp.Position
    lastRecordRotation = nil
    lastRecordFrameTime = -999
    lastOverlayUpdateClock = 0
    lastRecordGroundTime = -999
    lastRecordGroundInfo = nil
    lastRecordToolTime = -999
    lastRecordToolName = getEquippedToolName(char)

    --// Tracking untuk live-skip idle / kedut
    local lastState = getHumanoidStateName(hum)
    local lastWalkSpeed = liveBaseSpeed
    local lastToolName = lastRecordToolName or ""
    local recStartClockLocal = recordStartClock

    --// Jump suppression window (anti tap-thru REC button di HP)
    local suppressJumpUntil = os.clock() + 0.35
    local jumpGuardConn
    jumpGuardConn = addConnection(RunService.Heartbeat:Connect(function()
        if not isRecording or os.clock() >= suppressJumpUntil then
            if jumpGuardConn then jumpGuardConn:Disconnect() jumpGuardConn = nil end
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

    if recordConnection then
        recordConnection:Disconnect()
        recordConnection = nil
    end

    recordConnection = RunService.Heartbeat:Connect(function(dt)
        if not isRecording then return end
        if isRollbacking then return end

        local currentChar = LocalPlayer.Character
        if not currentChar then return end

        local currentHum = currentChar:FindFirstChildOfClass("Humanoid")
        local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
        if not currentHum or not currentHrp then return end

        local liveWalkSpeed = tonumber(currentHum.WalkSpeed) or 0
        if liveWalkSpeed > 0 then
            local equippedNow = getRecordToolNameFast(currentChar)
            if equippedNow ~= "" then
                lastKnownEquippedTool = equippedNow
                lastKnownToolWalkSpeed = math.max(tonumber(lastKnownToolWalkSpeed) or 0, liveWalkSpeed)
            elseif not lastKnownToolWalkSpeed then
                lastKnownToolWalkSpeed = liveWalkSpeed
            end
        end

        local actualDuration = os.clock() - recStartClockLocal

        --// =================================================
        --// LIVE SAMPLING - hemat frame, simpan event penting
        --// =================================================
        local stNow = getHumanoidStateName(currentHum)
        local toolNow = getRecordToolNameFast(currentChar) or ""
        local wsNow = liveWalkSpeed
        local floorNow = getHumanoidFloorMaterialNameSafe(currentHum)
        local groundedNow = isGroundFloorMaterialName(floorNow)
        local isAir = recordIsAirStateText(stNow) and not groundedNow

        --// Trigger "wajib rekam" (event-driven, tidak tergantung interval)
        local stateChanged = (stNow ~= lastState)
        local toolChanged = (toolNow ~= lastToolName)
        local speedChanged = math.abs(wsNow - lastWalkSpeed) >= 0.5
        local importantEvent = stateChanged or toolChanged or speedChanged

        --// Sample interval adaptif: di udara/lompat lebih rapat
        local sampleDt = isAir and RECORD_AIR_SAMPLE_DT or RECORD_MIN_SAMPLE_DT
        local sinceLast = actualDuration - lastRecordFrameTime

        if not importantEvent and sinceLast < sampleDt then
            updateOverlay(actualDuration, false)
            return
        end

        --// Skip idle/kedut: kalau bukan event penting & tidak ada gerakan asli, skip
        if not importantEvent and not isAir then
            local moving = isRealMovement(currentHum, currentHrp, lastRecordSavedPos)
            if not moving then
                --// Tetap simpan 1 keyframe "diam" tiap 0.5s biar timeline sinkron
                if (actualDuration - lastRecordFrameTime) < 0.5 then
                    updateOverlay(actualDuration, false)
                    return
                end
            end
        end

        local fr = makeFrame(actualDuration, currentHum, currentHrp)
        table.insert(recordFrames, fr)

        lastRecordFrameTime = actualDuration
        lastRecordSavedPos = currentHrp.Position
        lastState = stNow
        lastWalkSpeed = wsNow
        lastToolName = toolNow

        updateOverlay(actualDuration, false)
    end)

    notify("Record", "LIVE record aktif: Delta no false jump gundukan + anti speed spike.", 3)
end

stopRecording = function()
    rollbackCancel = true
    rollbackToken = rollbackToken + 1
    isRollbacking = false

    if RollbackBtn then
        RollbackBtn.Text = "ROLL"
        RollbackBtn.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
    end

    if not isRecording then
        RecordOverlay.Visible = false
        MainFrame.Visible = true
        restoreCharacterControl()
        restoreMouseLockState()
        return
    end

    isRecording = false

    if recordConnection then
        recordConnection:Disconnect()
        recordConnection = nil
    end

    -- RAW: jangan sanitize/retime saat stop, supaya data asli tidak berubah.
    temporaryRecord = deepCopy(recordFrames) or {}

    RecordOverlay.Visible = false
    MainFrame.Visible = true

    restoreCharacterControl()
    restoreMouseLockState()

    if #temporaryRecord > 0 then
        if saveNameBox and trimText(saveNameBox.Text) == "" then
            saveNameBox.Text = getNextDefaultName()
        end

        notify("Stop", "Record selesai. Frame bersih: " .. tostring(#temporaryRecord), 3)
    else
        notify("Stop", "Tidak ada gerakan yang terekam", 3)
    end
end

--// =========================================================
--// Smooth Character Apply / Playback
--// =========================================================

function getFrameCFrame(fr)
    local pos = tableToVec(fr.position)
    local yaw = tonumber(fr.rotation) or 0
    return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

function applyFrameMeta(fr, hum)
    if not fr or not hum then
        return
    end

    if not USE_MAP_WALKSPEED_ON_PLAYBACK then
        pcall(function()
            local ws = tonumber(fr.walkSpeed)
            if ws and ws > 0 and ws > (tonumber(hum.WalkSpeed) or 0) then
                hum.WalkSpeed = ws
            end
        end)
    end

    if not USE_MAP_HIPHEIGHT_ON_PLAYBACK then
        pcall(function()
            hum.HipHeight = tonumber(fr.hipHeight) or hum.HipHeight
        end)
    end

    if fr.jump == true and not USE_NATURAL_MAP_JUMP then
        pcall(function()
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end

    local st = tostring(fr.states or "")

    pcall(function()
        if st == "Jumping" then
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        elseif st == "Freefall" then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        elseif st == "Climbing" then
            hum:ChangeState(Enum.HumanoidStateType.Climbing)
        elseif st == "Swimming" then
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
        elseif st == "Running" then
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

    local noShiftLock = isNoShiftLockFrame(fr)

    --// PATCH LOCK PLAY:
    --// Saat playback, badan avatar wajib ikut rotation dari record.
    --// Jangan pakai AutoRotate/no-shift-lock karena itu bikin hadap badan berubah sendiri.
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
--// v1.5.1: Momentum preservation (anti micro-stutter)
        local currentVel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X * 0.85, 0, currentVel.Z * 0.85)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    pcall(function()
        local pos = tableToVec(fr.position)

        --// PATCH LOCK PLAY:
        --// Posisi + hadap badan selalu ikut data record.
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

    local ws = tonumber(fr.walkSpeed) or tonumber(fr.ws) or 0
    if ws > 0 then
        return ws
    end

    return 0
end

--// ANTI-JITTER IDLE:
--// Saat record kita skip frame idle/kedut, jadi antar 2 keyframe bisa ada gap waktu
--// dengan posisi nyaris sama. Kalau tetap di-Lerp + set velocity tiap heartbeat,
--// avatar terlihat bergetar di tempat. Solusi: HOLD penuh kalau segmen ini idle.
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
        return tonumber(hum.WalkSpeed) or DEFAULT_PLAYBACK_SPEED
    end

    return DEFAULT_PLAYBACK_SPEED
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

function buildBridgeFramesBetween(lastFrame, nextFrame, stepDistance, maxFrames, maxDistance)
    local result = {}

    if not lastFrame or not nextFrame then
        return result
    end

    stepDistance = tonumber(stepDistance) or PLAYBACK_STEP_DISTANCE
    maxFrames = tonumber(maxFrames) or MAX_BRIDGE_FRAMES
    maxDistance = tonumber(maxDistance) or PLAYBACK_MAX_SMOOTH_DISTANCE

    local p1 = tableToVec(lastFrame.position)
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

    local r1 = tonumber(lastFrame.rotation) or 0
    local r2 = tonumber(nextFrame.rotation) or r1

    local t1 = tonumber(lastFrame.times) or tonumber(lastFrame.t) or 0
    local t2 = tonumber(nextFrame.times) or tonumber(nextFrame.t) or (t1 + SAMPLE_INTERVAL * (steps + 1))
    if t2 <= t1 then
        t2 = t1 + SAMPLE_INTERVAL * (steps + 1)
    end

    local dir = p2 - p1
    local moveDir = Vector3.new(0, 0, 0)
    if dir.Magnitude > 0.01 then
        moveDir = dir.Unit
    end

    local bridgeSpeed = math.clamp(dist / math.max(t2 - t1, SAMPLE_INTERVAL), 8, MAX_PLAYBACK_SPEED)

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
        fr.city = vecToTable(moveDir * bridgeSpeed)
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
            local spd = math.max(getPlaybackFrameHorizontalSpeed(prev), getPlaybackFrameHorizontalSpeed(copy), DEFAULT_PLAYBACK_SPEED)
            t = lastT + math.clamp(hd / math.max(spd, 1), SPEED_TIMING_MIN_DT, SPEED_TIMING_MAX_DT)
        end

        copy.times = roundNumber(t, 9)
        copy.t = copy.times
        table.insert(result, copy)
        lastT = t
    end

    return result
end

function preparePlaybackFrames(rawFrames)
    -- Jangan retime ke SAMPLE_INTERVAL. Playback harus pakai timing asli record/map.
    local clean = sanitizeFrames(rawFrames, false)
    if not clean or #clean <= 0 then
        return nil
    end

    local result = {}
    local lastFrame = nil

    for _, fr in ipairs(clean) do
        local newFrame = deepCopy(fr)

        if not lastFrame then
            table.insert(result, newFrame)
            lastFrame = newFrame
        else
            local lastPos = tableToVec(lastFrame.position)
            local newPos = tableToVec(newFrame.position)
            local dist = (newPos - lastPos).Magnitude
            local forceCut = newFrame.seam == true or lastFrame.cutNext == true or dist > PLAYBACK_MAX_SMOOTH_DISTANCE

            if forceCut then
                newFrame.seam = true
                table.insert(result, newFrame)
                lastFrame = newFrame
            elseif dist < PLAYBACK_MIN_STEP_DISTANCE and newFrame.jump ~= true and not isAirState(newFrame.states) then
                -- skip frame kembar
            else
                if dist > (PLAYBACK_STEP_DISTANCE * 2.4) then
                    local bridge = buildBridgeFramesBetween(lastFrame, newFrame, PLAYBACK_STEP_DISTANCE, MAX_BRIDGE_FRAMES, PLAYBACK_MAX_SMOOTH_DISTANCE)

                    for _, bridgeFrame in ipairs(bridge) do
                        table.insert(result, bridgeFrame)
                        lastFrame = bridgeFrame
                    end
                end

                table.insert(result, newFrame)
                lastFrame = newFrame
            end
        end
    end

    if #result <= 0 then
        return nil
    end

    return normalizePlaybackTimesKeepOriginal(result)
end

function setPlaybackButtonState(active)
    if not StopPlayBtn then
        return
    end

    if active then
        StopPlayBtn.Text = "STOP PLAY"
        StopPlayBtn.BackgroundColor3 = Color3.fromRGB(190, 70, 75)
    else
        StopPlayBtn.Text = "STOP PLAY"
        StopPlayBtn.BackgroundColor3 = Color3.fromRGB(155, 60, 65)
    end
end

stopPlayback = function(showMsg)
    if not isPlaying then
        if showMsg then
            notify("Playback", "Tidak ada playback yang berjalan", 2)
        end
        return
    end

    playToken = playToken + 1
    isPlaying = false
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

--// =========================================================
--// PERBAIKAN PLAYBACK: Speed sekarang mengikuti angka di speedBox
--// =========================================================

--// =========================================================
--// BITWISE STYLE PLAYBACK UNTUK ONIUM
--// Baca JSON ONIUM/BitWise, AUTO speed map, manual speed box.
--// Cara speed sama BitWise: currentTime maju pakai speedMultiplier.
--// =========================================================

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
        local citySpeed = getFrameHorizontalVelocity(fr)
        local walkSpeed = tonumber(fr.walkSpeed) or tonumber(fr.ws) or 0
        local value = math.max(citySpeed, walkSpeed)

        -- buang frame idle agar AUTO speed tidak turun.
        if value >= MIN_PLAYBACK_SPEED and value <= MAX_PLAYBACK_SPEED then
            table.insert(values, value)
        end

        -- fallback dari jarak / waktu kalau city kosong.
        if i > 1 then
            local prev = frames[i - 1]
            local dt = (tonumber(fr.times) or tonumber(fr.t) or 0) - (tonumber(prev.times) or tonumber(prev.t) or 0)
            if dt > 0.002 then
                local hd = horizontalDistance(tableToVec(prev.position), tableToVec(fr.position))
                local spd = hd / dt
                if spd >= MIN_PLAYBACK_SPEED and spd <= MAX_PLAYBACK_SPEED then
                    table.insert(values, spd)
                end
            end
        end
    end

    if #values <= 0 then
        return DEFAULT_PLAYBACK_SPEED
    end

    table.sort(values)

    -- Pakai 75% percentile, bukan rata-rata.
    -- Ini biar frame pelan di awal/akhir tidak bikin AUTO speed turun.
    local idx = math.floor(#values * 0.75)
    if idx < 1 then
        idx = 1
    end

    return roundNumber(math.clamp(values[idx] or DEFAULT_PLAYBACK_SPEED, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED), 1)
end

function getPlaybackSpeedForFrames(frames)
    local recordedSpeed = estimateRecordedPlaybackSpeedBitwise(frames)
    local raw = tostring(speedBox and speedBox.Text or "AUTO")
    raw = raw:gsub(",", ".")
    raw = raw:gsub("^%s+", "")
    raw = raw:gsub("%s+$", "")

    local manual = tonumber(raw)
    if manual and manual > 0 then
        manual = math.clamp(manual, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)
        currentPlaybackSpeed = manual
        -- syncBaseSpeed tetap base record supaya multiplier benar.
        syncBaseSpeed = recordedSpeed
        return roundNumber(manual, 1), true, recordedSpeed
    end

    currentPlaybackSpeed = recordedSpeed
    syncBaseSpeed = recordedSpeed

    if speedBox then
        speedBox.Text = "AUTO"
    end

    return recordedSpeed, false, recordedSpeed
end

function findPreparedFrameAtTimeFast(frames, timeValue)
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

        if timeValue >= ta and timeValue <= tb then
            return mid
        elseif timeValue < ta then
            right = mid - 1
        else
            left = mid + 1
        end
    end

    if timeValue <= 0 then
        return 1
    end

    return math.max(1, #frames - 1)
end

function applyFrameBitwiseStyle(a, b, alpha, hum, hrp, speedMultiplier, playbackSpeed)
    if not a or not b or not hum or not hrp then
        return
    end

    local pa = tableToVec(a.position)
    local pb = tableToVec(b.position)

    local ra = tonumber(a.rotation) or 0
    local rb = tonumber(b.rotation) or ra

    local eased = easeCubic(math.clamp(alpha or 0, 0, 1))  -- v1.5.1: cubic easing instead of linear
    local targetPos = pa:Lerp(pb, eased)
    local yaw = lerpAngle(ra, rb, eased)

    local st = getFrameStateText(b)
    local previousState = getFrameStateText(a)
    local landing = (previousState == "Freefall" or previousState == "FallingDown" or isJumpStateText(previousState))
        and not isJumpStateText(st) and st ~= "Freefall" and st ~= "FallingDown"

    --// IDLE HOLD (anti getar):
    --// Segmen idle / nyaris diam tidak boleh di-Lerp + di-set velocity tiap heartbeat,
    --// karena bikin avatar bergetar di tempat. Cukup kunci CFrame ke posisi awal.
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

    --// PLAYBACK ANTI BLING VISUAL GUARD:
    --// Kalau masih ada frame Running yang targetPos-nya jauh mendadak, jangan langsung CFrame blink.
    --// Guard ini hanya untuk Running; Jump/Freefall tetap mengikuti momentum asli.
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
        local visualGap = (targetPos - nowPos).Magnitude
        if visualGap > (RUN_PLAYBACK_BIG_GAP_DISTANCE or 6.2) then
            local step = math.max(RUN_PLAYBACK_MAX_VISUAL_STEP or 4.25, 1)
            targetPos = nowPos:Lerp(targetPos, math.clamp(step / visualGap, 0.05, 1))
        end
    end

    local timeDiff = (tonumber(b.times) or tonumber(b.t) or 0) - (tonumber(a.times) or tonumber(a.t) or 0)
    if timeDiff <= 0.001 then
        timeDiff = SAMPLE_INTERVAL
    end

    local mapVel = getFrameVelocityVector(b)
    if mapVel.Magnitude < 0.05 then
        mapVel = (pb - pa) / math.max(timeDiff, 0.001)
    end

    local spdMul = math.clamp(tonumber(speedMultiplier) or 1, 0.05, 25)
    mapVel = mapVel * spdMul

    --// FIX FREEFALL JITTER:
    --// Velocity rekaman terpengaruh workspace.Gravity tiap map (beda map = beda fall speed).
    --// Kalau dipakai langsung saat playback, gravity lokal map saat play akan menambah/mengurangi
    --// Y velocity tiap frame, sementara CFrame juga di-teleport tiap frame -> dua sumber gerak
    --// saling adu = geter saat terjun dari ketinggian.
    --// Solusi: derive velocity dari delta posisi murni (pb-pa)/dt, sehingga selaras dengan CFrame
    --// teleport, terlepas dari gravity map manapun.
    local posDeltaVel = (pb - pa) / math.max(timeDiff, 0.001)
    posDeltaVel = posDeltaVel * spdMul

    local moveDir = tableToVec(b.moveDirection)
    if moveDir.Magnitude > 0.01 then
        pcall(function()
            hum:Move(moveDir.Unit, true)
        end)
    end

    pcall(function()
        local targetWs = tonumber(playbackSpeed) or tonumber(b.walkSpeed) or DEFAULT_PLAYBACK_SPEED
        hum.WalkSpeed = math.clamp(targetWs, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)
        hum.Sit = false
        hum.PlatformStand = false

        if not USE_MAP_HIPHEIGHT_ON_PLAYBACK then
            hum.HipHeight = tonumber(b.hipHeight) or hum.HipHeight
        end
    end)

    local isJumping = (b.jump == true) or isJumpStateText(st)
    local isFreefall = not landing and (st == "Freefall" or st == "FallingDown" or posDeltaVel.Y < -2 or mapVel.Y < -2)
    local isClimbing = st == "Climbing"
    local isSwimming = st == "Swimming"

    pcall(function()
        --// PATCH LOCK PLAY:
        --// BitWise playback tetap lock ke yaw/rotation record.
        hum.AutoRotate = false
        hrp.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, yaw, 0)

        local hVel = Vector3.new(mapVel.X, 0, mapVel.Z)

        --// FIX LOOP SPEED:
        --// Jangan pakai cap 240 terus-menerus, karena pada mode loop beberapa UI bisa
        --// menumpuk multiplier dan membuat speed lebih kenceng dari play biasa.
        local baseFrameSpeed = math.max(
            getFrameHorizontalVelocity(a),
            getFrameHorizontalVelocity(b),
            tonumber(playbackSpeed) or DEFAULT_PLAYBACK_SPEED,
            MIN_PLAYBACK_SPEED
        )
        local maxLoopSafeSpeed = math.max(baseFrameSpeed * LOOP_SPEED_SAFE_CAP_MULTIPLIER, MIN_PLAYBACK_SPEED)

        if hVel.Magnitude > maxLoopSafeSpeed then
            hVel = hVel.Unit * maxLoopSafeSpeed
        end

        local yVel = math.clamp(mapVel.Y, -220, 170)

        if isJumping then
            --// FIX FREEFALL JITTER (terjun dari atas):
            --// Pakai velocity dari delta posisi (sinkron dgn CFrame teleport), bukan velocity
            --// rekaman yang ter-skala gravity map. Horizontal pakai posDeltaVel.X/Z biar
            --// momentum saat terjun konsisten antar map.
            local fhX = posDeltaVel.X
            local fhZ = posDeltaVel.Z
            local fhMag = math.sqrt(fhX * fhX + fhZ * fhZ)
            if fhMag > maxLoopSafeSpeed and fhMag > 0 then
                local k = maxLoopSafeSpeed / fhMag
                fhX, fhZ = fhX * k, fhZ * k
            end
            local fyVel = math.clamp(posDeltaVel.Y, -500, 300)

            hrp.AssemblyLinearVelocity = Vector3.new(fhX, fyVel, fhZ)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

            if isFreefall then
                hum.Jump = false
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            else
                hum.Jump = true
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end

        elseif isClimbing then
            hrp.AssemblyLinearVelocity = Vector3.new(hVel.X * 0.25, math.clamp(yVel, -50, 50), hVel.Z * 0.25)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hum:ChangeState(Enum.HumanoidStateType.Climbing)

        elseif isSwimming then
            hrp.AssemblyLinearVelocity = Vector3.new(hVel.X, yVel, hVel.Z)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hum:ChangeState(Enum.HumanoidStateType.Swimming)

        else
            -- Running: tetap pakai city asli JSON agar speed tiap map tidak ngaco.
            -- Consume downward momentum on the first grounded frame after a jump.
            local landingY = landing and math.max(0, posDeltaVel.Y) or math.clamp(yVel, -80, 80)
            hrp.AssemblyLinearVelocity = Vector3.new(hVel.X, landingY, hVel.Z)
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

    local closestIndex = 1
    local closestDistance = (tableToVec(frames[1].position) - position).Magnitude
    local step = math.max(1, math.floor(#frames / 500))

    for i = 1, #frames, step do
        local pos = tableToVec(frames[i].position)
        local distance = (pos - position).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestIndex = i
        end
    end

    local searchRadius = math.min(step, 50)
    for i = math.max(1, closestIndex - searchRadius), math.min(#frames, closestIndex + searchRadius) do
        local pos = tableToVec(frames[i].position)
        local distance = (pos - position).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestIndex = i
        end
    end

    return closestIndex, closestDistance
end

function getBitwiseSmartStartForOnium(frames)
    local _, hum, hrp = getCharacter()
    if not hrp or not frames or #frames < 2 then
        return 1, tonumber(frames and frames[1] and (frames[1].times or frames[1].t)) or 0
    end

    local firstT = tonumber(frames[1].times) or tonumber(frames[1].t) or 0
    local lastT = tonumber(frames[#frames].times) or tonumber(frames[#frames].t) or firstT
    local finishLimit = math.max(lastT - PLAY_AGAIN_FINISH_TIME_WINDOW, firstT)

    local startPos = tableToVec(frames[1].position)
    local finishPos = tableToVec(frames[#frames].position)
    local distanceToFinish = (finishPos - hrp.Position).Magnitude

    local closestIndex, distanceTo = findNearestPreparedFrameToPosition(frames, hrp.Position)
    closestIndex = math.clamp(tonumber(closestIndex) or 1, 1, #frames - 1)
    local targetTime = tonumber(frames[closestIndex] and (frames[closestIndex].times or frames[closestIndex].t)) or firstT

    --// INTI FIX:
    --// Dulu kalau posisi sudah di FINISH, script mulai dari lastT - 0.35,
    --// jadi tombol PLAY terasa tidak bisa balik ke START.
    --// Sekarang hanya kalau avatar benar-benar masih dekat FINISH, PLAY ulang = START.
    if distanceToFinish <= PLAY_AGAIN_FINISH_RESET_DISTANCE and targetTime >= finishLimit then
        notify("Smart Resume", "Masih di FINISH, balik ke START", 1)
        return 1, firstT
    end

    --// Kalau avatar jauh dari path sekali, tetap pakai START sebagai fallback aman.
    --// Kalau avatar masih dekat salah satu bagian path, tetap resume dari titik terdekat.
    if distanceTo > 50 then
        notify("Smart Resume", "Jauh dari path, mulai dari START", 1)
        return 1, firstT
    end

    --// Kalau dekat akhir tapi bukan berdiri di FINISH, jangan paksa balik START.
    --// Ini menjaga request: kalau avatar sudah jauh dari FINISH, tetap play dari dekat posisi itu.
    if targetTime >= finishLimit then
        notify("Smart Resume", "Dekat akhir, lanjut dari titik terdekat", 1)
        return closestIndex, targetTime
    end

    notify("Smart Resume", "Mulai dari titik terdekat", 1)
    return closestIndex, targetTime
end

function playFrames(frames, checkpointName)
    frames = preparePlaybackFrames(frames)

    if not frames or #frames <= 1 then
        notify("Playback", "Data checkpoint kosong/rusak", 3)
        return
    end

    --// FIX SPEED MAP:
    --// Simpan speed asli map sebelum playback mengubah WalkSpeed.
    captureMapSpeedBeforePlayback()

    playToken = playToken + 1
    local myToken = playToken
    isPlaying = true
    setPlaybackButtonState(true)

    local playbackSpeed, manualMode, recordedBaseSpeed = getPlaybackSpeedForFrames(frames)
    local speedMultiplier = math.clamp((tonumber(playbackSpeed) or recordedBaseSpeed) / math.max(tonumber(recordedBaseSpeed) or DEFAULT_PLAYBACK_SPEED, 1), 0.05, 25)

    --// Time multiplier dan velocity multiplier dipisah supaya loop tidak terasa dobel speed.
    --// RAW EXACT: preview/playback hub mengikuti times + city asli dari record, bukan dikali lagi.
    local timeMultiplier = speedMultiplier
    local velocityMultiplier = speedMultiplier
    local modeText = manualMode and "MANUAL" or "AUTO MAP"

    if EXPORT_RAW_EXACT_MODE and RAW_EXACT_DISABLE_PREVIEW_SPEED_MULTIPLIER then
        timeMultiplier = 1
        velocityMultiplier = 1
        speedMultiplier = 1
        modeText = "RAW MAP"
    end

    task.spawn(function()
        notify(
            "Playback",
            "Play " .. tostring(checkpointName) .. " | " .. modeText .. " | speed " .. tostring(playbackSpeed),
            3
        )

        local char, hum, hrp = getCharacter()
        if not hum or not hrp then
            isPlaying = false
            setPlaybackButtonState(false)
            return
        end

        local oldAutoRotate = hum.AutoRotate
        local oldWalkSpeed = hum.WalkSpeed
        local oldJumpPower = hum.JumpPower

        pcall(function()
            --// PATCH LOCK PLAY:
            --// Selama playback, AutoRotate dimatikan supaya hadap badan tidak lepas dari record.
            hum.AutoRotate = false
            hum.PlatformStand = false
            hum.Sit = false
            hum.Jump = false
            hum.WalkSpeed = math.clamp(playbackSpeed, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)

        local startIndex, startTime = getBitwiseSmartStartForOnium(frames)
        local startFrame = frames[startIndex] or frames[1]
        equipFrameTool(startFrame, char, hum)
        applyFrameInstant(startFrame)
        task.wait(0.02)

        local firstT = tonumber(frames[1].times) or tonumber(frames[1].t) or 0
        local lastT = tonumber(frames[#frames].times) or tonumber(frames[#frames].t) or firstT
        local totalDuration = math.max(lastT - firstT, 0.001)
        local currentTime = math.clamp((tonumber(startTime) or firstT) - firstT, 0, totalDuration)
        local lastClock = os.clock()

        while myToken == playToken and isPlaying and currentTime < totalDuration do
            char, hum, hrp = getCharacter()
            if not hum or not hrp then
                break
            end

            local now = os.clock()
            local realDt = now - lastClock
            lastClock = now

            if realDt <= 0 then
                realDt = 0.016
            elseif realDt > 0.2 then
                realDt = 0.1
            end

            -- Ini inti metode BitWise: waktu playback dimajukan pakai multiplier speed.
            -- Pakai timeMultiplier, bukan velocity langsung, agar mode loop tidak menumpuk speed.
            currentTime = currentTime + (realDt * timeMultiplier)

            local absoluteTime = firstT + currentTime
            local idx = findPreparedFrameAtTimeFast(frames, absoluteTime)
            local a = frames[idx]
            local b = frames[idx + 1]

            if not a or not b then
                break
            end

            local ta = tonumber(a.times) or tonumber(a.t) or 0
            local tb = tonumber(b.times) or tonumber(b.t) or ta
            local dt = tb - ta
            if dt <= 0.001 then
                dt = SAMPLE_INTERVAL
            end

            local alpha = math.clamp((absoluteTime - ta) / dt, 0, 1)

            if b.seam == true or a.cutNext == true then
                equipFrameTool(b, char, hum)
                applyFrameInstant(b)
            else
                equipFrameTool(b, char, hum)
                applyFrameMeta(b, hum)
                applyFrameBitwiseStyle(a, b, alpha, hum, hrp, velocityMultiplier, playbackSpeed)
            end

            RunService.Heartbeat:Wait()
        end

        if myToken == playToken and isPlaying then
            local finalFrame = frames[#frames]
            applyFrameInstant(finalFrame)
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
                finalHum.AutoRotate = oldAutoRotate
                finalHum.PlatformStand = false
                finalHum.Sit = false
                finalHum.Jump = false
                finalHum.WalkSpeed = math.max(tonumber(oldWalkSpeed) or 0, MIN_PLAYBACK_SPEED)
                finalHum.JumpPower = oldJumpPower or finalHum.JumpPower
                finalHum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end

        --// FIX SPEED MAP:
        --// Jangan kirim playbackSpeed ke restore, karena itu bisa membuat speed normal map jadi terlalu cepat.
        restoreCharacterControl()

        isPlaying = false
        setPlaybackButtonState(false)
        notify("Playback", "Selesai. Mode " .. modeText .. ", speed " .. tostring(playbackSpeed), 2)
    end)
end

playCheckpoint = function(cp)
    if not cp or not cp.frames then
        return
    end

    playFrames(cp.frames, cp.name)
end

--// =========================================================
--// Rollback
--// =========================================================

function findRollbackTargetObjectIndex()
    if #recordFrames <= 2 then
        return nil, nil
    end

    local currentGroundKey = nil

    for i = #recordFrames, 1, -1 do
        local key = groundKeyFromFrame(recordFrames[i])
        if key then
            currentGroundKey = key
            break
        end
    end

    if not currentGroundKey then
        return nil, nil
    end

    local alreadySeenCurrentObject = false

    for i = #recordFrames, 1, -1 do
        local key = groundKeyFromFrame(recordFrames[i])

        if key then
            if key == currentGroundKey then
                alreadySeenCurrentObject = true
            elseif alreadySeenCurrentObject then
                return i, key
            end
        end
    end

    for i = 1, #recordFrames do
        if groundKeyFromFrame(recordFrames[i]) == currentGroundKey then
            return i, currentGroundKey
        end
    end

    return nil, nil
end


--// =========================================================
--// ROLLBACK SAFE GROUND FIX
--// Masalah: saat jatuh, rollback kadang balik ke posisi udara / pijakan sudah hilang,
--// lalu avatar jatuh lagi. Fix ini mencari frame rollback yang benar-benar masih
--// punya pijakan di map SAAT INI, lalu posisi HRP disesuaikan ke atas pijakan itu.
--// =========================================================
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

--// FIX OBJECT DI ATAS KEPALA:
--// Raycast ground lama mulai dari pos + 10. Kalau ada part/atap di atas kepala,
--// raycast kena atap dulu lalu rollback gagal. Versi ini skip hit yang posisinya
--// masih di atas/dekat HRP, jadi yang dipakai hanya pijakan di bawah badan.
ROLLBACK_CEILING_SKIP_MARGIN = 1.15
ROLLBACK_GROUND_SCAN_LIMIT = 12
ROLLBACK_HEAD_CHECK_UP = 5.5

function makeRollbackRaycastParams(extraIgnore)
    local char = LocalPlayer and LocalPlayer.Character
    local ignoreList = {}

    if char then
        table.insert(ignoreList, char)
    end

    if type(extraIgnore) == "table" then
        for _, inst in ipairs(extraIgnore) do
            if inst then
                table.insert(ignoreList, inst)
            end
        end
    end

    local params = RaycastParams.new()

    pcall(function()
        params.FilterType = Enum.RaycastFilterType.Blacklist
    end)

    pcall(function()
        params.FilterDescendantsInstances = ignoreList
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

    local ignoredHits = {}
    local origin = pos + Vector3.new(0, ROLLBACK_GROUND_RAY_UP, 0)
    local direction = Vector3.new(0, -(ROLLBACK_GROUND_RAY_UP + ROLLBACK_GROUND_RAY_DOWN), 0)

    for _ = 1, ROLLBACK_GROUND_SCAN_LIMIT do
        local params = makeRollbackRaycastParams(ignoredHits)
        local ok, result = pcall(function()
            return workspace:Raycast(origin, direction, params)
        end)

        if not ok or not result or not result.Instance then
            return nil
        end

        local inst = result.Instance
        local hitY = result.Position and result.Position.Y or -math.huge
        local hitIsAboveBody = hitY > (pos.Y - ROLLBACK_CEILING_SKIP_MARGIN)

        --// Kalau kena object atas kepala / object tidak valid, skip lalu raycast ulang.
        if hitIsAboveBody or not isRollbackPartValid(inst) then
            table.insert(ignoredHits, inst)
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
    local direction = Vector3.new(0, math.max(ROLLBACK_HEAD_CHECK_UP, hip + 3.2), 0)

    local ok, result = pcall(function()
        return workspace:Raycast(origin, direction, params)
    end)

    if ok and result and result.Instance and isRollbackPartValid(result.Instance) then
        return result
    end

    return nil
end

function getRollbackHoldCFrame(targetCF, hum)
    --// Jika ada object/atap di atas kepala, jangan tahan karakter lebih tinggi.
    --// Langsung tahan di target supaya tidak mentok object atas.
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

    -- Jangan jadikan frame udara sebagai target berdiri.
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

    -- Kalau beda Y terlalu jauh, kemungkinan pijakan asli sudah hilang dan ray kena lantai bawah.
    -- Jangan pakai target ini, cari frame sebelumnya.
    if math.abs(safePos.Y - rawPos.Y) > ROLLBACK_MAX_GROUND_Y_DIFF then
        return nil, nil, "wrong_ground_y"
    end

    local _, yaw, _ = rawCF:ToOrientation()
    local safeCF = CFrame.new(safePos) * CFrame.Angles(0, yaw, 0)

    return safeCF, safePos, "ok"
end

function isSafeRollbackFrameIndex(index)
    local _, hum = getCharacter()
    local fr = recordFrames[index]
    local cf = nil

    if not fr then
        return false
    end

    cf = select(1, getSafeRollbackCFrame(fr, hum))
    return cf ~= nil
end

function findSafeRollbackIndex(startIndex)
    startIndex = math.clamp(tonumber(startIndex) or #recordFrames, 1, #recordFrames)

    -- Cari mundur dulu: biasanya ini posisi sebelum lompat yang masih punya pijakan.
    for i = startIndex, 1, -1 do
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
    local distToGround = pos.Y - hit.Position.Y

    return distToGround >= (ROLLBACK_MIN_HRP_GROUND_OFFSET - 0.5)
        and distToGround <= (offset + 3.5)
end

function applyRollbackSmoothToFrame(targetFrame, myRollbackToken)
    local char, hum, hrp = getCharacter()
    if not hum or not hrp or type(targetFrame) ~= "table" then
        return false
    end

    if not isRecording or not isRollbacking or rollbackCancel or myRollbackToken ~= rollbackToken then
        return false
    end

    local targetCF, targetPos, safeReason = getSafeRollbackCFrame(targetFrame, hum)
    if not targetCF or not targetPos then
        --// Target tidak punya pijakan di map saat ini. Jangan rollback ke udara.
        return false
    end

    --// FIX ROLLBACK BLINK + JATUH LAGI:
    --// Jangan Lerp pelan-pelan. Di beberapa map, Lerp membuat avatar ditarik balik
    --// oleh physics/anti-teleport sehingga terlihat ngeblink.
    --// Pakai hard snap ke posisi yang sudah divalidasi ada pijakan di bawahnya.
    local oldAutoRotate = hum.AutoRotate
    local oldPlatformStand = hum.PlatformStand

    pcall(function()
        hum.AutoRotate = false
        hum.PlatformStand = true
        hum:Move(Vector3.new(0, 0, 0), true)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)

    pcall(function()
        hrp.Anchored = true
    end)

    --// Tahan sedikit di atas target, kecuali ada object/atap di atas kepala.
    local holdCF = getRollbackHoldCFrame(targetCF, hum)

    for i = 1, 10 do
        if not isRecording or not isRollbacking or rollbackCancel or myRollbackToken ~= rollbackToken then
            pcall(function() hrp.Anchored = false end)
            pcall(function()
                hum.PlatformStand = oldPlatformStand
                hum.AutoRotate = oldAutoRotate
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
--// v1.5.1: Momentum preservation (anti micro-stutter)
        local currentVel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X * 0.85, 0, currentVel.Z * 0.85)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    task.wait(0.08)

    pcall(function()
        hrp.Anchored = false
    end)

    pcall(function()
        hum.PlatformStand = oldPlatformStand
        hum.AutoRotate = oldAutoRotate
        hum.HipHeight = tonumber(targetFrame.hipHeight) or hum.HipHeight
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum:Move(Vector3.new(0, 0, 0), true)
    end)

    --// Tunggu sebentar setelah unanchor. Kalau langsung tidak ada ground, berarti target tidak aman.
    for _ = 1, 3 do
        RunService.Heartbeat:Wait()
    end

    local okDistance = false
    local okGround = false

    pcall(function()
        okDistance = (hrp.Position - targetPos).Magnitude <= 7
        okGround = isRollbackStillGrounded(hrp.Position, targetFrame, hum)
    end)

    if okDistance and okGround then
        lastRecordSavedPos = hrp.Position
        return true
    end

    --// Kalau map menarik balik / pijakan tidak ada, jangan hapus frame.
    return false
end

rollbackRecording = function()
    if not isRecording then
        notify("Rollback", "Recording belum berjalan", 2)
        return
    end

    forceShiftLockOff()

    --// Kalau rollback sedang jalan, pencet lagi = stop rollback
    if isRollbacking then
        rollbackCancel = true
        rollbackToken = rollbackToken + 1
        isRollbacking = false

        if RollbackBtn then
            RollbackBtn.Text = "ROLL"
            RollbackBtn.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
        end

        if overlayStatusLabel then
            overlayStatusLabel.Text = "● REC"
        end

        restoreCharacterControl()

        local _, _, hrp = getCharacter()
        if hrp then
            lastRecordSavedPos = hrp.Position
        end

        updateOverlay()
        notify("Rollback", "Rollback distop. Record lanjut dari posisi ini.", 2)
        return
    end

    if #recordFrames <= 2 then
        notify("Rollback", "Frame masih terlalu sedikit", 2)
        return
    end

    isRollbacking = true
    rollbackCancel = false
    rollbackToken = rollbackToken + 1

    local myRollbackToken = rollbackToken

    if overlayStatusLabel then
        overlayStatusLabel.Text = "↶ ROLLBACK. klik lagi untuk STOP"
    end

    if RollbackBtn then
        RollbackBtn.Text = "STOP ROLL"
        RollbackBtn.BackgroundColor3 = Color3.fromRGB(190, 80, 55)
    end

    task.spawn(function()
        local char, hum, hrp = getCharacter()
        local oldAutoRotate = nil

        if hum then
            oldAutoRotate = hum.AutoRotate
            pcall(function()
                hum.AutoRotate = false
            end)
        end

        --// PRIORITAS BARU:
        --// Balik ke posisi terakhir sebelum lompat / sebelum kaki lepas tanah.
        local targetIndex, targetReason = findRollbackBeforeJumpIndex()
        local usingJumpRollback = targetIndex ~= nil and targetIndex < #recordFrames

        --// Fallback lama kalau tidak ketemu frame sebelum lompat
        local targetGround = nil
        local usingObjectRollback = false

        if not usingJumpRollback then
            targetIndex, targetGround = findRollbackTargetObjectIndex()
            usingObjectRollback = targetIndex ~= nil and targetIndex < #recordFrames
        end

        local removed = 0

        if usingJumpRollback or usingObjectRollback then
            --// FIX: jangan rollback ke posisi yang pijakannya sudah hilang.
            --// Cari frame sebelumnya yang benar-benar masih ada ground di map saat ini.
            local safeIndex = findSafeRollbackIndex(targetIndex)
            if safeIndex then
                targetIndex = safeIndex
            end

            local targetFrame = safeIndex and recordFrames[targetIndex] or nil

            --// FIX: pindahkan avatar dulu, baru hapus frame.
            --// Kalau move gagal / ground tidak ada, frame tidak hilang dan rollback tidak ngeblink doang.
            local okMove = false
            if targetFrame
                and isRecording
                and isRollbacking
                and not rollbackCancel
                and myRollbackToken == rollbackToken
            then
                okMove = applyRollbackSmoothToFrame(targetFrame, myRollbackToken)
            end

            if okMove then
                while #recordFrames > targetIndex do
                    table.remove(recordFrames, #recordFrames)
                    removed = removed + 1
                end
            else
                notify("Rollback", "Gagal balik: map menarik avatar. Frame tidak dihapus.", 3)
            end

            updateOverlay()
        else
            --// Fallback terakhir: cari frame mundur yang benar-benar bisa ditempati.
            local maxRemove = math.min(ROLLBACK_MAX_FRAMES, math.max(0, #recordFrames - 1))
            local tryIndex = #recordFrames - 1

            while isRecording
                and isRollbacking
                and not rollbackCancel
                and myRollbackToken == rollbackToken
                and tryIndex >= 1
                and removed < maxRemove do

                local targetFrame = recordFrames[tryIndex]
                if not targetFrame then
                    break
                end

                local okMove = applyRollbackSmoothToFrame(targetFrame, myRollbackToken)
                if okMove then
                    while #recordFrames > tryIndex do
                        table.remove(recordFrames, #recordFrames)
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

        if finalHum and oldAutoRotate ~= nil then
            pcall(function()
                finalHum.AutoRotate = oldAutoRotate
            end)
        end

        if finalHrp then
            pcall(function()
                finalHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                finalHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)

            lastRecordSavedPos = finalHrp.Position
        end

        restoreCharacterControl()

        if myRollbackToken == rollbackToken then
            -- RAW: setelah rollback jangan retime, cukup normalisasi ringan.
            recordFrames = basicNormalizeFrames(recordFrames) or recordFrames
            isRollbacking = false
            rollbackCancel = false

            if RollbackBtn then
                RollbackBtn.Text = "ROLL"
                RollbackBtn.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
            end

            if isRecording and overlayStatusLabel then
                overlayStatusLabel.Text = "● REC"
            end

            updateOverlay()

            if removed > 0 then
                if usingJumpRollback then
                    notify("Rollback", "Balik ke posisi sebelum lompat | " .. tostring(removed) .. " frame dihapus", 3)
                elseif usingObjectRollback then
                    notify("Rollback", "Balik ke object terakhir: " .. tostring(targetGround or "object") .. " | " .. tostring(removed) .. " frame", 3)
                else
                    notify("Rollback", "Fallback mundur " .. tostring(removed) .. " frame", 3)
                end
            else
                notify("Rollback", "Rollback berhenti", 2)
            end
        else
            isRollbacking = false
            rollbackCancel = false

            if RollbackBtn then
                RollbackBtn.Text = "ROLL"
                RollbackBtn.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
            end

            if isRecording and overlayStatusLabel then
                overlayStatusLabel.Text = "● REC"
            end

            -- RAW: setelah rollback jangan retime, cukup normalisasi ringan.
            recordFrames = basicNormalizeFrames(recordFrames) or recordFrames
            updateOverlay()
        end
    end)
end


--// =========================================================
--// CLEAN SAVE + MERGE: HAPUS IDLE / KEDUT TANPA RUSAK RAW MOMENTUM
--// =========================================================

-- Cleaner ini hanya membuang frame yang benar-benar diam/patah kecil.
-- Data penting tetap RAW: city, rotation, moveDirection, walkSpeed, tool tidak dipalsukan.
local CLEAN_IDLE_EDGE_DISTANCE = 0.14
local CLEAN_IDLE_EDGE_SPEED = 2.25
local CLEAN_IDLE_EDGE_MOVEDIR = 0.08
local CLEAN_MICRO_DISTANCE = 0.035
local CLEAN_MIN_ROTATION = 0.035 -- radian, biar putaran avatar tetap terekam
local CLEAN_MAX_TIMING_GAP = 0.055
local CLEAN_MIN_TIMING_GAP = 0.004

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

    if rotA >= CLEAN_MIN_ROTATION or rotB >= CLEAN_MIN_ROTATION then
        return false
    end

    local dPrev = prev and select(1, frameDistance(prev, fr)) or 999
    local dNext = nextF and select(1, frameDistance(fr, nextF)) or 999
    local minDist = math.min(dPrev, dNext)

    if edgeMode then
        return minDist <= CLEAN_IDLE_EDGE_DISTANCE
            and hv <= CLEAN_IDLE_EDGE_SPEED
            and md <= CLEAN_IDLE_EDGE_MOVEDIR
    end

    return minDist <= CLEAN_MICRO_DISTANCE
        and hv <= CLEAN_IDLE_EDGE_SPEED
        and md <= CLEAN_IDLE_EDGE_MOVEDIR
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

    local dtBySpeed = nil
    if hSpeed > 1 and hd > 0.005 then
        dtBySpeed = hd / hSpeed
    end

    if ySpeed > 1 and vd > 0.005 then
        local yDt = vd / ySpeed
        if dtBySpeed then
            dtBySpeed = math.max(dtBySpeed, yDt)
        else
            dtBySpeed = yDt
        end
    end

    local dt = rawDt

    -- Kalau gap besar karena frame idle dibuang, padatkan supaya tidak ada jeda berhenti.
    if dt <= 0 or dt > CLEAN_MAX_TIMING_GAP then
        dt = dtBySpeed or SAMPLE_INTERVAL
    end

    if dtBySpeed and dt > CLEAN_MAX_TIMING_GAP then
        dt = dtBySpeed
    end

    return math.clamp(dt, CLEAN_MIN_TIMING_GAP, CLEAN_MAX_TIMING_GAP)
end

function compactCleanTimes(frames)
    local out = {}
    local currentTime = 0
    local prevOriginal = nil

    for i, fr in ipairs(frames or {}) do
        local copy = deepCopy(fr)
        if i == 1 then
            currentTime = 0
        else
            currentTime = currentTime + estimateCleanDt(prevOriginal or frames[i - 1], fr)
        end

        copy.times = roundNumber(currentTime, 9)
        copy.t = copy.times
        table.insert(out, copy)
        prevOriginal = fr
    end

    return out
end

--// =========================================================
--// ANTI KEDUT TOTAL V2
--// Save + Merge dibuat seperti merge lama: buang awal lari, awal henti,
--// frame dobel, micro-stop, dan frame slow di sambungan CP.
--// Data Jumping/Freefall/Climbing tetap dilindungi.
--// =========================================================
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
        return tonumber(syncBaseSpeed) or tonumber(currentPlaybackSpeed) or BITWISE_JSON_WALKSPEED or DEFAULT_PLAYBACK_SPEED
    end
    table.sort(speeds)
    local mid = math.floor((#speeds + 1) / 2)
    local base = tonumber(speeds[mid]) or BITWISE_JSON_WALKSPEED or DEFAULT_PLAYBACK_SPEED
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

function antiKedutStabilizeRun(prev, fr, nextF, baseSpeed)
    if EXPORT_RAW_EXACT_MODE then
        -- Jangan rebuild city/moveDirection saat mode upload akurat.
        return fr
    end
    if not fr or antiKedutIsAir(fr) then return fr end
    local dir = nil
    if prev then dir = antiKedutDirectionBetween(prev, fr) end
    if (not dir or dir.Magnitude <= 0.01) and nextF then dir = antiKedutDirectionBetween(fr, nextF) end
    if dir and dir.Magnitude > 0.01 then
        local hv = antiKedutHSpeed(fr)
        local ws = tonumber(fr.walkSpeed) or 0
        local speed = math.max(hv, ws, tonumber(baseSpeed) or 0, ANTI_KEDUT_MIN_RUN_SPEED)
        speed = math.clamp(speed, ANTI_KEDUT_MIN_RUN_SPEED, MAX_PLAYBACK_SPEED or 500000)
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
            local slowInternal = hv < math.max(ANTI_KEDUT_MIN_RUN_SPEED, base * ANTI_KEDUT_INTERNAL_RATIO)
            if dLast < ANTI_KEDUT_DUP_DIST and vdLast < 0.08 then
                keep = false
            elseif slowInternal and hdLast < ANTI_KEDUT_KEEP_DIST and md < 0.18 then
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


--// =========================================================
--// PATCH ONIUM: NO IDLE BUT SMOOTH TURN AFTER IDLE
--// Idle tetap dibuang, tapi rotasi saat diam tidak hilang kasar.
--// Contoh fix: hadap barat diam -> langsung hadap timur/utara/selatan -> jalan
--// hasil save tidak patah/snap, karena yaw disebar ke frame jalan berikutnya.
--// =========================================================
NO_IDLE_TURN_SMOOTH = true
NO_IDLE_TURN_MIN_GAP = 0.10          -- gap waktu yang dianggap ada idle yang dibuang
NO_IDLE_TURN_MIN_YAW = math.rad(18)  -- beda arah minimal agar perlu smoothing
NO_IDLE_TURN_MIN_FRAMES = 5
NO_IDLE_TURN_MAX_FRAMES = 18
NO_IDLE_TURN_MAX_DIST = 18           -- jangan smooth kalau ini teleport/sambungan jauh

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

            -- Kalau ada gap karena idle dibuang + arah berubah besar,
            -- jangan langsung snap. Rotasi disebar ke frame gerak berikutnya.
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

                        -- Sengaja tidak ubah position, city, speed, jump, state.
                        -- Ini cuma memperhalus hadap badan setelah idle dibuang.
                    end
                end
            end
        end
    end

    return out
end


--// =========================================================
--// PATCH ONIUM: REFERENCE JUMP SAVE OPTIMIZER V2
--// Target: kalau hasil record seperti checkpoint_1 masih kedut/pelan,
--// saat SAVE dibuat lebih mirip checkpoint_2: ground gap antar jump dipadatkan,
--// jalur jump dihaluskan, momentum udara distabilkan, dan timing tap-tap dirapikan.
--// Patch ini hanya jalan saat SAVE/MERGE. Record RAW dan playback live tidak diubah.
--// =========================================================
ANTI_KEDUT_REFERENCE_JUMP_ENABLED = true

--// Dari perbandingan checkpoint_1 vs checkpoint_2:
--// checkpoint_1 punya jeda ground antar spam jump lebih panjang.
--// checkpoint_2 biasanya hanya sekitar 4-6 frame ground sebelum jump berikutnya.
REF_JUMP_TARGET_GROUND_FRAMES = 7
REF_JUMP_MAX_SCAN_GROUND_FRAMES = 18
REF_JUMP_GAP_MAX_TIME = 0.20
REF_JUMP_GAP_MAX_DISTANCE = 13

--// Timing agar tap-tap cepat tapi tidak teleport kasar.
REF_JUMP_MIN_DT = 0.004
REF_JUMP_AIR_MAX_DT = 0.0195
REF_JUMP_GROUND_MAX_DT = 0.0145
REF_JUMP_NORMAL_MAX_DT = 0.034

--// Momentum udara dibuat stabil mengikuti speed map/coil yang sedang direkam.
REF_JUMP_MIN_AIR_HSPEED_RATIO = 0.86
REF_JUMP_MAX_AIR_HSPEED_RATIO = 1.24
REF_JUMP_MIN_GROUND_HSPEED_RATIO = 0.82
REF_JUMP_MIN_JUMP_Y_SPEED = 18

--// Smoothing kecil supaya kedut posisi/rotasi hasil record tidak ikut tajam.
REF_JUMP_SMOOTH_PASSES = 3
REF_JUMP_SMOOTH_NEIGHBOR_MAX_DIST = 6.5
REF_JUMP_ROT_SMOOTH_LIMIT = math.rad(70)

--// Tambahan smoothing supaya hasil yang awalnya kedut tidak patah saat disave.
REF_JUMP_ULTRA_SMOOTH_ENABLED = true
REF_JUMP_ULTRA_SMOOTH_PASSES = 1
REF_JUMP_ULTRA_POS_ALPHA = 0.16
REF_JUMP_ULTRA_Y_ALPHA_AIR = 0.06
REF_JUMP_ULTRA_ROT_ALPHA = 0.00
REF_JUMP_ULTRA_MAX_STEP_DIST = 7.5

--// MAP MATCH FIX:
--// Jangan paksa arah kiri/kanan/lurus dibuat dari path smoothing.
--// Di map obby/coil, arah udara asli ada di moveDirection/city/rotation.
--// Kalau ini di-overwrite, hasil play terasa beda dari map.
REF_JUMP_KEEP_MAP_AIR_CONTROL = true
REF_JUMP_KEEP_ORIGINAL_ROTATION = true
REF_JUMP_KEEP_ORIGINAL_CITY_DIR = true
REF_JUMP_MIN_MOTION_SPEED_KEEP = 8

--// =========================================================
--// PATCH ONIUM: RUNNING ANTI BLING / ANTI BLINK
--// Fokus fix: kadang saat PLAY hasil record lari ada blink/bling kecil.
--// Penyebab umum: frame lari terlalu jauh tapi timing terlalu pendek setelah clean/save.
--// Patch ini tidak mengubah sistem jump smoothing; hanya menjaga frame Running agar
--// jarak, timing, dan velocity tetap wajar sesuai speed map/coil.
--// =========================================================
RUN_ANTI_BLING_ENABLED = true
RUN_ANTI_BLING_MAX_STEP = 2.65            -- jarak antar frame Running yang aman sebelum ditambah bridge
RUN_ANTI_BLING_MAX_BRIDGE_DISTANCE = 18   -- di atas ini dianggap teleport/seam, jangan dipaksa bridge
RUN_ANTI_BLING_INSERT_MAX = 10            -- batas bridge per gap agar file tidak membesar berat
RUN_ANTI_BLING_MIN_DT = 0.0085            -- Running jangan terlalu padat waktunya
RUN_ANTI_BLING_MAX_DT = 0.050             -- Running tetap responsif, jangan terlalu lambat
RUN_ANTI_BLING_SPEED_CAP_MULT = 1.16      -- dt dihitung dari speed map/coil + toleransi
RUN_ANTI_BLING_KEEP_ROTATION = true

-- Safety visual saat playback: kalau masih ada gap aneh, jangan langsung blink jauh.
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

function refJumpIsShortGroundGap(frames, startIndex, endIndex, nextAirIndex)
    if not frames or not frames[startIndex] or not frames[endIndex] or not frames[nextAirIndex] then
        return false
    end

    local prevAir = frames[startIndex - 1]
    local nextAir = frames[nextAirIndex]
    if not prevAir or not refJumpIsAir(prevAir) or not refJumpIsAir(nextAir) then
        return false
    end

    local count = endIndex - startIndex + 1
    if count <= REF_JUMP_TARGET_GROUND_FRAMES then
        return false
    end
    if count > REF_JUMP_MAX_SCAN_GROUND_FRAMES then
        return false
    end

    for k = startIndex, endIndex do
        if refJumpIsHardProtected(frames[k]) then
            return false
        end
    end

    local gapTime = math.max(0, refJumpTime(nextAir) - refJumpTime(prevAir))
    local gapDist = antiKedutDist(prevAir, nextAir)

    return gapTime <= REF_JUMP_GAP_MAX_TIME and gapDist <= REF_JUMP_GAP_MAX_DISTANCE
end

function refJumpSampleGroundBlock(frames, startIndex, endIndex)
    local count = endIndex - startIndex + 1
    local keepCount = math.min(count, REF_JUMP_TARGET_GROUND_FRAMES)
    local selected = {}
    local selectedMap = {}

    local function addIndex(idx)
        idx = math.clamp(math.floor(idx + 0.5), startIndex, endIndex)
        if not selectedMap[idx] then
            selectedMap[idx] = true
            table.insert(selected, idx)
        end
    end

    if keepCount <= 1 then
        addIndex(endIndex)
    else
        for n = 1, keepCount do
            local alpha = (n - 1) / math.max(keepCount - 1, 1)
            addIndex(startIndex + ((count - 1) * alpha))
        end
    end

    --// Kalau ada putaran badan penting di tengah gap, simpan 1 frame itu agar tangga berputar tetap halus.
    local bestRot = 0
    local bestIndex = nil
    for i = startIndex + 1, endIndex - 1 do
        local rot = math.max(antiKedutYawDiff(frames[i - 1], frames[i]), antiKedutYawDiff(frames[i], frames[i + 1]))
        if rot > bestRot then
            bestRot = rot
            bestIndex = i
        end
    end
    if bestIndex and bestRot > math.rad(9) and #selected < REF_JUMP_TARGET_GROUND_FRAMES + 1 then
        addIndex(bestIndex)
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
            local startIndex = i
            local j = i
            while j <= #frames and frames[j] and not refJumpIsAir(frames[j]) do
                j = j + 1
            end

            if j <= #frames and refJumpIsShortGroundGap(frames, startIndex, j - 1, j) then
                local kept = refJumpSampleGroundBlock(frames, startIndex, j - 1)
                for _, item in ipairs(kept) do
                    table.insert(out, item)
                end
                removed = removed + ((j - startIndex) - #kept)
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
            local startIndex = i
            local j = i
            while j <= #frames and frames[j] and not refJumpIsAir(frames[j]) do
                j = j + 1
            end

            if j <= #frames then
                local prevAir = frames[startIndex - 1]
                local nextAir = frames[j]
                local gapTime = math.max(0, refJumpTime(nextAir) - refJumpTime(prevAir))
                local gapDist = antiKedutDist(prevAir, nextAir)
                if gapTime <= REF_JUMP_GAP_MAX_TIME and gapDist <= REF_JUMP_GAP_MAX_DISTANCE then
                    for k = startIndex, j - 1 do
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

    --// MAP MATCH:
    --// Smooth posisi boleh, tapi jangan ubah rotation/city/moveDirection.
    --// Kalau rotation ikut dismoothing, lompat lurus dan strafe kiri/kanan
    --// jadi terasa beda dengan gerakan map asli saat playback.
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
                        -- Air Y jangan terlalu diratakan, supaya tinggi lompat tetap sama map.
                        local y = cp.Y + ((sm.Y - cp.Y) * 0.18)
                        out[i].position = vecToTable(Vector3.new(sm.X, y, sm.Z))
                    else
                        -- Ground/tangga: Y tetap asli, hanya X/Z yang dilembutkan.
                        out[i].position = vecToTable(Vector3.new(sm.X, cp.Y, sm.Z))
                    end

                    -- Sengaja tidak ubah rotation.
                    -- Sengaja tidak ubah city/moveDirection.
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

                    -- MAP MATCH: rotation sengaja tidak diubah.
                    -- Rotation asli penting untuk lompat lurus, kiri-kanan, dan shift-lock.
                end
            end
        end
    end

    return out
end

function refJumpRebuildMoveDirectionFromPath(frames)
    --// MAP MATCH FIX:
    --// Versi sebelumnya menghitung ulang moveDirection/city dari path posisi.
    --// Itu bagus untuk membuang kedut, tapi merusak gerakan asli map saat
    --// lompat lurus, kiri, kanan, atau shift-lock.
    --// Jadi fungsi ini sekarang tidak overwrite arah gerak.
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

    local mobileJumpSafe = MOBILE_DELTA_JUMP_SAFE_MODE and framesLookMobileDeltaSafe(frames)
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

                -- Jangan ubah arah asli. Hanya bantu kalau speed terlalu jatuh
                -- akibat kedut record, supaya replay tidak terasa ketahan.
                local minRatio = refJumpIsAir(fr) and REF_JUMP_MIN_AIR_HSPEED_RATIO or REF_JUMP_MIN_GROUND_HSPEED_RATIO
                local minH = math.max(base * minRatio, ANTI_KEDUT_MIN_RUN_SPEED)
                local maxH = math.max(base * REF_JUMP_MAX_AIR_HSPEED_RATIO, minH)

                if mobileJumpSafe then
                    -- Mobile Delta: jangan paksa momentum lompat seperti PC.
                    -- Pertahankan velocity asli supaya jump tidak jadi nyentak/terlalu cepat.
                    if h <= 0.05 then
                        h = math.max(base * 0.72, ANTI_KEDUT_MIN_RUN_SPEED)
                    elseif h > maxH then
                        h = math.min(h, maxH)
                    end
                else
                    if h < minH then
                        h = minH
                    elseif h > maxH then
                        -- Cap lembut saja, jangan paksa terlalu rendah kalau coil/map memang cepat.
                        h = math.min(h, maxH)
                    end
                end

                local y = city.Y
                if refJumpIsAir(fr) then
                    local st = tostring(fr.states or fr.state or "")
                    if st == "Jumping" or fr.jump == true then
                        -- Jangan ubah arah lompat. Naikkan Y hanya kalau jelas jump naik tapi terlalu lemah.
                        if (not mobileJumpSafe) and y > 0 and y < REF_JUMP_MIN_JUMP_Y_SPEED then
                            y = REF_JUMP_MIN_JUMP_Y_SPEED
                        end
                        fr.jump = true
                        fr.states = "Jumping"
                    elseif st == "FallingDown" then
                        fr.states = "Freefall"
                    end
                else
                    -- Ground antar spam jump tetap ground, jangan dibuat air.
                    y = 0
                    fr.jump = false
                    fr.states = "Running"
                end

                -- moveDirection asli tetap disimpan kalau ada.
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

    local mobileJumpSafe = MOBILE_DELTA_JUMP_SAFE_MODE and framesLookMobileDeltaSafe(frames)
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
            local prevSource = frames[i - 1]
            local hd = antiKedutHDist(prev, fr)
            local vd = antiKedutVDist(prev, fr)
            local d = antiKedutDist(prev, fr)
            local hv = math.max(antiKedutHSpeed(prev), antiKedutHSpeed(fr), base)
            local yv = math.max(math.abs(antiKedutCity(prev).Y), math.abs(antiKedutCity(fr).Y), REF_JUMP_MIN_JUMP_Y_SPEED)
            local rawDt = (tonumber(frames[i].times) or tonumber(frames[i].t) or 0) - (tonumber(prevSource and (prevSource.times or prevSource.t)) or 0)
            local dt

            if mark[i] or mark[i - 1] or refJumpIsAir(prev) or refJumpIsAir(fr) then
                local hdt = (hd > 0.005) and (hd / math.max(hv, 1)) or REF_JUMP_MIN_DT
                local vdt = (vd > 0.005) and (vd / math.max(yv, 1)) or REF_JUMP_MIN_DT
                dt = math.max(hdt, vdt, REF_JUMP_MIN_DT)

                if mobileJumpSafe then
                    -- Mobile Delta FPS/timestamp lebih renggang. Jangan paksa dt 0.004-0.0195
                    -- seperti PC, karena itu bikin jump kelihatan speed-up/nyentak.
                    local rawSafe = rawDt > 0 and (rawDt * (MOBILE_DELTA_KEEP_RAW_DT_RATIO or 0.85)) or dt
                    dt = math.max(dt, rawSafe)

                    if refJumpIsAir(prev) or refJumpIsAir(fr) then
                        dt = math.clamp(dt, MOBILE_DELTA_AIR_MIN_DT or 0.010, MOBILE_DELTA_AIR_MAX_DT or 0.045)
                    else
                        dt = math.clamp(dt, MOBILE_DELTA_GROUND_MIN_DT or 0.0085, MOBILE_DELTA_GROUND_MAX_DT or 0.030)
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
                if mobileJumpSafe and rawDt > 0 then
                    dt = math.max(dt, rawDt * (MOBILE_DELTA_KEEP_RAW_DT_RATIO or 0.85))
                    dt = math.clamp(dt, ANTI_KEDUT_MIN_DT, MOBILE_DELTA_NORMAL_MAX_DT or 0.055)
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
        tonumber(a and a.walkSpeed) or 0,
        tonumber(b and b.walkSpeed) or 0,
        tonumber(fallback) or 0,
        ANTI_KEDUT_MIN_RUN_SPEED or 8
    )
    return math.clamp(speed, ANTI_KEDUT_MIN_RUN_SPEED or 8, MAX_PLAYBACK_SPEED or 500000)
end

function runAntiBlingInterpolateFrame(a, b, alpha, baseSpeed)
    local copy = deepCopy((alpha < 0.5 and a) or b)
    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    local pos = pa:Lerp(pb, alpha)

    local yawA = tonumber(a and a.rotation) or 0
    local yawB = tonumber(b and b.rotation) or yawA
    local yaw = lerpAngle(yawA, yawB, alpha)

    local dir = runAntiBlingFlatDir(a, b)
    local speed = runAntiBlingBaseSpeedFromPair(a, b, baseSpeed)

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
    copy.ground = nil -- bridge frame tidak perlu raycast ground baru; save jadi ringan
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

            -- Running datar/naik turun kecil saja yang di-bridge.
            -- Kalau VD besar, biasanya tangga/jump/landing; biarkan patch jump yang handle.
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
            if oldDt <= 0 then oldDt = SAMPLE_INTERVAL or 0.004 end

            local dt = oldDt

            if runAntiBlingIsRunning(prevOut) and runAntiBlingIsRunning(fr) then
                local hd = antiKedutHDist(prevOut, fr)
                local safeSpeed = runAntiBlingBaseSpeedFromPair(prevOut, fr, base) * (RUN_ANTI_BLING_SPEED_CAP_MULT or 1.16)
                local needDt = (hd > 0.005) and (hd / math.max(safeSpeed, 1)) or (RUN_ANTI_BLING_MIN_DT or 0.0085)

                -- Jangan biarkan Running terlalu pendek waktunya, karena itu sumber bling.
                dt = math.max(oldDt, needDt, RUN_ANTI_BLING_MIN_DT or 0.0085)
                dt = math.clamp(dt, RUN_ANTI_BLING_MIN_DT or 0.0085, RUN_ANTI_BLING_MAX_DT or 0.05)
            else
                -- Jump/tangga tetap pakai timing patch jump, jangan dibuat lambat.
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

    local removedGap = 0
    frames, removedGap = refJumpCompressGroundGaps(frames)
    frames = refJumpSmoothPositions(frames)
    frames = refJumpUltraSmoothChains(frames)
    frames = refJumpStabilizeMomentum(frames)

    if compactTime ~= false then
        frames = refJumpCompactTimes(frames)
    end

    -- MAP MATCH: arah/city/rotation asli dipertahankan; fungsi ini sekarang no-op agar kiri-kanan/lurus tetap sama map.
    frames = refJumpRebuildMoveDirectionFromPath(frames)

    return frames, removedGap
end

function cleanFramesForSaveMerge(inputFrames, compactTime)
    local frames = basicNormalizeFrames(inputFrames) or inputFrames
    if type(frames) ~= "table" or #frames <= 0 then return {}, 0 end

    if EXPORT_RAW_EXACT_MODE and RAW_EXACT_SAVE_WITHOUT_HEAVY_CLEANER then
        return prepareRawExactFramesForSave(frames)
    end

    local before = #frames
    local removedA = 0
    local removedB = 0
    local removedJump = 0

    --// Mobile Delta: koreksi state jump/freefall dari velocity sebelum cleaner berat.
    frames = mobileDeltaFixAirStateByVelocity(frames)

    frames = antiKedutTrimEdges(frames)
    frames, removedA = antiKedutCleanInternal(frames)

    frames = antiKedutTrimEdges(frames)
    frames, removedB = antiKedutCleanInternal(frames)

    --// Rotasi yang berubah saat idle tetap dihaluskan.
    frames = antiKedutSmoothIdleRotation(frames)

    --// FIX CEKPOINT 1 -> CEKPOINT 2:
    --// 1) gap ground antar spam jump dipadatkan seperti checkpoint_2,
    --// 2) jalur jump yang kedut dismoothing,
    --// 3) momentum udara/ground distabilkan,
    --// 4) timing save dibuat tap-tap cepat.
    frames, removedJump = refJumpOptimizer(frames, compactTime)

    --// FIX BLING SAAT LARI:
    --// Setelah frame kedut dibuang, kadang jarak Running jadi jauh tetapi times pendek.
    --// Ini menambah bridge frame dan melonggarkan timing Running seperlunya.
    local addedRunBridge = 0
    frames, addedRunBridge = runAntiBlingInsertBridges(frames)
    if compactTime ~= false then
        frames = runAntiBlingRetuneTimes(frames)
    end

    --// AUTO MAP: kedut tetap dibersihkan, lalu speed normal map/coil dikunci otomatis.
    --// Ini mencegah speed turun saat belok/mundur tanpa hardcode angka speed map.
    local speedFixed = 0
    local normalMapSpeed = nil
    frames, speedFixed, normalMapSpeed = autoMapCleanSpeedForSave(frames)

    local removed = math.max(0, before - #frames)
        + (tonumber(removedA) or 0)
        + (tonumber(removedB) or 0)
        + (tonumber(removedJump) or 0)

    return frames, removed
end

--// =========================================================
--// Save / Load / Delete
--// =========================================================

saveTemporaryRecord = function()
    -- RAW EXACT: hasil save/upload tetap mengikuti record asli dari map/coil.
    if not temporaryRecord or #temporaryRecord <= 0 then
        notify("Save", "Belum ada record. Tekan RECORD lalu STOP dulu.", 3)
        return
    end

    local name = cleanFileName(saveNameBox and saveNameBox.Text or "")

    if name == "" or name == "checkpoint" then
        name = getNextDefaultName()
    end

    -- SAVE harus tetap menghapus kedut seperti versi sebelumnya.
    -- Setelah bersih, auto map speed akan mengunci speed normal map/coil secara dinamis.
    local frames, removed = cleanFramesForSaveMerge(temporaryRecord, true)

    if not frames or #frames <= 0 then
        notify("Save", "Frame kosong setelah clean", 3)
        return
    end

    local ok, msg, path = saveFramesToFile(name, frames)

    local added = upsertCheckpoint(name, frames, false, path)

    --// Jangan render tulisan/titik CP saat save kalau mode marker OFF.
    --// Ini yang biasanya bikin save terasa lama/freeze.
    if CP_MARKER_ENABLED then
        task.defer(refreshCheckpointMarkers)
    end

    temporaryRecord = {}

    if saveNameBox then
        saveNameBox.Text = ""
    end

    if searchBox then
        searchBox.Text = ""
    end

    if refreshList then
        refreshList()
        task.defer(function()
            refreshList()
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

importLoad = function()
    local loadedCount = 0

    if safeFunc(listfiles) and safeFunc(readfile) then
        loadedCount = refreshFromFiles()
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
                loadedCount = loadedCount + 1
                notify("Import", "JSON clipboard masuk sebagai " .. name, 3)
            end
        end
    end

    refreshList()

    if loadedCount > 0 then
        notify("Load", "Berhasil load " .. tostring(loadedCount) .. " JSON", 3)
    else
        notify("Load", "Tidak ada JSON valid ditemukan", 3)
    end
end

deleteAllCheckpoints = function()
    for _, cp in ipairs(checkpoints) do
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

    checkpoints = {}
    nextOrder = 1
    clearMergeDots()
    clearCheckpointMarkers()
    refreshList()
    notify("Del All", "Semua checkpoint dihapus", 3)
end
refreshList = function()
    if not listFrame then
        return
    end

    --// Hapus item lama, tapi jangan hapus UIListLayout / UIPadding / UICorner / UIStroke
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local keyword = ""
    if searchBox then
        keyword = tostring(searchBox.Text or ""):lower()
    end

    table.sort(checkpoints, function(a, b)
        return (a.order or 9999) < (b.order or 9999)
    end)

    local shown = 0

    for _, cp in ipairs(checkpoints) do
        local name = tostring(cp.name or "checkpoint")
        local frameCount = 0

        if type(cp.frames) == "table" then
            frameCount = #cp.frames
        end

        local match = keyword == "" or name:lower():find(keyword, 1, true) ~= nil

        if match then
            shown = shown + 1

            local row = Instance.new("Frame")
            row.Name = "CheckpointItem_" .. name
            row.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
            row.Size = UDim2.new(1, -2, 0, 30)
            row.LayoutOrder = shown
            row.Parent = listFrame
            addCorner(row, 10)
            addStroke(row, Color3.fromRGB(70, 70, 95), 0.35)

            local playBtn = Instance.new("TextButton")
            playBtn.Name = "Play_" .. name
            playBtn.BackgroundTransparency = 1
            playBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
            playBtn.Font = Enum.Font.GothamBold
            playBtn.TextSize = 9
            playBtn.TextXAlignment = Enum.TextXAlignment.Left
            playBtn.Text = name .. " (" .. tostring(frameCount) .. " frame)"
            playBtn.Size = UDim2.new(1, -64, 1, 0)
            playBtn.Position = UDim2.fromOffset(10, 0)
            playBtn.Parent = row

            local markBtn = Instance.new("TextButton")
            markBtn.Name = "Marker_" .. name
            markBtn.BackgroundColor3 = (CP_MARKER_ENABLED and CP_MARKER_SELECTED_NAME == name)
                and Color3.fromRGB(55, 120, 80)
                or Color3.fromRGB(55, 55, 75)
            markBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            markBtn.Font = Enum.Font.GothamBold
            markBtn.TextSize = 9
            markBtn.Text = (CP_MARKER_ENABLED and CP_MARKER_SELECTED_NAME == name) and "✓" or "M"
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
                playCheckpoint(cp)
            end)

            bindButton(markBtn, function()
                toggleSingleCheckpointMarker(cp)
                refreshList()
            end)

            bindButton(delBtn, function()
                --// Hapus file kalau ada
                if cp.path then
                    deleteFile(cp.path)
                else
                    deleteFile(filePathForName(cp.name))
                end

                --// Hapus dari memory checkpoints
                for i = #checkpoints, 1, -1 do
                    if checkpoints[i] == cp or checkpoints[i].name == cp.name then
                        table.remove(checkpoints, i)
                        break
                    end
                end

                if CP_MARKER_ENABLED then
                    task.defer(refreshCheckpointMarkers)
                end

                refreshList()
                notify("Delete", name .. " dihapus", 2)
            end)
        end
    end

    if listFrame and listLayout then
        listFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 14)
    end
end
--// =========================================================
--// Merge Smooth + Clean Idle - FIX NO KEDUT / NO STOP JOIN
--// =========================================================

-- Buang frame pelan/diam di awal dan akhir checkpoint.
-- Ini khusus buat hasil merge supaya sambungan CP1 -> CP2 langsung lari.

--// =========================================================
--// FORCE RUNNING JOIN V2: sambungan CP langsung lari, tidak start/stop.
--// Tidak clamp ke 45; pakai speed asli record/coil supaya tidak ngaco.
--// =========================================================
--// =========================================================
--// MERGE ANTI SPEED SPIKE PATCH 2026-05-13
--// Penyebab bug: sambungan CP kadang diberi dt 0.004, padahal jaraknya masih
--// beberapa stud. Replay membaca itu sebagai speed besar sepersekian detik.
--// Patch ini membuat dt sambungan dan dt final dihitung dari jarak / speed normal.
--// =========================================================
local MERGE_ANTI_SPIKE_ENABLED = true
local MERGE_ANTI_SPIKE_SPEED_CAP_MULT = 1.08
local MERGE_ANTI_SPIKE_MIN_DT = 0.0065
local MERGE_ANTI_SPIKE_MAX_DT = 0.180
local MERGE_ANTI_SPIKE_JOIN_MAX_DT = 1.250

function mergeAntiSpikeFrameTime(fr)
    return tonumber(fr and fr.times) or tonumber(fr and fr.t) or 0
end

function mergeAntiSpikePairSpeed(a, b, fallback)
    local spd = math.max(
        antiKedutHSpeed(a),
        antiKedutHSpeed(b),
        tonumber(a and a.walkSpeed) or 0,
        tonumber(b and b.walkSpeed) or 0,
        tonumber(a and a.ws) or 0,
        tonumber(b and b.ws) or 0,
        tonumber(fallback) or 0,
        MIN_PLAYBACK_SPEED or 8
    )

    if spd <= 0 then
        spd = autoMapDetectNormalRunSpeed({ a, b }) or DEFAULT_PLAYBACK_SPEED
    end

    return math.clamp(spd, MIN_PLAYBACK_SPEED or 8, MAX_PLAYBACK_SPEED or 500000)
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

function estimateMergeJoinDt(previousFrame, newFrame, distOverride)
    if not MERGE_ANTI_SPIKE_ENABLED then
        return CLEAN_MIN_TIMING_GAP or 0.004
    end

    local dist, hd = mergeAntiSpikeDistance(previousFrame, newFrame)
    dist = tonumber(distOverride) or dist or 0

    if dist <= (MERGE_SKIP_JOIN_DISTANCE or 0.35) then
        return CLEAN_MIN_TIMING_GAP or 0.004
    end

    local baseSpeed = mergeAntiSpikePairSpeed(previousFrame, newFrame, nil)
    local safeSpeed = math.max(baseSpeed * (MERGE_ANTI_SPIKE_SPEED_CAP_MULT or 1.08), 1)
    local needDt = math.max(dist, hd or 0) / safeSpeed

    return math.clamp(needDt, MERGE_ANTI_SPIKE_MIN_DT or 0.0065, MERGE_ANTI_SPIKE_JOIN_MAX_DT or 1.25)
end

function mergeAntiSpikeRetuneTimes(frames)
    if not MERGE_ANTI_SPIKE_ENABLED then
        return frames
    end

    frames = basicNormalizeFrames(frames) or frames or {}
    if #frames <= 1 then
        return frames
    end

    local baseSpeed = autoMapDetectNormalRunSpeed(frames) or antiKedutBaseSpeed(frames) or DEFAULT_PLAYBACK_SPEED
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
                dt = MERGE_ANTI_SPIKE_MIN_DT or 0.0065
            end

            if (isJoin or isRunGap) and dist > 0.005 then
                local pairSpeed = mergeAntiSpikePairSpeed(prevOut, fr, baseSpeed)
                local safeSpeed = math.max(pairSpeed * (MERGE_ANTI_SPIKE_SPEED_CAP_MULT or 1.08), 1)
                local needDt = hd / safeSpeed

                if isJoin then
                    needDt = math.max(needDt, dist / safeSpeed)
                end

                if dt < needDt then
                    dt = needDt
                end

                if isJoin then
                    dt = math.min(dt, math.max(MERGE_ANTI_SPIKE_JOIN_MAX_DT or 1.25, needDt))
                elseif vd <= 1.5 then
                    dt = math.min(dt, math.max(MERGE_ANTI_SPIKE_MAX_DT or 0.18, needDt))
                end
            end

            dt = math.max(dt, MERGE_ANTI_SPIKE_MIN_DT or 0.0065)
            t = t + dt
        end

        fr.times = roundNumber(t, 9)
        fr.t = fr.times
        table.insert(out, fr)
    end

    return out
end

mergeCheckpoints = function()
    local normal = {}

    for _, cp in ipairs(checkpoints) do
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
    local mergedCount = 0
    local cutJoin = 0
    local removedTotal = 0
    local timeCursor = 0
    local previousFrame = nil

    clearMergeDots()

    for _, cp in ipairs(normal) do
        local frames, removed = cleanFramesForSaveMerge(cp.frames, true)
        removedTotal = removedTotal + (removed or 0)

        if frames and #frames > 0 then
            mergedCount = mergedCount + 1

            -- Buang idle awal/akhir sekali lagi khusus sambungan CP.
            frames = trimIdleStartEnd(frames)
            frames = compactCleanTimes(frames)

            local firstT = tonumber(frames[1].times) or tonumber(frames[1].t) or 0
            local lastLocalT = 0

            for i = 1, #frames do
                local newFrame = deepCopy(frames[i])
                local rawT = tonumber(newFrame.times) or tonumber(newFrame.t) or 0
                local localT = rawT - firstT

                if i > 1 and localT <= lastLocalT then
                    localT = lastLocalT + CLEAN_MIN_TIMING_GAP
                end

                if previousFrame and i == 1 then
                    createMergeDotPath(
                        mergedCount,
                        cp.name or ("checkpoint_" .. tostring(mergedCount)),
                        tableToVec(previousFrame.position),
                        tableToVec(newFrame.position)
                    )

                    local dist = (tableToVec(newFrame.position) - tableToVec(previousFrame.position)).Magnitude
                    newFrame.__mergeJoin = true
                    newFrame.__mergeJoinDistance = roundNumber(dist, 9)

                    -- PATCH MERGE SPEED: jangan biarkan CP baru mulai hanya 0.004 detik
                    -- setelah CP sebelumnya kalau jaraknya masih beberapa stud.
                    local prevTime = tonumber(previousFrame.times) or tonumber(previousFrame.t) or (timeCursor - (CLEAN_MIN_TIMING_GAP or 0.004))
                    local joinDt = estimateMergeJoinDt(previousFrame, newFrame, dist)
                    timeCursor = prevTime + math.max(joinDt, CLEAN_MIN_TIMING_GAP or 0.004)
                    localT = 0

                    if dist > MERGE_MAX_BRIDGE_DISTANCE then
                        -- Jarak jauh: tetap tandai seam, tapi timing tetap dibuat aman agar JSON tidak speed spike.
                        newFrame.seam = true
                        cutJoin = cutJoin + 1
                    else
                        -- Jarak dekat: tidak pakai hold/idle, langsung lanjut lari dengan timing aman.
                        newFrame.seam = false
                        newFrame.cutNext = false
                    end
                end

                -- Jangan ubah city/momentum/rotation/walkSpeed. Hanya waktu yang dipadatkan aman.
                newFrame.times = roundNumber(timeCursor + localT, 9)
                newFrame.t = newFrame.times

                table.insert(merged, newFrame)
                previousFrame = newFrame
                lastLocalT = localT
            end

            timeCursor = (tonumber(merged[#merged].times) or timeCursor) + CLEAN_MIN_TIMING_GAP
        end
    end

    if #merged <= 0 then
        notify("Merge", "Merge gagal, frame kosong", 3)
        return
    end

    -- Clean final untuk hapus duplikat kecil yang muncul antar CP, tetap tanpa ubah momentum.
    merged = cleanFramesForSaveMerge(merged, true)

    -- PATCH MERGE SPEED: final pass setelah cleaner, karena cleaner bisa memadatkan timing lagi.
    merged = mergeAntiSpikeRetuneTimes(merged)

    local ok, msg, path = saveFramesToFile("merged_record", merged)
    upsertCheckpoint("merged_record", merged, true, path)

    if CP_MARKER_ENABLED then
        task.defer(refreshCheckpointMarkers)
    end

    local dotCount = countMergeDots()

    if ok then
        notify(
            "Merge",
            "merged_record bersih: " .. tostring(mergedCount)
                .. " file | hapus " .. tostring(removedTotal)
                .. " idle/kedut | cut " .. tostring(cutJoin)
                .. " | titik " .. tostring(dotCount),
            4
        )
    else
        notify("Merge", "Merge masuk memory. " .. tostring(msg) .. " | titik " .. tostring(dotCount), 4)
    end
end

--// =========================================================
--// UI Events
--// =========================================================

bindButton(RecordBtn, function()
    --// FIX: reset humanoid state sebelum record baru,
    --// supaya sisa state dari playback sebelumnya (AutoRotate, Jump,
    --// PlatformStand, velocity) tidak bocor ke recording baru.
    local startedGrounded = true
    pcall(function()
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        local char = lp and lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum then
                hum.Jump = false
                hum.PlatformStand = false
                hum.AutoRotate = true
                local stName = tostring(hum:GetState().Name or "")
                if stName == "Freefall" or stName == "Jumping" or stName == "FallingDown" then
                    startedGrounded = false
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
    --// Beri waktu map re-apply ShiftLock / kamera-nya
    task.wait(0.05)
    startRecording()

    --// FIX MOBILE SHIFTLOCK JUMP BUG:
    --// Di HP, tap tombol Record sering "tembus" ke tombol Jump bawaan
    --// Roblox (apalagi saat ShiftLock aktif), sehingga Humanoid.Jump ke-trigger
    --// tepat setelah recording mulai => lompat tinggi tidak terkendali.
    --// Solusi: peredam jump ~0.35 detik di awal recording.
    pcall(function()
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        local suppressUntil = os.clock() + 0.35
        local conn
        conn = addConnection(RunService.Heartbeat:Connect(function()
            if os.clock() >= suppressUntil or not isRecording then
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
                if startedGrounded and (stName == "Jumping" or stName == "Freefall") then
                    pcall(function()
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                end
            end
            if hrp and startedGrounded then
                local v = hrp.AssemblyLinearVelocity
                if v.Y > 0 then
                    hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                end
            end
        end))
    end)
end)

bindButton(SetSpeedBtn, function()
    setSpeedFromCurrent()
end)

bindButton(StopPlayBtn, function()
    stopPlayback(true)
end)

bindButton(SaveBtn, function()
    saveTemporaryRecord()
end)

bindButton(cpMarkerToggleBtn, function()
    toggleCheckpointMarkersAll()
    refreshList()
end)

bindButton(DeleteAllBtn, function()
    deleteAllCheckpoints()
end)

bindButton(ImportBtn, function()
    importLoad()
end)

bindButton(RefreshBtn, function()
    local count = refreshFromFiles()
    refreshList()
    notify("Refresh", "Refresh selesai. File terbaca: " .. tostring(count), 3)
end)

bindButton(MergeBtn, function()
    mergeCheckpoints()
end)

addConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    refreshList()
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
    stopRecording()
end)

bindButton(RollbackBtn, function()
    rollbackRecording()
end)

bindButton(MinBtn, function()
    MainFrame.Visible = false
    MiniLogo.Visible = true
end)

bindButton(MiniLogo, function()
    MiniLogo.Visible = false
    MainFrame.Visible = true
end)

bindButton(CloseBtn, function()
    cleanup()
end)

--// =========================================================
--// Initial Load
--// =========================================================

if refreshList then
    refreshList()
end

task.spawn(function()
    task.wait(0.5)

    ensureFolder()

    if safeFunc(listfiles) and safeFunc(readfile) then
        local count = refreshFromFiles()

        if refreshList then
            refreshList()
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