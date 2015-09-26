//
//  SoundData.swift
//  soundboard
//
//  Created by florian on 18.09.15.
//  Copyright © 2015 floyd. All rights reserved.
//

import AudioToolbox
import SoundManager

class SoundData : NSObject, NSCoding {
  var filename = ""
  var sound = Sound()
  var duration: NSTimeInterval = 0.0
  var position = 0
  var name: String?
  var prettyName: String {
    if let name = self.name {
      return name
    } else {
      return self.filename.substringToIndex(self.filename.endIndex.advancedBy(-4))
    }
  }
  var volume: Float = 0.5 {
    didSet {
      self.sound.volume = self.volume
    }
  }
  
  override init() {
    super.init()
  }
  
  init(filename: String) {
    super.init()
    self.loadSound(filename)
  }
  
  private func loadSound(filename: String) {
    let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
    let soundURL = NSURL(fileURLWithPath: filename, relativeToURL: documentsUrl)
    
    self.filename = filename
    self.sound = Sound(contentsOfURL: soundURL)
    self.duration = self.determineDuration(soundURL)
  }
  
  private func determineDuration(url: NSURL) -> NSTimeInterval {
    var fileID: AudioFileID = AudioFileID()
    AudioFileOpenURL(url, AudioFilePermissions.ReadPermission, 0, &fileID)
    var bitrate: UInt32 = 0
    var bitrateSize: UInt32 = UInt32(sizeof(UInt32))
    AudioFileGetProperty(fileID, kAudioFilePropertyBitRate, &bitrateSize, &bitrate)
    
    var size: UInt64 = 0
    var sizeSize: UInt32 = UInt32(sizeof(UInt64))
    AudioFileGetProperty(fileID, kAudioFilePropertyAudioDataByteCount, &sizeSize, &size)
    
    var depth: UInt32 = 0
    var depthSize: UInt32 = UInt32(sizeof(UInt32))
    AudioFileGetProperty(fileID, kAudioFilePropertySourceBitDepth, &depthSize, &depth)
    
    AudioFileClose(fileID)
    
    return NSTimeInterval(size / UInt64(bitrate / depthSize))
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init()
    let filename = aDecoder.decodeObjectForKey("filename") as? String ?? ""
    self.loadSound(filename)
    self.volume = aDecoder.decodeObjectForKey("volume") as? Float ?? 0.5
    self.sound.looping = aDecoder.decodeObjectForKey("looping") as? Bool ?? false
    
    if (aDecoder.containsValueForKey("name")) {
      self.name = aDecoder.decodeObjectForKey("name") as? String ?? ""
    }
  }
  
  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(self.filename, forKey: "filename")
    aCoder.encodeObject(self.sound.looping, forKey: "looping")
    aCoder.encodeObject(self.volume, forKey: "volume")
    
    if let name = self.name {
      aCoder.encodeObject(name, forKey: "name")
    }
  }
}
