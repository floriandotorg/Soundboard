//
//  SoundBoardCollectionViewController.swift
//  soundboard
//
//  Created by florian on 17.09.15.
//  Copyright © 2015 floyd. All rights reserved.
//

import UIKit
import RAReorderableLayout

private let reuseIdentifier = "Cell"

class SoundBoardViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, SoundBoardCollectionViewCellDelegate, RAReorderableLayoutDelegate {
  var sounds = [SoundData]()
  var shouldFadeIn = false
  var shouldFadeOut = false
  var shouldCrossFade = false
  let fadeTime: NSTimeInterval = 1.5
  
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var crossFadeButton: UIButton!
  @IBOutlet weak var fadeInButton: UIButton!
  @IBOutlet weak var fadeOutButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let layout = self.collectionView?.collectionViewLayout as? RAReorderableLayout
    layout?.delegate = self
    
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(AVAudioSessionCategoryPlayback)
      try session.setActive(true)
      UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
      
      let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
      let directoryContents =  try NSFileManager.defaultManager().contentsOfDirectoryAtPath(documentsUrl.path!)
      
      try self.loadSoundData()
      self.sortSounds()
      
      directoryContents.forEach({ file in
        if (NSString(string: file).pathExtension == "mp3" && !self.sounds.contains({ $0.filename == file })) {
          self.sounds.append(SoundData(filename: file))
        }
      })
      
      self.persistendSort()
      
      self.sounds.forEach({ soundData in
        soundData.sound.completionHandler = { didFinish in
          self.collectionView?.reloadData()
        }
      })
    } catch { }
    
//    self.collectionView?.bringSubviewToFront((self.collectionView?.subviews.first)!)
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Do any additional setup after loading the view.
  }
  
  func getFileURL(fileName: String) throws -> NSURL  {
    let manager = NSFileManager.defaultManager()
    let dirURL = try manager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
    return dirURL.URLByAppendingPathComponent(fileName)
  }
  
  func saveSoundData() throws {
    let filePath = try getFileURL("sounds.lst").path!
    NSKeyedArchiver.archiveRootObject(self.sounds, toFile: filePath)
  }
  
  func loadSoundData() throws {
    let filePath = try getFileURL("sounds.lst").path!
    self.sounds = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [SoundData] ?? [SoundData]()
  }
  
  func soundBoardCollectionViewCell(cell: SoundBoardCollectionViewCell, didChange: SoundData) {
    do {
      try self.saveSoundData()
    } catch { }
  }
  
  func soundBoardCollectionViewCell(cell: SoundBoardCollectionViewCell, getNameForSound: SoundData, completion: ((String?) -> Void)) {
    let alertController = UIAlertController.init(title: "Edit Name", message: "Enter Name", preferredStyle: UIAlertControllerStyle.Alert)
    
    alertController.addTextFieldWithConfigurationHandler({ textField in
      textField.text = getNameForSound.prettyName
    })
    
    let save = UIAlertAction.init(title: "Speichern", style: UIAlertActionStyle.Default, handler: { _ in
      if let text = alertController.textFields?.first?.text {
        completion(text)
      }
    })
    alertController.addAction(save)
    
    let cancel = UIAlertAction.init(title: "Abbrechen", style: UIAlertActionStyle.Cancel, handler: nil)
    alertController.addAction(cancel)
    
    let delete = UIAlertAction.init(title: "Löschen", style: UIAlertActionStyle.Destructive, handler: { _ in
      completion(nil)
    })
    alertController.addAction(delete)
    
    
    self.presentViewController(alertController, animated: true, completion: nil)
  }
  
  
  @IBAction func stopAll(sender: AnyObject) {
    self.sounds.forEach({ soundData in soundData.sound.stop() })
  }
  
  @IBAction func fadeOutAll(sender: UIButton) {
    self.sounds.forEach({ soundData in soundData.sound.fadeOut(self.fadeTime) })
  }
  
  @IBAction func toggleCrossFade(sender: UIButton) {
    self.shouldCrossFade = !self.shouldCrossFade
    if (self.shouldCrossFade) {
      self.shouldFadeIn = false
      self.shouldFadeOut = false
    }
    self.updateButtons()
  }
  
  @IBAction func toggleFadeIn(sender: UIButton) {
    self.shouldFadeIn = !self.shouldFadeIn
    if (self.shouldFadeIn) {
      self.shouldCrossFade = false
    }
    self.updateButtons()
  }
  
  @IBAction func toggleFadeOut(sender: UIButton) {
    self.shouldFadeOut = !self.shouldFadeOut
    if (self.shouldFadeOut) {
      self.shouldCrossFade = false
    }
    self.updateButtons()
  }
  
  func updateButtons() {
    self.fadeOutButton.setTitleColor((self.shouldFadeOut ? self.view.tintColor : UIColor.darkGrayColor()), forState: UIControlState.Normal)
    self.fadeInButton.setTitleColor((self.shouldFadeIn ? self.view.tintColor : UIColor.darkGrayColor()), forState: UIControlState.Normal)
    self.crossFadeButton.setTitleColor((self.shouldCrossFade ? self.view.tintColor : UIColor.darkGrayColor()), forState: UIControlState.Normal)
  }
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using [segue destinationViewController].
  // Pass the selected object to the new view controller.
  }
  */
  
  // MARK: UICollectionViewDataSource
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.sounds.count
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
    return 10.0
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
    return 10.0
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
    return UIEdgeInsetsMake(30, 10, 10 , 10)
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    return CGSizeMake(140, 140)
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! SoundBoardCollectionViewCell
    
    cell.soundData = self.sounds[indexPath.row]
    cell.delegate = self
    
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, atIndexPath: NSIndexPath, didMoveToIndexPath toIndexPath: NSIndexPath) {
    swap(&self.sounds[atIndexPath.row], &self.sounds[toIndexPath.row])
    self.persistendSort()
  }
  
  func sortSounds() {
    self.sounds = self.sounds.sort({ a, b in a.position > b.position })
  }
  
  func persistendSort() {
    for (idx, el) in self.sounds.enumerate() {
      el.position = idx
    }
    
    do {
      try self.saveSoundData()
    } catch { }
  }
  
  // MARK: UICollectionViewDelegate
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    
    let soundData = sounds[indexPath.row];
    
    if (soundData.sound.playing) {
      if (self.shouldFadeOut) {
        soundData.sound.fadeOut(self.fadeTime)
      } else {
        soundData.sound.stop()
      }
    } else {
      soundData.sound.currentTime = 0
      
      if (self.shouldCrossFade) {
        self.sounds.forEach({ el in if (el !== soundData) { el.sound.fadeOut(self.fadeTime) } })
      }
      
      if (self.shouldFadeIn || self.shouldCrossFade) {
        soundData.sound.volume = 0
        soundData.sound.fadeTo(soundData.volume, duration: self.fadeTime)
      } else {
        soundData.sound.volume = soundData.volume
      }
      
      soundData.sound.play()
    }
    
    self.collectionView!.reloadData()
  }
  
  /*
  // Uncomment this method to specify if the specified item should be highlighted during tracking
  override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
  return true
  }
  */
  
  /*
  // Uncomment this method to specify if the specified item should be selected
  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
  return true
  }
  */
  
  /*
  // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
  override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
  return false
  }
  
  override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
  return false
  }
  
  override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
  
  }
  */
  
}
