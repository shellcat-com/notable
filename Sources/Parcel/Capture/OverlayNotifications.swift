import CoreGraphics
import Foundation

extension Notification.Name {
    /// Posted when Tab is pressed in an Overlay. `object` is the target `CGDirectDisplayID`.
    static let overlayTabPressed = Notification.Name("dev.parable.overlayTabPressed")
}
