import Foundation

package struct SearchQuery: Hashable, Sendable {
    package var terms: [String]
    package var phrases: [String]
    package var excludedTerms: [String]
    package var filters: [SearchFilter]
    package var excludedFilters: [SearchFilter]

    package init(terms: [String] = [], phrases: [String] = [], excludedTerms: [String] = [], filters: [SearchFilter] = [], excludedFilters: [SearchFilter] = []) {
        self.terms = terms
        self.phrases = phrases
        self.excludedTerms = excludedTerms
        self.filters = filters
        self.excludedFilters = excludedFilters
    }

    package var hasText: Bool {
        terms.isEmpty == false || phrases.isEmpty == false
    }

    package var isEmpty: Bool {
        hasText == false && excludedTerms.isEmpty && filters.isEmpty && excludedFilters.isEmpty
    }

    package var words: [String] {
        terms + phrases
    }
}
