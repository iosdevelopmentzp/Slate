import Foundation
import SlateDomain

struct MockSystemChecks: SystemChecking {
    func checks() async -> [DoctorCheck] {
        [
            DoctorCheck(id: "vault", title: "Notes folder", isOK: true, detail: "~/Documents/Slate"),
            DoctorCheck(id: "git", title: "Git", isOK: true, detail: "git version 2.50.1"),
            DoctorCheck(id: "index", title: "Search data", isOK: true, detail: "4 MB"),
        ]
    }
}
