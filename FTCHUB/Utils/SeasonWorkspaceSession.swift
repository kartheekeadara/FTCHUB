//
//  SeasonWorkspaceSession.swift
//  FTCHUB
//
//  Session object that owns Season workspace stores (sponsors, notebook; wishlist/mentor remain for future use).
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SeasonWorkspaceSession: ObservableObject {
    let wishlistStore = PartsWishlistStore()
    let sponsorStore = SponsorPipelineStore()
    let mentorStore = MentorLedgerStore()
    let notebookStore = EngineeringNotebookStore()
    
    private var teamId: UUID?
    
    func updateTeamContext(_ id: UUID?) {
        guard id != teamId else { return }
        teamId = id
        wishlistStore.updateTeamContext(id)
        sponsorStore.updateTeamContext(id)
        mentorStore.updateTeamContext(id)
        notebookStore.updateTeamContext(id)
    }
}
