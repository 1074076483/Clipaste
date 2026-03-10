import SwiftUI
import AppKit

struct ScrollAxisSwapperModifier: ViewModifier {
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    guard let window = event.window, window.className.contains("Panel") else {
                        return event
                    }

                    guard !event.modifierFlags.contains(.shift),
                          abs(event.scrollingDeltaY) > 0,
                          abs(event.scrollingDeltaX) == 0 else {
                        return event
                    }

                    guard let cgEvent = event.cgEvent?.copy() else {
                        return event
                    }

                    let deltaY = cgEvent.getIntegerValueField(.scrollWheelEventDeltaAxis1)
                    cgEvent.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: deltaY)
                    cgEvent.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 0)

                    let pointDeltaY = cgEvent.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
                    cgEvent.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: pointDeltaY)
                    cgEvent.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)

                    return NSEvent(cgEvent: cgEvent) ?? event
                }
            }
            .onDisappear {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                    self.monitor = nil
                }
            }
    }
}

extension View {
    /// 开启：垂直滚轮自动映射为水平滚动
    func mapVerticalScrollToHorizontal() -> some View {
        modifier(ScrollAxisSwapperModifier())
    }
}
