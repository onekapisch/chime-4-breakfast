import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
