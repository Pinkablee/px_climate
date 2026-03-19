local shared = require 'config.shared'

local NORMAL_FALLBACK = { 'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'OVERCAST', 'CLEARING' }

---Prints a debug message when debug mode is enabled.
---@param msg string
local function dbg(msg)
    if shared.Debug then
        print(('[px_climate] %s'):format(msg))
    end
end

---Clamps a number between a minimum and maximum value.
---@param n number
---@param a number
---@param b number
---@return number
local function clamp(n, a, b)
    if n < a then return a end
    if n > b then return b end
    return n
end

---Returns a random value from a list.
---@param list table
---@return any
local function pick(list)
    return list[math.random(1, #list)]
end

---Maps Open-Meteo WMO weather codes to GTA weather types.
---@param wmo number|string
---@param cloudCover number|string
---@return string
local function mapWmoToGta(wmo, cloudCover)
    wmo = tonumber(wmo) or 0
    cloudCover = tonumber(cloudCover) or 0

    if (wmo >= 95 and wmo <= 99) then
        return 'THUNDER'
    end

    if (wmo == 45 or wmo == 48) then
        return 'FOGGY'
    end

    if (wmo >= 71 and wmo <= 77) or (wmo == 85 or wmo == 86) then
        return 'XMAS'
    end

    if (wmo >= 51 and wmo <= 67) or (wmo >= 80 and wmo <= 82) then
        return 'RAIN'
    end

    if wmo == 3 then
        return 'OVERCAST'
    end

    if wmo == 2 then
        return 'CLOUDS'
    end

    if wmo == 1 then
        return (cloudCover >= 60) and 'CLOUDS' or 'CLEAR'
    end

    return 'EXTRASUNNY'
end

---Builds the Open-Meteo API request URL using the configured location and timezone.
---@return string
local function buildUrl()
    local tz = shared.Timezone:gsub(' ', '%%20')

    return (
        'https://api.open-meteo.com/v1/forecast' ..
        '?latitude=%s&longitude=%s' ..
        '&current=weather_code,cloud_cover' ..
        '&timezone=%s'
    ):format(shared.Latitude, shared.Longitude, tz)
end

local lastWeather = nil
local lastClock = nil

---Updates the synced weather state if the value has changed.
---@param w string
local function setWeather(w)
    if not w or w == '' then return end

    if lastWeather ~= w then
        lastWeather = w
        GlobalState.ws_weather = w
        dbg(('Weather -> %s'):format(w))
    end
end

---Updates the synced clock payload if the change is large enough to matter.
---@param unix number|string
---@param offsetSeconds number|string
local function setClock(unix, offsetSeconds)
    unix = tonumber(unix)
    offsetSeconds = tonumber(offsetSeconds)

    if not unix or not offsetSeconds then return end

    local payload = {
        unix = unix,
        utc_offset_seconds = offsetSeconds,
        at = os.time()
    }

    if not lastClock or math.abs((payload.unix + payload.utc_offset_seconds) - (lastClock.unix + lastClock.utc_offset_seconds)) >= 30 then
        lastClock = payload
        GlobalState.ws_clock = payload
        dbg(('Clock sync -> unix=%s offset=%s'):format(payload.unix, payload.utc_offset_seconds))
    end
end

local function fallbackInit()
    math.randomseed(os.time())

    setWeather((shared.LockedWeather and shared.LockedWeather ~= '') and shared.LockedWeather or pick(NORMAL_FALLBACK))
    setClock(os.time(), 0)
end

local function fetchAndApply()
    if shared.LockedWeather and shared.LockedWeather ~= '' then
        setWeather(shared.LockedWeather)
        return
    end

    local url = buildUrl()

    PerformHttpRequest(url, function(status, body, headers)
        if status ~= 200 or not body or body == '' then
            dbg(('Fetch failed (status=%s)'):format(status))
            return
        end

        local ok, data = pcall(function()
            return json.decode(body)
        end)

        if not ok or type(data) ~= 'table' then
            dbg('JSON decode failed')
            return
        end

        local current = data.current
        if type(current) ~= 'table' then
            dbg('No current payload')
            return
        end

        local wmo = current.weather_code
        local cloud = current.cloud_cover

        local gtaWeather = mapWmoToGta(wmo, cloud)
        setWeather(gtaWeather)

        local offset = data.utc_offset_seconds
        setClock(os.time(), offset)
    end, 'GET', '', {
        ['Accept'] = 'application/json'
    })
end

CreateThread(function()
    fallbackInit()

    Wait(1000)
    fetchAndApply()

    local fetchMs = clamp((shared.FetchIntervalMinutes or 10), 1, 60) * 60 * 1000

    while true do
        Wait(fetchMs)
        fetchAndApply()
    end
end)

CreateThread(function()
    while true do
        Wait(shared.BroadcastIntervalMs or 5000)

        if shared.LockedWeather and shared.LockedWeather ~= '' then
            setWeather(shared.LockedWeather)
        end

        if lastClock then
            GlobalState.ws_clock = lastClock
        end

        if lastWeather then
            GlobalState.ws_weather = lastWeather
        end
    end
end)

AddEventHandler('playerJoining', function()
    if lastWeather then
        GlobalState.ws_weather = lastWeather
    end

    if lastClock then
        GlobalState.ws_clock = lastClock
    end
end)

lib.addCommand('weather', {
    help = 'View current synced weather and Los Angeles time'
}, function(src)
    local isConsole = (src == 0)

    local weather = GlobalState.ws_weather or 'UNKNOWN'
    local clock = GlobalState.ws_clock

    if not clock or not clock.unix or not clock.utc_offset_seconds then
        local msg = 'Weather sync not ready yet.'

        if isConsole then
            print(('^1[px_climate]^0 %s'):format(msg))
        else
            lib.notify(src, {
                type = 'error',
                title = 'Climate',
                description = msg
            })
        end

        return
    end

    local now = os.time()
    local laTime = now + clock.utc_offset_seconds

    local secInDay = 86400
    local t = laTime % secInDay
    if t < 0 then t = t + secInDay end

    local hour = math.floor(t / 3600)
    local minute = math.floor((t % 3600) / 60)

    local suffix = (hour >= 12) and 'PM' or 'AM'
    local h12 = hour % 12
    if h12 == 0 then h12 = 12 end

    local formattedTime = ('%d:%02d%s'):format(h12, minute, suffix)
    local message = ('Los Angeles Time: %s | Weather: %s'):format(formattedTime, weather)

    if isConsole then
        print(('^3[px_climate]^0 %s'):format(message))
    else
        lib.notify(src, {
            type = 'info',
            title = 'Climate',
            description = message
        })
    end
end)

---Returns the current synced weather type on the server.
---@return string
local function getWeatherTypeServer()
    return tostring(GlobalState.ws_weather or lastWeather or shared.LockedWeather or 'EXTRASUNNY')
end

---Returns the current Los Angeles time as hour, minute, and second.
---@return number|nil, number|nil, number|nil
local function getLATimeHMS_Server()
    local clock = GlobalState.ws_clock or lastClock
    if not clock or not clock.utc_offset_seconds then
        return nil
    end

    local laTime = os.time() + tonumber(clock.utc_offset_seconds)

    local secInDay = 86400
    local t = laTime % secInDay
    if t < 0 then t = t + secInDay end

    local hour = math.floor(t / 3600)
    local minute = math.floor((t % 3600) / 60)
    local second = math.floor(t % 60)

    return hour, minute, second
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

---Returns the current Los Angeles time as a formatted string.
---@return string|nil
local function getLATimeFormatted_Server()
    local h, m = getLATimeHMS_Server()
    if not h then return nil end

    return format12Hour(h, m)
end

exports('getWeatherType', function()
    return getWeatherTypeServer()
end)

exports('getLATime', function()
    local h, m, s = getLATimeHMS_Server()
    return h, m, s
end)

exports('getLATimeFormatted', function()
    return getLATimeFormatted_Server()
end)

exports('getWeatherAndTime', function()
    local weather = getWeatherTypeServer()
    local h, m, s = getLATimeHMS_Server()
    local formatted = (h and format12Hour(h, m)) or nil

    return {
        weather = weather,
        hour = h,
        minute = m,
        second = s,
        formatted = formatted
    }
end)

RegisterNetEvent('px_climate:requestWeatherAndTime', function()
    local src = source
    local data = exports[GetCurrentResourceName()]:getWeatherAndTime()

    TriggerClientEvent('px_climate:responseWeatherAndTime', src, data)
end)