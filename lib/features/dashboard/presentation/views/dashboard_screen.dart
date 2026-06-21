import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/data/models/user_model.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../../reel_upload/presentation/views/upload_reel_screen.dart';
import 'content_planner_screen.dart';
import 'insights_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHELL
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthViewModel>(context, listen: false);
      if (auth.user != null) {
        Provider.of<DashboardViewModel>(context, listen: false)
            .loadAnalyses(auth.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthViewModel>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final tabs = [
      _DashboardHomeView(
        user: user,
        onTabChanged: (i) => setState(() => _currentIndex = i),
      ),
      const UploadReelScreen(embeddedMode: true),
      const ContentPlannerScreen(embeddedMode: true),
      const InsightsScreen(embeddedMode: true),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: IndexedStack(index: _currentIndex, children: tabs),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.grid_view_rounded, label: 'Dashboard'),
    (icon: Icons.play_circle_outline_rounded, label: 'Analyze'),
    (icon: Icons.calendar_month_outlined, label: 'Plan'),
    (icon: Icons.insights_rounded, label: 'Insights'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        border: Border(top: BorderSide(color: Color(0xFF141414), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: active ? 22 : 20,
                        color: active ? AppTheme.primary : const Color(0xFF3A3A3A),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? AppTheme.primary : const Color(0xFF3A3A3A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD HOME VIEW  (the scroll body)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHomeView extends StatelessWidget {
  final UserModel user;
  final Function(int) onTabChanged;

  const _DashboardHomeView({required this.user, required this.onTabChanged});

  // ── helpers ─────────────────────────────────────────────────────────────────

  String get _avatarUrl {
    if (user.profilePictureUrl.isNotEmpty) return user.profilePictureUrl;
    if (user.photoUrl?.isNotEmpty == true) return user.photoUrl!;
    return '';
  }

  // Creator level (new names per spec)
  ({String emoji, String label, Color color, double progress}) get _level {
    final f = user.followersCount;
    final a = user.analysesPerformed;
    final s = user.appStreak;
    // weight followers + activity
    if (f >= 50000 || (f >= 20000 && a >= 20)) {
      return (emoji: '🏆', label: 'Established Creator', color: const Color(0xFFFFD700), progress: 1.0);
    } else if (f >= 10000 || (f >= 3000 && a >= 10)) {
      return (emoji: '📈', label: 'Growing Creator', color: const Color(0xFF10B981), progress: min(f / 50000.0, 0.99));
    } else if (f >= 1000 || (f >= 300 && a >= 3)) {
      return (emoji: '🚀', label: 'Emerging Creator', color: AppTheme.primary, progress: min(f / 10000.0, 0.99));
    } else {
      return (emoji: '🌱', label: 'New Creator', color: const Color(0xFF94A3B8), progress: min(max(f / 1000.0, s / 30.0), 0.99));
    }
  }

  // AI Creator Summary — from user data only
  String get _creatorSummary {
    final niche = user.niche.isNotEmpty ? user.niche : 'your niche';
    final eng   = user.engagementRate;
    final conf  = user.cameraConfidence;
    final f     = user.followersCount;

    if (conf == 'Camera Shy' || conf == 'Nervous') {
      return 'Your content performs best as a faceless brand in $niche. '
          'Your strongest growth opportunity is improving hook strength in the first 3 seconds '
          'with compelling text overlays and strong audio choices.';
    }
    if (eng > 5.0) {
      return 'Your audience genuinely connects with your $niche content — above-average engagement proves it. '
          'Your strongest opportunity is combining educational storytelling with personal experiences '
          'to drive shares and saves.';
    }
    if (f > 10000) {
      return 'You have an established audience in $niche. '
          'Content that combines educational value with personal storytelling consistently outperforms for creators at your stage. '
          'Focus on improving hook strength to convert reach into loyal followers.';
    }
    return 'You\'re building momentum in $niche with ${_formatFollowers(f)} followers. '
        'Your content performs best when you combine educational storytelling with personal experiences. '
        'Your strongest growth opportunity is improving hook strength in the first 3 seconds.';
  }

  // AI Growth Insight — one punchy sentence
  String get _growthInsight {
    final eng = user.engagementRate;
    final f   = user.followersCount;
    final s   = user.appStreak;

    if (eng < 2.0) {
      return 'Your reels appear to lose viewers within the first few seconds. Focus on stronger curiosity-based hooks — start with a question or bold statement, never a greeting.';
    }
    if (s < 3) {
      return 'Irregular posting is your biggest growth blocker right now. The algorithm rewards consistent creators — aim for the same 3 days each week.';
    }
    if (f < 1000 && eng >= 3.0) {
      return 'You have solid engagement but limited reach. Prioritize Explore-friendly content — use trending audio and hook viewers in the first 1.5 seconds.';
    }
    if (eng > 5.0) {
      return 'Your engagement is strong. The next lever is increasing posting frequency to 4–5 times per week — this is the fastest path to your next follower milestone.';
    }
    return 'Reels with educational hooks in the first 2 seconds outperform for ${user.niche.isNotEmpty ? user.niche : "your niche"} creators. Test a "Did you know…" opening on your next reel.';
  }

  // Today's Growth Focus — AI coach style
  List<String> get _growthFocus {
    final eng = user.engagementRate;
    final s   = user.appStreak;
    final f   = user.followersCount;

    if (eng < 2.5) {
      return [
        'Strengthen your opening hook — rewrite before posting',
        'Test 3 different hook variations in Hook Lab',
        'Avoid starting with greetings — open with value',
      ];
    }
    if (s < 3) {
      return [
        'Post before 6 PM for maximum reach today',
        'Batch-record 2 reels to stay ahead of schedule',
        'Set a recurring reminder for your posting days',
      ];
    }
    if (f < 1000) {
      return [
        'Use trending audio to boost Explore visibility',
        'Add 3–5 niche-specific hashtags to your next post',
        'Engage in comments on 5 creator accounts in your niche',
      ];
    }
    return [
      'Strengthen opening hooks — first 2 seconds are critical',
      'Post before 6 PM for best algorithmic timing',
      'Test 3 hook variations using Hook Lab today',
    ];
  }

  // Bottom sheet data
  String get _whatsWorking {
    if (user.engagementRate > 4.0) {
      return 'Your engagement rate is above platform average — your audience genuinely connects with your content. Reels with strong hooks in the first 2 seconds are performing best for creators in your niche.';
    }
    return 'Your consistency is building momentum. Creators in ${user.niche.isNotEmpty ? user.niche : "your niche"} who post 4–5 times per week see 3× faster follower growth in months 2–3.';
  }

  String get _whatsHurting {
    if (user.engagementRate < 3.0) {
      return 'Low engagement signals the algorithm is reducing your reach. Fix: Open every reel with a pattern-interrupt hook in the first 1.5 seconds. Avoid generic intros — they kill watch time immediately.';
    }
    return 'Posting irregularity is your biggest growth blocker. The Instagram algorithm rewards creators who publish on a predictable schedule. Aim for the same 2–3 days per week, same time slots.';
  }

  String get _nextReelIdea {
    final niche = user.niche.isNotEmpty ? user.niche : 'your niche';
    final ideas = [
      '"I tried $niche for 30 days — here\'s what happened" → trend + personal story format',
      '"5 things nobody tells you about $niche" → list format with pattern interrupts',
      '"POV: you discover $niche for the first time" → relatable hook, high shareability',
      '"The $niche mistake that cost me followers" → curiosity + cautionary tale hook',
    ];
    return ideas[user.appStreak % ideas.length];
  }

  String get _postingSuggestion {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = days[DateTime.now().weekday - 1];
    return 'Best time to post today ($today): 6:00 PM – 8:00 PM local time. '
        'Engagement peaks on Tuesday–Friday for ${user.niche.isNotEmpty ? user.niche : "creator"} content. '
        'Post 4–5 times per week for maximum algorithmic reach.';
  }

  String _formatFollowers(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  void _openAI(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => _AISheet(
        userName: user.displayName.isNotEmpty ? user.displayName.split(' ').first : 'Creator',
        growthSummary: 'You\'re at ${_level.label} level with ${_formatFollowers(user.followersCount)} followers. '
            'Based on your ${user.niche.isNotEmpty ? user.niche : "content"} niche and '
            '${user.engagementRate.toStringAsFixed(1)}% engagement, '
            'you\'re on track to ${user.followersCount < 10000 ? "hit 10K" : "reach 100K"} '
            'within the next 60–90 days with consistent posting.',
        whatsWorking: _whatsWorking,
        whatsHurting: _whatsHurting,
        nextReelIdea: _nextReelIdea,
        postingSuggestion: _postingSuggestion,
      ),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm    = Provider.of<DashboardViewModel>(context);
    final level = _level;

    // Latest reel (index 0) separated from older ones
    final latest = vm.analyses.isNotEmpty ? vm.analyses.first : null;
    final older  = vm.analyses.length > 1 ? vm.analyses.sublist(1, min(vm.analyses.length, 5)) : <dynamic>[];

    return RefreshIndicator(
      onRefresh: () => vm.loadAnalyses(user.uid),
      color: AppTheme.primary,
      backgroundColor: const Color(0xFF111111),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── 1. HERO PROFILE CARD ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
              child: _HeroCard(
                user: user,
                avatarUrl: _avatarUrl,
                level: level,
                summary: _creatorSummary,
                onAITap: () => _openAI(context),
                formatFollowers: _formatFollowers,
              ),
            ),
          ),

          // ── 2. AI GROWTH INSIGHT ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _GrowthInsightCard(insight: _growthInsight),
            ),
          ),

          // ── 3. LATEST REEL AUDIT (featured) ──────────────────────────────
          if (vm.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
              ),
            )
          else if (latest != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _FeaturedAuditCard(
                  item: latest,
                  onTap: () => context.push('/analysis/${latest.id}'),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _EmptyAuditCard(onTap: () => onTabChanged(1)),
              ),
            ),

          // ── 4. CONTENT SIGNALS ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _ContentSignalsCard(vm: vm),
            ),
          ),

          // ── 5. TODAY'S GROWTH FOCUS ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _GrowthFocusCard(focuses: _growthFocus),
            ),
          ),

          // ── 6. QUICK ACTIONS ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _QuickActions(
                onAnalyze:     () => onTabChanged(1),
                onPlan:        () => onTabChanged(2),
                onHookLab:     () => context.push('/hook-testing'),
                onProfileAudit: () => context.push('/profile'),
              ),
            ),
          ),

          // ── 7. OLDER REEL AUDITS ──────────────────────────────────────────
          if (older.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
                child: Row(
                  children: [
                    const Text(
                      'Previous Audits',
                      style: TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => onTabChanged(1),
                      child: const Text(
                        'See all',
                        style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CompactAuditCard(
                      item: older[i],
                      onTap: () => context.push('/analysis/${older[i].id}'),
                    ),
                  ),
                  childCount: older.length,
                ),
              ),
            ),
          ],

          if (vm.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(vm.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. HERO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final UserModel user;
  final String avatarUrl;
  final ({String emoji, String label, Color color, double progress}) level;
  final String summary;
  final VoidCallback onAITap;
  final String Function(int) formatFollowers;

  const _HeroCard({
    required this.user,
    required this.avatarUrl,
    required this.level,
    required this.summary,
    required this.onAITap,
    required this.formatFollowers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1C1C1C), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Top row: avatar + name + badges ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF141414),
                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person_rounded, color: Color(0xFF4A4A4A), size: 26)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + handle
                        // Only show @handle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user.instagramHandle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user.instagramHandle.startsWith('@')
                                      ? user.instagramHandle
                                      : '@${user.instagramHandle}',
                                  style: const TextStyle(
                                    color: Color(0xFF4A4A4A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                // Streak + Ask AI pill
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Streak
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.18), width: 0.6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 3),
                          Text(
                            '${user.appStreak}d',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Ask AI pill
                    GestureDetector(
                      onTap: onAITap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A1040), Color(0xFF1A0A30)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 0.7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 11, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Ask AI',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Creator level pill ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: level.color.withOpacity(0.2), width: 0.7),
                  ),
                  child: Text(
                    '${level.emoji}  ${level.label}',
                    style: TextStyle(
                      color: level.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: level.progress),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 3,
                        backgroundColor: const Color(0xFF1A1A1A),
                        valueColor: AlwaysStoppedAnimation<Color>(level.color),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Metrics row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              children: [
                // Unified metric row: Posts, Reels, Followers, Following
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1C1C1C), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      _MetricCell(
                        label: 'Posts',
                        value: formatFollowers(user.totalPosts),
                        color: const Color(0xFF3B82F6),
                      ),
                      _VDiv(),
                      _MetricCell(
                        label: 'Reels',
                        value: formatFollowers(user.totalReels),
                        color: const Color(0xFF8B5CF6),
                      ),
                      _VDiv(),
                      _MetricCell(
                        label: 'Followers',
                        value: formatFollowers(user.followersCount),
                        color: AppTheme.primary,
                      ),
                      _VDiv(),
                      _MetricCell(
                        label: 'Following',
                        value: formatFollowers(user.followingCount),
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Creator Performance Score ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 4,
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Creator Performance Score: AI‑generated evaluation of your overall creator health, based on followers, engagement, posting frequency, and reel performance.',
                      child: const Text(
                        'CREATOR PERFORMANCE SCORE',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Color(0xFF8A9BB0),
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MetricCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: Color(0xFF3A3A3A), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _VDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 32, color: const Color(0xFF1C1C1C));
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. AI GROWTH INSIGHT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _GrowthInsightCard extends StatelessWidget {
  final String insight;
  const _GrowthInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient accent top-left
          Positioned(
            top: 0, left: 0,
            child: Container(
              width: 120, height: 60,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                gradient: RadialGradient(
                  colors: [AppTheme.primary.withOpacity(0.12), Colors.transparent],
                  radius: 1.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary.withOpacity(0.15), AppTheme.primary.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 0.6),
                  ),
                  child: Text('💡', style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI GROWTH INSIGHT',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        insight,
                        style: const TextStyle(
                          color: Color(0xFFCDD5E0),
                          fontSize: 13.5,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. FEATURED LATEST REEL AUDIT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedAuditCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  const _FeaturedAuditCard({required this.item, required this.onTap});

  Color _hookColor(String s) {
    switch (s.toLowerCase()) {
      case 'strong': return const Color(0xFF10B981);
      case 'moderate': return const Color(0xFFF59E0B);
      default: return const Color(0xFFEF4444);
    }
  }

  Color _retentionColor(String s) {
    switch (s.toLowerCase()) {
      case 'high': return const Color(0xFF10B981);
      case 'medium': return const Color(0xFFF59E0B);
      default: return const Color(0xFFEF4444);
    }
  }

  Color get _scoreColor {
    final s = item.viralScore as int;
    if (s >= 75) return const Color(0xFF10B981);
    if (s >= 50) return AppTheme.accent;
    return AppTheme.primary;
  }

  // AI insight derived from scores
  String get _aiInsight {
    final hook = (item.hookStrength as String).toLowerCase();
    final ret  = (item.retentionPrediction as String).toLowerCase();
    final score = item.viralScore as int;

    if (hook == 'strong' && ret == 'high') {
      return 'Excellent reel — strong hook and high retention. Replicate this format for your next post.';
    }
    if (hook == 'strong' && ret != 'high') {
      return 'The opening hook works, but viewers are dropping off mid-reel. Try adding a pattern interrupt at the halfway mark.';
    }
    if (hook != 'strong' && ret == 'high') {
      return 'Good retention once viewers are in — but you\'re losing people in the first 3 seconds. Rewrite the hook to open with curiosity.';
    }
    if (score < 50) {
      return 'This reel needs significant improvements. Start by rewriting the hook to open with a bold question or statement.';
    }
    return 'Solid performance. The opening hook works but the transition pacing could be tightened to improve retention.';
  }

  @override
  Widget build(BuildContext context) {
    final hc = _hookColor(item.hookStrength as String);
    final rc = _retentionColor(item.retentionPrediction as String);
    final sc = _scoreColor;
    const double ringSize = 72;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1C1C1C), width: 0.7),
          boxShadow: [
            BoxShadow(
              color: sc.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header label
            Row(
              children: [
                const Text(
                  'LATEST AUDIT',
                  style: TextStyle(
                    color: Color(0xFF3A3A3A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF2A2A2A), size: 18),
              ],
            ),
            const SizedBox(height: 14),

            // Score ring + title + badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Large score ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: (item.viralScore as int) / 100.0),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: 5,
                          backgroundColor: const Color(0xFF1A1A1A),
                          valueColor: AlwaysStoppedAnimation<Color>(sc),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.viralScore}',
                          style: TextStyle(
                            color: sc,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          'score',
                          style: TextStyle(color: Color(0xFF3A3A3A), fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Badge(label: 'Hook', value: item.hookStrength as String, color: hc),
                          const SizedBox(width: 8),
                          _Badge(label: 'Retention', value: item.retentionPrediction as String, color: rc),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(height: 0.5, color: const Color(0xFF141414)),
            ),

            // AI Insight
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✦', style: TextStyle(color: AppTheme.primary, fontSize: 11)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _aiInsight,
                    style: const TextStyle(
                      color: Color(0xFF8A9BB0),
                      fontSize: 12.5,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. CONTENT SIGNALS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ContentSignalsCard extends StatelessWidget {
  final DashboardViewModel vm;
  const _ContentSignalsCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    // Derive signals from real data
    final avgScore = vm.averageViralScore;
    final analysisCount = vm.totalReelsAnalyzed;

    // Hook Strength: from average hookScore across analyses, fallback to avgViralScore
    final hookSignal = () {
      if (vm.analyses.isEmpty) return 0;
      final total = vm.analyses.fold<int>(0, (s, a) => s + (a.hookScore as int));
      return (total / vm.analyses.length).round();
    }();

    // Storytelling: from captionScore average
    final storySignal = () {
      if (vm.analyses.isEmpty) return 0;
      final total = vm.analyses.fold<int>(0, (s, a) => s + (a.captionScore as int));
      return (total / vm.analyses.length).round();
    }();

    // Consistency: derived from number of analyses (more audits = more active creator)
    final consistencySignal = min(analysisCount * 10, 100);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1C1C1C), width: 0.7),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.graphic_eq_rounded, size: 15, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Content Signals',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (analysisCount == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Analyze reels to unlock',
                    style: TextStyle(color: Color(0xFF3A3A3A), fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _SignalBar(
            label: 'Hook Strength',
            score: analysisCount > 0 ? hookSignal : 0,
            color: AppTheme.primary,
            locked: analysisCount == 0,
          ),
          const SizedBox(height: 14),
          _SignalBar(
            label: 'Storytelling Quality',
            score: analysisCount > 0 ? storySignal : 0,
            color: const Color(0xFF6366F1),
            locked: analysisCount == 0,
          ),
          const SizedBox(height: 14),
          _SignalBar(
            label: 'Posting Consistency',
            score: consistencySignal,
            color: const Color(0xFF10B981),
            locked: false,
          ),
        ],
      ),
    );
  }
}

class _SignalBar extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool locked;

  const _SignalBar({
    required this.label,
    required this.score,
    required this.color,
    required this.locked,
  });

  String get _label {
    if (locked) return 'No data';
    if (score >= 75) return 'Strong';
    if (score >= 50) return 'Average';
    return 'Needs Work';
  }

  Color get _labelColor {
    if (locked) return const Color(0xFF2A2A2A);
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF8A9BB0), fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (!locked)
              Text(
                score.toString(),
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _labelColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_label,
                  style: TextStyle(color: _labelColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: locked ? 0 : score / 100.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 4,
              backgroundColor: const Color(0xFF141414),
              valueColor: AlwaysStoppedAnimation<Color>(locked ? const Color(0xFF1A1A1A) : color),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. TODAY'S GROWTH FOCUS
// ─────────────────────────────────────────────────────────────────────────────

class _GrowthFocusCard extends StatelessWidget {
  final List<String> focuses;
  const _GrowthFocusCard({required this.focuses});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1C1C1C), width: 0.7),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🎯', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 10),
              const Text(
                "Today's Growth Focus",
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...focuses.asMap().entries.map((e) {
            return Padding(
              padding: EdgeInsets.only(bottom: e.key < focuses.length - 1 ? 10 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        color: Color(0xFF8A9BB0),
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. QUICK ACTIONS
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final VoidCallback onAnalyze, onPlan, onHookLab, onProfileAudit;
  const _QuickActions({
    required this.onAnalyze,
    required this.onPlan,
    required this.onHookLab,
    required this.onProfileAudit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        // Primary row — full-width gradient tiles
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.analytics_rounded,
                label: 'Analyze Reel',
                sub: 'AI score + insights',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4D8D), Color(0xFFFF8A5B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: onAnalyze,
                primary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.calendar_month_rounded,
                label: 'Generate Plan',
                sub: 'AI content calendar',
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: onPlan,
                primary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Secondary row
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.science_rounded,
                label: 'Hook Lab',
                sub: 'Test hooks',
                color: const Color(0xFF10B981),
                onTap: onHookLab,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.manage_accounts_rounded,
                label: 'Profile Audit',
                sub: 'Optimise bio',
                color: const Color(0xFFF59E0B),
                onTap: onProfileAudit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label, sub;
  final VoidCallback onTap;
  final bool primary;
  final LinearGradient? gradient;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
    this.primary = false,
    this.gradient,
    this.color,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 110),
    vsync: this,
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.95).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppTheme.primary;
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.selectionClick(); _ctrl.forward(); },
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.primary ? widget.gradient : null,
            color: widget.primary ? null : const Color(0xFF0A0A0A),
            border: Border.all(
              color: widget.primary ? Colors.transparent : c.withOpacity(0.14),
              width: 0.7,
            ),
            boxShadow: widget.primary
                ? [BoxShadow(
                    color: (widget.gradient?.colors.first ?? AppTheme.primary).withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: widget.primary ? Colors.white.withOpacity(0.15) : c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 16, color: widget.primary ? Colors.white : c),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.primary ? Colors.white : const Color(0xFFF8FAFC),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.sub,
                style: TextStyle(
                  color: widget.primary ? Colors.white.withOpacity(0.6) : const Color(0xFF3A3A3A),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. COMPACT AUDIT CARD (older audits)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactAuditCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  const _CompactAuditCard({required this.item, required this.onTap});

  Color _hookColor(String s) {
    switch (s.toLowerCase()) {
      case 'strong': return const Color(0xFF10B981);
      case 'moderate': return const Color(0xFFF59E0B);
      default: return const Color(0xFFEF4444);
    }
  }

  Color _retColor(String s) {
    switch (s.toLowerCase()) {
      case 'high': return const Color(0xFF10B981);
      case 'medium': return const Color(0xFFF59E0B);
      default: return const Color(0xFFEF4444);
    }
  }

  Color get _scoreColor {
    final s = item.viralScore as int;
    if (s >= 75) return const Color(0xFF10B981);
    if (s >= 50) return AppTheme.accent;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final sc = _scoreColor;
    const sz = 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF080808),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF141414), width: 0.5),
        ),
        child: Row(
          children: [
            // Score ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: sz, height: sz,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (item.viralScore as int) / 100.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 3.5,
                      backgroundColor: const Color(0xFF1A1A1A),
                      valueColor: AlwaysStoppedAnimation<Color>(sc),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Text(
                  '${item.viralScore}',
                  style: TextStyle(color: sc, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Badge(label: 'Hook', value: item.hookStrength as String, color: _hookColor(item.hookStrength as String)),
                      const SizedBox(width: 6),
                      _Badge(label: 'Retention', value: item.retentionPrediction as String, color: _retColor(item.retentionPrediction as String)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF2A2A2A), size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY AUDIT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyAuditCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyAuditCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1C1C1C), width: 0.7),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_collection_outlined, size: 26, color: AppTheme.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'No reels analyzed yet',
              style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload your first reel for an AI-powered\nscore, hook rating, and actionable insights.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF3A3A3A), fontSize: 12.5, height: 1.55),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Analyze Your First Reel',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: Badge
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Badge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.18), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 10, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI ASSISTANT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AISheet extends StatelessWidget {
  final String userName, growthSummary, whatsWorking, whatsHurting, nextReelIdea, postingSuggestion;
  const _AISheet({
    required this.userName,
    required this.growthSummary,
    required this.whatsWorking,
    required this.whatsHurting,
    required this.nextReelIdea,
    required this.postingSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.88, 0.95],
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF060606),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(
            top: BorderSide(color: Color(0xFF1A1A1A), width: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 32, height: 3,
                decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Creator Assistant',
                          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                        ),
                        Text(
                          'Hey $userName — here\'s your growth intel',
                          style: const TextStyle(color: Color(0xFF3A3A3A), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1C1C1C), width: 0.6),
                      ),
                      child: const Icon(Icons.close_rounded, size: 15, color: Color(0xFF4A4A4A)),
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 0.5, color: const Color(0xFF101010)),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _AISection(icon: Icons.trending_up_rounded, color: const Color(0xFF10B981), title: 'Growth Summary', body: growthSummary),
                  const SizedBox(height: 14),
                  _AISection(icon: Icons.thumb_up_rounded, color: AppTheme.primary, title: "What's Working", body: whatsWorking),
                  const SizedBox(height: 14),
                  _AISection(icon: Icons.warning_amber_rounded, color: const Color(0xFFF59E0B), title: "What's Hurting Growth", body: whatsHurting),
                  const SizedBox(height: 14),
                  _AISection(
                    icon: Icons.lightbulb_rounded,
                    color: const Color(0xFF6366F1),
                    title: 'Next Reel Idea',
                    body: nextReelIdea,
                    highlight: true,
                  ),
                  const SizedBox(height: 14),
                  _AISection(icon: Icons.schedule_rounded, color: AppTheme.accent, title: 'Posting Suggestions', body: postingSuggestion),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AISection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;
  final bool highlight;

  const _AISection({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.05) : const Color(0xFF0C0C0C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? color.withOpacity(0.18) : const Color(0xFF141414),
          width: 0.7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: TextStyle(
                  color: highlight ? color : const Color(0xFFF8FAFC),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF8A9BB0),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
