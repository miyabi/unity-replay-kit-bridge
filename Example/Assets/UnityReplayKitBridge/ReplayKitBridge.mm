//
//  ReplayKitBridge.mm
//  Unity-iPhone
//
//  Created by Masayuki Iwai on 6/14/16.
//  iPad compatability by Bengt Ove Sannes on 14/03/18.
//
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

const char *kCallbackTarget = "ReplayKitBridge";

@interface ReplayKitBridge : NSObject <RPScreenRecorderDelegate, RPPreviewViewControllerDelegate>

@property (strong, nonatomic) RPPreviewViewController *previewViewController;
@property (nonatomic, readonly) RPScreenRecorder *screenRecorder;
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

- (RPScreenRecorder *)screenRecorder {
    return [RPScreenRecorder sharedRecorder];
}

#pragma mark - Screen recording

- (void)addCameraPreviewView {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([self.screenRecorder respondsToSelector:@selector(cameraPreviewView)]) {
        // iOS 10 or later
        UIView *cameraPreviewView = self.screenRecorder.cameraPreviewView;
        if (cameraPreviewView) {
            UIViewController *rootViewController = UnityGetGLViewController();
            [rootViewController.view addSubview:cameraPreviewView];
        }
    }
#endif
}

- (void)removeCameraPreviewView {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([self.screenRecorder respondsToSelector:@selector(cameraPreviewView)]) {
        // iOS 10 or later
        UIView *cameraPreviewView = self.screenRecorder.cameraPreviewView;
        if (cameraPreviewView) {
            [cameraPreviewView removeFromSuperview];
        }
    }
#endif
}

- (void)startRecording {
    __typeof__(self) __weak weakSelf = self;
    void (^handler)(NSError * _Nullable) = ^(NSError * _Nullable error){
        [weakSelf addCameraPreviewView];
        UnitySendMessage(kCallbackTarget, "OnStartRecording", "");
    };
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([self.screenRecorder respondsToSelector:@selector(startRecordingWithHandler:)]) {
        // iOS 10 or later
        [self.screenRecorder startRecordingWithHandler:handler];
        return;
    }
#endif

    // iOS 9
    [self.screenRecorder startRecordingWithMicrophoneEnabled:self.microphoneEnabled handler:handler];
}

- (void)cancelRecording {
    [self.screenRecorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        [self removeCameraPreviewView];
        [self.screenRecorder discardRecordingWithHandler:^{
            UnitySendMessage(kCallbackTarget, "OnCancelRecording", "");
        }];
    }];
}

- (void)stopRecording {
    [self.screenRecorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        [self removeCameraPreviewView];
        
        self.previewViewController = previewViewController;
        self.previewViewController.previewControllerDelegate = self;

        UnitySendMessage(kCallbackTarget, "OnStopRecording", "");
    }];
}

- (BOOL)presentPreviewView {
    if (self.previewViewController) {
        UIViewController *rootViewController = UnityGetGLViewController();
        if ( [self.previewViewController respondsToSelector:@selector(popoverPresentationController)] ) { 
            self.previewViewController.preferredContentSize = CGSizeMake(rootViewController.view.frame.size.width * 0.66, rootViewController.view.frame.size.height * 0.66);
            self.previewViewController.popoverPresentationController.sourceView = rootViewController.view;
         }
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
    return self.screenRecorder.available;
}

- (BOOL)isRecording {
    return self.screenRecorder.recording;
}

- (BOOL)isCameraEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([self.screenRecorder respondsToSelector:@selector(isCameraEnabled)]) {
        // iOS 10 or later
        return self.screenRecorder.cameraEnabled;
    }
#endif

    // iOS 9
    return NO;
}

- (void)setCameraEnabled:(BOOL)cameraEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([self.screenRecorder respondsToSelector:@selector(setCameraEnabled:)]) {
        // iOS 10 or later
        self.screenRecorder.cameraEnabled = cameraEnabled;
    }
#endif
}

- (BOOL)isMicrophoneEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([self.screenRecorder respondsToSelector:@selector(isMicrophoneEnabled)]) {
        // iOS 10 or later
        return self.screenRecorder.microphoneEnabled;
    }
#endif

    // iOS 9
    return _microphoneEnabled;
}

- (void)setMicrophoneEnabled:(BOOL)microphoneEnabled {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 // iOS SDK 10 or later
    if ([self.screenRecorder respondsToSelector:@selector(setMicrophoneEnabled:)]) {
        // iOS 10 or later
        self.screenRecorder.microphoneEnabled = microphoneEnabled;
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
    [self removeCameraPreviewView];

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
