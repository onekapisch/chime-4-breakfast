import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
