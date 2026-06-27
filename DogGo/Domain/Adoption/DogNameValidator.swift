import Foundation

enum DogNameValidationError: LocalizedError, Equatable {
    case empty
    case tooLong
    case containsLineBreak

    var errorDescription: String? {
        switch self {
        case .empty:
            "给它一个名字吧。"
        case .tooLong:
            "名字最多 12 个字。"
        case .containsLineBreak:
            "名字不能换行。"
        }
    }
}

struct DogNameValidator {
    static func validated(_ input: String) throws -> String {
        let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw DogNameValidationError.empty }
        guard !name.contains(where: \.isNewline) else { throw DogNameValidationError.containsLineBreak }
        guard name.count <= 12 else { throw DogNameValidationError.tooLong }
        return name
    }
}
