class ContentCalendarDay {
  final int day;
  final int weekNumber;
  final String title;
  final String idea; // legacy fallback, maps to fullScript
  
  // Strategy & Psychology
  final String dailyObjective;
  final String funnelStage;
  final String contentPillar;
  final String contentFormat;
  final String platform;
  final String targetAudience;
  final String psychologyUsed;
  final String psychologyReason;
  final String whyThisWorks;
  final String emotionTriggered;
  
  // Hook & Script
  final String hook;
  final List<String> alternativeHooks;
  final String fullScript;
  final String bRollSuggestions;
  final String cameraAngles;
  final String shotList;
  final String textOverlayTimeline;
  final String editingInstructions;
  final String musicSuggestions;
  
  // Caption & CTA
  final String caption;
  final List<String> alternativeCaptions;
  final String cta;
  final List<String> alternativeCTAs;
  final String hashtags;
  
  // Visual & Performance
  final String thumbnailIdea;
  final String thumbnailText;
  final String postingTime;
  final String difficulty;
  final String estimatedCreationTime;
  final String expectedEngagement;
  final String reachEstimate;
  final int viralityPotential;
  final int confidenceScore;
  final String performanceReasoning;
  final String roiEstimate;
  
  // Checklists
  final List<String> preProductionChecklist;
  final List<String> shootChecklist;
  final List<String> editChecklist;
  final List<String> uploadChecklist;
  final String repurposeSuggestions;
  final String successMetrics;

  ContentCalendarDay({
    required this.day,
    required this.weekNumber,
    required this.title,
    required this.idea,
    required this.dailyObjective,
    required this.funnelStage,
    required this.contentPillar,
    required this.contentFormat,
    required this.platform,
    required this.targetAudience,
    required this.psychologyUsed,
    required this.psychologyReason,
    required this.whyThisWorks,
    required this.emotionTriggered,
    required this.hook,
    required this.alternativeHooks,
    required this.fullScript,
    required this.bRollSuggestions,
    required this.cameraAngles,
    required this.shotList,
    required this.textOverlayTimeline,
    required this.editingInstructions,
    required this.musicSuggestions,
    required this.caption,
    required this.alternativeCaptions,
    required this.cta,
    required this.alternativeCTAs,
    required this.hashtags,
    required this.thumbnailIdea,
    required this.thumbnailText,
    required this.postingTime,
    required this.difficulty,
    required this.estimatedCreationTime,
    required this.expectedEngagement,
    required this.reachEstimate,
    required this.viralityPotential,
    required this.confidenceScore,
    required this.performanceReasoning,
    required this.roiEstimate,
    required this.preProductionChecklist,
    required this.shootChecklist,
    required this.editChecklist,
    required this.uploadChecklist,
    required this.repurposeSuggestions,
    required this.successMetrics,
  });

  factory ContentCalendarDay.fromJson(Map<String, dynamic> json) {
    List<String> _parseList(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    return ContentCalendarDay(
      day: json['day'] ?? 0,
      weekNumber: json['weekNumber'] ?? 1,
      title: json['title'] ?? '',
      idea: json['idea'] ?? '',
      dailyObjective: json['dailyObjective'] ?? json['goal'] ?? '',
      funnelStage: json['funnelStage'] ?? '',
      contentPillar: json['contentPillar'] ?? '',
      contentFormat: json['contentFormat'] ?? '',
      platform: json['platform'] ?? '',
      targetAudience: json['targetAudience'] ?? '',
      psychologyUsed: json['psychologyUsed'] ?? '',
      psychologyReason: json['psychologyReason'] ?? '',
      whyThisWorks: json['whyThisWorks'] ?? '',
      emotionTriggered: json['emotionTriggered'] ?? '',
      hook: json['hook'] ?? '',
      alternativeHooks: _parseList(json['alternativeHooks']),
      fullScript: json['fullScript'] ?? '',
      bRollSuggestions: json['bRollSuggestions'] ?? '',
      cameraAngles: json['cameraAngles'] ?? '',
      shotList: json['shotList'] ?? '',
      textOverlayTimeline: json['textOverlayTimeline'] ?? '',
      editingInstructions: json['editingInstructions'] ?? '',
      musicSuggestions: json['musicSuggestions'] ?? '',
      caption: json['caption'] ?? '',
      alternativeCaptions: _parseList(json['alternativeCaptions']),
      cta: json['cta'] ?? '',
      alternativeCTAs: _parseList(json['alternativeCTAs']),
      hashtags: json['hashtags'] ?? '',
      thumbnailIdea: json['thumbnailIdea'] ?? '',
      thumbnailText: json['thumbnailText'] ?? '',
      postingTime: json['postingTime'] ?? json['posting_time'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
      estimatedCreationTime: json['estimatedCreationTime'] ?? '',
      expectedEngagement: json['expectedEngagement'] ?? '',
      reachEstimate: json['reachEstimate'] ?? '',
      viralityPotential: json['viralityPotential'] ?? 0,
      confidenceScore: json['confidenceScore'] ?? 0,
      performanceReasoning: json['performanceReasoning'] ?? '',
      roiEstimate: json['roiEstimate'] ?? '',
      preProductionChecklist: _parseList(json['preProductionChecklist']),
      shootChecklist: _parseList(json['shootChecklist']),
      editChecklist: _parseList(json['editChecklist']),
      uploadChecklist: _parseList(json['uploadChecklist']),
      repurposeSuggestions: json['repurposeSuggestions'] ?? '',
      successMetrics: json['successMetrics'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'weekNumber': weekNumber,
      'title': title,
      'idea': idea,
      'dailyObjective': dailyObjective,
      'funnelStage': funnelStage,
      'contentPillar': contentPillar,
      'contentFormat': contentFormat,
      'platform': platform,
      'targetAudience': targetAudience,
      'psychologyUsed': psychologyUsed,
      'psychologyReason': psychologyReason,
      'whyThisWorks': whyThisWorks,
      'emotionTriggered': emotionTriggered,
      'hook': hook,
      'alternativeHooks': alternativeHooks,
      'fullScript': fullScript,
      'bRollSuggestions': bRollSuggestions,
      'cameraAngles': cameraAngles,
      'shotList': shotList,
      'textOverlayTimeline': textOverlayTimeline,
      'editingInstructions': editingInstructions,
      'musicSuggestions': musicSuggestions,
      'caption': caption,
      'alternativeCaptions': alternativeCaptions,
      'cta': cta,
      'alternativeCTAs': alternativeCTAs,
      'hashtags': hashtags,
      'thumbnailIdea': thumbnailIdea,
      'thumbnailText': thumbnailText,
      'postingTime': postingTime,
      'difficulty': difficulty,
      'estimatedCreationTime': estimatedCreationTime,
      'expectedEngagement': expectedEngagement,
      'reachEstimate': reachEstimate,
      'viralityPotential': viralityPotential,
      'confidenceScore': confidenceScore,
      'performanceReasoning': performanceReasoning,
      'roiEstimate': roiEstimate,
      'preProductionChecklist': preProductionChecklist,
      'shootChecklist': shootChecklist,
      'editChecklist': editChecklist,
      'uploadChecklist': uploadChecklist,
      'repurposeSuggestions': repurposeSuggestions,
      'successMetrics': successMetrics,
    };
  }
}

class WeeklyPlan {
  final int weekNumber;
  final String weeklyGoal;
  final List<String> weeklyKPIs;
  final String weeklyStrategy;
  final Map<String, dynamic> growthCoach;

  WeeklyPlan({
    required this.weekNumber,
    required this.weeklyGoal,
    required this.weeklyKPIs,
    required this.weeklyStrategy,
    required this.growthCoach,
  });

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      weekNumber: json['weekNumber'] ?? 1,
      weeklyGoal: json['weeklyGoal'] ?? '',
      weeklyKPIs: (json['weeklyKPIs'] as List?)?.map((e) => e.toString()).toList() ?? [],
      weeklyStrategy: json['weeklyStrategy'] ?? '',
      growthCoach: json['growthCoach'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'weeklyGoal': weeklyGoal,
      'weeklyKPIs': weeklyKPIs,
      'weeklyStrategy': weeklyStrategy,
      'growthCoach': growthCoach,
    };
  }
}

class ContentCalendarModel {
  final String id;
  final String niche;
  final String audience;
  final String goal;
  final String frequency;
  final DateTime createdAt;
  final String? pdfPath;
  
  // Strategy
  final String monthlyGoal;
  final List<String> monthlyKPIs;
  final Map<String, dynamic> contentGapAnalysis;
  final Map<String, dynamic> contentMixBreakdown;
  final Map<String, dynamic> platformDistribution;
  
  final List<WeeklyPlan> weeks;
  final List<ContentCalendarDay> days;

  ContentCalendarModel({
    required this.id,
    required this.niche,
    required this.audience,
    required this.goal,
    required this.frequency,
    required this.createdAt,
    this.pdfPath,
    required this.monthlyGoal,
    required this.monthlyKPIs,
    required this.contentGapAnalysis,
    required this.contentMixBreakdown,
    required this.platformDistribution,
    required this.weeks,
    required this.days,
  });

  factory ContentCalendarModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final rawDate = json['createdAt'];
    DateTime parsedDate;
    if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return ContentCalendarModel(
      id: docId ?? json['id'] ?? '',
      niche: json['niche'] ?? '',
      audience: json['audience'] ?? '',
      goal: json['goal'] ?? '',
      frequency: json['frequency'] ?? '',
      createdAt: parsedDate,
      pdfPath: json['pdf_path'] ?? json['pdfPath'],
      monthlyGoal: json['monthlyGoal'] ?? json['goal'] ?? '',
      monthlyKPIs: (json['monthlyKPIs'] as List?)?.map((e) => e.toString()).toList() ?? [],
      contentGapAnalysis: json['contentGapAnalysis'] ?? {},
      contentMixBreakdown: json['contentMixBreakdown'] ?? {},
      platformDistribution: json['platformDistribution'] ?? {},
      weeks: (json['weeks'] as List?)
              ?.map((item) => WeeklyPlan.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      days: (json['days'] as List?)
              ?.map((item) => ContentCalendarDay.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'niche': niche,
      'audience': audience,
      'goal': goal,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
      'pdfPath': pdfPath,
      'pdf_path': pdfPath,
      'monthlyGoal': monthlyGoal,
      'monthlyKPIs': monthlyKPIs,
      'contentGapAnalysis': contentGapAnalysis,
      'contentMixBreakdown': contentMixBreakdown,
      'platformDistribution': platformDistribution,
      'weeks': weeks.map((w) => w.toJson()).toList(),
      'days': days.map((day) => day.toJson()).toList(),
    };
  }
}
