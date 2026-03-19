# px_climate

px_climate is a real-time weather and time sync system for FiveM that pulls live data and keeps your server synced automatically.

It uses Open-Meteo to grab real-world weather based on your configured location, converts it into GTA weather types, and syncs it across all players using GlobalState. Time is also synced properly using timezone offsets so it stays accurate without drifting.

Everything is handled server-side and pushed to clients, so there’s no weird desync or flickering.

---

## How it works

When the resource starts, it sets a fallback weather so the server isn’t stuck waiting on the API.

After that, it requests live weather data using your latitude, longitude, and timezone. The returned weather code gets mapped into a GTA weather type like CLEAR, RAIN, FOGGY, etc.

That weather gets stored in GlobalState and is automatically applied on all clients.

Time works the same way. The server calculates the correct Los Angeles time using the API offset, then clients continuously update their clock based on that value so it stays smooth and accurate.

If the API fails at any point, nothing breaks. It just keeps the last known state and retries on the next interval.

---

## Installation

Put the resource in your resources folder and add:

ensure px_climate

Then open:

config/shared.lua

and set your location, intervals, and optional weather lock.

---

## Config

Latitude and Longitude control where the weather is pulled from.

Timezone controls the time sync and handles daylight saving automatically.

FetchIntervalMinutes controls how often weather is updated.

BroadcastIntervalMs controls how often the server pushes updates.

WeatherTransitionSeconds controls how smooth weather changes are.

LockedWeather will force a specific weather and disable live syncing if you set it.

---

## Command

/weather

Shows the current synced weather and Los Angeles time.

---

## Exports

exports['px_climate']:getWeatherType()

Returns current weather type.

exports['px_climate']:getLATime()

Returns hour, minute, second.

exports['px_climate']:getLATimeFormatted()

Returns formatted time like 1:42PM.

exports['px_climate']:getWeatherAndTime()

Returns everything in one table.

---

## Notes

Everything is server controlled.

Clients just apply what they receive.

No constant API spam, no heavy loops, no unnecessary logic.

If you want static weather, just set LockedWeather and it overrides everything.

---

## Dependencies

https://github.com/overextended/ox_lib

---

## Support

https://discord.gg/pinkable

---

## License

This resource is licensed for use on your server only.

Reselling, redistributing, sharing this resource in any form is strictly prohibited.