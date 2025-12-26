import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'Atlantis Grev',
      'app_subtitle': 'WhatsApp Account Warming',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'close': 'Close',
      'save': 'Save',
      'delete': 'Delete',
      'refresh': 'Refresh',
      
      // Auth Screen
      'login': 'Login',
      'telegram_id': 'Telegram ID',
      'username': 'Username',
      'referral_code': 'Referral Code (Optional)',
      'new_users_registered': 'New users will be automatically registered',
      'login_failed': 'Login failed',
      'fill_all_fields': 'Please fill all required fields',
      
      // Dashboard
      'dashboard': 'Dashboard',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'affiliate_balance': 'Affiliate Balance',
      'total_balance': 'Total Balance',
      'paid_accounts': 'Paid Accounts',
      'active_warming': 'Active Warming',
      'total_accounts': 'Total Accounts',
      'completed': 'Completed',
      'referrals': 'Referrals',
      'earnings': 'Earnings',
      'view_all': 'View All',
      'no_accounts_yet': 'No accounts yet',
      'buy_accounts': 'Buy Accounts',
      'notifications_coming_soon': 'Notifications coming soon',
      
      // Store
      'account_store': 'Account Store',
      'whatsapp_account': 'WhatsApp Account',
      'per_account': 'per account',
      'verified_ready': 'Verified & Ready',
      'automated_warming': '24h Automated Warming',
      'secure_private': 'Secure & Private',
      'support_247': '24/7 Support',
      'select_quantity': 'Select Quantity',
      'accounts': 'accounts',
      'total': 'Total',
      'purchase_now': 'Purchase Now',
      'accounts_added_after_payment': 'Accounts will be added to your dashboard after payment confirmation',
      'invoice_created': 'Payment invoice opened. Complete payment to receive accounts.',
      'failed_create_invoice': 'Failed to create invoice',
      
      // My Accounts
      'my_accounts': 'My Accounts',
      'all': 'All',
      'warming': 'Warming',
      'idle': 'Idle',
      'no_accounts_found': 'No accounts found',
      'purchase_from_store': 'Purchase accounts from the store',
      'error_loading_accounts': 'Error loading accounts',
      
      // Account Details
      'account_details': 'Account Details',
      'warming_progress': 'Warming Progress',
      'created': 'Created',
      'started': 'Started',
      'start_warming': 'Start Warming',
      'pause_warming': 'Pause Warming',
      'resume_warming': 'Resume Warming',
      'stop_warming': 'Stop Warming',
      'warming_logs': 'Warming Logs',
      'no_logs_available': 'No logs available',
      'confirm_start': 'This will start the automated warming process for this account. The process takes approximately 24 hours.',
      'confirm_action': 'Are you sure you want to {} this warming process?',
      'warming_action_success': 'Warming {} successful',
      'warming_action_failed': 'Failed to {} warming',
      'warming_started_success': 'Warming started successfully',
      'warming_start_failed': 'Failed to start warming',
      'failed_load_account': 'Failed to load account',
      
      // Referrals
      'your_referral_code': 'Your Referral Code',
      'copy_link': 'Copy Link',
      'share': 'Share',
      'show_qr_code': 'Show QR Code',
      'referral_qr_code': 'Referral QR Code',
      'how_it_works': 'How it Works',
      'share_link': 'Share your referral link with friends',
      'they_register': 'They register using your link',
      'earn_commission': 'You earn 10% of their purchases',
      'withdraw_anytime': 'Withdraw earnings anytime (min \$0.05)',
      'withdrawal_history': 'Withdrawal History',
      'total_earned': 'Total Earned',
      'referral_link_copied': 'Referral link copied to clipboard',
      'withdraw': 'Withdraw',
      
      // Withdrawal
      'withdrawal': 'Withdrawal',
      'available_balance': 'Available Balance',
      'amount_usdt': 'Amount (USDT)',
      'enter_amount': 'Enter amount to withdraw',
      'wallet_address': 'Wallet Address',
      'enter_wallet_address': 'Enter your USDT wallet address',
      'wallet_helper': 'TRC20/ERC20 USDT address',
      'important': 'Important',
      'check_wallet_warning': 'Please double-check your wallet address. Transactions cannot be reversed.',
      'request_withdrawal': 'Request Withdrawal',
      'withdrawal_processing': 'Withdrawals are processed within 24 hours',
      'withdrawal_submitted': 'Withdrawal request submitted successfully',
      'withdrawal_failed': 'Withdrawal failed',
      'please_enter_amount': 'Please enter amount',
      'invalid_amount': 'Invalid amount',
      'minimum_withdrawal': 'Minimum withdrawal is \${}',
      'maximum_withdrawal': 'Maximum withdrawal is \${}',
      'insufficient_balance': 'Insufficient balance',
      'please_enter_wallet': 'Please enter wallet address',
      'invalid_wallet': 'Invalid wallet address',
      
      // Profile
      'language': 'Language',
      'theme': 'Theme',
      'support': 'Support',
      'about': 'About',
      'logout': 'Logout',
      'system_default': 'System default',
      'manage_notifications': 'Manage notification preferences',
      'get_help': 'Get help and support',
      'language_selection_soon': 'Language selection coming soon',
      'theme_selection_soon': 'Theme selection coming soon',
      'notification_settings_soon': 'Notification settings coming soon',
      'support_coming_soon': 'Support coming soon',
      'are_you_sure_logout': 'Are you sure you want to logout?',
      'version': 'Version 1.0.0',
      
      // Bottom Navigation
      'store': 'Store',
    },
    'ru': {
      // Общие
      'app_name': 'Atlantis Grev',
      'app_subtitle': 'Прогрев WhatsApp аккаунтов',
      'loading': 'Загрузка...',
      'error': 'Ошибка',
      'success': 'Успешно',
      'retry': 'Повторить',
      'cancel': 'Отмена',
      'confirm': 'Подтвердить',
      'close': 'Закрыть',
      'save': 'Сохранить',
      'delete': 'Удалить',
      'refresh': 'Обновить',
      
      // Экран входа
      'login': 'Войти',
      'telegram_id': 'Telegram ID',
      'username': 'Имя пользователя',
      'referral_code': 'Реферальный код (необязательно)',
      'new_users_registered': 'Новые пользователи будут зарегистрированы автоматически',
      'login_failed': 'Ошибка входа',
      'fill_all_fields': 'Пожалуйста, заполните все обязательные поля',
      
      // Панель управления
      'dashboard': 'Панель',
      'notifications': 'Уведомления',
      'profile': 'Профиль',
      'affiliate_balance': 'Партнёрский баланс',
      'total_balance': 'Общий баланс',
      'paid_accounts': 'Оплаченные аккаунты',
      'active_warming': 'Активный прогрев',
      'total_accounts': 'Всего аккаунтов',
      'completed': 'Завершено',
      'referrals': 'Рефералы',
      'earnings': 'Заработок',
      'view_all': 'Показать все',
      'no_accounts_yet': 'Нет аккаунтов',
      'buy_accounts': 'Купить аккаунты',
      'notifications_coming_soon': 'Уведомления скоро появятся',
      
      // Магазин
      'account_store': 'Магазин аккаунтов',
      'whatsapp_account': 'WhatsApp аккаунт',
      'per_account': 'за аккаунт',
      'verified_ready': 'Проверено и готово',
      'automated_warming': 'Автоматический прогрев 24ч',
      'secure_private': 'Безопасно и приватно',
      'support_247': 'Поддержка 24/7',
      'select_quantity': 'Выберите количество',
      'accounts': 'аккаунтов',
      'total': 'Итого',
      'purchase_now': 'Купить сейчас',
      'accounts_added_after_payment': 'Аккаунты будут добавлены на вашу панель после подтверждения оплаты',
      'invoice_created': 'Счёт на оплату открыт. Завершите оплату для получения аккаунтов.',
      'failed_create_invoice': 'Не удалось создать счёт',
      
      // Мои аккаунты
      'my_accounts': 'Мои аккаунты',
      'all': 'Все',
      'warming': 'Прогрев',
      'idle': 'Ожидание',
      'no_accounts_found': 'Аккаунты не найдены',
      'purchase_from_store': 'Купите аккаунты в магазине',
      'error_loading_accounts': 'Ошибка загрузки аккаунтов',
      
      // Детали аккаунта
      'account_details': 'Детали аккаунта',
      'warming_progress': 'Прогресс прогрева',
      'created': 'Создан',
      'started': 'Начат',
      'start_warming': 'Начать прогрев',
      'pause_warming': 'Приостановить прогрев',
      'resume_warming': 'Возобновить прогрев',
      'stop_warming': 'Остановить прогрев',
      'warming_logs': 'Логи прогрева',
      'no_logs_available': 'Логи недоступны',
      'confirm_start': 'Это запустит автоматический процесс прогрева для этого аккаунта. Процесс занимает примерно 24 часа.',
      'confirm_action': 'Вы уверены, что хотите {} этот процесс прогрева?',
      'warming_action_success': 'Прогрев {} успешно',
      'warming_action_failed': 'Не удалось {} прогрев',
      'warming_started_success': 'Прогрев успешно запущен',
      'warming_start_failed': 'Не удалось запустить прогрев',
      'failed_load_account': 'Не удалось загрузить аккаунт',
      
      // Рефералы
      'your_referral_code': 'Ваш реферальный код',
      'copy_link': 'Скопировать ссылку',
      'share': 'Поделиться',
      'show_qr_code': 'Показать QR код',
      'referral_qr_code': 'QR код реферала',
      'how_it_works': 'Как это работает',
      'share_link': 'Поделитесь реферальной ссылкой с друзьями',
      'they_register': 'Они регистрируются по вашей ссылке',
      'earn_commission': 'Вы зарабатываете 10% с их покупок',
      'withdraw_anytime': 'Выводите заработок в любое время (мин. \$0.05)',
      'withdrawal_history': 'История выводов',
      'total_earned': 'Всего заработано',
      'referral_link_copied': 'Реферальная ссылка скопирована',
      'withdraw': 'Вывести',
      
      // Вывод средств
      'withdrawal': 'Вывод средств',
      'available_balance': 'Доступный баланс',
      'amount_usdt': 'Сумма (USDT)',
      'enter_amount': 'Введите сумму для вывода',
      'wallet_address': 'Адрес кошелька',
      'enter_wallet_address': 'Введите адрес вашего USDT кошелька',
      'wallet_helper': 'TRC20/ERC20 USDT адрес',
      'important': 'Важно',
      'check_wallet_warning': 'Пожалуйста, проверьте адрес кошелька. Транзакции нельзя отменить.',
      'request_withdrawal': 'Запросить вывод',
      'withdrawal_processing': 'Выводы обрабатываются в течение 24 часов',
      'withdrawal_submitted': 'Запрос на вывод успешно отправлен',
      'withdrawal_failed': 'Вывод не удался',
      'please_enter_amount': 'Пожалуйста, введите сумму',
      'invalid_amount': 'Неверная сумма',
      'minimum_withdrawal': 'Минимальная сумма вывода \${}',
      'maximum_withdrawal': 'Максимальная сумма вывода \${}',
      'insufficient_balance': 'Недостаточно средств',
      'please_enter_wallet': 'Пожалуйста, введите адрес кошелька',
      'invalid_wallet': 'Неверный адрес кошелька',
      
      // Профиль
      'language': 'Язык',
      'theme': 'Тема',
      'support': 'Поддержка',
      'about': 'О приложении',
      'logout': 'Выйти',
      'system_default': 'Системная',
      'manage_notifications': 'Управление настройками уведомлений',
      'get_help': 'Получить помощь и поддержку',
      'language_selection_soon': 'Выбор языка скоро появится',
      'theme_selection_soon': 'Выбор темы скоро появится',
      'notification_settings_soon': 'Настройки уведомлений скоро появятся',
      'support_coming_soon': 'Поддержка скоро появится',
      'are_you_sure_logout': 'Вы уверены, что хотите выйти?',
      'version': 'Версия 1.0.0',
      
      // Нижняя навигация
      'store': 'Магазин',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
  
  String get appName => translate('app_name');
  String get appSubtitle => translate('app_subtitle');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get retry => translate('retry');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get close => translate('close');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

