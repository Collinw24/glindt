import Testing
import Foundation
@testable import GlindtIOS

@Suite struct GlindtIOSSmokeTests {
    @Test func packageLinksCorrectly() {
        // Smoke test — ensures GlindtIOS links in an Apple-target build.
        let reachable = NetworkReachabilityService.shared
        #expect(reachable.isSatisfied == true || reachable.isSatisfied == false)
    }
}
