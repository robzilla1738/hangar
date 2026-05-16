// Project — workspace metadata. One project per repo/folder, usually.
// Persistence lands later in this phase via GRDB; v0.1 keeps the model
// stable so SQLite can swap in transparently.

import Foundation

public struct Project: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var cwd: URL
    public var env: [String: String]
    public var defaultAgentID: String?
    public var createdAt: Date
    public var lastOpenedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        cwd: URL,
        env: [String: String] = [:],
        defaultAgentID: String? = nil,
        createdAt: Date = Date(),
        lastOpenedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.cwd = cwd
        self.env = env
        self.defaultAgentID = defaultAgentID
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
    }
}

/// In-memory project store (v0.1).
///
/// GRDB-backed SQLite persistence lands in a follow-up sub-phase; the API here
/// is stable so swapping the backing store is a one-actor change.
public actor ProjectStore {
    private var projects: [UUID: Project] = [:]

    public init() {}

    public func list() -> [Project] {
        projects.values.sorted { $0.lastOpenedAt > $1.lastOpenedAt }
    }

    public func recent(limit: Int = 10) -> [Project] {
        Array(list().prefix(limit))
    }

    @discardableResult
    public func create(name: String, cwd: URL) -> Project {
        let project = Project(name: name, cwd: cwd)
        projects[project.id] = project
        return project
    }

    public func upsert(_ project: Project) {
        projects[project.id] = project
    }

    public func delete(id: UUID) {
        projects.removeValue(forKey: id)
    }

    public func touch(id: UUID) {
        guard var project = projects[id] else { return }
        project.lastOpenedAt = Date()
        projects[id] = project
    }
}
