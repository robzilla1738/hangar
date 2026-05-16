// NotificationCenterService — UNUserNotificationCenter wrapper that posts
// macOS notifications when a new approval lands. Action-button routing
// (Approve/Deny) lands when the AppDelegate-shaped notification responder
// is wired in Phase 11; for v0.1 we deliver the alert with a single tap-to-
// open-Hangar action and a badge count.

import Foundation
import UserNotifications

public actor NotificationCenterService {
    public static let approvalCategoryID = "HANGAR_APPROVAL"

    /// Whether to actually call UNUserNotificationCenter.
    ///
    /// False when running from `swift test` (no app bundle), true when
    /// running from a .app.
    private let enabled: Bool

    public init() {
        // The host process must be a packaged .app for UNUserNotificationCenter
        // to initialize. `swift test` runs out of /usr/bin so the bundle's
        // pathExtension is empty.
        self.enabled = Bundle.main.bundleURL.pathExtension == "app"
    }

    public func requestAuthorization() async {
        guard enabled else { return }
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Failure leaves the app working without OS notifications.
        }
        await registerCategories()
    }

    public func notifyApproval(agentName: String, prompt: String) async {
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Hangar — \(agentName) needs approval"
        content.body = String(prompt.prefix(180))
        content.categoryIdentifier = Self.approvalCategoryID
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func registerCategories() async {
        guard enabled else { return }
        let approve = UNNotificationAction(
            identifier: "HANGAR_APPROVE",
            title: "Approve",
            options: [.foreground]
        )
        let deny = UNNotificationAction(
            identifier: "HANGAR_DENY",
            title: "Deny",
            options: [.destructive]
        )
        let approveAll = UNNotificationAction(
            identifier: "HANGAR_APPROVE_ALL",
            title: "Approve all",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.approvalCategoryID,
            actions: [approve, deny, approveAll],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
