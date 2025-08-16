import 'package:flutter/material.dart';
import 'package:vanguard/core/di/service_locator.dart';
import 'package:vanguard/core/services/theme_service.dart';
import 'package:vanguard/core/services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final themeService = sl<ThemeService>();
  final notificationService = sl<NotificationService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = themeService.isRTL;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRTL ? 'الإعدادات' : 'Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListenableBuilder(
        listenable: themeService,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context,
                  isRTL ? 'المظهر' : 'Appearance',
                  Icons.palette_outlined,
                ),
                const SizedBox(height: 16),
                _buildThemeModeSelector(context, isRTL),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  isRTL ? 'اللغة والإعدادات المحلية' : 'Language & Locale',
                  Icons.language_outlined,
                ),
                const SizedBox(height: 16),
                _buildLanguageSelector(context, isRTL),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  isRTL ? 'الإشعارات' : 'Notifications',
                  Icons.notifications_outlined,
                ),
                const SizedBox(height: 16),
                _buildNotificationSettings(context, isRTL),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  isRTL ? 'المهام والتحديات' : 'Tasks & Challenges',
                  Icons.task_alt_outlined,
                ),
                const SizedBox(height: 16),
                _buildTaskSettings(context, isRTL),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  isRTL ? 'البيانات' : 'Data',
                  Icons.storage_outlined,
                ),
                const SizedBox(height: 16),
                _buildDataSettings(context, isRTL),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  isRTL ? 'حول التطبيق' : 'About',
                  Icons.info_outline,
                ),
                const SizedBox(height: 16),
                _buildAboutSection(context, isRTL),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            context,
            isRTL ? 'فاتح' : 'Light',
            Icons.light_mode,
            ThemeMode.light,
            isRTL,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            isRTL ? 'داكن' : 'Dark',
            Icons.dark_mode,
            ThemeMode.dark,
            isRTL,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            isRTL ? 'النظام' : 'System',
            Icons.auto_mode,
            ThemeMode.system,
            isRTL,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    ThemeMode mode,
    bool isRTL,
  ) {
    final theme = Theme.of(context);
    final isSelected = themeService.themeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: () => themeService.setThemeMode(mode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildLanguageOption(
            context,
            'العربية',
            '🇸🇦',
            const Locale('ar'),
            isRTL,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildLanguageOption(
            context,
            'English',
            '🇺🇸',
            const Locale('en'),
            isRTL,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String flag,
    Locale locale,
    bool isRTL,
  ) {
    final theme = Theme.of(context);
    final isSelected = themeService.locale.languageCode == locale.languageCode;

    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: () => themeService.setLocale(locale),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(isRTL ? 'تذكيرات المهام' : 'Task Reminders'),
            subtitle: Text(
              isRTL ? 'إشعارات للمهام المستحقة' : 'Notifications for due tasks',
            ),
            value: true, // TODO: Connect to actual setting
            onChanged: (value) {
              // TODO: Implement notification toggle
            },
            secondary: const Icon(Icons.schedule),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          SwitchListTile(
            title: Text(isRTL ? 'إشعارات التحديات' : 'Challenge Notifications'),
            subtitle: Text(
              isRTL ? 'تذكيرات لبدء التحديات' : 'Reminders to start challenges',
            ),
            value: true, // TODO: Connect to actual setting
            onChanged: (value) {
              // TODO: Implement challenge notification toggle
            },
            secondary: const Icon(Icons.emoji_events),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ListTile(
            title: Text(isRTL ? 'أوقات التذكير' : 'Reminder Times'),
            subtitle: Text(
              isRTL
                  ? '15 دقيقة، 5 دقائق قبل الموعد'
                  : '15 minutes, 5 minutes before due',
            ),
            leading: const Icon(Icons.access_time),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show reminder times dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSettings(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(isRTL ? 'التحديات التلقائية' : 'Auto Challenges'),
            subtitle: Text(
              isRTL
                  ? 'اقتراح تحديات للمهام المتأخرة'
                  : 'Suggest challenges for overdue tasks',
            ),
            value: true, // TODO: Connect to actual setting
            onChanged: (value) {
              // TODO: Implement auto challenge toggle
            },
            secondary: const Icon(Icons.auto_awesome),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ListTile(
            title: Text(
                isRTL ? 'مدة التحدي الافتراضية' : 'Default Challenge Duration'),
            subtitle: Text(isRTL ? '10 دقائق' : '10 minutes'),
            leading: const Icon(Icons.timer),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show duration picker
            },
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ListTile(
            title: Text(isRTL ? 'أصوات النجاح' : 'Success Sounds'),
            subtitle: Text(
              isRTL
                  ? 'تشغيل أصوات عند إكمال المهام'
                  : 'Play sounds when completing tasks',
            ),
            leading: const Icon(Icons.volume_up),
            trailing: Switch(
              value: true, // TODO: Connect to actual setting
              onChanged: (value) {
                // TODO: Implement sound toggle
              },
            ),
            onTap: () {
              // TODO: Toggle sound setting
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(isRTL ? 'تصدير البيانات' : 'Export Data'),
            subtitle: Text(
              isRTL
                  ? 'تصدير المهام والإحصائيات'
                  : 'Export tasks and statistics',
            ),
            leading: const Icon(Icons.download),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showExportDialog(context, isRTL);
            },
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ListTile(
            title: Text(isRTL ? 'استيراد البيانات' : 'Import Data'),
            subtitle: Text(
              isRTL ? 'استيراد المهام من ملف' : 'Import tasks from file',
            ),
            leading: const Icon(Icons.upload),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showImportDialog(context, isRTL);
            },
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ListTile(
            title: Text(
              isRTL ? 'مسح جميع البيانات' : 'Clear All Data',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: Text(
              isRTL
                  ? 'حذف جميع المهام والإعدادات'
                  : 'Delete all tasks and settings',
            ),
            leading: Icon(
              Icons.delete_forever,
              color: theme.colorScheme.error,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearDataDialog(context, isRTL);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(isRTL ? 'الإصدار' : 'Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ListTile(
            title: Text(isRTL ? 'المطور' : 'Developer'),
            subtitle: const Text('Dakka Team'),
            leading: const Icon(Icons.code),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ListTile(
            title: Text(isRTL ? 'سياسة الخصوصية' : 'Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ListTile(
            title: Text(isRTL ? 'شروط الاستخدام' : 'Terms of Service'),
            leading: const Icon(Icons.description),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: Open terms of service
            },
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'تصدير البيانات' : 'Export Data'),
        content: Text(
          isRTL
              ? 'سيتم تصدير جميع المهام والإحصائيات إلى ملف JSON'
              : 'All tasks and statistics will be exported to a JSON file',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isRTL
                        ? 'تم تصدير البيانات بنجاح'
                        : 'Data exported successfully',
                  ),
                ),
              );
            },
            child: Text(isRTL ? 'تصدير' : 'Export'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'استيراد البيانات' : 'Import Data'),
        content: Text(
          isRTL
              ? 'اختر ملف JSON لاستيراد المهام'
              : 'Choose a JSON file to import tasks',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement import functionality
            },
            child: Text(isRTL ? 'اختيار ملف' : 'Choose File'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'مسح جميع البيانات' : 'Clear All Data'),
        content: Text(
          isRTL
              ? 'تحذير: هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع المهام والإعدادات نهائياً.'
              : 'Warning: This action cannot be undone. All tasks and settings will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear data functionality
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(isRTL ? 'مسح البيانات' : 'Clear Data'),
          ),
        ],
      ),
    );
  }
}
