import Foundation
import SwiftData

//Модель для хранения данных о канале, связывающего два узла. Поле dataVolume (поток) и channelType(тип канала) являются необязательными, тк их дополняем в процессе работы приложения.
@Model
final class Channel: Identifiable {
    var id: UUID = UUID()
    var node1: String
    var node2: String
    var dataVolume: Double?
    var packageVolume: Double
    var channelType: ChannelType?

    init(node1: String, node2: String, dataVolume: Double? = nil, packageVolume: Double = 128,  channelType: ChannelType? = nil) {
        self.node1 = node1
        self.node2 = node2
        self.dataVolume = dataVolume
        self.packageVolume = packageVolume
        self.channelType = channelType
    }
}
