import ArgumentParser
import Foundation

struct TaskCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "task",
        abstract: "Start a task in a project, change its status, or add to its log.",
        subcommands: [TaskNewCommand.self, TaskStatusCommand.self, TaskLogCommand.self]
    )
}
