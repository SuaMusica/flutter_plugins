import AVFoundation
import GoogleInteractiveMediaAds
import UIKit
import PureLayout
import MediaPlayer

class AdsViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate, AVPictureInPictureControllerDelegate {
    var channel: FlutterMethodChannel?
    
    // Video objects
    var contentPlayer: AVPlayer?
    var contentPlayerLayer: AVPlayerLayer?
    
    // IMA objects
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var adsLoader: IMAAdsLoader?
    var adsManager: IMAAdsManager?
    var companionSlot: IMACompanionAdSlot?
    
    // PiP objects.
    var pictureInPictureController: AVPictureInPictureController?
    var pictureInPictureProxy: IMAPictureInPictureProxy?
    
    var adUrl: String!
    var contentUrl: String!
    var screen: Screen!
    var args: [String: Any]!
    var active: Bool = true
    var playing: Bool = false
    var isRemoteControlOn = false
    var sentOnComplete = false
    
    @IBOutlet weak var totalProgress: UILabel!
    @IBOutlet weak var currentProgress: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var whyListenAdView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var companionView: UIView!
    @IBOutlet weak var pictureInPictureButton: UIButton!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil);

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil);
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpContentPlayer()
        setUpAdsLoader()
        setupAudioSession()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        requestAds()
    }
    
    @IBAction func playPauseHandler(_ sender: Any) {
        if (playing) {
            adsManager?.pause()
        } else {
            adsManager?.resume()
        }
    }
    
    @IBAction func understoodAdHandler(_ sender: Any) {UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.whyListenAdView.alpha = 0.0
        }) { [weak self] (isCompleted) in
        self?.whyListenAdView.isHidden = true
        }
    }
    
    @IBAction func whyListenAdHandler(_ sender: Any) {
        whyListenAdView.alpha = 0.0
        whyListenAdView.isHidden = false
            
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.whyListenAdView.alpha = 1.0
            }) { (isCompleted) in }
    }
    
    func setup(channel: FlutterMethodChannel?, adUrl: String?, contentUrl: String?, screen: Screen, args: [String: Any]?) {
        self.channel = channel
        self.adUrl = adUrl
        self.contentUrl = contentUrl
        self.screen = screen
        self.args = args
    }
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            } else {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            }
        } catch(let error) {
            print("AD: \(error.localizedDescription)")
        }
    }
    
    func setUpContentPlayer() {
        // Load AVPlayer with path to our content.
        guard let contentUrl = URL(string: self.contentUrl) else {
            print("AD: ERROR: please use a valid URL for the content URL")
            return
        }
        
        guard let videoViewUnwraped = self.videoView else {
            print("AD: ERROR: videoView NOT FOUND")
            return
        }
        self.videoView.showLoading()
        contentPlayer = AVPlayer(url: contentUrl)
        
        // Create a player layer for the player.
        contentPlayerLayer = AVPlayerLayer(player: contentPlayer)
        
        let commandCenter = MPRemoteCommandCenter.shared()
        self.isRemoteControlOn = commandCenter.previousTrackCommand.isEnabled
        commandCenter.previousTrackCommand.isEnabled = false;
        commandCenter.nextTrackCommand.isEnabled = false;

        // Size, position, and display the AVPlayer.
        contentPlayerLayer?.frame = videoViewUnwraped.layer.bounds
        videoViewUnwraped.layer.addSublayer(contentPlayerLayer!)
        
        // Set up our content playhead and contentComplete callback.
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer)
        
        // Set ourselves up for PiP.
        pictureInPictureProxy = IMAPictureInPictureProxy(avPictureInPictureControllerDelegate: self)
        pictureInPictureController = AVPictureInPictureController(playerLayer: contentPlayerLayer!)
        if pictureInPictureController != nil {
          pictureInPictureController!.delegate = pictureInPictureProxy
        }
        if !AVPictureInPictureController.isPictureInPictureSupported() && pictureInPictureButton != nil
        {
          pictureInPictureButton.isHidden = true
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AdsViewController.contentDidFinishPlaying(_:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: contentPlayhead!.player.currentItem);
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AdsViewController.applicationDidBecomeActive(notification:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil);

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AdsViewController.applicationDidEnterBackground(notification:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil);
    }
    
    // Initialize ad display container.
    func createAdDisplayContainer() -> IMAAdDisplayContainer {
      // Create our AdDisplayContainer. Initialize it with our videoView as the container. This
      // will result in ads being displayed over our content video.
      if companionView != nil {
        return IMAAdDisplayContainer(adContainer: videoView, companionSlots: [companionSlot!])
      } else {
        return IMAAdDisplayContainer(adContainer: videoView, companionSlots: nil)
      }
    }

    // Register companion slots.
    func setUpCompanions() {
      companionSlot = IMACompanionAdSlot(
        view: companionView,
        width: 300,
        height: 250)
    }

    @objc func applicationDidBecomeActive(notification: NSNotification) {
        let oldStatus = self.active
        self.active = true
        if (!oldStatus) {
            adsManager?.resume()
        }
    }

    @objc func applicationDidEnterBackground(notification: NSNotification) {
        self.active = false
    }
    
    @objc func contentDidFinishPlaying(_ notification: Notification) {
        print("AD: Got a contentDidFinishPlaying")
        // Make sure we don't call contentComplete as a result of an ad completing.
        if (notification.object as! AVPlayerItem) == contentPlayer?.currentItem {
            adsLoader?.contentComplete()
            self.onComplete()
        }
    }
    
    func setUpAdsLoader() {
        let settings = IMASettings()
        settings.enableBackgroundPlayback = true
        adsLoader = IMAAdsLoader(settings: settings)
        adsLoader?.delegate = self
        if (companionView != nil) {
            setUpCompanions()
        }
    }
    
    fileprivate func onComplete() {
        if (!self.sentOnComplete) {
            self.sentOnComplete = true
            let commandCenter = MPRemoteCommandCenter.shared()
            if (self.isRemoteControlOn) {
                commandCenter.previousTrackCommand.isEnabled = true;
                commandCenter.nextTrackCommand.isEnabled = true;
            }
            
            // we need to notify that the ad was played
            self.channel?.invokeMethod("onComplete", arguments: [String: String]())
        }
    }
    
    func requestAds() {
        if (self.active) {
            // Create an ad request with our ad tag, display container, and optional user context.
            let request = IMAAdsRequest(
                adTagUrl: getAdTagUrl(),
                adDisplayContainer: createAdDisplayContainer(),
                avPlayerVideoDisplay: IMAAVPlayerVideoDisplay(avPlayer: contentPlayer),
                pictureInPictureProxy: pictureInPictureProxy,
                userContext: nil)
            
            request?.vastLoadTimeout = 30000
            
            adsLoader?.requestAds(with: request)
        } else {
            onComplete()
        }
    }
    
    func getsafeAreaBottomMargin() -> CGFloat {
        if #available(iOS 11.0, *) {
            let currentwindow = UIApplication.shared.windows.first
            return (currentwindow?.safeAreaLayoutGuide.owningView?.frame.size.height)! - (currentwindow?.safeAreaLayoutGuide.layoutFrame.size.height)! - (currentwindow?.safeAreaLayoutGuide.layoutFrame.origin.y)!
        }
        else {
            return 0
        }
    }
    
    // MARK: - IMAAdsLoaderDelegate
    
    func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        
        // Create ads rendering settings and tell the SDK to use the in-app browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.loadVideoTimeout = 300
        
        // Commenting this line to open the click in safari Until Apple fixes the Bug!
        adsRenderingSettings.webOpenerPresentingController = self
        
        // Initialize the ads manager.
        adsManager?.initialize(with: adsRenderingSettings)
    }
    
    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        if (adErrorData != nil && adErrorData.adError != nil) {
            let message = adErrorData?.adError?.message ?? "unknown"
            print("AD: Error loading ads: \(message)")
        }
        contentPlayer?.play()

        onComplete()
        
        let code = AdsViewController.toErrorCode(error: adErrorData?.adError)
        let message = adErrorData?.adError?.message ?? "unknown"

        let args = [
            "type" : "ERROR",
            "error.code": code,
            "error.message": message,
        ]

        self.channel?.invokeMethod("onAdEvent", arguments: args)
        self.dismiss(animated: false, completion: nil)
    }
    
    // MARK: - IMAAdsManagerDelegate
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        switch event.type {
        case IMAAdEventType.ALL_ADS_COMPLETED:
            print("AD: Got a ALL_ADS_COMPLETED event")
        case IMAAdEventType.CLICKED:
            print("AD: Got a CLICKED event")
        case IMAAdEventType.COMPLETE:
            print("AD: Got a COMPLETE event")
            onComplete()
            adsManager.destroy()
            
            self.adsManager = nil
            self.adsLoader = nil
            self.dismiss(animated: false, completion: nil)
        case IMAAdEventType.CUEPOINTS_CHANGED:
            print("AD: Got a CUEPOINTS_CHANGED event")
        case IMAAdEventType.FIRST_QUARTILE:
            print("AD: Got a FIRST_QUARTILE event")
        case IMAAdEventType.LOG:
            print("AD: Got a LOG event")
        case IMAAdEventType.AD_BREAK_READY:
            print("AD: Got a AD_BREAK_READY event")
        case IMAAdEventType.MIDPOINT:
            print("AD: Got a MIDPOINT event")
        case IMAAdEventType.PAUSE:
            print("AD: Got a PAUSE event")
            print("MYMP: PAUSED CLICKED")
            self.setPaused()
        case IMAAdEventType.RESUME:
            print("AD: Got a RESUME event")
            self.setPlaying()
        case IMAAdEventType.SKIPPED:
            print("AD: Got a SKIPPED event")
            onComplete()
            adsManager.destroy()
            
            self.adsManager = nil
            self.adsLoader = nil
            self.dismiss(animated: false, completion: nil)
        case IMAAdEventType.STARTED:
            print("AD: Got a STARTED event")
            self.setPlaying()
        case IMAAdEventType.TAPPED:
            print("AD: Got a TAPPED event")
        case IMAAdEventType.THIRD_QUARTILE:
            print("AD: Got a THIRD_QUARTILE event")
        case IMAAdEventType.LOADED:
            print("AD: Got a LOADED event")
            let contentType = event?.ad?.contentType ?? "video"
            if (contentType.hasPrefix("audio")) {
                videoView.isHidden = true
                companionView.isHidden = false
            } else {
                videoView.isHidden = false
                companionView.isHidden = true
            }
            adsManager.start()
        case IMAAdEventType.AD_BREAK_STARTED:
            print("AD: Got a AD_BREAK_STARTED event")
        case IMAAdEventType.AD_BREAK_ENDED:
            print("AD: Got a AD_BREAK_ENDED event")
        case IMAAdEventType.AD_PERIOD_STARTED:
            print("AD: Got a AD_PERIOD_STARTED event")
        case IMAAdEventType.AD_PERIOD_ENDED:
            print("AD: Got a AD_PERIOD_ENDED event")
        default:
            print("AD: Got an unknown event")
        }
        
        let type = AdsViewController.toEventType(event: event)
        
        let args = [
            "type" : type,
            "ad.id" : event.ad.adId,
            "ad.title" : event.ad.adTitle,
            "ad.description" : event.ad.adDescription,
            "ad.system" : event.ad.adSystem,
            "ad.advertiserName" : event.ad.advertiserName,
            "ad.contentType" : event.ad.contentType,
            "ad.creativeAdID" : event.ad.creativeAdID,
            "ad.creativeID" : event.ad.creativeID,
            "ad.dealID" : event.ad.dealID,
        ]
        
        self.channel?.invokeMethod("onAdEvent", arguments: args)
    }
    
    func setPlaying() {
        self.playing = true
        self.playPauseButton.setImage(UIImage(named: "bt_pause.png", in: Bundle(identifier: "org.cocoapods.smads"), compatibleWith: nil), for: UIControl.State.normal)
    }
    
    func setPaused() {
        self.playing = false
        self.playPauseButton.setImage(UIImage(named: "bt_play.png", in: Bundle(identifier: "org.cocoapods.smads"), compatibleWith: nil), for: UIControl.State.normal)
    }
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        print("AD: didReceive error")
        let code = AdsViewController.toErrorCode(error: error)
        let message = error?.message ?? "unknown"

        // Something went wrong with the ads manager after ads were loaded.
        // Log the error and play the content.
        if (error != nil) {
            print("AD: AdsManager code: \(code) error: \(message)")
        }
        contentPlayer?.play()

        onComplete()

        let args = [
            "type" : "ERROR",
            "error.code": code,
            "error.message": message,
        ]

        self.channel?.invokeMethod("onAdEvent", arguments: args)
        self.dismiss(animated: false, completion: nil)
    }
    
    func adsManager(_ adsManager: IMAAdsManager!, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        let progress = Float(mediaTime/totalTime)
        currentProgress?.text = formatTimeInterval(mediaTime)
        totalProgress?.text = formatTimeInterval(totalTime)
        progressSlider?.value = progress
        
        if (progress == 1.0) {
            onComplete()
        }
    }
    
    func formatTimeInterval(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional // Use the appropriate positioning for the current locale
        formatter.allowedUnits = [.minute, .second ] // Units to display in the formatted string
        formatter.zeroFormattingBehavior = [ .pad ] // Pad with zeroes where appropriate for the locale

        return formatter.string(from: time)!
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        // The SDK is going to play ads, so pause the content.
        print("AD: adsManagerDidRequestContentPause")
        contentPlayer?.pause()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        // The SDK is done playing ads (at least for now), so resume the content.
        print("AD: adsManagerDidRequestContentResume")
        contentPlayer?.play()
    }
    
    func getAdTagUrl() -> String {
        var url: String = self.adUrl

        if (url.hasSuffix("cust_params=")) {
            url += "platform%3Dios%26Domain%3Dsuamusica"
            
            for (key, value) in self.args {
                if (key.starts(with: "__")) {
                    continue
                }
                url += "%26\(key)%3D\(value)"
            }
        }

        print("AD: Using AD URL: \(url)")


        return url
    }
    
    
    static func toErrorCode(error: IMAAdError!) -> String {
        var code = "unknown"
        switch error.code {
        case IMAErrorCode.VAST_MALFORMED_RESPONSE:
            code = "VAST_MALFORMED_RESPONSE"
        case IMAErrorCode.VAST_TRAFFICKING_ERROR:
            code = "VAST_TRAFFICKING_ERROR"
        case IMAErrorCode.VAST_LOAD_TIMEOUT:
            code = "VAST_LOAD_TIMEOUT"
        case IMAErrorCode.VAST_INVALID_URL:
            code = "VAST_INVALID_URL"
        case IMAErrorCode.VIDEO_PLAY_ERROR:
            code = "VIDEO_PLAY_ERROR"
        case IMAErrorCode.VAST_MEDIA_LOAD_TIMEOUT:
            code = "VAST_MEDIA_LOAD_TIMEOUT"
        case IMAErrorCode.VAST_LINEAR_ASSET_MISMATCH:
            code = "VAST_LINEAR_ASSET_MISMATCH"
        case IMAErrorCode.COMPANION_AD_LOADING_FAILED:
            code = "COMPANION_AD_LOADING_FAILED"
        case IMAErrorCode.UNKNOWN_ERROR:
            code = "UNKNOWN_ERROR"
        case IMAErrorCode.PLAYLIST_MALFORMED_RESPONSE:
            code = "PLAYLIST_MALFORMED_RESPONSE"
        case IMAErrorCode.FAILED_TO_REQUEST_ADS:
            code = "FAILED_TO_REQUEST_ADS"
        case IMAErrorCode.REQUIRED_LISTENERS_NOT_ADDED:
            code = "REQUIRED_LISTENERS_NOT_ADDED"
        case IMAErrorCode.VAST_ASSET_NOT_FOUND:
            code = "VAST_ASSET_NOT_FOUND"
        case IMAErrorCode.ADSLOT_NOT_VISIBLE:
            code = "ADSLOT_NOT_VISIBLE"
        case IMAErrorCode.VAST_EMPTY_RESPONSE:
            code = "VAST_EMPTY_RESPONSE"
        case IMAErrorCode.FAILED_LOADING_AD:
            code = "FAILED_LOADING_AD"
        case IMAErrorCode.STREAM_INITIALIZATION_FAILED:
            code = "STREAM_INITIALIZATION_FAILED"
        case IMAErrorCode.INVALID_ARGUMENTS:
            code = "INVALID_ARGUMENTS"
        case IMAErrorCode.API_ERROR:
            code = "API_ERROR"
        case IMAErrorCode.VIDEO_ELEMENT_USED:
            code = "VIDEO_ELEMENT_USED"
        case IMAErrorCode.VIDEO_ELEMENT_REQUIRED:
            code = "VIDEO_ELEMENT_REQUIRED"
        case IMAErrorCode.CONTENT_PLAYHEAD_MISSING:
            code = "CONTENT_PLAYHEAD_MISSING"
        default:
            code = "unknown"
        }
        
        return code
    }
    
    static func toEventType(event: IMAAdEvent!) -> String {
        var type = "unknown"
        switch event.type {
        case IMAAdEventType.ALL_ADS_COMPLETED:
            type = "ALL_ADS_COMPLETED"
        case IMAAdEventType.CLICKED:
            type = "CLICKED"
        case IMAAdEventType.COMPLETE:
            type = "COMPLETE"
        case IMAAdEventType.CUEPOINTS_CHANGED:
            type = "CUEPOINTS_CHANGED"
        case IMAAdEventType.FIRST_QUARTILE:
            type = "FIRST_QUARTILE"
        case IMAAdEventType.LOG:
            type = "LOG"
        case IMAAdEventType.AD_BREAK_READY:
            type = "AD_BREAK_READY"
        case IMAAdEventType.MIDPOINT:
            type = "MIDPOINT"
        case IMAAdEventType.PAUSE:
            type = "PAUSE"
        case IMAAdEventType.RESUME:
            type = "RESUME"
        case IMAAdEventType.SKIPPED:
            type = "SKIPPED"
        case IMAAdEventType.STARTED:
            type = "STARTED"
        case IMAAdEventType.TAPPED:
            type = "TAPPED"
        case IMAAdEventType.THIRD_QUARTILE:
            type = "THIRD_QUARTILE"
        case IMAAdEventType.LOADED:
            type = "LOADED"
        case IMAAdEventType.AD_BREAK_STARTED:
            type = "AD_BREAK_STARTED"
        case IMAAdEventType.AD_BREAK_ENDED:
            type = "AD_BREAK_ENDED"
        case IMAAdEventType.AD_PERIOD_STARTED:
            type = "AD_PERIOD_STARTED"
        case IMAAdEventType.AD_PERIOD_ENDED:
            type = "AD_PERIOD_ENDED"
        default:
            type = "unknown"
        }
        
        return type
    }
    
    class func instantiateFromNib() -> AdsViewController {
        return AdsViewController(nibName: String(describing:self), bundle: Bundle(identifier: "org.cocoapods.smads"))
    }
}

@IBDesignable extension UIButton {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}
