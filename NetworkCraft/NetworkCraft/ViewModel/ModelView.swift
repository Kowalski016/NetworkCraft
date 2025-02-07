import SwiftUI
import SwiftData

// MARK: - Главное меню
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Node", destination: NodeMenuView())
                NavigationLink("Channel", destination: ChannelMenuView())
                NavigationLink("Channel Type", destination: ChannelTypeMenuView())
                NavigationLink("Charts", destination: ChartsView())
                NavigationLink("Load Matrix", destination: LoadMatrixView())
                NavigationLink("Shortest Path", destination: ShortestPathMenuView())
                NavigationLink("Full Connected Graph", destination: FullConnectedGraphView())
            }
            .navigationTitle("Main Menu")
        }
    }
}

// MARK: - Меню работы с узлами
struct NodeMenuView: View {
    @State private var showAddNodeSheet = false
    @State private var showDeleteNodeSheet = false
    @State private var showTableNodeSheet = false

    var body: some View {
        List {
            Button("Add Node") { showAddNodeSheet = true }
                .sheet(isPresented: $showAddNodeSheet) { AddNodeView() }
            Button("Delete Node") { showDeleteNodeSheet = true }
                .sheet(isPresented: $showDeleteNodeSheet) { DeleteNodeView() }
            Button("Table Node") { showTableNodeSheet = true }
                .sheet(isPresented: $showTableNodeSheet) { TableNodeView() }
        }
        .navigationTitle("Nodes")
    }
}

// MARK: - Представление для добавления нового узла
struct AddNodeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var nodeName = ""
    @State private var xCoordinate = ""
    @State private var yCoordinate = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Введите параметры узла")) {
                    TextField("Название", text: $nodeName)
                    TextField("Координата X", text: $xCoordinate)
                        .keyboardType(.decimalPad)
                    TextField("Координата Y", text: $yCoordinate)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Node")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        guard let x = Double(xCoordinate),
                              let y = Double(yCoordinate),
                              !nodeName.isEmpty else { return }
                        let newNode = Node(name: nodeName, x: x, y: y)
                        context.insert(newNode)
                        do { try context.save() }
                        catch { print("Ошибка сохранения узла: \(error.localizedDescription)") }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Представление для удаления узла
struct DeleteNodeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var nodeNameToDelete = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Введите название узла для удаления")) {
                    TextField("Название", text: $nodeNameToDelete)
                }
            }
            .navigationTitle("Delete Node")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Удалить") {
                        let nodes = fetchNodes(withName: nodeNameToDelete)
                        for node in nodes { context.delete(node) }
                        do { try context.save() }
                        catch { print("Ошибка удаления узла: \(error.localizedDescription)") }
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func fetchNodes(withName name: String) -> [Node] {
        let request = FetchDescriptor<Node>(predicate: #Predicate { (node: Node) in
            node.name == name
        })
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - Представление для отображения узлов
struct TableNodeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Node.name, order: .forward) private var nodes: [Node]

    var body: some View {
        NavigationStack {
            List {
                ForEach(nodes) { node in
                    HStack {
                        Text(node.name)
                        Spacer()
                        Text("(\(node.x, specifier: "%.2f"), \(node.y, specifier: "%.2f"))")
                    }
                }
            }
            .navigationTitle("Nodes Table")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Закрыть") { dismiss() } }
            }
        }
    }
}

// MARK: - Меню работы с каналами
struct ChannelMenuView: View {
    @Environment(\.modelContext) private var context
    @State private var showAddChannelSheet = false
    @State private var showDeleteChannelSheet = false
    @State private var showTableChannelSheet = false
    @State private var showEnterPackageSheet = false
    @State private var showNetworkDelaySheet = false
    @State private var showAlert = false
    @State private var alertMessage: String = ""
    @State private var showAverageDelayAlert = false

    var body: some View {
        List {
            Button("Add Channels") { showAddChannelSheet = true }
                .sheet(isPresented: $showAddChannelSheet) { AddChannelView() }

            Button("Delete Channels") { showDeleteChannelSheet = true }
                .sheet(isPresented: $showDeleteChannelSheet) { DeleteChannelView() }

            Button("Table Channels") { showTableChannelSheet = true }
                .sheet(isPresented: $showTableChannelSheet) { TableChannelView() }

            Button("Enter Package") { showEnterPackageSheet = true }
                .sheet(isPresented: $showEnterPackageSheet) { EnterPackageView() }

            Button("Choose Type Channel") {
                chooseTypeChannel()
            }

            Button("Network Delay") { showNetworkDelaySheet = true }
                .sheet(isPresented: $showNetworkDelaySheet) { NetworkDelayView() }
            
            
            Button("Average Delay") {
                calculateAverageDelay()
            }
        }
        .navigationTitle("Channels")
        .alert("Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    /// Функция для выбора наименьшего подходящего типа канала для каждого канала.
    private func chooseTypeChannel() {
        // Получаем все типы каналов
        guard let channelTypes = try? context.fetch(FetchDescriptor<ChannelType>()) else {
            alertMessage = "Не удалось получить типы каналов."
            showAlert = true
            return
        }
        // Получаем все каналы
        guard let channels = try? context.fetch(FetchDescriptor<Channel>()) else {
            alertMessage = "Не удалось получить каналы."
            showAlert = true
            return
        }
        
        var updatedCount = 0
        for channel in channels {
            // Если dataVolume не задан, пропускаем
            guard let dataVolume = channel.dataVolume else { continue }
            // Подбираем все типы, у которых скорость больше dataVolume
            let suitableTypes = channelTypes.filter { $0.speed > dataVolume }
            if suitableTypes.isEmpty { continue }
            // Выбираем тип с минимальной скоростью из подходящих
            if let chosenType = suitableTypes.min(by: { $0.speed < $1.speed }) {
                channel.channelType = chosenType
                updatedCount += 1
            }
        }
        
        do {
            try context.save()
            alertMessage = "Тип канала выбран для \(updatedCount) каналов."
            showAlert = true
        } catch {
            alertMessage = "Ошибка сохранения типа канала: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    /// Функция для расчёта средней задержки по всем каналам (каналы с задержкой равной 0 не учитываются)
    private func calculateAverageDelay() {
        // Получаем все каналы
        guard let channels = try? context.fetch(FetchDescriptor<Channel>()) else {
            alertMessage = "Не удалось получить каналы."
            showAlert = true
            return
        }
        var totalDelay: Double = 0
        var count: Int = 0
        
        for channel in channels {
            // Если dataVolume не задан или равен 0, пропускаем канал
            guard let dataVolume = channel.dataVolume, dataVolume > 0 else { continue }
            guard let type = channel.channelType else { continue }
            let availableSpeed = type.speed - dataVolume
            if availableSpeed <= 0 { continue }
            let delay = channel.packageVolume / availableSpeed
            // Если delay равна 0, не учитываем её
            if delay == 0 { continue }
            totalDelay += delay
            count += 1
        }
        
        if count == 0 {
            alertMessage = "Нет каналов с ненулевой задержкой для расчёта."
        } else {
            let avgDelay = totalDelay / Double(count)
            alertMessage = String(format: "Средняя задержка: %.2f", avgDelay)
        }

        showAlert = true
    }
}

// MARK: - Представление для обновления размера пакета
struct EnterPackageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    // Получаем список каналов для выбора
    @Query(sort: \Channel.node1, order: .forward) private var channels: [Channel]
    
    @State private var selectedChannelId: UUID?
    @State private var packageText: String = "128"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Выберите канал")) {
                    Picker("Канал", selection: $selectedChannelId) {
                        Text("Выберите канал").tag(Optional<UUID>(nil))
                        ForEach(channels) { channel in
                            Text("\(channel.node1) - \(channel.node2)")
                                .tag(Optional(channel.id))
                        }
                    }
                }
                Section(header: Text("Объём пакета")) {
                    TextField("Введите объём пакета", text: $packageText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Enter Package")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") { savePackage() }
                }
            }
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func savePackage() {
        guard let selectedId = selectedChannelId,
              let newPackage = Double(packageText) else {
            alertMessage = "Пожалуйста, выберите канал и введите корректный объём."
            showAlert = true
            return
        }
        if let channel = channels.first(where: { $0.id == selectedId }) {
            channel.packageVolume = newPackage
            do {
                try context.save()
                dismiss()
            } catch {
                alertMessage = "Ошибка сохранения: \(error.localizedDescription)"
                showAlert = true
            }
        } else {
            alertMessage = "Выбранный канал не найден."
            showAlert = true
        }
    }
}

// MARK: - Представление для расчёта задержки по каналам
struct NetworkDelayView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Channel.node1, order: .forward) private var channels: [Channel]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(channels) { channel in
                    HStack {
                        Text("\(channel.node1) - \(channel.node2)")
                        Spacer()
                        // Если dataVolume равен 0, то задержка = 0
                        if let type = channel.channelType, let dataVolume = channel.dataVolume {
                            if dataVolume == 0 {
                                Text("Задержка: 0")
                            } else if (type.speed - dataVolume) > 0 {
                                let delay = channel.packageVolume / (type.speed - dataVolume)
                                Text("Задержка: \(delay, specifier: "%.2f")")
                            } else {
                                Text("Задержка: N/A")
                            }
                        } else {
                            Text("Задержка: N/A")
                        }
                    }
                }
            }
            .navigationTitle("Network Delay")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Представление для добавления нового канала
struct AddChannelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var node1Name = ""
    @State private var node2Name = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Введите названия узлов для соединения")) {
                    TextField("Первый узел", text: $node1Name)
                    TextField("Второй узел", text: $node2Name)
                }
            }
            .navigationTitle("Add Channel")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        let firstNodeExists = nodeExists(withName: node1Name)
                        let secondNodeExists = nodeExists(withName: node2Name)
                        
                        if !firstNodeExists || !secondNodeExists {
                            alertMessage = "Один или оба узла не найдены"
                            showAlert = true
                            return
                        }
                        
                        let newChannel = Channel(node1: node1Name, node2: node2Name)
                        context.insert(newChannel)
                        do { try context.save() }
                        catch { print("Ошибка сохранения канала: \(error.localizedDescription)") }
                        dismiss()
                    }
                }
            }
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text(alertMessage) }
        }
    }
    
    private func nodeExists(withName name: String) -> Bool {
        let request = FetchDescriptor<Node>(predicate: #Predicate { (node: Node) in
            node.name == name
        })
        let result = (try? context.fetch(request)) ?? []
        return !result.isEmpty
    }
}

// MARK: - Представление для удаления канала
struct DeleteChannelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var node1Name = ""
    @State private var node2Name = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Введите названия узлов между которыми удалить канал")) {
                    TextField("Первый узел", text: $node1Name)
                    TextField("Второй узел", text: $node2Name)
                }
            }
            .navigationTitle("Delete Channel")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Удалить") {
                        let request = FetchDescriptor<Channel>(predicate: #Predicate { (channel: Channel) in
                            (channel.node1 == node1Name && channel.node2 == node2Name) ||
                            (channel.node1 == node2Name && channel.node2 == node1Name)
                        })
                        let channels = (try? context.fetch(request)) ?? []
                        
                        if channels.isEmpty {
                            alertMessage = "Канал между указанными узлами не найден"
                            showAlert = true
                            return
                        }
                        
                        for channel in channels { context.delete(channel) }
                        do { try context.save() }
                        catch { print("Ошибка удаления канала: \(error.localizedDescription)") }
                        dismiss()
                    }
                }
            }
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text(alertMessage) }
        }
    }
}

// MARK: - Представление для отображения таблицы с каналами
struct TableChannelView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Channel.node1, order: .forward) private var channels: [Channel]

    var body: some View {
        NavigationStack {
            List {
                ForEach(channels) { channel in
                    HStack {
                        Text(channel.node1)
                        Text(" ")
                        Text(channel.node2)
                        Text(" ")
                        Text(String(format: "%.0f", channel.dataVolume ?? 0))
                        Text(" ")
                        Text(channel.channelType?.name ?? " ")
                        Text(" ")
                        Text(String(format: "%.0f",channel.channelType?.price ?? 0))
                        Text(" ")
                        Text(String(format: "%.0f",channel.packageVolume))
                    }
                }
            }
            .navigationTitle("Nodes Table")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Закрыть") { dismiss() } }
            }
        }
    }
}

// MARK: - Меню работы с типами каналов
struct ChannelTypeMenuView: View {
    @State private var showAddChannelTypeSheet = false
    @State private var showTableChannelTypeSheet = false
    @State private var showDeleteChannelTypeSheet = false

    var body: some View {
        List {
            Button("Add Channel Type") { showAddChannelTypeSheet = true }
                .sheet(isPresented: $showAddChannelTypeSheet) { AddChannelTypeView() }
            
            Button("Delete Channel Type") { showDeleteChannelTypeSheet = true }
                .sheet(isPresented: $showDeleteChannelTypeSheet) { DeleteChannelTypeView() }
            
            Button("Table Channel Type") { showTableChannelTypeSheet = true }
                .sheet(isPresented: $showTableChannelTypeSheet) { TableChannelTypeView() }
        }
        .navigationTitle("Channel Types")
    }
}

// MARK: - Представление для добавления типа канала
struct AddChannelTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var typeName = ""
    @State private var speedText = ""
    @State private var priceText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Введите параметры типа канала")) {
                    TextField("Название типа", text: $typeName)
                    TextField("Скорость", text: $speedText)
                        .keyboardType(.decimalPad)
                    TextField("Цена", text: $priceText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Channel Type")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        guard let speed = Double(speedText),
                              let price = Double(priceText),
                              !typeName.isEmpty else {
                            alertMessage = "Пожалуйста, заполните все поля корректно."
                            showAlert = true
                            return
                        }
                        let newChannelType = ChannelType(name: typeName, speed: speed, price: price)
                        context.insert(newChannelType)
                        do { try context.save() }
                        catch { print("Ошибка сохранения типа канала: \(error.localizedDescription)") }
                        dismiss()
                    }
                }
            }
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text(alertMessage) }
        }
    }
}

// MARK: - Представление для удаления типа канала
struct DeleteChannelTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var channelTypeNameToDelete = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Введите название типа канала, который нужно удалить")) {
                    TextField("Тип канала", text: $channelTypeNameToDelete)
                }
            }
            .navigationTitle("Delete Channel Type")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Удалить") {
                        let channelsType = fetctChannelsType(withName: channelTypeNameToDelete)
                        for channelType in channelsType { context.delete(channelType) }
                        do { try context.save() }
                        catch { print("Ошибка удаления типа канала: \(error.localizedDescription)") }
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func fetctChannelsType(withName name: String) -> [ChannelType] {
        let request = FetchDescriptor<ChannelType>(predicate: #Predicate { (сhannelType: ChannelType) in
            сhannelType.name == name
        })
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - Представление для отображения таблицы с типами каналов
struct TableChannelTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ChannelType.speed, order: .forward) private var channelTypes: [ChannelType]

    var body: some View {
        NavigationStack {
            List {
                ForEach(channelTypes) { type in
                    HStack {
                        Text(type.name)
                        Spacer()
                        Text("Скорость: \(type.speed, specifier: "%.0f")")
                        Text("Цена: \(type.price, specifier: "%.0f")")
                    }
                }
            }
            .navigationTitle("Channel Types Table")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Закрыть") { dismiss() } }
            }
        }
    }
}

// MARK: - Просмотр узлов и каналов на графике
struct ChartsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Node.name, order: .forward) private var nodes: [Node]
    @Query(sort: \Channel.node1, order: .forward) private var channels: [Channel]
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Отрисовка каналов как линий между узлами
                ForEach(channels) { channel in
                    if let startNode = nodes.first(where: { $0.name == channel.node1 }),
                       let endNode = nodes.first(where: { $0.name == channel.node2 }) {
                        Path { path in
                            let startPoint = convertCoordinates(x: startNode.x, y: startNode.y, in: geo.size)
                            let endPoint = convertCoordinates(x: endNode.x, y: endNode.y, in: geo.size)
                            path.move(to: startPoint)
                            path.addLine(to: endPoint)
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }
                }
                // Отрисовка узлов как кружков с подписями
                ForEach(nodes) { node in
                    let pos = convertCoordinates(x: node.x, y: node.y, in: geo.size)
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                        // 30/2 - это половина диаметра кружка, добавляем еще отступ (например, 8)
                        Text(node.name)
                            .foregroundColor(.green)
                            .font(.caption)
                            .offset(y: -(30 / 2 + 8))
                    }
                    .position(pos)
                }

            }
            .scaleEffect(scale)
            .offset(offset)
            // Жест перемещения (Drag)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height)
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            // Жест масштабирования (Magnification)
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
                    .onEnded { value in
                        scale = value
                    }
            )
        }
        .navigationTitle("Charts")
    }
    
    // Функция преобразования координат узла в координаты экрана.
    // Здесь предполагается, что центр экрана соответствует логическим координатам (0,0),
    // а 1 единица измерения равна 50 поинтам.
    private func convertCoordinates(x: Double, y: Double, in size: CGSize) -> CGPoint {
        let scaleFactor: CGFloat = 50 // 50 поинтов на единицу
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let newX = center.x + CGFloat(x) * scaleFactor
        let newY = center.y + CGFloat(y) * scaleFactor
        return CGPoint(x: newX, y: newY)
    }
}


// MARK: - Матрица нагрузки
struct LoadMatrixView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \LoadMatrix.node1, order: .forward) private var loadMatrices: [LoadMatrix]
    @State private var showAddLoadMatrixSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(loadMatrices) { entry in
                    HStack {
                        Text("\(entry.node1) → \(entry.node2)")
                        Spacer()
                        Text("\(entry.volume, specifier: "%.0f")")
                    }
                }
                // Добавляем возможность удаления через смахивание строки
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("Load Matrix")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddLoadMatrixSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddLoadMatrixSheet) {
                AddLoadMatrixView()
            }
        }
    }
    
    // Функция для удаления записей матрицы нагрузки по переданным индексам.
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = loadMatrices[index]
            context.delete(entry)
        }
        do {
            try context.save()
        } catch {
            print("Ошибка удаления записи матрицы нагрузки: \(error.localizedDescription)")
        }
    }
}




// MARK: - Представление для добавления новой записи в матрицу нагрузки
// Пользователь выбирает узел-отправитель и узел-получатель из списка, затем вводит объём передаваемых данных.
struct AddLoadMatrixView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // Получаем список узлов для выбора
    @Query(sort: \Node.name, order: .forward) private var nodes: [Node]

    @State private var selectedNode1Id: UUID? = nil
    @State private var selectedNode2Id: UUID? = nil
    @State private var volumeText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Select Nodes")) {
                    Picker("From Node", selection: $selectedNode1Id) {
                        Text("Select Node").tag(Optional<UUID>(nil))
                        ForEach(nodes) { node in
                            Text(node.name).tag(Optional(node.id))
                        }
                    }
                    Picker("To Node", selection: $selectedNode2Id) {
                        Text("Select Node").tag(Optional<UUID>(nil))
                        ForEach(nodes) { node in
                            Text(node.name).tag(Optional(node.id))
                        }
                    }
                }
                Section(header: Text("Volume")) {
                    TextField("Enter volume", text: $volumeText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Load Matrix")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveLoadMatrix() }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text(alertMessage) }
        }
    }
    
    private func saveLoadMatrix() {
        guard let fromId = selectedNode1Id,
              let toId = selectedNode2Id,
              let volume = Double(volumeText) else {
            alertMessage = "Please select both nodes and enter a valid volume."
            showAlert = true
            return
        }
        
        guard let fromNode = nodes.first(where: { $0.id == fromId }),
              let toNode = nodes.first(where: { $0.id == toId }) else {
            alertMessage = "Selected nodes not found."
            showAlert = true
            return
        }
        
        let newLoadMatrix = LoadMatrix(node1: fromNode.name, node2: toNode.name, volume: volume)
        context.insert(newLoadMatrix)
        do {
            try context.save()
        } catch {
            alertMessage = "Error saving load matrix: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        dismiss()
    }
}

// MARK: - Меню для расчета кратчайшего пути, таблицы путей и расчета потоков
struct ShortestPathMenuView: View {
    @Environment(\.modelContext) private var context
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showTableSheet = false

    var body: some View {
        NavigationStack {
            List {
                Button("Calculate Path") {
                    calculateShortestPaths()
                }
                Button("Table Shortest Path") {
                    showTableSheet = true
                }
                // Новая кнопка для расчёта потока через каналы
                Button("Flow Calculation") {
                    calculateFlow()
                }
            }
            .navigationTitle("Shortest Path")
            .alert("Message", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showTableSheet) {
                TableShortestPathView()
            }
        }
    }
    
    // Функция для расчёта кратчайших путей для всех записей матрицы нагрузки.
    private func calculateShortestPaths() {
        // Получаем все каналы
        guard let channels = try? context.fetch(FetchDescriptor<Channel>()) else {
            alertMessage = "Не удалось получить каналы."
            showAlert = true
            return
        }
        // Построим граф: название узла -> список соседних узлов
        var graph: [String: [String]] = [:]
        for channel in channels {
            graph[channel.node1, default: []].append(channel.node2)
            graph[channel.node2, default: []].append(channel.node1)
        }
        
        // Получаем все записи матрицы нагрузки
        guard let loadEntries = try? context.fetch(FetchDescriptor<LoadMatrix>()) else {
            alertMessage = "Не удалось получить матрицу нагрузки."
            showAlert = true
            return
        }
        
        // Удаляем существующие записи кратчайших путей (если они были ранее рассчитаны)
        if let existingPaths = try? context.fetch(FetchDescriptor<ShortestPath>()) {
            for sp in existingPaths {
                context.delete(sp)
            }
        }
        
        // Для каждой записи матрицы нагрузки, находим кратчайший путь
        for entry in loadEntries {
            let source = entry.node1
            let target = entry.node2
            let pathNodes = bfs(source: source, target: target, graph: graph)
            let pathString: String
            if let pathNodes = pathNodes {
                pathString = pathNodes.joined(separator: " -> ")
            } else {
                pathString = "Путь не найден"
            }
            
            let sp = ShortestPath(node1: source, node2: target, path: pathString)
            context.insert(sp)
        }
        
        do {
            try context.save()
            alertMessage = "Кратчайшие пути рассчитаны."
            showAlert = true
        } catch {
            alertMessage = "Ошибка сохранения кратчайших путей: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // Реализация поиска кратчайшего пути (BFS) для невзвешенного графа.
    private func bfs(source: String, target: String, graph: [String: [String]]) -> [String]? {
        var queue: [[String]] = [[source]]
        var visited: Set<String> = [source]
        
        while !queue.isEmpty {
            let path = queue.removeFirst()
            if let last = path.last, last == target {
                return path
            }
            if let neighbors = graph[path.last ?? ""] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        visited.insert(neighbor)
                        var newPath = path
                        newPath.append(neighbor)
                        queue.append(newPath)
                    }
                }
            }
        }
        return nil
    }
    
    private func calculateFlow() {
        // Сбрасываем для всех каналов значение dataVolume в 0
        guard let channelRecords = try? context.fetch(FetchDescriptor<Channel>()) else {
            alertMessage = "Не удалось получить каналы."
            showAlert = true
            return
        }
        for channel in channelRecords {
            channel.dataVolume = 0
        }
        
        // Получаем все записи матрицы нагрузки
        guard let loadMatrices = try? context.fetch(FetchDescriptor<LoadMatrix>()) else {
            alertMessage = "Не удалось получить матрицу нагрузки."
            showAlert = true
            return
        }
        // Создаём изменяемую копию записей матрицы нагрузки,
        // чтобы при сопоставлении каждой записи можно было «удалять» её из списка
        var remainingLoad = loadMatrices
        
        // Получаем все записи кратчайших путей
        guard let spRecords = try? context.fetch(FetchDescriptor<ShortestPath>()) else {
            alertMessage = "Не удалось получить кратчайшие пути."
            showAlert = true
            return
        }
        
        // Словарь для суммирования потока для каждого канала.
        // Ключ – строка, составленная из имён узлов в отсортированном порядке (например, "A-B")
        var channelFlows: [String: Double] = [:]
        
        // Для каждой записи кратчайшего пути
        for sp in spRecords {
            // Для сопоставления пытаемся найти соответствующую запись в матрице нагрузки.
            // Предполагается, что для каждой записи в ShortestPath существует ровно одна запись в LoadMatrix,
            // где sp.node1 и sp.node2 совпадают с исходными и конечными узлами.
            if let index = remainingLoad.firstIndex(where: { $0.node1 == sp.node1 && $0.node2 == sp.node2 }) {
                let volume = remainingLoad[index].volume
                remainingLoad.remove(at: index)
                // Разбиваем строку пути, например "A -> B -> C", на массив узлов
                let nodesInPath = sp.path.components(separatedBy: " -> ")
                // Для каждого соседнего сегмента пути добавляем объем в словарь channelFlows
                for i in 0..<nodesInPath.count - 1 {
                    let first = nodesInPath[i]
                    let second = nodesInPath[i + 1]
                    // Формируем ключ – отсортированная пара узлов, чтобы канал идентифицировался независимо от направления
                    let channelKey = [first, second].sorted().joined(separator: "-")
                    channelFlows[channelKey, default: 0] += volume
                }
            }
        }
        
        // Обновляем для каждого канала его свойство dataVolume на основе рассчитанных сумм
        for channel in channelRecords {
            let key = [channel.node1, channel.node2].sorted().joined(separator: "-")
            channel.dataVolume = channelFlows[key] ?? 0
        }
        
        do {
            try context.save()
            alertMessage = "Расчёт потока выполнен успешно."
            showAlert = true
        } catch {
            alertMessage = "Ошибка сохранения данных по потоку: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Представление таблицы кратчайших путей.
struct TableShortestPathView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ShortestPath.node1, order: .forward) private var shortestPaths: [ShortestPath]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(shortestPaths) { sp in
                    VStack(alignment: .leading) {
                        Text("\(sp.node1) → \(sp.node2):")
                            .fontWeight(.bold)
                        Text(sp.path)
                    }
                }
            }
            .navigationTitle("Table Shortest Path")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Представление для создания полносвязного графа
/// Представление, которое позволяет создать полносвязный граф – т.е. соединить все узлы между собой каналами.
struct FullConnectedGraphView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Node.name, order: .forward) private var nodes: [Node]
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Нажмите кнопку для создания полносвязного графа.\nВсе узлы будут соединены между собой напрямую.")
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Generate Graph") {
                    generateFullConnectedGraph()
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Full Connected Graph")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .alert("Message", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    /// Функция для создания полносвязного графа.
    /// Для каждой пары узлов проверяется, существует ли уже канал между ними; если нет, создаётся новый канал.
    private func generateFullConnectedGraph() {
        var createdCount = 0
        
        // Извлекаем все существующие каналы за один запрос
        guard let existingChannels = try? context.fetch(FetchDescriptor<Channel>()) else {
            alertMessage = "Не удалось получить существующие каналы."
            showAlert = true
            return
        }
        
        // Формируем множество ключей для существующих каналов
        // Ключ формируется как отсортированная пара имен, объединённых дефисом, например "A-B"
        var existingChannelKeys = Set<String>()
        for channel in existingChannels {
            let key = [channel.node1, channel.node2].sorted().joined(separator: "-")
            existingChannelKeys.insert(key)
        }
        
        // Перебираем все пары узлов, используя уже загруженный массив nodes (предполагается, что nodes получены через @Query)
        for i in 0..<nodes.count {
            for j in i+1..<nodes.count {
                let nodeA = nodes[i]
                let nodeB = nodes[j]
                let key = [nodeA.name, nodeB.name].sorted().joined(separator: "-")
                // Если канал с таким ключом отсутствует, создаём его
                if !existingChannelKeys.contains(key) {
                    let newChannel = Channel(node1: nodeA.name, node2: nodeB.name)
                    context.insert(newChannel)
                    createdCount += 1
                }
            }
        }
        
        do {
            try context.save()
            alertMessage = "Полносвязный граф создан.\nДобавлено каналов: \(createdCount)."
            showAlert = true
        } catch {
            alertMessage = "Ошибка создания графа: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
}

