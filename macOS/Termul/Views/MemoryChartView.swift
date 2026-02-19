//
//  MemoryChartView.swift
//  Termul
//
//  Created by Service Helper
//

import SwiftUI

/// Sparkline chart view for displaying memory usage history
struct MemoryChartView: View {
    // MARK: - Properties

    /// Memory data points to display
    let memoryData: [MemoryData]

    /// Whether the chart is expanded to show more details
    @State private var isExpanded = false

    /// Currently hovered data point (optional)
    @State private var hoveredPoint: MemoryData?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chartHeader

            if memoryData.isEmpty {
                emptyChartView
            } else {
                chartView
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.02))
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Chart Header

    private var chartHeader: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let current = memoryData.last {
                        Text(current.memoryMBFormatted)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(memoryColor(for: current.memoryMB))

                        Image(systemName: memoryTrendSymbol)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(memoryTrendColor)
                    } else {
                        Text("--")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                if memoryData.last != nil {
                    Text("Current Memory")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }
            }

            Spacer()

            if isExpanded, let stats = statistics {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 12) {
                        Stat(label: "Min", value: formatMemory(stats.min))
                        Stat(label: "Max", value: formatMemory(stats.max))
                        Stat(label: "Avg", value: formatMemory(stats.avg))
                    }
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.01))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }

    // MARK: - Chart View

    private var chartView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid lines
                if isExpanded {
                    gridLines(height: geometry.size.height)
                }

                // Gradient fill under curve
                fillPath(size: geometry.size)

                // Sparkline path
                sparklinePath(size: geometry.size)

                // Hover indicator
                if let hovered = hoveredPoint, isExpanded {
                    hoverIndicator(for: hovered, size: geometry.size)
                }
            }
            .frame(height: isExpanded ? 120 : 60)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onHover { hovering in
                            if !hovering {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    hoveredPoint = nil
                                }
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleHover(at: value.location, in: geometry.size)
                                }
                        )
                }
            )
        }
        .frame(height: isExpanded ? 120 : 60)
        .padding(.top, 8)
    }

    // MARK: - Sparkline Path

    private func sparklinePath(size: CGSize) -> some View {
        let path = createSparklinePath(in: size)

        return path
            .stroke(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: isExpanded ? 2 : 1.5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
    }

    // MARK: - Fill Path

    private func fillPath(size: CGSize) -> some View {
        let path = createSparklinePath(in: size)
        var fillPath = path

        // Close the path at the bottom
        fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
        fillPath.addLine(to: CGPoint(x: 0, y: size.height))
        fillPath.closeSubpath()

        return fillPath
            .fill(
                LinearGradient(
                    colors: [
                        gradientColors.first!.opacity(0.3),
                        gradientColors.last!.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    // MARK: - Grid Lines

    private func gridLines(height: CGFloat) -> some View {
        ZStack {
            ForEach(0..<4) { i in
                let y = CGFloat(i) * (height / 3)
                Rectangle()
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 1)
                    .position(x: 0, y: y)
            }
        }
    }

    // MARK: - Hover Indicator

    @ViewBuilder
    private func hoverIndicator(for data: MemoryData, size: CGSize) -> some View {
        if let index = memoryData.firstIndex(where: { $0.id == data.id }) {
            let x = CGFloat(index) / CGFloat(max(1, memoryData.count - 1)) * size.width
            let values = memoryData.map { $0.memoryMB }
            let minVal = values.min() ?? 0
            let maxVal = max(values.max() ?? 1, minVal + 1)
            let y = size.height - ((data.memoryMB - minVal) / (maxVal - minVal) * size.height)

            ZStack {
                // Vertical line
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)
                    .position(x: x, y: size.height / 2)

                // Horizontal line
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .position(x: size.width / 2, y: y)

                // Point indicator
                Circle()
                    .fill(.white)
                    .frame(width: 6, height: 6)
                    .position(x: x, y: y)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                // Tooltip
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatMemory(data.memoryMB))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)

                    Text(timestampString(for: data.timestamp))
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.8))
                )
                .position(x: min(max(x + 40, 60), size.width - 40), y: min(max(y - 20, 20), size.height - 20))
            }
        }
    }

    // MARK: - Empty Chart View

    private var emptyChartView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .frame(width: 40, height: 40)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.15))
            }

            Text("No memory data yet")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.25))

            Text("Start a project to begin tracking")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.15))
        }
        .frame(height: isExpanded ? 120 : 60)
    }

    // MARK: - Helper Methods

    private func createSparklinePath(in size: CGSize) -> Path {
        guard !memoryData.isEmpty else {
            return Path()
        }

        let values = memoryData.map { $0.memoryMB }
        let minVal = values.min() ?? 0
        let maxVal = max(values.max() ?? 1, minVal + 1)

        var path = Path()

        for (index, data) in memoryData.enumerated() {
            let x = CGFloat(index) / CGFloat(max(1, memoryData.count - 1)) * size.width
            let normalizedValue = (data.memoryMB - minVal) / (maxVal - minVal)
            let y = size.height - (normalizedValue * size.height)

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Smooth curve using cubic bezier
                if index > 0 {
                    let prevX = CGFloat(index - 1) / CGFloat(max(1, memoryData.count - 1)) * size.width
                    let prevData = memoryData[index - 1]
                    let prevNormalizedValue = (prevData.memoryMB - minVal) / (maxVal - minVal)
                    let prevY = size.height - (prevNormalizedValue * size.height)

                    let cp1x = prevX + (x - prevX) * 0.5
                    let cp1y = prevY
                    let cp2x = prevX + (x - prevX) * 0.5
                    let cp2y = y

                    path.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: cp1x, y: cp1y),
                        control2: CGPoint(x: cp2x, y: cp2y)
                    )
                }
            }
        }

        return path
    }

    private func handleHover(at location: CGPoint, in size: CGSize) {
        guard !memoryData.isEmpty else { return }

        let index = Int((location.x / size.width) * CGFloat(memoryData.count))
        let clampedIndex = max(0, min(memoryData.count - 1, index))

        withAnimation(.easeOut(duration: 0.1)) {
            hoveredPoint = memoryData[clampedIndex]
        }
    }

    // MARK: - Properties

    private var statistics: (min: Double, max: Double, avg: Double)? {
        guard !memoryData.isEmpty else { return nil }

        let values = memoryData.map { $0.memoryMB }
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        let avg = values.reduce(0, +) / Double(values.count)

        return (min: min, max: max, avg: avg)
    }

    private var gradientColors: [Color] {
        guard let last = memoryData.last else {
            return [DesignColors.iron]
        }

        switch last.memoryMB {
        case 0..<500:
            return [DesignColors.success, DesignColors.success]
        case 500..<1024:
            return [DesignColors.warning, DesignColors.warning]
        case 1024..<2048:
            return [DesignColors.warning, DesignColors.warning]
        default:
            return [DesignColors.error, DesignColors.coral]
        }
    }

    private func memoryColor(for mb: Double) -> Color {
        switch mb {
        case 0..<500: return DesignColors.success
        case 500..<1024: return DesignColors.warning
        case 1024..<2048: return DesignColors.warning
        default: return DesignColors.error
        }
    }

    private var memoryTrendColor: Color {
        guard !memoryData.isEmpty else { return DesignColors.iron }

        if memoryData.count >= 10 {
            let recent = memoryData.suffix(10).map { $0.memoryMB }
            let averageFirst = recent.prefix(5).reduce(0, +) / 5.0
            let averageLast = recent.suffix(5).reduce(0, +) / 5.0

            let delta = averageLast - averageFirst

            if delta > 10 { return DesignColors.error }
            if delta < -10 { return DesignColors.success }
        }

        return DesignColors.iron
    }

    private var memoryTrendSymbol: String {
        if memoryData.count >= 10 {
            let recent = memoryData.suffix(10).map { $0.memoryMB }
            let averageFirst = recent.prefix(5).reduce(0, +) / 5.0
            let averageLast = recent.suffix(5).reduce(0, +) / 5.0

            let delta = averageLast - averageFirst

            if delta > 10 { return "arrow.up.right" }
            if delta < -10 { return "arrow.down.right" }
        }

        return "arrow.right"
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            let gb = mb / 1024.0
            return String(format: "%.1f GB", gb)
        } else {
            return String(format: "%.0f MB", mb)
        }
    }

    private func timestampString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Stat View

private struct Stat: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 2) {
            Text("\(label):")
                .foregroundColor(.white.opacity(0.4))
            Text(value)
        }
    }
}
