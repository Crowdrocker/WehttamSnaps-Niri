import QtQuick
import Quickshell
import qs.Commons
import qs.Services.Keyboard

Item {
  id: root

  // Plugin metadata
  property string name: I18n.tr("plugins.emoji")
  property var launcher: null
  property bool handleSearch: false

  property string selectedCategory: "recent"
  property bool isBrowsingMode: false

  property var categoryIcons: ({
                                 "recent": "clock",
                                 "people": "user",
                                 "animals": "paw",
                                 "nature": "leaf",
                                 "food": "apple",
                                 "activity": "run",
                                 "travel": "plane",
                                 "objects": "home",
                                 "symbols": "star",
                                 "flags": "flag"
                               })

  property var categories: ["recent", "people", "animals", "nature", "food", "activity", "travel", "objects", "symbols", "flags"]

  // Force update results when emoji service loads
  Connections {
    target: EmojiService
    function onLoadedChanged() {
      if (EmojiService.loaded && root.launcher) {
        root.launcher.updateResults();
      }
    }
  }

  // Initialize plugin
  function init() {
    Logger.i("EmojiPlugin", "Initialized");
  }

  function selectCategory(category) {
    selectedCategory = category;
    if (launcher) {
      launcher.updateResults();
    }
  }

  function onOpened() {
    // Always reset to "recent" category when opening
    selectedCategory = "recent";
  }

  // Check if this plugin handles the command
  function handleCommand(searchText) {
    return searchText.startsWith(">emoji");
  }

  // Return available commands when user types ">"
  function commands() {
    return [
          {
            "name": ">emoji",
            "description": I18n.tr("plugins.emoji-search-description"),
            "icon": "face-smile",
            "isImage": false,
            "onActivate": function () {
              launcher.setSearchText(">emoji ");
            }
          }
        ];
  }

  // Get search results
  function getResults(searchText) {
    if (!searchText.startsWith(">emoji")) {
      return [];
    }

    if (!EmojiService.loaded) {
      return [
            {
              "name": I18n.tr("plugins.emoji-loading"),
              "description": I18n.tr("plugins.emoji-loading-description"),
              "icon": "view-refresh",
              "isImage": false,
              "onActivate": function () {}
            }
          ];
    }

    var query = searchText.slice(6).trim();

    if (query === "") {
      isBrowsingMode = true;
      var emojis = EmojiService.getEmojisByCategory(selectedCategory);
      return emojis.map(formatEmojiEntry);
    } else {
      isBrowsingMode = false;
      var emojis = EmojiService.search(query);
      return emojis.map(formatEmojiEntry);
    }
  }

  // Format an emoji entry for the results list
  function formatEmojiEntry(emoji) {
    let title = emoji.name;
    let description = emoji.keywords.join(", ");

    if (emoji.category) {
      description += " • Category: " + emoji.category;
    }

    const emojiChar = emoji.emoji;

    return {
      "name": title,
      "description": description,
      "icon": null,
      "isImage": false,
      "emojiChar": emojiChar,
      "onActivate": function () {
        EmojiService.copy(emojiChar);
        launcher.close();
      }
    };
  }
}
