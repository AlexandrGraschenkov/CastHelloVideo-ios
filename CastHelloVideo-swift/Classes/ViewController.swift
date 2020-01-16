// Copyright 2019 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import GoogleCast
import UIKit

@objc(ViewController)
class ViewController: UIViewController, GCKSessionManagerListener, GCKRemoteMediaClientListener, GCKRequestDelegate {
  @IBOutlet var castVideoButton: UIButton!
  @IBOutlet var castInstructionLabel: UILabel!

  private var castButton: GCKUICastButton!
  private var mediaInformation: GCKMediaInformation?
  private var sessionManager: GCKSessionManager!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initially hide the cast button until a session is started.
    showLoadVideoButton(showButton: false)

    sessionManager = GCKCastContext.sharedInstance().sessionManager
    sessionManager.add(self)

    // Add cast button.
    castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))

    // Used to overwrite the theme in AppDelegate.
    castButton.tintColor = .darkGray

    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(castDeviceDidChange(notification:)),
                                           name: NSNotification.Name.gckCastStateDidChange,
                                           object: GCKCastContext.sharedInstance())
  }

  @objc func castDeviceDidChange(notification _: Notification) {
    if GCKCastContext.sharedInstance().castState != GCKCastState.noDevicesAvailable {
      // Display the instructions for how to use Google Cast on the first app use.
      GCKCastContext.sharedInstance().presentCastInstructionsViewControllerOnce(with: castButton)
    }
  }

  // MARK: Cast Actions

    func playVideoRemotely() {
      GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()

      // Define media metadata.
      let metadata = GCKMediaMetadata()

      let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: URL(string: "https://www.dropbox.com/s/bqhmu0vx6d2ol6w/video.mkv?dl=1")!)
      mediaInfoBuilder.streamType = GCKMediaStreamType.none
      mediaInfoBuilder.contentType = "video/mkv"
      mediaInfoBuilder.metadata = metadata
      
      let track = GCKMediaTrack(identifier: 1, contentIdentifier: "https://www.dropbox.com/s/huhxqyp51g1jdmn/audio1.ac3?dl=1", contentType: "audio/ac3", type: .audio, textSubtype: .unknown, name: "Audio \(1)", languageCode: "ru", customData: nil)
      let track2 = GCKMediaTrack(identifier: 2, contentIdentifier: "https://www.dropbox.com/s/c2hi8p44jt44pr1/audio2.ac3?dl=1", contentType: "audio/ac3", type: .audio, textSubtype: .unknown, name: "Audio \(2)", languageCode: "ru", customData: nil)
      let track3 = GCKMediaTrack(identifier: 3, contentIdentifier: "https://www.dropbox.com/s/ogsh07dzfm1mlkm/audio3.ac3?dl=1", contentType: "audio/ac3", type: .audio, textSubtype: .unknown, name: "Audio \(3)", languageCode: "en", customData: nil)
      let track4 = GCKMediaTrack(identifier: 4, contentIdentifier: "https://www.dropbox.com/s/esmh0mycqnpflv1/subtitles2.srt?dl=1", contentType: "text/vtt", type: .text, textSubtype: .captions, name: "Sub \(1)", languageCode: "en", customData: nil)
      let track5 = GCKMediaTrack(identifier: 5, contentIdentifier: "https://www.dropbox.com/s/wzmselbwulbzdis/subtitles3.srt?dl=1", contentType: "text/vtt", type: .text, textSubtype: .captions, name: "Sub \(2)", languageCode: "ru", customData: nil)
      mediaInfoBuilder.mediaTracks = [track, track2, track3, track4, track5]
      mediaInformation = mediaInfoBuilder.build()

      let mediaLoadRequestDataBuilder = GCKMediaLoadRequestDataBuilder()
      mediaLoadRequestDataBuilder.mediaInformation = mediaInformation

      // Send a load request to the remote media client.

      mediaLoadRequestDataBuilder.autoplay = true
      mediaLoadRequestDataBuilder.startTime = 0
      mediaLoadRequestDataBuilder.activeTrackIDs = [NSNumber(value: 1), NSNumber(value: 4)]
      
      if let request = sessionManager.currentSession?.remoteMediaClient?.loadMedia(with: mediaLoadRequestDataBuilder.build()) {
        request.delegate = self
      }
    }
  
  @IBAction func loadVideo(sender _: AnyObject) {
    print("Load Video")

    if sessionManager.currentSession == nil {
      print("Cast device not connected")
      return
    }

    playVideoRemotely()
  }

  func showLoadVideoButton(showButton: Bool) {
    castVideoButton.isHidden = !showButton
    // Instructions should always be the opposite visibility of the video button.
    castInstructionLabel.isHidden = !castVideoButton.isHidden
  }

  // MARK: GCKSessionManagerListener

  func sessionManager(_: GCKSessionManager,
                      didStart session: GCKSession) {
    print("sessionManager didStartSession: \(session)")

    // Add GCKRemoteMediaClientListener.
    session.remoteMediaClient?.add(self)

    showLoadVideoButton(showButton: true)
  }

  func sessionManager(_: GCKSessionManager,
                      didResumeSession session: GCKSession) {
    print("sessionManager didResumeSession: \(session)")

    // Add GCKRemoteMediaClientListener.
    session.remoteMediaClient?.add(self)

    showLoadVideoButton(showButton: true)
  }

  func sessionManager(_: GCKSessionManager,
                      didEnd session: GCKSession,
                      withError error: Error?) {
    print("sessionManager didEndSession: \(session)")

    // Remove GCKRemoteMediaClientListener.
    session.remoteMediaClient?.remove(self)

    if let error = error {
      showError(error)
    }

    showLoadVideoButton(showButton: false)
  }

  func sessionManager(_: GCKSessionManager,
                      didFailToStart session: GCKSession,
                      withError error: Error) {
    print("sessionManager didFailToStartSessionWithError: \(session) error: \(error)")

    // Remove GCKRemoteMediaClientListener.
    session.remoteMediaClient?.remove(self)

    showLoadVideoButton(showButton: false)
  }

  // MARK: GCKRemoteMediaClientListener

  func remoteMediaClient(_: GCKRemoteMediaClient,
                         didUpdate mediaStatus: GCKMediaStatus?) {
    if let mediaStatus = mediaStatus {
      mediaInformation = mediaStatus.mediaInformation
    }
  }

  // MARK: - GCKRequestDelegate

  func requestDidComplete(_ request: GCKRequest) {
    print("request \(Int(request.requestID)) completed")
  }

  func request(_ request: GCKRequest,
               didFailWithError error: GCKError) {
    print("request \(Int(request.requestID)) didFailWithError \(error)")
  }

  func request(_ request: GCKRequest,
               didAbortWith abortReason: GCKRequestAbortReason) {
    print("request \(Int(request.requestID)) didAbortWith reason \(abortReason)")
  }

  // MARK: Misc

  func showError(_ error: Error) {
    let alertController = UIAlertController(title: "Error",
                                            message: error.localizedDescription,
                                            preferredStyle: UIAlertController.Style.alert)
    let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
    alertController.addAction(action)

    present(alertController, animated: true, completion: nil)
  }
}
