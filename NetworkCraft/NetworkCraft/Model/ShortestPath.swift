//
//  ShortestPath.swift
//  NetworkCraft
//
//  Created by Adel Mansurov on 07.02.2025.
//

import Foundation
import SwiftData

//Модель для хранения данных о кратчайших путях, хранит от какого узла, к какому передается информация и путь
@Model
final class ShortestPath: Identifiable {
    var id: UUID = UUID()
    var node1: String
    var node2: String
    var path: String

    init(node1: String, node2: String, path: String) {
        self.node1 = node1
        self.node2 = node2
        self.path = path
    }
}
