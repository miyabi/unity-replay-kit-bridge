using UnityEngine;
using System.Collections;

public class UIController : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}

	public void OnPressStartRecordingButton() {
		if (!ReplayKitBridge.IsScreenRecorderAvailable || ReplayKitBridge.IsRecording) {
			return;
		}

		ReplayKitBridge.onStartRecordingCallback = OnStartRecording;
		ReplayKitBridge.onDiscardRecordingCallback = OnDiscardRecording;
		ReplayKitBridge.onStopRecordingCallback = OnStopRecording;
		ReplayKitBridge.onFinishPreviewCallback = OnFinishPreview;
		ReplayKitBridge.IsCameraEnabled = true;
		ReplayKitBridge.IsMicrophoneEnabled = true;
		ReplayKitBridge.StartRecording();
	}

	public void OnPressDiscardRecordingButton() {
		if (!ReplayKitBridge.IsRecording) {
			return;
		}

		ReplayKitBridge.IsCameraEnabled = false;
		ReplayKitBridge.IsMicrophoneEnabled = false;
		ReplayKitBridge.DiscardRecording();
	}

	public void OnPressStopRecordingButton() {
		if (!ReplayKitBridge.IsRecording) {
			return;
		}

		ReplayKitBridge.IsCameraEnabled = false;
		ReplayKitBridge.IsMicrophoneEnabled = false;
		ReplayKitBridge.StopRecording();
	}

	public void OnStartRecording() {
		Debug.Log("OnStartRecording");
	}

	public void OnDiscardRecording() {
		Debug.Log("OnDiscardRecording");
	}

	public void OnStopRecording() {
		Debug.Log("OnStopRecording");
		Time.timeScale = 0;
		ReplayKitBridge.PresentPreviewViewController();
	}

	public void OnFinishPreview(string activityType) {
		Debug.Log("OnFinishPreview activityType=" + activityType);
		ReplayKitBridge.DismissPreviewViewController();
		Time.timeScale = 1;
	}
}
