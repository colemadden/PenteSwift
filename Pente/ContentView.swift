import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "gamecontroller")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Pente Game")
                .font(.title)
            Text("Use this app in iMessage")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
