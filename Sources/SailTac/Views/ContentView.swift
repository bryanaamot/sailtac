import SwiftUI

public struct ContentView: View {
    @AppStorage("tab") var tab = Tab.signin
    @AppStorage("name") var name = "Skipper"
    @State var appearance = ""
    @State var isBeating = false
    @EnvironmentObject var appData: AppData
    @State var isSheetPresented = false

    public init() {
    }

    public var body: some View {
        @State var windAngle = Angle(degrees: 0.0)
        TabView(selection: $tab) {
            if !appData.signedIn {
                SignInView()
                    .tabItem { Label("Sign In", systemImage: "house.fill") }
                    .tag(Tab.signin)
            } else {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(Tab.signin)

//                SpinnableCompass(windAngle: $windAngle)
//                    .tabItem { Label("Map", systemImage: "map") }
//                    .tag(Tab.map)
            }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
//        .tint(.red)
    }
}

enum Tab : String, Hashable {
    case signin, map, settings
}
