import SwiftUI
import ServiceManagement
import os

@main
struct HamsterTodoApp: App {
    @StateObject private var iconAnimator = HamsterIconAnimator()
    @StateObject private var viewModel = TodoViewModel()

    private static let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "App")

    init() {
        let todoCount: Int
        if let path = VaultAccessManager.shared.vaultURL?.path {
            todoCount = DailyNoteParser.loadTodos(from: path)
                .filter { !$0.isCompleted }
                .count
        } else {
            todoCount = 0
        }
        NotificationManager.requestPermissionAndSchedule(incompleteTodoCount: todoCount)

        do {
            try SMAppService.mainApp.register()
        } catch {
            Self.logger.error("Failed to register login item: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PopupView()
                .environmentObject(viewModel)
        } label: {
            Image(nsImage: iconAnimator.currentImage)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class HamsterIconAnimator: ObservableObject {
    @Published var currentImage: NSImage

    private var timer: Timer?
    private var frameIndex = 0
    private let frames = PixelHamster.Frame.allCases

    init() {
        self.currentImage = PixelHamster.makeImage(frame: .sitting)
        startAnimation()
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceFrame()
            }
        }
    }

    private func advanceFrame() {
        frameIndex = (frameIndex + 1) % frames.count
        currentImage = PixelHamster.makeImage(frame: frames[frameIndex])
    }
}
