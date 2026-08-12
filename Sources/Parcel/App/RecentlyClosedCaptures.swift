struct RecentlyClosedCaptures {
    private let limit: Int
    private var captures: [Capture] = []

    init(limit: Int = 12) {
        self.limit = max(1, limit)
    }

    var count: Int { captures.count }

    mutating func push(_ capture: Capture) {
        captures.append(capture)
        if captures.count > limit {
            captures.removeFirst(captures.count - limit)
        }
    }

    mutating func restore() -> Capture? {
        captures.popLast()
    }
}
