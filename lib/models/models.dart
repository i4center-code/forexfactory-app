/// Data models for the FFI mobile API. Parsing is defensive: unknown or
/// missing fields fall back to empty values instead of throwing.
String _s(dynamic v) => v == null ? '' : v.toString();

int _i(dynamic v, [int d = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(_s(v)) ?? d;
}

bool _b(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = _s(v).toLowerCase();
  return s == '1' || s == 'true';
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

class CalendarEvent {
  final String title;
  final String titleFa;
  final String country;
  final DateTime? date;
  final String impact;
  final String forecast;
  final String previous;
  final String actual;
  /// Persian analysis text from calendar `analyses` map (keyed by English title).
  final String analysisFa;
  /// English analysis text from calendar `analyses` map.
  final String analysisEn;

  const CalendarEvent({
    required this.title,
    required this.titleFa,
    required this.country,
    required this.date,
    required this.impact,
    required this.forecast,
    required this.previous,
    required this.actual,
    this.analysisFa = '',
    this.analysisEn = '',
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> j, {String analysisFa = '', String analysisEn = ''}) =>
      CalendarEvent(
        title: _s(j['title']),
        titleFa: _s(j['title_fa']),
        country: _s(j['country']),
        date: _date(j['date']),
        impact: _s(j['impact']),
        forecast: _s(j['forecast']),
        previous: _s(j['previous']),
        actual: _s(j['actual']),
        analysisFa: analysisFa,
        analysisEn: analysisEn,
      );

  String get displayTitle => titleFa.isNotEmpty ? titleFa : title;

  bool get hasAnalysis => analysisFa.isNotEmpty || analysisEn.isNotEmpty;

  /// Prefer Persian analysis; fall back to English.
  String get displayAnalysis => analysisFa.isNotEmpty ? analysisFa : analysisEn;

  CalendarEvent withAnalysis({String fa = '', String en = ''}) => CalendarEvent(
        title: title,
        titleFa: titleFa,
        country: country,
        date: date,
        impact: impact,
        forecast: forecast,
        previous: previous,
        actual: actual,
        analysisFa: fa,
        analysisEn: en,
      );
}

class CalendarResult {
  final List<CalendarEvent> events;
  final DateTime? generatedAt;
  final bool fromPaidEndpoint;
  final String? fallbackNote;
  /// Raw analyses map from API: event English title → {fa, en}.
  final Map<String, Map<String, String>> analyses;

  const CalendarResult(
    this.events,
    this.generatedAt, {
    this.fromPaidEndpoint = false,
    this.fallbackNote,
    this.analyses = const {},
  });

  factory CalendarResult.fromJson(
    dynamic data, {
    bool fromPaidEndpoint = false,
    String? fallbackNote,
  }) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final raw = map['events'] is List ? map['events'] as List : (data is List ? data : const []);

    final analyses = <String, Map<String, String>>{};
    final rawAnalyses = map['analyses'];
    if (rawAnalyses is Map) {
      rawAnalyses.forEach((key, value) {
        if (value is Map) {
          analyses[key.toString()] = {
            'fa': _s(value['fa']),
            'en': _s(value['en']),
          };
        } else if (value != null && value.toString().isNotEmpty) {
          // Tolerate a plain string analysis.
          analyses[key.toString()] = {'fa': value.toString(), 'en': ''};
        }
      });
    }

    final events = raw.whereType<Map>().map((e) {
      final j = Map<String, dynamic>.from(e);
      final title = _s(j['title']);
      final a = analyses[title];
      return CalendarEvent.fromJson(
        j,
        analysisFa: a?['fa'] ?? '',
        analysisEn: a?['en'] ?? '',
      );
    }).toList();

    return CalendarResult(
      events,
      _date(map['generated_at']),
      fromPaidEndpoint: fromPaidEndpoint,
      fallbackNote: fallbackNote,
      analyses: analyses,
    );
  }
}

class NewsItem {
  final int id;
  final String title;
  final String summary;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String source;

  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.source,
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        id: _i(j['id']),
        title: _s(j['title']),
        summary: _s(j['summary']),
        url: _s(j['url']),
        imageUrl: (j['image_url'] == null || _s(j['image_url']).isEmpty) ? null : _s(j['image_url']),
        publishedAt: _date(j['published_at']),
        source: _s(j['source']),
      );
}

class NewsPage {
  final List<NewsItem> items;
  final int page;
  final int totalPages;
  final int total;
  const NewsPage(this.items, this.page, this.totalPages, this.total);

  bool get hasMore => page < totalPages;

  factory NewsPage.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final raw = map['items'] is List ? map['items'] as List : const [];
    final meta = map['meta'] is Map ? map['meta'] as Map : const {};
    return NewsPage(
      raw.whereType<Map>().map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      _i(meta['page'], 1),
      _i(meta['total_pages'], 1),
      _i(meta['total'], raw.length),
    );
  }
}

/// Profile from GET /me (and optionally nested `user` from login/register).
///
/// Real /me shape:
/// `{id, username, email, email_verified, full_name, balance, status, last_login, created_at}`
///
/// Login/register `user` shape:
/// `{id, username, email, name}`  (name = full_name; username may be null)
class UserProfile {
  final Map<String, dynamic> raw;
  const UserProfile(this.raw);

  factory UserProfile.fromJson(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final u = map['user'];
      return UserProfile(u is Map ? Map<String, dynamic>.from(u) : map);
    }
    return const UserProfile({});
  }

  String get email => _s(raw['email']);
  /// Prefer full_name (/me), then name (auth tokens), then display_name.
  String get name => _s(raw['full_name'] ?? raw['name'] ?? raw['display_name']);
  String get username => _s(raw['username'] ?? raw['user_login']);
  String get id => _s(raw['id'] ?? raw['ID']);
  int get balance => _i(raw['balance']);
  String get status => _s(raw['status']);
  bool get emailVerified => _b(raw['email_verified']);
  DateTime? get lastLogin => _date(raw['last_login']);
  DateTime? get createdAt => _date(raw['created_at']);
}

/// Tokens returned by login/register/refresh.
///
/// Real shape (flat under `data`):
/// `{access_token, token_type, expires_in, refresh_token, refresh_expires_in, user:{...}}`
class AuthTokens {
  final String access;
  final String? refresh;
  final int? expiresIn;
  final int? refreshExpiresIn;
  final String? tokenType;
  final UserProfile? user;

  const AuthTokens(
    this.access,
    this.refresh, {
    this.expiresIn,
    this.refreshExpiresIn,
    this.tokenType,
    this.user,
  });

  static AuthTokens? tryParse(dynamic data) {
    if (data is! Map) return null;
    final Map src = data['tokens'] is Map ? data['tokens'] as Map : data;
    final access = _s(src['access_token'] ?? src['access']);
    if (access.isEmpty) return null;
    final refresh = _s(src['refresh_token'] ?? src['refresh']);
    UserProfile? user;
    final u = data['user'] ?? src['user'];
    if (u is Map) user = UserProfile.fromJson(u);
    return AuthTokens(
      access,
      refresh.isEmpty ? null : refresh,
      expiresIn: src['expires_in'] is num ? (src['expires_in'] as num).toInt() : int.tryParse(_s(src['expires_in'])),
      refreshExpiresIn: src['refresh_expires_in'] is num
          ? (src['refresh_expires_in'] as num).toInt()
          : int.tryParse(_s(src['refresh_expires_in'])),
      tokenType: _s(src['token_type']).isEmpty ? null : _s(src['token_type']),
      user: user,
    );
  }
}

/// Locally stored raw key (shown once at create; needed for X-API-Key calls).
class StoredApiKey {
  final int id;
  final String name;
  final String display;
  final String raw;
  final List<String> calendarTypes;

  const StoredApiKey({
    required this.id,
    required this.name,
    required this.display,
    required this.raw,
    required this.calendarTypes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'display': display,
        'raw': raw,
        'calendar_types': calendarTypes,
      };

  factory StoredApiKey.fromJson(Map<String, dynamic> j) => StoredApiKey(
        id: _i(j['id']),
        name: _s(j['name']),
        display: _s(j['display']),
        raw: _s(j['raw']),
        calendarTypes: j['calendar_types'] is List
            ? (j['calendar_types'] as List).map((e) => e.toString()).toList()
            : const [],
      );
}
