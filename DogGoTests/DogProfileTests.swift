import XCTest
@testable import DogGo

final class DogProfileTests: XCTestCase {
    func testDefaultBreedIsShibaInu() {
        let dog = DogProfile(name: "栗子")

        XCTAssertEqual(dog.name, "栗子")
        XCTAssertEqual(dog.breed, "shibaInu")
    }
}
