#import "ComscorePlugin.h"
#import "ComScore.h"

@implementation ComscorePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"comscore"
                                     binaryMessenger:[registrar messenger]];
    ComscorePlugin* instance = [[ComscorePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"initialize" isEqualToString:call.method]) {
        // NSString *publisherId = call.arguments[@"publisherId"];
        // bool secureTransmissionEnabled = call.arguments[@"secureTransmissionEnabled"];
        
        // SCORPublisherConfiguration  *publisherConfiguration =
        // [SCORPublisherConfiguration publisherConfigurationWithBuilderBlock:^(SCORPublisherConfigurationBuilder*  builder) {
        //     builder.publisherId = @"your_comscore_publisher_id";
        // }];
        
//        SCORPublisherConfiguration *publisherConfiguration = [SCORPublisherConfiguration publisherConfigurationWithBuilderBlock:^(SCORPublisherConfigurationBuilder*  builder) {
//            builder.publisherId = publisherId;
//            builder.secureTransmissionEnabled = secureTransmissionEnabled;
//        }];
        result(@true);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
