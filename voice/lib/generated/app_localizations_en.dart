// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Voice Autobiography';

  @override
  String get tabDictation => 'Dictation';

  @override
  String get tabRecords => 'Records';

  @override
  String get tabAutobiography => 'Autobiography';

  @override
  String get tabProfile => 'Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get aboutApp => 'About App';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get feedback => 'Feedback';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get user => 'User';

  @override
  String get notLoggedIn => 'Not Logged In';

  @override
  String get statistics => 'Statistics';

  @override
  String get recordCount => 'Records';

  @override
  String get totalDuration => 'Duration';

  @override
  String get wordCount => 'Words';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get foundUnsavedAutobiography => 'Unsaved Autobiography Found';

  @override
  String get restorePrompt =>
      'An unsaved autobiography from your last session was found. Do you want to continue editing?';

  @override
  String get discard => 'Discard';

  @override
  String get continueEdit => 'Continue Editing';

  @override
  String get checkInAutobiography =>
      'Please check and save the generated content in the Autobiography page';

  @override
  String get autobiographyGenerated =>
      '✓ Autobiography generated! Please check and save in the Autobiography page';

  @override
  String get view => 'View';

  @override
  String get loginPhoneTitle => 'Phone Login';

  @override
  String get registerPhoneTitle => 'Phone Register';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get createAccount => 'Create Account';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get phoneHint => 'Enter 11-digit phone number';

  @override
  String get phoneErrorEmpty => 'Please enter phone number';

  @override
  String get phoneErrorInvalid => 'Invalid phone number format';

  @override
  String get codeLabel => 'Verification Code';

  @override
  String get codeHint => 'Enter 4-digit code';

  @override
  String get codeErrorEmpty => 'Please enter verification code';

  @override
  String get codeErrorLength => 'Code must be 4 digits';

  @override
  String get getCode => 'Get Code';

  @override
  String get nicknameLabel => 'Nickname (Optional)';

  @override
  String get nicknameHint => 'Enter nickname';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Register';

  @override
  String get noAccountRegister => 'No account? Register now';

  @override
  String get hasAccountLogin => 'Have an account? Login now';

  @override
  String get agreementText =>
      'Login implies agreement to User Agreement and Privacy Policy';

  @override
  String get codeSent => 'Verification code sent';

  @override
  String get recordsTitle => 'My Records';

  @override
  String selectedCount(Object count) {
    return '$count Selected';
  }

  @override
  String get batchDelete => 'Batch Delete';

  @override
  String get cancelSelection => 'Cancel Selection';

  @override
  String get loadFailed => 'Load Failed';

  @override
  String get retry => 'Retry';

  @override
  String get noRecords => 'No Voice Records';

  @override
  String get startRecordingHint => 'Tap microphone below to start recording';

  @override
  String get searchRecordsHint => 'Search records';

  @override
  String get allTags => 'All';

  @override
  String get filterOptions => 'Filter Options';

  @override
  String get sortDateDesc => 'Date Desc (Newest First)';

  @override
  String get sortDateAsc => 'Date Asc (Oldest First)';

  @override
  String get sortDurationDesc => 'Duration Desc (Longest First)';

  @override
  String get sortDurationAsc => 'Duration Asc (Shortest First)';

  @override
  String get deleteRecordTitle => 'Delete Record';

  @override
  String deleteRecordConfirm(Object title) {
    return 'Are you sure you want to delete \"$title\"? This cannot be undone.';
  }

  @override
  String get batchDeleteTitle => 'Batch Delete';

  @override
  String batchDeleteConfirm(Object count) {
    return 'Are you sure you want to delete $count records? This cannot be undone.';
  }

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get delete => 'Delete';
}
