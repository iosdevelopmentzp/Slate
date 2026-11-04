import Foundation

package enum BuiltInTemplates {
    package static let bodies: [String: String] = [
        "note": "",
        "task": """
        ## Overview

        {{cursor}}

        ## Status

        ## Key facts

        ## Questions

        ## Plan

        - [ ] 

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
