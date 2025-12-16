//
//  String+Helpers.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import Foundation

nonisolated public extension String {
    func toBase64() -> String {
        Data(self.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }
}
