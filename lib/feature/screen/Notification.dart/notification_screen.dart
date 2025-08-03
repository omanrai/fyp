import 'package:flutter/material.dart';
import 'package:flutter_fyp/feature/controller/course/course_controller.dart';
import 'package:flutter_fyp/feature/screen/courses/course%20test/course_test_quiz.dart';
import 'package:get/get.dart';

import '../../controller/miscalleneous/notification_controller.dart';
import '../../model/auth/user_model.dart';
import '../../model/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  final UserModel? user;
  final Color roleColor;

  const NotificationScreen({super.key, required this.user, required this.roleColor});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late NotificationController notificationController;

  @override
  void initState() {
    super.initState();
    notificationController = Get.find<NotificationController>();

    // Fetch notifications when screen loads
    if (widget.user?.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notificationController.fetchNotifications(userId: widget.user!.id);
      });
    }
  }

  // Helper method to check if user is in recipients (handles both formats)
  bool _isUserInRecipients(NotificationModel notification, String userId) {
    // Check recipient IDs first (from update API)
    if (notification.recipientIds.isNotEmpty) {
      return notification.recipientIds.contains(userId);
    }
    // Check recipient objects (from fetch API)
    return notification.recipients.any((recipient) => recipient.id == userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: widget.roleColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.user?.id != null) {
                notificationController.fetchNotifications(
                  userId: widget.user!.id,
                );
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (notificationController.isLoading.value) {
          return _buildLoadingState();
        }

        if (notificationController.errorMessage.isNotEmpty) {
          return _buildErrorState(notificationController);
        }

        // Filter notifications for current user using the helper method
        final userNotifications = notificationController.notifications
            .where(
              (notification) =>
                  widget.user?.id != null &&
                  _isUserInRecipients(notification, widget.user!.id),
            )
            .toList();

        if (userNotifications.isEmpty) {
          return _buildEmptyState();
        }

        return _buildNotificationList(userNotifications);
      }),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(NotificationController controller) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: const TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.user?.id != null) {
                  controller.fetchNotifications(userId: widget.user!.id);
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 50,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any notifications yet.',
              style: TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> userNotifications) {
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.user?.id != null) {
          await notificationController.fetchNotifications(
            userId: widget.user!.id,
          );
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: userNotifications.length,
        itemBuilder: (context, index) {
          final notification = userNotifications[index];
          return _buildNotificationCard(notification, notificationController);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    NotificationController controller,
  ) {
    final isRead = notification.isReadByUser(widget.user!.id);
    final icon = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);
    final userStatus = notification.getStatusForUser(widget.user!.id);
    final statusColor = _getColorForStatus(userStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            // Mark notification as read if it's currently unread
            if (!isRead) {
              controller.markNotificationAsRead(
                notification.id,
                widget.user!.id,
              );
            }
            final CourseController courseController = Get.put(
              CourseController(),
            );
            await courseController.fetchCourses();
            // Navigate to CourseTestQuizScreen if notification has courseId
            if (notification.data?.courseId != null &&
                notification.data!.courseId.isNotEmpty) {
              // Find the course that matches the notification's courseId
              final targetCourse = courseController.courses.firstWhere(
                (course) => course.id == notification.data!.courseId,
                orElse: () => throw Exception('Course not found'),
              );

              // Navigate to CourseTestQuizScreen with the found course
              try {
                Get.to(() => CourseTestQuizScreen(course: targetCourse));
              } catch (e) {
                // Handle case where course is not found
                Get.snackbar(
                  'Error',
                  'Course not found or not available',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            } else {
              // Handle notifications without courseId - you can customize this behavior
              Get.snackbar(
                'Info',
                'This notification doesn\'t contain course information',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isRead
                    ? Colors.grey.withOpacity(0.2)
                    : color.withOpacity(0.3),
                width: isRead ? 1 : 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isRead
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          // Updated recipient count logic
                          Builder(
                            builder: (context) {
                              int recipientCount = 0;
                              if (notification.recipientIds.isNotEmpty) {
                                recipientCount =
                                    notification.recipientIds.length;
                              } else {
                                recipientCount = notification.recipients.length;
                              }

                              return Text(
                                'To: $recipientCount recipient${recipientCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isRead)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notification.status.toJsonString.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: isRead
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notification.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (notification.data?.courseId != null &&
                    notification.data!.courseId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Course: ${notification.data!.courseId}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.blue.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                if (notification.readAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Read On: ${_formatDateTime(notification.readAt!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Show first few recipients if available (only for full objects)
                if (notification.recipients.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      children: notification.recipients
                          .take(3)
                          .map(
                            (recipient) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                recipient.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return Icons.system_update;
      case 'promotion':
        return Icons.local_offer;
      case 'message':
        return Icons.message;
      case 'alert':
        return Icons.warning;
      case 'test':
        return Icons.quiz;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return Colors.blue;
      case 'promotion':
        return Colors.green;
      case 'message':
        return Colors.purple;
      case 'alert':
        return Colors.red;
      case 'test':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getColorForStatus(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.delivered:
        return Colors.green;
      case NotificationStatus.failed:
        return Colors.red;
      case NotificationStatus.read:
        return Colors.blue;
      case NotificationStatus.sent:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
