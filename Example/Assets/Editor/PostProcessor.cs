using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace ReplayKitExample {
	public static class PostProcessor {
		internal static DirectoryInfo CopyToDirectory(string srcPath, string destDirPath) {
			FileSystemInfo srcInfo = null;
			if(Directory.Exists(srcPath)) {
				srcInfo = new DirectoryInfo(srcPath);
			} else if(File.Exists(srcPath)) {
				srcInfo = new FileInfo(srcPath);
			}

			if(srcInfo == null) {
				UnityEngine.Debug.LogError("File not found: " + srcPath);
				return null;
			}

			// Clean up destination
			if(File.Exists(destDirPath)) {
				File.Delete(destDirPath);
			}

			var destDirInfo = new DirectoryInfo(destDirPath);
			// Create destination directory if needed
			if(!destDirInfo.Exists) {
				destDirInfo.Create();
			}

			var destPath = Path.Combine(destDirInfo.FullName, srcInfo.Name);
			if(srcInfo.GetType() == typeof(DirectoryInfo)) {
				// Copy directory contents
				var destInfo = new DirectoryInfo(destPath);
				if(destInfo.Exists) {
					destInfo.Delete(true);
				}
				destInfo.Create();

				((DirectoryInfo)srcInfo).GetFiles()
					.Select(_=>_.CopyTo(Path.Combine(destPath, _.Name), true));

				((DirectoryInfo)srcInfo).GetDirectories()
					.Select(_=>CopyToDirectory(_.FullName, destPath));

				return destInfo;
			} else {
				// Copy just a file
				((FileInfo)srcInfo).CopyTo(destPath, true);
				return destDirInfo;
			}
		}

		internal static void ExecutePlistBuddyCommand(string command, string path) {
			using(var process = new Process()) {
				process.StartInfo.FileName = "/usr/libexec/PlistBuddy";
				process.StartInfo.Arguments = string.Format("-c \"{0}\" \"{1}\"", command, path);
				process.StartInfo.CreateNoWindow = true;
				try {
					process.Start();
					process.WaitForExit();
					process.Close();
				} catch(System.Exception e) {
					UnityEngine.Debug.LogError(e.Message);
				}
			}
		}

		[PostProcessBuild]
		public static void OnPostProcessBuild(BuildTarget buildTarget, string buildPath) {
			if(buildTarget == BuildTarget.iOS) {
				// So PBXProject.GetPBXProjectPath returns wrong path, we need to construct path by ourselves instead
	 			// var projPath = PBXProject.GetPBXProjectPath(buildPath);
				var projPath = buildPath + "/Unity-iPhone.xcodeproj/project.pbxproj";
				var proj = new PBXProject();
				proj.ReadFromFile(projPath);

				var targetGuid = proj.TargetGuidByName(PBXProject.GetUnityTargetName());
				var debugConfigGuid = proj.BuildConfigByName(targetGuid, "Debug");

				//// Configure build settings
				// Disable bitcode
				proj.SetBuildProperty(targetGuid, "ENABLE_BITCODE", "NO");

				//// Modify Info.plist
				string plistPath = buildPath + "/Info.plist";

				ExecutePlistBuddyCommand("Add :NSCameraUsageDescription string 'Screen recording'", plistPath);

				proj.WriteToFile(projPath);
			}
		}
	}
}
