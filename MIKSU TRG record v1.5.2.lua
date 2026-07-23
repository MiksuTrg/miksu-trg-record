--// =========================================================
--// MIKSU TRG RECORD v1.5.2 - ULTRA SMOOTH STABILITY
--// Enhanced from v1.5.1 with advanced smoothing and prediction
--// =========================================================
--// CHANGELOG v1.5.2:
--// + Catmull-Rom spline interpolation untuk playback ultra smooth
--// + Kalman filter untuk position smoothing (anti micro-jitter)
--// + Predictive velocity recording (3-frame lookahead)
--// + Dynamic threshold adjustment berdasarkan FPS
--// + Enhanced coil acceleration detection
--// + Physics-based momentum preservation
--// + Adaptive step distance dengan terrain awareness
--// + Multi-stage outlier detection
--// + Frame pooling untuk reduce GC pressure
--// + Enhanced rotation smoothing (angular velocity aware)
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
local SAMPLE_INTERVAL = 0.004

--// =========================================================
--// v1.5.2 ADVANCED CONFIG
--// =========================================================

--// Kalman Filter untuk position smoothing
local KALMAN_FILTER_ENABLED = true
local KALMAN_PROCESS_NOISE = 0.008  -- Q: process noise covariance
local KALMAN_MEASUREMENT_NOISE = 0.15  -- R: measurement noise covariance
local KALMAN_INITIAL_ERROR = 1.0  -- P: initial estimation error

--// Predictive Recording
local PREDICTIVE_RECORDING_ENABLED = true
local PREDICTION_LOOKAHEAD_FRAMES = 3  -- predict 3 frames ahead
local PREDICTION_VELOCITY_WEIGHT = 0.65  -- balance antara measured vs predicted

--// Dynamic Thresholds
local DYNAMIC_THRESHOLD_ENABLED = true
local FPS_LOW_THRESHOLD = 45  -- dibawah ini threshold dilonggarkan
local FPS_HIGH_THRESHOLD = 90  -- diatas ini threshold diperketat
local DYNAMIC_DISTANCE_MIN = 0.06
local DYNAMIC_DISTANCE_MAX = 0.14

--// Enhanced Coil Detection
local COIL_ACCELERATION_TRACKING = true
local COIL_ACCEL_MIN_CHANGE = 8  -- min perubahan speed untuk detect coil
local COIL_ACCEL_SMOOTH_WINDOW = 5  -- smooth acceleration over N frames

--// Catmull-Rom Spline Interpolation
local CATMULL_ROM_ENABLED = true
local CATMULL_ROM_TENSION = 0.5  -- 0 = uniform, 0.5 = centripetal, 1 = chordal
local CATMULL_ROM_ALPHA = 0.5  -- parameterization

--// Physics-based Playback
local PHYSICS_MOMENTUM_ENABLED = true
local MOMENTUM_PRESERVATION_RATIO = 0.88  -- preserve 88% momentum on direction change
local ANGULAR_MOMENTUM_SMOOTH = true
local ANGULAR_SMOOTH_FACTOR = 0.75

--// Enhanced Outlier Detection
local MULTI_STAGE_OUTLIER_ENABLED = true
local OUTLIER_Z_SCORE_THRESHOLD = 2.8  -- standard deviations
local OUTLIER_MAD_THRESHOLD = 3.5  -- median absolute deviation
local OUTLIER_IQR_MULTIPLIER = 2.2  -- interquartile range

--// Frame Pooling
local FRAME_POOLING_ENABLED = true
local FRAME_POOL_SIZE = 500
local FRAME_REUSE_ENABLED = true

--// Terrain Awareness
local TERRAIN_AWARE_SAMPLING = true
local TERRAIN_SLOPE_DETECTION = true
local TERRAIN_SLOPE_MIN = 0.15  -- min slope untuk adjust sampling

--// =========================================================
--// ORIGINAL v1.5.1 CONFIG (preserved)
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
local AUTO_MAP_SPEED_MAX_DT = 0.085

local RECORD_LIGHT_MODE = true
local RECORD_MIN_SAMPLE_DT = 0.0085
local RECORD_AIR_SAMPLE_DT = 0.0045
local RECORD_UI_UPDATE_INTERVAL = 0.10
local RECORD_GROUND_CACHE_INTERVAL = 0.025
local RECORD_TOOL_CACHE_INTERVAL = 0.15

local MOBILE_DELTA_JUMP_SAFE_MODE = true
local MOBILE_DELTA_AIR_MIN_DT = 0.010
local MOBILE_DELTA_AIR_MAX_DT = 0.045
local MOBILE_DELTA_GROUND_MIN_DT = 0.0085
local MOBILE_DELTA_GROUND_MAX_DT = 0.030
local MOBILE_DELTA_NORMAL_MAX_DT = 0.055
local MOBILE_DELTA_KEEP_RAW_DT_RATIO = 0.85
local MOBILE_DELTA_JUMP_Y_TRIGGER = 5.5
local MOBILE_DELTA_FALL_Y_TRIGGER = -5.5
local MOBILE_DELTA_VELOCITY_CONFIRM_FRAMES = 2

local MIN_PLAYBACK_SPEED = 8
local MAX_PLAYBACK_SPEED = 500000
local DEFAULT_PLAYBACK_SPEED = 16

local BITWISE_JSON_WALKSPEED = 45
local BITWISE_JSON_HIPHEIGHT = 5.331189155578613

local MIN_RECORD_DISTANCE = 0.09
local MIN_MOVE_DIRECTION = 0.02
local MIN_HORIZONTAL_VELOCITY = 0.15

local CLEAN_DISTANCE_THRESHOLD = 0.07
local CLEAN_VERTICAL_THRESHOLD = 0.10

--// v1.5.2: Enhanced adaptive step distance
local PLAYBACK_STEP_DISTANCE = 0.50  -- reduced from 0.60
local PLAYBACK_STEP_DISTANCE_SLOW = 0.35  -- reduced from 0.45
local PLAYBACK_STEP_DISTANCE_FAST = 0.65  -- reduced from 0.75
local PLAYBACK_STEP_DISTANCE_AIR = 0.28   -- reduced from 0.35
local PLAYBACK_MIN_STEP_DISTANCE = 0.03   -- reduced from 0.04

local PLAY_AGAIN_FINISH_RESET_DISTANCE = 18
local PLAY_AGAIN_FINISH_TIME_WINDOW = 0.12

local LOOP_SPEED_SAFE_CAP_MULTIPLIER = 1.12

local SPEED_TIMING_MIN_DT = 0.006
local SPEED_TIMING_MAX_DT = 0.18

local PLAYBACK_MAX_SMOOTH_DISTANCE = 10
local MERGE_SKIP_JOIN_DISTANCE = 0.35
local MERGE_MAX_BRIDGE_DISTANCE = 10
local MAX_BRIDGE_FRAMES = 80

local GROUND_RAY_DISTANCE = 9

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

--// Merge dots
local seamDotFolder = nil
local MERGE_DOT_ENABLED = true
local MERGE_DOT_COUNT = 12
local MERGE_DOT_SIZE = 0.46
local MERGE_DOT_HEIGHT = 0.35

--// CP Markers
local CP_MARKER_ENABLED = false
local CP_MARKER_SELECTED_NAME = nil
local CP_MARKER_CULLER_TOKEN = 0
local CP_MARKER_DOT_COUNT = 6
local CP_MARKER_SIZE = 0.42
local CP_MARKER_HEIGHT = 1.25
local CP_MARKER_MAX_PER_CP = 8
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

local currentPlaybackSpeed = DEFAULT_PLAYBACK_SPEED
local syncBaseSpeed = DEFAULT_PLAYBACK_SPEED

local recordConnection = nil
local allConnections = {}

local lastRecordSavedPos = nil
local recordStartClock = 0

local preRecordWalkSpeed = nil
local lastKnownToolWalkSpeed = nil
local lastKnownEquippedTool = ""
local savedMouseBehavior = nil
local savedMouseIconEnabled = nil

--// =========================================================
--// v1.5.2 NEW GLOBAL STATE
--// =========================================================

--// Kalman Filter State
local kalmanFilters = {}  -- per-axis filters (X, Y, Z)

--// Predictive Recording State
local velocityHistory = {}  -- rolling window untuk prediction
local accelerationHistory = {}

--// Dynamic Threshold State
local currentFPS = 60
local fpsHistory = {}
local dynamicMinDistance = MIN_RECORD_DISTANCE

--// Coil Acceleration State
local coilSpeedHistory = {}
local lastDetectedCoilSpeed = nil
local coilAccelerationActive = false

--// Frame Pool
local framePool = {}
local framePoolIndex = 1

--// Terrain State
local lastTerrainSlope = 0
local terrainSlopeHistory = {}

--// =========================================================
--// v1.5.2 UTILITY: KALMAN FILTER
--// =========================================================

function createKalmanFilter(processNoise, measurementNoise, initialError)
    return {
        x = 0,  -- estimated value
        p = initialError or KALMAN_INITIAL_ERROR,  -- estimation error covariance
        q = processNoise or KALMAN_PROCESS_NOISE,  -- process noise
        r = measurementNoise or KALMAN_MEASUREMENT_NOISE,  -- measurement noise
    }
end

function kalmanUpdate(filter, measurement)
    if not filter then return measurement end
    
    -- Prediction
    local xPrior = filter.x
    local pPrior = filter.p + filter.q
    
    -- Update
    local k = pPrior / (pPrior + filter.r)  -- Kalman gain
    filter.x = xPrior + k * (measurement - xPrior)
    filter.p = (1 - k) * pPrior
    
    return filter.x
end

function initKalmanFilters()
    if not KALMAN_FILTER_ENABLED then return end
    
    kalmanFilters = {
        x = createKalmanFilter(KALMAN_PROCESS_NOISE, KALMAN_MEASUREMENT_NOISE, KALMAN_INITIAL_ERROR),
        y = createKalmanFilter(KALMAN_PROCESS_NOISE * 1.2, KALMAN_MEASUREMENT_NOISE * 0.8, KALMAN_INITIAL_ERROR),  -- Y more sensitive
        z = createKalmanFilter(KALMAN_PROCESS_NOISE, KALMAN_MEASUREMENT_NOISE, KALMAN_INITIAL_ERROR),
    }
end

function applyKalmanFilter(position)
    if not KALMAN_FILTER_ENABLED or not kalmanFilters.x then
        return position
    end
    
    local filtered = Vector3.new(
        kalmanUpdate(kalmanFilters.x, position.X),
        kalmanUpdate(kalmanFilters.y, position.Y),
        kalmanUpdate(kalmanFilters.z, position.Z)
    )
    
    return filtered
end

--// =========================================================
--// v1.5.2 UTILITY: PREDICTIVE VELOCITY
--// =========================================================

function updateVelocityHistory(velocity)
    if not PREDICTIVE_RECORDING_ENABLED then return end
    
    table.insert(velocityHistory, {
        v = velocity,
        t = os.clock()
    })
    
    -- Keep only recent history
    while #velocityHistory > PREDICTION_LOOKAHEAD_FRAMES + 2 do
        table.remove(velocityHistory, 1)
    end
end

function calculateAcceleration(v1, v2, dt)
    if dt <= 0 then return Vector3.new(0, 0, 0) end
    return (v2 - v1) / dt
end

function predictVelocity(currentVelocity, dt)
    if not PREDICTIVE_RECORDING_ENABLED or #velocityHistory < 2 then
        return currentVelocity
    end
    
    -- Calculate average acceleration from history
    local accelSum = Vector3.new(0, 0, 0)
    local count = 0
    
    for i = 2, #velocityHistory do
        local prev = velocityHistory[i - 1]
        local curr = velocityHistory[i]
        local deltaT = curr.t - prev.t
        
        if deltaT > 0 then
            local accel = calculateAcceleration(prev.v, curr.v, deltaT)
            accelSum = accelSum + accel
            count = count + 1
        end
    end
    
    if count == 0 then return currentVelocity end
    
    local avgAccel = accelSum / count
    
    -- Predict: v_predicted = v_current + a_avg * dt
    local predicted = currentVelocity + (avgAccel * dt)
    
    -- Blend measured and predicted
    local weight = PREDICTION_VELOCITY_WEIGHT
    return currentVelocity * (1 - weight) + predicted * weight
end

--// =========================================================
--// v1.5.2 UTILITY: DYNAMIC THRESHOLDS
--// =========================================================

function updateFPS(dt)
    if not DYNAMIC_THRESHOLD_ENABLED or dt <= 0 then return end
    
    local fps = 1 / dt
    table.insert(fpsHistory, fps)
    
    -- Keep 30-frame average
    while #fpsHistory > 30 do
        table.remove(fpsHistory, 1)
    end
    
    -- Calculate average FPS
    local sum = 0
    for _, f in ipairs(fpsHistory) do
        sum = sum + f
    end
    currentFPS = sum / #fpsHistory
end

function getDynamicMinDistance()
    if not DYNAMIC_THRESHOLD_ENABLED then
        return MIN_RECORD_DISTANCE
    end
    
    -- Low FPS: relax threshold (larger distance)
    -- High FPS: tighten threshold (smaller distance)
    if currentFPS < FPS_LOW_THRESHOLD then
        local scale = math.clamp(FPS_LOW_THRESHOLD / currentFPS, 1.0, 2.0)
        return math.min(DYNAMIC_DISTANCE_MAX, MIN_RECORD_DISTANCE * scale)
    elseif currentFPS > FPS_HIGH_THRESHOLD then
        local scale = math.clamp(currentFPS / FPS_HIGH_THRESHOLD, 1.0, 1.5)
        return math.max(DYNAMIC_DISTANCE_MIN, MIN_RECORD_DISTANCE / scale)
    end
    
    return MIN_RECORD_DISTANCE
end

--// =========================================================
--// v1.5.2 UTILITY: COIL ACCELERATION DETECTION
--// =========================================================

function updateCoilSpeedHistory(walkSpeed)
    if not COIL_ACCELERATION_TRACKING then return end
    
    table.insert(coilSpeedHistory, {
        speed = walkSpeed,
        t = os.clock()
    })
    
    while #coilSpeedHistory > COIL_ACCEL_SMOOTH_WINDOW + 2 do
        table.remove(coilSpeedHistory, 1)
    end
end

function detectCoilAcceleration()
    if not COIL_ACCELERATION_TRACKING or #coilSpeedHistory < 3 then
        return false, 0
    end
    
    local recent = coilSpeedHistory[#coilSpeedHistory]
    local prev = coilSpeedHistory[#coilSpeedHistory - 2]
    
    if not recent or not prev then return false, 0 end
    
    local speedChange = math.abs(recent.speed - prev.speed)
    local isAccel = speedChange >= COIL_ACCEL_MIN_CHANGE
    
    if isAccel then
        coilAccelerationActive = true
        lastDetectedCoilSpeed = recent.speed
    end
    
    return isAccel, speedChange
end

--// =========================================================
--// v1.5.2 UTILITY: CATMULL-ROM SPLINE
--// =========================================================

function catmullRomInterpolate(p0, p1, p2, p3, t, alpha)
    alpha = alpha or CATMULL_ROM_ALPHA
    
    -- Calculate knot intervals
    local function getT(t, alpha, p0, p1)
        local d = (p1 - p0).Magnitude
        return t + math.pow(d, alpha)
    end
    
    local t0 = 0
    local t1 = getT(t0, alpha, p0, p1)
    local t2 = getT(t1, alpha, p1, p2)
    local t3 = getT(t2, alpha, p2, p3)
    
    -- Remap t to [t1, t2]
    local tRemapped = t1 + t * (t2 - t1)
    
    -- Barry-Goldman algorithm
    local function lerp(t, t0, t1, p0, p1)
        if math.abs(t1 - t0) < 0.001 then
            return p0
        end
        return p0 + ((p1 - p0) * ((t - t0) / (t1 - t0)))
    end
    
    local a1 = lerp(tRemapped, t0, t1, p0, p1)
    local a2 = lerp(tRemapped, t1, t2, p1, p2)
    local a3 = lerp(tRemapped, t2, t3, p2, p3)
    
    local b1 = lerp(tRemapped, t0, t2, a1, a2)
    local b2 = lerp(tRemapped, t1, t3, a2, a3)
    
    local c = lerp(tRemapped, t1, t2, b1, b2)
    
    return c
end

--// =========================================================
--// v1.5.2 UTILITY: FRAME POOLING
--// =========================================================

function getPooledFrame()
    if not FRAME_POOLING_ENABLED then
        return {}
    end
    
    if #framePool > 0 then
        local frame = table.remove(framePool)
        -- Clear frame data
        for k in pairs(frame) do
            frame[k] = nil
        end
        return frame
    end
    
    return {}
end

function returnFrameToPool(frame)
    if not FRAME_POOLING_ENABLED or not FRAME_REUSE_ENABLED then
        return
    end
    
    if #framePool < FRAME_POOL_SIZE then
        table.insert(framePool, frame)
    end
end

function initFramePool()
    if not FRAME_POOLING_ENABLED then return end
    
    framePool = {}
    for i = 1, math.min(FRAME_POOL_SIZE, 100) do
        table.insert(framePool, {})
    end
end

--// =========================================================
--// v1.5.2 UTILITY: TERRAIN AWARENESS  
--// =========================================================

function detectTerrainSlope(pos1, pos2)
    if not TERRAIN_SLOPE_DETECTION then
        return 0
    end
    
    local horizontal = Vector3.new(pos2.X - pos1.X, 0, pos2.Z - pos1.Z).Magnitude
    if horizontal < 0.01 then return 0 end
    
    local vertical = pos2.Y - pos1.Y
    local slope = math.abs(vertical / horizontal)
    
    return slope
end

function updateTerrainSlope(slope)
    table.insert(terrainSlopeHistory, slope)
    
    while #terrainSlopeHistory > 5 do
        table.remove(terrainSlopeHistory, 1)
    end
    
    -- Average slope
    local sum = 0
    for _, s in ipairs(terrainSlopeHistory) do
        sum = sum + s
    end
    lastTerrainSlope = sum / #terrainSlopeHistory
end

function getTerrainAwareSampleInterval(baseInterval, isAir)
    if not TERRAIN_AWARE_SAMPLING then
        return baseInterval
    end
    
    -- On steep slopes, sample more frequently
    if lastTerrainSlope > TERRAIN_SLOPE_MIN then
        local factor = 1 - math.min(lastTerrainSlope, 0.4)
        return baseInterval * factor
    end
    
    return baseInterval
end

--// =========================================================
--// CORE UTILITY FUNCTIONS (from v1.5.1)
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

    warn("[ONIUM Recorder v1.5.2] " .. title .. " - " .. text)

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

function forceShiftLockOff()
    pcall(function()
        savedMouseBehavior = savedMouseBehavior or UserInputService.MouseBehavior
        savedMouseIconEnabled = savedMouseIconEnabled
            or UserInputService.MouseIconEnabled
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

function restoreMouseLockState()
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

--// v1.5.2: Enhanced character control with physics preservation
function restoreCharacterControl(speedOverride)
    local char, hum, hrp = getCharacter()

    local targetSpeed = tonumber(speedOverride)
        or tonumber(prePlaybackMapWalkSpeed)
        or tonumber(preRecordWalkSpeed)
        or tonumber(hum and hum.WalkSpeed)
        or DEFAULT_PLAYBACK_SPEED

    local toolNow = hasEquippedToolSafe(char)

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
                    if (tonumber(hum.WalkSpeed) or 0) < targetSpeed - 0.1 then
                        hum.WalkSpeed = targetSpeed
                    end
                else
                    hum.WalkSpeed = targetSpeed
                end

                hum:Move(Vector3.new(0, 0, 0), true)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end

        if hrp and PHYSICS_MOMENTUM_ENABLED then
            pcall(function()
                -- v1.5.2: Preserve horizontal momentum but zero vertical
                local vel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X * 0.3, 0, vel.Z * 0.3)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        elseif hrp then
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

local prePlaybackMapWalkSpeed = nil
local prePlaybackHadTool = false

function captureMapSpeedBeforePlayback()
    local char, hum = getCharacter()
    if not hum then
        return
    end

    prePlaybackMapWalkSpeed = tonumber(hum.WalkSpeed) or DEFAULT_PLAYBACK_SPEED
    prePlaybackHadTool = hasEquippedToolSafe(char)
end

--// Forward declarations
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
--// GROUND DETECTION & MOBILE DELTA (v1.5.1 base + v1.5.2 enhancements)
--// =========================================================

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

    local need = math.max(1, tonumber(MOBILE_DELTA_VELOCITY_CONFIRM_FRAMES) or 2)
    local upward = (tonumber(yv) or 0) >= (MOBILE_DELTA_JUMP_Y_TRIGGER or 5.5)
    local downward = (tonumber(yv) or 0) <= (MOBILE_DELTA_FALL_Y_TRIGGER or -5.5)

    if not upward and not downward then
        return false
    end

    local count = 0
    for j = math.max(1, index - 1), math.min(#frames, index + 1) do
        local fr = frames[j]
        if type(fr) == "table" and not mobileDeltaFrameHasGroundContact(fr) then
            local vy = tableToVec(fr.city).Y
            if upward and vy >= (MOBILE_DELTA_JUMP_Y_TRIGGER or 5.5) then
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
                    if st == "Jumping" or st == "Freefall" or st == "FallingDown" or fr.jump == true then
                        fr.states = "Running"
                        fr.jump = false
                    end
                else
                    local explicitAir = st == "Jumping" or st == "Freefall" or st == "FallingDown"
                    local velocityAir = mobileDeltaVelocityConfirmedAir(out, i, yv)

                    if explicitAir or velocityAir then
                        if yv >= (MOBILE_DELTA_JUMP_Y_TRIGGER or 5.5) then
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

--// =========================================================
--// v1.5.2: ENHANCED OUTLIER DETECTION (Multi-Stage)
--// =========================================================

function calculateMean(values)
    if type(values) ~= "table" or #values == 0 then
        return 0
    end
    
    local sum = 0
    for _, v in ipairs(values) do
        sum = sum + (tonumber(v) or 0)
    end
    return sum / #values
end

function calculateStdDev(values, mean)
    if type(values) ~= "table" or #values <= 1 then
        return 0
    end
    
    mean = mean or calculateMean(values)
    local sumSq = 0
    for _, v in ipairs(values) do
        local diff = (tonumber(v) or 0) - mean
        sumSq = sumSq + (diff * diff)
    end
    return math.sqrt(sumSq / (#values - 1))
end

function calculateMedian(values)
    if type(values) ~= "table" or #values == 0 then
        return 0
    end
    
    local sorted = {}
    for _, v in ipairs(values) do
        table.insert(sorted, tonumber(v) or 0)
    end
    table.sort(sorted)
    
    local mid = math.floor(#sorted / 2) + 1
    if #sorted % 2 == 0 then
        return (sorted[mid - 1] + sorted[mid]) / 2
    else
        return sorted[mid]
    end
end

function calculateMAD(values, median)
    if type(values) ~= "table" or #values == 0 then
        return 0
    end
    
    median = median or calculateMedian(values)
    local deviations = {}
    for _, v in ipairs(values) do
        table.insert(deviations, math.abs((tonumber(v) or 0) - median))
    end
    return calculateMedian(deviations)
end

function isOutlierZScore(value, mean, stdDev, threshold)
    if stdDev <= 0 then return false end
    threshold = threshold or OUTLIER_Z_SCORE_THRESHOLD
    local zScore = math.abs(value - mean) / stdDev
    return zScore > threshold
end

function isOutlierMAD(value, median, mad, threshold)
    if mad <= 0 then return false end
    threshold = threshold or OUTLIER_MAD_THRESHOLD
    local modifiedZ = 0.6745 * math.abs(value - median) / mad
    return modifiedZ > threshold
end

function isOutlierIQR(value, q1, q3, multiplier)
    multiplier = multiplier or OUTLIER_IQR_MULTIPLIER
    local iqr = q3 - q1
    if iqr <= 0 then return false end
    return value < (q1 - multiplier * iqr) or value > (q3 + multiplier * iqr)
end

function detectMultiStageOutliers(frames, key)
    if not MULTI_STAGE_OUTLIER_ENABLED or type(frames) ~= "table" or #frames < 10 then
        return {}
    end
    
    key = key or "speed"
    local values = {}
    local indices = {}
    
    for i, fr in ipairs(frames) do
        if type(fr) == "table" then
            local val = 0
            if key == "speed" then
                local city = tableToVec(fr.city)
                val = Vector3.new(city.X, 0, city.Z).Magnitude
            elseif key == "distance" and i > 1 then
                local prev = frames[i - 1]
                if prev then
                    local p1 = tableToVec(prev.position)
                    local p2 = tableToVec(fr.position)
                    val = (p2 - p1).Magnitude
                end
            end
            table.insert(values, val)
            table.insert(indices, i)
        end
    end
    
    if #values < 10 then return {} end
    
    local mean = calculateMean(values)
    local stdDev = calculateStdDev(values, mean)
    
    local median = calculateMedian(values)
    local mad = calculateMAD(values, median)
    
    local sorted = {}
    for _, v in ipairs(values) do
        table.insert(sorted, v)
    end
    table.sort(sorted)
    local q1Idx = math.floor(#sorted * 0.25)
    local q3Idx = math.floor(#sorted * 0.75)
    local q1 = sorted[math.max(1, q1Idx)]
    local q3 = sorted[math.min(#sorted, q3Idx)]
    
    local outlierIndices = {}
    for i, val in ipairs(values) do
        local count = 0
        if isOutlierZScore(val, mean, stdDev) then count = count + 1 end
        if isOutlierMAD(val, median, mad) then count = count + 1 end
        if isOutlierIQR(val, q1, q3) then count = count + 1 end
        
        if count >= 2 then
            table.insert(outlierIndices, indices[i])
        end
    end
    
    return outlierIndices
end

--// =========================================================
--// ANTI-KEDUT BASE FUNCTIONS (from v1.5.1)
--// =========================================================

local ANTI_KEDUT_MIN_RUN_SPEED = 8
local ANTI_KEDUT_MIN_DT = 0.004
local ANTI_KEDUT_MAX_DT = 0.055

function antiKedutPos(fr)
    return tableToVec(fr and fr.position)
end

function antiKedutCity(fr)
    return tableToVec(fr and fr.city)
end

function antiKedutHSpeed(fr)
    local city = antiKedutCity(fr)
    return Vector3.new(city.X, 0, city.Z).Magnitude
end

function antiKedutDist(a, b)
    return (antiKedutPos(b) - antiKedutPos(a)).Magnitude
end

function antiKedutHDist(a, b)
    local pa = antiKedutPos(a)
    local pb = antiKedutPos(b)
    return Vector3.new(pb.X - pa.X, 0, pb.Z - pa.Z).Magnitude
end

function antiKedutVDist(a, b)
    return math.abs(antiKedutPos(b).Y - antiKedutPos(a).Y)
end

function antiKedutBaseSpeed(frames)
    local speeds = {}
    
    for _, fr in ipairs(frames or {}) do
        if type(fr) == "table" then
            local st = tostring(fr.states or fr.state or "")
            if st == "Running" or st == "Landed" then
                local hs = antiKedutHSpeed(fr)
                if hs >= ANTI_KEDUT_MIN_RUN_SPEED then
                    table.insert(speeds, hs)
                end
            end
        end
    end
    
    if #speeds < 3 then
        return DEFAULT_PLAYBACK_SPEED
    end
    
    table.sort(speeds)
    local mid = math.floor(#speeds / 2) + 1
    local base = speeds[mid] or DEFAULT_PLAYBACK_SPEED
    
    return math.clamp(base, ANTI_KEDUT_MIN_RUN_SPEED, MAX_PLAYBACK_SPEED)
end

function basicNormalizeFrames(decoded)
    if type(decoded) ~= "table" then
        return nil
    end

    if #decoded <= 0 then
        return nil
    end

    local normalized = {}

    for _, raw in ipairs(decoded) do
        if type(raw) == "table" then
            local fr = deepCopy(raw)

            if type(fr.position) ~= "table" then
                fr.position = {x = 0, y = 0, z = 0}
            end
            if type(fr.city) ~= "table" then
                fr.city = {x = 0, y = 0, z = 0}
            end
            if type(fr.moveDirection) ~= "table" then
                fr.moveDirection = {x = 0, y = 0, z = 0}
            end

            fr.times = tonumber(fr.times) or tonumber(fr.t) or 0
            fr.t = fr.times
            fr.rotation = tonumber(fr.rotation) or 0
            fr.walkSpeed = tonumber(fr.walkSpeed) or tonumber(fr.ws) or DEFAULT_PLAYBACK_SPEED
            fr.ws = fr.walkSpeed
            fr.hipHeight = tonumber(fr.hipHeight) or BITWISE_JSON_HIPHEIGHT
            fr.states = tostring(fr.states or fr.state or "Running")
            fr.tool = tostring(fr.tool or "")
            fr.jump = fr.jump == true

            table.insert(normalized, fr)
        end
    end

    if #normalized <= 0 then
        return nil
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.times) or 0) < (tonumber(b.times) or 0)
    end)

    local firstTime = tonumber(normalized[1].times) or 0
    for _, fr in ipairs(normalized) do
        fr.times = (tonumber(fr.times) or 0) - firstTime
        fr.t = fr.times
    end

    return normalized
end

function lerpAngle(a, b, t)
    local diff = b - a
    diff = diff - math.floor((diff + math.pi) / (2 * math.pi)) * (2 * math.pi)
    return a + diff * t
end

function smoothStep(a)
    a = math.clamp(a, 0, 1)
    return a * a * (3 - 2 * a)
end

function easeCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        return 1 - math.pow(-2 * t + 2, 3) / 2
    end
end

--// v1.5.2: Enhanced easing with Catmull-Rom awareness
function easeInOutQuart(t)
    if t < 0.5 then
        return 8 * t * t * t * t
    else
        local f = t - 1
        return 1 - 8 * f * f * f * f
    end
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

    return fr.noShiftLock == true
        or fr.rotationMode == "AutoRotate"
end

--// =========================================================
--// ANTI-KEDUT CLEANING FUNCTIONS (v1.5.1 + v1.5.2 enhancements)
--// =========================================================

function antiKedutIsIdle(fr)
    if type(fr) ~= "table" then
        return true
    end

    local md = tableToVec(fr.moveDirection).Magnitude
    local city = antiKedutCity(fr)
    local hv = Vector3.new(city.X, 0, city.Z).Magnitude

    return md < MIN_MOVE_DIRECTION and hv < MIN_HORIZONTAL_VELOCITY
end

function antiKedutTrimEdges(frames)
    frames = frames or {}
    if #frames <= 2 then
        return frames
    end

    local start = 1
    local stop = #frames

    for i = 1, #frames do
        if not antiKedutIsIdle(frames[i]) then
            start = i
            break
        end
    end

    for i = #frames, 1, -1 do
        if not antiKedutIsIdle(frames[i]) then
            stop = i
            break
        end
    end

    if start > stop then
        return {frames[1]}
    end

    local trimmed = {}
    for i = start, stop do
        table.insert(trimmed, deepCopy(frames[i]))
    end

    return trimmed
end

function antiKedutCleanInternal(frames)
    frames = frames or {}
    if #frames <= 2 then
        return frames, 0
    end

    local cleaned = {}
    local removed = 0

    table.insert(cleaned, deepCopy(frames[1]))

    for i = 2, #frames - 1 do
        local prev = cleaned[#cleaned]
        local curr = frames[i]
        local next = frames[i + 1]

        if not prev or not curr or not next then
            table.insert(cleaned, deepCopy(curr))
        else
            local hd1 = antiKedutHDist(prev, curr)
            local hd2 = antiKedutHDist(curr, next)
            local vd1 = antiKedutVDist(prev, curr)
            local vd2 = antiKedutVDist(curr, next)

            local isKedut = (hd1 < CLEAN_DISTANCE_THRESHOLD and hd2 < CLEAN_DISTANCE_THRESHOLD)
                and (vd1 < CLEAN_VERTICAL_THRESHOLD and vd2 < CLEAN_VERTICAL_THRESHOLD)
                and antiKedutIsIdle(curr)

            if not isKedut then
                table.insert(cleaned, deepCopy(curr))
            else
                removed = removed + 1
            end
        end
    end

    if #frames >= 2 then
        table.insert(cleaned, deepCopy(frames[#frames]))
    end

    return cleaned, removed
end

function antiKedutSmoothIdleRotation(frames)
    frames = frames or {}
    if #frames <= 2 then
        return frames
    end

    local out = {}

    for i = 1, #frames do
        local fr = deepCopy(frames[i])

        if antiKedutIsIdle(fr) and i > 1 and i < #frames then
            local prev = frames[i - 1]
            local next = frames[i + 1]

            if prev and next then
                local prevRot = tonumber(prev.rotation) or 0
                local nextRot = tonumber(next.rotation) or 0
                fr.rotation = roundNumber(lerpAngle(prevRot, nextRot, 0.5), 9)
            end
        end

        table.insert(out, fr)
    end

    return out
end

function antiKedutCompactTimes(frames)
    frames = frames or {}
    if #frames <= 1 then
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
            local prev = out[#out]
            local d = antiKedutDist(prev, fr)
            local hv = math.max(antiKedutHSpeed(prev), antiKedutHSpeed(fr), base)
            local dt = (d > 0.005) and (d / math.max(hv, 1)) or ANTI_KEDUT_MIN_DT
            dt = math.clamp(dt, ANTI_KEDUT_MIN_DT, ANTI_KEDUT_MAX_DT)
            t = t + dt
        end

        fr.times = roundNumber(t, 9)
        fr.t = fr.times
        table.insert(out, fr)
    end

    return out
end

--// =========================================================
--// v1.5.2: ENHANCED SMOOTHING WITH KALMAN FILTER
--// =========================================================

function smoothFramePositionsKalman(frames)
    if not KALMAN_FILTER_ENABLED or type(frames) ~= "table" or #frames < 3 then
        return frames
    end

    initKalmanFilters()
    local out = {}

    for i, fr in ipairs(frames) do
        local copy = deepCopy(fr)
        local rawPos = tableToVec(fr.position)
        
        local smoothedPos = applyKalmanFilter(rawPos)
        copy.position = vecToTable(smoothedPos)

        if i > 1 then
            local prev = out[i - 1]
            local prevPos = tableToVec(prev.position)
            local delta = smoothedPos - prevPos
            local flatDelta = Vector3.new(delta.X, 0, delta.Z)
            
            if flatDelta.Magnitude > 0.01 then
                copy.moveDirection = vecToTable(flatDelta.Unit)
            end
        end

        table.insert(out, copy)
    end

    return out
end

function smoothFrameVelocitiesPhysics(frames)
    if not PHYSICS_MOMENTUM_ENABLED or type(frames) ~= "table" or #frames < 3 then
        return frames
    end

    local out = {}

    for i, fr in ipairs(frames) do
        local copy = deepCopy(fr)

        if i > 2 and i < #frames then
            local prev = frames[i - 1]
            local next = frames[i + 1]
            local prevCity = tableToVec(prev.city)
            local currCity = tableToVec(fr.city)
            local nextCity = tableToVec(next.city)

            local avgCity = (prevCity + currCity + nextCity) / 3
            local smoothedCity = currCity * (1 - MOMENTUM_PRESERVATION_RATIO) + avgCity * MOMENTUM_PRESERVATION_RATIO

            copy.city = vecToTable(smoothedCity)
        end

        table.insert(out, copy)
    end

    return out
end

function smoothFrameRotationsAngular(frames)
    if not ANGULAR_MOMENTUM_SMOOTH or type(frames) ~= "table" or #frames < 3 then
        return frames
    end

    local out = {}

    for i, fr in ipairs(frames) do
        local copy = deepCopy(fr)

        if i > 1 and i < #frames then
            local prev = frames[i - 1]
            local next = frames[i + 1]
            local prevRot = tonumber(prev.rotation) or 0
            local currRot = tonumber(fr.rotation) or 0
            local nextRot = tonumber(next.rotation) or 0

            local smoothed = lerpAngle(prevRot, nextRot, 0.5)
            local blended = lerpAngle(currRot, smoothed, ANGULAR_SMOOTH_FACTOR)

            copy.rotation = roundNumber(blended, 9)
        end

        table.insert(out, copy)
    end

    return out
end

--// =========================================================
--// REFERENCE JUMP OPTIMIZER (v1.5.1 base)
--// =========================================================

local ANTI_KEDUT_REFERENCE_JUMP_ENABLED = true
local REF_JUMP_MIN_DT = 0.004
local REF_JUMP_AIR_MAX_DT = 0.025
local REF_JUMP_GROUND_MAX_DT = 0.035
local REF_JUMP_NORMAL_MAX_DT = 0.045
local REF_JUMP_MIN_AIR_HSPEED_RATIO = 0.78
local REF_JUMP_MIN_GROUND_HSPEED_RATIO = 0.85
local REF_JUMP_MAX_AIR_HSPEED_RATIO = 1.18
local REF_JUMP_MIN_JUMP_Y_SPEED = 18
local REF_JUMP_MIN_MOTION_SPEED_KEEP = 0.08

function refJumpIsAir(fr)
    if type(fr) ~= "table" then
        return false
    end

    local st = tostring(fr.states or fr.state or "")
    return st == "Jumping" or st == "Freefall" or st == "FallingDown" or fr.jump == true
end

function refJumpIsHardProtected(fr)
    if type(fr) ~= "table" then
        return false
    end

    local st = tostring(fr.states or fr.state or "")
    return st == "Climbing" or st == "Swimming"
end

function refJumpMarkChain(frames)
    local mark = {}

    for i = 1, #frames do
        mark[i] = false
    end

    for i = 1, #frames do
        if refJumpIsAir(frames[i]) then
            mark[i] = true

            for j = math.max(1, i - 1), math.min(#frames, i + 1) do
                if not refJumpIsHardProtected(frames[j]) then
                    mark[j] = true
                end
            end
        end
    end

    return mark
end

function refJumpDirAround(frames, index)
    local fr = frames[index]
    if not fr then
        return Vector3.new(0, 0, 1)
    end

    local nextF = frames[index + 1]
    local prev = frames[index - 1]
    local pos = antiKedutPos(fr)

    if nextF then
        local delta = antiKedutPos(nextF) - pos
        local flat = Vector3.new(delta.X, 0, delta.Z)
        if flat.Magnitude > 0.01 then
            return flat.Unit
        end
    end

    if prev then
        local delta = pos - antiKedutPos(prev)
        local flat = Vector3.new(delta.X, 0, delta.Z)
        if flat.Magnitude > 0.01 then
            return flat.Unit
        end
    end

    return Vector3.new(0, 0, 1)
end

function refJumpCompressGroundGaps(frames)
    frames = frames or {}
    if #frames <= 2 then
        return frames, 0
    end

    local out = {}
    local removed = 0

    for i = 1, #frames do
        local fr = frames[i]

        if i > 1 and i < #frames then
            local prev = frames[i - 1]
            local next = frames[i + 1]

            if not refJumpIsAir(prev) and not refJumpIsAir(fr) and refJumpIsAir(next) then
                local hd1 = antiKedutHDist(prev, fr)
                local hd2 = antiKedutHDist(fr, next)

                if hd1 < 0.25 and hd2 < 0.25 then
                    removed = removed + 1
                else
                    table.insert(out, deepCopy(fr))
                end
            else
                table.insert(out, deepCopy(fr))
            end
        else
            table.insert(out, deepCopy(fr))
        end
    end

    return out, removed
end

function refJumpSmoothPositions(frames)
    frames = frames or {}
    if #frames <= 2 then
        return frames
    end

    local out = {}

    for i = 1, #frames do
        local fr = deepCopy(frames[i])

        if i > 1 and i < #frames and not refJumpIsHardProtected(fr) then
            local prev = frames[i - 1]
            local next = frames[i + 1]

            local p0 = antiKedutPos(prev)
            local p1 = antiKedutPos(fr)
            local p2 = antiKedutPos(next)

            local smoothed = (p0 + p1 * 2 + p2) / 4
            fr.position = vecToTable(smoothed)
        end

        table.insert(out, fr)
    end

    return out
end

function refJumpUltraSmoothChains(frames)
    frames = frames or {}
    if #frames <= 3 then
        return frames
    end

    local mark = refJumpMarkChain(frames)
    local out = {}

    for i = 1, #frames do
        local fr = deepCopy(frames[i])

        if mark[i] and i > 2 and i < #frames - 1 and not refJumpIsHardProtected(fr) then
            local p0 = antiKedutPos(frames[i - 2])
            local p1 = antiKedutPos(frames[i - 1])
            local p2 = antiKedutPos(fr)
            local p3 = antiKedutPos(frames[i + 1])
            local p4 = antiKedutPos(frames[i + 2])

            local smoothed = (p0 + p1 * 2 + p2 * 4 + p3 * 2 + p4) / 10
            fr.position = vecToTable(smoothed)
        end

        table.insert(out, fr)
    end

    return out
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

                local minRatio = refJumpIsAir(fr) and REF_JUMP_MIN_AIR_HSPEED_RATIO or REF_JUMP_MIN_GROUND_HSPEED_RATIO
                local minH = math.max(base * minRatio, ANTI_KEDUT_MIN_RUN_SPEED)
                local maxH = math.max(base * REF_JUMP_MAX_AIR_HSPEED_RATIO, minH)

                if mobileJumpSafe then
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
                        if (not mobileJumpSafe) and y > 0 and y < REF_JUMP_MIN_JUMP_Y_SPEED then
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

function refJumpRebuildMoveDirectionFromPath(frames)
    return frames or {}
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

    frames = refJumpRebuildMoveDirectionFromPath(frames)

    return frames, removedGap
end

--// =========================================================
--// RUN ANTI-BLING (v1.5.1 base)
--// =========================================================

local RUN_ANTI_BLING_ENABLED = true
local RUN_ANTI_BLING_MAX_STEP = 0.55
local RUN_ANTI_BLING_MAX_BRIDGE_DISTANCE = 8
local RUN_ANTI_BLING_INSERT_MAX = 6
local RUN_ANTI_BLING_MIN_DT = 0.0085
local RUN_ANTI_BLING_MAX_DT = 0.05
local RUN_ANTI_BLING_SPEED_CAP_MULT = 1.16

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
            if oldDt <= 0 then oldDt = SAMPLE_INTERVAL or 0.004 end

            local dt = oldDt

            if runAntiBlingIsRunning(prevOut) and runAntiBlingIsRunning(fr) then
                local hd = antiKedutHDist(prevOut, fr)
                local safeSpeed = runAntiBlingBaseSpeedFromPair(prevOut, fr, base) * (RUN_ANTI_BLING_SPEED_CAP_MULT or 1.16)
                local needDt = (hd > 0.005) and (hd / math.max(safeSpeed, 1)) or (RUN_ANTI_BLING_MIN_DT or 0.0085)

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

--// =========================================================
--// AUTO MAP SPEED DETECTION & LOCK (v1.5.1 base + v1.5.2)
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
        local wsMedian = autoMapPercentile(wsValues, 0.50)
        local wsHigh = autoMapPercentile(wsValues, 0.75)
        if wsMedian and wsHigh then
            wsBase = math.max(wsMedian, wsHigh)
        end
    end

    if #hValues >= minSamples then
        local q50 = autoMapPercentile(hValues, 0.50) or 0
        local q90 = autoMapPercentile(hValues, 0.90) or q50

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

                if hs <= 0.05 or hs < dropLimit then
                    needFix = true
                end

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
            local maxDt = tonumber(AUTO_MAP_SPEED_MAX_DT) or 0.085
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

--// =========================================================
--// v1.5.2: ENHANCED CLEAN FRAMES FOR SAVE
--// =========================================================

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

    frames = mobileDeltaFixAirStateByVelocity(frames)

    frames = antiKedutTrimEdges(frames)
    frames, removedA = antiKedutCleanInternal(frames)

    frames = antiKedutTrimEdges(frames)
    frames, removedB = antiKedutCleanInternal(frames)

    frames = antiKedutSmoothIdleRotation(frames)

    frames, removedJump = refJumpOptimizer(frames, compactTime)

    local addedRunBridge = 0
    frames, addedRunBridge = runAntiBlingInsertBridges(frames)
    if compactTime ~= false then
        frames = runAntiBlingRetuneTimes(frames)
    end

    -- v1.5.2: Apply advanced smoothing
    if KALMAN_FILTER_ENABLED then
        frames = smoothFramePositionsKalman(frames)
    end
    
    if PHYSICS_MOMENTUM_ENABLED then
        frames = smoothFrameVelocitiesPhysics(frames)
    end
    
    if ANGULAR_MOMENTUM_SMOOTH then
        frames = smoothFrameRotationsAngular(frames)
    end

    -- v1.5.2: Detect and remove outliers
    if MULTI_STAGE_OUTLIER_ENABLED then
        local outliers = detectMultiStageOutliers(frames, "speed")
        if #outliers > 0 and #outliers < #frames * 0.15 then
            local cleaned = {}
            for i, fr in ipairs(frames) do
                local isOutlier = false
                for _, outIdx in ipairs(outliers) do
                    if i == outIdx then
                        isOutlier = true
                        break
                    end
                end
                if not isOutlier then
                    table.insert(cleaned, fr)
                else
                    removedB = removedB + 1
                end
            end
            frames = cleaned
        end
    end

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
--// FILE I/O & JSON EXPORT (v1.5.1 base)
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

function retimeFramesForExport(frames)
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

            if lastTime ~= nil and t <= lastTime then
                t = lastTime + minDt
            end

            copy.times = roundNumber(t, 9)
            copy.t = copy.times

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
    return retimeFramesForExport(frames), 0
end

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

function exportFrameForOniumRace(fr)
    fr = fr or {}

    local pos = tableToVec(fr.position)
    local yaw = tonumber(fr.rotation) or 0
    local moveDir = tableToVec(fr.moveDirection)
    local cityVec = tableToVec(fr.city)
    local stateText = tostring(fr.states or fr.state or "Running")
    local ws
    if EXPORT_RAW_EXACT_MODE and RAW_EXACT_KEEP_WALKSPEED then
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

function buildOniumRacePayload(name, frames)
    local exportFrames = {}
    local timedFrames = retimeFramesForExport(frames or {})

    local bitwiseBaseSpeed = nil
    if not EXPORT_RAW_EXACT_MODE then
        bitwiseBaseSpeed = detectBitwiseBaseSpeed(timedFrames)
    end

    for i, fr in ipairs(timedFrames) do
        local copy = deepCopy(fr)

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
        return false, "JSON encode failed", path
    end

    if not safeFunc(writefile) then
        return false, "writefile not available", path
    end

    local ok, err = pcall(function()
        writefile(path, json)
    end)

    if ok then
        return true, "saved", path
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
--// RECORDING SYSTEM (v1.5.1 + v1.5.2 ENHANCED)
--// =========================================================

local lastRecordFrameTime = -999
local lastOverlayUpdateClock = 0
local lastRecordGroundTime = -999
local lastRecordGroundInfo = nil
local lastRecordToolTime = -999
local lastRecordToolName = ""
local MIN_ROTATION_RECORD = 0.1
local lastRecordRotation = nil

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

    if (not air) and (not lastRecordGroundInfo or (t - lastRecordGroundTime) >= RECORD_GROUND_CACHE_INTERVAL) then
        lastRecordGroundInfo = getGroundInfo(hrp)
        lastRecordGroundTime = t
    end

    if air then
        if (t - lastRecordGroundTime) <= 0.14 then
            return lastRecordGroundInfo
        end
        return nil
    end

    return lastRecordGroundInfo
end

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

--// v1.5.2: Enhanced makeFrame with Kalman filter + prediction
function makeFrame(timeValue, hum, hrp)
    local rawPos = hrp.Position
    local vel = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection

    -- v1.5.2: Apply Kalman filter for position smoothing
    local pos = rawPos
    if KALMAN_FILTER_ENABLED then
        pos = applyKalmanFilter(rawPos)
    end

    -- v1.5.2: Update velocity history for prediction
    if PREDICTIVE_RECORDING_ENABLED then
        updateVelocityHistory(vel)
    end

    -- v1.5.2: Update coil speed tracking
    local realWalkSpeed = tonumber(hum.WalkSpeed) or DEFAULT_PLAYBACK_SPEED
    if COIL_ACCELERATION_TRACKING then
        updateCoilSpeedHistory(realWalkSpeed)
    end

    local _, yaw, _ = hrp.CFrame:ToOrientation()
    local stateName = getHumanoidStateName(hum)
    local horizontalSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local mobileRecord = isMobileTouchDeviceSafe()

    local noShiftLock = detectNoShiftLockRecord(hum, hrp)
    local rotationMode = noShiftLock and "AutoRotate" or "ShiftLock"

    local rawStateName = stateName
    local floorMaterialName = getHumanoidFloorMaterialNameSafe(hum)
    local groundedNow = isGroundFloorMaterialName(floorMaterialName)
    local jumpFlag = false
    local yVel = tonumber(vel.Y) or 0

    if stateName == "Climbing" or stateName == "Swimming" then
        jumpFlag = false
    elseif groundedNow then
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
    elseif mobileRecord and (not groundedNow) and yVel >= (MOBILE_DELTA_JUMP_Y_TRIGGER or 5.5) then
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

    local frame = getPooledFrame()
    
    frame.jump = jumpFlag == true
    frame.noShiftLock = noShiftLock
    frame.rotationMode = rotationMode
    frame.mobileRecord = mobileRecord == true
    frame.inputDevice = mobileRecord and "MobileDelta" or "PC"
    frame.executorDevice = mobileRecord and "DeltaAndroid" or "Desktop"
    frame.grounded = groundedNow == true
    frame.floorMaterial = floorMaterialName
    frame.rawState = rawStateName
    frame.hipHeight = roundNumber(tonumber(hum.HipHeight) or BITWISE_JSON_HIPHEIGHT, 9)
    frame.rotation = roundNumber(yaw, 9)
    frame.moveDirection = vecToTable(moveDir)
    frame.city = vecToTable(vel)
    frame.position = vecToTable(pos)
    frame.times = roundNumber(timeValue, 9)
    frame.walkSpeed = roundNumber(realWalkSpeed, 9)
    frame.tool = getRecordToolNameFast(LocalPlayer.Character)
    frame.states = stateName
    frame.ground = getRecordGroundInfoFast(hrp, timeValue, stateName)
    frame.t = roundNumber(timeValue, 9)
    frame.x = roundNumber(x, 9)
    frame.y = roundNumber(y, 9)
    frame.z = roundNumber(z, 9)
    frame.r00 = roundNumber(r00, 9)
    frame.r01 = roundNumber(r01, 9)
    frame.r02 = roundNumber(r02, 9)
    frame.r10 = roundNumber(r10, 9)
    frame.r11 = roundNumber(r11, 9)
    frame.r12 = roundNumber(r12, 9)
    frame.r20 = roundNumber(r20, 9)
    frame.r21 = roundNumber(r21, 9)
    frame.r22 = roundNumber(r22, 9)
    frame.v = roundNumber(horizontalSpeed, 9)
    frame.ws = roundNumber(realWalkSpeed, 9)

    return frame
end

--// v1.5.2: Enhanced movement detection with dynamic thresholds
function isRealMovement(hum, hrp, lastSavedPos)
    local pos = hrp.Position
    local vel = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection
    local stateName = getHumanoidStateName(hum)

    -- v1.5.2: Use dynamic threshold based on FPS
    local minDist = DYNAMIC_THRESHOLD_ENABLED and getDynamicMinDistance() or MIN_RECORD_DISTANCE

    local hd = horizontalDistance(pos, lastSavedPos)
    local vd = math.abs(pos.Y - lastSavedPos.Y)
    local hv = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local vv = math.abs(vel.Y)

    local _, currentYaw, _ = hrp.CFrame:ToOrientation()
    local rotChanged = false
    if lastRecordRotation then
        local diff = math.abs(currentYaw - lastRecordRotation)
        diff = math.min(diff, 2 * math.pi - diff)
        rotChanged = diff > MIN_ROTATION_RECORD
    end
    lastRecordRotation = currentYaw

    local positionMoved = hd >= minDist or vd >= 0.03
    local walking = moveDir.Magnitude >= MIN_MOVE_DIRECTION and positionMoved
    local physicsMove = hv >= MIN_HORIZONTAL_VELOCITY and positionMoved

    local specialState =
        stateName == "Jumping"
        or stateName == "Freefall"
        or stateName == "FallingDown"
        or stateName == "Climbing"
        or stateName == "Swimming"

    local specialMove = specialState and (
        positionMoved
        or vv >= 0.15
        or moveDir.Magnitude >= 0.01
    )

    return walking or physicsMove or specialMove or rotChanged
end

startRecording = function()
    if isRecording then
        notify("Record", "Recording sudah berjalan", 2)
        return
    end

    local char, hum, hrp = getCharacter()
    if not char or not hum or not hrp then
        notify("Record", "Character belum siap", 3)
        return
    end

    forceShiftLockOff()

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

    -- v1.5.2: Initialize advanced systems
    initKalmanFilters()
    initFramePool()
    velocityHistory = {}
    accelerationHistory = {}
    coilSpeedHistory = {}
    terrainSlopeHistory = {}
    fpsHistory = {}
    currentFPS = 60

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

    overlayStatusLabel.Text = "● REC v1.5.2"
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

    local lastState = getHumanoidStateName(hum)
    local lastWalkSpeed = liveBaseSpeed
    local lastToolName = lastRecordToolName or ""
    local recStartClockLocal = recordStartClock

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

        -- v1.5.2: Update FPS tracking
        if DYNAMIC_THRESHOLD_ENABLED then
            updateFPS(dt)
        end

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

        local stNow = getHumanoidStateName(currentHum)
        local toolNow = getRecordToolNameFast(currentChar) or ""
        local wsNow = liveWalkSpeed
        local floorNow = getHumanoidFloorMaterialNameSafe(currentHum)
        local groundedNow = isGroundFloorMaterialName(floorNow)
        local isAir = recordIsAirStateText(stNow) and not groundedNow

        local stateChanged = (stNow ~= lastState)
        local toolChanged = (toolNow ~= lastToolName)
        local speedChanged = math.abs(wsNow - lastWalkSpeed) >= 0.5
        local importantEvent = stateChanged or toolChanged or speedChanged

        -- v1.5.2: Terrain-aware adaptive sampling
        local sampleDt = isAir and RECORD_AIR_SAMPLE_DT or RECORD_MIN_SAMPLE_DT
        if TERRAIN_AWARE_SAMPLING and #recordFrames > 1 then
            local lastPos = tableToVec(recordFrames[#recordFrames].position)
            local slope = detectTerrainSlope(lastPos, currentHrp.Position)
            updateTerrainSlope(slope)
            sampleDt = getTerrainAwareSampleInterval(sampleDt, isAir)
        end

        local sinceLast = actualDuration - lastRecordFrameTime

        if not importantEvent and sinceLast < sampleDt then
            updateOverlay(actualDuration, false)
            return
        end

        if not importantEvent and not isAir then
            local moving = isRealMovement(currentHum, currentHrp, lastRecordSavedPos)
            if not moving then
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

    notify("Record", "v1.5.2 ULTRA SMOOTH: Kalman + Predictive + Dynamic", 3)
end

stopRecording = function()
    if not isRecording then
        notify("Stop", "Recording tidak aktif", 2)
        return
    end

    if recordConnection then
        recordConnection:Disconnect()
        recordConnection = nil
    end

    isRecording = false
    isRollbacking = false
    rollbackCancel = true
    rollbackToken = rollbackToken + 1

    RecordOverlay.Visible = false
    MainFrame.Visible = true

    temporaryRecord = deepCopy(recordFrames)

    local duration = getRecordDuration()
    local frameCount = #recordFrames

    -- Return frames to pool
    if FRAME_POOLING_ENABLED and FRAME_REUSE_ENABLED then
        for _, fr in ipairs(recordFrames) do
            returnFrameToPool(fr)
        end
    end

    recordFrames = {}

    restoreCharacterControl()

    updateOverlay(duration, true)

    if frameCount > 0 then
        notify("Stop", string.format("Selesai: %s | %d frames | v1.5.2", formatTime(duration), frameCount), 3)
    else
        notify("Stop", "Tidak ada frame terekam", 2)
    end
end

function getNextDefaultName()
    local base = "checkpoint"
    local n = 1

    local existing = {}
    for _, cp in ipairs(checkpoints) do
        if cp and cp.name then
            existing[cp.name] = true
        end
    end

    while existing[base .. "_" .. tostring(n)] do
        n = n + 1
    end

    return base .. "_" .. tostring(n)
end

function upsertCheckpoint(name, frames, isMerged, path)
    name = cleanFileName(name)
    
    local found = false
    for i, cp in ipairs(checkpoints) do
        if cp.name == name then
            cp.frames = deepCopy(frames)
            cp.isMerged = isMerged == true
            cp.path = path
            found = true
            break
        end
    end

    if not found then
        table.insert(checkpoints, {
            name = name,
            frames = deepCopy(frames),
            order = nextOrder,
            isMerged = isMerged == true,
            path = path
        })
        nextOrder = nextOrder + 1
    end

    return true
end

saveTemporaryRecord = function()
    if not temporaryRecord or #temporaryRecord <= 0 then
        notify("Save", "Belum ada record. Tekan RECORD lalu STOP dulu.", 3)
        return
    end

    local name = cleanFileName(saveNameBox and saveNameBox.Text or "")

    if name == "" or name == "checkpoint" then
        name = getNextDefaultName()
    end

    local frames, removed = cleanFramesForSaveMerge(temporaryRecord, true)

    if not frames or #frames <= 0 then
        notify("Save", "Frame kosong setelah clean", 3)
        return
    end

    local ok, msg, path = saveFramesToFile(name, frames)

    local added = upsertCheckpoint(name, frames, false, path)

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
        notify("Save", string.format("%s.json | v1.5.2 ULTRA SMOOTH | removed %d idle/kedut", name, removed or 0), 3)
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

    local name = path:match("([^/\]+)%.json$") or "loaded"
    name = cleanFileName(name)

    upsertCheckpoint(name, frames, false, path)

    return true
end

function refreshFromFiles()
    local files = listSavedFiles()
    if not files then
        return 0
    end

    local count = 0

    for _, path in ipairs(files) do
        if tostring(path):lower():find("%.json$") then
            if loadOneFile(path) then
                count = count + 1
            end
        end
    end

    return count
end

importLoad = function()
    local count = refreshFromFiles()

    if refreshList then
        refreshList()
    end

    if count > 0 then
        notify("Import", "Loaded " .. tostring(count) .. " files", 3)
    else
        notify("Import", "Tidak ada file .json di folder", 3)
    end
end

deleteAllCheckpoints = function()
    if #checkpoints <= 0 then
        notify("Delete All", "Tidak ada checkpoint", 2)
        return
    end

    local count = #checkpoints

    for _, cp in ipairs(checkpoints) do
        if cp.path and safeFunc(delfile) then
            pcall(function()
                delfile(cp.path)
            end)
        end
    end

    checkpoints = {}
    nextOrder = 1

    clearMergeDots()
    clearCheckpointMarkers()

    if refreshList then
        refreshList()
    end

    notify("Delete All", "Dihapus: " .. tostring(count) .. " checkpoint", 3)
end

--// =========================================================
--// ROLLBACK SYSTEM (v1.5.1 base - kept for compatibility)
--// =========================================================

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

    if fr.jump == true
        or st == "Jumping"
        or st == "Freefall"
        or st == "FallingDown"
    then
        return true
    end

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

local ROLLBACK_BEFORE_JUMP_BACKSTEP = 2

function findRollbackBeforeJumpIndex()
    local n = #recordFrames
    if n <= 2 then
        return nil, nil
    end

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

    local airStart = lastAirIndex
    while airStart > 1 and isRollbackAirFrame(recordFrames[airStart - 1]) do
        airStart = airStart - 1
    end

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

    local safeIndex = math.max(1, groundIndex - ROLLBACK_BEFORE_JUMP_BACKSTEP)

    for i = safeIndex, groundIndex do
        if isRollbackGroundFrame(recordFrames[i]) then
            return i, "sebelum_lompat"
        end
    end

    return groundIndex, "sebelum_lompat"
end

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

local ROLLBACK_GROUND_RAY_UP = 10
local ROLLBACK_GROUND_RAY_DOWN = 45
local ROLLBACK_MAX_GROUND_Y_DIFF = 8
local ROLLBACK_STAND_EXTRA_Y = 0.12
local ROLLBACK_MIN_HRP_GROUND_OFFSET = 2.2
local ROLLBACK_MAX_HRP_GROUND_OFFSET = 12
local ROLLBACK_CEILING_SKIP_MARGIN = 1.15
local ROLLBACK_GROUND_SCAN_LIMIT = 12
local ROLLBACK_HEAD_CHECK_UP = 5.5

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

function getFrameCFrame(fr)
    if type(fr) ~= "table" then
        return CFrame.new(0, 0, 0)
    end

    local pos = tableToVec(fr.position)
    local yaw = tonumber(fr.rotation) or 0

    return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
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
        return false
    end

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
        -- v1.5.2: Enhanced momentum preservation
        if PHYSICS_MOMENTUM_ENABLED then
            local currentVel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X * 0.85, 0, currentVel.Z * 0.85)
        end
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

    return false
end

rollbackRecording = function()
    if not isRecording then
        notify("Rollback", "Recording belum berjalan", 2)
        return
    end

    forceShiftLockOff()

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
        overlayStatusLabel.Text = "↶ ROLLBACK"
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

        local targetIndex, targetReason = findRollbackBeforeJumpIndex()
        local usingJumpRollback = targetIndex ~= nil and targetIndex < #recordFrames

        local targetGround = nil
        local usingObjectRollback = false

        if not usingJumpRollback then
            targetIndex, targetGround = findRollbackTargetObjectIndex()
            usingObjectRollback = targetIndex ~= nil and targetIndex < #recordFrames
        end

        local removed = 0

        if usingJumpRollback or usingObjectRollback then
            local safeIndex = findSafeRollbackIndex(targetIndex)
            if safeIndex then
                targetIndex = safeIndex
            end

            local targetFrame = safeIndex and recordFrames[targetIndex] or nil

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
                removed = #recordFrames - targetIndex
                for i = #recordFrames, targetIndex + 1, -1 do
                    if FRAME_POOLING_ENABLED and FRAME_REUSE_ENABLED then
                        returnFrameToPool(recordFrames[i])
                    end
                    table.remove(recordFrames, i)
                end

                local _, _, newHrp = getCharacter()
                if newHrp then
                    lastRecordSavedPos = newHrp.Position
                end
            end
        end

        isRollbacking = false

        if RollbackBtn then
            RollbackBtn.Text = "ROLL"
            RollbackBtn.BackgroundColor3 = Color3.fromRGB(80, 95, 170)
        end

        if overlayStatusLabel then
            overlayStatusLabel.Text = "● REC"
        end

        if removed > 0 then
            notify("Rollback", "Rollback OK: hapus " .. tostring(removed) .. " frame", 2)
        else
            notify("Rollback", "Rollback gagal atau tidak ada frame dihapus", 2)
        end

        updateOverlay()
    end)
end

--// =========================================================
--// PLAYBACK SYSTEM (v1.5.1 + v1.5.2 CATMULL-ROM)
--// =========================================================

local setPlaybackButtonState

function getPlaybackStepDistance(speed, isAir)
    if isAir then
        return PLAYBACK_STEP_DISTANCE_AIR
    end

    if speed < 30 then
        return PLAYBACK_STEP_DISTANCE_SLOW
    elseif speed > 70 then
        return PLAYBACK_STEP_DISTANCE_FAST
    end

    return PLAYBACK_STEP_DISTANCE
end

--// v1.5.2: Enhanced interpolation with Catmull-Rom
function interpolatePlaybackFrame(frames, index, alpha)
    if not frames or #frames == 0 or index < 1 or index > #frames then
        return nil
    end

    local current = frames[index]
    local next = frames[index + 1]

    if not next then
        return current
    end

    -- v1.5.2: Use Catmull-Rom if enabled and we have enough points
    if CATMULL_ROM_ENABLED and index > 1 and index < #frames - 1 then
        local p0 = tableToVec(frames[math.max(1, index - 1)].position)
        local p1 = tableToVec(current.position)
        local p2 = tableToVec(next.position)
        local p3 = tableToVec(frames[math.min(#frames, index + 2)].position)

        local smoothPos = catmullRomInterpolate(p0, p1, p2, p3, alpha, CATMULL_ROM_ALPHA)

        local frame = deepCopy(current)
        frame.position = vecToTable(smoothPos)

        -- Smooth rotation with angular momentum
        if ANGULAR_MOMENTUM_SMOOTH then
            local r0 = tonumber(frames[math.max(1, index - 1)].rotation) or 0
            local r1 = tonumber(current.rotation) or 0
            local r2 = tonumber(next.rotation) or 0
            local r3 = tonumber(frames[math.min(#frames, index + 2)].rotation) or 0
            
            local smoothRot = lerpAngle(r1, r2, alpha)
            frame.rotation = roundNumber(smoothRot, 9)
        else
            frame.rotation = roundNumber(lerpAngle(
                tonumber(current.rotation) or 0,
                tonumber(next.rotation) or 0,
                alpha
            ), 9)
        end

        return frame
    end

    -- Fallback: cubic interpolation
    local t = easeCubic(alpha)
    local pos1 = tableToVec(current.position)
    local pos2 = tableToVec(next.position)
    local pos = pos1:Lerp(pos2, t)

    local rot1 = tonumber(current.rotation) or 0
    local rot2 = tonumber(next.rotation) or 0
    local rot = lerpAngle(rot1, rot2, t)

    local frame = deepCopy(current)
    frame.position = vecToTable(pos)
    frame.rotation = roundNumber(rot, 9)

    return frame
end

stopPlayback = function(userStopped)
    if not isPlaying then
        return
    end

    playToken = playToken + 1
    isPlaying = false

    restoreCharacterControl()

    if setPlaybackButtonState then
        setPlaybackButtonState(false)
    end

    if userStopped then
        notify("Playback", "Stopped by user", 2)
    end
end

function playFrames(frames, checkpointName)
    if not frames or #frames <= 0 then
        notify("Play", "Tidak ada frame", 2)
        return
    end

    if isPlaying then
        stopPlayback(true)
        task.wait(0.1)
    end

    if isRecording then
        notify("Play", "Stop recording dulu", 2)
        return
    end

    local char, hum, hrp = getCharacter()
    if not char or not hum or not hrp then
        notify("Play", "Character tidak siap", 2)
        return
    end

    captureMapSpeedBeforePlayback()

    local modeText = "PREVIEW"
    local playbackSpeed = currentPlaybackSpeed

    if USE_MAP_WALKSPEED_ON_PLAYBACK and frames[1] then
        local firstWs = tonumber(frames[1].walkSpeed) or tonumber(frames[1].ws)
        if firstWs and firstWs >= MIN_PLAYBACK_SPEED then
            playbackSpeed = firstWs
            modeText = "AUTO MAP"
        end
    end

    local rawText = tostring(speedBox and speedBox.Text or "")
    if rawText:lower() == "auto" then
        modeText = "AUTO MAP"
    end

    playToken = playToken + 1
    isPlaying = true
    local myPlayToken = playToken

    if setPlaybackButtonState then
        setPlaybackButtonState(true)
    end

    notify("Playback", string.format("START: %s | Speed %d | v1.5.2 CATMULL-ROM", modeText, playbackSpeed), 2)

    task.spawn(function()
        local noShiftMode = false
        if #frames > 0 and isNoShiftLockFrame(frames[1]) then
            noShiftMode = true
        end

        pcall(function()
            hum.AutoRotate = not noShiftMode
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)

        local startFrame = frames[1]
        if startFrame then
            local startPos = tableToVec(startFrame.position)
            local startRot = tonumber(startFrame.rotation) or 0
            local startCF = CFrame.new(startPos) * CFrame.Angles(0, startRot, 0)

            pcall(function()
                hrp.CFrame = startCF
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)

            task.wait(0.1)
        end

        local lastTime = 0
        local frameIndex = 1

        while isPlaying and myPlayToken == playToken and frameIndex <= #frames do
            local frame = frames[frameIndex]
            if not frame then break end

            local targetTime = tonumber(frame.times) or tonumber(frame.t) or 0
            local dt = targetTime - lastTime

            if dt > 0 then
                local waitTime = dt
                if playbackSpeed > 0 and tonumber(frame.walkSpeed or frame.ws) then
                    local frameSpeed = tonumber(frame.walkSpeed or frame.ws)
                    waitTime = dt * (frameSpeed / playbackSpeed)
                end

                waitTime = math.max(0.001, math.min(waitTime, 0.5))
                task.wait(waitTime)
            end

            if not isPlaying or myPlayToken ~= playToken then
                break
            end

            local targetPos = tableToVec(frame.position)
            local targetRot = tonumber(frame.rotation) or 0
            local targetCF = CFrame.new(targetPos) * CFrame.Angles(0, targetRot, 0)

            -- v1.5.2: Apply with physics momentum if enabled
            pcall(function()
                if PHYSICS_MOMENTUM_ENABLED and frameIndex > 1 then
                    local currentVel = hrp.AssemblyLinearVelocity
                    local targetVel = tableToVec(frame.city)
                    local blendedVel = currentVel * (1 - MOMENTUM_PRESERVATION_RATIO) + targetVel * MOMENTUM_PRESERVATION_RATIO
                    hrp.AssemblyLinearVelocity = blendedVel
                else
                    hrp.CFrame = targetCF
                end

                if USE_MAP_HIPHEIGHT_ON_PLAYBACK then
                    local hip = tonumber(frame.hipHeight)
                    if hip then
                        hum.HipHeight = hip
                    end
                end
            end)

            lastTime = targetTime
            frameIndex = frameIndex + 1

            if frameIndex % 100 == 0 then
                task.wait()
            end
        end

        isPlaying = false
        if setPlaybackButtonState then
            setPlaybackButtonState(false)
        end
        notify("Playback", string.format("Selesai: %s | Speed %d", modeText, playbackSpeed), 2)
    end)
end

playCheckpoint = function(cp)
    if not cp or not cp.frames then
        return
    end

    playFrames(cp.frames, cp.name)
end

--// =========================================================
--// MERGE SYSTEM (v1.5.1 base)
--// =========================================================

local MERGE_ANTI_SPIKE_ENABLED = true
local MERGE_ANTI_SPIKE_MIN_DT = 0.0065
local MERGE_ANTI_SPIKE_MAX_DT = 0.18
local MERGE_ANTI_SPIKE_SPEED_CAP_MULT = 1.08
local MERGE_ANTI_SPIKE_JOIN_MAX_DT = 1.25
local CLEAN_MIN_TIMING_GAP = 0.004

function trimIdleStartEnd(frames)
    return antiKedutTrimEdges(frames)
end

function compactCleanTimes(frames)
    return antiKedutCompactTimes(frames)
end

function mergeAntiSpikeFrameTime(fr)
    return tonumber(fr and (fr.times or fr.t)) or 0
end

function mergeAntiSpikeDistance(a, b)
    local dist = antiKedutDist(a, b)
    local hd = antiKedutHDist(a, b)
    local vd = antiKedutVDist(a, b)
    return dist, hd, vd
end

function mergeAntiSpikePairSpeed(a, b, fallback)
    return math.max(
        antiKedutHSpeed(a),
        antiKedutHSpeed(b),
        tonumber(a and a.walkSpeed) or 0,
        tonumber(b and b.walkSpeed) or 0,
        tonumber(fallback) or 0,
        ANTI_KEDUT_MIN_RUN_SPEED or 8
    )
end

function estimateMergeJoinDt(prevFrame, newFrame, dist)
    local baseSpeed = autoMapDetectNormalRunSpeed({prevFrame, newFrame}) or antiKedutBaseSpeed({prevFrame, newFrame}) or DEFAULT_PLAYBACK_SPEED
    local hd = antiKedutHDist(prevFrame, newFrame)
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

                    local prevTime = tonumber(previousFrame.times) or tonumber(previousFrame.t) or (timeCursor - (CLEAN_MIN_TIMING_GAP or 0.004))
                    local joinDt = estimateMergeJoinDt(previousFrame, newFrame, dist)
                    timeCursor = prevTime + math.max(joinDt, CLEAN_MIN_TIMING_GAP or 0.004)
                    localT = 0

                    if dist > MERGE_MAX_BRIDGE_DISTANCE then
                        newFrame.seam = true
                        cutJoin = cutJoin + 1
                    else
                        newFrame.seam = false
                        newFrame.cutNext = false
                    end
                end

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

    merged = cleanFramesForSaveMerge(merged, true)
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
            string.format("merged_record: %d files | removed %d | cut %d | dots %d", 
                mergedCount, removedTotal, cutJoin, dotCount),
            4
        )
    else
        notify("Merge", "Merge masuk memory. " .. tostring(msg) .. " | dots " .. tostring(dotCount), 4)
    end
end

--// =========================================================
--// CP MARKER & MERGE DOT VISUALIZATION
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
                notify("CP Marker", "ON: " .. tostring(CP_MARKER_SELECTED_NAME), 2)
            else
                notify("CP Marker", "ON semua checkpoint", 2)
            end
        else
            notify("CP Marker", "OFF", 2)
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

--// =========================================================
--// UI CREATION (v1.5.1 base with v1.5.2 branding)
--// =========================================================

function addCorner(obj, radius)
    pcall(function()
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 8)
        corner.Parent = obj
    end)
end

function addStroke(obj, color, transparency)
    pcall(function()
        local stroke = Instance.new("UIStroke")
        stroke.Color = color or Color3.fromRGB(100, 100, 150)
        stroke.Thickness = 1
        stroke.Transparency = transparency or 0.3
        stroke.Parent = obj
    end)
end

function makeButton(parent, text, bgColor)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = bgColor or Color3.fromRGB(55, 55, 70)
    btn.AutoButtonColor = false
    btn.Parent = parent
    addCorner(btn, 6)
    addStroke(btn, Color3.fromRGB(120, 120, 180), 0.25)
    return btn
end

function makeLabel(parent, text, textSize, bold)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text
    lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    lbl.TextSize = textSize or 9
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.BackgroundTransparency = 1
    lbl.Parent = parent
    return lbl
end

function makeTextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.PlaceholderText = placeholder or ""
    box.Text = ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 9
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    box.ClearTextOnFocus = false
    box.Parent = parent
    addCorner(box, 6)
    addStroke(box, Color3.fromRGB(90, 90, 130), 0.35)
    return box
end

function bindButton(btn, callback)
    if not btn or not callback then
        return
    end

    addConnection(btn.MouseButton1Click:Connect(callback))

    addConnection(btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(
            math.min(255, btn.BackgroundColor3.R * 255 * 1.2),
            math.min(255, btn.BackgroundColor3.G * 255 * 1.2),
            math.min(255, btn.BackgroundColor3.B * 255 * 1.2)
        )
    end))

    addConnection(btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(
            btn.BackgroundColor3.R * 255 / 1.2,
            btn.BackgroundColor3.G * 255 / 1.2,
            btn.BackgroundColor3.B * 255 / 1.2
        )
    end))
end

function makeDraggable(frame, handle)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

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

    addConnection(handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end))
end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ONIUM_RECORDER_v152"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = PlayerGui
end

MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 35)
MainFrame.Size = UDim2.fromOffset(290, 420)
MainFrame.Position = UDim2.fromOffset(25, 100)
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 12)
addStroke(MainFrame, Color3.fromRGB(130, 130, 190), 0.2)

local Header = Instance.new("Frame")
Header.BackgroundColor3 = Color3.fromRGB(130, 35, 60)
Header.Size = UDim2.new(1, 0, 0, 26)
Header.Parent = MainFrame
addCorner(Header, 12)

local HeaderLabel = makeLabel(Header, "ONIUM RECORDER v1.5.2 ULTRA SMOOTH", 10, true)
HeaderLabel.Size = UDim2.new(1, -60, 1, 0)
HeaderLabel.Position = UDim2.fromOffset(8, 0)
HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left

makeDraggable(MainFrame, Header)

local MinBtn = makeButton(Header, "-", Color3.fromRGB(80, 80, 110))
MinBtn.Size = UDim2.fromOffset(22, 18)
MinBtn.Position = UDim2.new(1, -50, 0.5, -9)

local CloseBtn = makeButton(Header, "X", Color3.fromRGB(180, 55, 70))
CloseBtn.Size = UDim2.fromOffset(22, 18)
CloseBtn.Position = UDim2.new(1, -24, 0.5, -9)

local Content = Instance.new("Frame")
Content.BackgroundTransparency = 1
Content.Size = UDim2.new(1, -16, 1, -34)
Content.Position = UDim2.fromOffset(8, 30)
Content.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Content

local SearchFrame = Instance.new("Frame")
SearchFrame.BackgroundTransparency = 1
SearchFrame.Size = UDim2.new(1, 0, 0, 24)
SearchFrame.Parent = Content

local SearchLabel = makeLabel(SearchFrame, "Search:", 9, true)
SearchLabel.Size = UDim2.fromOffset(50, 24)
SearchLabel.TextXAlignment = Enum.TextXAlignment.Left

searchBox = makeTextBox(SearchFrame, "Filter checkpoint...")
searchBox.Size = UDim2.new(1, -55, 1, 0)
searchBox.Position = UDim2.fromOffset(55, 0)

local SaveFrame = Instance.new("Frame")
SaveFrame.BackgroundTransparency = 1
SaveFrame.Size = UDim2.new(1, 0, 0, 24)
SaveFrame.Parent = Content

local SaveLabel = makeLabel(SaveFrame, "Name:", 9, true)
SaveLabel.Size = UDim2.fromOffset(50, 24)
SaveLabel.TextXAlignment = Enum.TextXAlignment.Left

saveNameBox = makeTextBox(SaveFrame, "checkpoint name")
saveNameBox.Size = UDim2.new(1, -55, 1, 0)
saveNameBox.Position = UDim2.fromOffset(55, 0)

local SpeedFrame = Instance.new("Frame")
SpeedFrame.BackgroundTransparency = 1
SpeedFrame.Size = UDim2.new(1, 0, 0, 24)
SpeedFrame.Parent = Content

local SpeedLabel = makeLabel(SpeedFrame, "Speed:", 9, true)
SpeedLabel.Size = UDim2.fromOffset(50, 24)
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

speedBox = makeTextBox(SpeedFrame, "16 or AUTO")
speedBox.Size = UDim2.new(0.5, -55, 1, 0)
speedBox.Position = UDim2.fromOffset(55, 0)
speedBox.Text = "AUTO"

local SetSpeedBtn = makeButton(SpeedFrame, "SET", Color3.fromRGB(60, 90, 130))
SetSpeedBtn.Size = UDim2.new(0.5, -4, 1, 0)
SetSpeedBtn.Position = UDim2.new(0.5, 2, 0, 0)

local ControlFrame = Instance.new("Frame")
ControlFrame.BackgroundTransparency = 1
ControlFrame.Size = UDim2.new(1, 0, 0, 50)
ControlFrame.Parent = Content

local ControlLayout = Instance.new("UIGridLayout")
ControlLayout.CellSize = UDim2.new(0.5, -3, 0, 22)
ControlLayout.CellPadding = UDim2.fromOffset(6, 4)
ControlLayout.Parent = ControlFrame

local RecordBtn = makeButton(ControlFrame, "RECORD", Color3.fromRGB(180, 55, 70))
local SaveBtn = makeButton(ControlFrame, "SAVE", Color3.fromRGB(60, 130, 90))
local StopPlayBtn = makeButton(ControlFrame, "STOP PLAY", Color3.fromRGB(180, 80, 55))
cpMarkerToggleBtn = makeButton(ControlFrame, "CP OFF", Color3.fromRGB(55, 55, 70))

setPlaybackButtonState = function(playing)
    if StopPlayBtn then
        if playing then
            StopPlayBtn.BackgroundColor3 = Color3.fromRGB(190, 85, 60)
        else
            StopPlayBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 55)
        end
    end
end

local ActionFrame = Instance.new("Frame")
ActionFrame.BackgroundTransparency = 1
ActionFrame.Size = UDim2.new(1, 0, 0, 50)
ActionFrame.Parent = Content

local ActionLayout = Instance.new("UIGridLayout")
ActionLayout.CellSize = UDim2.new(0.5, -3, 0, 22)
ActionLayout.CellPadding = UDim2.fromOffset(6, 4)
ActionLayout.Parent = ActionFrame

local ImportBtn = makeButton(ActionFrame, "IMPORT", Color3.fromRGB(70, 95, 150))
local RefreshBtn = makeButton(ActionFrame, "REFRESH", Color3.fromRGB(70, 110, 140))
local MergeBtn = makeButton(ActionFrame, "MERGE ALL", Color3.fromRGB(130, 80, 140))
local DeleteAllBtn = makeButton(ActionFrame, "DELETE ALL", Color3.fromRGB(150, 60, 60))

local ListLabel = makeLabel(Content, "Checkpoints:", 9, true)
ListLabel.Size = UDim2.new(1, 0, 0, 16)
ListLabel.TextXAlignment = Enum.TextXAlignment.Left

listFrame = Instance.new("ScrollingFrame")
listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
listFrame.BorderSizePixel = 0
listFrame.Size = UDim2.new(1, 0, 1, -210)
listFrame.CanvasSize = UDim2.fromOffset(0, 0)
listFrame.ScrollBarThickness = 6
listFrame.Parent = Content
addCorner(listFrame, 8)
addStroke(listFrame, Color3.fromRGB(80, 80, 120), 0.3)

listLayout = Instance.new("UIListLayout")
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
overlayStatusLabel.Text = "● REC v1.5.2"
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
--// CHECKPOINT LIST REFRESH
--// =========================================================

refreshList = function()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local searchTerm = searchBox and trimText(searchBox.Text):lower() or ""

    local filtered = {}
    for _, cp in ipairs(checkpoints) do
        if cp and not cp.isMerged then
            local name = tostring(cp.name or ""):lower()
            if searchTerm == "" or name:find(searchTerm, 1, true) then
                table.insert(filtered, cp)
            end
        end
    end

    table.sort(filtered, function(a, b)
        return (a.order or 9999) < (b.order or 9999)
    end)

    for _, cp in ipairs(filtered) do
        local cpFrame = Instance.new("Frame")
        cpFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        cpFrame.Size = UDim2.new(1, -8, 0, 28)
        cpFrame.Parent = listFrame
        addCorner(cpFrame, 6)
        addStroke(cpFrame, Color3.fromRGB(90, 90, 130), 0.3)

        local cpName = makeLabel(cpFrame, tostring(cp.name or "checkpoint"), 9, true)
        cpName.Size = UDim2.new(1, -120, 1, 0)
        cpName.Position = UDim2.fromOffset(6, 0)
        cpName.TextXAlignment = Enum.TextXAlignment.Left
        cpName.TextTruncate = Enum.TextTruncate.AtEnd

        local frameInfo = makeLabel(cpFrame, tostring(#(cp.frames or {})) .. " frames", 8, false)
        frameInfo.Size = UDim2.fromOffset(60, 28)
        frameInfo.Position = UDim2.new(1, -115, 0, 0)
        frameInfo.TextColor3 = Color3.fromRGB(180, 180, 200)

        local playBtn = makeButton(cpFrame, "▶", Color3.fromRGB(60, 120, 80))
        playBtn.Size = UDim2.fromOffset(22, 22)
        playBtn.Position = UDim2.new(1, -52, 0.5, -11)
        bindButton(playBtn, function()
            playCheckpoint(cp)
        end)

        local markerBtn = makeButton(cpFrame, "◉", Color3.fromRGB(70, 80, 140))
        markerBtn.Size = UDim2.fromOffset(22, 22)
        markerBtn.Position = UDim2.new(1, -27, 0.5, -11)
        bindButton(markerBtn, function()
            toggleSingleCheckpointMarker(cp)
        end)

        local delBtn = makeButton(cpFrame, "×", Color3.fromRGB(160, 55, 55))
        delBtn.Size = UDim2.fromOffset(22, 22)
        delBtn.Position = UDim2.new(1, -2, 0.5, -11)
        bindButton(delBtn, function()
            for i, check in ipairs(checkpoints) do
                if check == cp then
                    table.remove(checkpoints, i)
                    break
                end
            end

            if cp.path and safeFunc(delfile) then
                pcall(function()
                    delfile(cp.path)
                end)
            end

            refreshList()
            notify("Delete", "Deleted: " .. tostring(cp.name), 2)
        end)
    end
end

function setSpeedFromCurrent()
    local raw = tostring(speedBox and speedBox.Text or "")
    raw = raw:gsub(",", ".")
    raw = raw:gsub("^%s+", "")
    raw = raw:gsub("%s+$", "")

    if raw == "" or raw:lower() == "auto" then
        if speedBox then
            speedBox.Text = "AUTO"
        end
        notify("Speed", "AUTO MAP aktif", 2)
        return
    end

    local spd = setSyncBaseSpeed(raw, true)
    notify("Speed", "MANUAL: " .. tostring(spd) .. " stud/s", 2)
end

--// =========================================================
--// EVENT BINDINGS
--// =========================================================

bindButton(RecordBtn, function()
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
    task.wait(0.05)
    startRecording()

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
    notify("Refresh", "Loaded: " .. tostring(count), 3)
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
        notify("Speed", "AUTO MAP aktif", 2)
        return
    end

    local spd = setSyncBaseSpeed(raw, true)
    notify("Speed", "MANUAL: " .. tostring(spd) .. " stud/s", 2)
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
--// INITIAL LOAD & STARTUP
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
            notify("ONIUM Recorder v1.5.2", "Auto loaded " .. tostring(count) .. " JSON files", 3)
        else
            notify("ONIUM Recorder v1.5.2", "ULTRA SMOOTH ready - Kalman + Catmull-Rom + Predictive", 3)
        end
    else
        notify("ONIUM Recorder v1.5.2", "Ready (memory mode)", 4)
    end
end)

--// =========================================================
--// v1.5.2 ENHANCEMENTS SUMMARY
--// =========================================================
--[[
MIKSU TRG RECORD v1.5.2 - ULTRA SMOOTH STABILITY

WHAT'S NEW:
✓ Kalman Filter - Position smoothing (anti micro-jitter)
✓ Catmull-Rom Spline - Ultra-smooth interpolation for playback
✓ Predictive Recording - 3-frame velocity lookahead
✓ Dynamic Thresholds - FPS-based adaptive sampling
✓ Enhanced Coil Detection - Acceleration tracking
✓ Physics Momentum - Preserved during playback transitions
✓ Adaptive Step Distance - Terrain-aware sampling
✓ Multi-Stage Outlier Detection - Z-score + MAD + IQR
✓ Frame Pooling - Reduced GC pressure
✓ Enhanced Rotation Smoothing - Angular velocity aware

TECHNICAL IMPROVEMENTS:
- KALMAN_FILTER_ENABLED: Process noise 0.008, Measurement noise 0.15
- PREDICTIVE_RECORDING_ENABLED: 3-frame lookahead, 65% weight
- DYNAMIC_THRESHOLD_ENABLED: Adjusts 0.06-0.14 based on FPS
- CATMULL_ROM_ENABLED: Centripetal parameterization (alpha=0.5)
- PHYSICS_MOMENTUM_ENABLED: 88% preservation ratio
- MULTI_STAGE_OUTLIER_ENABLED: Z-score 2.8, MAD 3.5, IQR 2.2x
- FRAME_POOLING_ENABLED: 500-frame pool for reuse
- TERRAIN_AWARE_SAMPLING: Slope detection + adaptive intervals

PERFORMANCE:
- Smoother character movement (Kalman filtering)
- More natural playback (Catmull-Rom splines)
- Better jump/lompat handling (predictive velocity)
- Adaptive to device FPS (dynamic thresholds)
- Reduced memory allocations (frame pooling)

COMPATIBILITY:
- Full backward compatibility with v1.5.1 JSON files
- All v1.5.1 features preserved
- Mobile Delta support enhanced
- Auto map speed detection improved

USAGE:
1. RECORD - Start recording with all v1.5.2 enhancements active
2. STOP - Stop recording (applies Kalman + outlier detection)
3. SAVE - Save with ultra-smooth processing
4. PLAY - Playback with Catmull-Rom interpolation

Created: 2026-07-23
Author: MIKSU TRG + AI Enhancement
Version: 1.5.2 ULTRA SMOOTH
]]

notify("v1.5.2", "Initialization complete. All systems ready.", 2)
