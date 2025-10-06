//
//  AppStatus.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//  Copyright © 2025 Ideas Form. All rights reserved.
//

import SwiftUI
import AppStoreConnect_Swift_SDK

typealias AppStatus = AppStoreConnect_Swift_SDK.AppStoreVersionState

extension AppStatus {
    var systemImage: String {
        switch self {
        case .accepted:
            return "checkmark.circle.fill"
        case .developerRemovedFromSale:
            return "minus.circle.fill"
        case .developerRejected:
            return "xmark.circle.fill"
        case .inReview:
            return "magnifyingglass.circle.fill"
        case .invalidBinary:
            return "exclamationmark.triangle.fill"
        case .metadataRejected:
            return "xmark.circle.fill"
        case .pendingAppleRelease:
            return "clock.circle.fill"
        case .pendingContract:
            return "doc.text.fill"
        case .pendingDeveloperRelease:
            return "person.circle.fill"
        case .prepareForSubmission:
            return "paperplane.circle.fill"
        case .preorderReadyForSale:
            return "cart.circle.fill"
        case .processingForAppStore:
            return "gearshape.circle.fill"
        case .readyForReview:
            return "eye.circle.fill"
        case .readyForSale:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        case .removedFromSale:
            return "minus.circle.fill"
        case .waitingForExportCompliance:
            return "shield.circle.fill"
        case .waitingForReview:
            return "clock.circle.fill"
        case .replacedWithNewVersion:
            return "arrow.clockwise.circle.fill"
        case .notApplicable:
            return "questionmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .accepted:
            return "Accepted"
        case .developerRemovedFromSale:
            return "Removed from Sale by Developer"
        case .developerRejected:
            return "Rejected by Developer"
        case .inReview:
            return "In Review"
        case .invalidBinary:
            return "Invalid Binary"
        case .metadataRejected:
            return "Metadata Rejected"
        case .pendingAppleRelease:
            return "Pending Apple Release"
        case .pendingContract:
            return "Pending Contract"
        case .pendingDeveloperRelease:
            return "Pending Developer Release"
        case .prepareForSubmission:
            return "Prepare for Submission"
        case .preorderReadyForSale:
            return "Preorder Ready for Sale"
        case .processingForAppStore:
            return "Processing for App Store"
        case .readyForReview:
            return "Ready for Review"
        case .readyForSale:
            return "Ready for Sale"
        case .rejected:
            return "Rejected"
        case .removedFromSale:
            return "Removed from Sale"
        case .waitingForExportCompliance:
            return "Waiting for Export Compliance"
        case .waitingForReview:
            return "Waiting for Review"
        case .replacedWithNewVersion:
            return "Replaced with New Version"
        case .notApplicable:
            return "Not Applicable"
        }
    }
    
    var color: Color {
        switch self {
        case .accepted, .readyForSale:
            return .green
        case .developerRejected, .metadataRejected, .rejected, .invalidBinary:
            return .red
        case .developerRemovedFromSale, .removedFromSale:
            return .orange
        case .inReview, .readyForReview, .waitingForReview:
            return .blue
        case .pendingAppleRelease, .pendingContract, .pendingDeveloperRelease, .waitingForExportCompliance:
            return .yellow
        case .processingForAppStore, .prepareForSubmission:
            return .purple
        case .preorderReadyForSale:
            return .mint
        case .replacedWithNewVersion:
            return .cyan
        case .notApplicable:
            return .gray
        }
    }
}

extension AppStatus: Comparable {
    public static func < (lhs: AppStoreConnect_Swift_SDK.AppStoreVersionState, rhs: AppStoreConnect_Swift_SDK.AppStoreVersionState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
