//
//  ReplayKitBridge.mm
//  Unity-iPhone
//
//  Created by Masayuki Iwai on 6/14/16.
//
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

const NSString *kCallbackTarget = @"ReplayKitBridge";

@interface ReplayKitBridge : NSObject <RPScreenRecorderDelegate, RPPreviewViewControllerDelegate>

@property (strong, nonatomic) RPPreviewViewController *previewViewController;

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

- (void)callback:(NSString *)message withParameter:(NSString *)parameter {
    UnitySendMessage([kCallbackTarget cStringUsingEncoding:NSUTF8StringEncoding],
                     [message cStringUsingEncoding:NSUTF8StringEncoding],
                     [parameter cStringUsingEncoding:NSUTF8StringEncoding]);
}

#pragma mark - Screen recording

- (void)startRecording {
    [[RPScreenRecorder sharedRecorder] startRecordingWithHandler:^(NSError * _Nullable error) {
        UIView *cameraPreviewView = [RPScreenRecorder sharedRecorder].cameraPreviewView;
        if (cameraPreviewView) {
            UIViewController *rootViewController = UnityGetGLViewController();
            [rootViewController.view addSubview:cameraPreviewView];
        }
        [self callback:@"OnStartRecording" withParameter:@""];
    }];
}

- (void)discardRecording {
    UIView *cameraPreviewView = [RPScreenRecorder sharedRecorder].cameraPreviewView;
    if (cameraPreviewView) {
        [cameraPreviewView removeFromSuperview];
    }

    [[RPScreenRecorder sharedRecorder] discardRecordingWithHandler:^{
        [self callback:@"OnDiscardRecording" withParameter:@""];
    }];
}

- (void)stopRecording {
    UIView *cameraPreviewView = [RPScreenRecorder sharedRecorder].cameraPreviewView;
    if (cameraPreviewView) {
        [cameraPreviewView removeFromSuperview];
    }
    
    [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        self.previewViewController = previewViewController;
        self.previewViewController.previewControllerDelegate = self;

        [self callback:@"OnStopRecording" withParameter:@""];
    }];
}

- (BOOL)presentPreviewViewController {
    if (self.previewViewController) {
        UIViewController *rootViewController = UnityGetGLViewController();
        [rootViewController presentViewController:self.previewViewController animated:YES completion:nil];
        return YES;
    }
    
    return NO;
}

- (void)dismissPreviewController {
    if (self.previewViewController) {
        [self.previewViewController dismissViewControllerAnimated:YES completion:^{
            self.previewViewController = nil;
        }];
    }
}

#pragma mark - RPPreviewControllerDelegate

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController {
    [self callback:@"OnFinishPreview" withParameter:@""];
}

- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet<NSString *> *)activityTypes {
    for (NSString *activityType in activityTypes) {
        [self callback:@"OnFinishPreview" withParameter:activityType];
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
    
    BOOL _rp_presentPreviewViewController() {
        return [[ReplayKitBridge sharedInstance] presentPreviewViewController];
    }
    
    void _rp_dismissPreviewViewController() {
        [[ReplayKitBridge sharedInstance] dismissPreviewController];
    }

    BOOL _rp_isScreenRecorderAvailable() {
        return [RPScreenRecorder sharedRecorder].available;
    }

    BOOL _rp_isRecording() {
        return [RPScreenRecorder sharedRecorder].recording;
    }

    BOOL _rp_isCameraEnabled() {
        return [RPScreenRecorder sharedRecorder].cameraEnabled;
    }

    void _rp_setCameraEnabled(BOOL cameraEnabled) {
        [RPScreenRecorder sharedRecorder].cameraEnabled = cameraEnabled;
    }

    BOOL _rp_isMicrophoneEnabled() {
        return [RPScreenRecorder sharedRecorder].microphoneEnabled;
    }

    void _rp_setMicrophoneEnabled(BOOL microphoneEnabled) {
        [RPScreenRecorder sharedRecorder].microphoneEnabled = microphoneEnabled;
    }
}
