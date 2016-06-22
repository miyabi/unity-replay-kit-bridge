using UnityEngine;
using System.Runtime.InteropServices;

public class ReplayKitBridge : MonoBehaviour {
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

	public static void StartRecording() {
		_rp_startRecording();
	}

	public static void DiscardRecording() {
		_rp_discardRecording();
	}

	public static void StopRecording() {
		_rp_stopRecording();
	}

	public static bool PresentPreviewViewController() {
		return _rp_presentPreviewViewController();
	}

	public static void DismissPreviewViewController() {
		_rp_dismissPreviewViewController();
	}

    public static bool IsScreenRecorderAvailable {
    	get { return _rp_isScreenRecorderAvailable(); }
    }

    public static bool IsRecording {
    	get { return _rp_isRecording(); }
    }

	public static bool IsCameraEnabled {
		get { return _rp_isCameraEnabled(); }
		set { _rp_setCameraEnabled(value); }
	}

	public static bool IsMicrophoneEnabled {
		get { return _rp_isMicrophoneEnabled(); }
		set { _rp_setMicrophoneEnabled(value); }
	}

	public static System.Action onStartRecordingCallback;
	public static System.Action onDiscardRecordingCallback;
	public static System.Action onStopRecordingCallback;
	public static System.Action<string> onFinishPreviewCallback;

	private static ReplayKitBridge _sharedInstance;

	static ReplayKitBridge() {
		var obj = new GameObject("ReplayKitBridge");
		_sharedInstance = obj.AddComponent<ReplayKitBridge>();
	}

	void Awake() {
		if (_sharedInstance != null) {
			Destroy(gameObject);
			return;
		}

		DontDestroyOnLoad(gameObject);
	}

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
}
