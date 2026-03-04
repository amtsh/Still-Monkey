//
//  Reel.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import Foundation

struct Reel: Identifiable {
    let id: UUID
    let content: Content

    init(id: UUID = UUID(), content: Content) {
        self.id = id
        self.content = content
    }

    enum Content {
        case chapterTitle(index: Int, title: String)
        case content(chapterIndex: Int, text: String)
    }

    var chapterIndex: Int {
        switch content {
        case .chapterTitle(let index, _): return index
        case .content(let index, _): return index
        }
    }
}
