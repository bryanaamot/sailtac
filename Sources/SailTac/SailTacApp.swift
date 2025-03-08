import Foundation
import OSLog
import SwiftUI

let logger: Logger = Logger(subsystem: "net.brainware.sailtac", category: "SailTac")

/// The Android SDK number we are running against, or `nil` if not running on Android
let androidSDK = ProcessInfo.processInfo.environment["android.os.Build.VERSION.SDK_INT"].flatMap({ Int($0) })

/// The shared top-level view for the app, loaded from the platform-specific App delegates below.
///
/// The default implementation merely loads the `ContentView` for the app and logs a message.
public struct RootView : View {
    @ObservedObject var appData = AppData.shared
    public init() {
    }

    public var body: some View {
        ContentView()
            .environmentObject(appData)
            .task {
                logger.log("Welcome to Skip on \(androidSDK != nil ? "Android" : "Darwin")!")
                logger.warning("Skip app logs are viewable in the Xcode console for iOS; Android logs can be viewed in Studio or using adb logcat")
            }
            .onOpenURL { url in
                handleUniversalLink(url: url)
            }
    }
    
    private func handleUniversalLink(url: URL) {
        if url.path == "/verify" {
            // Navigate to verification screen logic
            print("Verification link received")
        } else {
            // Handle other paths
            print("Unhandled path: \(url.path)")
        }
    }
}

#if !SKIP
public protocol SailTacApp : App {
}

/// The entry point to the SailTac app.
/// The concrete implementation is in the SailTacApp module.
public extension SailTacApp {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
#endif
