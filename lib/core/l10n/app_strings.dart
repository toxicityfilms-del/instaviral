import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/settings/app_settings.dart';

/// UI copy (English / Hindi). AI-generated captions stay English unless user changes prompt elsewhere.
abstract class AppStrings {
  String get appTitle;
  String get growthCockpitTitle;
  String get growthCockpitBody;
  String get profileTooltip;
  String get logoutTooltip;
  String get creatorFallback;

  String get tileHashtags;
  String get tileHashtagsSub;
  String get tileCaption;
  String get tileCaptionSub;
  String get tileTrends;
  String get tileTrendsSub;
  String get tileIdeas;
  String get tileIdeasSub;
  String get tileViralScore;
  String get tileViralScoreSub;
  String get tilePostAnalyzer;
  String get tilePostAnalyzerSub;
  String get tileAnalyzeMedia;
  String get tileAnalyzeMediaSub;
  String get tileChecklist;
  String get tileChecklistSub;

  String get shortcutWorkflow;
  String get shortcutWorkflowSub;
  String get shortcutSaved;
  String get shortcutSavedSub;
  String get badgeNew;

  String get onboardingTitle1;
  String get onboardingBody1;
  String get onboardingTitle2;
  String get onboardingBody2;
  String get onboardingTitle3;
  String get onboardingBody3;
  String get onboardingNext;
  String get onboardingStart;
  String get onboardingSkip;

  String get historyTitle;
  String get historyEmpty;
  String get historyClearAll;
  String get historyClearTitle;
  String get historyClearBody;
  String get historyCopyPackTooltip;
  String get historyDetailDelete;
  String get historyCopyFullPack;
  String get historyPin;
  String get historyUnpin;
  String get historyCleared;
  String get historyDeleteConfirmTitle;
  String get cancel;
  String get clear;
  String get delete;
  String get retry;
  String get analyzeFailBanner;

  String get settingsAppearance;
  String get settingsSectionTheme;
  String get settingsThemeDark;
  String get settingsThemeLight;
  String get settingsThemeSystem;
  String get settingsThemeDarkShort;
  String get settingsThemeLightShort;
  String get settingsThemeSystemShort;
  String get settingsLanguage;
  String get settingsLanguageEn;
  String get settingsLanguageHi;
  String get settingsPrivacy;
  String get settingsAnalyticsOptIn;
  String get settingsAnalyticsOptInSub;
  String get settingsReminder;
  String get settingsReminderSub;
  String get settingsSetDailyReminder;
  String get settingsCancelReminder;
  String get settingsFeedback;
  String get settingsFeedbackSub;

  String get whatsNewTitle;
  String get whatsNewBody;
  String get whatsNewGotIt;

  String get workflowAppBar;
  String get workflowTwoAnalyzers;
  String get workflowSuggestedOrder;
  String get workflowStepProfile;
  String get workflowStepProfileSub;
  String get workflowStepIdeas;
  String get workflowStepIdeasSub;
  String get workflowStepCaption;
  String get workflowStepCaptionSub;
  String get workflowStepHashtags;
  String get workflowStepHashtagsSub;
  String get workflowStepPostAnalyzer;
  String get workflowStepPostAnalyzerSub;
  String get workflowStepMedia;
  String get workflowStepMediaSub;

  String get checklistAppBar;
  String get checklistIntro;
  String get checklistItemHook;
  String get checklistItemCaption;
  String get checklistItemHashtags;
  String get checklistItemCoverText;
  String get checklistItemAudio;

  String get actionSharePack;
  String get actionShare;
  String get shareSheetTitle;
  String get shareAsImageTitle;
  String get shareAsImageSubtitle;
  String get shareAsTextTitle;
  String get analysisShareScoreLabel;
  String get analysisShareNichePrefix;
  String get analysisShareEngagementTips;
  String get analysisShareTipsLockedBody;
  String get analysisShareTipsEmpty;
  String get snackShareImageFailed;
  String get actionRemindPost;
  String get actionCopyFullPack;
  String get snackFullPackCopied;
  String get snackReminderScheduled;
  String get snackReminderCancelled;
  String get reminderNotifTitle;
  String get reminderNotifBody;

  String get errorTooManyRequests;
  String get errorServer;
  String get errorSession;
  String get errorNetwork;
  String get errorGenericAnalyze;
  String get postAnalyzeBestTimeFallback;
  String get postAnalyzeAudioFallback;
  String get viralBestTimeTitle;
  String get viralAudioSuggestionTitle;
  String get viralNicheLabel;

  String get analyzeMediaCompareTitle;

  String get comparisonTitle;
  String get comparisonVsLast;
  String get comparisonPointsVsLast;
  String get comparisonBefore;
  String get comparisonAfter;
  String get comparisonViralScore;
  String get comparisonHook;
  String get comparisonCaption;
  String get comparisonTipsCount;

  /// Short badge when viral score increased vs last run.
  String get comparisonImprovedBadge;

  String get actionShareComparisonResult;
  String get comparisonShareCardHeading;
  String get comparisonShareImprovementLabel;

  /// Shown when no prior analysis exists yet (before/after unlocks on second run).
  String get firstAnalysisInsightsHint;

  /// Primary CTA after first analysis to run comparison on second analyze.
  String get firstAnalysisImproveCta;
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final lc = ref.watch(appSettingsProvider).localeCode;
  return lc == AppLocaleCode.hi ? AppStringsHi() : AppStringsEn();
});

class AppStringsEn implements AppStrings {
  @override
  String get appTitle => 'ReelBoost AI';
  @override
  String get growthCockpitTitle => 'Your growth cockpit';
  @override
  String get growthCockpitBody =>
      'Profile, analyzers, captions, hashtags, ideas, trends, viral score — plus saved packs & workflow.';
  @override
  String get profileTooltip => 'Profile';
  @override
  String get logoutTooltip => 'Log out';
  @override
  String get creatorFallback => 'Creator';

  @override
  String get tileHashtags => 'Hashtags';
  @override
  String get tileHashtagsSub => '15 tags by competition';
  @override
  String get tileCaption => 'Caption';
  @override
  String get tileCaptionSub => 'Viral copy + hooks';
  @override
  String get tileTrends => 'Trends';
  @override
  String get tileTrendsSub => 'Ideas & sounds';
  @override
  String get tileIdeas => 'Ideas';
  @override
  String get tileIdeasSub => '5 reel ideas';
  @override
  String get tileViralScore => 'Viral score';
  @override
  String get tileViralScoreSub => 'Caption + tags';
  @override
  String get tilePostAnalyzer => 'Post analyzer';
  @override
  String get tilePostAnalyzerSub => 'Idea + optional image';
  @override
  String get tileAnalyzeMedia => 'Analyze media';
  @override
  String get tileAnalyzeMediaSub => 'Image/video insights';
  @override
  String get tileChecklist => 'Publish checklist';
  @override
  String get tileChecklistSub => 'Before you hit post';

  @override
  String get shortcutWorkflow => 'Workflow';
  @override
  String get shortcutWorkflowSub => 'Reel steps + analyzer guide';
  @override
  String get shortcutSaved => 'Saved';
  @override
  String get shortcutSavedSub => 'Past analyses — copy again';
  @override
  String get badgeNew => 'NEW';

  @override
  String get onboardingTitle1 => 'All-in-one reel assistant';
  @override
  String get onboardingBody1 =>
      'Captions, hashtags, ideas, trends, and two smart analyzers — tuned with your creator profile.';
  @override
  String get onboardingTitle2 => 'Two analyzers';
  @override
  String get onboardingBody2 =>
      'Post analyzer: your idea + optional photo. Analyze media: upload the real image or video for visual insights.';
  @override
  String get onboardingTitle3 => 'Save & share';
  @override
  String get onboardingBody3 =>
      'Every analysis is saved on this device. Copy the full pack or share it in one tap. Set Hindi or light theme in Profile.';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingStart => 'Get started';
  @override
  String get onboardingSkip => 'Skip';

  @override
  String get historyTitle => 'Saved analyses';
  @override
  String get historyEmpty =>
      'No saved analyses yet.\nRun Post analyzer or Analyze media — results save automatically. Pull down to refresh tips.';
  @override
  String get historyClearAll => 'Clear all';
  @override
  String get historyClearTitle => 'Clear history?';
  @override
  String get historyClearBody => 'All saved analysis packs will be removed from this device.';
  @override
  String get historyCopyPackTooltip => 'Copy pack';
  @override
  String get historyDetailDelete => 'Delete';
  @override
  String get historyCopyFullPack => 'Copy full pack';
  @override
  String get historyPin => 'Pin to top';
  @override
  String get historyUnpin => 'Unpin';
  @override
  String get historyCleared => 'History cleared';
  @override
  String get historyDeleteConfirmTitle => 'Delete this entry?';
  @override
  String get cancel => 'Cancel';
  @override
  String get clear => 'Clear';
  @override
  String get delete => 'Delete';
  @override
  String get retry => 'Retry';
  @override
  String get analyzeFailBanner =>
      'Last analyze failed. Check connection or API quota, then retry.';

  @override
  String get settingsAppearance => 'Appearance & language';
  @override
  String get settingsSectionTheme => 'Theme';
  @override
  String get settingsThemeDark => 'Dark theme';
  @override
  String get settingsThemeLight => 'Light theme';
  @override
  String get settingsThemeSystem => 'Match system';
  @override
  String get settingsThemeDarkShort => 'Dark';
  @override
  String get settingsThemeLightShort => 'Light';
  @override
  String get settingsThemeSystemShort => 'System';
  @override
  String get settingsLanguage => 'App language';
  @override
  String get settingsLanguageEn => 'English';
  @override
  String get settingsLanguageHi => 'हिंदी';
  @override
  String get settingsPrivacy => 'Privacy';
  @override
  String get settingsAnalyticsOptIn => 'Anonymous usage stats';
  @override
  String get settingsAnalyticsOptInSub =>
      'Counts screen opens on this device only (debug / product improvement). No ads profile.';
  @override
  String get settingsReminder => 'Posting reminder';
  @override
  String get settingsReminderSub => 'Daily nudge at a time you choose (local notification).';
  @override
  String get settingsSetDailyReminder => 'Set daily reminder…';
  @override
  String get settingsCancelReminder => 'Cancel reminder';
  @override
  String get settingsFeedback => 'Send feedback';
  @override
  String get settingsFeedbackSub => 'Email the developer from your mail app.';

  @override
  String get whatsNewTitle => 'What’s new';
  @override
  String get whatsNewBody =>
      '• Hindi UI + light/dark theme (Profile)\n• Onboarding & tips\n• Share pack, haptics, pins in history\n• Publish checklist & daily reminder\n• Clearer errors when the API is busy';
  @override
  String get whatsNewGotIt => 'Got it';

  @override
  String get workflowAppBar => 'Reel workflow';
  @override
  String get workflowTwoAnalyzers => 'Two analyzers';
  @override
  String get workflowSuggestedOrder => 'Suggested order';
  @override
  String get workflowStepProfile => 'Profile';
  @override
  String get workflowStepProfileSub => 'Niche & bio for better AI';
  @override
  String get workflowStepIdeas => 'Ideas';
  @override
  String get workflowStepIdeasSub => 'Pick a reel angle';
  @override
  String get workflowStepCaption => 'Caption';
  @override
  String get workflowStepCaptionSub => 'Viral copy & hooks';
  @override
  String get workflowStepHashtags => 'Hashtags';
  @override
  String get workflowStepHashtagsSub => '15 tags tuned to competition';
  @override
  String get workflowStepPostAnalyzer => 'Post analyzer';
  @override
  String get workflowStepPostAnalyzerSub => 'Idea + optional image → full pack';
  @override
  String get workflowStepMedia => 'Analyze media';
  @override
  String get workflowStepMediaSub => 'Image or video → hook, caption, tags';

  @override
  String get checklistAppBar => 'Publish checklist';
  @override
  String get checklistIntro => 'Tick items before you post — better reach & saves.';
  @override
  String get checklistItemHook => 'Strong first 3 seconds (hook on screen + audio)';
  @override
  String get checklistItemCaption => 'Caption has a clear CTA (comment / save / follow)';
  @override
  String get checklistItemHashtags => 'Hashtags mix niche + broad (not spammy)';
  @override
  String get checklistItemCoverText => 'Cover text readable on small phones';
  @override
  String get checklistItemAudio => 'Trending audio fits the vibe (or original is intentional)';

  @override
  String get actionSharePack => 'Share pack';
  @override
  String get actionShare => 'Share';
  @override
  String get shareSheetTitle => 'Share analysis';
  @override
  String get shareAsImageTitle => 'Share as image';
  @override
  String get shareAsImageSubtitle => 'Instagram Story, WhatsApp, and more';
  @override
  String get shareAsTextTitle => 'Share as text';
  @override
  String get analysisShareScoreLabel => 'VIRAL SCORE';
  @override
  String get analysisShareNichePrefix => 'Niche';
  @override
  String get analysisShareEngagementTips => 'Engagement tips';
  @override
  String get analysisShareTipsLockedBody =>
      'Unlock personalized engagement tips with Premium.';
  @override
  String get analysisShareTipsEmpty =>
      'Keep testing hooks, pacing, and posting times to improve reach.';
  @override
  String get snackShareImageFailed => 'Couldn’t share image. Try again.';
  @override
  String get actionRemindPost => 'Remind me to post';
  @override
  String get actionCopyFullPack => 'Copy full pack (hook + caption + hashtags + more)';
  @override
  String get snackFullPackCopied => 'Full pack copied';
  @override
  String get snackReminderScheduled => 'Daily reminder set';
  @override
  String get snackReminderCancelled => 'Reminder cancelled';
  @override
  String get reminderNotifTitle => 'Time to post your reel';
  @override
  String get reminderNotifBody => 'Open ReelBoost and copy your pack to Instagram.';

  @override
  String get errorTooManyRequests =>
      'Too many requests right now. Wait a minute and try again. If this keeps happening, check API quota.';
  @override
  String get errorServer => 'The server had a problem. Try again in a moment.';
  @override
  String get errorSession => 'Your session expired. Sign in again to continue.';
  @override
  String get errorNetwork => 'Couldn’t reach the server. Check your connection and try again.';
  @override
  String get errorGenericAnalyze => 'Couldn’t analyze this post. Please try again.';
  @override
  String get postAnalyzeBestTimeFallback =>
      'No timing detail in this response. Tap Analyze again after checking your connection.';
  @override
  String get postAnalyzeAudioFallback =>
      'No audio suggestion in this response. Tap Analyze again after checking your connection.';
  @override
  String get viralBestTimeTitle => 'Best time';
  @override
  String get viralAudioSuggestionTitle => 'Audio suggestion';
  @override
  String get viralNicheLabel => 'Niche context';

  @override
  String get analyzeMediaCompareTitle =>
      'Not the same as Post analyzer: that one is for your written idea + optional photo. '
      'This screen needs the actual file (image or video).';

  @override
  String get comparisonTitle => 'Compared to last analysis';
  @override
  String get comparisonVsLast => 'vs last score';
  @override
  String get comparisonPointsVsLast => 'pts vs last score';
  @override
  String get comparisonBefore => 'Before';
  @override
  String get comparisonAfter => 'After';
  @override
  String get comparisonViralScore => 'Viral score';
  @override
  String get comparisonHook => 'Hook';
  @override
  String get comparisonCaption => 'Caption';
  @override
  String get comparisonTipsCount => 'Engagement tips (count)';

  @override
  String get comparisonImprovedBadge => '🔥 Improved';

  @override
  String get actionShareComparisonResult => 'Share Result';
  @override
  String get comparisonShareCardHeading => 'Score comparison';
  @override
  String get comparisonShareImprovementLabel => 'Improvement';

  @override
  String get firstAnalysisInsightsHint => '🔥 Analyze again to unlock improvement insights';

  @override
  String get firstAnalysisImproveCta => 'Improve & Analyze Again';
}

class AppStringsHi implements AppStrings {
  @override
  String get appTitle => 'ReelBoost AI';
  @override
  String get growthCockpitTitle => 'आपका ग्रोथ कॉकपिट';
  @override
  String get growthCockpitBody =>
      'प्रोफाइल, एनालाइज़र, कैप्शन, हैशटैग, आइडियाज, ट्रेंड्स, वायरल स्कोर — सेव्ड पैक और वर्कफ़्लो के साथ।';
  @override
  String get profileTooltip => 'प्रोफाइल';
  @override
  String get logoutTooltip => 'लॉग आउट';
  @override
  String get creatorFallback => 'क्रिएटर';

  @override
  String get tileHashtags => 'हैशटैग';
  @override
  String get tileHashtagsSub => 'कॉम्पिटिशन के हिसाब से 15 टैग';
  @override
  String get tileCaption => 'कैप्शन';
  @override
  String get tileCaptionSub => 'वायरल कॉपी + हुक';
  @override
  String get tileTrends => 'ट्रेंड्स';
  @override
  String get tileTrendsSub => 'आइडियाज और साउंड';
  @override
  String get tileIdeas => 'आइडियाज';
  @override
  String get tileIdeasSub => '5 रील आइडियाज';
  @override
  String get tileViralScore => 'वायरल स्कोर';
  @override
  String get tileViralScoreSub => 'कैप्शन + टैग';
  @override
  String get tilePostAnalyzer => 'पोस्ट एनालाइज़र';
  @override
  String get tilePostAnalyzerSub => 'आइडिया + ऑप्शनल फोटो';
  @override
  String get tileAnalyzeMedia => 'मीडिया एनालाइज़';
  @override
  String get tileAnalyzeMediaSub => 'इमेज/वीडियो इनसाइट्स';
  @override
  String get tileChecklist => 'पब्लिश चेकलिस्ट';
  @override
  String get tileChecklistSub => 'पोस्ट से पहले';

  @override
  String get shortcutWorkflow => 'वर्कफ़्लो';
  @override
  String get shortcutWorkflowSub => 'रील स्टेप्स + गाइड';
  @override
  String get shortcutSaved => 'सेव्ड';
  @override
  String get shortcutSavedSub => 'पुराने एनालिसिस';
  @override
  String get badgeNew => 'नया';

  @override
  String get onboardingTitle1 => 'ऑल-इन-वन रील असिस्टेंट';
  @override
  String get onboardingBody1 =>
      'कैप्शन, हैशटैग, आइडियाज, ट्रेंड्स और दो स्मार्ट एनालाइज़र — आपकी क्रिएटर प्रोफाइल के साथ।';
  @override
  String get onboardingTitle2 => 'दो एनालाइज़र';
  @override
  String get onboardingBody2 =>
      'पोस्ट एनालाइज़र: आपका आइडिया + ऑप्शनल फोटो। मीडिया एनालाइज़: असली फोटो या वीडियो अपलोड करें।';
  @override
  String get onboardingTitle3 => 'सेव और शेयर';
  @override
  String get onboardingBody3 =>
      'हर एनालिसिस इस फोन पर सेव होती है। पूरा पैक कॉपी या एक टैप में शेयर करें। प्रोफाइल में हिंदी या लाइट थीम चुनें।';
  @override
  String get onboardingNext => 'आगे';
  @override
  String get onboardingStart => 'शुरू करें';
  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get historyTitle => 'सेव्ड एनालिसिस';
  @override
  String get historyEmpty =>
      'अभी कुछ सेव नहीं है।\nपोस्ट या मीडिया एनालाइज़ चलाएँ — रिजल्ट अपने आप सेव होंगे। नीचे खींचकर रिफ्रेश करें।';
  @override
  String get historyClearAll => 'सब हटाएँ';
  @override
  String get historyClearTitle => 'हिस्ट्री साफ़ करें?';
  @override
  String get historyClearBody => 'सारे सेव्ड पैक इस डिवाइस से हट जाएँगे।';
  @override
  String get historyCopyPackTooltip => 'पैक कॉपी';
  @override
  String get historyDetailDelete => 'हटाएँ';
  @override
  String get historyCopyFullPack => 'पूरा पैक कॉपी';
  @override
  String get historyPin => 'ऊपर पिन करें';
  @override
  String get historyUnpin => 'पिन हटाएँ';
  @override
  String get historyCleared => 'हिस्ट्री साफ़ हो गई';
  @override
  String get historyDeleteConfirmTitle => 'यह एंट्री हटाएँ?';
  @override
  String get cancel => 'रद्द';
  @override
  String get clear => 'साफ़';
  @override
  String get delete => 'हटाएँ';
  @override
  String get retry => 'दोबारा';
  @override
  String get analyzeFailBanner =>
      'पिछला एनालाइज़ फेल। कनेक्शन या API कोटा चेक करके दोबारा कोशिश करें।';

  @override
  String get settingsAppearance => 'दिखावट और भाषा';
  @override
  String get settingsSectionTheme => 'थीम';
  @override
  String get settingsThemeDark => 'डार्क थीम';
  @override
  String get settingsThemeLight => 'लाइट थीम';
  @override
  String get settingsThemeSystem => 'सिस्टम जैसा';
  @override
  String get settingsThemeDarkShort => 'डार्क';
  @override
  String get settingsThemeLightShort => 'लाइट';
  @override
  String get settingsThemeSystemShort => 'सिस्टम';
  @override
  String get settingsLanguage => 'ऐप भाषा';
  @override
  String get settingsLanguageEn => 'English';
  @override
  String get settingsLanguageHi => 'हिंदी';
  @override
  String get settingsPrivacy => 'प्राइवेसी';
  @override
  String get settingsAnalyticsOptIn => 'अनाम उपयोग आँकड़े';
  @override
  String get settingsAnalyticsOptInSub =>
      'सिर्फ इस डिवाइस पर स्क्रीन खुलने की गिनती (डेव / सुधार)। विज्ञापन प्रोफाइल नहीं।';
  @override
  String get settingsReminder => 'पोस्ट रिमाइंडर';
  @override
  String get settingsReminderSub => 'रोज़ आपके चुने समय पर लोकल नोटिफिकेशन।';
  @override
  String get settingsSetDailyReminder => 'रोज़ का रिमाइंडर…';
  @override
  String get settingsCancelReminder => 'रिमाइंडर रद्द';
  @override
  String get settingsFeedback => 'फीडबैक भेजें';
  @override
  String get settingsFeedbackSub => 'मेल ऐप से डेवलपर को लिखें।';

  @override
  String get whatsNewTitle => 'नया क्या है';
  @override
  String get whatsNewBody =>
      '• हिंदी UI + लाइट/डार्क थीम (प्रोफाइल)\n• ऑनबोर्डिंग और टिप्स\n• शेयर पैक, हैप्टिक, हिस्ट्री में पिन\n• पब्लिश चेकलिस्ट और दैनिक रिमाइंडर\n• API व्यस्त होने पर साफ़ एरर';
  @override
  String get whatsNewGotIt => 'ठीक है';

  @override
  String get workflowAppBar => 'रील वर्कफ़्लो';
  @override
  String get workflowTwoAnalyzers => 'दो एनालाइज़र';
  @override
  String get workflowSuggestedOrder => 'सुझाया क्रम';
  @override
  String get workflowStepProfile => 'प्रोफाइल';
  @override
  String get workflowStepProfileSub => 'निच और बायो — बेहतर AI';
  @override
  String get workflowStepIdeas => 'आइडियाज';
  @override
  String get workflowStepIdeasSub => 'एक एंगल चुनें';
  @override
  String get workflowStepCaption => 'कैप्शन';
  @override
  String get workflowStepCaptionSub => 'वायरल कॉपी और हुक';
  @override
  String get workflowStepHashtags => 'हैशटैग';
  @override
  String get workflowStepHashtagsSub => '15 टैग';
  @override
  String get workflowStepPostAnalyzer => 'पोस्ट एनालाइज़र';
  @override
  String get workflowStepPostAnalyzerSub => 'आइडिया + फोटो → पूरा पैक';
  @override
  String get workflowStepMedia => 'मीडिया एनालाइज़';
  @override
  String get workflowStepMediaSub => 'इमेज/वीडियो → हुक, कैप्शन, टैग';

  @override
  String get checklistAppBar => 'पब्लिश चेकलिस्ट';
  @override
  String get checklistIntro => 'पोस्ट से पहले टिक करें — रीच और सेव्स बेहतर।';
  @override
  String get checklistItemHook => 'पहले 3 सेकंड में धांसू हुक (स्क्रीन + ऑडियो)';
  @override
  String get checklistItemCaption => 'कैप्शन में साफ़ CTA (कमेंट / सेव / फॉलो)';
  @override
  String get checklistItemHashtags => 'हैशटैग: निच + ब्रॉड मिक्स, स्पैम नहीं';
  @override
  String get checklistItemCoverText => 'कवर टेक्स्ट छोटे फोन पर पढ़ने लायक';
  @override
  String get checklistItemAudio => 'ट्रेंडिंग ऑडियो मूड से मैच (या जानबूझकर ओरिजिनल)';

  @override
  String get actionSharePack => 'पैक शेयर';
  @override
  String get actionShare => 'शेयर';
  @override
  String get shareSheetTitle => 'एनालिसिस शेयर करें';
  @override
  String get shareAsImageTitle => 'इमेज के रूप में शेयर';
  @override
  String get shareAsImageSubtitle => 'Instagram Story, WhatsApp और अन्य';
  @override
  String get shareAsTextTitle => 'टेक्स्ट के रूप में शेयर';
  @override
  String get analysisShareScoreLabel => 'वायरल स्कोर';
  @override
  String get analysisShareNichePrefix => 'निच';
  @override
  String get analysisShareEngagementTips => 'एंगेजमेंट टिप्स';
  @override
  String get analysisShareTipsLockedBody =>
      'पर्सनलाइज़्ड एंगेजमेंट टिप्स के लिए Premium लें।';
  @override
  String get analysisShareTipsEmpty =>
      'रीच बढ़ाने के लिए हुक, पेसिंग और पोस्ट टाइम टेस्ट करते रहें।';
  @override
  String get snackShareImageFailed => 'इमेज शेयर नहीं हो सकी। दोबारा कोशिश करें।';
  @override
  String get actionRemindPost => 'पोस्ट की याद दिलाएँ';
  @override
  String get actionCopyFullPack => 'पूरा पैक कॉपी (हुक + कैप्शन + हैशटैग…)';
  @override
  String get snackFullPackCopied => 'पूरा पैक कॉपी हो गया';
  @override
  String get snackReminderScheduled => 'रोज़ का रिमाइंडर सेट';
  @override
  String get snackReminderCancelled => 'रिमाइंडर रद्द';
  @override
  String get reminderNotifTitle => 'रील पोस्ट करने का समय';
  @override
  String get reminderNotifBody => 'ReelBoost खोलें और Instagram के लिए पैक कॉपी करें।';

  @override
  String get errorTooManyRequests =>
      'बहुत ज़्यादा रिक्वेस्ट। एक मिनट बाद कोशिश करें। बार-बार हो तो API कोटा चेक करें।';
  @override
  String get errorServer => 'सर्वर में दिक्कत। थोड़ी देर बाद कोशिश करें।';
  @override
  String get errorSession => 'सेशन खत्म हो गया। दोबारा साइन इन करें।';
  @override
  String get errorNetwork => 'सर्वर तक नहीं पहुँचे। नेट और API URL चेक करें।';
  @override
  String get errorGenericAnalyze => 'एनालाइज़ नहीं हो सका। दोबारा कोशिश करें।';
  @override
  String get postAnalyzeBestTimeFallback =>
      'इस जवाब में टाइमिंग नहीं मिली। कनेक्शन चेक करके दोबारा एनालाइज़ करें।';
  @override
  String get postAnalyzeAudioFallback =>
      'इस जवाब में ऑडियो सुझाव नहीं मिला। कनेक्शन चेक करके दोबारा एनालाइज़ करें।';
  @override
  String get viralBestTimeTitle => 'सबसे अच्छा समय';
  @override
  String get viralAudioSuggestionTitle => 'ऑडियो सुझाव';
  @override
  String get viralNicheLabel => 'निच संदर्भ';

  @override
  String get analyzeMediaCompareTitle =>
      'पोस्ट एनालाइज़र जैसा नहीं: वहाँ लिखा आइडिया + ऑप्शनल फोटो। '
      'यहाँ असली फाइल (फोटो या वीडियो) चाहिए।';

  @override
  String get comparisonTitle => 'पिछली एनालिसिस से तुलना';
  @override
  String get comparisonVsLast => 'पिछले स्कोर से';
  @override
  String get comparisonPointsVsLast => 'पॉइंट पिछले स्कोर से';
  @override
  String get comparisonBefore => 'पहले';
  @override
  String get comparisonAfter => 'अब';
  @override
  String get comparisonViralScore => 'वायरल स्कोर';
  @override
  String get comparisonHook => 'हुक';
  @override
  String get comparisonCaption => 'कैप्शन';
  @override
  String get comparisonTipsCount => 'एंगेजमेंट टिप्स (संख्या)';

  @override
  String get comparisonImprovedBadge => '🔥 बेहतर';

  @override
  String get actionShareComparisonResult => 'रिज़ल्ट शेयर करें';
  @override
  String get comparisonShareCardHeading => 'स्कोर तुलना';
  @override
  String get comparisonShareImprovementLabel => 'सुधार';

  @override
  String get firstAnalysisInsightsHint =>
      '🔥 इम्प्रूवमेंट इनसाइट्स के लिए दोबारा एनालाइज़ करें';

  @override
  String get firstAnalysisImproveCta => 'सुधारें और दोबारा एनालाइज़ करें';
}
