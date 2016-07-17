//
//  ReplayKitBridge.mm
//  Unity-iPhone
//
//  Created by Masayuki Iwai on 6/14/16.
//
//

#import <ReplayKit/ReplayKit.h>
#include "unityswift-Swift.h"

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
        return [[ReplayKitBridge sharedInstance] screenRecorderAvailable];
    }

    BOOL _rp_isRecording() {
        return [[ReplayKitBridge sharedInstance] recording];
    }

    BOOL _rp_isCameraEnabled() {
        return [[ReplayKitBridge sharedInstance] cameraEnabled];
    }

    void _rp_setCameraEnabled(BOOL cameraEnabled) {
        [[ReplayKitBridge sharedInstance] setCameraEnabled:cameraEnabled];
    }

    BOOL _rp_isMicrophoneEnabled() {
        return [[ReplayKitBridge sharedInstance] microphoneEnabled];
    }

    void _rp_setMicrophoneEnabled(BOOL microphoneEnabled) {
        [[ReplayKitBridge sharedInstance] setMicrophoneEnabled:microphoneEnabled];
    }
}
