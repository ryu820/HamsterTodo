import UserNotifications
import os

enum NotificationManager {
    private static let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "NotificationManager")

    static func requestPermissionAndSchedule(incompleteTodoCount: Int) {
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

            scheduleDailyReminder(incompleteTodoCount: incompleteTodoCount)
        }
    }

    private static func scheduleDailyReminder(incompleteTodoCount count: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: [Strings.Notification.identifier]
        )

        let content = UNMutableNotificationContent()
        content.title = Greetings.random()
        content.body = count > 0
            ? Strings.Notification.bodyWithCount(count)
            : Strings.Notification.bodyEmpty
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: Strings.Notification.identifier,
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
