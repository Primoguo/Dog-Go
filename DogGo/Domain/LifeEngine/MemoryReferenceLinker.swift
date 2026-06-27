import Foundation

struct MemoryReferenceLinker {
    func link(
        eventID: UUID,
        requiredTags: [String],
        memories: [MemoryRecord]
    ) -> [String] {
        guard !requiredTags.isEmpty else { return [] }
        let required = Set(requiredTags)
        let matching = memories.filter { !required.isDisjoint(with: Set($0.tags)) }
        matching.forEach { $0.addReference(from: eventID) }
        return Array(required.intersection(matching.flatMap(\.tags))).sorted()
    }
}
