#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <ComScore/ComScore.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.

  SCORPublisherConfiguration  *publisherConfiguration =
  [SCORPublisherConfiguration publisherConfigurationWithBuilderBlock:^(SCORPublisherConfigurationBuilder*  builder) {
    builder.publisherId = @"your_comscore_publisher_id";
  }];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
