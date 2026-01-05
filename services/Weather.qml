pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

Singleton {
    id: root

    readonly property bool enabled: Config.options?.bar?.weather?.enable ?? false
    readonly property int fetchInterval: (Config.options?.bar?.weather?.fetchInterval ?? 10) * 60 * 1000
    readonly property bool useUSCS: Config.options?.bar?.weather?.useUSCS ?? false

    property var location: ({ valid: false, lat: 0, lon: 0, name: "" })

    property var data: ({
        uv: "0",
        humidity: "0%",
        sunrise: "--:--",
        sunset: "--:--",
        windDir: "N",
        wCode: "113",
        city: "City",
        wind: "0 km/h",
        precip: "0 mm",
        visib: "10 km",
        press: "1013 hPa",
        temp: "--°C",
        tempFeelsLike: "--°C"
    })

    function isNightNow(): bool {
        const h = new Date().getHours();
        return h < 6 || h >= 18;
    }

    function refineData(apiData) {
        if (!apiData?.current) return;
        
        const current = apiData.current;
        const astro = apiData.astronomy;
        
        let result = {};
        result.uv = current.uvIndex ?? "0";
        result.humidity = (current.humidity ?? 0) + "%";
        result.sunrise = astro?.sunrise ?? "--:--";
        result.sunset = astro?.sunset ?? "--:--";
        result.windDir = current.winddir16Point ?? "N";
        result.wCode = current.weatherCode ?? "113";
        result.city = root.location.name || "Unknown";

        if (root.useUSCS) {
            result.temp = (current.temp_F ?? 0) + "°F";
            result.tempFeelsLike = (current.FeelsLikeF ?? 0) + "°F";
            result.wind = (current.windspeedMiles ?? 0) + " mph";
            result.precip = (current.precipInches ?? 0) + " in";
            result.visib = (current.visibilityMiles ?? 0) + " mi";
            result.press = (current.pressureInches ?? 0) + " inHg";
        } else {
            result.temp = (current.temp_C ?? 0) + "°C";
            result.tempFeelsLike = (current.FeelsLikeC ?? 0) + "°C";
            result.wind = (current.windspeedKmph ?? 0) + " km/h";
            result.precip = (current.precipMM ?? 0) + " mm";
            result.visib = (current.visibility ?? 0) + " km";
            result.press = (current.pressure ?? 0) + " hPa";
        }

        root.data = result;
        console.info("[Weather] Updated:", result.temp, result.city);
    }

    // Step 1: Get location from IP (primary method)
    function getLocation() {
        if (ipLocator.running) return;
        console.info("[Weather] Getting location...");
        ipLocator.running = true;
    }

    // Step 2: Fetch weather using city name (more accurate than coordinates)
    function fetchWeather() {
        if (!root.location.valid || fetcher.running) return;
        
        const city = encodeURIComponent(root.location.name.split(',')[0].trim());
        const cmd = `curl -s --max-time 15 'wttr.in/${city}?format=j1' | jq '{current: .current_condition[0], astronomy: .weather[0].astronomy[0]}'`;
        fetcher.command = ["/usr/bin/bash", "-c", cmd];
        fetcher.running = true;
    }

    function getData() {
        if (root.location.valid) {
            fetchWeather();
        } else {
            getLocation();
        }
    }

    // Retry timer for when network isn't ready at startup
    property int _retryCount: 0
    Timer {
        id: retryTimer
        interval: 5000  // 5 seconds between retries
        repeat: false
        onTriggered: {
            if (!root.location.valid && root._retryCount < 3) {
                root._retryCount++;
                console.info("[Weather] Retry attempt", root._retryCount);
                root.getLocation();
            }
        }
    }

    onEnabledChanged: {
        if (enabled && Config.ready) retryTimer.start();
    }
    onUseUSCSChanged: fetchWeather()

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && root.enabled) {
                retryTimer.start();
            }
        }
    }

    // IP geolocation (ip-api.com - accurate)
    Process {
        id: ipLocator
        command: ["/usr/bin/curl", "-s", "--max-time", "10", "http://ip-api.com/json/?fields=lat,lon,city,regionName"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    console.warn("[Weather] IP location empty, trying fallback");
                    fallbackLocator.running = true;
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    if (data.lat && data.lon) {
                        root.location = {
                            valid: true,
                            lat: data.lat,
                            lon: data.lon,
                            name: data.city + (data.regionName ? `, ${data.regionName}` : "")
                        };
                        console.info("[Weather] Location:", root.location.name);
                        root.fetchWeather();
                    } else {
                        fallbackLocator.running = true;
                    }
                } catch (e) {
                    console.error("[Weather] IP location error:", e.message);
                    fallbackLocator.running = true;
                }
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                console.warn("[Weather] IP location failed, trying fallback");
                fallbackLocator.running = true;
            }
        }
    }

    // Fallback: ipwho.is
    Process {
        id: fallbackLocator
        command: ["/usr/bin/curl", "-s", "--max-time", "10", "https://ipwho.is/"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                try {
                    const data = JSON.parse(text);
                    if (data.latitude && data.longitude) {
                        root.location = {
                            valid: true,
                            lat: data.latitude,
                            lon: data.longitude,
                            name: data.city + (data.region ? `, ${data.region}` : "")
                        };
                        console.info("[Weather] Location (fallback):", root.location.name);
                        root.fetchWeather();
                    } else {
                        // Both methods failed, schedule retry
                        retryTimer.start();
                    }
                } catch (e) {
                    console.error("[Weather] Fallback location error:", e.message);
                    retryTimer.start();
                }
            }
        }
        onExited: (code) => {
            // If fallback also fails, schedule retry
            if (code !== 0 && !root.location.valid) {
                retryTimer.start();
            }
        }
    }

    // Weather fetcher
    Process {
        id: fetcher
        command: ["/usr/bin/bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    console.warn("[Weather] Empty response");
                    retryTimer.start();
                    return;
                }
                try {
                    root.refineData(JSON.parse(text));
                } catch (e) {
                    console.error("[Weather] Parse error:", e.message);
                    retryTimer.start();
                }
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                console.error("[Weather] Fetch failed, code:", code);
                retryTimer.start();
            }
        }
    }

    Timer {
        id: fetchTimer
        running: root.enabled && Config.ready
        repeat: true
        interval: root.fetchInterval > 0 ? root.fetchInterval : 600000
        onTriggered: root.getData()
        onRunningChanged: {
            if (running) Qt.callLater(() => root.getData())
        }
    }
}
