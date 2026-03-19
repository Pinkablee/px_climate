local shared = require 'config.shared'

local currentWeather, lastAppliedWeather = nil, nil
local clockSync = nil
local clockSyncAtMs = 0

---Returns whether the provided weather type should enable snow effects.
---@param w string
---@return boolean
local function isSnowWeather(w)
    return (w == 'SNOW' or w == 'BLIZZARD' or w == 'SNOWLIGHT' or w == 'XMAS')
end

---Applies the requested weather type locally and handles smooth transitions.
---@param w string
local function applyWeather(w)
    if not w or w == '' then return end

    if w ~= lastAppliedWeather then
        ClearOverrideWeather()
        ClearWeatherTypePersist()

        local t = tonumber(shared.WeatherTransitionSeconds) or 15.0
        SetWeatherTypeOverTime(w, t)

        Wait(500)

        SetWeatherTypeNowPersist(w)
        SetWeatherTypeNow(w)
        SetOverrideWeather(w)

        lastAppliedWeather = w
    else
        SetWeatherTypeNowPersist(w)
        SetOverrideWeather(w)
    end

    local snow = isSnowWeather(w)
    SetForcePedFootstepsTracks(snow)
    SetForceVehicleTrails(snow)
end

---Builds the current Los Angeles time from synced server clock data.
---@return number|nil, number|nil, number|nil
local function computeLocalTime()
    if not clockSync or type(clockSync) ~= 'table' then
        return nil
    end

    local unix = tonumber(clockSync.unix)
    local offset = tonumber(clockSync.utc_offset_seconds)
    if not unix or not offset then
        return nil
    end

    local elapsed = (GetGameTimer() - clockSyncAtMs) / 1000.0
    local now = unix + elapsed
    local la = now + offset

    local secInDay = 86400
    local t = la % secInDay
    if t < 0 then t = t + secInDay end

    local hour = math.floor(t / 3600)
    local minute = math.floor((t % 3600) / 60)
    local second = math.floor(t % 60)

    return hour, minute, second
end

AddStateBagChangeHandler('ws_weather', nil, function(bagName, key, value)
    if bagName ~= 'global' or not value then return end
    currentWeather = tostring(value)
end)

AddStateBagChangeHandler('ws_clock', nil, function(bagName, key, value)
    if bagName ~= 'global' or type(value) ~= 'table' then return end
    clockSync = value
    clockSyncAtMs = GetGameTimer()
end)

CreateThread(function()
    while true do
        if currentWeather == nil then
            local w = GlobalState.ws_weather or shared.LockedWeather or 'EXTRASUNNY'
            currentWeather = tostring(w)
        end

        applyWeather(currentWeather)
        Wait(4000)
    end
end)

CreateThread(function()
    local lastH, lastM, lastS = -1, -1, -1

    while true do
        Wait(250)

        local h, m, s = computeLocalTime()
        if h then
            if h ~= lastH or m ~= lastM or s ~= lastS then
                NetworkOverrideClockTime(h, m, s)
                lastH, lastM, lastS = h, m, s
            end
        end
    end
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end

    Wait(200)

    currentWeather = tostring(GlobalState.ws_weather or shared.LockedWeather or 'EXTRASUNNY')
    clockSync = GlobalState.ws_clock
    clockSyncAtMs = GetGameTimer()

    applyWeather(currentWeather)
end)

---Returns the current local synced weather type.
---@return string
local function getWeatherType()
    return tostring(currentWeather or GlobalState.ws_weather or shared.LockedWeather or 'EXTRASUNNY')
end

---Returns the current synced Los Angeles time.
---@return number|nil, number|nil, number|nil
local function getLATimeHMS()
    local h, m, s = computeLocalTime()
    if not h then
        return nil
    end

    return h, m, s
end

---Formats 24-hour time into 12-hour display format.
---@param hour number
---@param minute number
---@return string
local function format12Hour(hour, minute)
    local suffix = (hour >= 12) and 'PM' or 'AM'
    local h12 = hour % 12
    if h12 == 0 then h12 = 12 end

    return ('%d:%02d%s'):format(h12, minute, suffix)
end

---Returns the current synced Los Angeles time formatted as 12-hour time.
---@return string|nil
local function getLATimeFormatted()
    local h, m = getLATimeHMS()
    if not h then return nil end

    return format12Hour(h, m)
end

exports('getWeatherType', getWeatherType)

exports('getLATime', function()
    local h, m, s = getLATimeHMS()
    return h, m, s
end)

exports('getLATimeFormatted', getLATimeFormatted)

exports('getWeatherAndTime', function()
    local weather = getWeatherType()
    local h, m, s = getLATimeHMS()
    local formatted = (h and format12Hour(h, m)) or nil

    return {
        weather = weather,
        hour = h,
        minute = m,
        second = s,
        formatted = formatted
    }
end)

RegisterNetEvent('px_climate:getWeatherType', function(cb)
    if type(cb) ~= 'function' then return end
    cb(getWeatherType())
end)

RegisterNetEvent('px_climate:getLATime', function(cb)
    if type(cb) ~= 'function' then return end

    local h, m, s = getLATimeHMS()
    cb(h, m, s)
end)

RegisterNetEvent('px_climate:getWeatherAndTime', function(cb)
    if type(cb) ~= 'function' then return end
    cb(exports[GetCurrentResourceName()]:getWeatherAndTime())
end)