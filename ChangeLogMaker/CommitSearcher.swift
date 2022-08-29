//
//  CommitSearcher.swift
//  ChangeLogMaker
//
//  Created by Yaroslav on 20.07.2022.
//

import Foundation

class CommitSearcher {
    private let path = URL(string: CommandLine.arguments[0])?.deletingLastPathComponent()
    
    func run() {
        if gitExists() {
            let title = MarkdownHeader(title: "[Unreleased]", level: .h2, style: .atx, close: false)
            let subtitle = MarkdownHeader(title: "☑️ Added:", level: .h1, style: .atx, close: false)
            let list = MarkdownList(items: getCommitsMessages(filter: "\\[VID.*\\]"))
            print(list.markdown)
            writeChangelog(markdown: [title,subtitle,list])
        } else {
            print("Error: can't find git repository\n")
        }
    }
}

private extension CommitSearcher {
    
    func shell(_ command: String) -> String {
        guard let path = path else { return "Can't get path" }
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "cd \(path)&&\(command)"]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }

    func gitExists() -> Bool {
        return Bool(shell("git rev-parse --is-inside-work-tree").trimmingCharacters(in: .newlines)) ?? false
    }

    func getCommitsMessages(filter: String) -> [String] {
        shell("""
            git log -i --grep="\\[VID.*\\]" --pretty=%s $(git describe --tags --abbrev=0 @^)..@
        """)
            .components(separatedBy: "\n")
            .filter({ !$0.isEmpty })
    }

    func writeChangelog(markdown: MarkdownConvertible) {
        guard let path = path?.path else { return print("Can't get path") }
        do {
            try MarkdownFile.init(filename: "CHANHELOG", basePath: path, content: markdown).write()
            print("CHANGELOG successfully created")
        } catch {
            print(error)
        }

    }

}
