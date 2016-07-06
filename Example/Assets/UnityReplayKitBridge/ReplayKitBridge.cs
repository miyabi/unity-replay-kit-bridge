using UnityEngine;
using System.Runtime.InteropServices;

public class ReplayKitBridge : MonoBehaviour {
    #region Declare external C interface
    #if UNITY_IOS
    [DllImport("__Internal")]
    private static extern void _rp_startRecording();

    [DllImport("__Internal")]
    private static extern void _rp_discardRecording();

    [DllImport("__Internal")]
    private static extern void _rp_stopRecording();

    [DllImport("__Internal")]
    private static extern bool _rp_presentPreviewViewController();

    [DllImport("__Internal")]
    private static extern void _rp_dismissPreviewViewController();

    [DllImport("__Internal")]
    private static extern bool _rp_isScreenRecorderAvailable();

    [DllImport("__Internal")]
    private static extern bool _rp_isRecording();

    [DllImport("__Internal")]
    private static extern bool _rp_isCameraEnabled();

    [DllImport("__Internal")]
    private static extern void _rp_setCameraEnabled(bool cameraEnabled);

    [DllImport("__Internal")]
    private static extern bool _rp_isMicrophoneEnabled();

    [DllImport("__Internal")]
    private static extern void _rp_setMicrophoneEnabled(bool microphoneEnabled);
    #endif
    #endregion

    #region Wrapped methods and properties
    public static void StartRecording() {
        #if UNITY_IOS
        _rp_startRecording();
        #endif
    }

    public static void DiscardRecording() {
        #if UNITY_IOS
        _rp_discardRecording();
        #endif
    }

    public static void StopRecording() {
        #if UNITY_IOS
        _rp_stopRecording();
        #endif
    }

    public static bool PresentPreviewViewController() {
        #if UNITY_IOS
        return _rp_presentPreviewViewController();
        #else
        return false;
        #endif
    }

    public static void DismissPreviewViewController() {
        #if UNITY_IOS
        _rp_dismissPreviewViewController();
        #endif
    }

    public static bool IsScreenRecorderAvailable {
        get {
            #if UNITY_IOS
            return _rp_isScreenRecorderAvailable();
            #else
            return false;
            #endif
        }
    }

    public static bool IsRecording {
        get {
            #if UNITY_IOS
            return _rp_isRecording();
            #else
            return false;
            #endif
        }
    }

    public static bool IsCameraEnabled {
        get {
            #if UNITY_IOS
            return _rp_isCameraEnabled();
            #else
            return false;
            #endif
        }
        set {
            #if UNITY_IOS
            _rp_setCameraEnabled(value);
            #endif
        }
    }

    public static bool IsMicrophoneEnabled {
        get {
            #if UNITY_IOS
            return _rp_isMicrophoneEnabled();
            #else
            return false;
            #endif
        }
        set {
            #if UNITY_IOS
            _rp_setMicrophoneEnabled(value);
            #endif
        }
    }
    #endregion

    #region Singleton implementation
    private static ReplayKitBridge _sharedInstance;
    public static ReplayKitBridge SharedInstance {
        get {
            if (_sharedInstance == null) {
                var obj = new GameObject("ReplayKitBridge");
                _sharedInstance = obj.AddComponent<ReplayKitBridge>();
            }
            return _sharedInstance;
        }
    }

    void Awake() {
        if (_sharedInstance != null) {
            Destroy(gameObject);
            return;
        }

        DontDestroyOnLoad(gameObject);
    }
    #endregion

    #region Delegates
    public System.Action onStartRecordingCallback;
    public System.Action onDiscardRecordingCallback;
    public System.Action onStopRecordingCallback;
    public System.Action<string> onFinishPreviewCallback;

    public void OnStartRecording() {
        if (onStartRecordingCallback != null) {
            onStartRecordingCallback.Invoke();
        }
    }

    public void OnDiscardRecording() {
        if (onDiscardRecordingCallback != null) {
            onDiscardRecordingCallback.Invoke();
        }
    }

    public void OnStopRecording() {
        if (onStopRecordingCallback != null) {
            onStopRecordingCallback.Invoke();
        }
    }

    public void OnFinishPreview(string activityType) {
        if (onFinishPreviewCallback != null) {
            onFinishPreviewCallback.Invoke(activityType);
        }
    }
    #endregion
}
