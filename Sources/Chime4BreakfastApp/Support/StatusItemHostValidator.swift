import Foundation

/// Separates a real menu-bar host from the off-screen frames that Control Center
/// can report while it has not actually allocated a visible status-item slot.
enum StatusItemHostValidator {
    static func isHosted(
        statusItemFrame: CGRect,
        screenFrame: CGRect,
        visibleFrame: CGRect
    ) -> Bool {
        guard statusItemFrame.width > 1, statusItemFrame.height > 1 else {
            return false
        }

        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY
        guard menuBarHeight > 0 else {
            return false
        }

        let menuBarFrame = CGRect(
            x: screenFrame.minX,
            y: visibleFrame.maxY,
            width: screenFrame.width,
            height: menuBarHeight
        )
        return menuBarFrame.intersects(statusItemFrame)
    }
}
