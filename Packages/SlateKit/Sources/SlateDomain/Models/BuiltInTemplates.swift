import Foundation

package enum BuiltInTemplates {
    package static let bodies: [String: String] = [
        "note": "",
        "task": """
        ## Context

        {{cursor}}

        ## Plan

        - [ ] 

        ## Findings

        ## Links

        ## Questions

        ## Log

        """,
        "daily": """
        ## Log

        {{cursor}}

        ## Notes

        """,
        "meeting": """
        **Attendees:** {{cursor}}

        ## Agenda

        ## Decisions

        ## Actions

        - [ ] 

        """,
        "snippet": """
        ```{{language}}
        {{cursor}}
        ```

        """,
    ]
}
