//
//  AppStoreConnectConfig.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation

struct AppStoreConnectConfig: Codable {
    var issuerID: String
    var privateKeyID: String
    var privateKey: String
    
    init(issuerID: String = "", privateKeyID: String = "", privateKey: String = "") {
        self.issuerID = issuerID
        self.privateKeyID = privateKeyID
        self.privateKey = privateKey
    }
    
    var isValid: Bool {
        return !issuerID.isEmpty && !privateKeyID.isEmpty && !privateKey.isEmpty
    }
}
