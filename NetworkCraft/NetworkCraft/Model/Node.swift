import Foundation
import SwiftData

//Модель для хранения данных об узле, название, координаты (по x y).
@Model
final class Node: Identifiable {
    var id: UUID = UUID()
    var name: String
    var x: Double
    var y: Double

    init(name: String, x: Double, y: Double) {
        self.name = name
        self.x = x
        self.y = y
    }
}
