// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Fetchy';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonSaveChanges => 'حفظ التغييرات';

  @override
  String get commonDone => 'تم';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonRemove => 'إزالة';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonAdd => 'إضافة';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get commonOpen => 'فتح';

  @override
  String get commonShare => 'مشاركة';

  @override
  String get commonCopy => 'نسخ';

  @override
  String get commonClear => 'مسح';

  @override
  String get commonChoose => 'اختيار';

  @override
  String get commonChange => 'تغيير';

  @override
  String get commonImport => 'استيراد';

  @override
  String get commonTest => 'اختبار';

  @override
  String get commonReset => 'إعادة تعيين';

  @override
  String get commonTryAgain => 'إعادة المحاولة';

  @override
  String get commonAll => 'الكل';

  @override
  String get commonNotSet => 'غير محدد';

  @override
  String get commonNotAvailable => 'غير متاح';

  @override
  String get commonAutomatic => 'تلقائي';

  @override
  String get commonDefaultSettings => 'الإعدادات الافتراضية';

  @override
  String get commonNotAvailableOnDevice => 'غير متاح على هذا الجهاز.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navHistory => 'السجل';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get homeTitle => 'اجلب أي رابط وسائط';

  @override
  String get homeSubtitle => 'الصق رابطًا أو شاركه مع Fetchy.';

  @override
  String get linkFieldHint => 'الصق رابطًا';

  @override
  String get linkFieldClear => 'مسح';

  @override
  String get linkFieldPaste => 'لصق';

  @override
  String get fetch => 'جلب';

  @override
  String get fetching => 'جارٍ جلب معلومات الوسائط...';

  @override
  String get fetchFailed => 'تعذّر جلب هذا الرابط';

  @override
  String get recentDownloads => 'التنزيلات الأخيرة';

  @override
  String get noDownloadsYet => 'لا توجد تنزيلات بعد';

  @override
  String get noDownloadsDescription => 'ستظهر تنزيلاتك هنا.';

  @override
  String get homeSlowFetchMessage =>
      'بعض المواقع تستغرق وقتًا أطول قليلًا في الجلب. يرجى الانتظار، سيظهر المحتوى قريبًا.';

  @override
  String get homeNoSupportedLinkFound => 'لم يتم العثور على رابط فيديو مدعوم.';

  @override
  String get mediaTypeVideoAudio => 'فيديو';

  @override
  String get mediaTypeAudioOnly => 'صوت فقط';

  @override
  String get qualityLabel => 'الجودة';

  @override
  String get resolutionLabel => 'الدقة';

  @override
  String get audioFormatLabel => 'الصيغة';

  @override
  String get qualityTierBestQuality => 'أفضل جودة';

  @override
  String get qualityTierVeryHigh => 'عالية جدًا';

  @override
  String get qualityTierHigh => 'عالية';

  @override
  String get qualityTierMedium => 'متوسطة';

  @override
  String get qualityTierLow => 'منخفضة';

  @override
  String get qualityTierVeryLow => 'منخفضة جدًا';

  @override
  String get download => 'تنزيل';

  @override
  String get downloadOptionsSaved => 'تم حفظ خياراتك.';

  @override
  String get homeTagline => 'الصق أي رابط وسيجلب لك Fetchy الوسائط.';

  @override
  String get downloadStarting => 'جارٍ بدء التنزيل...';

  @override
  String get downloadWillStartSoon => 'سيبدأ التنزيل قريبًا';

  @override
  String get downloading => 'جارٍ التنزيل';

  @override
  String get merging => 'جارٍ دمج الفيديو والصوت...';

  @override
  String get downloadComplete => 'اكتمل التنزيل';

  @override
  String get downloadFailed => 'فشل التنزيل';

  @override
  String get downloadCanceled => 'أُلغي التنزيل';

  @override
  String savedToPath(String path) {
    return 'حُفظ في: $path';
  }

  @override
  String get couldNotOpenFile => 'تعذّر فتح هذا الملف.';

  @override
  String get couldNotShareFile => 'تعذّرت مشاركة هذا الملف.';

  @override
  String get summaryLabelFormat => 'الصيغة';

  @override
  String get summaryLabelBitrate => 'معدل البت';

  @override
  String get summaryLabelMetadata => 'البيانات الوصفية';

  @override
  String get summaryLabelArtwork => 'الغلاف';

  @override
  String get summaryLabelQuality => 'الجودة';

  @override
  String get summaryLabelFps => 'معدل الإطارات';

  @override
  String get summaryLabelAudio => 'الصوت';

  @override
  String get summaryLabelSubtitles => 'الترجمة';

  @override
  String get summaryLabelSize => 'الحجم';

  @override
  String get summaryValueSource => 'من المصدر';

  @override
  String get summaryValueCustom => 'مخصص';

  @override
  String get summaryValueIncluded => 'متضمن';

  @override
  String get summaryValueNone => 'بلا';

  @override
  String get sizeUnavailable => 'الحجم غير معروف';

  @override
  String get qualityUnavailable => 'الجودة غير معروفة';

  @override
  String convertToFormat(String format) {
    return 'تحويل إلى $format';
  }

  @override
  String sizeDownloadedSuffix(String size) {
    return 'تم تنزيل $size';
  }

  @override
  String get downloadOptionsTitle => 'خيارات التنزيل';

  @override
  String get downloadOptionsAudioSubtitle =>
      'يمكنك تعديل عنوان الأغنية والفنان والألبوم لهذا التنزيل، إن أردت.';

  @override
  String get downloadOptionsVideoSubtitle =>
      'يمكنك تعديل اسم الملف الذي سيُحفظ به هذا الفيديو، إن أردت.';

  @override
  String get audioGroupTitle => 'الصوت';

  @override
  String get videoGroupTitle => 'الفيديو';

  @override
  String get pullInfo => 'سحب المعلومات';

  @override
  String get songTitleLabel => 'عنوان الأغنية';

  @override
  String get artistLabel => 'الفنان';

  @override
  String get albumLabel => 'الألبوم';

  @override
  String get filenameLabel => 'اسم الملف';

  @override
  String get thumbnailLabel => 'الصورة المصغرة';

  @override
  String get artworkNone => 'بلا';

  @override
  String get artworkSource => 'من المصدر';

  @override
  String get artworkCustom => 'مخصصة';

  @override
  String get artworkSourceSelected => 'غلاف من المصدر';

  @override
  String get artworkCustomSelected => 'صورة مخصصة';

  @override
  String get artworkRemoveTooltip => 'إزالة';

  @override
  String get artworkNoSourceThumbnail =>
      'لا تحتوي هذه الوسائط على صورة مصغرة من المصدر لاستخدامها.';

  @override
  String get artworkCouldNotUseImage => 'تعذّر استخدام هذه الصورة.';

  @override
  String get artworkSourceSelectedMessage => 'تم اختيار الغلاف من المصدر.';

  @override
  String get artworkImageSelectedMessage => 'تم اختيار الصورة.';

  @override
  String get pullInfoNoUsableMetadata =>
      'لا تحتوي هذه الوسائط على بيانات موسيقية يمكن استخدامها.';

  @override
  String get pullInfoPartial => 'توفّر بعض المعلومات فقط، وتم تعبئتها.';

  @override
  String get pullInfoFilledIn => 'تمت تعبئة البيانات الوصفية من المصدر.';

  @override
  String get pullInfoReadError =>
      'تعذّرت قراءة البيانات الوصفية من هذه الوسائط.';

  @override
  String get advancedOptions => 'خيارات متقدمة';

  @override
  String get useAutomatic => 'استخدام التلقائي';

  @override
  String get formatLabel => 'الصيغة';

  @override
  String get qualityPickerLabel => 'الجودة';

  @override
  String get subtitlesLabel => 'الترجمة';

  @override
  String get bitrateLabel => 'معدل البت';

  @override
  String get bitrateBest => 'الأفضل';

  @override
  String bitrateKbps(int value) {
    return '$value kbps';
  }

  @override
  String get includeAudioLabel => 'تضمين الصوت';

  @override
  String get includeAudioOnDescription =>
      'يتم تنزيل الفيديو مع الصوت، كالمعتاد.';

  @override
  String get includeAudioOffDescription => 'يتم تنزيل الفيديو فقط، بدون صوت.';

  @override
  String get noAudioTag => 'بدون صوت';

  @override
  String get subtitlesTag => 'ترجمة';

  @override
  String get automaticRecommended => 'تلقائي (موصى به)';

  @override
  String get noCreatorSubtitlesAvailable => 'لا تتوفر ترجمة من صاحب المحتوى';

  @override
  String get autoGeneratedSubtitles => 'ترجمة تلقائية';

  @override
  String get fpsNotAvailable => 'غير متاح';

  @override
  String get subtitlesOff => 'إيقاف';

  @override
  String get activeTagFormatQuality => 'الصيغة والجودة';

  @override
  String get activeTagFormatBitrate => 'الصيغة ومعدل البت';

  @override
  String get engineTitle => 'المحرك';

  @override
  String get engineYtDlpLabel => 'yt-dlp';

  @override
  String engineCurrentVersion(String version) {
    return 'الإصدار الحالي: $version';
  }

  @override
  String get engineCheckingVersion => 'جارٍ التحقق من الإصدار…';

  @override
  String get engineVersionUnknown => 'غير معروف';

  @override
  String get engineBundledInfo => 'yt-dlp (مضمّن) عبر youtubedl-android';

  @override
  String get engineCheckForUpdates => 'التحقق من التحديثات';

  @override
  String get engineUpdating => 'جارٍ التحديث…';

  @override
  String get engineUpdatingStatus => 'جارٍ تحديث yt-dlp…';

  @override
  String get engineAlreadyUpToDate => 'yt-dlp محدّث بالفعل.';

  @override
  String get engineUpdatedSuccessfully => 'تم تحديث yt-dlp بنجاح.';

  @override
  String get engineVerificationFailed =>
      'تم تحديث yt-dlp، لكن تعذّر التحقق من الإصدار الجديد.';

  @override
  String get engineUpdateFailed => 'فشل تحديث yt-dlp.';

  @override
  String get appVersionLabel => 'إصدار التطبيق';

  @override
  String get quickFetchTitle => 'الجلب السريع';

  @override
  String get quickFetchMasterDescription =>
      'اكتشاف الروابط المنسوخة المدعومة تلقائيًا.';

  @override
  String get quickFetchIntro =>
      'يكتشف روابط الفيديو التي تنسخها من التطبيقات المدعومة، ويمنحك طريقة سريعة لجلبها.';

  @override
  String get quickFetchEnableTitle => 'تفعيل الجلب السريع';

  @override
  String get quickFetchOnDescription =>
      'مفعّل، Fetchy يراقب النسخ في التطبيقات المدعومة.';

  @override
  String get quickFetchOffDescription =>
      'غير مفعّل، لن يطّلع Fetchy على الحافظة إطلاقًا.';

  @override
  String get quickFetchActionStyleTitle => 'طريقة التنبيه';

  @override
  String get quickFetchStyleNotification => 'إشعار';

  @override
  String get quickFetchStyleFloatingDot => 'نقطة عائمة';

  @override
  String get quickFetchStyleNotificationDescription =>
      'يستخدم إشعارات أندرويد.';

  @override
  String get quickFetchStyleOverlayDescription =>
      'يتطلب إذن الظهور فوق التطبيقات الأخرى.';

  @override
  String get quickFetchStatusTitle => 'الحالة';

  @override
  String get quickFetchBackgroundEnabledTitle => 'الكشف في الخلفية: مفعّل';

  @override
  String get quickFetchBackgroundEnabledMessage =>
      'سينتبه Fetchy عندما تنسخ رابطًا من تطبيق مدعوم.';

  @override
  String get quickFetchBackgroundDisabledTitle => 'الكشف في الخلفية: غير مفعّل';

  @override
  String get quickFetchBackgroundDisabledMessage =>
      'يستخدم الجلب السريع خدمة إمكانية الوصول فقط لاكتشاف عمليات النسخ في التطبيقات المدعومة. لا يقرأ Fetchy الحافظة إلا بعد أن تضغط على إجراء الجلب السريع.\n\nبدون هذا الإذن، لا يزال بإمكانك مشاركة رابط مع Fetchy أو لصقه في الشاشة الرئيسية.\n\nإذا ظهرت لك قائمة بدلًا من فتح Fetchy مباشرة، اضغط على التطبيقات التي تم تنزيلها ← Fetchy ← وفعّله.';

  @override
  String get quickFetchEnableAccessibility => 'تفعيل كشف إمكانية الوصول';

  @override
  String get quickFetchNotificationAllowedTitle => 'الإشعارات: مسموح بها';

  @override
  String get quickFetchNotificationAllowedMessage =>
      'تظهر عمليات النسخ المكتشفة كإشعار.';

  @override
  String get quickFetchNotificationNotAllowedTitle =>
      'الإشعارات: غير مسموح بها';

  @override
  String get quickFetchNotificationNotAllowedMessage =>
      'يحتاج وضع الإشعارات إذنًا لإرسال الإشعارات، وإلا فلن يظهر أي إجراء سريع.';

  @override
  String get quickFetchOpenNotificationSettings => 'فتح إعدادات الإشعارات';

  @override
  String get quickFetchOverlayAllowedTitle => 'النافذة العائمة: مسموح بها';

  @override
  String get quickFetchOverlayAllowedMessage =>
      'تظهر نقطة صغيرة فوق التطبيقات الأخرى عند اكتشاف نسخ، وتختفي بعد استخدامها أو تجاهلها.';

  @override
  String get quickFetchOverlayNotAllowedTitle =>
      'النافذة العائمة: غير مسموح بها';

  @override
  String get quickFetchOverlayNotAllowedMessage =>
      'تحتاج النقطة العائمة إذنًا للظهور فوق التطبيقات الأخرى. وإلى أن يُمنح، يعتمد Fetchy على الإشعارات بدلًا منها.';

  @override
  String get quickFetchEnableOverlay => 'تفعيل الظهور فوق التطبيقات الأخرى';

  @override
  String get quickFetchHowItWorksTitle => 'كيف يعمل';

  @override
  String get quickFetchHowItWorks1 =>
      'تكتشف إمكانية الوصول فقط أنك قمت بعملية نسخ داخل تطبيق مدعوم، ومن أي تطبيق كان ذلك.';

  @override
  String get quickFetchHowItWorks2 =>
      'لا يسمح أندرويد لأي تطبيق بقراءة الحافظة في الخلفية، ولا يحاول Fetchy ذلك. تُقرأ الحافظة مرة واحدة فقط، بعد ضغطك على الإجراء السريع وFetchy مفتوح.';

  @override
  String get quickFetchHowItWorks3 =>
      'لا يُقبل إلا المواقع المراقَبة أدناه. أي شيء آخر يُتجاهل، وتصلك رسالة بأنه لم يُعثر على رابط.';

  @override
  String get quickFetchHowItWorks4 =>
      'نسخ رابط لا يبدأ التنزيل أبدًا. لا شيء يحدث إلى أن تضغط، وتظل أنت من يختار الجودة.';

  @override
  String get quickFetchHowItWorks5 =>
      'لا يُرفع أي شيء إلى أي مكان. لا يُحفظ أي نص منسوخ.';

  @override
  String get quickFetchWatchedSitesTitle => 'المواقع المراقبة';

  @override
  String get quickFetchNoSitesWatched =>
      'لا توجد مواقع مراقَبة. اضغط تعديل لإضافة واحد.';

  @override
  String get quickFetchWatchedSitesFooter =>
      'تعديل هذه القائمة يغيّر ما يكتشفه الجلب السريع، بما في ذلك المواقع المدمجة أعلاه.';

  @override
  String get quickFetchConsentTitle => 'تفعيل الجلب السريع؟';

  @override
  String get quickFetchConsent1 =>
      'ينتبه الجلب السريع عندما تنسخ رابطًا من تطبيق مدعوم، ويعرض عليك طريقة سريعة لجلبه.';

  @override
  String get quickFetchConsent2 =>
      'يحتاج إذن إمكانية الوصول لاكتشاف عمليات النسخ في الخلفية. هذا الإذن يخبر Fetchy فقط أنك نسخت شيئًا، ومن أي تطبيق. لا يمكنه قراءة حافظتك في الخلفية، ولا يقرأ شاشتك إطلاقًا.';

  @override
  String get quickFetchConsent3 =>
      'لا تُقرأ حافظتك إلا بعد ضغطك على الإجراء، وFetchy مفتوح أمامك. لا شيء يُرفع أبدًا.';

  @override
  String get quickFetchConsent4 =>
      'يستهلك الكشف في الخلفية قدرًا بسيطًا من البطارية.';

  @override
  String get quickFetchTurnOn => 'تفعيل';

  @override
  String get watchedDomainsEditTitle => 'تعديل المواقع المراقبة';

  @override
  String get watchedDomainsOnePerLine => 'أدخل نطاقًا واحدًا في كل سطر.';

  @override
  String get watchedDomainsAddUrl => 'إضافة رابط';

  @override
  String get watchedDomainsExampleHint => 'example.com';

  @override
  String get watchedDomainsInvalidDomain => 'هذا لا يبدو نطاق موقع صحيحًا.';

  @override
  String get watchedDomainsResetToDefaults => 'استعادة الإعدادات الافتراضية';

  @override
  String get watchedDomainsResetConfirmTitle => 'استعادة الإعدادات الافتراضية؟';

  @override
  String get watchedDomainsResetConfirmBody =>
      'سيؤدي هذا إلى تجاهل أي مواقع أضفتها أو أزلتها، واستعادة القائمة المدمجة.';

  @override
  String get watchedDomainsDiscardTitle => 'تجاهل التغييرات؟';

  @override
  String get watchedDomainsDiscardBody => 'لم يتم حفظ تعديلاتك.';

  @override
  String get watchedDomainsKeepEditing => 'متابعة التعديل';

  @override
  String get watchedDomainsDiscard => 'تجاهل';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get sectionAppearance => 'المظهر';

  @override
  String get themeLabel => 'السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get sectionDownloads => 'التنزيلات';

  @override
  String get downloadLocationTitle => 'موقع التنزيل';

  @override
  String get sectionAccounts => 'الحسابات';

  @override
  String get connectedAccountsTitle => 'الحسابات المتصلة / الجلسات';

  @override
  String get connectedAccountsSubtitle =>
      'اختياري: اربط جلسة منصة للمحتوى الذي يتطلب حسابًا.';

  @override
  String get sectionHistory => 'السجل';

  @override
  String get historySaveEnabled => 'حفظ سجل التنزيلات';

  @override
  String get historySaveDescription => 'الاحتفاظ بسجل محلي لتنزيلاتك.';

  @override
  String get historyClearAction => 'مسح السجل';

  @override
  String get sectionAdvanced => 'متقدم';

  @override
  String get rootFeaturesTitle => 'ميزات الروت';

  @override
  String get rootFeaturesComingSoon => 'قريبًا، غير متاح بعد.';

  @override
  String get sectionDiagnostics => 'التشخيص';

  @override
  String get technicalInformationTitle => 'معلومات تقنية';

  @override
  String get technicalInformationSubtitle =>
      'قيود المنصات المعروفة، ومعلومات المطوّرين، وما يجب فعله عند فشل التنزيل.';

  @override
  String get sectionAbout => 'حول التطبيق';

  @override
  String downloadLocationSummary(
    String organization,
    String video,
    String audio,
  ) {
    return '$organization · الفيديو: $video · الصوت: $audio';
  }

  @override
  String get engineTileTitle => 'المحرك';

  @override
  String get diagnosticsLimitationsTitle => 'القيود';

  @override
  String get diagnosticsLimitationsBody =>
      'قد يفشل التنزيل لعدة أسباب:\n1. يتطلب الموقع تسجيل الدخول.\n2. المحتوى مقيّد.\n3. يحظر الموقع هذا النوع من الطلبات مؤقتًا.\n4. هذا النوع من المحتوى غير مدعوم بالكامل بعد.\n\nقد يساعد تسجيل الدخول أو إضافة الكوكيز أحيانًا، لكنه لن يجعل كل فيديو قابلًا للتنزيل.';

  @override
  String get diagnosticsDeveloperInfoTitle => 'معلومات المطوّرين';

  @override
  String get diagnosticsDeveloperInfoSubtitle =>
      'للمستخدمين المتقدمين الذين يبحثون في مشاكل الاستخراج.';

  @override
  String get diagnosticsSessionsPrivacy =>
      'تُحفظ الجلسات محليًا على هذا الجهاز، ومشفّرة بحماية Android Keystore. لا يملك Fetchy خادمًا، ولا يرفع الجلسات أو الكوكيز إلى أي مكان.';

  @override
  String get diagnosticsUpstreamResourcesTitle => 'موارد المشروع الأصلي';

  @override
  String get diagnosticsEngineFindInSettings =>
      'ستجدها في الإعدادات، ضمن المحرك.';

  @override
  String get diagnosticsEngineFfmpegBundled => 'مضمّن مع التطبيق';

  @override
  String get developerInfoTitle => 'معلومات المطوّرين';

  @override
  String get developerInfoIntro =>
      'للمستخدمين المتقدمين الذين يبحثون في مشاكل الاستخراج. يمكن لصق هذا بأمان في تقرير مشكلة على GitHub.';

  @override
  String get developerInfoEmptyState =>
      'لا يوجد فشل جلب حديث لعرضه. تظهر التفاصيل هنا بعد فشل عملية جلب، عند فتح هذه الصفحة من زر المعلومات الخاص بالفشل.';

  @override
  String get developerInfoCopyTechnicalDetails => 'نسخ التفاصيل التقنية';

  @override
  String get developerInfoTechnicalDetailsCopied => 'تم نسخ التفاصيل التقنية.';

  @override
  String get developerInfoPlatformLabel => 'المنصة';

  @override
  String get developerInfoExtractorLabel => 'المستخرج';

  @override
  String get developerInfoVersionLabel => 'إصدار yt-dlp';

  @override
  String get developerInfoAppVersionLabel => 'إصدار التطبيق';

  @override
  String get developerInfoErrorCategoryLabel => 'فئة الخطأ';

  @override
  String get developerInfoSanitizedMessageTitle => 'الرسالة';

  @override
  String get developerInfoKnownLimitationTitle => 'القيد المعروف ذو الصلة';

  @override
  String get developerInfoUpstreamIssueTitle =>
      'مشكلة محتملة في المشروع الأصلي';

  @override
  String get developerInfoDetailTitle => 'التفاصيل';

  @override
  String get developerInfoNoAdditionalDetail => '(لا توجد تفاصيل إضافية)';

  @override
  String get developerInfoNotApplicable => 'غير قابل للتطبيق';

  @override
  String developerInfoUpstreamIssueHint(String url) {
    return 'قد يكون هذا قيدًا معروفًا في yt-dlp. راجع $url';
  }

  @override
  String get developerInfoUnknown => 'غير معروف';

  @override
  String get errorMorePossibleReasons => 'الأسباب المحتملة';

  @override
  String get errorMoreInformation => 'مزيد من المعلومات';

  @override
  String get errorSettingsPointer => 'الإعدادات ← معلومات تقنية';

  @override
  String get errorDeveloperInformation => 'معلومات المطوّرين';

  @override
  String get errorWhy => 'لماذا؟';

  @override
  String get errorConnectedAccounts => 'الحسابات المتصلة';

  @override
  String get errorImportSession => 'استيراد جلسة';

  @override
  String get errorReconnect => 'إعادة الاتصال';

  @override
  String get errorTitleAuthRequired => 'قد يتطلب الأمر تسجيل الدخول';

  @override
  String get errorTitleSessionExpired => 'قد تكون جلستك منتهية الصلاحية';

  @override
  String get errorTitleSessionInvalid => 'قد لا تكون جلستك صالحة بعد الآن';

  @override
  String get errorTitlePlatformRestricted => 'هذا المحتوى مقيّد';

  @override
  String get errorTitleAntiBot => 'المنصة تحظر هذا الطلب';

  @override
  String get errorTitleNetworkError => 'تعذّر الوصول إلى المنصة';

  @override
  String get errorTitleUnsupported => 'هذا الرابط غير مدعوم';

  @override
  String get errorTitleExtractorError => 'تعذّرت معالجة هذه الوسائط';

  @override
  String get errorTitleUnknown => 'حدث خطأ ما';

  @override
  String get errorReasonAuthRequired1 => 'قد يتطلب هذا المحتوى تسجيل الدخول.';

  @override
  String errorReasonAuthRequired2(String subject) {
    return 'قد تقصر $subject الوصول إليه على الحسابات المسجّلة.';
  }

  @override
  String get errorReasonAuthRequired3 =>
      'قد يساعد تسجيل الدخول مع بعض المحتوى المقيّد، لكنه لا يضمن الوصول.';

  @override
  String get errorReasonSessionExpired1 =>
      'قد تكون جلستك المحفوظة منتهية الصلاحية.';

  @override
  String errorReasonSessionExpired2(String subject) {
    return 'من المحتمل أن تكون $subject قد أنهت الجلسة.';
  }

  @override
  String errorReasonSessionInvalid1(String subject) {
    return 'قد لا تحمل هذه الجلسة المحفوظة صلاحية الوصول المناسبة لـ$subject بعد الآن.';
  }

  @override
  String get errorReasonSessionInvalid2 =>
      'ربما تم إبطالها أو استبدالها بتسجيل دخول أحدث في مكان آخر.';

  @override
  String get errorReasonPlatformRestricted1 =>
      'من المحتمل أن يكون المحتوى قد أُزيل أو أصبح خاصًا.';

  @override
  String get errorReasonPlatformRestricted2 => 'قد يكون مقيّدًا في منطقتك.';

  @override
  String errorReasonPlatformRestricted3(String subject) {
    return 'من المحتمل أن تكون $subject قد أزالته لسبب يتعلق بالسياسات.';
  }

  @override
  String errorReasonAntiBot1(String subject) {
    return 'قد تكون $subject تحدّ من هذا النوع من الطلبات أو تتحقق منه.';
  }

  @override
  String get errorReasonAntiBot2 => 'غالبًا ما يكون هذا مؤقتًا.';

  @override
  String get errorReasonAntiBot3 =>
      'هذا قيد في نظام الحماية الخاص بالمنصة. قد لا يحل تسجيل الدخول هذه المشكلة.';

  @override
  String errorReasonImpersonation1(String subject) {
    return 'من المحتمل أن تكون $subject قد غيّرت طريقة تسليم المحتوى.';
  }

  @override
  String get errorReasonImpersonation2 =>
      'هذا قيد في بيئة التشغيل، وليس مشكلة في الحساب أو المحتوى.';

  @override
  String get errorReasonNetwork1 => 'قد يكون جهازك غير متصل بالإنترنت.';

  @override
  String errorReasonNetwork2(String subject) {
    return 'قد تكون خوادم $subject غير متاحة مؤقتًا.';
  }

  @override
  String get errorReasonUnsupported1 => 'صيغة هذا الرابط غير مدعومة حاليًا.';

  @override
  String errorReasonExtractor1(String subject) {
    return 'من المحتمل أن تكون $subject قد غيّرت طريقة تسليم هذا المحتوى.';
  }

  @override
  String get errorReasonExtractor2 =>
      'قد تُحل هذه المشكلة تلقائيًا عند إعادة المحاولة.';

  @override
  String errorReasonUnknown1(String subject) {
    return 'قد تحتاج $subject تسجيل الدخول.';
  }

  @override
  String get errorReasonUnknown2 => 'قد يكون المحتوى مقيّدًا.';

  @override
  String errorReasonUnknown3(String subject) {
    return 'قد تحظر $subject هذا الطلب مؤقتًا.';
  }

  @override
  String get errorReasonUnknown4 =>
      'قد لا يكون هذا النوع من المحتوى مدعومًا بعد.';

  @override
  String get errorReasonUnknown5 =>
      'قد يساعد تسجيل الدخول أو إضافة الكوكيز، لكن ليس دائمًا.';

  @override
  String get errorLimitationAuthRequired =>
      'يتطلب المستخرج جلسة موثّقة لهذا المحتوى، ولا توجد جلسة مرفقة.';

  @override
  String get errorLimitationSessionExpired =>
      'يبدو أن كوكيز الجلسة المرفقة منتهية الصلاحية.';

  @override
  String get errorLimitationSessionInvalid =>
      'يتم رفض كوكيز الجلسة المرفقة باعتبارها غير صالحة.';

  @override
  String get errorLimitationPlatformRestricted =>
      'تُبلغ المنصة أن هذا المحتوى غير متاح (أُزيل، أو خاص، أو مقيّد جغرافيًا).';

  @override
  String get errorLimitationAntiBot =>
      'رفض نظام كشف الروبوتات أو تحديد المعدل الخاص بالمنصة هذا الطلب.';

  @override
  String get errorLimitationImpersonation =>
      'يتطلب هذا المستخرج محاكاة عميل TLS (curl_cffi) غير متوفرة في هذا الإصدار.';

  @override
  String get errorLimitationNetwork =>
      'تعذّر وصول الطلب إلى المنصة (مشكلة اتصال أو DNS).';

  @override
  String get errorLimitationUnsupported =>
      'لا يتعرف أي مستخرج في نسخة yt-dlp هذه على هذا الرابط.';

  @override
  String get errorLimitationExtractor =>
      'لم تكن صيغة صفحة أو استجابة المنصة كما توقّعها المستخرج، على الأرجح بسبب تغيير حديث من جهة المنصة.';

  @override
  String get errorLimitationUnknown => 'لم يتطابق نص الفشل مع أي فئة معروفة.';

  @override
  String get errorMessageAuthRequiredGeneric =>
      'قد يتطلب هذا المحتوى تسجيل الدخول.';

  @override
  String get errorMessageAuthRequiredTikTok =>
      'هذا المقطع من TikTok مقيّد أو يتطلب تسجيل الدخول.';

  @override
  String get errorMessageSessionExpired =>
      'قد تكون جلستك المحفوظة منتهية الصلاحية. أعد الاتصال وحاول مرة أخرى.';

  @override
  String get errorMessageSessionInvalid => 'هذه الجلسة المحفوظة لم تعد صالحة.';

  @override
  String errorMessageImpersonationWithPlatform(String platform) {
    return 'تعذّر على $platform توفير هذا الفيديو الآن.';
  }

  @override
  String get errorMessageImpersonationGeneric => 'تعذّر جلب هذا الفيديو الآن.';

  @override
  String get errorMessageAntiBot => 'تحظر المنصة حاليًا هذا النوع من الطلبات.';

  @override
  String get errorMessagePlatformRestricted =>
      'هذا المحتوى مقيّد من قبل المنصة.';

  @override
  String errorMessageNetworkWithPlatform(String platform) {
    return 'تعذّر الوصول إلى $platform. تحقق من اتصالك وحاول مرة أخرى.';
  }

  @override
  String get errorMessageNetworkGeneric =>
      'تعذّر الوصول إلى الخادم. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get errorMessageUnsupportedTikTok => 'رابط TikTok هذا غير مدعوم.';

  @override
  String errorMessageUnsupportedWithSubject(String subject) {
    return '$subject غير مدعومة.';
  }

  @override
  String get errorMessageExtractor => 'تعذّر استخراج هذا الآن.';

  @override
  String errorMessageUnknownEmpty(String subject) {
    return 'تعذّر جلب $subject.';
  }

  @override
  String get errorMessageUnknownGeneric => 'حدث خطأ ما أثناء جلب هذه الوسائط.';

  @override
  String get errorSubjectFallback => 'المنصة';

  @override
  String get errorSubjectThisLink => 'هذا الرابط';

  @override
  String get upstreamYtDlpRepo => 'مستودع GitHub';

  @override
  String get upstreamYtDlpIssues => 'الإبلاغ عن مشكلة';

  @override
  String get upstreamDocumentation => 'الوثائق';

  @override
  String get sessionsPageTitle => 'الحسابات المتصلة';

  @override
  String get sessionsPrivacyNotice =>
      'يعمل Fetchy بلا اتصال أولًا. تُحفظ جلساتك محليًا على هذا الجهاز. لا يرفع Fetchy جلساتك إلى أي خادم خاص به.\n\nقد تساعد الجلسة المتصلة في الوصول إلى المحتوى الذي يتطلب حسابًا، لكنها لا تتجاوز كل قيود المنصة.';

  @override
  String get sessionsPlatformsSection => 'المنصات';

  @override
  String get sessionsOtherSitesSection => 'مواقع أخرى';

  @override
  String get sessionsNoCustomSites => 'لا توجد مواقع مخصصة بعد.';

  @override
  String get sessionsAddCookiesForOtherSites => 'إضافة كوكيز لمواقع أخرى';

  @override
  String get sessionsConnected => 'متصل';

  @override
  String sessionsRemoveSiteConfirmTitle(String domain) {
    return 'إزالة $domain؟';
  }

  @override
  String get sessionsRemoveSiteConfirmBody =>
      'سيؤدي هذا إلى حذف الكوكيز المحفوظة لهذا الموقع من هذا الجهاز بشكل آمن. يمكنك إضافته مرة أخرى في أي وقت.';

  @override
  String get sessionsAddCookiesDialogTitle => 'إضافة كوكيز لمواقع أخرى';

  @override
  String get sessionsEnterWebsite => 'أدخل الموقع الذي تخص هذه الكوكيز.';

  @override
  String get sessionsWebsiteLabel => 'الموقع';

  @override
  String get sessionsWebsiteHint => 'example.com';

  @override
  String sessionsCookiesImportedMessage(String domain) {
    return 'تم استيراد كوكيز $domain.';
  }

  @override
  String get sessionsCouldNotImportCookies => 'تعذّر استيراد هذه الكوكيز.';

  @override
  String sessionsPasteCookiesForWebsite(String website) {
    return 'لصق كوكيز $website';
  }

  @override
  String get sessionsPasteCookiesHelp =>
      'الصق محتوى ملف تصدير cookies.txt بصيغة Netscape، وهو نفس الصيغة التي تنتجها إضافات تصدير الكوكيز من المتصفح.';

  @override
  String get sessionsCookieFileHint => '# Netscape HTTP Cookie File\n...';

  @override
  String sessionsSessionConnectedMessage(String platform) {
    return 'تم الاتصال بجلسة $platform.';
  }

  @override
  String get sessionsCouldNotOpenBrowser => 'تعذّر فتح متصفح لتسجيل الدخول.';

  @override
  String get sessionsBrowserUnconfirmedTitle =>
      'تعذّر على Fetchy التأكد مما حدث في متصفحك';

  @override
  String get sessionsBrowserUnconfirmedBody =>
      'إذا سجّلت الدخول، لا يمكن نقل جلسة المتصفح هذه إلى Fetchy تلقائيًا على هذا الجهاز. لاستخدام ذلك الحساب في Fetchy، استورد كوكيز جلستك عبر خيار متقدم.';

  @override
  String get sessionsNotNow => 'ليس الآن';

  @override
  String get sessionsImportCookiesNow => 'استيراد الكوكيز الآن';

  @override
  String sessionsSessionImportedMessage(String platform) {
    return 'تم استيراد جلسة $platform.';
  }

  @override
  String get sessionsCouldNotImportSession => 'تعذّر استيراد هذه الجلسة.';

  @override
  String get sessionsCouldNotCompleteTest => 'تعذّر إكمال الاختبار.';

  @override
  String get sessionsTestConnectionTitle => 'اختبار الاتصال';

  @override
  String sessionsTestConnectionResultTitle(String platform) {
    return 'اختبار اتصال $platform';
  }

  @override
  String sessionsTestUrlPrompt(String platform) {
    return 'الصق رابط $platform لاختبار هذه الجلسة. هذا مجرد فحص سريع، ولن يُنزَّل أي شيء.';
  }

  @override
  String get sessionsUrlHint => 'https://…';

  @override
  String get sessionsExportSessionTitle => 'تصدير الجلسة؟';

  @override
  String get sessionsExportSessionBody =>
      'يحتوي الملف المُصدَّر على بيانات تسجيل الدخول لحسابك. يمكن لأي شخص يملك هذا الملف الوصول إلى حسابك على هذه المنصة.\n\nلا تشاركه مع أحد. لن يرفعه Fetchy إلى أي مكان أبدًا، وأنت من يختار مكان حفظه.';

  @override
  String get sessionsSessionExported => 'تم تصدير الجلسة.';

  @override
  String get sessionsCouldNotExportSession => 'تعذّر تصدير هذه الجلسة.';

  @override
  String sessionsRemoveSessionConfirmTitle(String platform) {
    return 'إزالة جلسة $platform؟';
  }

  @override
  String get sessionsRemoveSessionConfirmBody =>
      'سيؤدي هذا إلى حذف الجلسة المحفوظة من هذا الجهاز بشكل آمن. يمكنك إعادة الاتصال في أي وقت.';

  @override
  String get sessionsExperimentalTag => 'تجريبي';

  @override
  String get sessionsImportRequiredTag => 'يتطلب استيراد جلسة';

  @override
  String get sessionsNotConnected => 'غير متصل';

  @override
  String get sessionsXBlocksInAppBrowser =>
      'يمنع X نقل الجلسة عبر تسجيل الدخول من المتصفح المدمج إلى تطبيقات مثل Fetchy. استورد ملف cookies.txt أدناه لاستخدام جلسة مسجّلة هنا.';

  @override
  String get sessionsImportCookiesTxtTitle => 'استيراد cookies.txt';

  @override
  String get sessionsImportCookiesTxtSubtitleAvailable =>
      'الطريقة العملية لاستخدام X في Fetchy: صدّر ملف cookies.txt من متصفحك المسجّل دخوله واستورده هنا.';

  @override
  String get sessionsOpenInBrowserTitle => 'فتح في المتصفح';

  @override
  String get sessionsOpenInBrowserSubtitle =>
      'يفتح X في متصفحك المعتاد، للراحة فقط. هذا لا يستورد جلسة إلى Fetchy. استخدم استيراد cookies.txt أعلاه لذلك.';

  @override
  String get sessionsSignInBrowserTitle => 'تسجيل الدخول عبر المتصفح';

  @override
  String get sessionsSignInBrowserTitleExperimental =>
      'تسجيل الدخول عبر المتصفح (تجريبي)';

  @override
  String get sessionsSignInTikTokRedirectWarning =>
      'قد تعيد صفحة تسجيل دخول TikTok توجيهك إلى تطبيق TikTok قبل أن يتمكن Fetchy من التقاط جلسة. إذا حدث هذا، استخدم استيراد الكوكيز/ملف الجلسة أدناه بدلًا من ذلك، فهو يعمل دائمًا.';

  @override
  String sessionsSignInGenericSubtitle(String platform) {
    return 'سجّل الدخول عبر صفحة تسجيل الدخول الخاصة بـ$platform في متصفحك.';
  }

  @override
  String get sessionsImportCookiesFileTitle => 'استيراد الكوكيز / ملف الجلسة';

  @override
  String get sessionsImportCookiesFileSubtitle =>
      'للمستخدمين المتقدمين: استورد ملف تصدير cookies.txt.';

  @override
  String get sessionsRootAssistedTitle => 'استيراد جلسة/متصفح بمساعدة الروت';

  @override
  String sessionsRootAssistedSubtitle(String platform) {
    return 'لا يفك Fetchy تشفير قواعد بيانات Chrome أو المتصفحات الأخرى مباشرة. يتطلب ذلك أدوات متخصصة خاصة بكل جهاز لا يمكن لـFetchy أتمتتها بأمان. إذا استخدمت أداة روت لاستخراج ملف كوكيز لـ$platform، حوّله إلى صيغة cookies.txt وأدخله عبر \'استيراد الكوكيز / ملف الجلسة\' أعلاه، فالنتيجة واحدة في الحالتين.';
  }

  @override
  String get sessionsTestConnectionTileTitle => 'اختبار الاتصال';

  @override
  String get sessionsTestConnectionAvailableSubtitle =>
      'تشغيل فحص سريع باستخدام رابط تقدّمه أنت.';

  @override
  String get sessionsTestConnectionUnavailableSubtitle => 'اربط جلسة أولًا.';

  @override
  String get sessionsExportSessionTileTitle => 'تصدير الجلسة';

  @override
  String get sessionsExportSessionTileSubtitle =>
      'فقط إذا كنت بحاجة صريحة لنسخة. تعامل معها بحذر.';

  @override
  String get sessionsRemoveSessionTileTitle => 'إزالة الجلسة';

  @override
  String get sessionsRemoveSessionTileSubtitle =>
      'يحذف الجلسة المحفوظة من هذا الجهاز بشكل آمن.';

  @override
  String get sessionsCookieSourceTitle => 'مصدر الكوكيز';

  @override
  String sessionsCookieSourcePrompt(String website) {
    return 'كيف تريد إحضار الكوكيز لـ$website؟';
  }

  @override
  String get sessionsImportCookieFileTitle => 'استيراد ملف كوكيز';

  @override
  String get sessionsImportCookieFileSubtitle =>
      'استورد ملف تصدير cookies.txt لهذا الموقع.';

  @override
  String get sessionsPasteCookiesTitle => 'لصق الكوكيز';

  @override
  String get sessionsPasteCookiesSubtitle =>
      'الصق نص كوكيز بصيغة Netscape مباشرة.';

  @override
  String get sessionsStatusConnected => 'متصل';

  @override
  String get sessionsStatusConnectedWorks => 'متصل · الجلسة تعمل';

  @override
  String get sessionsStatusConnectedUnverified =>
      'متصل · تعذّر التحقق من الحالة';

  @override
  String get sessionsStatusExpired => 'منتهية الصلاحية';

  @override
  String get sessionsStatusInvalid => 'غير صالحة';

  @override
  String get sessionsStatusNotConnected => 'غير متصل';

  @override
  String get sessionsStatusImportRequired => 'يتطلب استيراد جلسة';

  @override
  String get sessionsTestWorks => 'الجلسة تعمل في هذا الاختبار.';

  @override
  String sessionsTestStatusUnverified(String message) {
    return 'تعذّر التحقق من حالة الجلسة: $message';
  }

  @override
  String get sessionsCookieFileInvalid => 'تعذّر استخدام هذا الملف كجلسة.';

  @override
  String get sessionsCustomCookieInvalid => 'تعذّر استخدام هذه الكوكيز.';

  @override
  String get sessionWarningTitle => 'ربط جلسة منصة؟';

  @override
  String get sessionWarningBody =>
      'يمكن أن تحتوي جلستك على بيانات تسجيل الدخول لحسابك.\n\nيحفظها Fetchy على هذا الجهاز فقط، وهي مشفّرة.\n\nإذا صدّرت ملف جلسة يومًا، لا تشاركه مع أحد.\n\nربط جلسة لا يضمن أن المحتوى المقيّد أو المحمي سيصبح قابلًا للتنزيل.';

  @override
  String get duplicateDialogTitle => 'تم تنزيله من قبل';

  @override
  String get duplicateDialogBody => 'هذا الملف موجود بالفعل على جهازك:';

  @override
  String get duplicateDialogDownloadAgain => 'إعادة التنزيل';

  @override
  String get duplicateDialogDefaultPath => 'Downloads/Fetchy';

  @override
  String get downloadLocationTitleLabel => 'موقع التنزيل';

  @override
  String get downloadLocationIntro =>
      'اختر مكان حفظ الفيديو والصوت، وهل ينظّمهما Fetchy في مجلداته الخاصة. هذا يغيّر فقط وجهة الملفات؛ اسم الملف والجودة إعدادات منفصلة.';

  @override
  String get downloadLocationVideoLabel => 'الفيديو';

  @override
  String get downloadLocationAudioLabel => 'الصوت';

  @override
  String get downloadLocationBaseFolderTitle => 'المجلد الأساسي';

  @override
  String get downloadLocationVideoLocationTitle => 'موقع الفيديو';

  @override
  String get downloadLocationAudioLocationTitle => 'موقع الصوت';

  @override
  String get downloadLocationSameAsVideo => 'نفس مجلد الفيديو';

  @override
  String get downloadLocationDifferentFolder => 'استخدام مجلد مختلف';

  @override
  String get downloadLocationSameFolderAsVideo => 'نفس مجلد الفيديو';

  @override
  String get downloadLocationFolderInaccessible =>
      'لم يعد الوصول إلى هذا المجلد ممكنًا. اختر مجلدًا جديدًا.';

  @override
  String get downloadLocationNoFolderChosen => 'لم يتم اختيار مجلد';

  @override
  String get downloadLocationChooseFolder => 'اختيار مجلد';

  @override
  String get downloadLocationOrganizationTitle => 'التنظيم';

  @override
  String get downloadLocationUseSubfolders => 'استخدام مجلدات Fetchy الفرعية';

  @override
  String get downloadLocationUseSubfoldersOnDescription =>
      'ينشئ Fetchy مجلدين فرعيين للفيديو والصوت داخل المجلد الأساسي أعلاه.';

  @override
  String get downloadLocationUseSubfoldersOffDescription =>
      'تُحفظ الملفات مباشرة في المجلد الأساسي أعلاه، بدون مجلد فرعي خاص بـFetchy.';

  @override
  String get storageBaseAndroidDefaultLabel => 'مجلدات أندرويد الافتراضية';

  @override
  String get storageBaseAndroidDefaultDescription =>
      'Movies وMusic، نفس المجلدات التي تستخدمها التطبيقات الأخرى.';

  @override
  String get storageBaseCustomLabel => 'مجلد مخصص';

  @override
  String get storageBaseCustomDescription => 'اختر بدقة أين تُحفظ الملفات.';

  @override
  String get storageSelectedFolderFallback => 'المجلد المحدد';

  @override
  String storageVideoLocationCustom(String folder) {
    return '$folder / Videos';
  }

  @override
  String storageAudioLocationCustom(String folder) {
    return '$folder / Audio';
  }

  @override
  String get storageVideoLocationDefaultSubfolders =>
      'Movies / Fetchy / Videos';

  @override
  String get storageVideoLocationDefault => 'Movies';

  @override
  String get storageAudioLocationDefaultSubfolders => 'Music / Fetchy / Audio';

  @override
  String get storageAudioLocationDefault => 'Music';

  @override
  String storageOrganizedSummary(String baseLabel) {
    return 'منظّم بواسطة Fetchy · $baseLabel';
  }

  @override
  String get storageSummaryDefault => 'افتراضي';

  @override
  String get storageSummaryCustom => 'مخصص';

  @override
  String get historyPageTitle => 'السجل';

  @override
  String get historySearchHint => 'ابحث في السجل...';

  @override
  String get historyClearHistoryTooltip => 'مسح السجل';

  @override
  String get historyClearHistoryTitle => 'مسح السجل؟';

  @override
  String get historyClearHistoryBody =>
      'سيؤدي هذا إلى إزالة جميع التنزيلات المسجّلة من هذا الجهاز. لن يحذف هذا الملفات التي تم تنزيلها فعليًا.';

  @override
  String get historyNoMatchingDownloads => 'لا توجد تنزيلات مطابقة';

  @override
  String get historyTryChangingFilters =>
      'جرّب تغيير كلمات البحث أو عوامل التصفية.';

  @override
  String get historyResetFilters => 'إعادة تعيين عوامل التصفية';

  @override
  String get historyNoHistoryYet => 'لا يوجد سجل بعد';

  @override
  String get historyDownloadsWillShowHere => 'ستظهر هنا التنزيلات التي تكملها.';

  @override
  String get historyFilterTooltip => 'تصفية';

  @override
  String get historyMediaTypeLabel => 'نوع الوسائط';

  @override
  String get historySourceLabel => 'المصدر';

  @override
  String get historyMediaTypeVideo => 'فيديو';

  @override
  String get historyMediaTypeAudio => 'صوت';

  @override
  String get historySourceOther => 'أخرى';

  @override
  String get historyFileMissing => 'الملف مفقود';

  @override
  String get historyJustNow => 'الآن';

  @override
  String historyMinutesAgo(int minutes) {
    return 'قبل $minutes د';
  }

  @override
  String historyHoursAgo(int hours) {
    return 'قبل $hours س';
  }

  @override
  String historyDaysAgo(int days) {
    return 'قبل $days يوم';
  }

  @override
  String get historyDetailTitle => 'تفاصيل التنزيل';

  @override
  String get historyFileAvailable => 'الملف متوفر على الجهاز';

  @override
  String get historyFileMissingOrRemoved => 'الملف مفقود أو أُزيل من التخزين';

  @override
  String get historySourceUrlLabel => 'رابط المصدر';

  @override
  String get historyPlatformLabel => 'المنصة';

  @override
  String get historyTypeLabel => 'النوع';

  @override
  String get historyQualityLabel => 'الجودة';

  @override
  String get historyFormatLabel => 'الصيغة';

  @override
  String get historyFileNameLabel => 'اسم الملف';

  @override
  String get historyFileSizeLabel => 'حجم الملف';

  @override
  String get historySavedToLabel => 'حُفظ في';

  @override
  String get historyCopySourceUrl => 'نسخ رابط المصدر';

  @override
  String get historyLinkCopied => 'تم نسخ الرابط.';

  @override
  String get rootFeaturesPageTitle => 'متقدم / ميزات الروت';

  @override
  String get rootFeaturesComingSoonTag => 'قريبًا';

  @override
  String get rootFeaturesDescription =>
      'ميزات الروت مخطَّط لها في إصدار مستقبلي. لا يتحقق هذا الإصدار من الروت، ولا يطلبه، ولا ينفّذ أي أمر روت. يعمل Fetchy كتطبيق عادي بدون روت.';

  @override
  String get rootFeaturesSectionTitle => 'ميزات الروت';

  @override
  String get rootFeaturesBrowserImportTitle => 'أداة استيراد جلسة المتصفح';

  @override
  String get rootFeaturesBrowserImportReason =>
      'هذا مقصود، وليس فجوة سيتم سدّها لاحقًا. تحفظ إصدارات Chrome/Chromium الحديثة الكوكيز في قاعدة بيانات مشفّرة مرتبطة بـAndroid Keystore. فك تشفيرها ليس أمرًا يمكن لـFetchy فعله بأمان أو موثوقية بمفرده، حتى مع صلاحية الروت، والخطأ فيه قد يعرّض بيانات متصفح حقيقي للتلف.';

  @override
  String get rootFeaturesDiagnosticsTitle => 'تشخيص متقدم';

  @override
  String get rootFeaturesDiagnosticsReason =>
      'غير منفَّذ. لم يُحدَّد بعد أي بيانات تشخيصية محددة.';

  @override
  String get rootFeaturesFileAccessTitle =>
      'تحسينات اختيارية للوصول إلى الملفات';

  @override
  String get rootFeaturesFileAccessReason =>
      'غير منفَّذ. الوصول العادي لتخزين أندرويد (SAF/MediaStore) يغطي بالفعل احتياجات Fetchy، لذا لا شيء يتطلب هذا حاليًا.';

  @override
  String get rootFeaturesSessionImportTitle => 'استيراد جلسة بمساعدة الروت';

  @override
  String get rootFeaturesSessionImportReason =>
      'يعيد استخدام نفس استيراد cookies.txt المتقدم المتاح بالفعل في الحسابات المتصلة. استخرج ملف كوكيز بأداة روت خارجية، حوّله إلى صيغة cookies.txt، واستورده هناك. لا يُخطَّط لاستخراج مخصص داخل التطبيق.';

  @override
  String rootFeaturesNotBuiltYet(String reason) {
    return 'لم يُبنَ بعد. $reason';
  }

  @override
  String get rootFeaturesAccessDescription =>
      'يمنح الوصول بصلاحية الروت تطبيق Fetchy وصولًا موسّعًا للملفات على هذا الجهاز.\n\nفعّل هذا فقط إذا كنت تفهم هذه الميزة وتثق بها. سيستخدم Fetchy الروت فقط للعملية المتقدمة المحددة.';

  @override
  String get rootFeaturesEnableButton => 'تفعيل ميزات الروت';

  @override
  String get rootFeaturesEnableConfirmTitle => 'تفعيل ميزات الروت؟';

  @override
  String get rootFeaturesBypassNotice =>
      'قد يوفر الوصول بصلاحية الروت وصولًا محليًا إضافيًا، لكنه لا يضمن تجاوز حماية المنصة من الروبوتات، أو متطلبات المصادقة، أو إدارة الحقوق الرقمية (DRM)، أو القيود من جهة الخادم.';

  @override
  String get rootStatusAvailable => 'الروت: متاح';

  @override
  String get rootStatusUnavailable => 'الروت: غير متاح على هذا الجهاز';

  @override
  String get rootStatusDenied => 'الروت: تم رفض الوصول';

  @override
  String get rootStatusUnknown => 'الروت: لم يتم التحقق بعد';

  @override
  String get updatesTitle => 'التحديثات';

  @override
  String get updatesSettingsRowSubtitle => 'ابحث عن إصدار أحدث من Fetchy';

  @override
  String get updatesCurrentVersionLabel => 'الإصدار الحالي';

  @override
  String get updatesNewVersionLabel => 'الإصدار الجديد';

  @override
  String get updatesCheckAction => 'التحقق من التحديثات';

  @override
  String get updatesCheckingStatus => 'جارٍ التحقق من التحديثات…';

  @override
  String get updatesUpToDateTitle => 'أنت على أحدث إصدار';

  @override
  String updatesUpToDateBody(String version) {
    return 'الإصدار $version من Fetchy هو أحدث إصدار منشور.';
  }

  @override
  String get updatesNeverChecked => 'لم يتم التحقق بعد';

  @override
  String get updatesLastCheckedNever => 'لم يبحث Fetchy عن تحديثات بعد.';

  @override
  String get updatesAvailableTitle => 'يتوفر تحديث';

  @override
  String updatesAvailableBody(String version) {
    return 'الإصدار $version من Fetchy متاح للتثبيت.';
  }

  @override
  String get updatesReleaseNotesTitle => 'ما الجديد';

  @override
  String get updatesNoReleaseNotes => 'لا توجد ملاحظات لهذا الإصدار.';

  @override
  String updatesPublishedOn(String date) {
    return 'نُشر في $date';
  }

  @override
  String get updatesDownloadAction => 'تنزيل التحديث';

  @override
  String updatesDownloadSize(String size) {
    return 'حجم التنزيل: $size';
  }

  @override
  String get updatesDownloadingStatus => 'جارٍ تنزيل التحديث…';

  @override
  String updatesDownloadedAmount(String received, String total) {
    return '$received من $total';
  }

  @override
  String get updatesDownloadCancelAction => 'إلغاء التنزيل';

  @override
  String get updatesReadyTitle => 'جاهز للتثبيت';

  @override
  String updatesReadyBody(String version) {
    return 'تم تنزيل الإصدار $version من Fetchy. سيطلب منك Android تأكيد التثبيت.';
  }

  @override
  String get updatesInstallAction => 'تثبيت التحديث';

  @override
  String get updatesPermissionTitle => 'مطلوب إذن التثبيت';

  @override
  String get updatesPermissionBody =>
      'لا يسمح Android للتطبيق بفتح المُثبِّت إلا بعد سماحك بذلك. فعّل \"تثبيت التطبيقات غير المعروفة\" لـ Fetchy، ثم عد إلى هنا وتابع.';

  @override
  String get updatesOpenAndroidSettingsAction => 'فتح إعدادات Android';

  @override
  String get updatesContinueInstallAction => 'متابعة التثبيت';

  @override
  String get updatesFailedTitle => 'فشل التحديث';

  @override
  String get updatesGithubUnavailableTitle => 'GitHub غير متاح';

  @override
  String get updatesNoApkTitle => 'لا يوجد ملف قابل للتثبيت';

  @override
  String updatesNoApkBody(String version) {
    return 'الإصدار $version لا يتضمن ملف APK لنظام Android، لذا لا يوجد ما يمكن تثبيته منه.';
  }

  @override
  String get updatesViewOnGithubAction => 'العرض على GitHub';

  @override
  String get updatesErrorNotConfigured =>
      'لم يتم تكوين مصدر التحديث لهذه النسخة بعد، لذا لا يمكن لـ Fetchy التحقق من التحديثات.';

  @override
  String get updatesErrorNoNetwork => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get updatesErrorTimeout => 'لم يستجب GitHub في الوقت المحدد.';

  @override
  String get updatesErrorRateLimited =>
      'يحدّ GitHub من الطلبات حاليًا. يرجى المحاولة لاحقًا.';

  @override
  String get updatesErrorHttp => 'أعاد GitHub استجابة غير متوقعة.';

  @override
  String get updatesErrorMalformed => 'تعذّرت قراءة استجابة GitHub.';

  @override
  String get updatesErrorNoRelease => 'لا توجد إصدارات منشورة بعد.';

  @override
  String get updatesErrorUnknown => 'حدث خطأ أثناء التحقق من التحديثات.';

  @override
  String get updatesInstallErrorPackageMismatch =>
      'هذا الملف ليس نسخة من Fetchy، لذا لم يتم تثبيته.';

  @override
  String get updatesInstallErrorNotNewer =>
      'النسخة التي تم تنزيلها ليست أحدث من المثبتة.';

  @override
  String get updatesInstallErrorSignature =>
      'التحديث موقّع بمفتاح مختلف عن التطبيق المثبت، لذا سيرفضه Android. نزّل Fetchy من المصدر نفسه الذي ثبّته منه.';

  @override
  String get updatesInstallErrorCorrupt =>
      'الملف الذي تم تنزيله ليس حزمة Android صالحة.';

  @override
  String get updatesInstallErrorDownloadFailed => 'تعذّر تنزيل التحديث.';

  @override
  String get updatesInstallErrorCanceled => 'تم إلغاء التنزيل.';

  @override
  String get updatesInstallErrorUnknown => 'تعذّر فتح المُثبِّت.';

  @override
  String get updatesPrivacyNote =>
      'التحقق من التحديثات يتصل بـ GitHub فقط. لا يتم إرسال أي حساب أو جلسة أو حافظة أو سجل تنزيلات.';
}
