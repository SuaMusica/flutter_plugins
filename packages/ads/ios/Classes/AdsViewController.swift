import AVFoundation
import GoogleInteractiveMediaAds

class AdsViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate, AVPictureInPictureControllerDelegate {
    var callback: SmadsCallback?
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
    
    var isVideo: Bool = true
    var adUrl: String!
    var contentUrl: String = "https://assets.suamusica.com.br/video/virgula.mp3"
    var args: [String: Any]!
    var playing: Bool = false
    var isRemoteControlOn = false
    var sentOnComplete = false
    var hasStarted: Bool = false
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var companionView: UIView!
    
    init(callback: SmadsCallback?) {
        print("AD: INIT AdsViewController")
        self.callback = callback
        super.init(nibName: String(describing:"AdsViewController"), bundle: Bundle(identifier: "org.cocoapods.smads"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    deinit {
        print("AD: deinit")
        
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
        print("AD: viewDidLoad")
        super.viewDidLoad()
        
        setUpContentPlayer()
        setUpAdsLoader()
        setupAudioSession()
        
        self.callback!.onAddEvent(args: ["type" : "IOS_READY"])
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("AD: viewDidAppear")
        requestAds()
    }
    
    func dispose(){
        print("AD: dispose")
        adsManager?.destroy()
    }
    
    func pause(){
        print("AD: pause")
        adsManager?.pause()
    }
    
    func play(){
        print("AD: play")
        if (hasStarted) {
            adsManager?.resume()
        } else {
            hasStarted = true
            adsManager?.start()
        }
    }
    
    func skipAd(){
        print("AD: skipAd")
        adsManager?.skip()
    }
    
    func load(adUrl: String?, args: [String: Any]?) {
        print("AD: Load")
        self.adUrl = adUrl
        self.args = args
        loadViewIfNeeded()
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
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer!)
        
        // Set ourselves up for PiP.
        pictureInPictureProxy = IMAPictureInPictureProxy(avPictureInPictureControllerDelegate: self)
        pictureInPictureController = AVPictureInPictureController(playerLayer: contentPlayerLayer!)
        if pictureInPictureController != nil {
            pictureInPictureController!.delegate = pictureInPictureProxy
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
        return IMAAdDisplayContainer(adContainer: videoView,viewController: self, companionSlots: [companionSlot!])
    }
    
    // Register companion slots.
    func setUpCompanions() {
        companionSlot = IMACompanionAdSlot(
            view: companionView,
            width: Int(companionView.frame.size.width),
            height: Int(companionView.frame.size.height))
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        print("AD: applicationDidBecomeActive")
        //        let oldStatus = self.active
        //        self.active = true
        //        if (!oldStatus) {
        //            adsManager?.resume()
        //        }
    }
    
    @objc func applicationDidEnterBackground(notification: NSNotification) {
        print("AD: applicationDidEnterBackground")
        if (isVideo) {
            adsManager?.pause()
        }
        //        self.active = false
        
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
        adsLoader!.delegate = self
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
            self.callback?.onComplete()
        }
    }
    
    func requestAds() {
        // Create an ad request with our ad tag, display container, and optional user context.
        guard let contentPlayer = self.contentPlayer else { return }
        guard let pictureInPictureProxy = self.pictureInPictureProxy else { return }
        guard let adsLoader = self.adsLoader else { return }
        
        let request = IMAAdsRequest(
            adTagUrl: getAdTagUrl(),
            adDisplayContainer: createAdDisplayContainer(),
            avPlayerVideoDisplay: IMAAVPlayerVideoDisplay(avPlayer: contentPlayer),
            pictureInPictureProxy: pictureInPictureProxy,
            userContext: nil)
        
        request.vastLoadTimeout = 30000
        
        adsLoader.requestAds(with: request)
        
    }
    
    // MARK: - IMAAdsLoaderDelegate
    
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
        print("AD: adsLoader loadedData")
        
        self.adsManager = adsLoadedData.adsManager
        guard let adsManager = self.adsManager else { return }
        
        adsManager.delegate = self
        
        // Create ads rendering settings and tell the SDK to use the in-app browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.loadVideoTimeout = 300
//        adsRenderingSettings.linkOpenerPresentingController = self
//        print("AD: adsLoader loadedData 2")

        // Initialize the ads manager.
        adsManager.initialize(with: adsRenderingSettings)
    }
    
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        
        let message = adErrorData.adError.message ?? "unknown"
        print("AD: Error loading ads: \(message)")
        let code = AdsViewController.toErrorCode(error: adErrorData.adError)
        
        let args = [
            "type" : "ERROR",
            "error.code": code,
            "error.message": message,
        ]
        self.callback?.onError(args:args)
        
    }
    
    // MARK: - IMAAdsManagerDelegate
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
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
        case IMAAdEventType.RESUME:
            print("AD: Got a RESUME event")
        case IMAAdEventType.SKIPPED:
            print("AD: Got a SKIPPED event")
            onComplete()
            adsManager.destroy()
            
            self.adsManager = nil
            self.adsLoader = nil
            self.dismiss(animated: false, completion: nil)
        case IMAAdEventType.STARTED:
            print("AD: Got a STARTED event")
        case IMAAdEventType.TAPPED:
            print("AD: Got a TAPPED event")
        case IMAAdEventType.THIRD_QUARTILE:
            print("AD: Got a THIRD_QUARTILE event")
        case IMAAdEventType.LOADED:
            print("AD: Got a LOADED event")
            let contentType = event.ad?.contentType ?? "video"
            if (contentType.hasPrefix("audio")) {
                print("AD: isAudio")
                isVideo = false
                videoView.isHidden = true
                companionView.isHidden = false
            } else {
                print("AD: isVideo")
                videoView.frame.size.width = UIScreen.main.bounds.size.width
                isVideo = true
                videoView.isHidden = false
                companionView.isHidden = true
            }
            hasStarted = false;
            //For iOS we should start as soon as it is loaded as we do not preload it.
            play()
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
        if(event.ad != nil){
            let args = [
                "type" : type,
                "ad.id" : event.ad!.adId,
                "ad.title" : event.ad!.adTitle,
                "ad.description" : event.ad!.adDescription,
                "ad.system" : event.ad!.adSystem,
                "ad.advertiserName" : event.ad!.advertiserName,
                "ad.contentType" : event.ad!.contentType,
                "ad.creativeAdID" : event.ad!.creativeAdID,
                "ad.creativeID" : event.ad!.creativeID,
                "ad.dealID" : event.ad!.dealID,
            ]
            self.callback?.onAddEvent(args: args)
            
        }
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        print("AD: didReceive error")
        let code = AdsViewController.toErrorCode(error: error)
        let message = error.message
        
        // Something went wrong with the ads manager after ads were loaded.
        // Log the error and play the content.
        
        print("AD: AdsManager code: \(code) error: \(String(describing: message))")
        
        let args = [
            "type" : "ERROR",
            "error.code": code,
            "error.message": message,
        ]
        
        self.callback?.onError(args:args)
        
    }
    
    func adsManager(_ adsManager: IMAAdsManager, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        self.callback?.onAddEvent(args: [
            "type" : "AD_PROGRESS",
            "duration": String(describing: totalTime),
            "position": String(describing: mediaTime),
        ])
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // The SDK is going to play ads, so pause the content.
        print("AD: adsManagerDidRequestContentPause")
        contentPlayer?.pause()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
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
    
}
