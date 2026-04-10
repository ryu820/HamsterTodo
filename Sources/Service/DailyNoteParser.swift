import Foundation
import os

enum DailyNoteParser {
    private static let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "DailyNoteParser")
    private static let datePattern = /^\d{4}-\d{2}-\d{2}\.md$/
    private static let maxFileSize = 1_000_000

    static func parseTodos(from markdown: String) -> [TodoItem] {
        let lines = markdown.components(separatedBy: .newlines)
        var inTodoSection = false
        var items: [TodoItem] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("## ") {
                if trimmed == Strings.Parser.todoSectionHeading {
                    inTodoSection = true
                    continue
                } else if inTodoSection {
                    break
                }
            }

            guard inTodoSection else { continue }

            if trimmed.hasPrefix("- [ ] ") {
                let text = String(trimmed.dropFirst(6))
                items.append(TodoItem(text: text, isCompleted: false))
            } else if trimmed.hasPrefix("- [x] ") {
                let text = String(trimmed.dropFirst(6))
                items.append(TodoItem(text: text, isCompleted: true))
            }
        }

        return items
    }

    static func findLatestNote(in directoryPath: String) -> String? {
        let fm = FileManager.default
        do {
            let files = try fm.contentsOfDirectory(atPath: directoryPath)
            let mdFiles = files
                .filter { (try? datePattern.wholeMatch(in: $0)) != nil }
                .sorted()
            guard let latest = mdFiles.last else { return nil }
            return (directoryPath as NSString).appendingPathComponent(latest)
        } catch {
            logger.error("Failed to read directory \(directoryPath): \(error.localizedDescription)")
            return nil
        }
    }

    static func loadTodos(from directoryPath: String) -> [TodoItem] {
        guard let notePath = findLatestNote(in: directoryPath) else { return [] }

        let fm = FileManager.default
        do {
            let attrs = try fm.attributesOfItem(atPath: notePath)
            if let size = attrs[.size] as? Int, size > maxFileSize {
                logger.warning("Note file too large (\(size) bytes), skipping")
                return []
            }
        } catch {
            logger.error("Failed to read file attributes: \(error.localizedDescription)")
            return []
        }

        do {
            let content = try String(contentsOfFile: notePath, encoding: .utf8)
            return parseTodos(from: content)
        } catch {
            logger.error("Failed to read note file: \(error.localizedDescription)")
            return []
        }
    }

    static func latestNoteDate(from directoryPath: String) -> String? {
        guard let notePath = findLatestNote(in: directoryPath) else { return nil }
        let filename = (notePath as NSString).lastPathComponent
        return filename.replacingOccurrences(of: ".md", with: "")
    }
}
