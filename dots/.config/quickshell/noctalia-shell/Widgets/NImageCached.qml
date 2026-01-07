pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io
import "../Helpers/sha256.js" as Checksum
import qs.Commons

Image {
  id: root

  property string imagePath: ""
  property string imageHash: ""
  property string cacheFolder: Settings.cacheDirImages
  property int maxCacheDimension: 384
  readonly property string cachePath: imageHash ? `${cacheFolder}${imageHash}@${maxCacheDimension}x${maxCacheDimension}.png` : ""

  asynchronous: true
  fillMode: Image.PreserveAspectCrop
  sourceSize.width: maxCacheDimension
  sourceSize.height: maxCacheDimension
  smooth: true
  onImagePathChanged: {
    if (imagePath) {
      imageHash = Checksum.sha256(imagePath);
      // Logger.i("NImageCached", imagePath, imageHash)
    } else {
      source = "";
      imageHash = "";
    }
  }
  onCachePathChanged: {
    if (imageHash && cachePath) {
      // Try to load the cached version, failure will be detected below in onStatusChanged
      // Failure is expected and warnings are ok in the console. Don't try to improve without consulting.
      source = cachePath;
    }
  }
  onStatusChanged: {
    if (source == cachePath && status === Image.Error) {
      // Cached image was not available, show the original
      source = imagePath;
    } else if (source == imagePath && status === Image.Ready && imageHash && cachePath) {
      // Original image is shown and fully loaded, time to cache it
      const grabPath = cachePath;
      if (visible && width > 0 && height > 0 && Window.window && Window.window.visible)
      grabToImage(res => {
                    return res.saveToFile(grabPath);
                  });
    }
  }
}
