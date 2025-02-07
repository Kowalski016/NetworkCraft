import Foundation
import SwiftData

// Модель для хранения матрицы нагрузки, каждая запись хранит название узла-отправителя, узла-получателя и объём передаваемых данных.
@Model
final class LoadMatrix: Identifiable {
    var id: UUID = UUID()
    var node1: String
    var node2: String
    var volume: Double

    init(node1: String, node2: String, volume: Double) {
        self.node1 = node1
        self.node2 = node2
        self.volume = volume
    }
}
