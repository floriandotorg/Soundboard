//
//  SoundBoardCollectionViewCell.swift
//  soundboard
//
//  Created by florian on 17.09.15.
//  Copyright © 2015 floyd. All rights reserved.
//

import UIKit

protocol SoundBoardCollectionViewCellDelegate {
  func soundBoardCollectionViewCell(cell: SoundBoardCollectionViewCell, didChange: SoundData)
  func soundBoardCollectionViewCell(cell: SoundBoardCollectionViewCell, getNameForSound: SoundData, completion: ((String?) -> Void))
}

class SoundBoardCollectionViewCell: UICollectionViewCell, UIAlertViewDelegate {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var loopButton: UIButton!
  
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var endTimeLabel: UILabel!
  @IBOutlet weak var startTimeLabel: UILabel!
  @IBOutlet weak var slider: UISlider!
  
  @IBAction func sliderValueChanged(sender: UISlider) {
    self.soundData.volume = sender.value
    self.delegate?.soundBoardCollectionViewCell(self, didChange: self.soundData)
  }
  
  @IBAction func toggleLoop(sender: UIButton) {
    self.soundData.sound.looping = !soundData.sound.looping
    updateCell()
    self.delegate?.soundBoardCollectionViewCell(self, didChange: self.soundData)
  }
  
  @IBAction func editName(sender: AnyObject) {
    self.delegate?.soundBoardCollectionViewCell(self, getNameForSound: self.soundData, completion: { name in
      self.soundData.name = name
      self.updateCell()
      self.delegate?.soundBoardCollectionViewCell(self, didChange: self.soundData)
    })
  }
  
  var timer: NSTimer?
  var delegate: SoundBoardCollectionViewCellDelegate?
  
  func stringFromTimeInterval(interval: NSTimeInterval) -> String {
    let interval = Int(interval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let hours = (interval / 3600)
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }
  
  func updateCell() {
    self.nameLabel.text = soundData.prettyName

    if (self.soundData.sound.playing) {
      self.backgroundColor = UIColor.redColor()
    } else {
      self.backgroundColor = UIColor.lightGrayColor()
    }
    
    self.loopButton.setTitleColor((self.soundData.sound.looping ? UIColor.blueColor() : UIColor.darkGrayColor()), forState: UIControlState.Normal)
    
    self.slider.value = self.soundData.volume
    
    self.endTimeLabel.text = stringFromTimeInterval(soundData.duration)
    self.updateProgress()
    
    self.timer?.invalidate()
    self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
  }
  
  func updateProgress() {
    self.startTimeLabel.text = stringFromTimeInterval(soundData.sound.currentTime)
    self.progressView.progress = Float(soundData.sound.currentTime / soundData.duration)
  }
  
  var soundData = SoundData() {
    didSet {
      self.updateCell()
    }
  }
}

