//
//  ReplayKitBridge.swift
//  Unity-iPhone
//
//  Created by Masayuki Iwai on 2016/07/05.
//
//

import Foundation
import ReplayKit

let kCallbackTarget = "ReplayKitBridge"

class ReplayKitBridge: NSObject, RPScreenRecorderDelegate, RPPreviewViewControllerDelegate {
    static let sharedInstance: ReplayKitBridge = ReplayKitBridge()
    #if swift(>=3.0) // iOS SDK 10 or later
        let screenRecorder = RPScreenRecorder.shared()
    #else
        let screenRecorder = RPScreenRecorder.sharedRecorder()
    #endif

    var previewViewController: RPPreviewViewController?

    var screenRecorderAvailable: Bool {
        #if swift(>=3.0) // iOS SDK 10 or later
            return self.screenRecorder.isAvailable
        #else
            return self.screenRecorder.available
        #endif
    }
    
    var recording: Bool {
        #if swift(>=3.0) // iOS SDK 10 or later
            return self.screenRecorder.isRecording;
        #else
            return self.screenRecorder.recording
        #endif
    }

    var cameraEnabled: Bool {
        get {
            #if swift(>=3.0) // iOS SDK 10 or later
                if #available(iOS 10, *) {
                    // iOS 10 or later
                    return self.screenRecorder.isCameraEnabled
                }
            #endif
            
            // iOS 9
            return false
        }
        set {
            #if swift(>=3.0) // iOS SDK 10 or later
                if #available(iOS 10, *) {
                    // iOS 10 or later
                    self.screenRecorder.isCameraEnabled = newValue
                }
            #endif
        }
    }

    private var _microphoneEnabled: Bool = false
    var microphoneEnabled: Bool {
        get {
            #if swift(>=3.0) // iOS SDK 10 or later
                if #available(iOS 10, *) {
                    // iOS 10 or later
                    return self.screenRecorder.isMicrophoneEnabled
                }
            #endif

            // iOS 9
            return _microphoneEnabled
        }
        set {
            #if swift(>=3.0) // iOS SDK 10 or later
                if #available(iOS 10, *) {
                    // iOS 10 or later
                    self.screenRecorder.isMicrophoneEnabled = newValue
                    return
                }
            #endif
            
            // iOS 9
            _microphoneEnabled = newValue;
        }
    }

    private override init() {
        super.init()
        self.screenRecorder.delegate = self
    }

    // MARK: - Screen recording

    private func addCameraPreviewView() {
        #if swift(>=3.0) // iOS SDK 10 or later
            if #available(iOS 10, *) {
                // iOS 10 or later
                if let cameraPreviewView = self.screenRecorder.cameraPreviewView {
                    if let rootViewController = UnitySwift.getGLViewController() {
                        rootViewController.view.addSubview(cameraPreviewView)
                    }
                }
            }
        #endif
    }
    
    private func removeCameraPreviewView() {
        #if swift(>=3.0) // iOS SDK 10 or later
            if #available(iOS 10, *) {
                // iOS 10 or later
                if let cameraPreviewView = self.screenRecorder.cameraPreviewView {
                    cameraPreviewView.removeFromSuperview()
                }
            }
        #endif
    }

    func startRecording() {
        let handler = { [unowned self] (error: NSError?) in
            self.addCameraPreviewView()
            UnitySwift.sendMessage(kCallbackTarget, method: "OnStartRecording", message: "")
        }
        
        #if swift(>=3.0) // iOS SDK 10 or later
            if #available(iOS 10, *) {
                // iOS 10 or later
                self.screenRecorder.startRecording(handler: handler)
            } else {
                // iOS 9
                self.screenRecorder.startRecording(withMicrophoneEnabled: self.microphoneEnabled, handler: handler)
            }
        #else
            self.screenRecorder.startRecordingWithMicrophoneEnabled(self.microphoneEnabled, handler: handler)
        #endif
    }
    
    func cancelRecording() {
        let handler = { [unowned self] () in
            self.removeCameraPreviewView()
            UnitySwift.sendMessage(kCallbackTarget, method: "OnCancelRecording", message: "")
        }
        
        #if swift(>=3.0) // iOS SDK 10 or later
            self.screenRecorder.stopRecording(handler: { (previewViewController, error) in
                self.screenRecorder.discardRecording(handler: handler)
            })
        #else
            self.screenRecorder.stopRecordingWithHandler({ (previewViewController, error) in
                self.screenRecorder.discardRecordingWithHandler(handler)
            })
        #endif
    }
    
    func stopRecording() {
        let handler = { [unowned self] (previewViewController: RPPreviewViewController?, error: NSError?) in
            self.removeCameraPreviewView()

            self.previewViewController = previewViewController
            if let previewViewController = self.previewViewController {
                previewViewController.previewControllerDelegate = self
            }
            
            UnitySwift.sendMessage(kCallbackTarget, method: "OnStopRecording", message: "")
        }
        
        #if swift(>=3.0) // iOS SDK 10 or later
            self.screenRecorder.stopRecording(handler: handler)
        #else
            self.screenRecorder.stopRecordingWithHandler(handler)
        #endif
    }
    
    func presentPreviewView() -> Bool {
        if let previewViewController = self.previewViewController {
            if let rootViewController = UnitySwift.getGLViewController() {
                #if swift(>=3.0) // iOS SDK 10 or later
                    rootViewController.present(previewViewController, animated: true, completion: nil)
                #else
                    rootViewController.presentViewController(previewViewController, animated: true, completion: nil)
                #endif
            }
            return true
        }
        
        return false
    }
    
    func dismissPreviewView() {
        if let previewViewController = self.previewViewController {
            #if swift(>=3.0) // iOS SDK 10 or later
                previewViewController.dismiss(animated: true, completion: {
                    self.previewViewController = nil
                })
            #else
                previewViewController.dismissViewControllerAnimated(true, completion: {
                    self.previewViewController = nil
                })
            #endif
        }
    }

    // MARK: - RPScreenRecorderDelegate

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
    }
    
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWithError error: NSError, previewViewController: RPPreviewViewController?) {
        self.removeCameraPreviewView()
        
        self.previewViewController = previewViewController
        if let previewViewController = self.previewViewController {
            previewViewController.previewControllerDelegate = self;
        }
        
        UnitySwift.sendMessage(kCallbackTarget, method: "OnStopRecordingWithError", message: error.description);
    }

    // MARK: - RPPreviewControllerDelegate

    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        UnitySwift.sendMessage(kCallbackTarget, method: "OnFinishPreview", message: "");
    }
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        for activityType in activityTypes {
            UnitySwift.sendMessage(kCallbackTarget, method: "OnFinishPreview", message: activityType);
        }
    }
}
