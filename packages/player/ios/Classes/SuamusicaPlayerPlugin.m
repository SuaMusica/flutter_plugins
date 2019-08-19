#import "SuamusicaPlayerPlugin.h"
#import <suamusica_player/suamusica_player-Swift.h>

@implementation SuamusicaPlayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSuamusicaPlayerPlugin registerWithRegistrar:registrar];
}
@end
