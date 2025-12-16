import ActivityKit

struct DamagoAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }
    // Fixed non-changing properties about your activity go here!
    var name: String
}
