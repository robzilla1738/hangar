// AwarenessAdapter — thin Sendable bridge from PaneViewModel into the
// app-level ApprovalInbox + NotificationCenterService. Injected by AppState
// via WindowViewModel.bindAwareness so the kit modules stay decoupled from
// the app target.

import Foundation

public final class AwarenessAdapter: @unchecked Sendable {
    public let approvalInbox: ApprovalInbox
    public let notificationService: NotificationCenterService

    public init(
        approvalInbox: ApprovalInbox,
        notificationService: NotificationCenterService = NotificationCenterService()
    ) {
        self.approvalInbox = approvalInbox
        self.notificationService = notificationService
    }

    /// Forward an approval prompt to the inbox + macOS notification center.
    public func report(_ item: ApprovalItem, agentDisplayName: String?) {
        let inbox = approvalInbox
        let center = notificationService
        Task {
            await inbox.add(item)
            await center.notifyApproval(
                agentName: agentDisplayName ?? "Hangar agent",
                prompt: item.prompt
            )
        }
    }
}
