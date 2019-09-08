#import "AssetLoaderDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation AssetLoaderDelegate

- (id)init{
    if (self = [super init]) {
    }
    return self;
}

#pragma mark - AVURLAsset resource loading

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    NSLog(@"pendingRequests:%@",loadingRequest);
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    NSLog(@"pendingRequests:%@",loadingRequest);
}

@end
