//
//  ChartViewFallback.swift
//  App
//

import Accelerate
import Combine
import SwiftUI

// MARK: - ChartViewFallback

struct ChartViewFallback: View {
    // MARK: Internal

    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var store: AppStore

    var chartView: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                yGridView()
                alarmLowGridView()
                alarmHighGridView()
                targetGridView()
                scrollGridView(fullSize: geo.size).padding(.leading, Config.y.padding)
            }
            .gesture(TapGesture(count: 2).onEnded { _ in
                store.dispatch(.setChartShowLines(enabled: !store.state.chartShowLines))
            })
            .onChange(of: colorScheme) { scheme in
                if deviceColorScheme != scheme {
                    DirectLog.info("onChange colorScheme: \(scheme)")
                    deviceColorScheme = scheme
                }
            }
            .onChange(of: store.state.chartShowLines) { chartShowLines in
                DirectLog.info("onChange chartShowLines: \(chartShowLines)")

                updateCgmPath(fullSize: geo.size, glucoseValues: cgmValues)
                updateBgmPath(fullSize: geo.size, glucoseValues: bgmValues)
            }
            .onChange(of: store.state.alarmLow) { alarmLow in
                DirectLog.info("onChange alarmLow: \(alarmLow)")

                updateYGrid(fullSize: geo.size, alarmLow: alarmLow, alarmHigh: store.state.alarmHigh, targetValue: store.state.targetValue, glucoseUnit: store.state.glucoseUnit)
                updateAlarmLowGrid(fullSize: geo.size, alarmLow: alarmLow)
            }
            .onChange(of: store.state.alarmHigh) { alarmHigh in
                DirectLog.info("onChange alarmHigh: \(alarmHigh)")

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: alarmHigh, targetValue: store.state.targetValue, glucoseUnit: store.state.glucoseUnit)
                updateAlarmHighGrid(fullSize: geo.size, alarmHigh: alarmHigh)
            }
            .onChange(of: store.state.targetValue) { targetValue in
                DirectLog.info("onChange targetValue: \(targetValue)")

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: targetValue, glucoseUnit: store.state.glucoseUnit)
                updateTargetGrid(fullSize: geo.size, targetValue: targetValue)
            }
            .onChange(of: store.state.glucoseUnit) { glucoseUnit in
                DirectLog.info("onChange glucoseUnit: \(glucoseUnit)")

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: store.state.targetValue, glucoseUnit: glucoseUnit)
            }
            .onChange(of: store.state.glucoseValues) { _ in
                DirectLog.info("onChange glucoseValues: \(store.state.glucoseValues.count)")

                updateHelpVariables(fullSize: geo.size, glucoseValues: store.state.glucoseValues)
                updateGlucoseValues(glucoseValues: store.state.glucoseValues)
            }
            .onChange(of: store.state.chartZoomLevel) { zoomLevel in
                DirectLog.info("onChange zoomLevel: \(zoomLevel)")

                updateZoomLevel(level: zoomLevel)

                updateHelpVariables(fullSize: geo.size, glucoseValues: store.state.glucoseValues)
                updateGlucoseValues(glucoseValues: store.state.glucoseValues)
            }
            .onChange(of: [bgmValues, cgmValues]) { _ in
                DirectLog.info("onChange bgmValues/cgmValues")

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: store.state.targetValue, glucoseUnit: store.state.glucoseUnit)
                updateXGrid(fullSize: geo.size, firstTimeStamp: self.firstTimeStamp, lastTimeStamp: self.lastTimeStamp)

                updateAlarmLowGrid(fullSize: geo.size, alarmLow: store.state.alarmLow)
                updateAlarmHighGrid(fullSize: geo.size, alarmHigh: store.state.alarmHigh)
                updateTargetGrid(fullSize: geo.size, targetValue: store.state.targetValue)

                updateCgmPath(fullSize: geo.size, glucoseValues: cgmValues)
                updateBgmPath(fullSize: geo.size, glucoseValues: bgmValues)
            }

            .onAppear {
                DirectLog.info("onAppear")

                updateZoomLevel(level: store.state.chartZoomLevel)

                updateHelpVariables(fullSize: geo.size, glucoseValues: store.state.glucoseValues)
                updateGlucoseValues(glucoseValues: store.state.glucoseValues)
            }
        }
    }

    var body: some View {
        if !store.state.glucoseValues.isEmpty {
            Section {
                chartView
                    .padding(.leading, 5)
                    .padding(.trailing, 0)
                    .padding(.top, 15)
                    .padding(.bottom, 5)
                    .frame(height: Config.height)

                HStack {
                    ForEach(Config.zoomLevels, id: \.level) { zoom in
                        Button(
                            action: {
                                store.dispatch(.setChartZoomLevel(level: zoom.level))
                            },
                            label: {
                                Circle()
                                    .if(store.state.chartZoomLevel == zoom.level) {
                                        $0.fill(Config.y.textColor)
                                    } else: {
                                        $0.stroke(Config.y.textColor)
                                    }
                                    .frame(width: 12, height: 12)

                                Text(zoom.title)
                                    .font(.subheadline)
                                    .foregroundColor(Config.y.textColor)
                            }
                        ).buttonStyle(.plain)

                        Spacer()
                    }

                    Button(
                        action: {
                            store.dispatch(.setChartShowLines(enabled: !store.state.chartShowLines))
                        },
                        label: {
                            Rectangle()
                                .if(store.state.chartShowLines) {
                                    $0.fill(Config.y.textColor)
                                } else: {
                                    $0.stroke(Config.y.textColor)
                                }
                                .frame(width: 12, height: 12)

                            Text("Line")
                                .font(.subheadline)
                                .foregroundColor(Config.y.textColor)
                        }
                    ).buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Private

    private enum Config {
        enum alarm {
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth)

            static var color: Color { Color.ui.red.opacity(opacity) }
        }

        enum target {
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth)

            static var color: Color { Color.ui.green.opacity(opacity) }
        }

        enum now {
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth, dash: [4, 8])

            static var color: Color { Color.ui.blue.opacity(opacity) }
        }

        enum dot {
            static let size: CGFloat = 3.5

            static var cgmColor: Color { Color(.sRGB, red: 0.21, green: 0.27, blue: 0.31) | Color(.sRGB, red: 0.90, green: 0.89, blue: 0.89) }
            static var bgmColor: Color { Color.ui.red }
        }

        enum line {
            static var size = 2.5

            static var cgmColor: Color { Color(.sRGB, red: 0.21, green: 0.27, blue: 0.31) | Color(.sRGB, red: 0.90, green: 0.89, blue: 0.89) }
            static var bgmColor: Color { Color.ui.red }
        }

        enum x {
            static let fontSize: CGFloat = 12
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth)
            static let stepWidth: Double = 5

            static var color: Color { Color(.sRGB, red: 0.89, green: 0.90, blue: 0.92) | Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25) } // .opacity(opacity)
            static var textColor: Color { Color(.sRGB, red: 0.09, green: 0.09, blue: 0.09) | Color(.sRGB, red: 0.63, green: 0.63, blue: 0.63) }
        }

        enum y {
            static let additionalBottom: CGFloat = fontSize * 2
            static let fontSize: CGFloat = 12
            static let fontWidth: CGFloat = 28
            static let padding: CGFloat = 20
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth)

            static let mgdLGrid: [Int] = [0, 50, 100, 150, 200, 250, 300, 350, 400]
            static let mmolLGrid: [Int] = [0, 54, 108, 162, 216, 270, 324, 378]

            static var color: Color { Color(.sRGB, red: 0.89, green: 0.90, blue: 0.92) | Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25) }
            static var textColor: Color { Color(.sRGB, red: 0.09, green: 0.09, blue: 0.09) | Color(.sRGB, red: 0.63, green: 0.63, blue: 0.63) }
        }

        static let zoomGridStep: [Int: Double] = [
            1: 15,
            5: 60,
            15: 180,
            30: 360,
        ]

        static let zoomLevels: [ZoomLevelFallback] = [
            ZoomLevelFallback(level: 1, title: "1m"),
            ZoomLevelFallback(level: 5, title: "5m"),
            ZoomLevelFallback(level: 15, title: "15m"),
            ZoomLevelFallback(level: 30, title: "30m"),
        ]

        static let endID = "End"
        static let height: CGFloat = 350
        static let lineWidth = 0.1
        static let maxGlucose = 400
        static let minGlucose = 0
        static let opacity = 0.5

        static var backgroundColor: Color { Color(.sRGB, red: 0.96, green: 0.96, blue: 0.96) | Color(.sRGB, red: 0.09, green: 0.09, blue: 0.09) }
    }

    @StateObject private var updater = MinuteUpdaterFallback()
    @State private var alarmHighGridPath = Path()
    @State private var alarmLowGridPath = Path()
    @State private var firstTimeStamp: Date? = nil
    @State private var cgmPath = Path()
    @State private var bgmPath = Path()
    @State private var glucoseSteps: Int = 0
    @State private var lastTimeStamp: Date? = nil
    @State private var targetGridPath = Path()
    @State private var xGridPath = Path()
    @State private var xGridTexts: [TextInfoFallback] = []
    @State private var yGridPath = Path()
    @State private var yGridTexts: [TextInfoFallback] = []
    @State private var deviceOrientation = UIDevice.current.orientation
    @State private var deviceColorScheme = ColorScheme.light
    @State private var cgmValues: [Glucose] = []
    @State private var cgmInfos: [GlucoseInfoFallback] = []
    @State private var glucoseInfo: GlucoseInfoFallback? = nil
    @State private var bgmValues: [Glucose] = []
    @State private var zoomGridStep = Config.zoomGridStep[Config.zoomLevels.first!.level]!

    private let calculationQueue = DispatchQueue(label: "libre-direct.chart-calculation")

    private func scrollGridView(fullSize: CGSize) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scroll in
                ZStack {
                    xGridView()

                    nowView(fullSize: fullSize)
                        .zIndex(2)

                    if store.state.chartShowLines {
                        cgmLineView()
                            .zIndex(3)
                    } else {
                        cgmDotsView()
                            .zIndex(3)
                    }

                    bgmDotsView().zIndex(4)
                }
                .frame(width: CGFloat(Double(glucoseSteps) * Config.x.stepWidth))
                .onChange(of: store.state.glucoseValues) { _ in
                    scroll.scrollTo(Config.endID, anchor: .trailing)
                }
                .onChange(of: store.state.chartZoomLevel) { _ in
                    scroll.scrollTo(Config.endID, anchor: .trailing)
                }.onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                        scroll.scrollTo(Config.endID, anchor: .trailing)
                    }
                }
            }
        }
    }

    private func alarmHighGridView() -> some View {
        alarmHighGridPath
            .stroke(style: Config.alarm.strokeStyle)
            .stroke(Config.alarm.color)
    }

    private func alarmLowGridView() -> some View {
        alarmLowGridPath
            .stroke(style: Config.alarm.strokeStyle)
            .stroke(Config.alarm.color)
    }

    private func nowView(fullSize: CGSize) -> some View {
        Path { path in
            #if targetEnvironment(simulator)
                let now = ISO8601DateFormatter().date(from: "2021-08-01T11:50:00+0200") ?? Date()
            #else
                let now = Date().toRounded(on: 1, .minute)
            #endif

            let x = self.translateTimeStampToX(timestamp: now)

            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: fullSize.height - Config.y.additionalBottom))
        }
        .stroke(style: Config.now.strokeStyle)
        .stroke(Config.now.color)
    }

    private func cgmLineView() -> some View {
        cgmPath
            .stroke(Config.line.cgmColor, lineWidth: Config.line.size)
    }

    private func cgmDotsView() -> some View {
        cgmPath
            .fill(Config.dot.cgmColor)
    }

    private func bgmDotsView() -> some View {
        bgmPath
            .fill(Config.dot.bgmColor)
    }

    private func targetGridView() -> some View {
        targetGridPath
            .stroke(style: Config.target.strokeStyle)
            .stroke(Config.target.color)
    }

    private func xGridView() -> some View {
        ZStack {
            xGridPath
                .stroke(style: Config.x.strokeStyle)
                .stroke(Config.x.color)

            ForEach(xGridTexts, id: \.self.x) { text in
                let fontWeight: Font.Weight = text.highlight ? .semibold : .regular

                Text(text.description)
                    .foregroundColor(Config.x.textColor)
                    .font(.system(size: Config.x.fontSize))
                    .fontWeight(fontWeight)
                    .position(x: text.x, y: text.y)
                    .if(text.x == xGridTexts.last?.x) { $0.id(Config.endID) }
            }
        }
    }

    private func yGridView() -> some View {
        ZStack {
            yGridPath
                .stroke(style: Config.y.strokeStyle)
                .stroke(Config.y.color)

            ForEach(yGridTexts, id: \.self.y) { text in
                let fontWeight: Font.Weight = text.highlight ? .semibold : .regular

                Text(text.description)
                    .foregroundColor(Config.y.textColor)
                    .font(.system(size: Config.y.fontSize))
                    .fontWeight(fontWeight)
                    .padding(0)
                    .frame(width: Config.y.fontWidth, alignment: .trailing)
                    .position(x: text.x, y: text.y)
            }
        }
    }

    private func updateZoomLevel(level: Int) {
        if Config.zoomLevels.contains(where: { $0.level == level }) {
            zoomGridStep = Config.zoomGridStep[level]!
        } else {
            store.dispatch(.setChartZoomLevel(level: Config.zoomLevels.first!.level))
        }
    }

    private func updateHelpVariables(fullSize: CGSize, glucoseValues: [Glucose]) {
        DirectLog.info("updateHelpVariables")

        if let first = glucoseValues.first, let last = glucoseValues.last {
            let firstTimeStamp = first.timestamp.addingTimeInterval(-2 * zoomGridStep * 60)

            #if targetEnvironment(simulator)
                let lastTimeStamp = last.timestamp.addingTimeInterval(2 * zoomGridStep * 60)
            #else
                let lastTimeStamp = Date().toRounded(on: 1, .minute).addingTimeInterval(2 * zoomGridStep * 60)
            #endif

            let glucoseSteps = Int(firstTimeStamp.distance(to: lastTimeStamp) / 60) / store.state.chartZoomLevel

            self.firstTimeStamp = firstTimeStamp
            self.lastTimeStamp = lastTimeStamp
            self.glucoseSteps = glucoseSteps
        }
    }

    private func findGlucoseInfo(x: CGFloat) {
        let halfSize = Config.x.stepWidth / 2

        let glucoseInfo = cgmInfos.reversed().first(where: { info in
            info.x - halfSize < x && info.x + halfSize > x
        })

        self.glucoseInfo = glucoseInfo
    }

    private func updateGlucoseValues(glucoseValues: [Glucose]) {
        DirectLog.info("updateGlucoseValues")

        calculationQueue.async {
            if store.state.chartZoomLevel == 1 {
                let cgmValues = glucoseValues.filter { value in
                    value.type == .cgm && value.glucoseValue != nil
                }

                let bgmValues = glucoseValues.filter { value in
                    value.type == .bgm && value.glucoseValue != nil
                }

                DispatchQueue.main.async {
                    self.cgmValues = cgmValues
                    self.bgmValues = bgmValues
                }
            } else {
                // cgm values
                let filteredValues = glucoseValues.filter { value in
                    value.type == .cgm && value.glucoseValue != nil
                }.map { value in
                    (value.timestamp.toRounded(on: store.state.chartZoomLevel, .minute), value.glucoseValue!)
                }

                let groupedValues: [Date: [(Date, Int)]] = Dictionary(grouping: filteredValues, by: { $0.0 })
                let cgmValues: [Glucose] = groupedValues.map { group in
                    let sumGlucoseValues = group.value.reduce(0) {
                        $0 + $1.1
                    }

                    let meanGlucoseValues = sumGlucoseValues / group.value.count

                    return Glucose.sensorGlucose(timestamp: group.key, glucoseValue: meanGlucoseValues)
                }.sorted(by: { $0.timestamp < $1.timestamp })

                // bgm values
                let bgmValues = glucoseValues.filter { value in
                    value.type == .bgm && value.glucoseValue != nil
                }.map { value in
                    Glucose.bloodGlucose(timestamp: value.timestamp.toRounded(on: store.state.chartZoomLevel, .minute), glucoseValue: value.glucoseValue!)
                }

                DispatchQueue.main.async {
                    self.cgmValues = cgmValues
                    self.bgmValues = bgmValues
                }
            }
        }
    }

    private func updateAlarmHighGrid(fullSize: CGSize, alarmHigh: Int?) {
        DirectLog.info("updateAlarmHighGrid")

        calculationQueue.async {
            if let alarmHigh = alarmHigh {
                let alarmHighGridPath = Path { path in
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(alarmHigh))

                    path.move(to: CGPoint(x: Config.y.padding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }

                DispatchQueue.main.async {
                    self.alarmHighGridPath = alarmHighGridPath
                }
            }
        }
    }

    private func updateAlarmLowGrid(fullSize: CGSize, alarmLow: Int?) {
        DirectLog.info("updateAlarmLowGrid")

        calculationQueue.async {
            if let alarmLow = alarmLow {
                let alarmLowGridPath = Path { path in
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(alarmLow))

                    path.move(to: CGPoint(x: Config.y.padding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }

                DispatchQueue.main.async {
                    self.alarmLowGridPath = alarmLowGridPath
                }
            }
        }
    }

    private func updateCgmPath(fullSize: CGSize, glucoseValues: [Glucose]) {
        DirectLog.info("updateCgmPath")
        var isFirst = true

        calculationQueue.async {
            var cgmInfo: [GlucoseInfoFallback] = []

            let cgmPath = Path { path in
                for glucose in glucoseValues {
                    guard let glucoseValue = glucose.glucoseValue else {
                        return
                    }

                    let x = self.translateTimeStampToX(timestamp: glucose.timestamp)
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(glucoseValue))

                    cgmInfo.append(GlucoseInfoFallback(x: x, glucose: glucose))

                    if store.state.chartShowLines {
                        if isFirst {
                            isFirst = false
                            path.move(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addEllipse(in: CGRect(x: x - Config.dot.size / 2, y: y - Config.dot.size / 2, width: Config.dot.size, height: Config.dot.size))
                    }
                }
            }

            DispatchQueue.main.async {
                self.cgmPath = cgmPath
                self.cgmInfos = cgmInfo
            }
        }
    }

    private func updateBgmPath(fullSize: CGSize, glucoseValues: [Glucose]) {
        DirectLog.info("updateBgmPath")

        calculationQueue.async {
            let cgmPath = Path { path in
                for glucose in glucoseValues {
                    guard let glucoseValue = glucose.glucoseValue else {
                        return
                    }

                    let x = self.translateTimeStampToX(timestamp: glucose.timestamp)
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(glucoseValue))

                    path.addEllipse(in: CGRect(x: x - Config.dot.size, y: y - Config.dot.size, width: Config.dot.size * 2, height: Config.dot.size * 2))
                }
            }

            DispatchQueue.main.async {
                self.bgmPath = cgmPath
            }
        }
    }

    private func updateTargetGrid(fullSize: CGSize, targetValue: Int?) {
        DirectLog.info("updateTargetGrid")

        calculationQueue.async {
            if let targetValue = targetValue {
                let targetGridPath = Path { path in
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(targetValue))

                    path.move(to: CGPoint(x: Config.y.padding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }

                DispatchQueue.main.async {
                    self.targetGridPath = targetGridPath
                }
            }
        }
    }

    private func updateXGrid(fullSize: CGSize, firstTimeStamp: Date?, lastTimeStamp: Date?) {
        DirectLog.info("updateXGrid")

        calculationQueue.async {
            if let firstTimeStamp = firstTimeStamp, let lastTimeStamp = lastTimeStamp {
                let allHours = Date.valuesBetween(
                    from: firstTimeStamp.toRounded(on: Int(zoomGridStep), .minute).addingTimeInterval(-3600),
                    to: lastTimeStamp.toRounded(on: Int(zoomGridStep), .minute).addingTimeInterval(3600),
                    component: .minute,
                    step: Int(zoomGridStep)
                )

                let xGridPath = Path { path in
                    for hour in allHours {
                        if hour == Date().toRounded(on: 1, .minute) {
                            continue
                        }

                        path.move(to: CGPoint(x: self.translateTimeStampToX(timestamp: hour), y: 0))
                        path.addLine(to: CGPoint(x: self.translateTimeStampToX(timestamp: hour), y: fullSize.height - Config.y.additionalBottom))
                    }
                }

                var xGridTexts: [TextInfoFallback] = []
                for hour in allHours {
                    let highlight = Calendar.current.component(.minute, from: hour) == 0
                    let x = self.translateTimeStampToX(timestamp: hour)
                    let y = fullSize.height - Config.y.fontSize
                    xGridTexts.append(TextInfoFallback(description: hour.toLocalTime(), x: x, y: y, highlight: highlight))
                }

                DispatchQueue.main.async {
                    self.xGridPath = xGridPath
                    self.xGridTexts = xGridTexts
                }
            }
        }
    }

    private func updateYGrid(fullSize: CGSize, alarmLow: Int?, alarmHigh: Int?, targetValue: Int?, glucoseUnit: GlucoseUnit) {
        DirectLog.info("updateYGrid")

        calculationQueue.async {
            let gridParts = store.state.glucoseUnit == .mgdL
                ? Config.y.mgdLGrid
                : Config.y.mmolLGrid

            let yGridPath = Path { path in
                for i in gridParts {
                    if i == alarmLow || i == alarmHigh || i == targetValue {
                        continue
                    }

                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(i))

                    path.move(to: CGPoint(x: Config.y.padding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }
            }

            var yGridTexts: [TextInfoFallback] = []
            for i in gridParts {
                if i <= DirectConfig.minReadableGlucose {
                    continue
                }

                let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(i))
                yGridTexts.append(TextInfoFallback(description: i.asGlucose(unit: glucoseUnit), x: 0, y: y, highlight: false))
            }

            DispatchQueue.main.async {
                self.yGridPath = yGridPath
                self.yGridTexts = yGridTexts
            }
        }
    }

    private func translateGlucoseToY(fullSize: CGSize, glucose: CGFloat) -> CGFloat {
        let inMin = CGFloat(Config.minGlucose)
        let inMax = CGFloat(Config.maxGlucose)
        let outMin = fullSize.height - Config.y.additionalBottom
        let outMax = CGFloat(0)

        let y = (glucose - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
        return y
    }

    private func translateStepsToX(steps: Int) -> CGFloat {
        return CGFloat(steps) * CGFloat(Config.x.stepWidth)
    }

    private func translateTimeStampToX(timestamp: Date) -> CGFloat {
        if let first = firstTimeStamp {
            let steps = Int(first.distance(to: timestamp) / 60) / store.state.chartZoomLevel

            return translateStepsToX(steps: steps)
        }

        return 0
    }
}

// MARK: - TextInfoFallback

private struct TextInfoFallback {
    let description: String
    let x: CGFloat
    let y: CGFloat
    let highlight: Bool
}

// MARK: - GlucoseInfoFallback

private struct GlucoseInfoFallback {
    let x: CGFloat
    let glucose: Glucose
}

// MARK: - ZoomLevelFallback

private struct ZoomLevelFallback {
    let level: Int
    let title: String
}

// MARK: - MinuteUpdaterFallback

private class MinuteUpdaterFallback: ObservableObject {
    // MARK: Lifecycle

    init() {
        let fireDate = Date().toRounded(on: 1, .minute).addingTimeInterval(60)
        DirectLog.info("MinuteUpdater, init with \(fireDate)")

        let timer = Timer(fire: fireDate, interval: 60, repeats: true) { _ in
            DirectLog.info("MinuteUpdater, fires at \(Date())")
            self.objectWillChange.send()
        }
        RunLoop.main.add(timer, forMode: .common)

        self.timer = timer
    }

    // MARK: Internal

    var timer: Timer?
}

infix operator |: AdditionPrecedence
private extension Color {
    /// Easily define two colors for both light and dark mode.
    /// - Parameters:
    ///   - lightMode: The color to use in light mode.
    ///   - darkMode: The color to use in dark mode.
    /// - Returns: A dynamic color that uses both given colors respectively for the given user interface style.
    static func | (lightMode: Color, darkMode: Color) -> Color {
        return UITraitCollection.current.userInterfaceStyle == .light ? lightMode : darkMode
    }
}
