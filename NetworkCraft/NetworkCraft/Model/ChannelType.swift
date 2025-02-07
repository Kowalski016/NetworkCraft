import Foundation
import SwiftData
//Модель для хранения данных о типе канала, содержащая название, скорость и цену.
@Model
final class ChannelType: Identifiable {
    var id: UUID = UUID()
    var name: String
    var speed: Double
    var price: Double

    init(name: String, speed: Double, price: Double) {
        self.name = name
        self.speed = speed
        self.price = price
    }
}
