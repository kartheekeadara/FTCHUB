//
//  EngineeringNotebookExport.swift
//  FTCHUB
//
//  PDF export for engineering notebook + run log.
//

import Foundation
#if canImport(UIKit)
import UIKit
import CoreText
#endif

enum EngineeringNotebookExport {
#if canImport(UIKit)
    static func pdfData(
        teamNumber: String?,
        notes: [EngineeringNote],
        runs: [RunLogEntry]
    ) -> Data? {
        let attributed = pdfAttributedContent(
            teamNumber: teamNumber,
            notes: notes,
            runs: runs
        )
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "FTC HUB",
            kCGPDFContextTitle as String: "Engineering Notebook"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
        var range = CFRange(location: 0, length: 0)
        return renderer.pdfData { ctx in
            let cgContext = ctx.cgContext
            while range.location < attributed.length {
                ctx.beginPage()
                cgContext.saveGState()

                // Core Text uses a bottom-left origin; flip the PDF context to match UIKit.
                cgContext.translateBy(x: 0, y: pageRect.height)
                cgContext.scaleBy(x: 1.0, y: -1.0)

                let textRect = pageRect.insetBy(dx: 48, dy: 56)
                let flippedTextRect = CGRect(
                    x: textRect.origin.x,
                    y: pageRect.height - textRect.origin.y - textRect.height,
                    width: textRect.width,
                    height: textRect.height
                )
                let path = CGPath(rect: flippedTextRect, transform: nil)
                range.length = attributed.length - range.location
                let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
                CTFrameDraw(frame, cgContext)

                let visible = CTFrameGetVisibleStringRange(frame)
                cgContext.restoreGState()
                if visible.length == 0 { break }
                range.location += visible.length
            }
        }
    }
    
    private static func pdfAttributedContent(
        teamNumber: String?,
        notes: [EngineeringNote],
        runs: [RunLogEntry]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.lineSpacing = 3
        bodyStyle.paragraphSpacing = 6
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.black,
            .paragraphStyle: bodyStyle
        ]
        let sectionAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black,
            .paragraphStyle: bodyStyle
        ]
        let entryTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black,
            .paragraphStyle: bodyStyle
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: bodyStyle
        ]
        let metaAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray,
            .paragraphStyle: bodyStyle
        ]
        
        result.append(NSAttributedString(string: "Engineering Notebook\n", attributes: titleAttrs))
        if let num = teamNumber, !num.isEmpty {
            result.append(NSAttributedString(string: "Team \(num)\n", attributes: metaAttrs))
        }
        result.append(NSAttributedString(
            string: "Generated \(Date().formatted(date: .complete, time: .shortened))\n\n",
            attributes: metaAttrs
        ))
        result.append(NSAttributedString(
            string: "Student-authored entries; mentor guidance only. Not an official FIRST portfolio.\n\n",
            attributes: metaAttrs
        ))
        
        let sortedNotes = notes.sorted { $0.createdAt < $1.createdAt }
        result.append(NSAttributedString(string: "Notebook entries\n", attributes: sectionAttrs))
        if sortedNotes.isEmpty {
            result.append(NSAttributedString(string: "No entries yet.\n\n", attributes: bodyAttrs))
        }
        for note in sortedNotes {
            result.append(NSAttributedString(string: "\(note.title)\n", attributes: entryTitleAttrs))
            var meta = note.createdAt.formatted(date: .complete, time: .shortened)
            meta += " · \(note.entryKind.displayName)"
            if let phase = note.designPhase { meta += " · \(phase.displayName)" }
            if let author = note.authorStudent, !author.isEmpty { meta += " · \(author)" }
            result.append(NSAttributedString(string: "\(meta)\n", attributes: metaAttrs))
            if let subsystem = note.subsystem, !subsystem.isEmpty {
                result.append(NSAttributedString(string: "Subsystem: \(subsystem)\n", attributes: bodyAttrs))
            }
            if !note.body.isEmpty {
                result.append(NSAttributedString(string: "\(note.body)\n", attributes: bodyAttrs))
            }
            if let attachments = note.attachmentsNote, !attachments.isEmpty {
                result.append(NSAttributedString(string: "Attachments: \(attachments)\n", attributes: bodyAttrs))
            }
            if let nextStep = note.nextStep, !nextStep.isEmpty {
                result.append(NSAttributedString(string: "Next step: \(nextStep)\n", attributes: bodyAttrs))
            }
            if let linkedId = note.linkedRunLogId,
               let run = runs.first(where: { $0.id == linkedId }) {
                result.append(NSAttributedString(
                    string: "Linked test: \(run.hypothesis) → \(run.result)\n",
                    attributes: bodyAttrs
                ))
            }
            result.append(NSAttributedString(string: "\n", attributes: bodyAttrs))
        }
        
        let sortedRuns = runs.sorted { $0.createdAt < $1.createdAt }
        result.append(NSAttributedString(string: "Run log\n", attributes: sectionAttrs))
        if sortedRuns.isEmpty {
            result.append(NSAttributedString(string: "No test runs logged.\n", attributes: bodyAttrs))
        }
        for run in sortedRuns {
            result.append(NSAttributedString(
                string: "\(run.createdAt.formatted(date: .abbreviated, time: .shortened)) — \(run.hypothesis)\n",
                attributes: entryTitleAttrs
            ))
            if let setup = run.setup, !setup.isEmpty {
                result.append(NSAttributedString(string: "Setup: \(setup)\n", attributes: bodyAttrs))
            }
            result.append(NSAttributedString(string: "Result: \(run.result)\n", attributes: bodyAttrs))
            if let passFail = run.passFail {
                result.append(NSAttributedString(
                    string: "Pass/fail: \(passFail ? "Pass" : "Fail")\n",
                    attributes: bodyAttrs
                ))
            }
            if let nextAction = run.nextAction, !nextAction.isEmpty {
                result.append(NSAttributedString(string: "Next: \(nextAction)\n", attributes: bodyAttrs))
            }
            result.append(NSAttributedString(string: "\n", attributes: bodyAttrs))
        }
        
        return result
    }
#else
    static func pdfData(teamNumber: String?, notes: [EngineeringNote], runs: [RunLogEntry]) -> Data? { nil }
#endif
}
