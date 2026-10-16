import Foundation
import SlateDomain

struct NoopRecorder: CommandRecording {
    func record(_ record: CommandRecord) {}
}
