return {
    -- World latitude used for real weather data (Open-Meteo API)
    -- Example: Los Angeles = 34.0522
    Latitude = 34.0522,

    -- World longitude used for real weather data
    -- Example: Los Angeles = -118.2437
    Longitude = -118.2437,

    -- Timezone used for automatic DST handling
    -- Must match Open-Meteo supported timezone format
    Timezone = 'America/Los_Angeles',

    -- How often the server requests real weather data (in minutes)
    -- Recommended: 5–15 minutes
    FetchIntervalMinutes = 10,

    -- How often weather/time is pushed to clients (milliseconds)
    -- Lower = more responsive, higher = less network usage
    BroadcastIntervalMs = 5000,

    -- Duration of smooth weather transitions (client-side)
    WeatherTransitionSeconds = 15.0,

    -- Forces a fixed weather type and disables API syncing
    -- Leave empty ('') to enable real-time weather
    -- Valid values:
    -- EXTRASUNNY, CLEAR, NEUTRAL, SMOG, FOGGY, OVERCAST,
    -- CLOUDS, CLEARING, RAIN, THUNDER, SNOW, BLIZZARD,
    -- SNOWLIGHT, XMAS, HALLOWEEN
    LockedWeather = '',

    -- Enables console debug logs for troubleshooting
    Debug = false,
}