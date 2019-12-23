import AVFoundation
import GoogleInteractiveMediaAds
import UIKit

class AdsViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    static let kTestAppContentUrl_MP4 = "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3?Expires=1577156252&Signature=eeZ42~~1AxWapeFNgUFljNGTZ~jdH1v9bCN1T9UEBXr6-3OVBjqw9Swvk~tN-B2RRMpebm1iQRxIU4IddHcKKmFZo9jiov6-0ANZOlyyVdBqA-o63Xf7PRrNjm-sJGMrln1OUE8UOZFGCtssPcqH0Cj4piYOmCHSvmMWM90p~as62Ojq7WdGmk-70LNr5uRT0K2Bcz-sWbQlmzevWfUb2Mc2I51AyS6yaeSLnnzIftO00bBXY~Wx2QMpYbq5e6Qj6clK2R-yt2ifpfj2kI0~ES4gilhA0GPVjsuzIkRgXBn7MgyYAB541beZ2cdXeR7sfrIhcC14vUPvErAPInESMw__&Key-Pair-Id=APKAJXI72ADZRFKVIR2Q"
    
    var videoView: UIView!
    var contentPlayer: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var adsLoader: IMAAdsLoader!
    var adsManager: IMAAdsManager!
    
    static let kAppAdTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480%7C400x300%7C730x400&iu=/7090806/Suamusica.com.br-ROA-Preroll&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&url=[referrer_url]&description_url=[description_url]&correlator=[timestamp]&cust_params=platform%3Dios%26Domain%3Dsuamusica%26age%3D$age%26gender%3D$gender";
    
    // platform%3Dios%26Domain%3Dsuamusica%26age%3D$age%26gender%3D$gender
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpContentPlayer()
        setUpAdsLoader()
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
        self.dismiss(animated: false, completion: nil)
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
            self.dismiss(animated: false, completion: nil)
        default:
            print(event.type)
        }
        
        //        if event.type == IMAAdEventType.LOADED {
        //            // When the SDK notifies us that ads have been loaded, play them.
        //            adsManager.start()
        //        }
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
}

