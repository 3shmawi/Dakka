import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:vanguard/data/models/task.dart';

class NotificationService {
  static const String _channelKey = 'dakka_channel';
  static const String _challengeChannelKey = 'dakka_challenge_channel';

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelGroupKey: 'dakka_group',
          channelKey: _channelKey,
          channelName: 'Task Notifications',
          channelDescription: 'Notifications for tasks and reminders',
          defaultColor: const Color(0xFF6366F1),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelGroupKey: 'dakka_group',
          channelKey: _challengeChannelKey,
          channelName: 'Challenge Notifications',
          channelDescription: 'Notifications for challenges and achievements',
          defaultColor: const Color(0xFFE11D48),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'dakka_group',
          channelGroupName: 'Dakka Notifications',
        )
      ],
    );

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> scheduleTaskNotifications(Task task) async {
    if (task.dueDate == null) return;

    final now = DateTime.now();
    final dueDate = task.dueDate!;

    // Schedule notification 15 minutes before due time
    final beforeTime = dueDate.subtract(const Duration(minutes: 15));
    if (beforeTime.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: task.id.hashCode,
          channelKey: _channelKey,
          title: 'Task Reminder',
          body: '${task.title} is due in 15 minutes',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': task.id, 'type': 'reminder'},
        ),
        schedule: NotificationCalendar.fromDate(date: beforeTime),
      );
    }

    // Schedule notification at due time
    if (dueDate.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: task.id.hashCode + 1,
          channelKey: _channelKey,
          title: 'Task Due Now!',
          body: '${task.title} is due now',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': task.id, 'type': 'due'},
        ),
        schedule: NotificationCalendar.fromDate(date: dueDate),
      );
    }
  }

  Future<void> showChallengeNotification({
    required String challengeTitle,
    required String challengeDescription,
    required String taskId,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _challengeChannelKey,
        title: '🎯 Challenge Available!',
        body: challengeTitle,
        bigPicture: 'asset://assets/challenge_notification.png',
        notificationLayout: NotificationLayout.BigText,
        payload: {'taskId': taskId, 'type': 'challenge'},
        actionType: ActionType.Default,
      ),
    );
  }

  Future<void> showChallengeProgressNotification({
    required String challengeTitle,
    required int remainingMinutes,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _challengeChannelKey,
        title: '⏰ Challenge in Progress',
        body: '$challengeTitle - $remainingMinutes minutes remaining!',
        notificationLayout: NotificationLayout.Default,
        payload: {'type': 'challenge_progress'},
      ),
    );
  }

  Future<void> showSuccessNotification(String challengeTitle) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _challengeChannelKey,
        title: '🎉 Challenge Completed!',
        body: 'Well done! You completed: $challengeTitle',
        notificationLayout: NotificationLayout.Default,
        payload: {'type': 'challenge_success'},
      ),
    );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    await AwesomeNotifications().cancelNotificationsByGroupKey(taskId);
    await AwesomeNotifications().cancel(taskId.hashCode);
    await AwesomeNotifications().cancel(taskId.hashCode + 1);
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
