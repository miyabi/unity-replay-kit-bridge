using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace ReplayKitBridge {
    public static class PostProcessor {
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

                //// Configure build settings
                // Disable bitcode
                proj.SetBuildProperty(targetGuid, "ENABLE_BITCODE", "NO");

                proj.WriteToFile(projPath);

                //// Modify Info.plist
                var plistPath = buildPath + "/Info.plist";

                // Describe camera usage
                var description = Regex.Replace(Config.CameraUsageDescription, "([\\\\'\"])", "\\$1");
                ExecutePlistBuddyCommand(string.Format("Add :NSCameraUsageDescription string '{0}'", description), plistPath);
            }
        }
    }
}
