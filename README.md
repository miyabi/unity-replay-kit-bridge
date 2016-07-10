# Unity ReplayKit Bridge

Native plugin to use ReplayKit with Unity.  
The ReplayKit framework provides the ability to record video and audio within your app and share it.

## Downloads

Download unity-replay-kit-bridge.unitypackage from link below:

-   [Releases · miyabi/unity-replay-kit-bridge](https://github.com/miyabi/unity-replay-kit-bridge/releases)

## Installation

1.  Open your project in Unity.
2.  Open the downloaded package by double-click or choose Assets menu > Import Package > Custom Package... to import plugin into your project.
3.  Plugin files are imported into UnityReplayKitBridge folder.

## Usage

### Properties

```csharp
// Check whether the screen recorder is available.
if (ReplayKitBridge.IsScreenRecorderAvailable) {
    Debug.Log("Screen recorder is available.");
}

// Check whether the app is recording.
if (ReplayKitBridge.IsRecording) {
    Debug.Log("Now recording.");
}

// Check whether the camera is enabled. (iOS 10 or later)
if (!ReplayKitBridge.IsCameraEnabled) {
    // Enable the camera. (iOS 10 or later)
    ReplayKitBridge.IsCameraEnabled = true;
}

// Check whether the microphone is enabled.
if (!ReplayKitBridge.IsMicrophoneEnabled) {
    // Enable the microphone.
    ReplayKitBridge.IsMicrophoneEnabled = true;
}
```

### Set up delegates

```csharp
ReplayKitBridge.Instance.onStartRecordingCallback = () => {
    // Called when recording has been started.
};

ReplayKitBridge.Instance.onStopRecordingCallback = () => {
    // Called when recording has been stopped.
    Time.timeScale = 0;                     // Pause scene while user is editting and sharing recorded screen.
    ReplayKitBridge.PresentPreviewView();   // Present preview view.
};

ReplayKitBridge.Instance.onFinishPreviewCallback = (string activityType) => {
    // Called when recorded video has been saved or when the done button has been pressed.
    ReplayKitBridge.DismissPreviewView();   // Dismiss preview view.
    Time.timeScale = 1;                     // Resume time scale.
};

ReplayKitBridge.Instance.onCancelRecordingCallback = () => {
    // Called when recording has been stopped and discarded.
};

ReplayKitBridge.Instance.onStopRecordingWithErrorCallback = (string error) => {
    // Called when recording has been stopped due to an error.
};
```

### Start/stop/cancel screen recording

```csharp
ReplayKitBridge.StartRecording();       // Start screen recording.
ReplayKitBridge.StopRecording();        // Stop screen recording.
ReplayKitBridge.CancelRecording();      // Stop and discard current screen recording.
```

### Preview view

```csharp
ReplayKitBridge.PresentPreviewView();   // Present preview view.
ReplayKitBridge.DismissPreviewView();   // Dismiss preview view.
```

## Configuration

### Camera Usage Description

Camera Usage Description (NSCameraUsageDescription) is defined in UnityReplayKitBridge/Editor/Config.cs.  
This value is written in Info.plist and displayed when the system prompts the user to allow access to the camera.

```csharp
public const string CameraUsageDescription = "Screen recording";
```

## Requirements

iOS 9 or later

## Compatibility

Unity 5.3.5f1
Xcode 7.3.1
