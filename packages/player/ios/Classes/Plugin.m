#import "Plugin.h"

#import "AssetLoaderDelegate.h"

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

static NSString *const CHANNEL_NAME = @"suamusica_player";

static int *const STATE_IDLE = 0;
static int *const STATE_BUFFERING = 1;
static int *const STATE_PLAYING = 2;
static int *const STATE_PAUSED = 3;
static int *const STATE_STOPPED = 4;
static int *const STATE_COMPLETED = 5;
static int *const STATE_ERROR = 6;

static NSMutableDictionary * players;

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
FlutterMethodChannel *_channel_player;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
                                   methodChannelWithName:CHANNEL_NAME
                                   binaryMessenger:[registrar messenger]];
  Plugin* instance = [[Plugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  _channel_player = channel;
}

- (id)init {
  self = [super init];
  if (self) {
      players = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString * playerId = call.arguments[@"playerId"];
  NSLog(@"iOS => call %@, playerId %@", call.method, playerId);

  typedef void (^CaseBlock)(void);

  // Squint and this looks like a proper switch!
  NSDictionary *methods = @{
                @"play":
                  ^{
                    NSLog(@"play!");
                    NSString *url = call.arguments[@"url"];
                    NSString *cookie = call.arguments[@"cookie"];
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
                    NSLog(@"cookie: %@", cookie);
                    NSLog(@"isLocal: %d %@", isLocal, call.arguments[@"isLocal"] );
                    NSLog(@"volume: %f %@", volume, call.arguments[@"volume"] );
                    NSLog(@"position: %d %@", milliseconds, call.arguments[@"positions"] );
                    [self play:playerId url:url cookie:cookie isLocal:isLocal volume:volume time:time isNotification:respectSilence];
                  },
                @"pause":
                  ^{
                    NSLog(@"pause");
                    [self pause:playerId];
                  },
                @"resume":
                  ^{
                    NSLog(@"resume");
                    [self resume:playerId];
                  },
                @"stop":
                  ^{
                    NSLog(@"stop");
                    [self stop:playerId];
                  },
                @"release":
                    ^{
                        NSLog(@"release");
                        [self stop:playerId];
                    },
                @"seek":
                  ^{
                    NSLog(@"seek");
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
                    NSLog(@"setUrl");
                    NSString *url = call.arguments[@"url"];
                    NSString *cookie = call.arguments[@"cookie"];
                    int isLocal = [call.arguments[@"isLocal"]intValue];
                    [ self setUrl:url
                          isLocal:isLocal
                          cookie:cookie
                          playerId:playerId
                          onReady:^(NSString * playerId) {
                            int state = STATE_PLAYING;
                            [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": playerId, @"state": @(state)}];
                            result(@(1));
                          }
                    ];
                  },
                @"getDuration":
                    ^{
                        
                        int duration = [self getDuration:playerId];
                        NSLog(@"getDuration: %i ", duration);
                        result(@(duration));
                    },
				@"getCurrentPosition":
                    ^{
                        int currentPosition = [self getCurrentPosition:playerId];
                        NSLog(@"getCurrentPosition: %i ", currentPosition);
                        result(@(currentPosition));
                    },
                @"setVolume":
                  ^{
                    NSLog(@"setVolume");
                    float volume = (float)[call.arguments[@"volume"] doubleValue];
                    [self setVolume:volume playerId:playerId];
                  },
                @"setReleaseMode":
                  ^{
                    NSLog(@"setReleaseMode");
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
  }
}

-(void) setUrl: (NSString*) url
       isLocal: (bool) isLocal
       cookie: (NSString*) cookie
       playerId: (NSString*) playerId
       onReady:(VoidCallback)onReady
{
  NSMutableDictionary * playerInfo = players[playerId];
  AVPlayer *player = playerInfo[@"player"];
  NSMutableSet *observers = playerInfo[@"observers"];
  AVPlayerItem *playerItem;
    
  NSLog(@"setUrl url: %@ cookie: %@", url, cookie);

  @try {
    if (!playerInfo || ![url isEqualToString:playerInfo[@"url"]]) {
      if (isLocal) {
        playerItem = [ [ AVPlayerItem alloc ] initWithURL:[ NSURL fileURLWithPath:url ]];
      } else {
        NSURL *_url = [NSURL URLWithString: url];
        NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSMutableArray *cookies = [NSMutableArray array];	
        NSArray *cookiesItems = [cookie componentsSeparatedByString:@";"];	
        for (NSString *cookieItem in cookiesItems) {	
          NSArray *keyValue = [cookieItem componentsSeparatedByString:@"="];	
          if ([keyValue count] == 2) {	
            NSString *key = [keyValue objectAtIndex:0];	
            NSString *value = [keyValue objectAtIndex:1];	
            NSHTTPCookie *httpCookie = [ [NSHTTPCookie cookiesWithResponseHeaderFields:@{@"Set-Cookie": [NSString stringWithFormat:@"%@=%@", key, value]} forURL:_url] objectAtIndex:0];
            [cookies addObject:httpCookie];
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
        
        // AVURLAsset * asset = [AVURLAsset URLAssetWithURL:_url options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers, AVURLAssetHTTPCookiesKey : cookies }];
        AVURLAsset * asset = [AVURLAsset URLAssetWithURL:_url options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers, AVURLAssetHTTPCookiesKey : [cookiesStorage cookies] }];
          
        NSLog(@"resourceLoader: %@", [asset resourceLoader]);
        [[asset resourceLoader] setDelegate:self queue:dispatch_get_main_queue()];

        playerItem = [AVPlayerItem playerItemWithAsset:asset];
      }
        
      if (playerInfo[@"url"]) {
        [[player currentItem] removeObserver:self forKeyPath:@"player.currentItem.status" ];

        [ playerInfo setObject:url forKey:@"url" ];

        for (id ob in observers) {
          [ [ NSNotificationCenter defaultCenter ] removeObserver:ob ];
        }
        [ observers removeAllObjects ];
        [ player replaceCurrentItemWithPlayerItem: playerItem ];
      } else {
        player = [[ AVPlayer alloc ] initWithPlayerItem: playerItem ];
        observers = [[NSMutableSet alloc] init];

        [ playerInfo setObject:player forKey:@"player" ];
        [ playerInfo setObject:url forKey:@"url" ];
        [ playerInfo setObject:observers forKey:@"observers" ];

        CMTime interval = CMTimeMakeWithSeconds(0.2, NSEC_PER_SEC);
        id timeObserver = [ player  addPeriodicTimeObserverForInterval: interval queue: nil usingBlock:^(CMTime time){
          [self onTimeInterval:playerId time:time];
        }];
        [timeobservers addObject:@{@"player":player, @"observer":timeObserver}];
      }
        
      id anobserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemDidPlayToEndTimeNotification
                                                                          object: playerItem
                                                                          queue: nil
                                                                      usingBlock:^(NSNotification* note){
                                                                          [self onSoundComplete:playerId];
                                                                      }];
      [observers addObject:anobserver];
        
      // is sound ready
      [playerInfo setObject:onReady forKey:@"onReady"];
      [playerItem addObserver:self
                            forKeyPath:@"player.currentItem.status"
                            options:0
                            context:(void*)playerId];
        
    } else {
      if ([[player currentItem] status ] == AVPlayerItemStatusReadyToPlay) {
        onReady(playerId);
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

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
  NSLog(@"resourceLoader(2): %@", resourceLoader);
  NSLog(@"pendingRequests:%@",loadingRequest);
  return YES;
}

-(void) play: (NSString*) playerId
         url: (NSString*) url
      cookie: (NSString *) cookie
     isLocal: (int) isLocal
      volume: (float) volume
        time: (CMTime) time
      isNotification: (bool) respectSilence
{
    NSError *error = nil;
    AVAudioSessionCategory category;
    if (respectSilence) {
        category = AVAudioSessionCategoryAmbient;
    } else {
        category = AVAudioSessionCategoryPlayback;
    }
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: category
                    error:&error];
  if (!success) {
    NSLog(@"Error setting speaker: %@", error);
  }
  [[AVAudioSession sharedInstance] setActive:YES error:&error];

  [ self setUrl:url
         isLocal:isLocal 
         cookie:cookie 
         playerId:playerId 
         onReady:^(NSString * playerId) {
           NSMutableDictionary * playerInfo = players[playerId];
           AVPlayer *player = playerInfo[@"player"];
           [ player setVolume:volume ];
           [ player seekToTime:time ];
           [ player play];
           [ playerInfo setObject:@true forKey:@"isPlaying" ];
           int state = STATE_PLAYING;
            [_channel_player invokeMethod:@"state.change" arguments:@{@"playerId": playerId, @"state": @(state)}];
         }    
  ];
}

-(void) updateDuration: (NSString *) playerId
{
  NSMutableDictionary * playerInfo = players[playerId];
  AVPlayer *player = playerInfo[@"player"];

  CMTime duration = [[[player currentItem]  asset] duration];
  NSLog(@"ios -> updateDuration...%f", CMTimeGetSeconds(duration));
  if(CMTimeGetSeconds(duration)>0){
    NSLog(@"ios -> invokechannel");
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
    int position =  CMTimeGetSeconds(time)*1000;
    int duration = [self getDuration:playerId];
    NSLog(@"ios -> onTimeInterval...");
    [_channel_player invokeMethod:@"audio.onCurrentPosition" arguments:@{@"playerId": playerId, @"position": @(position), @"duration": @(duration)}];
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
      NSLog(@"Error: %@", [[player currentItem] error]);
      AVPlayerItemErrorLog *errorLog = [[player currentItem] errorLog];
      NSLog(@"errorLog: %@", errorLog);
      NSLog(@"errorLog: events: %@", [errorLog events]);
      NSLog(@"errorLog: extendedLogData: %@", [errorLog extendedLogData]);
    
      [_channel_player invokeMethod:@"audio.onError" arguments:@{@"playerId": playerId, @"value": @"AVPlayerItemStatus.failed"}];
    }
  } else {
    // Any unrecognized context must belong to super
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

- (void)dealloc {
  for (id value in timeobservers)
    [value[@"player"] removeTimeObserver:value[@"observer"]];
  timeobservers = nil;

  for (NSString* playerId in players) {
      NSMutableDictionary * playerInfo = players[playerId];
      NSMutableSet * observers = playerInfo[@"observers"];
      for (id ob in observers)
        [[NSNotificationCenter defaultCenter] removeObserver:ob];
  }
  players = nil;
}

@end
