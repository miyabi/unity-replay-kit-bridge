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
    RPScreenRecorder *screenRecorder = [RPScreenRecorder sharedRecorder];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([screenRecorder respondsToSelector:@selector(startRecordingWithHandler:)]) {
        [screenRecorder startRecordingWithHandler:^(NSError * _Nullable error) {
            // iOS 10 or later
            UIView *cameraPreviewView = screenRecorder.cameraPreviewView;
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
    [screenRecorder startRecordingWithMicrophoneEnabled:self.microphoneEnabled
                                                handler:^(NSError * _Nullable error) {
                                                    UnitySendMessage(kCallbackTarget, "OnStartRecording", "");
                                                }];
}

- (void)cancelRecording {
    RPScreenRecorder *screenRecorder = [RPScreenRecorder sharedRecorder];

    [screenRecorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
        if ([screenRecorder respondsToSelector:@selector(cameraPreviewView)]) {
            // iOS 10 or later
            UIView *cameraPreviewView = screenRecorder.cameraPreviewView;
            if (cameraPreviewView) {
                [cameraPreviewView removeFromSuperview];
            }
        }
#endif
        
        [screenRecorder discardRecordingWithHandler:^{
            UnitySendMessage(kCallbackTarget, "OnCancelRecording", "");
        }];
    }];
}

- (void)stopRecording {
    RPScreenRecorder *screenRecorder = [RPScreenRecorder sharedRecorder];
    
    [screenRecorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
        if ([screenRecorder respondsToSelector:@selector(cameraPreviewView)]) {
            // iOS 10 or later
            UIView *cameraPreviewView = screenRecorder.cameraPreviewView;
            if (cameraPreviewView) {
                [cameraPreviewView removeFromSuperview];
            }
        }
#endif
        
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
    RPScreenRecorder *screenRecorder = [RPScreenRecorder sharedRecorder];
    if ([screenRecorder respondsToSelector:@selector(isCameraEnabled)]) {
        // iOS 10 or later
        return screenRecorder.cameraEnabled;
    }
#endif

    // iOS 9
    return NO;
}

- (void)setCameraEnabled:(BOOL)cameraEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    RPScreenRecorder *screenRecorder = [RPScreenRecorder sharedRecorder];
    if ([screenRecorder respondsToSelector:@selector(setCameraEnabled:)]) {
        // iOS 10 or later
        screenRecorder.cameraEnabled = cameraEnabled;
    }
#endif
}

- (BOOL)isMicrophoneEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    RPScreenRecorder *screenRecorder = [RPScreenRecorder sharedRecorder];
    if ([screenRecorder respondsToSelector:@selector(isMicrophoneEnabled)]) {
        // iOS 10 or later
        return screenRecorder.microphoneEnabled;
    }
#endif

    // iOS 9
    return _microphoneEnabled;
}

- (void)setMicrophoneEnabled:(BOOL)microphoneEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    RPScreenRecorder *screenRecorder = [RPScreenRecorder sharedRecorder];
    if ([screenRecorder respondsToSelector:@selector(setMicrophoneEnabled:)]) {
        // iOS 10 or later
        screenRecorder.microphoneEnabled = microphoneEnabled;
        return;
    }
#endif

    // iOS 9
    _microphoneEnabled = microphoneEnabled;
}

#pragma mark - RPScreenRecorderDelegate

- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder {
}

- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithError:(NSError *)error previewViewController:(RPPreviewViewController *)previewViewController {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([screenRecorder respondsToSelector:@selector(cameraPreviewView)]) {
        // iOS 10 or later
        UIView *cameraPreviewView = screenRecorder.cameraPreviewView;
        if (cameraPreviewView) {
            [cameraPreviewView removeFromSuperview];
        }
    }
#endif

    self.previewViewController = previewViewController;
    self.previewViewController.previewControllerDelegate = self;
    
    UnitySendMessage(kCallbackTarget, "OnStopRecordingWithError", error.description.UTF8String);
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
    
    void _rp_cancelRecording() {
        [[ReplayKitBridge sharedInstance] cancelRecording];
    }

    void _rp_stopRecording() {
        [[ReplayKitBridge sharedInstance] stopRecording];
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
