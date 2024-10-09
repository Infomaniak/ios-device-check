@testable import InfomaniakDeviceCheck
import XCTest

final class InfomaniakDeviceCheckTests: XCTestCase {
    func testAttestationToken() async throws {
        let attestation = try await InfomaniakDeviceCheck().generateAttestationFor(
            targetUrl: URL(string: "https://login.infomaniak.com")!,
            bundleId: "com.infomaniak.mail"
        )
    }
}
