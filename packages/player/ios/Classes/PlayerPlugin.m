#if __has_include(<smplayer/smplayer-Swift.h>)
#import <smplayer/smplayer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "smplayer-Swift.h"
#endif

#import "PlayerPlugin.h"
#import "NSString+MD5.h"

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

@import AFNetworking;

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
static int const STATE_SEEK_END = 7;
static int const STATE_BUFFER_EMPTY = 8;

static bool loadOnly = false;

static int Ok = 1;
static int NotOk = -1;

static int const PLAYER_ERROR_FAILED = 0;
static int const PLAYER_ERROR_UNKNOWN = 1;
static int const PLAYER_ERROR_UNDEFINED = 2;
static int const PLAYER_ERROR_FAILED_TO_PLAY = 3;
static int const PLAYER_ERROR_FAILED_TO_PLAY_ERROR = 4;
static int const PLAYER_ERROR_NETWORK_ERROR = 5;

static NSMutableDictionary *playersCurrentItem;

NSString *DEFAULT_COVER = @"https://images.suamusica.com.br/gaMy5pP78bm6VZhPZCs4vw0TdEw=/500x500/imgs/cd_cover.png";

NSString *MINUTES_OF_SILENCE = @"";

BOOL notifiedBufferEmptyWithNoConnection = false;

@interface PlayerPlugin()
-(int) pause;
-(int) resume;
-(void) stop;
-(float)rate;
-(void) notifyStateChangeWithState:(int)state overrideBlock:(bool)overrideBlock;
-(int) seek: (CMTime) time;
-(void) onSoundComplete;
-(void) updateDuration;
-(void) onTimeInterval: (CMTime) time;
-(void) invokeMethod:(NSString*)methodName arguments:(id _Nullable)arguments;
-(BOOL) isNotificationCommandEnabled;
-(BOOL) failedToStartPlaying;
-(BOOL) stopTryingToReconnect;
-(BOOL) shallSendEvents;
-(void) playLast;
@end

@implementation PlayerPlugin {
    FlutterResult _result;
    NSMutableDictionary *playerInfo;
}

typedef void (^VoidCallback)(void);

NSMutableSet *timeobservers;
FlutterMethodChannel *_channel_player = nil;
PlayerPlugin* instance = nil;
BOOL alreadyInAudioSession = false;
BOOL isLoadingComplete = false;
AVAssetResourceLoadingRequest* currentResourceLoadingRequest = nil;
AVAssetResourceLoader* currentResourceLoader = nil;
dispatch_queue_t serialQueue = nil;
dispatch_queue_t playerQueue = nil;

NSString* latestUrl = nil;
bool latestIsLocal = NO;
NSString* latestCookie = nil;
VoidCallback latestOnReady = nil;
AVPlayerItem* latestPlayerItemObserved = nil;
BOOL alreadyhasEnded = false;
BOOL shouldAutoStart = false;
BOOL stopTryingToReconnect = false;
NSString *lastName = nil;
NSString *lastAuthor = nil;
NSString *lastUrl = nil;
NSString *lastCoverUrl = nil;
NSString *lastCookie = nil;
float lastVolume = 1.0;
CMTime lastTime;
BOOL lastRespectSilence;

BOOL shallSendEvents = true;

PlaylistItem *currentItem = nil;

id<ReachabilityCenter> reachabilityCenter = nil;
id<RemoteControlCenter> remoteCommandCenter = nil;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[PlayerPlugin alloc] init];
            instance->playerInfo = nil;
            FlutterMethodChannel* channel = [FlutterMethodChannel
                                             methodChannelWithName:CHANNEL_NAME
                                             binaryMessenger:[registrar messenger]];
            [registrar addMethodCallDelegate:instance channel:channel];
            [PlayerPlugin saveDefaultCover:registrar];
            _channel_player = channel;
            
            NSString* minutesOfSilenceKey = [registrar lookupKeyForAsset:@"assets/30-minutes-of-silence.mp3"];
            MINUTES_OF_SILENCE = [[NSBundle mainBundle] pathForResource:minutesOfSilenceKey ofType:nil];
        }
    }
}

+(void) saveDefaultCover:(NSObject<FlutterPluginRegistrar>*)registrar {
    NSString *defaultCoverAssetKey = [registrar lookupKeyForAsset:@"assets/cd_cover.png"];
    NSString *defaultCoverPath = [[NSBundle mainBundle] pathForResource:defaultCoverAssetKey ofType:nil];
    if (defaultCoverPath != nil) {
        [[CoverCenter shared] saveDefaultCoverWithPath:defaultCoverPath];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        serialQueue = dispatch_queue_create("com.suamusica.player.queue", DISPATCH_QUEUE_SERIAL);
        playerQueue = dispatch_queue_create("com.suamusica.player.playerQueue", DISPATCH_QUEUE_SERIAL);
        [self configureRemoteCommandCenter];
        [self configureReachabilityCheck];
        [ScreenCenter addNotificationObservers];
    }
    return self;
}

-(void)configureReachabilityCheck {
    if (reachabilityCenter == nil && instance != nil) {
        id<Player> player = (id<Player>) instance;
        reachabilityCenter = [[AFNetworkBasedReachabilityCenterFactory shared] create:player];
        [reachabilityCenter start];
    }
}

-(void) playLast {
    [self play:lastName author:lastAuthor url:lastUrl coverUrl:lastCoverUrl cookie:lastCookie isLocal:false volume:lastVolume time:lastTime isNotification:lastRespectSilence];
}

-(BOOL) shallSendEvents {
    return shallSendEvents;
}

-(BOOL) stopTryingToReconnect {
    return stopTryingToReconnect;
}

-(BOOL) failedToStartPlaying {
    return [self->playerInfo[@"failedToStartPlaying"] boolValue];
}

-(void)configureRemoteCommandCenter {
    if (remoteCommandCenter == nil && instance != nil) {
        id<Player> player = (id<Player>) instance;
        remoteCommandCenter = [[RemoteControlCenterFactory shared] createWithPlayer:player];
        [remoteCommandCenter start];
    }
}

-(void)disableRemoteCommandCenter {
    NSLog(@"Player: MPRemote: Disabling Remote Command Center...");
    [self->playerInfo setObject:@false forKey:@"isPlaying"];
    [AudioSessionManager inactivateSession];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = NULL;
    if (remoteCommandCenter == nil && instance != nil) {
        [remoteCommandCenter stop];
    }
    
    NSLog(@"Player: MPRemote: Disabled Remote Command Center! Done!");
}

-(void)disableNotificationCommands {
    NSLog(@"Player: MPRemote: Disabling Remote Commands: START");
    [self->playerInfo setValue:@false forKey:@"areNotificationCommandsEnabled"];
    NSLog(@"Player: MPRemote: Disabled Remote Commands: END");
}

-(void)enableNotificationCommands {
    NSLog(@"Player: MPRemote: Enabling Remote Commands: START");
    [self->playerInfo setValue:@true forKey:@"areNotificationCommandsEnabled"];
    NSLog(@"Player: MPRemote: Enabling Remote Commands: END");
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
    shallSendEvents = [call.arguments[@"shallSendEvents"] boolValue];
    NSLog(@"Player: Method Call => call %@", call.method);
    
    typedef void (^CaseBlock)(void);
    
    // Squint and this looks like a proper switch!
    NSDictionary *methods = @{
        @"can_play":
            ^{
                result(@(Ok));
            },
        @"load":
            ^{
                NSLog(@"Player: load!");
                NSString *albumId = call.arguments[@"albumId"];
                NSString *albumTitle = call.arguments[@"albumTitle"];
                NSString *name = call.arguments[@"name"];
                NSString *author = call.arguments[@"author"];
                NSString *url = call.arguments[@"url"];
                NSString *coverUrl = call.arguments[@"coverUrl"];
                NSString *cookie = call.arguments[@"cookie"];
                if (albumId == nil)
                    result(0);
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
                if (coverUrl == nil) {
                    coverUrl = DEFAULT_COVER;
                }
                int isLocal = [call.arguments[@"isLocal"]intValue] ;
                float volume = (float)[call.arguments[@"volume"] doubleValue] ;
                int milliseconds = call.arguments[@"position"] == [NSNull null] ? 0.0 : [call.arguments[@"position"] intValue] ;
                bool respectSilence = [call.arguments[@"respectSilence"]boolValue] ;
                CMTime time = CMTimeMakeWithSeconds(milliseconds / 1000,NSEC_PER_SEC);
                
                currentItem = [[PlaylistItem alloc] initWithAlbumId:albumId albumName:albumTitle title:name artist:author url:url coverUrl:coverUrl];
                
                lastName = name;
                lastAuthor = author;
                lastUrl = url;
                lastCoverUrl = coverUrl;
                lastCookie = cookie;
                lastVolume = volume;
                lastTime = time;
                lastRespectSilence = respectSilence;
                
                int ret = [self load:name author:author url:url coverUrl:coverUrl cookie:cookie isLocal:isLocal volume:volume time:time isNotification:respectSilence];
                result(@(ret));
            },
        @"play":
            ^{
                NSLog(@"Player: play!");
                NSString *albumId = call.arguments[@"albumId"];
                NSString *albumTitle = call.arguments[@"albumTitle"];
                NSString *name = call.arguments[@"name"];
                NSString *author = call.arguments[@"author"];
                NSString *url = call.arguments[@"url"];
                NSString *coverUrl = call.arguments[@"coverUrl"];
                NSString *cookie = call.arguments[@"cookie"];
                if (albumId == nil)
                    result(0);
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
                if (coverUrl == nil) {
                    coverUrl = DEFAULT_COVER;
                }
                int isLocal = [call.arguments[@"isLocal"]intValue] ;
                float volume = (float)[call.arguments[@"volume"] doubleValue] ;
                int milliseconds = call.arguments[@"position"] == [NSNull null] ? 0.0 : [call.arguments[@"position"] intValue] ;
                bool respectSilence = [call.arguments[@"respectSilence"]boolValue] ;
                CMTime time = CMTimeMakeWithSeconds(milliseconds / 1000,NSEC_PER_SEC);
                
                currentItem = [[PlaylistItem alloc] initWithAlbumId:albumId albumName:albumTitle title:name artist:author url:url coverUrl:coverUrl];
                
                lastName = name;
                lastAuthor = author;
                lastUrl = url;
                lastCoverUrl = coverUrl;
                lastCookie = cookie;
                lastVolume = volume;
                lastTime = time;
                lastRespectSilence = respectSilence;
                
                int ret = [self play:name author:author url:url coverUrl:coverUrl cookie:cookie isLocal:isLocal volume:volume time:time isNotification:respectSilence];
                result(@(ret));
            },
        @"pause":
            ^{
                NSLog(@"Player: pause");
                int ret = [self pause];
                result(@(ret));
            },
        @"resume":
            ^{
                NSLog(@"Player: resume");
                int ret = [self resume];
                result(@(ret));
            },
        @"send_notification":
            ^{
                NSLog(@"Player: send_notification");
                NSString *albumId = call.arguments[@"albumId"];
                NSString *albumTitle = call.arguments[@"albumTitle"];
                NSString *name = call.arguments[@"name"];
                NSString *author = call.arguments[@"author"];
                NSString *url = @"silence://from-asset";
                NSString *coverUrl = call.arguments[@"coverUrl"];
                NSString *cookie = call.arguments[@"cookie"];
                bool isPlaying = [call.arguments[@"isPlaying"]boolValue] ;
                
                if (albumId == nil)
                    result(0);
                if (name == nil)
                    result(0);
                if (author == nil)
                    result(0);
                if (url == nil)
                    result(0);
                if (cookie == nil)
                    result(0);
                if (call.arguments[@"position"] == nil)
                    result(0);
                if (call.arguments[@"duration"] == nil)
                    result(0);
                if (coverUrl == nil) {
                    coverUrl = DEFAULT_COVER;
                }
                int position = call.arguments[@"position"] == [NSNull null] ? 0.0 : [call.arguments[@"position"] intValue]/1000 ;
                int duration = call.arguments[@"duration"] == [NSNull null] ? 0.0 : [call.arguments[@"duration"] intValue]/1000 ;
                CMTime time = CMTimeMakeWithSeconds(position,NSEC_PER_SEC);
                
                currentItem = [[PlaylistItem alloc] initWithAlbumId:albumId albumName:albumTitle title:name artist:author url:url coverUrl:coverUrl];
                
                lastName = name;
                lastAuthor = author;
                lastUrl = url;
                lastCoverUrl = coverUrl;
                lastCookie = cookie;
                lastTime = time;
                
                if (isPlaying == false) {
                    [self pause];
                } else if (position == 0) {
                    [self play:name author:author url:url coverUrl:coverUrl cookie:cookie isLocal:true volume:0.0 time:time isNotification:true];
                }
                [NowPlayingCenter setWithItem:currentItem];
                dispatch_async(dispatch_get_global_queue(0,0), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [NowPlayingCenter updateWithItem:currentItem rate:1.0 position:position duration:duration];
                    });
                });
                
                
                result(@(1));
            },
        @"remove_notification":
            ^{
                NSLog(@"Player: remove_notification");
                [self disableRemoteCommandCenter];
                result(@(1));
            },
        @"disable_notification_commands":
            ^{
                NSLog(@"Player: disable_notification_commands");
                [self disableNotificationCommands];
                result(@(1));
            },
        @"enable_notification_commands":
            ^{
                NSLog(@"Player: enable_notification_commands");
                [self enableNotificationCommands];
                result(@(1));
            },
        @"stop":
            ^{
                NSLog(@"Player: stop");
                [self stop];
                result(@(1));
            },
        @"release":
            ^{
                NSLog(@"Player: release");
                [self stop];
                result(@(1));
            },
        @"seek":
            ^{
                NSLog(@"Player: seek");
                if (!call.arguments[@"position"]) {
                    result(0);
                } else {
                    int milliseconds = [call.arguments[@"position"] intValue];
                    NSLog(@"Player: Seeking to: %d milliseconds", milliseconds);
                    int ret = [self seek: CMTimeMakeWithSeconds(milliseconds / 1000,NSEC_PER_SEC)];
                    result(@(ret));
                }
            },
        @"setUrl":
            ^{
                NSLog(@"Player: setUrl");
                NSString *url = call.arguments[@"url"];
                NSString *cookie = call.arguments[@"cookie"];
                int isLocal = [call.arguments[@"isLocal"]intValue];
                int ret = [ self setUrl:url
                                isLocal:isLocal
                                 cookie:cookie
                              shallPlay: true
                                onReady:^() {
                    result(@(1));
                }
                           ];
                result(@(ret));
            },
        @"getDuration":
            ^{
                
                int duration = [self getDuration];
                NSLog(@"Player: getDuration: %i ", duration);
                result(@(duration));
            },
        @"getCurrentPosition":
            ^{
                int currentPosition = [self getCurrentPosition];
                NSLog(@"Player: getCurrentPosition: %i ", currentPosition);
                result(@(currentPosition));
            },
        @"setVolume":
            ^{
                NSLog(@"Player: setVolume");
                float volume = (float)[call.arguments[@"volume"] doubleValue];
                [self setVolume:volume];
                result(@(1));
            },
        @"setReleaseMode":
            ^{
                NSLog(@"Player: setReleaseMode");
                NSString *releaseMode = call.arguments[@"releaseMode"];
                bool looping = [releaseMode hasSuffix:@"LOOP"];
                [self setLooping:looping];
                result(@(1));
            }
    };
    [self initPlayerInfo];
    CaseBlock c = methods[call.method];
    if (c) c(); else {
        NSLog(@"Player: not implemented");
        result(FlutterMethodNotImplemented);
    }
}

-(void) initPlayerInfo {
    if (!self->playerInfo) {
        self->playerInfo = [@{@"isPlaying": @false,
                               @"pausedByVoiceSearch": @false,
                               @"pausedByInterruption": @false,
                               @"volume": @(1.0),
                               @"looping": @(false),
                               @"areNotificationCommandsEnabled": @(true),
                               @"isSeeking": @(false),
                               @"failedToStartPlaying": @(false),
        } mutableCopy];
    }
}

-(void) setCurrentItem:(NSString *) name
                author:(NSString *) author
                   url:(NSString *) url
              coverUrl:(NSString *) coverUrl
{
    NSLog(@"Player: name=%@ author=%@ url=%@ coverUrl=%@", name, author, url, coverUrl);
    playersCurrentItem = [@{
        @"name": name,
        @"author": author,
        @"url": url,
        @"coverUrl": coverUrl} mutableCopy];
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


-(void) configurePlayer:(NSString *)url {
    AVPlayer *player = self->playerInfo[@"player"];
    if (@available(iOS 10.0, *)) {
        if ([url rangeOfString: m3u8Ext].location != NSNotFound) {
            player.automaticallyWaitsToMinimizeStalling = TRUE;
        } else{
            player.automaticallyWaitsToMinimizeStalling = FALSE;
        }
    }
}

-(void) initAVPlayer:(AVPlayerItem *)playerItem url:(NSString *)url onReady:(VoidCallback) onReady {
    __block AVPlayer *player = nil;
    
    dispatch_async (playerQueue,  ^{
        player = [[ AVPlayer alloc ] init];
        [self configurePlayer:url];
        player.allowsExternalPlayback = FALSE;
        [player replaceCurrentItemWithPlayerItem:playerItem];
        NSMutableSet *observers = [[NSMutableSet alloc] init];
        
        [ self->playerInfo setObject:player forKey:@"player" ];
        [ self->playerInfo setObject:url forKey:@"url" ];
        [ self->playerInfo setObject:observers forKey:@"observers"];
        
        CMTime interval = CMTimeMakeWithSeconds(0.9, NSEC_PER_SEC);
        id timeObserver = [player addPeriodicTimeObserverForInterval: interval queue: nil usingBlock:^(CMTime time){
            [self onTimeInterval:time];
        }];
        [timeobservers addObject:@{@"player":player, @"observer":timeObserver}];
        
        id avrouteobserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVAudioSessionRouteChangeNotification
                                                                                 object: nil
                                                                                  queue: NSOperationQueue.mainQueue
                                                                             usingBlock:^(NSNotification* notification){
            NSDictionary *dict = notification.userInfo;
            NSLog(@"Player: AVAudioSessionRouteChangeNotification received. UserInfo: %@", dict);
            NSNumber *reason = [[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey];

            switch (reason.unsignedIntegerValue) {
                case AVAudioSessionRouteChangeReasonCategoryChange:
                {
                    NSString *category = [[AVAudioSession sharedInstance] category];
                    
                    if ([category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
                        NSLog(@"Category: %@ PAUSE", category);
                        [self->playerInfo setValue:@(true) forKey:@"pausedByVoiceSearch"];
                        [self pause];
                    }
                    if ([category isEqualToString:AVAudioSessionCategoryPlayback]) {
                        NSLog(@"Category: %@ RESUME %@", category, self->playerInfo[@"pausedByVoiceSearch"]);
                        int pausedByVoice = [self->playerInfo[@"pausedByVoiceSearch"] intValue];
                        if (pausedByVoice == 1) {
                            [self->playerInfo setValue:@(false) forKey:@"pausedByVoiceSearch"];
                            [self resume];
                        } else {
                            NSLog(@"No operation required!");
                        }
                    }
                }
                break;
                    
                case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
                    [self pause];
                    break;
                default:
                    break;
            }
        }];
        id avlostobserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVAudioSessionMediaServicesWereLostNotification
                                                                                object: nil
                                                                                 queue: NSOperationQueue.mainQueue
                                                                            usingBlock:^(NSNotification* note){
            NSDictionary *dict = note.userInfo;
            NSLog(@"Player: AVAudioSessionMediaServicesWereLostNotification received. UserInfo: %@", dict);
        }];
        id avrestartobserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVAudioSessionMediaServicesWereResetNotification
                                                                                   object: nil
                                                                                    queue: NSOperationQueue.mainQueue
                                                                               usingBlock:^(NSNotification* note){
            NSDictionary *dict = note.userInfo;
            NSLog(@"Player: AVAudioSessionMediaServicesWereResetNotification received. UserInfo: %@", dict);
            NSLog(@"Player: Player Error: %lu", (unsigned long)[player hash]);
            [self disposePlayer];
            [self setUrl:latestUrl isLocal:latestIsLocal cookie:latestCookie shallPlay: true onReady:latestOnReady];
        }];
        
        AVAudioSession *aSession = [AVAudioSession sharedInstance];
        id interruptionObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVAudioSessionInterruptionNotification
                                                                                      object: aSession
                                                                                       queue: NSOperationQueue.mainQueue
                                                                                  usingBlock:^(NSNotification* notification){
            NSDictionary *dict = notification.userInfo;
            NSLog(@"Player: AVAudioSessionInterruptionNotification received. UserInfo: %@", dict);
            NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
            NSNumber *interruptionOption = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
                        
            switch (interruptionType.unsignedIntegerValue) {
                case AVAudioSessionInterruptionTypeBegan:{
                    int isPlaying = [self->playerInfo[@"isPlaying"] intValue];
                    if (isPlaying == 1) {
                        [self->playerInfo setValue:@(true) forKey:@"pausedByInterruption"];
                        [self pause];
                    }
                } break;
                case AVAudioSessionInterruptionTypeEnded:{
                    if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume) {
                        int pausedByInterruption = [self->playerInfo[@"pausedByInterruption"] intValue];
                        if (pausedByInterruption == 1) {
                            [self->playerInfo setValue:@(false) forKey:@"pausedByInterruption"];
                            [self resume];
                        }
                    }
                } break;
                default:
                    break;
            }
            
        }];
        
        [observers addObject:avlostobserver];
        [observers addObject:avrouteobserver];
        [observers addObject:avrestartobserver];
        [observers addObject:interruptionObserver];
        
        // is sound ready
        [self->playerInfo setObject:onReady forKey:@"onReady"];
    });
    
    
}

-(void)observePlayerItem:(AVPlayerItem *)playerItem {
    if (latestPlayerItemObserved != playerItem) {
        if (latestPlayerItemObserved != nil) {
            NSLog(@"Player: latestPlayerItemObserved");
            
            [self disposePlayerItem:latestPlayerItemObserved];
        }
        
        
        alreadyhasEnded = false;
        shouldAutoStart = true;
        [playerItem addObserver:self
                     forKeyPath:@"status"
                        options:NSKeyValueObservingOptionNew
                        context:nil];
        
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
            [self onSoundComplete];
        }];
        
        
        id jumpedItemObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemTimeJumpedNotification
                                                                                    object: playerItem
                                                                                     queue: nil
                                                                                usingBlock:^(NSNotification* note){
            [self->playerInfo setValue:@(false) forKey:@"isSeeking"];
            int state = STATE_SEEK_END;
            [self notifyStateChange:state overrideBlock:false];
            NSLog(@"Player: AVPlayerItemTimeJumpedNotification: %@", [note object]);
        }];
        id failedEndTimeObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemFailedToPlayToEndTimeNotification
                                                                                       object: playerItem
                                                                                        queue: nil
                                                                                   usingBlock:^(NSNotification* note){
            // item has failed to play to its end time
            if ([reachabilityCenter isConnected] || latestIsLocal) {
                NSLog(@"Player: AVPlayerItemFailedToPlayToEndTimeNotification: %@", [note object]);
                [self notifyOnError:PLAYER_ERROR_FAILED];
            } else {
                stopTryingToReconnect = true;
                notifiedBufferEmptyWithNoConnection = true;
#ifdef ENABLE_PLAYER_NETWORK_ERROR
                if (!notifiedBufferEmptyWithNoConnection) {
                    [self notifyOnError:PLAYER_ERROR_NETWORK_ERROR];
                }
#endif
            }
        }];
        id stalledObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemPlaybackStalledNotification
                                                                                 object: playerItem
                                                                                  queue: nil
                                                                             usingBlock:^(NSNotification* note){
            // media did not arrive in time to continue playback
            NSLog(@"Player: AVPlayerItemPlaybackStalledNotification: %@", [note object]);
        }];
        id newAccessLogObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemNewAccessLogEntryNotification
                                                                                      object: playerItem
                                                                                       queue: nil
                                                                                  usingBlock:^(NSNotification* note){
            // a new access log entry has been added
            NSLog(@"Player: AVPlayerItemNewAccessLogEntryNotification: %@", [note object]);
        }];
        id newAccessLogErrorObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemNewErrorLogEntryNotification
                                                                                           object: playerItem
                                                                                            queue: nil
                                                                                       usingBlock:^(NSNotification* note){
            // a new access log entry error has been added
            NSLog(@"Player: AVPlayerItemNewErrorLogEntryNotification: %@", [note object]);
            AVPlayerItemErrorLog *errorLog = [playerItem errorLog];
            NSLog(@"Player: AVPlayerItemNewErrorLogEntryNotification: %@", errorLog);
            
#ifdef ENABLE_PLAYER_NETWORK_ERROR
            // we decided to remove this
            if (!notifiedBufferEmptyWithNoConnection) {
                [self notifyOnError:PLAYER_ERROR_NETWORK_ERROR];
                notifiedBufferEmptyWithNoConnection = true;
            }
            [self pause];
#endif
            
        }];
        if (@available(iOS 13.0, *)) {
            id selectionDidChangeObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemMediaSelectionDidChangeNotification
                                                                                                object: playerItem
                                                                                                 queue: nil
                                                                                            usingBlock:^(NSNotification* note){
                NSLog(@"Player: AVPlayerItemMediaSelectionDidChangeNotification: %@", [note object]);
            }];
            id timeOffsetFromLiveObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemRecommendedTimeOffsetFromLiveDidChangeNotification
                                                                                                object: playerItem
                                                                                                 queue: nil
                                                                                            usingBlock:^(NSNotification* note){
                // the value of recommendedTimeOffsetFromLive has changed
                NSLog(@"Player: AVPlayerItemRecommendedTimeOffsetFromLiveDidChangeNotification: %@", [note object]);
            }];
            
            [observers addObject:selectionDidChangeObserver];
            [observers addObject:timeOffsetFromLiveObserver];
        }
        id failedToPlayEndTimeObserver = [[ NSNotificationCenter defaultCenter ] addObserverForName: AVPlayerItemFailedToPlayToEndTimeErrorKey
                                                                                             object: playerItem
                                                                                              queue: nil
                                                                                         usingBlock:^(NSNotification* note){
            // NSError
            NSLog(@"Player: AVPlayerItemFailedToPlayToEndTimeErrorKey: %@", [note object]);
            [self notifyOnError:PLAYER_ERROR_FAILED];
        }];
        
                
        [observers addObject:timeEndObserver];
        [observers addObject:jumpedItemObserver];
        [observers addObject:failedEndTimeObserver];
        [observers addObject:stalledObserver];
        [observers addObject:newAccessLogObserver];
        [observers addObject:newAccessLogErrorObserver];
        [observers addObject:failedToPlayEndTimeObserver];
        
        [self->playerInfo setObject:observers forKey:@"observers_player_item"];
        latestPlayerItemObserved = playerItem;
    }
}

-(void)disposePlayerItem:(AVPlayerItem *)playerItem {
    if (playerItem == nil) {
        return;
    }
    if (latestPlayerItemObserved == playerItem) {
        NSLog(@"Player: disposing Player Items : START");
        
        @try {
            [playerItem removeObserver:self forKeyPath:@"status" context:nil];
        } @catch (NSException * __unused exception) {
            NSLog(@"Player: failed dispose status %@", exception);
        }
        @try {
            [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:nil];
        } @catch (NSException * __unused exception) {
            NSLog(@"Player: failed dispose playbackLikelyToKeepUp %@", exception);
        }
        @try {
            [playerItem removeObserver:self forKeyPath:@"playbackBufferFull" context:nil];
        } @catch (NSException * __unused exception) {
            NSLog(@"Player: failed dispose playbackBufferFull %@", exception);
        }
        @try {
            [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:nil];
        } @catch (NSException * __unused exception) {
            NSLog(@"Player: failed dispose playbackBufferEmpty %@", exception);
        }
        
        NSMutableSet *observers = self->playerInfo[@"observers_player_item"];
        
        for (id ob in observers) {
            @try {
                [ [ NSNotificationCenter defaultCenter ] removeObserver:ob ];
            } @catch (NSException * __unused exception) {
                NSLog(@"Player: failed remove removeObserver %@ : %@", ob, exception);
            }
        }
        latestPlayerItemObserved = nil;
        NSLog(@"Player: disposing Player Items : END");
    }
}

- (void)treatPlayerObservers:(AVPlayer *)player url:(NSString *)url {
    NSMutableSet *observers = self->playerInfo[@"observers"];
    NSLog(@"Player: entered treatPlayerObservers ");
    
    @try {
        [[player currentItem] removeObserver:self forKeyPath:@"status" ];
    } @catch (NSException * __unused exception) {
        NSLog(@"Player: failed dispose status %@", exception);
    }
    
    for (id ob in observers) {
        @try {
            [ [ NSNotificationCenter defaultCenter ] removeObserver:ob ];
        } @catch (NSException * __unused exception) {      NSLog(@"Player: failed dispose generic %@", exception);
        }
    }
    [ observers removeAllObjects ];
}

-(int) setUrl: (NSString*) url
      isLocal: (bool) isLocal
       cookie: (NSString*) cookie
    shallPlay: (bool) shallPlay
      onReady:(VoidCallback)onReady
{
    if([url containsString:@"silence://from-asset"]){
        url = MINUTES_OF_SILENCE;
    }
    NSLog(@"Player: setUrl url: %@ cookie: %@", url, cookie);
    currentResourceLoader = nil;
    [self disposePlayerItem:latestPlayerItemObserved];
    AVPlayer *player = self->playerInfo[@"player"];
    [self configurePlayer:url];
    
    __block AVPlayerItem *playerItem;
    @try {
        if (!self->playerInfo || ![url isEqualToString:self->playerInfo[@"url"]] || [url containsString:@"silence.mp3"] ) {
            NSLog(@"Player: Loading new URL");
            if (isLocal) {
                NSLog(@"Player: Item is Local");
                playerItem = [ [ AVPlayerItem alloc ] initWithURL:[ NSURL fileURLWithPath:url ]];
                if (shallPlay) {
                    [self playItem:playerItem url:url onReady:onReady];
                } else {
                    [self loadItem:playerItem url:url onReady:onReady];
                }
            } else {
                NSLog(@"Player: Item is Remote");
                NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:url] resolvingAgainstBaseURL:YES];
                if ([components.path rangeOfString: m3u8Ext].location != NSNotFound) {
                    NSLog(@"Player: Item is m3u8");
                    components.scheme = customPlaylistScheme;
                    url = components.URL.absoluteString;
                    NSLog(@"Player: newUrl: %@", url);
                }
                
                NSURL *_url = [NSURL URLWithString: url];
                NSURL *_urlWildcard = [NSURL URLWithString: @"*.suamusica.com.br/*"];
                NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                [cookiesStorage removeCookiesSinceDate:[NSDate dateWithTimeIntervalSince1970:0]];
                
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
                            NSLog(@"Player: %@", exception.reason);
                        }
                    }
                }
                
                NSMutableDictionary * headers = [NSMutableDictionary dictionary];
                [headers setObject:@"mp.next" forKey:@"User-Agent"];
                [headers setObject:cookie forKey:@"Cookie"];
                
                AVURLAsset * asset = [AVURLAsset URLAssetWithURL:_url options:@{@"AVURLAssetHTTPHeaderFieldsKey": headers, AVURLAssetHTTPCookiesKey : [cookiesStorage cookies] }];
                currentResourceLoader = [asset resourceLoader];
                [[asset resourceLoader] setDelegate:(id)self queue:serialQueue];
                
                NSArray *keys = @[@"playable"];
                [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
                    NSError *error = nil;
                    AVKeyValueStatus status = [asset statusOfValueForKey:@"playable" error:&error];
                    switch (status) {
                        case AVKeyValueStatusLoaded:
                            playerItem = [AVPlayerItem playerItemWithAsset:asset];
                            break;
                            
                        case AVKeyValueStatusUnknown:
                        case AVKeyValueStatusFailed:
                        case AVKeyValueStatusCancelled:
                            NSLog(@"loadValuesAsynchronouslyForKeys: ERROR: %@", error);
                            playerItem = nil;
                            break;
                            
                        default:
                            break;
                    }
                    
                    if (shallPlay) {
                        [self playItem:playerItem url:url onReady:onReady];
                    } else {
                        [self loadItem:playerItem url:url onReady:onReady];
                    }
                }];
            }
        } else {
            NSLog(@"Player: player or item is nil player: [%@] item: [%@]", player, [player currentItem]);
            if (player == nil && [player currentItem] == nil) {
                NSLog(@"Player: player status: %ld",(long)[[player currentItem] status ]);
                
                [self initAVPlayer:playerItem url:url onReady: onReady];
                [self observePlayerItem:playerItem];
            } else if ([[player currentItem] status ] == AVPlayerItemStatusReadyToPlay) {
                NSLog(@"Player: item ready to play");
                [self observePlayerItem:[player currentItem]];
                [ self->playerInfo setObject:@true forKey:@"isPlaying" ];
                int state = STATE_PLAYING;
                [self notifyStateChange:state overrideBlock:false];
                onReady();
            } else if ([[player currentItem] status ] == AVPlayerItemStatusFailed) {
                NSLog(@"Player: FAILED STATUS. Notifying app that an error happened.");
                [self disposePlayerItem:[player currentItem]];
                [self notifyOnError:PLAYER_ERROR_FAILED];
            } else {
                NSLog(@"Player: player status: %ld",(long)[[player currentItem] status ]);
                NSLog(@"Player: If status 0 wait player reload alone.");
            }
        }
        
        return Ok;
    }
    
    @catch (NSException *exception) {
        NSLog(@"Player: Exception on setUrl: %@", exception);
    }
    @finally {
        NSLog(@"Player: Finally condition");
    }
}

-(void) loadItem:(AVPlayerItem *)playerItem
             url:(NSString *) url
         onReady:(VoidCallback)onReady {
    AVPlayer *player = self->playerInfo[@"player"];
    
    if (playerItem == nil) {
        [_channel_player invokeMethod:@"audio.onError" arguments:@{@"errorType": @(PLAYER_ERROR_FAILED)}];
    }
    
    if (self->playerInfo[@"url"]) {
        NSLog(@"Player: Replacing item");
        @autoreleasepool {
            [self observePlayerItem:playerItem];
            dispatch_async (playerQueue,  ^{
                @try {
                    [ player replaceCurrentItemWithPlayerItem: playerItem ];
                    NSLog(@"Player: Pausing");
                    [self pause];
                    [ self->playerInfo setObject:@false forKey:@"isPlaying" ];
                    [ self->playerInfo setObject:url forKey:@"url" ];
                    notifiedBufferEmptyWithNoConnection = false;
                    stopTryingToReconnect = false;
                    [NowPlayingCenter setWithItem:currentItem];
                } @catch (NSException * __unused exception) {
                    NSLog(@"Player: failed to replaceCurrentItemWithPlayerItem %@", exception);
                }
            });
        }
    } else {
        NSLog(@"Player: Initing AVPPlayer");
        [self observePlayerItem:playerItem];
        [self initAVPlayer:playerItem url:url onReady: onReady];
    }
}

-(void) playItem:(AVPlayerItem *)playerItem
             url:(NSString *) url
         onReady:(VoidCallback)onReady {
    AVPlayer *player = self->playerInfo[@"player"];
    
    if (playerItem == nil) {
        [self notifyOnError:PLAYER_ERROR_FAILED];
    }
    
    if (self->playerInfo[@"url"]) {
        NSLog(@"Player: Replacing item");
        @autoreleasepool {
            [self observePlayerItem:playerItem];
            dispatch_async (playerQueue,  ^{
                @try {
                    [ player replaceCurrentItemWithPlayerItem: playerItem ];
                } @catch (NSException * __unused exception) {
                    NSLog(@"Player: failed to replaceCurrentItemWithPlayerItem %@", exception);
                }
            });
        }
    } else {
        NSLog(@"Player: Initing AVPPlayer");
        [self observePlayerItem:playerItem];
        [self initAVPlayer:playerItem url:url onReady: onReady];
    }
    NSLog(@"Player: Resuming");
    [self resume];
    int state = STATE_BUFFERING;
    [self notifyStateChange:state overrideBlock:false];
    [ self->playerInfo setObject:@false forKey:@"isPlaying" ];
    [ self->playerInfo setObject:url forKey:@"url" ];
    
    notifiedBufferEmptyWithNoConnection = false;
    stopTryingToReconnect = false;
    
    [NowPlayingCenter setWithItem:currentItem];
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
    
    NSLog(@"Player: ==> requestURL: %@", [[request URL] absoluteString]);
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable _data, NSURLResponse * _Nullable _response, NSError * _Nullable error) {
        NSHTTPURLResponse *responseCode = (NSHTTPURLResponse *) _response;
        
        if([responseCode statusCode] != 200) {
            NSLog(@"Player: Error getting %@, HTTP status code %li", requestUrl, (long)[responseCode statusCode]);
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
        NSLog(@"Player: ==> baseURL: %@", baseUrl);
        
        for (int i = 0; i < [lines count]; i++) {
            NSString* line = lines[i];
            if ([line rangeOfString:extInfo].location != NSNotFound) {
                i++;
                NSString* treatedUrl = [lines[i] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                lines[i] = [NSString stringWithFormat:@"%@/%@", baseUrl, treatedUrl];
            }
        }
        NSString* _file = [lines componentsJoinedByString:@"\n"];
        NSLog(@"Player: %@", _file);
        
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
    NSLog(@"Player: ==> Redirect.URL: %@", [[redirect URL] absoluteString]);
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
    [self->playerInfo setValue:@(true) forKey:@"failedToStartPlaying"];
    NSLog(@"Player: reportError.error: %d",error);
    [loadingRequest finishLoadingWithError:[NSError errorWithDomain: NSURLErrorDomain code:error userInfo: nil]];
}

-(int) ensureConnected: (int) isLocal
{
#ifdef ENABLE_PLAYER_NETWORK_ERROR
    // we decided to remove this
    if (![reachabilityCenter isConnected] && !isLocal) {
        [self notifyOnError:PLAYER_ERROR_NETWORK_ERROR];
        return -1;
    }
#endif
    return Ok;
}

-(int) configureAudioSession
{
    return [AudioSessionManager activeSession] ? Ok : NotOk;
}

-(int) load: (NSString*) name
     author: (NSString*) author
        url: (NSString*) url
   coverUrl: (NSString*) coverUrl
     cookie: (NSString *) cookie
    isLocal: (int) isLocal
     volume: (float) volume
       time: (CMTime) time
isNotification: (bool) respectSilence
{
    loadOnly = true;
    if ([self ensureConnected:isLocal] == -1) {
        return -1;
    }
    
    AVPlayer *player = self->playerInfo[@"player"];
    if (player.rate != 0) {
        [player pause];
    }
    
    if (!@available(iOS 11,*)) {
        url = [url stringByReplacingOccurrencesOfString:@".m3u8"
                                             withString:@".mp3"];
        url = [url stringByReplacingOccurrencesOfString:@"stream/"
                                             withString:@""];
    }
    latestUrl = url;
    latestIsLocal = isLocal;
    latestCookie = cookie;
    latestOnReady = ^() {
        NSLog(@"Player: Inside OnReady");
        AVPlayer *player = self->playerInfo[@"player"];
        [ player setVolume:volume ];
        [ player seekToTime:time ];
        [ player play];
    };
    
    NSLog(@"Player: Volume: %f", volume);
    
    [self configureRemoteCommandCenter];
    if ([self configureAudioSession] != Ok) {
        if (!loadOnly) {
            [_channel_player invokeMethod:@"audio.onError" arguments:@{@"errorType": @(PLAYER_ERROR_FAILED)}];
            return NotOk;
        }
    }
    
    if (name == nil) {
        name = @"unknown";
    }
    
    if (author == nil) {
        author = @"unknown";
    }
    
    if (coverUrl == nil) {
        coverUrl = DEFAULT_COVER;
    }
    
    NSLog(@"Player: [SET_CURRENT_ITEM LOG] name=%@ author=%@ url=%@ coverUrl=%@", name, author, url, coverUrl);
    [self setCurrentItem:name author:author url:url coverUrl:coverUrl];
    
    
    [self setUrl:url
         isLocal:isLocal
          cookie:cookie
       shallPlay: false
         onReady:latestOnReady];
    
    return Ok;
}

-(int) play: (NSString*) name
     author: (NSString*) author
        url: (NSString*) url
   coverUrl: (NSString*) coverUrl
     cookie: (NSString *) cookie
    isLocal: (int) isLocal
     volume: (float) volume
       time: (CMTime) time
isNotification: (bool) respectSilence
{
    loadOnly = false;
    if ([self ensureConnected:isLocal] == -1) {
        return -1;
    }
    
    AVPlayer *player = self->playerInfo[@"player"];
    if (player.rate != 0) {
        [player pause];
    }
    
    if (!@available(iOS 11,*)) {
        url = [url stringByReplacingOccurrencesOfString:@".m3u8"
                                             withString:@".mp3"];
        url = [url stringByReplacingOccurrencesOfString:@"stream/"
                                             withString:@""];
    }
    latestUrl = url;
    latestIsLocal = isLocal;
    latestCookie = cookie;
    latestOnReady = ^() {
        NSLog(@"Player: Inside OnReady");
        AVPlayer *player = self->playerInfo[@"player"];
        [ player setVolume:volume ];
        [ player seekToTime:time ];
        [ player play];
    };
    
    NSLog(@"Player: Volume: %f", volume);
    
    [self configureRemoteCommandCenter];
    if ([self configureAudioSession] != Ok) {
        [self notifyOnError:PLAYER_ERROR_FAILED];
        return NotOk;
    }
    
    if (name == nil) {
        name = @"unknown";
    }
    
    if (author == nil) {
        author = @"unknown";
    }
    
    if (coverUrl == nil) {
        coverUrl = DEFAULT_COVER;
    }
    
    NSLog(@"Player: [SET_CURRENT_ITEM LOG] name=%@ author=%@ url=%@ coverUrl=%@", name, author, url, coverUrl);
    [self setCurrentItem:name author:author url:url coverUrl:coverUrl];
    
    
    [self setUrl:url
         isLocal:isLocal
          cookie:cookie
       shallPlay: true
         onReady:latestOnReady];
    
    return Ok;
    
}

-(void) updateDuration
{
    AVPlayer *player = self->playerInfo[@"player"];
    
    CMTime duration = [[[player currentItem]  asset] duration];
    NSLog(@"Player: ios -> updateDuration...%f", CMTimeGetSeconds(duration));
    if(CMTimeGetSeconds(duration)>0){
        int durationInMilliseconds = CMTimeGetSeconds(duration)*1000;
        if (shallSendEvents) {
            [_channel_player invokeMethod:@"audio.onDuration" arguments:@{@"duration": @(durationInMilliseconds)}];
        }
    }
}

-(int) getDuration {
    AVPlayer *player = self->playerInfo[@"player"];
    
    CMTime duration = [[[player currentItem]  asset] duration];
    int mseconds= CMTimeGetSeconds(duration)*1000;
    return mseconds;
}

-(int) getCurrentPosition {
    AVPlayer *player = self->playerInfo[@"player"];
    
    CMTime duration = [player currentTime];
    int durationInMilliseconds = CMTimeGetSeconds(duration)*1000;
    return durationInMilliseconds;
}

-(void) onTimeInterval: (CMTime) time {
    if (![self->playerInfo[@"isSeeking"] boolValue]) {
        int position =  CMTimeGetSeconds(time);
        AVPlayer *player = self->playerInfo[@"player"];
        
        // let us save it
        lastTime = time;
        
        CMTime duration = [[[player currentItem]  asset] duration];
        int _duration = CMTimeGetSeconds(duration);
        
        NSString *name = playersCurrentItem[@"name"];
        NSString *author = playersCurrentItem[@"author"];
        NSString *coverUrl = playersCurrentItem[@"coverUrl"];
        if (name == nil || author == nil  || coverUrl == nil){
            name = @"Sua Musica";
            author = @"Sua Musica";
            coverUrl = DEFAULT_COVER;
        }
        
        int durationInMillis = _duration*1000;
        int positionInMillis = position*1000;
        
        if (shallSendEvents) {
            [_channel_player invokeMethod:@"audio.onCurrentPosition" arguments:@{@"position": @(positionInMillis), @"duration": @(durationInMillis)}];
            
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NowPlayingCenter updateWithItem:currentItem rate:1.0 position:position duration:_duration];
                });
            });
        }
        player = nil;
    } else {
        NSLog(@"Player: onTimeInterval skipped... reason: seeking");
    }
}

-(int) pause {
    NSLog(@"Player: pause");
    AVPlayer *player = self->playerInfo[@"player"];
    
    [self doPause];
    int state = STATE_PAUSED;
    [self notifyStateChange:state overrideBlock:false];
    return Ok;
}

-(void) doPause {
    AVPlayer *player = self->playerInfo[@"player"];
    
    [ player pause ];
    [self->playerInfo setObject:@false forKey:@"isPlaying"];
}

-(int) resume {
    if ([self ensureConnected:latestIsLocal] == -1) {
        return -1;
    }
    
    NSLog(@"Player: resume");
    
    [self configureRemoteCommandCenter];
    [self configureAudioSession];
    
    AVPlayer *player = self->playerInfo[@"player"];
    [player play];
    [self->playerInfo setObject:@true forKey:@"isPlaying"];
    int state = STATE_PLAYING;
    [self notifyStateChange:state overrideBlock:false];
    
    [NowPlayingCenter setWithItem:currentItem];
    
    return Ok;
}

-(void) setVolume: (float) volume {
    NSLog(@"Player: setVolume");
    AVPlayer *player = self->playerInfo[@"player"];
    self->playerInfo[@"volume"] = @(volume);
    [ player setVolume:volume ];
}

-(void) setLooping: (bool) looping {
    NSLog(@"Player: setLooping");
    [self->playerInfo setObject:@(looping) forKey:@"looping"];
}

-(void) stop {
    NSLog(@"Player: stop");
    
    if ([self->playerInfo[@"isPlaying"] boolValue]) {
        [ self pause ];
        [ self seek:CMTimeMake(0, 1) ];
        [self->playerInfo setObject:@false forKey:@"isPlaying"];
        int state = STATE_STOPPED;
        [self notifyStateChange:state overrideBlock:false];
    }
}

-(float) rate {
    NSLog(@"Player: rate");
    
    AVPlayer *player = self->playerInfo[@"player"];
    return player.rate;
}


-(int) seek: (CMTime) time {
    if ([self ensureConnected:latestIsLocal] == -1) {
        return -1;
    }
    NSLog(@"Player: seek");
    [self->playerInfo setValue:@(true) forKey:@"isSeeking"];
    AVPlayer *player = self->playerInfo[@"player"];
    [[player currentItem] seekToTime:time];
    [self onTimeInterval:time];
    return Ok;
}

-(void) onSoundComplete {
    NSLog(@"Player: ios -> onSoundComplete...");
    if(!alreadyhasEnded){
        alreadyhasEnded = true;
        [ _channel_player invokeMethod:@"audio.onComplete" arguments:@{}];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
    NSLog(@"Player: observeValueForKeyPath: %@", keyPath);
    if ([keyPath isEqualToString: @"status"]) {
        AVPlayer *player = self->playerInfo[@"player"];
        
        NSLog(@"Player: player status: %ld",(long)[[player currentItem] status ]);
        
        // Do something with the status...
        if ([[player currentItem] status ] == AVPlayerItemStatusReadyToPlay) {
            [self updateDuration];
            
            VoidCallback onReady = self->playerInfo[@"onReady"];
            if (onReady != nil) {
                [self->playerInfo removeObjectForKey:@"onReady"];
                onReady();
            }
        } else if ([[player currentItem] status ] == AVPlayerItemStatusFailed) {
            AVAsset *currentPlayerAsset = [[player currentItem] asset];
            
            if ([currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
                NSLog(@"Player: Error.URL: %@", [(AVURLAsset *)currentPlayerAsset URL]);
            }
            NSLog(@"Player: Error: %@", [[player currentItem] error]);
            NSLog(@"Player: PlayerError: %@", [player error]);
            AVPlayerItemErrorLog *errorLog = [[player currentItem] errorLog];
            NSLog(@"Player: errorLog: %@", errorLog);
            NSLog(@"Player: errorLog: events: %@", [errorLog events]);
            NSLog(@"Player: errorLog: extendedLogData: %@", [errorLog extendedLogData]);
            
            [self disposePlayerItem:[player currentItem]];
            [self notifyOnError:PLAYER_ERROR_FAILED];
        } else {
            NSLog(@"Player: player status: %ld",(long)[[player currentItem] status ]);
            NSLog(@"Player: Unknown Error: %@", [[player currentItem] error]);
            NSLog(@"Player: Unknown PlayerError: %@", [player error]);
            AVAsset *currentPlayerAsset = [[player currentItem] asset];
            
            if ([currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
                NSLog(@"Player: Unknown Error.URL: %@", [(AVURLAsset *)currentPlayerAsset URL]);
            }
            AVPlayerItemErrorLog *errorLog = [[player currentItem] errorLog];
            NSLog(@"Player: Unknown errorLog: %@", errorLog);
            NSLog(@"Player: Unknown errorLog: events: %@", [errorLog events]);
            NSLog(@"Player: Unknown errorLog: extendedLogData: %@", [errorLog extendedLogData]);
            
            [self disposePlayerItem:[player currentItem]];
            // [self notifyOnError:PLAYER_ERROR_UNKNOWN];
        }
    } else if ([keyPath isEqualToString: @"playbackBufferEmpty"]) {
        AVPlayer *player = self->playerInfo[@"player"];
        if (player.rate != 0) {
            int state = [reachabilityCenter isConnected] ? STATE_BUFFER_EMPTY : STATE_BUFFERING;
            [self notifyStateChange:state overrideBlock:false];
        } else {
            NSLog(@"Player: playbackBufferEmpty rate == 0");
            int state = STATE_PAUSED;
            [self notifyStateChange:state overrideBlock:false];
        }
    } else if ([keyPath isEqualToString: @"playbackLikelyToKeepUp"] || [keyPath isEqualToString: @"playbackBufferFull"]) {
        AVPlayer *player = self->playerInfo[@"player"];
        NSNumber* newValue = [change objectForKey:NSKeyValueChangeNewKey];
        BOOL shouldStartPlaySoon = [newValue boolValue];
        NSLog(@"Player: observeValueForKeyPath: %@ -- shouldStartPlaySoon: %s player.rate = %.2f shouldAutoStart = %s loadOnly = %s", keyPath, shouldStartPlaySoon ? "YES": "NO", player.rate, shouldAutoStart ? "YES": "NO", loadOnly? "YES": "NO");
        if (shouldStartPlaySoon && player.rate == 0 && shouldAutoStart && !loadOnly) {
            player.rate = 1.0;
        }
        if (shouldStartPlaySoon && player.rate != 0) {
            [ self->playerInfo setObject:@true forKey:@"isPlaying" ];
            int state = STATE_PLAYING;
            [self notifyStateChange:state overrideBlock:false];
        }
        shouldAutoStart = false;
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void) notifyStateChange:(int)state
             overrideBlock:(bool)overrideBlock
{
    if (shallSendEvents || overrideBlock) {
        [_channel_player invokeMethod:@"state.change" arguments:@{@"state": @(state)}];
    }
}


- (void) notifyOnError: (int)errorType
{
    if (shallSendEvents) {
        [_channel_player invokeMethod:@"audio.onError" arguments:@{@"errorType": @(errorType)}];
    }
}


- (void)invokeMethod:(NSString*)methodName arguments:(id _Nullable)arguments
{
    [_channel_player invokeMethod:methodName arguments:arguments];
}

-(BOOL)isNotificationCommandEnabled
{
    return [self->playerInfo[@"areNotificationCommandsEnabled"] boolValue];
}

- (void) disposePlayer {
    for (id value in timeobservers)
        [value[@"player"] removeTimeObserver:value[@"observer"]];
    timeobservers = nil;
    
    NSMutableSet * observers = self->playerInfo[@"observers"];
    for (id ob in observers)
        [[NSNotificationCenter defaultCenter] removeObserver:ob];
    
    AVPlayer *player = self->playerInfo[@"player"];
    @autoreleasepool {
        [player replaceCurrentItemWithPlayerItem:nil];
    }
    player = nil;
    [playersCurrentItem removeAllObjects];
}

- (void)dealloc {
    NSLog(@"Player: DEALLOC:");
    [self disposePlayerItem:latestPlayerItemObserved];
    [self disposePlayer];
    
    playersCurrentItem = nil;
    currentResourceLoadingRequest = nil;
    currentResourceLoader = nil;
    serialQueue = nil;
    playerQueue = nil;
    timeobservers = nil;
    alreadyInAudioSession = false;
    isLoadingComplete = false;
    latestUrl = nil;
    latestIsLocal = NO;
    latestCookie = nil;
    latestOnReady = nil;
    latestPlayerItemObserved = nil;
    
    [reachabilityCenter stop];
    [remoteCommandCenter stop];
}

@end
