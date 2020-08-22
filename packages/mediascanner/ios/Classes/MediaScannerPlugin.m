#import "MediaScannerPlugin.h"
#if __has_include(<MediaScanner/MediaScanner-Swift.h>)
#import <MediaScanner/MediaScanner-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "MediaScanner-Swift.h"
#endif

@implementation MediaScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMediaScannerPlugin registerWithRegistrar:registrar];
}
@end
