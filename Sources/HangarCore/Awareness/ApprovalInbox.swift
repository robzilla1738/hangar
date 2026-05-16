// ApprovalInbox — single source of truth for pending agent approvals
// across every pane and window. Listening to `items` gives an always-
// current list; responding to an item routes the user's choice back
// to the originating pane via the provided sink.

import Foundation

public struct ApprovalItem: Identifiable, Sendable, Equatable {
    public enum State: Sendable, Equatable {
        case pending
        case approved
        case denied
        case approvedAll
    }

    public let id: UUID
    public let paneID: UUID
    public let agentID: AgentProfileID
    public let prompt: String
    public let detectedAt: Date
    public var state: State

    public init(
        id: UUID = UUID(),
        paneID: UUID,
        agentID: AgentProfileID,
        prompt: String,
        detectedAt: Date = Date(),
        state: State = .pending
    ) {
        self.id = id
        self.paneID = paneID
        self.agentID = agentID
        self.prompt = prompt
        self.detectedAt = detectedAt
        self.state = state
    }
}

public enum ApprovalAction: Sendable, Equatable {
    case approve
    case deny
    case approveAll
}

/// Closure that writes a literal byte sequence back into a pane's PTY.
public typealias PaneInputSink = @Sendable (UUID, String) -> Void

public actor ApprovalInbox {
    public private(set) var items: [ApprovalItem] = []
    public let updates: AsyncStream<[ApprovalItem]>
    private let updatesContinuation: AsyncStream<[ApprovalItem]>.Continuation
    private let inputSink: PaneInputSink

    public init(inputSink: @escaping PaneInputSink = { _, _ in }) {
        let (stream, continuation) = AsyncStream<[ApprovalItem]>.makeStream()
        self.updates = stream
        self.updatesContinuation = continuation
        self.inputSink = inputSink
        continuation.yield([])
    }

    deinit {
        updatesContinuation.finish()
    }

    public func add(_ item: ApprovalItem) {
        items.append(item)
        updatesContinuation.yield(items)
    }

    public func respond(itemID: UUID, action: ApprovalAction) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].state = stateFor(action)
        let item = items[index]
        let response: String
        switch action {
        case .approve: response = "y\n"
        case .deny: response = "n\n"
        case .approveAll: response = "a\n"
        }
        inputSink(item.paneID, response)
        updatesContinuation.yield(items)
    }

    public func pendingCount() -> Int {
        items.filter { $0.state == .pending }.count
    }

    public func clearResolved() {
        items.removeAll { $0.state != .pending }
        updatesContinuation.yield(items)
    }

    private func stateFor(_ action: ApprovalAction) -> ApprovalItem.State {
        switch action {
        case .approve: return .approved
        case .deny: return .denied
        case .approveAll: return .approvedAll
        }
    }
}
