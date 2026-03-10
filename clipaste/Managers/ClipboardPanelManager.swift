import AppKit
import SwiftUI

/// ClipboardPanelManager is responsible for managing the floating clipboard history panel.
/// It uses a borderless panel that follows the mouse's screen and presents in front of the Dock.
class ClipboardPanelManager {
    static let shared = ClipboardPanelManager()
    private static let panelLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
    
    private var panel: ClipboardPanel?
    private var eventMonitor: Any?
    
    /// Indicates whether the panel is currently visible to the user.
    private(set) var isVisible: Bool = false
    
    private init() {
        setupPanel()
    }
    
    private func setupPanel() {
        // Use a regular borderless panel so the search field can establish a normal text input session.
        let styleMask: NSWindow.StyleMask = [.borderless]
        
        let panel = ClipboardPanel(
            contentRect: .zero,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        // Ensure the panel can display full-size content and has a clear background.
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.alphaValue = 0.0 // Start invisible
        
        // Present above the Dock and move with the current Space.
        panel.level = Self.panelLevel
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        
        // Set the SwiftUI view as the content view controller
        let hostingController = NSHostingController(rootView: ClipboardMainView())
        panel.contentViewController = hostingController
        
        self.panel = panel
    }
    
    /// Toggles the visibility of the clipboard panel.
    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    /// Shows the panel at the bottom of the screen covering 100% of the screen width and 250pt in height.
    func showPanel() {
        guard !isVisible, let panel = panel else { return }
        
        let screen = screenContainingMouse() ?? NSScreen.main
        let screenFrame = screen?.frame ?? .zero
        // 面板需要容纳顶部 Header + 卡片区域 + 内边距，300pt 会导致卡片底部被裁剪，这里略微调高高度以完整展示内容。
        let panelHeight: CGFloat = 340
        
        // Start slightly below the screen edge and animate up so the panel sits in front of the Dock.
        let hiddenFrame = NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY - 20,
            width: screenFrame.width,
            height: panelHeight
        )
        
        let visibleFrameRect = NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: screenFrame.width,
            height: panelHeight
        )
        
        // Set to initial hidden state before animation starts
        panel.setFrame(hiddenFrame, display: true)
        panel.alphaValue = 0.0

        // Establish the app activation context before focusing the panel so IME session setup succeeds.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.becomeFirstResponder()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            panel.animator().setFrame(visibleFrameRect, display: true)
            panel.animator().alphaValue = 1.0
        }) { [weak self] in
            self?.isVisible = true
            self?.setupEventMonitor()
        }
    }
    
    /// Hides the clipboard panel without affecting other app windows.
    func hidePanel() {
        guard isVisible else { return }
        dismissPanelOnly()
    }

    private func dismissPanelOnly() {
        guard let panel = panel else { return }
        removeEventMonitor()
        panel.orderOut(nil)
        panel.resignKey()
        isVisible = false
    }

    private func screenContainingMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) }
    }

    private func hasOtherActiveWindows() -> Bool {
        guard let panel else { return false }

        let visibleWindows = NSApplication.shared.windows.filter { $0.isVisible }
        return visibleWindows.contains { window in
            window !== panel
        }
    }
    
    // MARK: - Event Monitoring
    
    /// Sets up a global monitor to detect clicks outside the panel when it's visible.
    private func setupEventMonitor() {
        guard eventMonitor == nil else { return }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.isVisible else { return }

            if self.hasOtherActiveWindows() {
                self.dismissPanelOnly()
            } else {
                self.hidePanel()
            }
        }
    }
    
    /// Removes the global event monitor.
    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
