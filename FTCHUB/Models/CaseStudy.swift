//
//  CaseStudy.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

// MARK: - Case Study
struct CaseStudy: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: ResourceCategory
    let difficulty: DifficultyLevel
    let sections: [CaseStudySection]
    let keyTakeaways: [String]
    let relatedConcepts: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: ResourceCategory,
        difficulty: DifficultyLevel = .intermediate,
        sections: [CaseStudySection] = [],
        keyTakeaways: [String] = [],
        relatedConcepts: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.sections = sections
        self.keyTakeaways = keyTakeaways
        self.relatedConcepts = relatedConcepts
    }
}

// MARK: - Case Study Section
struct CaseStudySection: Identifiable {
    let id: UUID
    let title: String
    let content: String
    let imageName: String?
    let codeExample: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        imageName: String? = nil,
        codeExample: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.imageName = imageName
        self.codeExample = codeExample
    }
}

