import SwiftSyntax

extension SourceFileSyntax {
    /// Returns a copy of the source file with import statements sorted alphabetically.
    func sortedImports() -> SourceFileSyntax {
        var result: [CodeBlockItemSyntax] = []
        var buffer: [CodeBlockItemSyntax] = []

        func flushBuffer() {
            guard !buffer.isEmpty else { return }

            let groupLeadingTrivia = buffer.first!.leadingTrivia
            var importItems: [(CodeBlockItemSyntax, ImportDeclSyntax)] = buffer.map { item in
                let decl = item.item.as(ImportDeclSyntax.self)!
                return (item, decl)
            }

            importItems.sort { lhs, rhs in
                let name1 = lhs.1.path.description.trimmingCharacters(in: .whitespacesAndNewlines)
                let name2 = rhs.1.path.description.trimmingCharacters(in: .whitespacesAndNewlines)
                return name1.localizedCompare(name2) == .orderedAscending
            }

            for (index, pair) in importItems.enumerated() {
                var newDecl = pair.1
                let leading = index == 0 ? groupLeadingTrivia : Trivia.newlines(1)
                newDecl = newDecl
                    .with(\.leadingTrivia, leading)
                    .with(\.trailingTrivia, pair.1.trailingTrivia)
                let newItem = pair.0.with(\.item, .decl(DeclSyntax(newDecl)))
                result.append(newItem)
            }

            buffer.removeAll()
        }

        for item in statements {
            if item.item.as(ImportDeclSyntax.self) != nil {
                if buffer.isEmpty {
                    buffer.append(item)
                } else {
                    let hasBlankLine = item.leadingTrivia.contains { piece in
                        if case .newlines(let n) = piece, n >= 2 { return true }
                        return false
                    }
                    if hasBlankLine {
                        flushBuffer()
                        buffer.append(item)
                    } else {
                        buffer.append(item)
                    }
                }
            } else {
                flushBuffer()
                result.append(item)
            }
        }

        flushBuffer()

        return with(\.statements, CodeBlockItemListSyntax(result))
    }
}
