pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import "root:"

/**
 * AnimeService - Jikan API (MyAnimeList unofficial API)
 * Provides anime schedule, seasonal anime, and search functionality
 * API Docs: https://docs.api.jikan.moe/
 */
Singleton {
    id: root

    readonly property string baseUrl: "https://api.jikan.moe/v4"
    
    // Rate limiting: Jikan allows 3 requests/second, 60/minute
    property int requestDelay: 350  // ms between requests
    property bool _canRequest: true
    
    // Current data
    property var schedule: []           // Today's airing anime
    property var seasonalAnime: []      // Current season anime
    property var topAiring: []          // Top airing anime
    property string currentDay: Qt.formatDate(new Date(), "dddd").toLowerCase()
    
    // Loading states
    property bool loadingSchedule: false
    property bool loadingSeasonal: false
    property bool loadingTop: false
    property bool loading: loadingSchedule || loadingSeasonal || loadingTop
    
    // Error handling
    property string lastError: ""
    
    // Cache timestamps
    property var _cacheTimestamps: ({})
    property var _scheduleCache: ({})  // Cache schedule data per day
    readonly property int cacheValidityMs: 10 * 60 * 1000  // 10 minutes
    
    Timer {
        id: rateLimitTimer
        interval: root.requestDelay
        onTriggered: root._canRequest = true
    }
    
    function _makeRequest(endpoint, callback) {
        if (!root._canRequest) {
            Qt.callLater(() => root._makeRequest(endpoint, callback))
            return
        }
        
        root._canRequest = false
        rateLimitTimer.start()
        
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        callback(response.data, null)
                    } catch (e) {
                        callback(null, "Parse error: " + e.message)
                    }
                } else if (xhr.status === 429) {
                    root.lastError = "Rate limited, retrying..."
                    Qt.callLater(() => {
                        rateLimitTimer.interval = 1000
                        root._makeRequest(endpoint, callback)
                    })
                } else {
                    callback(null, "HTTP " + xhr.status)
                }
            }
        }
        xhr.open("GET", root.baseUrl + endpoint)
        xhr.setRequestHeader("Accept", "application/json")
        xhr.send()
    }
    
    function _isCacheValid(key) {
        const timestamp = root._cacheTimestamps[key]
        if (!timestamp) return false
        return (Date.now() - timestamp) < root.cacheValidityMs
    }
    
    function _updateCache(key) {
        const timestamps = root._cacheTimestamps
        timestamps[key] = Date.now()
        root._cacheTimestamps = timestamps
    }
    
    /**
     * Get anime schedule for a specific day
     * @param day - monday, tuesday, etc. or "today"
     */
    function fetchSchedule(day) {
        const targetDay = day === "today" ? root.currentDay : day
        const cacheKey = "schedule_" + targetDay
        
        // Check if we have cached data for THIS specific day
        if (root._isCacheValid(cacheKey) && root._scheduleCache[targetDay]) {
            root.schedule = root._scheduleCache[targetDay]
            return
        }
        
        root.loadingSchedule = true
        root.lastError = ""
        
        // showNsfw: true = show all, false/undefined = filter to SFW only
        const sfw = (Config.options?.sidebar?.animeSchedule?.showNsfw ?? false) ? "" : "&sfw=true"
        
        root._makeRequest("/schedules?filter=" + targetDay + sfw + "&limit=25", (data, error) => {
            root.loadingSchedule = false
            if (error) {
                root.lastError = error
                return
            }
            const normalized = data.map(anime => root._normalizeAnime(anime))
            // Cache the data for this day
            root._scheduleCache[targetDay] = normalized
            root.schedule = normalized
            root._updateCache(cacheKey)
        })
    }
    
    /**
     * Get current season anime
     */
    function fetchSeasonalAnime() {
        const cacheKey = "seasonal"
        
        if (root._isCacheValid(cacheKey) && root.seasonalAnime.length > 0) {
            return
        }
        
        root.loadingSeasonal = true
        root.lastError = ""
        
        const sfw = (Config.options?.sidebar?.animeSchedule?.showNsfw ?? false) ? "" : "&sfw=true"
        
        root._makeRequest("/seasons/now?limit=25" + sfw, (data, error) => {
            root.loadingSeasonal = false
            if (error) {
                root.lastError = error
                return
            }
            root.seasonalAnime = data.map(anime => root._normalizeAnime(anime))
            root._updateCache(cacheKey)
        })
    }
    
    /**
     * Get top airing anime
     */
    function fetchTopAiring() {
        const cacheKey = "top_airing"
        
        if (root._isCacheValid(cacheKey) && root.topAiring.length > 0) {
            return
        }
        
        root.loadingTop = true
        root.lastError = ""
        
        const sfw = (Config.options?.sidebar?.animeSchedule?.showNsfw ?? false) ? "" : "&sfw=true"
        
        root._makeRequest("/top/anime?filter=airing" + sfw + "&limit=25", (data, error) => {
            root.loadingTop = false
            if (error) {
                root.lastError = error
                return
            }
            root.topAiring = data.map(anime => root._normalizeAnime(anime))
            root._updateCache(cacheKey)
        })
    }
    
    /**
     * Normalize anime data to consistent format
     */
    function _normalizeAnime(anime) {
        return {
            id: anime.mal_id,
            title: anime.title,
            titleEnglish: anime.title_english ?? anime.title,
            titleJapanese: anime.title_japanese ?? "",
            image: anime.images?.jpg?.large_image_url ?? anime.images?.jpg?.image_url ?? "",
            imageSmall: anime.images?.jpg?.small_image_url ?? anime.images?.jpg?.image_url ?? "",
            score: anime.score ?? 0,
            members: anime.members ?? 0,
            episodes: anime.episodes ?? "?",
            status: anime.status ?? "",
            airing: anime.airing ?? false,
            synopsis: anime.synopsis ?? "",
            genres: (anime.genres ?? []).map(g => g.name),
            studios: (anime.studios ?? []).map(s => s.name),
            source: anime.source ?? "",
            rating: anime.rating ?? "",
            broadcast: anime.broadcast?.string ?? "",
            url: anime.url ?? "",
            type: anime.type ?? "TV",
            season: anime.season ?? "",
            year: anime.year ?? ""
        }
    }
    
    /**
     * Refresh all data
     */
    function refresh() {
        root._cacheTimestamps = {}
        root._scheduleCache = {}
        root.fetchSchedule("today")
    }
    
    /**
     * Get day name for display
     */
    function getDayName(day) {
        const days = {
            "monday": "Monday",
            "tuesday": "Tuesday", 
            "wednesday": "Wednesday",
            "thursday": "Thursday",
            "friday": "Friday",
            "saturday": "Saturday",
            "sunday": "Sunday"
        }
        return days[day] ?? day
    }
    
    /**
     * Format broadcast time
     */
    function formatBroadcast(broadcast) {
        if (!broadcast) return ""
        // Jikan returns format like "Sundays at 00:00 (JST)"
        return broadcast.replace(" (JST)", " JST")
    }
    
    Component.onCompleted: {
        // Auto-fetch on load if enabled
        if (Config.options?.sidebar?.animeSchedule?.enable) {
            Qt.callLater(() => root.fetchSchedule("today"))
        }
    }
}
