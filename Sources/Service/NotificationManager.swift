import UserNotifications
import os

enum NotificationManager {
    private static let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "NotificationManager")

    static func requestPermissionAndSchedule(todosPath: String?) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error = error {
                logger.error("Notification permission error: \(error.localizedDescription)")
                return
            }

            guard granted else {
                logger.info("Notification permission denied by user")
                return
            }

            scheduleDailyReminder(todosPath: todosPath)
        }
    }

    private static func scheduleDailyReminder(todosPath: String?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["hamster-daily-reminder"]
        )

        var count = 0
        if let path = todosPath {
            count = DailyNoteParser.loadTodos(from: path)
                .filter { !$0.isCompleted }
                .count
        }

        let content = UNMutableNotificationContent()
        content.title = Greetings.random()
        content.body = count > 0
            ? "\(count)개의 할 일이 기다리고 있어요"
            : "오늘은 할 일이 없어요~ 푹 쉬세요 🐹💤"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "hamster-daily-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                logger.error("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
}
