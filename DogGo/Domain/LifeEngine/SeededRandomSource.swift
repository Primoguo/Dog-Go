import Foundation

protocol RandomSource {
    mutating func nextUInt64() -> UInt64
}

struct SplitMix64RandomSource: RandomSource {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextUInt64() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

enum StableEventSeed {
    static func make(dogID: UUID, windowStart: Date, slot: Int) -> UInt64 {
        let canonical = "\(dogID.uuidString.lowercased())|\(Int64(windowStart.timeIntervalSince1970))|\(slot)"
        return fnv1a64(bytes: canonical.utf8)
    }

    private static func fnv1a64<Bytes: Sequence>(bytes: Bytes) -> UInt64 where Bytes.Element == UInt8 {
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in bytes {
            hash ^= UInt64(byte)
            hash &*= 0x100000001B3
        }
        return hash
    }
}
