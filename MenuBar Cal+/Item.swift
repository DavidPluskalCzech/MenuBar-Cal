//
//  Item.swift
//  MenuBar Cal+
//
//  Created by David Pluskal on 13.11.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
