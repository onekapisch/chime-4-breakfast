import Foundation

struct WindowSnapshot: Equatable {
    let app: TargetApp
    let message: String
    let fingerprint: String
    /// True when the user was in another app at any point while this response
    /// was generating (or at completion) - i.e. they stepped away and should be
    /// pulled back with the screen glow.
    var userWasAway: Bool = false
}
