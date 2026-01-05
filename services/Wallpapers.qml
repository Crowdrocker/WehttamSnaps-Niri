pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "root:"

Singleton {
    id: root

    // Wallpaper path resolution for aurora/backdrop
    readonly property bool isWaffleFamily: (Config.options?.panelFamily ?? "ii") === "waffle"
    readonly property bool useBackdropWallpaper: isWaffleFamily
        ? (Config.options?.waffles?.background?.backdrop?.hideWallpaper ?? false)
        : (Config.options?.background?.backdrop?.hideWallpaper ?? false)

    readonly property string effectiveWallpaperPath: {
        function isVideoFile(path: string): bool {
            return path.endsWith(".mp4") || path.endsWith(".webm") || path.endsWith(".mkv") || path.endsWith(".avi") || path.endsWith(".mov")
        }
        if (useBackdropWallpaper) {
            if (isWaffleFamily) {
                const wBackdrop = Config.options?.waffles?.background?.backdrop ?? {}
                const useBackdropOwn = !(wBackdrop.useMainWallpaper ?? true)
                if (useBackdropOwn && wBackdrop.wallpaperPath) return wBackdrop.wallpaperPath
                const wBg = Config.options?.waffles?.background ?? {}
                const useMainForWaffle = wBg.useMainWallpaper ?? true
                return useMainForWaffle ? (Config.options?.background?.wallpaperPath ?? "") : (wBg.wallpaperPath || (Config.options?.background?.wallpaperPath ?? ""))
            }
            const iiBackdrop = Config.options?.background?.backdrop ?? {}
            const useMain = iiBackdrop.useMainWallpaper ?? true
            const mainPath = Config.options?.background?.wallpaperPath ?? ""
            return useMain ? mainPath : (iiBackdrop.wallpaperPath || mainPath)
        }
        if (isWaffleFamily) {
            const wBg = Config.options?.waffles?.background ?? {}
            const useMain = wBg.useMainWallpaper ?? true
            if (useMain) {
                const mainWp = Config.options?.background?.wallpaperPath ?? ""
                return isVideoFile(mainWp) ? (Config.options?.background?.thumbnailPath ?? mainWp) : mainWp
            }
            return wBg.wallpaperPath || (Config.options?.background?.wallpaperPath ?? "")
        }
        const mainWp = Config.options?.background?.wallpaperPath ?? ""
        return isVideoFile(mainWp) ? (Config.options?.background?.thumbnailPath ?? mainWp) : mainWp
    }

    readonly property string effectiveWallpaperUrl: {
        const path = root.effectiveWallpaperPath
        if (!path || path.length === 0) return ""
        return path.startsWith("file://") ? path : ("file://" + path)
    }

    property string thumbgenScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/thumbgen-venv.sh`
    property string generateThumbnailsMagickScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/generate-thumbnails-magick.sh`
    property alias directory: folderModel.folder
    readonly property string effectiveDirectory: FileUtils.trimFileProtocol(folderModel.folder.toString())
    property url defaultFolder: Qt.resolvedUrl(`${Directories.pictures}/Wallpapers`)
    property alias folderModel: folderModel
    property string searchQuery: ""
    readonly property list<string> extensions: ["jpg", "jpeg", "png", "webp", "avif", "bmp", "svg", "gif", "mp4", "webm", "mkv", "avi", "mov"]
    property list<string> wallpapers: []
    readonly property bool thumbnailGenerationRunning: thumbgenProc.running
    property real thumbnailGenerationProgress: 0

    signal changed()
    signal folderChanged()
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    function load() {}
    function refresh() {} // Compatibility - FolderListModel auto-refreshes

    Process { id: applyProc }
    
    function openFallbackPicker(darkMode = Appearance.m3colors.darkmode) {
        applyProc.exec([Directories.wallpaperSwitchScriptPath, "--mode", (darkMode ? "dark" : "light")])
    }

    function apply(path, darkMode = Appearance.m3colors.darkmode) {
        if (!path || path.length === 0) return
        applyProc.exec([Directories.wallpaperSwitchScriptPath, "--image", path, "--mode", (darkMode ? "dark" : "light")])
        root.changed()
    }

    Process {
        id: selectProc
        property string filePath: ""
        property bool darkMode: Appearance.m3colors.darkmode
        function select(filePath, darkMode = Appearance.m3colors.darkmode) {
            selectProc.filePath = filePath
            selectProc.darkMode = darkMode
            selectProc.exec(["test", "-d", FileUtils.trimFileProtocol(filePath)])
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                setDirectory(selectProc.filePath)
                return
            }
            root.apply(selectProc.filePath, selectProc.darkMode)
        }
    }

    function select(filePath, darkMode = Appearance.m3colors.darkmode) {
        selectProc.select(filePath, darkMode)
    }

    function randomFromCurrentFolder(darkMode = Appearance.m3colors.darkmode) {
        if (folderModel.count === 0) return
        const randomIndex = Math.floor(Math.random() * folderModel.count)
        const filePath = folderModel.get(randomIndex, "filePath")
        root.select(filePath, darkMode)
    }

    Process {
        id: validateDirProc
        property string nicePath: ""
        property bool _pendingFileCheck: false
        function setDirectoryIfValid(path) {
            validateDirProc.nicePath = FileUtils.trimFileProtocol(path).replace(/\/+$/, "")
            if (/^\/*$/.test(validateDirProc.nicePath)) validateDirProc.nicePath = "/"
            validateDirProc._pendingFileCheck = false
            validateDirProc.exec(["test", "-d", validateDirProc.nicePath])
        }
        onExited: (exitCode, exitStatus) => {
            if (!validateDirProc._pendingFileCheck) {
                if (exitCode === 0) {
                    root.directory = Qt.resolvedUrl(validateDirProc.nicePath)
                    return
                }
                validateDirProc._pendingFileCheck = true
                validateDirProc.exec(["test", "-f", validateDirProc.nicePath])
                return
            }
            if (exitCode === 0) {
                root.directory = Qt.resolvedUrl(FileUtils.parentDirectory(validateDirProc.nicePath))
            }
        }
    }

    function setDirectory(path) {
        validateDirProc.setDirectoryIfValid(path)
    }
    function navigateUp() {
        folderModel.navigateUp()
    }
    function navigateBack() {
        folderModel.navigateBack()
    }
    function navigateForward() {
        folderModel.navigateForward()
    }

    FolderListModelWithHistory {
        id: folderModel
        folder: Qt.resolvedUrl(root.defaultFolder)
        caseSensitive: false
        nameFilters: {
            const query = root.searchQuery.trim().toLowerCase()
            // Check if query is an extension filter (e.g., ".gif", ".mp4")
            if (query.startsWith(".")) {
                const ext = query.slice(1)
                if (root.extensions.includes(ext)) return [`*.${ext}`]
            }
            // Normal search: apply query to all extensions
            const searchParts = query.split(" ").filter(s => s.length > 0).map(s => `*${s}*`).join("")
            return root.extensions.map(ext => `*${searchParts}*.${ext}`)
        }
        showDirs: true
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: false
        onCountChanged: {
            root.wallpapers = []
            for (let i = 0; i < folderModel.count; i++) {
                const path = folderModel.get(i, "filePath") || FileUtils.trimFileProtocol(folderModel.get(i, "fileURL"))
                if (path && path.length) root.wallpapers.push(path)
            }
        }
        onFolderChanged: root.folderChanged()
    }

    property string _pendingThumbnailSize: ""
    property string _pendingThumbnailDir: ""
    
    function generateThumbnail(size: string) {
        if (!["normal", "large", "x-large", "xx-large"].includes(size)) throw new Error("Invalid thumbnail size")
        root._pendingThumbnailSize = size
        root._pendingThumbnailDir = FileUtils.trimFileProtocol(root.directory)
        thumbgenDebounce.restart()
    }
    
    Timer {
        id: thumbgenDebounce
        interval: 300
        onTriggered: {
            if (thumbgenProc.running) return
            thumbgenProc.directory = root._pendingThumbnailDir
            thumbgenProc._size = root._pendingThumbnailSize
            thumbgenProc.command = [thumbgenScriptPath, "--size", root._pendingThumbnailSize, "--machine_progress", "--only_images", "-d", root._pendingThumbnailDir]
            root.thumbnailGenerationProgress = 0
            thumbgenProc.running = true
        }
    }

    Process {
        id: thumbgenProc
        property string directory
        property string _size: ""
        environment: ({
            "ILLOGICAL_IMPULSE_VIRTUAL_ENV": Quickshell.env("HOME") + "/.local/state/quickshell/.venv"
        })
        stdout: SplitParser {
            onRead: data => {
                let match = data.match(/PROGRESS (\d+)\/(\d+)/)
                if (match) root.thumbnailGenerationProgress = parseInt(match[1]) / parseInt(match[2])
                match = data.match(/FILE (.+)/)
                if (match) root.thumbnailGeneratedFile(match[1])
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                thumbgenFallbackProc.command = [generateThumbnailsMagickScriptPath, "--size", thumbgenProc._size, "-d", FileUtils.trimFileProtocol(thumbgenProc.directory)]
                thumbgenFallbackProc.running = true
                return
            }
            root.thumbnailGenerated(thumbgenProc.directory)
        }
    }

    Process {
        id: thumbgenFallbackProc
        onExited: root.thumbnailGenerated(thumbgenProc.directory)
    }
}
