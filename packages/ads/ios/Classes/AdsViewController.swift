import AVFoundation
import GoogleInteractiveMediaAds
import UIKit
import PureLayout

class AdsViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    let channel: FlutterMethodChannel?
    var videoView: UIView!
    var contentPlayer: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var adsLoader: IMAAdsLoader!
    var adsManager: IMAAdsManager!
    let adUrl: String
    let contentUrl: String
    let args: [String: Any]
    
    init(channel: FlutterMethodChannel?, adUrl: String?, contentUrl: String?, args: [String: Any]?) {
        self.channel = channel
        self.adUrl = adUrl!
        self.contentUrl = contentUrl!
        self.args = args!
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience required init(coder aDecoder: NSCoder) {
        self.init(channel: nil, adUrl: nil, contentUrl: nil, args: nil)
    }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        
        videoView = UIView()
        videoView.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        videoView.backgroundColor = .white
        view.addSubview(videoView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpContentPlayer()
        setUpAdsLoader()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playerLayer?.frame = self.videoView.layer.bounds
        
        requestAds()
    }
    
    func setUpContentPlayer() {
        // Load AVPlayer with path to our content.
        guard let contentUrl = URL(string: self.contentUrl) else {
            print("ERROR: please use a valid URL for the content URL")
            return
        }
        contentPlayer = AVPlayer(url: contentUrl)
        
        // Create a player layer for the player.
        playerLayer = AVPlayerLayer(player: contentPlayer)
        
        // Size, position, and display the AVPlayer.
        playerLayer?.frame = videoView.layer.bounds
        videoView.layer.addSublayer(playerLayer!)
        
        // Set up our content playhead and contentComplete callback.
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AdsViewController.contentDidFinishPlaying(_:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: contentPlayer?.currentItem);
    }
    
    @objc func contentDidFinishPlaying(_ notification: Notification) {
        // Make sure we don't call contentComplete as a result of an ad completing.
        if (notification.object as! AVPlayerItem) == contentPlayer?.currentItem {
            adsLoader.contentComplete()
        }
    }
    
    func setUpAdsLoader() {
        adsLoader = IMAAdsLoader(settings: nil)
        adsLoader.delegate = self
    }
    
    func requestAds() {
        // Create ad display container for ad rendering.
        let adDisplayContainer = IMAAdDisplayContainer(adContainer: videoView, companionSlots: nil)
        // Create an ad request with our ad tag, display container, and optional user context.
        let request = IMAAdsRequest(
            adTagUrl: getAdTagUrl(),
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: contentPlayhead,
            userContext: nil)
        
        adsLoader.requestAds(with: request)
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
        adsManager.delegate = self
        
        // Create ads rendering settings and tell the SDK to use the in-app browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.webOpenerPresentingController = self
        
        // Initialize the ads manager.
        adsManager.initialize(with: adsRenderingSettings)
    }
    
    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        if (adErrorData != nil && adErrorData.adError != nil) {
            let message = adErrorData?.adError?.message ?? "unknown"
            print("Error loading ads: \(message)")
        }
        contentPlayer?.play()

        self.channel?.invokeMethod("onComplete", arguments: [String: String]())
        
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
        case IMAAdEventType.LOADED:
            adsManager.start()
        case IMAAdEventType.COMPLETE:
            self.channel?.invokeMethod("onComplete", arguments: [String: String]())
            adsManager.destroy()
            self.dismiss(animated: false, completion: nil)
        default:
            print(event.type)
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
    
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        let code = AdsViewController.toErrorCode(error: error)
        let message = error?.message ?? "unknown"

        // Something went wrong with the ads manager after ads were loaded.
        // Log the error and play the content.
        if (error != nil) {
            print("AdsManager error: \(message)")
        }
        contentPlayer?.play()

        self.channel?.invokeMethod("onComplete", arguments: [String: String]())

        let args = [
            "type" : "ERROR",
            "error.code": code,
            "error.message": message,
        ]

        self.channel?.invokeMethod("onAdEvent", arguments: args)
        self.dismiss(animated: false, completion: nil)
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        // The SDK is going to play ads, so pause the content.
        contentPlayer?.pause()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        // The SDK is done playing ads (at least for now), so resume the content.
        contentPlayer?.play()
    }

    func getAdTagUrl() -> String {
        var url = self.adUrl

        url += "platform%3Dios%26Domain%3Dsuamusica"

        for (key, value) in self.args {
            if (key.starts(with: "__")) {
                continue
            }
            url += "%26\(key)%3D\(value)"
        }

        print("Using AD URL: \(url)")

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
        case IMAErrorCode.VAST_TOO_MANY_REDIRECTS:
            code = "VAST_TOO_MANY_REDIRECTS"
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
        case IMAErrorCode.IOS_RUNTIME_TOO_OLD:
            code = "IOS_RUNTIME_TOO_OLD"
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

