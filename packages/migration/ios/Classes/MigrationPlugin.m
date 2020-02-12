#import "MigrationPlugin.h"
#if __has_include(<migration/migration-Swift.h>)
#import <migration/migration-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "migration-Swift.h"
#endif

@implementation MigrationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMigrationPlugin registerWithRegistrar:registrar];
}
@end
