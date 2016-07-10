using UnityEngine;
using System.Runtime.InteropServices;

public class ReplayKitBridge : MonoBehaviour {
    #region Declare external C interface
    #if UNITY_IOS && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void _rp_startRecording();

    [DllImport("__Internal")]
    private static extern void _rp_cancelRecording();

    [DllImport("__Internal")]
    private static extern void _rp_stopRecording();

    [DllImport("__Internal")]
    private static extern bool _rp_presentPreviewView();

    [DllImport("__Internal")]
    private static extern void _rp_dismissPreviewView();

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
        #if UNITY_IOS && !UNITY_EDITOR
        _rp_startRecording();
        #endif
    }

    public static void CancelRecording() {
        #if UNITY_IOS && !UNITY_EDITOR
        _rp_cancelRecording();
        #endif
    }

    public static void StopRecording() {
        #if UNITY_IOS && !UNITY_EDITOR
        _rp_stopRecording();
        #endif
    }

    public static bool PresentPreviewView() {
        #if UNITY_IOS && !UNITY_EDITOR
        return _rp_presentPreviewView();
        #else
        return false;
        #endif
    }

    public static void DismissPreviewView() {
        #if UNITY_IOS && !UNITY_EDITOR
        _rp_dismissPreviewView();
        #endif
    }

    public static bool IsScreenRecorderAvailable {
        get {
            #if UNITY_IOS && !UNITY_EDITOR
            return _rp_isScreenRecorderAvailable();
            #else
            return false;
            #endif
        }
    }

    public static bool IsRecording {
        get {
            #if UNITY_IOS && !UNITY_EDITOR
            return _rp_isRecording();
            #else
            return false;
            #endif
        }
    }

    public static bool IsCameraEnabled {
        get {
            #if UNITY_IOS && !UNITY_EDITOR
            return _rp_isCameraEnabled();
            #else
            return false;
            #endif
        }
        set {
            #if UNITY_IOS && !UNITY_EDITOR
            _rp_setCameraEnabled(value);
            #endif
        }
    }

    public static bool IsMicrophoneEnabled {
        get {
            #if UNITY_IOS && !UNITY_EDITOR
            return _rp_isMicrophoneEnabled();
            #else
            return false;
            #endif
        }
        set {
            #if UNITY_IOS && !UNITY_EDITOR
            _rp_setMicrophoneEnabled(value);
            #endif
        }
    }
    #endregion

    #region Singleton implementation
    private static ReplayKitBridge _instance;
    public static ReplayKitBridge Instance {
        get {
            if (_instance == null) {
                var obj = new GameObject("ReplayKitBridge");
                _instance = obj.AddComponent<ReplayKitBridge>();
            }
            return _instance;
        }
    }

    void Awake() {
        if (_instance != null) {
            Destroy(gameObject);
            return;
        }

        DontDestroyOnLoad(gameObject);
    }
    #endregion

    #region Delegates
    public System.Action onStartRecordingCallback;
    public System.Action onCancelRecordingCallback;
    public System.Action onStopRecordingCallback;
    public System.Action<string> onFinishPreviewCallback;

    public void OnStartRecording() {
        if (onStartRecordingCallback != null) {
            onStartRecordingCallback.Invoke();
        }
    }

    public void OnCancelRecording() {
        if (onCancelRecordingCallback != null) {
            onCancelRecordingCallback.Invoke();
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
