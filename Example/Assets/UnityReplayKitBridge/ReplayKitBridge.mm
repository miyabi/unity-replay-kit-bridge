//
//  ReplayKitBridge.mm
//  Unity-iPhone
//
//  Created by Masayuki Iwai on 6/14/16.
//
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

const char *kCallbackTarget = "ReplayKitBridge";

@interface ReplayKitBridge : NSObject <RPScreenRecorderDelegate, RPPreviewViewControllerDelegate>

@property (strong, nonatomic) RPPreviewViewController *previewViewController;
@property (nonatomic, readonly) BOOL screenRecorderAvailable;
@property (nonatomic, readonly) BOOL recording;
@property (nonatomic) BOOL cameraEnabled;
@property (nonatomic) BOOL microphoneEnabled;

@end

@implementation ReplayKitBridge

static ReplayKitBridge *_sharedInstance = nil;
+ (ReplayKitBridge *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [ReplayKitBridge new];
        [RPScreenRecorder sharedRecorder].delegate = _sharedInstance;
    });
    return _sharedInstance;
}

#pragma mark - Screen recording

- (void)startRecording {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([recorder respondsToSelector:@selector(startRecordingWithHandler:)]) {
        // iOS 10 or later
        [recorder startRecordingWithHandler:^(NSError * _Nullable error) {
            UIView *cameraPreviewView = [RPScreenRecorder sharedRecorder].cameraPreviewView;
            if (cameraPreviewView) {
                UIViewController *rootViewController = UnityGetGLViewController();
                [rootViewController.view addSubview:cameraPreviewView];
            }
            
            UnitySendMessage(kCallbackTarget, "OnStartRecording", "");
        }];
        
        return;
    }
#endif

    // iOS 9
    [recorder startRecordingWithMicrophoneEnabled:self.microphoneEnabled
                                          handler:^(NSError * _Nullable error) {
                                              UnitySendMessage(kCallbackTarget, "OnStartRecording", "");
                                          }];
}

- (void)discardRecording {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([recorder respondsToSelector:@selector(cameraPreviewView)]) {
        // iOS 10 or later
        UIView *cameraPreviewView = recorder.cameraPreviewView;
        if (cameraPreviewView) {
            [cameraPreviewView removeFromSuperview];
        }
    }
#endif

    [recorder discardRecordingWithHandler:^{
        UnitySendMessage(kCallbackTarget, "OnDiscardRecording", "");
    }];
}

- (void)stopRecording {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([recorder respondsToSelector:@selector(cameraPreviewView)]) {
        // iOS 10 or later
        UIView *cameraPreviewView = recorder.cameraPreviewView;
        if (cameraPreviewView) {
            [cameraPreviewView removeFromSuperview];
        }
    }
#endif
    
    [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        self.previewViewController = previewViewController;
        self.previewViewController.previewControllerDelegate = self;

        UnitySendMessage(kCallbackTarget, "OnStopRecording", "");
    }];
}

- (BOOL)presentPreviewView {
    if (self.previewViewController) {
        UIViewController *rootViewController = UnityGetGLViewController();
        [rootViewController presentViewController:self.previewViewController animated:YES completion:nil];
        return YES;
    }
    
    return NO;
}

- (void)dismissPreviewView {
    if (self.previewViewController) {
        [self.previewViewController dismissViewControllerAnimated:YES completion:^{
            self.previewViewController = nil;
        }];
    }
}

- (BOOL)isScreenRecorderAvailable {
    return [RPScreenRecorder sharedRecorder].available;
}

- (BOOL)isRecording {
    return [RPScreenRecorder sharedRecorder].recording;
}

- (BOOL)isCameraEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    if ([recorder respondsToSelector:@selector(isCameraEnabled)]) {
        // iOS 10 or later
        return recorder.cameraEnabled;
    }
#endif

    // iOS 9
    return NO;
}

- (void)setCameraEnabled:(BOOL)cameraEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    if ([recorder respondsToSelector:@selector(setCameraEnabled:)]) {
        // iOS 10 or later
        recorder.cameraEnabled = cameraEnabled;
    }
#endif
}

- (BOOL)isMicrophoneEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    if ([recorder respondsToSelector:@selector(isMicrophoneEnabled)]) {
        // iOS 10 or later
        return recorder.microphoneEnabled;
    }
#endif

    // iOS 9
    return _microphoneEnabled;
}

- (void)setMicrophoneEnabled:(BOOL)microphoneEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    if ([recorder respondsToSelector:@selector(setMicrophoneEnabled:)]) {
        // iOS 10 or later
        recorder.microphoneEnabled = microphoneEnabled;
        return;
    }
#endif

    // iOS 9
    _microphoneEnabled = microphoneEnabled;
}

#pragma mark - RPPreviewControllerDelegate

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController {
    UnitySendMessage(kCallbackTarget, "OnFinishPreview", "");
}

- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet<NSString *> *)activityTypes {
    for (NSString *activityType in activityTypes) {
        UnitySendMessage(kCallbackTarget, "OnFinishPreview", activityType.UTF8String);
    }
}

@end

#pragma mark - C interface

extern "C" {
    void _rp_startRecording() {
        [[ReplayKitBridge sharedInstance] startRecording];
    }

    void _rp_stopRecording() {
        [[ReplayKitBridge sharedInstance] stopRecording];
    }
    
    void _rp_discardRecording() {
        [[ReplayKitBridge sharedInstance] discardRecording];
    }
    
    BOOL _rp_presentPreviewView() {
        return [[ReplayKitBridge sharedInstance] presentPreviewView];
    }
    
    void _rp_dismissPreviewView() {
        [[ReplayKitBridge sharedInstance] dismissPreviewView];
    }

    BOOL _rp_isScreenRecorderAvailable() {
        return [[ReplayKitBridge sharedInstance] isScreenRecorderAvailable];
    }

    BOOL _rp_isRecording() {
        return [[ReplayKitBridge sharedInstance] isRecording];
    }

    BOOL _rp_isCameraEnabled() {
        return [[ReplayKitBridge sharedInstance] isCameraEnabled];
    }

    void _rp_setCameraEnabled(BOOL cameraEnabled) {
        [[ReplayKitBridge sharedInstance] setCameraEnabled:cameraEnabled];
    }

    BOOL _rp_isMicrophoneEnabled() {
        return [[ReplayKitBridge sharedInstance] isMicrophoneEnabled];
    }

    void _rp_setMicrophoneEnabled(BOOL microphoneEnabled) {
        [[ReplayKitBridge sharedInstance] setMicrophoneEnabled:microphoneEnabled];
    }
}
