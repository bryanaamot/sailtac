import Foundation
import OSLog
import SwiftUI

let useLocalServer = true

#if !SKIP
let iPad = UIDevice.current.userInterfaceIdiom == .pad
#else
let iPad = false // UIDevice.current.userInterfaceIdiom == .pad
#endif

// see: https://developer.android.com/studio/run/emulator-networking
#if !SKIP
let endPoint =  useLocalServer ? "http://localhost:8080" : "https://services.sailtac.com"
let websocketEndpoint = useLocalServer ? "ws://localhost:8080" : "wss://services.sailtac.com"
#else
let endPoint =  useLocalServer ? "http://10.0.2.2:8080" : "https://services.sailtac.com"
let websocketEndpoint = useLocalServer ? "ws://localhost:8080" : "wss://services.sailtac.com"
#endif


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
                #if !SKIP
                UIScreen.main.brightness = 1.0
                #endif
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
