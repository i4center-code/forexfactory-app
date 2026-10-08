import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'endpoints.dart';

/// Error returned by the API envelope `{ok:false, error:{code,message,fields?}}`
/// or produced locally for network / parse failures.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final Map<String, String>? fields;
  /// Seconds from HTTP `Retry-After` (429 / rate_limited / quota_exceeded).
  final int? retryAfterSeconds;

  const ApiException(
    this.code,
    this.message, {
    this.statusCode,
    this.fields,
    this.retryAfterSeconds,
  });

  bool get isTokenExpired => code == 'token_expired';
  bool get isInvalidToken => code == 'invalid_token';
  bool get isNetwork => code == 'network_error';
  bool get isInsufficientBalance => code == 'insufficient_balance' || statusCode == 402;
  bool get isForbidden =>
      statusCode == 403 ||
      code == 'forbidden' ||
      code == 'subscription_required' ||
      code == 'subscription_expired' ||
      code == 'plan_scope';
  bool get isConflict =>
      statusCode == 409 ||
      code == 'idempotency_conflict' ||
      code == 'key_limit_reached' ||
      code == 'code_taken';
  bool get isNotFound => statusCode == 404 || code == 'not_found';
  bool get isRateLimited => code == 'rate_limited' || code == 'quota_exceeded' || statusCode == 429;

  static const _faDigits = '۰۱۲۳۴۵۶۷۸۹';
  static String _toFaDigits(String input) {
    final buf = StringBuffer();
    for (final cu in input.codeUnits) {
      final ch = String.fromCharCode(cu);
      final i = '0123456789'.indexOf(ch);
      buf.write(i >= 0 ? _faDigits[i] : ch);
    }
    return buf.toString();
  }

  /// Parse `Retry-After` header: integer seconds (preferred) or HTTP-date (ignored → null).
  static int? parseRetryAfter(http.Response res) {
    final raw = res.headers['retry-after'] ?? res.headers['Retry-After'];
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final secs = int.tryParse(s);
    if (secs != null && secs >= 0) return secs;
    return null; // HTTP-date form not used by this API
  }

  /// Persian-friendly message for common sales / auth codes.
  String get displayMessage {
    switch (code) {
      case 'invalid_credentials':
        return 'ایمیل یا رمز عبور نادرست است';
      case 'account_disabled':
        return 'حساب کاربری غیرفعال است';
      case 'email_taken':
        return 'این ایمیل قبلاً ثبت شده است';
      case 'username_taken':
        return 'این نام کاربری قبلاً گرفته شده است';
      case 'insufficient_balance': // 402
        return 'برای خرید این پلن موجودی کیف پولتان کم است. لطفاً از پشتیبانی شارژ حساب بگیرید و دوباره تلاش کنید — support@forexfactoryiran.ir';
      case 'subscription_required': // 403
        return 'مدت پلن API به پایان رسیده است. برای ادامه، یکی از پلن‌ها را دوباره بخرید.';
      case 'key_limit_reached': // 409
        return 'به سقف تعداد کلیدهای فعال این اشتراک رسیده‌اید؛ یک کلید قدیمی را باطل کنید یا صبر کنید تا جا خالی شود.';
      case 'code_taken': // 409
        return 'این کد پلن قبلاً استفاده شده است.';
      case 'forbidden': // 403
        return 'دسترسی مجاز نیست.';
      case 'not_found':
        return 'مورد درخواستی یافت نشد.';
      case 'invalid_type':
        return 'نوع تقویم نامعتبر است.';
      case 'rate_limited': // 429 — QUOTA_NOTES daily quota (or minute; prefer daily copy)
      case 'quota_exceeded':
        final ra = retryAfterSeconds;
        if (ra != null && ra > 0) {
          return 'سقف درخواست روزانهٔ پلن شما پر شده. حدود ${_toFaDigits('$ra')} ثانیه دیگر دوباره می‌توانید درخواست بفرستید — یا فردا پس از صفر شدن شمارندهٔ روزانه.';
        }
        return 'سقف درخواست روزانهٔ پلن شما پر شده. لطفاً فردا دوباره تلاش کنید یا پلن با سقف بالاتر بخرید.';
      case 'invalid_api_key':
        return 'کلید API نامعتبر یا موجود نیست.';
      case 'subscription_expired': // 403
        return 'مدت پلن API به پایان رسیده است. برای ادامه، یکی از پلن‌ها را دوباره بخرید.';
      case 'plan_scope': // 403
        return 'این نوع تقویم در پلن شما نیست.';
      case 'validation_error':
        if (fields != null && fields!.isNotEmpty) {
          return fields!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        }
        return message.isNotEmpty ? message : 'خطای اعتبارسنجی';
      case 'idempotency_conflict': // 409
        return 'این درخواست قبلاً با همین شناسه ثبت شده؛ نتیجهٔ قبلی را ببینید و دوباره دکمه را نزنید.';
      case 'not_renewable': // 409
        return 'این اشتراک لغو شده است. برای ادامه یک پلن را دوباره بخرید.';
      case 'already_cancelled': // 409
        return 'این اشتراک از قبل لغو شده است.';
      case 'calendar_unavailable':
        return 'داده تقویم در دسترس نیست.';
      case 'network_error':
        return 'ارتباط برقرار نشد. اتصال اینترنت را چک کنید و دوباره تلاش کنید.';
      default:
        return message.isNotEmpty ? message : 'خطای ناشناخته ($code)';
    }
  }

  @override
  String toString() =>
      'ApiException($code, $message, status=$statusCode, retryAfter=$retryAfterSeconds)';
}

/// Low-level JSON client that unwraps the `{ok, data}` envelope.
class ApiClient {
  ApiClient({http.Client? httpClient, String baseUrl = BASE_URL})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  final http.Client _http;
  final String _baseUrl;
  static const Duration timeout = Duration(seconds: 20);

  String get baseUrl => _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    return (query == null || query.isEmpty) ? uri : uri.replace(queryParameters: query);
  }

  Map<String, String> _headers({
    String? bearer,
    String? apiKey,
    bool json = false,
    Map<String, String>? extra,
  }) =>
      {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json; charset=utf-8',
        if (bearer != null && bearer.isNotEmpty) 'Authorization': 'Bearer $bearer',
        if (apiKey != null && apiKey.isNotEmpty) 'X-API-Key': apiKey,
        if (extra != null) ...extra,
      };

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    String? bearer,
    String? apiKey,
    Map<String, String>? headers,
  }) {
    return _send(() => _http.get(
          _uri(path, query),
          headers: _headers(bearer: bearer, apiKey: apiKey, extra: headers),
        ));
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    String? bearer,
    Map<String, String>? headers,
  }) {
    return _send(() => _http.post(
          _uri(path),
          headers: _headers(bearer: bearer, json: true, extra: headers),
          body: jsonEncode(body),
        ));
  }

  Future<dynamic> delete(String path, {String? bearer, Map<String, String>? headers}) {
    return _send(() => _http.delete(
          _uri(path),
          headers: _headers(bearer: bearer, extra: headers),
        ));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('network_error', 'ارتباط برقرار نشد. اتصال اینترنت را چک کنید و دوباره تلاش کنید.');
    } catch (e) {
      // On web, a CORS rejection also lands here (ClientException: XMLHttpRequest error).
      throw const ApiException('network_error', 'ارتباط برقرار نشد. اتصال اینترنت را چک کنید و دوباره تلاش کنید.');
    }

    final retryAfter = ApiException.parseRetryAfter(res);

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException(
        'bad_response',
        'پاسخ نامعتبر از سرور (HTTP ${res.statusCode})',
        statusCode: res.statusCode,
        retryAfterSeconds: retryAfter,
      );
    }

    if (decoded is Map<String, dynamic>) {
      if (decoded['ok'] == true) return decoded['data'];
      final err = decoded['error'];
      if (err is Map) {
        Map<String, String>? fields;
        final rawFields = err['fields'];
        if (rawFields is Map) {
          fields = rawFields.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        throw ApiException(
          (err['code'] ?? 'unknown_error').toString(),
          (err['message'] ?? 'خطای ناشناخته').toString(),
          statusCode: res.statusCode,
          fields: fields,
          retryAfterSeconds: retryAfter,
        );
      }
    }
    throw ApiException(
      'bad_response',
      'ساختار پاسخ نامعتبر (HTTP ${res.statusCode})',
      statusCode: res.statusCode,
      retryAfterSeconds: retryAfter,
    );
  }

  void close() => _http.close();
}
