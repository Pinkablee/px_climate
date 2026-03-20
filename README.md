# px_climate

px_climate is a real-time weather and time sync system for FiveM built to keep your server environment updated automatically with a cleaand lightweight setup.

It pulls live weather data from your configured location, converts it into GTA weather states, and syncs both weather and time across thserver without the bloated feel of larger climate resources.

Everything is handled server-side and pushed cleanly to clients, so the system stays practical, smooth, and easy to maintain.

---

## How it works

g 
When the resource starts, it applies a fallback weather state so the server always has a valid environment while live data is being 
fetched.

After that, it requests weather data using your configured latitude, longitude, and timezone. The returned weather values are mapped intGTA weather types such as clear, rain, fog, and similar states.

Weather is stored server-side and synced to all clients so everyone stays consistent.

t
Time is handled the same way. The resource calculates the correct synced time using the configured timezone and keeps it updated without
drifting.

If the API fails at any point, nothing breaks. The script keeps the last known state and retries again on the next update interval.

---

## Features

- Real-time weather syncing based on a configured location
- Automatic time syncing with timezone-aware handling
- GTA weather state mapping from live weather data
- Fully server-side controlled syncing
- Smooth weather transitions for a cleaner result
- Configurable update intervals and optional forced weather
- Lightweight structure built for simple deployment and easy maintenance

---

## Installation

Put the resource in your resources folder and add:

ensure px_climate

Then open:

config/shared.lua

and configure your location, timezone, update intervals, and optional locked weather settings.

---

## Config

Latitude and Longitude control where live weather data is pulled from.

Timezone controls how server time is calculated and synced.

FetchIntervalMinutes controls how often new weather data is requested.

BroadcastIntervalMs controls how often the server pushes updates.

WeatherTransitionSeconds controls how smoothly weather changes are applied.

LockedWeather lets you force a specific weather type instead of using live syncing.

---

## Command

/weather

Displays the current synced weather and current synced time.

---

## Exports

exports['px_climate']:getWeatherType()

Returns the current synced weather type.

exports['px_climate']:getLATime()

Returns the current synced hour, minute, and second.

exports['px_climate']:getLATimeFormatted()

Returns the current synced time in a formatted string.

exports['px_climate']:getWeatherAndTime()

Returns the synced weather and time data in one table.

---

## Notes

Everything is controlled server-side and clients only apply the synced state they receive.

The resource is built to avoid unnecessary loops, constant API spam, or messy client-side handling.

If you want a static setup instead of live weather, you can set LockedWeather and force a specific climate state.

---

## Dependencies

https://github.com/overextended/ox_lib

---

## Support

https://discord.gg/pinkable