local RESOURCE_NAME = GetCurrentResourceName()
local VERSION_URL = 'https://raw.githubusercontent.com/Pinkablee/versions/main/climate.txt'

local function parseVersion(version)
    local major, minor, patch = tostring(version or ''):match('^(%d+)%.(%d+)%.(%d+)$')

    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0
    }
end

local function isRemoteVersionNewer(currentVersion, remoteVersion)
    local current = parseVersion(currentVersion)
    local remote = parseVersion(remoteVersion)

    if remote.major ~= current.major then
        return remote.major > current.major
    end

    if remote.minor ~= current.minor then
        return remote.minor > current.minor
    end

    return remote.patch > current.patch
end

local function printVersionMessage(messageType, message)
    local prefixes = {
        success = '^2[Version Check]^0',
        warning = '^3[Version Check]^0',
        error = '^1[Version Check]^0'
    }

    print(('%s %s'):format(prefixes[messageType] or prefixes.warning, message))
end

CreateThread(function()
    local currentVersion = GetResourceMetadata(RESOURCE_NAME, 'version', 0) or '0.0.0'

    PerformHttpRequest(VERSION_URL, function(statusCode, responseBody)
        if statusCode ~= 200 or not responseBody or responseBody == '' then
            printVersionMessage('error', ('Unable to retrieve the latest version information for %s.'):format(RESOURCE_NAME))
            return
        end

        local latestVersion = responseBody:match('%d+%.%d+%.%d+')

        if not latestVersion then
            printVersionMessage('error', ('The remote version response for %s was invalid.'):format(RESOURCE_NAME))
            return
        end

        if isRemoteVersionNewer(currentVersion, latestVersion) then
            printVersionMessage(
                'warning',
                ('An update is available for %s. Current version: ^1%s^0 | Latest version: ^2%s^0'):format(
                    RESOURCE_NAME,
                    currentVersion,
                    latestVersion
                )
            )
            return
        end

        printVersionMessage(
            'success',
            ('%s is up to date. Current version: ^2%s^0'):format(RESOURCE_NAME, currentVersion)
        )
    end, 'GET')
end)