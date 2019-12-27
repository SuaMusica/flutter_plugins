import AVFoundation
import GoogleInteractiveMediaAds
import UIKit
import PureLayout

class AdsViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    static let kTestAppContentUrl_MP4 = "https://assets.suamusica.com.br/video/virgula.mp3"
    
    let channel: FlutterMethodChannel?
    var videoView: UIView!
    var contentPlayer: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var adsLoader: IMAAdsLoader!
    var adsManager: IMAAdsManager!
    
    //    static let kAppAdTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480%7C400x300%7C730x400&iu=/7090806/Suamusica.com.br-ROA-Preroll&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&url=[referrer_url]&description_url=[description_url]&correlator=[timestamp]&cust_params=platform%3Dios%26Domain%3Dsuamusica%26age%3D$age%26gender%3D$gender";
    
    static let kAppAdTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";
    
    init(channel: FlutterMethodChannel?) {
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience required init(coder aDecoder: NSCoder) {
        self.init(channel: nil)
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
        guard let contentURL = URL(string: AdsViewController.kTestAppContentUrl_MP4) else {
            print("ERROR: please use a valid URL for the content URL")
            return
        }
        contentPlayer = AVPlayer(url: contentURL)
        
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
        // TODO: Fix variables
        let request = IMAAdsRequest(
            adTagUrl: AdsViewController.getAdTag(age: "41", gender: "male"),
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
        // Something went wrong with the ads manager after ads were loaded. Log the error and play the
        // content.
        if (error != nil) {
            let message = error?.message ?? "unknown"
            print("AdsManager error: \(message)")
        }
        contentPlayer?.play()
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        // The SDK is going to play ads, so pause the content.
        contentPlayer?.pause()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        // The SDK is done playing ads (at least for now), so resume the content.
        contentPlayer?.play()
    }
    
    static func getAdTag(age: String, gender: String) -> String {
        // TODO
        var tag = kAppAdTagUrl.replacingOccurrences(of: "$age", with: age, options: .literal, range: nil)
        tag = tag.replacingOccurrences(of: "$gender", with: gender, options: .literal, range: nil)
        return tag
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

