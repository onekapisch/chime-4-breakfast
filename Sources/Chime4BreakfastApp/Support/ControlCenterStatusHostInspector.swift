import AppKit
import ApplicationServices

/// Detects the Control Center failure mode where several third-party status
/// items exist in the Accessibility tree but all are assigned a zero-sized slot.
enum ControlCenterStatusHostInspector {
    private static let collapsedItemThreshold = 3

    static func needsRecoveryPanel(
        statusItemIsInMenuBarBand: Bool,
        collapsedStatusItemCount: Int?
    ) -> Bool {
        guard statusItemIsInMenuBarBand else {
            return true
        }
        return (collapsedStatusItemCount ?? 0) >= collapsedItemThreshold
    }

    static func collapsedStatusItemCount() -> Int? {
        guard let controlCenter = NSWorkspace.shared.runningApplications.first(
            where: { $0.bundleIdentifier == "com.apple.controlcenter" }
        ) else {
            return nil
        }

        let application = AXUIElementCreateApplication(controlCenter.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.2)
        guard let menuBarValue = attribute(kAXMenuBarAttribute, of: application),
              CFGetTypeID(menuBarValue) == AXUIElementGetTypeID() else {
            return nil
        }
        let menuBar = unsafeBitCast(menuBarValue, to: AXUIElement.self)

        guard let items = attribute(kAXChildrenAttribute, of: menuBar) as? [AXUIElement] else {
            return nil
        }

        return items.reduce(into: 0) { count, item in
            guard attribute(kAXRoleAttribute, of: item) as? String == kAXMenuBarItemRole,
                  let size = size(of: item),
                  size.width <= 1,
                  size.height <= 1 else {
                return
            }
            count += 1
        }
    }

    private static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private static func size(of element: AXUIElement) -> CGSize? {
        guard let value = attribute(kAXSizeAttribute, of: element),
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        var size = CGSize.zero
        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }
        return size
    }
}
