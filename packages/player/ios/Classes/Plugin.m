#import "Plugin.h"

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

static NSString *const CHANNEL_NAME = @"smplayer";
static NSString *redirectScheme = @"rdtp";
static NSString *customPlaylistScheme = @"cplp";
static NSString *customKeyScheme = @"ckey";
static NSString *httpsScheme = @"https";
static NSString *m3u8Ext = @".m3u8";
static NSString *mp3Ext = @".mp3";
static NSString *extInfo = @"#EXTINF:";
static int redirectErrorCode = 302;
static int badRequestErrorCode = 400;

static int const STATE_IDLE = 0;
static int const STATE_BUFFERING = 1;
static int const STATE_PLAYING = 2;
static int const STATE_PAUSED = 3;
static int const STATE_STOPPED = 4;
static int const STATE_COMPLETED = 5;
static int const STATE_ERROR = 6;


static int const PLAYER_ERROR_FAILED = 0;
static int const PLAYER_ERROR_UNKNOWN = 1;
static int const PLAYER_ERROR_FAILED_TO_PLAY = 2;
static int const PLAYER_ERROR_FAILED_TO_PLAY_ERROR = 3;

static NSMutableDictionary * players;
static NSMutableDictionary * playersCurrentItem;

@interface Plugin()
-(void) pause: (NSString *) playerId;
-(void) stop: (NSString *) playerId;
-(void) seek: (NSString *) playerId time: (CMTime) time;
-(void) onSoundComplete: (NSString *) playerId;
-(void) updateDuration: (NSString *) playerId;
-(void) onTimeInterval: (NSString *) playerId time: (CMTime) time;
@end

@implementation Plugin {
  FlutterResult _result;
}

typedef void (^VoidCallback)(NSString * playerId);

NSMutableSet *timeobservers;
FlutterMethodChannel *_channel_player = nil;
Plugin* instance = nil;
NSString* _playerId = nil;
BOOL alreadyInAudioSession = false;
BOOL isLoadingComplete = false;
AVAssetResourceLoadingRequest* currentResourceLoadingRequest = nil;
AVAssetResourceLoader* currentResourceLoader = nil;
dispatch_queue_t serialQueue = nil;

NSString* latestUrl = nil;
bool latestIsLocal = NO;
NSString* latestCookie = nil;
NSString* latestPlayerId = nil;
VoidCallback latestOnReady = nil;
AVPlayerItem* latestPlayerItemObserved = nil;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  @synchronized(self) {
    if (instance == nil) {
      instance = [[Plugin alloc] init];
      FlutterMethodChannel* channel = [FlutterMethodChannel
                                        methodChannelWithName:CHANNEL_NAME
                                        binaryMessenger:[registrar messenger]];
      [registrar addMethodCallDelegate:instance channel:channel];
      _channel_player = channel;
    }
  }
}

- (id)init {
  self = [super init];
  if (self) {
      serialQueue = dispatch_queue_create("com.suamusica.player.queue", DISPATCH_QUEUE_SERIAL);
      players = [[NSMutableDictionary alloc] init];
      playersCurrentItem = [[NSMutableDictionary alloc] init];
    
      [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
      MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

      [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
          if (_playerId != nil) {
              [self resume:_playerId];
              int state = STATE_PLAYING;
              [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": _playerId, @"state": @(state)}];
          }
          return MPRemoteCommandHandlerStatusSuccess;
      }];

      [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
          if (_playerId != nil) {
              [self pause:_playerId];
              int state = STATE_PAUSED;
              [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": _playerId, @"state": @(state)}];
          }
          return MPRemoteCommandHandlerStatusSuccess;
      }];

      [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
          if (_playerId != nil) {
              [_channel_player invokeMethod:@"commandCenter.onNext" arguments:@{@"playerId": _playerId}];
          }
          return MPRemoteCommandHandlerStatusSuccess;
      }];

      [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
          if (_playerId != nil) {
              [_channel_player invokeMethod:@"commandCenter.onPrevious" arguments:@{@"playerId": _playerId}];
          }
          return MPRemoteCommandHandlerStatusSuccess;
      }];
  }
  return self;
}

-(void)setCurrentResourceLoadingRequest: (AVAssetResourceLoadingRequest*) resourceLoadingRequest {
  NSLog(@"===> set.resourceLoading: %@", resourceLoadingRequest);
  if (currentResourceLoadingRequest != nil) {
    if (!currentResourceLoadingRequest.cancelled && !currentResourceLoadingRequest.finished) {
      [currentResourceLoadingRequest finishLoading];
    }
  }
  currentResourceLoadingRequest = resourceLoadingRequest;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString * playerId = call.arguments[@"playerId"];
  NSLog(@"iOS => call %@, playerId %@", call.method, playerId);

  typedef void (^CaseBlock)(void);

  // Squint and this looks like a proper switch!
  NSDictionary *methods = @{
                @"play":
                  ^{
//                    NSLog(@"play!");
                    NSString *name = call.arguments[@"name"];
                    NSString *author = call.arguments[@"author"];
                    NSString *url = call.arguments[@"url"];
                    NSString *coverUrl = call.arguments[@"coverUrl"];
                    NSString *cookie = call.arguments[@"cookie"];
                    if (name == nil)
                        result(0);
                    if (author == nil)
                        result(0);
                    if (url == nil)
                        result(0);
                    if (cookie == nil)
                        result(0);
                    if (call.arguments[@"isLocal"] == nil)
                        result(0);
                    if (call.arguments[@"volume"] == nil)
                        result(0);
                    if (call.arguments[@"position"] == nil)
                        result(0);
                    if (call.arguments[@"respectSilence"] == nil)
                        result(0);
                    int isLocal = [call.arguments[@"isLocal"]intValue] ;
                    float volume = (float)[call.arguments[@"volume"] doubleValue] ;
                    int milliseconds = call.arguments[@"position"] == [NSNull null] ? 0.0 : [call.arguments[@"position"] intValue] ;
                    bool respectSilence = [call.arguments[@"respectSilence"]boolValue] ;
                    CMTime time = CMTimeMakeWithSeconds(milliseconds / 1000,NSEC_PER_SEC);
//                    NSLog(@"cookie: %@", cookie);
//                    NSLog(@"isLocal: %d %@", isLocal, call.arguments[@"isLocal"] );
//                    NSLog(@"volume: %f %@", volume, call.arguments[@"volume"] );
//                    NSLog(@"position: %d %@", milliseconds, call.arguments[@"positions"] );
                    [self play:playerId name:name author:author url:url coverUrl:coverUrl cookie:cookie isLocal:isLocal volume:volume time:time isNotification:respectSilence];
                  },
                @"pause":
                  ^{
//                    NSLog(@"pause");
                    [self pause:playerId];
                  },
                @"resume":
                  ^{
//                    NSLog(@"resume");
                    [self resume:playerId];
                  },
                @"stop":
                  ^{
//                    NSLog(@"stop");
                    [self stop:playerId];
                  },
                @"release":
                    ^{
//                      NSLog(@"release");
                      [self stop:playerId];
                    },
                @"seek":
                  ^{
//                    NSLog(@"seek");
                    if (!call.arguments[@"position"]) {
                      result(0);
                    } else {
                      int milliseconds = [call.arguments[@"position"] intValue];
                      NSLog(@"Seeking to: %d milliseconds", milliseconds);
                      [self seek:playerId time:CMTimeMakeWithSeconds(milliseconds / 1000,NSEC_PER_SEC)];
                    }
                  },
                @"setUrl":
                  ^{
//                    NSLog(@"setUrl");
                    NSString *url = call.arguments[@"url"];
                    NSString *cookie = call.arguments[@"cookie"];
                    int isLocal = [call.arguments[@"isLocal"]intValue];
                    [ self setUrl:url
                          isLocal:isLocal
                          cookie:cookie
                          playerId:playerId
                          onReady:^(NSString * playerId) {
                            int state = STATE_PLAYING;
                            NSMutableDictionary * playerInfo = players[playerId];
                            [ playerInfo setObject:@true forKey:@"isPlaying" ];
                            [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": playerId, @"state": @(state)}];
                            result(@(1));
                          }
                    ];
                  },
                @"getDuration":
                    ^{
                        
                        int duration = [self getDuration:playerId];
//                        NSLog(@"getDuration: %i ", duration);
                        result(@(duration));
                    },
                @"getCurrentPosition":
                    ^{
                        int currentPosition = [self getCurrentPosition:playerId];
//                        NSLog(@"getCurrentPosition: %i ", currentPosition);
                        result(@(currentPosition));
                    },
                @"setVolume":
                  ^{
//                    NSLog(@"setVolume");
                    float volume = (float)[call.arguments[@"volume"] doubleValue];
                    [self setVolume:volume playerId:playerId];
                  },
                @"setReleaseMode":
                  ^{
//                    NSLog(@"setReleaseMode");
                    NSString *releaseMode = call.arguments[@"releaseMode"];
                    bool looping = [releaseMode hasSuffix:@"LOOP"];
                    [self setLooping:looping playerId:playerId];
                  }
                };

  [ self initPlayerInfo:playerId ];
  CaseBlock c = methods[call.method];
  if (c) c(); else {
    NSLog(@"not implemented");
    result(FlutterMethodNotImplemented);
  }
  if(![call.method isEqualToString:@"setUrl"]) {
    result(@(1));
  }
}

-(void) initPlayerInfo: (NSString *) playerId {
  NSMutableDictionary * playerInfo = players[playerId];
  if (!playerInfo) {
    players[playerId] = [@{@"isPlaying": @false, @"volume": @(1.0), @"looping": @(false)} mutableCopy];
    _playerId = playerId;
  }
}

-(void) setCurrentItem: (NSString *) playerId
                  name:(NSString *) name
                author:(NSString *) author
                   url:(NSString *) url
              coverUrl:(NSString *) coverUrl
                  {
  NSLog(@"playerId=%@ name=%@ author=%@ url=%@ coverUrl=%@", playerId, name, author, url, coverUrl);
  playersCurrentItem[playerId] = @{
    @"name": name,
    @"author": author,
    @"url": url,
    @"coverUrl": coverUrl};
}

-(NSString*) replaceScheme: (NSString*) oldScheme
                 newScheme: (NSString*) newScheme
                   fromUrl: (NSString*) url {
  NSURLComponents *components = [NSURLComponents componentsWithString: url];
  if ([components.scheme rangeOfString: oldScheme].location != NSNotFound) {
    components.scheme = newScheme;
    return components.URL.absoluteString;
  }
  
  return url;
}

-(void) initAVPlayer:(NSString *)playerId playerItem:(AVPlayerItem *)playerItem url:(NSString *)url onReady:(VoidCallback) onReady {
  NSMutableDictionary * playerInfo = players[_playerId];
  AVPlayer *player = [[ AVPlayer alloc ] initWithPlayerItem: playerItem ];
  NSMutableSet *observers = [[NSMutableSet alloc] init];
  
  [ playerInfo setObject:player forKey:@"player" ];
  [ playerInfo setObject:url forKey:@"url" ];
  [ playerInfo setObject:observers forKey:@"observers"];
  
  CMTime interval = CMTimeMakeWithSeconds(0.2, NSEC_PER_SEC);
  id timeObserver = [player  addPeriodicTimeObserverForInterval: interval queue: nil usingBlock:^(CMTime time){
    [self onTimeInterval:playerId time:time];
  }];
  [timeobservers addObject:@{@"player":player, @"observer":timeObserver}];
  
  id avrouteobserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVAudioSessionRouteChangeNotification
      object: nil
      queue: NSOperationQueue.mainQueue
  usingBlock:^(NSNotification* note){
    NSDictionary *dict = note.userInfo;
    NSLog(@"AVAudioSessionRouteChangeNotification received. UserInfo: %@", dict);
  }];
  id avlostobserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVAudioSessionMediaServicesWereLostNotification
      object: nil
      queue: NSOperationQueue.mainQueue
  usingBlock:^(NSNotification* note){
    NSDictionary *dict = note.userInfo;
    NSLog(@"AVAudioSessionMediaServicesWereLostNotification received. UserInfo: %@", dict);
  }];
  id avrestartobserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVAudioSessionMediaServicesWereResetNotification
      object: nil
      queue: NSOperationQueue.mainQueue
  usingBlock:^(NSNotification* note){
    NSDictionary *dict = note.userInfo;
    NSLog(@"AVAudioSessionMediaServicesWereResetNotification received. UserInfo: %@", dict);
    NSLog(@"Player Error: %lu", (unsigned long)[player hash]);
    [self disposePlayer];
    
    [self setUrl:latestUrl isLocal:latestIsLocal cookie:latestCookie playerId:latestPlayerId onReady:latestOnReady];
  }];
  [observers addObject:avlostobserver];
  [observers addObject:avrouteobserver];
  [observers addObject:avrestartobserver];
    
  // is sound ready
  [playerInfo setObject:onReady forKey:@"onReady"];
}

-(void)observePlayerItem:(AVPlayerItem *)playerItem playerId:(NSString *)playerId {
  if (latestPlayerItemObserved != playerItem) {
    if (latestPlayerItemObserved != nil) {
      [self disposePlayerItem:latestPlayerItemObserved];
    }
    [playerItem addObserver:self
                          forKeyPath:@"player.currentItem.status"
                          options:NSKeyValueObservingOptionNew
                          context:(void*)playerId];
    
    [playerItem addObserver:self
                          forKeyPath:@"playbackBufferEmpty"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
    
    [playerItem addObserver:self
                          forKeyPath:@"playbackLikelyToKeepUp"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
    
    [playerItem addObserver:self
                          forKeyPath:@"playbackBufferFull"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
    
    NSMutableSet *observers = [[NSMutableSet alloc] init];
      
    id timeEndObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemDidPlayToEndTimeNotification
                                                                        object: playerItem
                                                                        queue: nil
                                                                    usingBlock:^(NSNotification* note){
                                                                        [self onSoundComplete:playerId];
                                                                    }];
    
    
    id jumpedItemObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemTimeJumpedNotification
        object: playerItem
        queue: nil
    usingBlock:^(NSNotification* note){
      NSLog(@"AVPlayerItemTimeJumpedNotification: %@", [note object]);
    }];
    id failedEndTimeObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemFailedToPlayToEndTimeNotification
        object: playerItem
        queue: nil
    usingBlock:^(NSNotification* note){
      // item has failed to play to its end time
        NSLog(@"AVPlayerItemFailedToPlayToEndTimeNotification: %@", [note object]);
        [_channel_player invokeMethod:@"audio.onError" arguments:@{@"playerId": playerId, @"errorType": @(PLAYER_ERROR_FAILED)}];
    }];
    id stalledObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemPlaybackStalledNotification
        object: playerItem
        queue: nil
    usingBlock:^(NSNotification* note){
      // media did not arrive in time to continue playback
        NSLog(@"AVPlayerItemPlaybackStalledNotification: %@", [note object]);
    }];
    id newAccessLogObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemNewAccessLogEntryNotification
        object: playerItem
        queue: nil
    usingBlock:^(NSNotification* note){
      // a new access log entry has been added
        NSLog(@"AVPlayerItemNewAccessLogEntryNotification: %@", [note object]);
    }];
    id newAccessLogErrorObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemNewErrorLogEntryNotification
        object: playerItem
        queue: nil
    usingBlock:^(NSNotification* note){
      // a new access log entry error has been added
        NSLog(@"AVPlayerItemNewErrorLogEntryNotification: %@", [note object]);
    }];
    if (@available(iOS 13.0, *)) {
      id selectionDidChangeObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemMediaSelectionDidChangeNotification
          object: playerItem
          queue: nil
      usingBlock:^(NSNotification* note){
        // a media selection group changed its selected option
        NSLog(@"AVPlayerItemMediaSelectionDidChangeNotification: %@", [note object]);
      }];
      id timeOffsetFromLiveObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemRecommendedTimeOffsetFromLiveDidChangeNotification
          object: playerItem
          queue: nil
      usingBlock:^(NSNotification* note){
        // the value of recommendedTimeOffsetFromLive has changed
          NSLog(@"AVPlayerItemRecommendedTimeOffsetFromLiveDidChangeNotification: %@", [note object]);
      }];
      
      [observers addObject:selectionDidChangeObserver];
      [observers addObject:timeOffsetFromLiveObserver];
    }
    id failedToPlayEndTimeObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemFailedToPlayToEndTimeErrorKey
        object: playerItem
        queue: nil
    usingBlock:^(NSNotification* note){
      // NSError
        NSLog(@"AVPlayerItemFailedToPlayToEndTimeErrorKey: %@", [note object]);
      [_channel_player invokeMethod:@"audio.onError" arguments:@{@"playerId": playerId, @"errorType": @(PLAYER_ERROR_FAILED)}];
    }];
    
    
    NSMutableDictionary * playerInfo = players[_playerId];
    
    [observers addObject:timeEndObserver];
    [observers addObject:jumpedItemObserver];
    [observers addObject:failedEndTimeObserver];
    [observers addObject:stalledObserver];
    [observers addObject:newAccessLogObserver];
    [observers addObject:newAccessLogErrorObserver];
    [observers addObject:failedToPlayEndTimeObserver];
    
    [playerInfo setObject:observers forKey:@"observers_player_item"];
    latestPlayerItemObserved = playerItem;
  }
}

-(void)disposePlayerItem:(AVPlayerItem *)playerItem {
  if (latestPlayerItemObserved == playerItem) {
    @try {
      [playerItem removeObserver:self forKeyPath:@"player.currentItem.status" context:(void*)_playerId];
    } @catch (NSException * __unused exception) {}
    @try {
      [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:nil];
    } @catch (NSException * __unused exception) {}
    @try {
      [playerItem removeObserver:self forKeyPath:@"playbackBufferFull" context:nil];
    } @catch (NSException * __unused exception) {}
    @try {
      [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:nil];
    } @catch (NSException * __unused exception) {}
    
    NSMutableDictionary * playerInfo = players[_playerId];
    NSMutableSet *observers = playerInfo[@"observers_player_item"];
    
    for (id ob in observers) {
      @try {
        [ [ NSNotificationCenter defaultCenter ] removeObserver:ob ];
      } @catch (NSException * __unused exception) {}
    }
  }
}

- (void)treatPlayerObservers:(AVPlayer *)player url:(NSString *)url {
  NSMutableDictionary * playerInfo = players[_playerId];
  NSMutableSet *observers = playerInfo[@"observers"];
  @try {
    [[player currentItem] removeObserver:self forKeyPath:@"player.currentItem.status" ];
  } @catch (NSException * __unused exception) {}

  for (id ob in observers) {
    @try {
      [ [ NSNotificationCenter defaultCenter ] removeObserver:ob ];
    } @catch (NSException * __unused exception) {}
  }
  [ observers removeAllObjects ];
}

-(void) setUrl: (NSString*) url
       isLocal: (bool) isLocal
       cookie: (NSString*) cookie
       playerId: (NSString*) playerId
       onReady:(VoidCallback)onReady
{
  NSLog(@"setUrl url: %@ cookie: %@", url, cookie);
  currentResourceLoader = nil;
  
  NSMutableDictionary * playerInfo = players[playerId];
  AVPlayer *player = playerInfo[@"player"];
  
  AVPlayerItem *playerItem;

  @try {
    if (!playerInfo || ![url isEqualToString:playerInfo[@"url"]]) {
      if (isLocal) {
        playerItem = [ [ AVPlayerItem alloc ] initWithURL:[ NSURL fileURLWithPath:url ]];
      } else {
        NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:url] resolvingAgainstBaseURL:YES];
        if ([components.path rangeOfString: m3u8Ext].location != NSNotFound) {
          components.scheme = customPlaylistScheme;
          url = components.URL.absoluteString;
          NSLog(@"newUrl: %@", url);
        }
        
        NSURL *_url = [NSURL URLWithString: url];
        NSURL *_urlWildcard = [NSURL URLWithString: @"*.suamusica.com.br/*"];
        NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

        NSArray *cookiesItems = [cookie componentsSeparatedByString:@";"];
        for (NSString *cookieItem in cookiesItems) {
          NSArray *keyValue = [cookieItem componentsSeparatedByString:@"="];
          if ([keyValue count] == 2) {
            NSString *key = [keyValue objectAtIndex:0];
            NSString *value = [keyValue objectAtIndex:1];
            NSHTTPCookie *httpCookie = [ [NSHTTPCookie cookiesWithResponseHeaderFields:@{@"Set-Cookie": [NSString stringWithFormat:@"%@=%@", key, value]} forURL:_urlWildcard] objectAtIndex:0];
           
            @try {
              [cookiesStorage setCookie:httpCookie];
            }
            @catch (NSException *exception) {
              NSLog(@"%@", exception.reason);
            }
          }
        }

        NSMutableDictionary * headers = [NSMutableDictionary dictionary];
        [headers setObject:@"mp.next" forKey:@"User-Agent"];
        [headers setObject:cookie forKey:@"Cookie"];
        
        AVURLAsset * asset = [AVURLAsset URLAssetWithURL:_url options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers, AVURLAssetHTTPCookiesKey : [cookiesStorage cookies] }];
        currentResourceLoader = [asset resourceLoader];
        [[asset resourceLoader] setDelegate:(id)self queue:serialQueue];

        playerItem = [AVPlayerItem playerItemWithAsset:asset];
      }

      if (playerInfo[@"url"]) {
        @autoreleasepool {
          [self observePlayerItem:playerItem playerId:playerId];
          [ player replaceCurrentItemWithPlayerItem: playerItem ];
        }
      } else {
        [self observePlayerItem:playerItem playerId:playerId];
        [self initAVPlayer:playerId playerItem:playerItem url:url onReady: onReady];
      }
      [self resume:playerId];
      int state = STATE_BUFFERING;
      [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": playerId, @"state": @(state)}];
      [ playerInfo setObject:@false forKey:@"isPlaying" ];
      [ playerInfo setObject:url forKey:@"url" ];
    } else {
      if (player == nil && [player currentItem] == nil) {
        NSLog(@"player status: %ld",(long)[[player currentItem] status ]);
        
        [self initAVPlayer:playerId playerItem:playerItem url:url onReady: onReady];
        [self observePlayerItem:playerItem playerId:playerId];
      } else if ([[player currentItem] status ] == AVPlayerItemStatusReadyToPlay) {
        onReady(playerId);
      } else {
        [self treatPlayerObservers:player url:url];
        [self disposePlayer];
        NSLog(@"player status: %ld",(long)[[player currentItem] status ]);
        NSLog(@"Trying restart music after duck");
        [self setUrl:latestUrl isLocal:latestIsLocal cookie:latestCookie playerId:latestPlayerId onReady:latestOnReady];
      }
    }
  }
  @catch (NSException *exception) {
    NSLog(@"%@", exception.reason);
  }
  @finally {
    NSLog(@"Finally condition");
  }
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader    shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
//  NSLog(@"loadingRequest.URL: %@", [[loadingRequest request] URL]);
  NSString* scheme = [[[loadingRequest request] URL] scheme];
  if (currentResourceLoader != resourceLoader) {
    return NO;
  }
  
  if ([self isRedirectSchemeValid:scheme]) {
    return [self handleRedirectRequest:loadingRequest];
  }
  
  if ([self isCustomPlaylistSchemeValid:scheme]) {
    dispatch_async (serialQueue,  ^ {
        [self handleCustomPlaylistRequest:loadingRequest];
    });
    return YES;
  }
  
  return NO;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
  if (currentResourceLoadingRequest != nil && currentResourceLoadingRequest.request == loadingRequest.request) {
    [self setCurrentResourceLoadingRequest:nil];
  }
}

- (BOOL) isCustomPlaylistSchemeValid:(NSString *)scheme
{
    return ([customPlaylistScheme isEqualToString:scheme]);
}

/*!
 *  Handles the custom play list scheme:
 *
 *  1) Verifies its a custom playlist request, otherwise report an error.
 *  2) Generates the play list.
 *  3) Create a reponse with the new URL and report success.
 */
- (BOOL) handleCustomPlaylistRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
  [self setCurrentResourceLoadingRequest:loadingRequest];
  NSString* url = [[[loadingRequest request] URL] absoluteString];
  __block NSString *requestUrl = [self replaceScheme:customPlaylistScheme newScheme:httpsScheme fromUrl:url];
  __block NSString *playlistRequest = [self replaceScheme:customPlaylistScheme newScheme:redirectScheme fromUrl:url];
  
  NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookiesStorage cookies]];
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setHTTPMethod:@"GET"];
  [request setURL:[NSURL URLWithString:requestUrl]];
  [request setAllHTTPHeaderFields:headers];

  dispatch_semaphore_t sema = dispatch_semaphore_create(0);

  NSLog(@"==> requestURL: %@", [[request URL] absoluteString]);
  NSURLSession *session = [NSURLSession sharedSession];
  [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable _data, NSURLResponse * _Nullable _response, NSError * _Nullable error) {
    NSHTTPURLResponse *responseCode = (NSHTTPURLResponse *) _response;
    
    if([responseCode statusCode] != 200) {
      NSLog(@"Error getting %@, HTTP status code %li", requestUrl, (long)[responseCode statusCode]);
      [self reportError:loadingRequest withErrorCode:badRequestErrorCode];
      dispatch_semaphore_signal(sema);
    }
    
    NSString* file = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    NSMutableArray<NSString *>* lines = [file componentsSeparatedByString:@"\n"].mutableCopy;
    
    NSMutableArray<NSString *>* splittedUrl = [playlistRequest componentsSeparatedByString:@"/"].mutableCopy;
    if ([[splittedUrl lastObject] rangeOfString:m3u8Ext].location != NSNotFound) {
      [splittedUrl removeLastObject];
    }
    __block NSString* baseUrl = [splittedUrl componentsJoinedByString:@"/"];
    NSLog(@"==> baseURL: %@", baseUrl);
    
    for (int i = 0; i < [lines count]; i++) {
      NSString* line = lines[i];
      if ([line rangeOfString:extInfo].location != NSNotFound) {
        i++;
        NSString* treatedUrl = [lines[i] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        lines[i] = [NSString stringWithFormat:@"%@/%@", baseUrl, treatedUrl];
      }
    }
    NSString* _file = [lines componentsJoinedByString:@"\n"];
    NSLog(@"%@", _file);
    
    NSData* data = [_file dataUsingEncoding:NSUTF8StringEncoding];
    if (data)
    {
        [loadingRequest.dataRequest respondWithData:data];
        [loadingRequest finishLoading];
    } else
    {
        [self reportError:loadingRequest withErrorCode:badRequestErrorCode];
    }
    dispatch_semaphore_signal(sema);
  }] resume];
  
  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return YES;
}

/*!
 * Validates the given redirect schme.
 */
- (BOOL) isRedirectSchemeValid:(NSString *)scheme
{
    return ([redirectScheme isEqualToString:scheme]);
}

-(NSURLRequest* ) generateRedirectURL:(NSURLRequest *)sourceURL
{
  NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookiesStorage cookies]];
    NSMutableURLRequest *redirect = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[[sourceURL URL] absoluteString] stringByReplacingOccurrencesOfString:redirectScheme withString:httpsScheme]]];
  [redirect setAllHTTPHeaderFields:headers];
  NSLog(@"==> Redirect.URL: %@", [[redirect URL] absoluteString]);
    return redirect;
}
/*!
 *  The delegate handler, handles the received request:
 *
 *  1) Verifies its a redirect request, otherwise report an error.
 *  2) Generates the new URL
 *  3) Create a reponse with the new URL and report success.
 */
- (BOOL) handleRedirectRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURLRequest *redirect = nil;
  [self setCurrentResourceLoadingRequest:loadingRequest];
    
    redirect = [self generateRedirectURL:(NSURLRequest *)[loadingRequest request]];
    if (redirect)
    {
      [loadingRequest setRedirect:redirect];
      NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
      NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookiesStorage cookies]];
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[redirect URL] statusCode:redirectErrorCode HTTPVersion:nil headerFields:headers];
      [loadingRequest setResponse:response];
      [loadingRequest finishLoading];
    } else
    {
        [self reportError:loadingRequest withErrorCode:badRequestErrorCode];
    }
  return YES;
}

- (void) reportError:(AVAssetResourceLoadingRequest *) loadingRequest withErrorCode:(int) error
{
  NSLog(@"reportError.error: %d",error);
    [loadingRequest finishLoadingWithError:[NSError errorWithDomain: NSURLErrorDomain code:error userInfo: nil]];
}

-(void) play: (NSString*) playerId
        name: (NSString*) name
      author: (NSString*) author
         url: (NSString*) url
    coverUrl: (NSString*) coverUrl
      cookie: (NSString *) cookie
     isLocal: (int) isLocal
      volume: (float) volume
        time: (CMTime) time
      isNotification: (bool) respectSilence
{
  
  latestUrl = url;
  latestIsLocal = isLocal;
  latestCookie = cookie;
  latestPlayerId = playerId;
  latestOnReady = ^(NSString * playerId) {
    NSMutableDictionary * playerInfo = players[playerId];
    AVPlayer *player = playerInfo[@"player"];
    [ player setVolume:volume ];
    [ player seekToTime:time ];
    [ player play];
  };
  
  NSLog(@"Volume: %f", volume);
  NSError *error = nil;
  BOOL success = success = [[AVAudioSession sharedInstance]
              setCategory: AVAudioSessionCategoryPlayback
              error:&error];
  if (!success) {
    NSLog(@"Error setting speaker: %@", error);
    [self stop:playerId];
    [[AVAudioSession sharedInstance] setActive:NO error:&error];
    [self disposePlayer];
    NSLog(@"Trying restart music after duck");
    [self setUrl:latestUrl isLocal:latestIsLocal cookie:latestCookie playerId:latestPlayerId onReady:latestOnReady];
    return;
  } else {
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
  }
  
  if (name == nil) {
    name = @"unknown";
  }

  if (author == nil) {
    author = @"unknown";
  }

  if (coverUrl == nil) {
    coverUrl = @"unknown";
  }

  NSLog(@"[SET_CURRENT_ITEM LOG] playerId=%@ name=%@ author=%@ url=%@ coverUrl=%@", playerId, name, author, url, coverUrl);
  [self setCurrentItem:playerId name:name author:author url:url coverUrl:coverUrl];

  [ self setUrl:url
         isLocal:isLocal
         cookie:cookie
         playerId:playerId
         onReady:latestOnReady
  ];
}

-(void) updateDuration: (NSString *) playerId
{
  NSMutableDictionary * playerInfo = players[playerId];
  AVPlayer *player = playerInfo[@"player"];

  CMTime duration = [[[player currentItem]  asset] duration];
  NSLog(@"ios -> updateDuration...%f", CMTimeGetSeconds(duration));
  if(CMTimeGetSeconds(duration)>0){
    int durationInMilliseconds = CMTimeGetSeconds(duration)*1000;
    [_channel_player invokeMethod:@"audio.onDuration" arguments:@{@"playerId": playerId, @"duration": @(durationInMilliseconds)}];
  }
}

-(int) getDuration: (NSString *) playerId {
    NSMutableDictionary * playerInfo = players[playerId];
    AVPlayer *player = playerInfo[@"player"];
    
   CMTime duration = [[[player currentItem]  asset] duration];
    int mseconds= CMTimeGetSeconds(duration)*1000;
    return mseconds;
}

-(int) getCurrentPosition: (NSString *) playerId {
    NSMutableDictionary * playerInfo = players[playerId];
    AVPlayer *player = playerInfo[@"player"];
    
    CMTime duration = [player currentTime];
    int durationInMilliseconds = CMTimeGetSeconds(duration)*1000;
    return durationInMilliseconds;
}

-(void) onTimeInterval: (NSString *) playerId
                  time: (CMTime) time {
    int position =  CMTimeGetSeconds(time);
    NSMutableDictionary * playerInfo = players[playerId];
    AVPlayer *player = playerInfo[@"player"];
     
    CMTime duration = [[[player currentItem]  asset] duration];
    int _duration = CMTimeGetSeconds(duration);

    NSDictionary *currentItem = playersCurrentItem[playerId];
    NSString *name = currentItem[@"name"];
    NSString *author = currentItem[@"author"];
    NSString *coverUrl = currentItem[@"coverUrl"];
  
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{
       MPMediaItemPropertyTitle: name,
       MPMediaItemPropertyAlbumTitle: name,
       MPMediaItemPropertyArtist: author,
       MPMediaItemPropertyPlaybackDuration: [NSNumber numberWithInt:_duration],
       MPNowPlayingInfoPropertyElapsedPlaybackTime: [NSNumber numberWithInt:position]
    };
    int durationInMillis = _duration*1000;
    int positionInMillis = position*1000;

    [_channel_player invokeMethod:@"audio.onCurrentPosition" arguments:@{@"playerId": playerId, @"position": @(positionInMillis), @"duration": @(durationInMillis)}];
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: coverUrl]];
        if ( data == nil )
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage* image = [UIImage imageWithData: data];
            MPMediaItemArtwork* art = nil;
            if (@available(iOS 10.0, *)) {
                art = [[MPMediaItemArtwork alloc] initWithBoundsSize:image.size requestHandler:^UIImage * _Nonnull(CGSize size) {
                    return image;
                }];
            } else {
                art = [[MPMediaItemArtwork alloc] initWithImage: image];
            }
            [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{
                   MPMediaItemPropertyTitle: name,
                   MPMediaItemPropertyAlbumTitle: name,
                   MPMediaItemPropertyArtist: author,
                   MPMediaItemPropertyArtwork: art,
                   MPMediaItemPropertyPlaybackDuration: [NSNumber numberWithInt:_duration],
                   MPNowPlayingInfoPropertyElapsedPlaybackTime: [NSNumber numberWithInt:position]
                };
            image = nil;
            art = nil;
        });
        data = nil;
    });
    
    playerInfo = nil;
    player = nil;
}

-(void) pause: (NSString *) playerId {
  NSMutableDictionary * playerInfo = players[playerId];
  AVPlayer *player = playerInfo[@"player"];

  [ player pause ];
  [playerInfo setObject:@false forKey:@"isPlaying"];
  int state = STATE_PAUSED;
  [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": playerId, @"state": @(state)}];
}

-(void) resume: (NSString *) playerId {
  NSMutableDictionary * playerInfo = players[playerId];
  AVPlayer *player = playerInfo[@"player"];
  [player play];
  [playerInfo setObject:@true forKey:@"isPlaying"];
  int state = STATE_PLAYING;
  [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": playerId, @"state": @(state)}];
}

-(void) setVolume: (float) volume
        playerId:  (NSString *) playerId {
  NSMutableDictionary *playerInfo = players[playerId];
  AVPlayer *player = playerInfo[@"player"];
  playerInfo[@"volume"] = @(volume);
  [ player setVolume:volume ];
}

-(void) setLooping: (bool) looping
        playerId:  (NSString *) playerId {
  NSMutableDictionary *playerInfo = players[playerId];
  [playerInfo setObject:@(looping) forKey:@"looping"];
}

-(void) stop: (NSString *) playerId {
  NSMutableDictionary * playerInfo = players[playerId];

  if ([playerInfo[@"isPlaying"] boolValue]) {
    [ self pause:playerId ];
    [ self seek:playerId time:CMTimeMake(0, 1) ];
    [playerInfo setObject:@false forKey:@"isPlaying"];
    int state = STATE_STOPPED;
    [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": playerId, @"state": @(state)}];
  }
}

-(void) seek: (NSString *) playerId
        time: (CMTime) time {
  NSMutableDictionary * playerInfo = players[playerId];
  AVPlayer *player = playerInfo[@"player"];
  [[player currentItem] seekToTime:time];
}

-(void) onSoundComplete: (NSString *) playerId {
  NSLog(@"ios -> onSoundComplete...");
  NSMutableDictionary * playerInfo = players[playerId];

  if (![playerInfo[@"isPlaying"] boolValue]) {
    return;
  }

  [ self pause:playerId ];
  [ self seek:playerId time:CMTimeMakeWithSeconds(0,1) ];

  if ([ playerInfo[@"looping"] boolValue]) {
    [ self resume:playerId ];
  }

  [ _channel_player invokeMethod:@"audio.onComplete" arguments:@{@"playerId": playerId}];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
  NSLog(@"observeValueForKeyPath: %@", keyPath);
  if ([keyPath isEqualToString: @"player.currentItem.status"]) {
    NSString *playerId = (__bridge NSString*)context;
    NSMutableDictionary * playerInfo = players[playerId];
    AVPlayer *player = playerInfo[@"player"];

    NSLog(@"player status: %ld",(long)[[player currentItem] status ]);

    // Do something with the status...
    if ([[player currentItem] status ] == AVPlayerItemStatusReadyToPlay) {
      [self updateDuration:playerId];

      VoidCallback onReady = playerInfo[@"onReady"];
      if (onReady != nil) {
        [playerInfo removeObjectForKey:@"onReady"];
        onReady(playerId);
      }
    } else if ([[player currentItem] status ] == AVPlayerItemStatusFailed) {
      AVAsset *currentPlayerAsset = [[player currentItem] asset];
      
      if ([currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
       NSLog(@"Error.URL: %@", [(AVURLAsset *)currentPlayerAsset URL]);
      }
      NSLog(@"Error: %@", [[player currentItem] error]);
      NSLog(@"PlayerError: %@", [player error]);
      AVPlayerItemErrorLog *errorLog = [[player currentItem] errorLog];
      NSLog(@"errorLog: %@", errorLog);
      NSLog(@"errorLog: events: %@", [errorLog events]);
      NSLog(@"errorLog: extendedLogData: %@", [errorLog extendedLogData]);
    
      [self disposePlayerItem:[player currentItem]];
      [_channel_player invokeMethod:@"audio.onError" arguments:@{@"playerId": playerId, @"errorType": @(PLAYER_ERROR_FAILED)}];
    } else {
      NSLog(@"player status: %ld",(long)[[player currentItem] status ]);
      NSLog(@"Unknown Error: %@", [[player currentItem] error]);
      NSLog(@"Unknown PlayerError: %@", [player error]);
      AVAsset *currentPlayerAsset = [[player currentItem] asset];
      
      if ([currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
       NSLog(@"Unknown Error.URL: %@", [(AVURLAsset *)currentPlayerAsset URL]);
      }
      AVPlayerItemErrorLog *errorLog = [[player currentItem] errorLog];
      NSLog(@"Unknown errorLog: %@", errorLog);
      NSLog(@"Unknown errorLog: events: %@", [errorLog events]);
      NSLog(@"Unknown errorLog: extendedLogData: %@", [errorLog extendedLogData]);
      
      [self disposePlayerItem:[player currentItem]];
      [_channel_player invokeMethod:@"audio.onError" arguments:@{@"playerId": playerId, @"errorType": @(PLAYER_ERROR_UNKNOWN)}];
    }
  } else if ([keyPath isEqualToString: @"playbackBufferEmpty"]) {
    int state = STATE_BUFFERING;
    [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": _playerId, @"state": @(state)}];
  } else if ([keyPath isEqualToString: @"playbackLikelyToKeepUp"] || [keyPath isEqualToString: @"playbackBufferFull"]) {
    NSMutableDictionary * playerInfo = players[_playerId];
    NSNumber* newValue = [change objectForKey:NSKeyValueChangeNewKey];
    BOOL shouldStartPlaySoon = [newValue boolValue];
    if (shouldStartPlaySoon) {
      [ playerInfo setObject:@true forKey:@"isPlaying" ];
      int state = STATE_PLAYING;
       [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": _playerId, @"state": @(state)}];
    }
  } else {
    // Any unrecognized context must belong to super
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

- (void) disposePlayer {
  for (id value in timeobservers)
    [value[@"player"] removeTimeObserver:value[@"observer"]];
  timeobservers = nil;

  for (NSString* playerId in players) {
      NSMutableDictionary * playerInfo = players[playerId];
      NSMutableSet * observers = playerInfo[@"observers"];
      for (id ob in observers)
        [[NSNotificationCenter defaultCenter] removeObserver:ob];
  }
  
  NSMutableDictionary * playerInfo = players[_playerId];
  AVPlayer *player = playerInfo[@"player"];
  @autoreleasepool {
    [player replaceCurrentItemWithPlayerItem:nil];
  }
  player = nil;
  [players removeAllObjects];
  [playersCurrentItem removeAllObjects];
}

- (void)dealloc {
  [self disposePlayerItem:latestPlayerItemObserved];
  [self disposePlayer];
  
  players = nil;
  playersCurrentItem = nil;
  _playerId = nil;
  currentResourceLoadingRequest = nil;
  currentResourceLoader = nil;
  serialQueue = nil;
  timeobservers = nil;
  alreadyInAudioSession = false;
  isLoadingComplete = false;
  latestUrl = nil;
  latestIsLocal = NO;
  latestCookie = nil;
  latestPlayerId = nil;
  latestOnReady = nil;
  latestPlayerItemObserved = nil;
  
  [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

@end

