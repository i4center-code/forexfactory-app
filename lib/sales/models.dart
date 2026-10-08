import 'format.dart';

export 'format.dart' show formatToman, formatPlanPrice, purchaseSuccessMessage, toPersianDigits, parseSalesDate;

/// Active catalog plan from `GET /plans`.
class Plan {
  final int id;
  final String code;
  final String nameFa;
  final String nameEn;
  final String? descriptionFa;
  final int priceToman;
  final int durationDays;
  final List<String> calendarTypes;
  final int? dailyRequestLimit;
  final int? monthlyRequestLimit;
  final int rateLimitPerMin;
  final int sortOrder;

  const Plan({
    required this.id,
    required this.code,
    required this.nameFa,
    required this.nameEn,
    required this.descriptionFa,
    required this.priceToman,
    required this.durationDays,
    required this.calendarTypes,
    required this.dailyRequestLimit,
    required this.monthlyRequestLimit,
    required this.rateLimitPerMin,
    required this.sortOrder,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: asInt(j['id']),
        code: (j['code'] ?? '').toString(),
        nameFa: (j['name_fa'] ?? '').toString(),
        nameEn: (j['name_en'] ?? '').toString(),
        descriptionFa: j['description_fa']?.toString(),
        priceToman: asInt(j['price_toman']),
        durationDays: asInt(j['duration_days']),
        calendarTypes: asStringList(j['calendar_types']),
        dailyRequestLimit: asIntOrNull(j['daily_request_limit']),
        monthlyRequestLimit: asIntOrNull(j['monthly_request_limit']),
        rateLimitPerMin: asInt(j['rate_limit_per_min'], 60),
        sortOrder: asInt(j['sort_order']),
      );

  String get displayName => nameFa.isNotEmpty ? nameFa : nameEn;

  static List<Plan> listFromData(dynamic data) {
    final map = data is Map ? data : const {};
    final raw = map['plans'] is List ? map['plans'] as List : const [];
    return raw.whereType<Map>().map((e) => Plan.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}

class LedgerEntry {
  final int id;
  final int userId;
  final String type; // topup | purchase | refund | adjustment
  final int amountToman;
  final int balanceBefore;
  final int balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? paymentGateway;
  final String? gatewayRef;
  final String? idempotencyKey;
  final String? description;
  final String createdBy;
  final DateTime? createdAt;

  const LedgerEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.amountToman,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.referenceType,
    required this.referenceId,
    required this.paymentGateway,
    required this.gatewayRef,
    required this.idempotencyKey,
    required this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        id: asInt(j['id']),
        userId: asInt(j['user_id']),
        type: (j['type'] ?? '').toString(),
        amountToman: asInt(j['amount_toman']),
        balanceBefore: asInt(j['balance_before']),
        balanceAfter: asInt(j['balance_after']),
        referenceType: j['reference_type']?.toString(),
        referenceId: asIntOrNull(j['reference_id']),
        paymentGateway: j['payment_gateway']?.toString(),
        gatewayRef: j['gateway_ref']?.toString(),
        idempotencyKey: j['idempotency_key']?.toString(),
        description: j['description']?.toString(),
        createdBy: (j['created_by'] ?? '').toString(),
        createdAt: parseSalesDate(j['created_at']),
      );

  String get typeLabelFa {
    switch (type) {
      case 'topup':
        return 'شارژ';
      case 'purchase':
        return 'خرید اشتراک';
      case 'refund':
        return 'بازگشت وجه';
      case 'adjustment':
        return 'تعدیل';
      default:
        return type;
    }
  }
}

class Wallet {
  final int balance;
  final String currency;
  final String unit;
  final List<LedgerEntry> ledger;

  const Wallet({
    required this.balance,
    required this.currency,
    required this.unit,
    required this.ledger,
  });

  factory Wallet.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final raw = map['ledger'] is List ? map['ledger'] as List : const [];
    return Wallet(
      balance: asInt(map['balance']),
      currency: (map['currency'] ?? 'IRT').toString(),
      unit: (map['unit'] ?? 'toman').toString(),
      ledger: raw
          .whereType<Map>()
          .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class Subscription {
  final int id;
  final int userId;
  final int planId;
  final String status; // pending | active | expired | cancelled
  final int pricePaidToman;
  final List<String> calendarTypes;
  final int? dailyRequestLimit;
  final int? monthlyRequestLimit;
  final int? rateLimitPerMin;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final bool autoRenew;
  final DateTime? cancelledAt;
  final int? ledgerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.pricePaidToman,
    required this.calendarTypes,
    required this.dailyRequestLimit,
    required this.monthlyRequestLimit,
    required this.rateLimitPerMin,
    required this.startsAt,
    required this.expiresAt,
    required this.autoRenew,
    required this.cancelledAt,
    required this.ledgerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: asInt(j['id']),
        userId: asInt(j['user_id']),
        planId: asInt(j['plan_id']),
        status: (j['status'] ?? '').toString(),
        pricePaidToman: asInt(j['price_paid_toman']),
        calendarTypes: asStringList(j['calendar_types']),
        dailyRequestLimit: asIntOrNull(j['daily_request_limit']),
        monthlyRequestLimit: asIntOrNull(j['monthly_request_limit']),
        rateLimitPerMin: asIntOrNull(j['rate_limit_per_min']),
        startsAt: parseSalesDate(j['starts_at']),
        expiresAt: parseSalesDate(j['expires_at']),
        autoRenew: asBool(j['auto_renew']),
        cancelledAt: parseSalesDate(j['cancelled_at']),
        ledgerId: asIntOrNull(j['ledger_id']),
        createdAt: parseSalesDate(j['created_at']),
        updatedAt: parseSalesDate(j['updated_at']),
      );

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  /// Soft-cancel allowed unless already cancelled (API is idempotent either way).
  bool get canCancel => !isCancelled;
  /// Renew allowed for active/expired; cancelled must purchase again.
  bool get canRenew => !isCancelled;

  String get statusLabelFa {
    switch (status) {
      case 'pending':
        return 'در انتظار';
      case 'active':
        return 'فعال';
      case 'expired':
        return 'منقضی';
      case 'cancelled':
        return 'لغو شده';
      default:
        return status;
    }
  }

  static List<Subscription> listFromData(dynamic data) {
    final map = data is Map ? data : const {};
    final raw = map['subscriptions'] is List ? map['subscriptions'] as List : const [];
    return raw
        .whereType<Map>()
        .map((e) => Subscription.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// API key metadata. [rawKey] is only present on create response (`api_key` field).
class ApiKey {
  final int id;
  final int userId;
  final int subscriptionId;
  final String name;
  final String keyPrefix;
  final String keyLast4;
  final String display;
  final List<String> calendarTypes;
  final String status; // active | revoked
  final DateTime? lastUsedAt;
  final String? lastUsedIp;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final DateTime? createdAt;
  final String? rawKey;

  const ApiKey({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.name,
    required this.keyPrefix,
    required this.keyLast4,
    required this.display,
    required this.calendarTypes,
    required this.status,
    required this.lastUsedAt,
    required this.lastUsedIp,
    required this.expiresAt,
    required this.revokedAt,
    required this.createdAt,
    this.rawKey,
  });

  factory ApiKey.fromJson(Map<String, dynamic> j, {String? rawKey}) {
    final prefix = (j['key_prefix'] ?? '').toString();
    final last4 = (j['key_last4'] ?? '').toString();
    final display = (j['display'] ?? (prefix.isEmpty ? '' : '$prefix…$last4')).toString();
    return ApiKey(
      id: asInt(j['id']),
      userId: asInt(j['user_id']),
      subscriptionId: asInt(j['subscription_id']),
      name: (j['name'] ?? '').toString(),
      keyPrefix: prefix,
      keyLast4: last4,
      display: display,
      calendarTypes: asStringList(j['calendar_types']),
      status: (j['status'] ?? '').toString(),
      lastUsedAt: parseSalesDate(j['last_used_at']),
      lastUsedIp: j['last_used_ip']?.toString(),
      expiresAt: parseSalesDate(j['expires_at']),
      revokedAt: parseSalesDate(j['revoked_at']),
      createdAt: parseSalesDate(j['created_at']),
      rawKey: rawKey,
    );
  }

  bool get isActive => status == 'active' && revokedAt == null;

  String get statusLabelFa => isActive ? 'فعال' : 'لغو شده';

  static List<ApiKey> listFromData(dynamic data) {
    final map = data is Map ? data : const {};
    final raw = map['keys'] is List ? map['keys'] as List : const [];
    return raw.whereType<Map>().map((e) => ApiKey.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}

class PurchaseResult {
  final Subscription subscription;
  final Plan plan;
  final int balance;
  final int ledgerId;
  final bool idempotent;

  const PurchaseResult({
    required this.subscription,
    required this.plan,
    required this.balance,
    required this.ledgerId,
    required this.idempotent,
  });

  factory PurchaseResult.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final sub = map['subscription'];
    final plan = map['plan'];
    return PurchaseResult(
      subscription: Subscription.fromJson(
        sub is Map ? Map<String, dynamic>.from(sub) : <String, dynamic>{},
      ),
      plan: Plan.fromJson(
        plan is Map ? Map<String, dynamic>.from(plan) : <String, dynamic>{},
      ),
      balance: asInt(map['balance']),
      ledgerId: asInt(map['ledger_id']),
      idempotent: asBool(map['idempotent']),
    );
  }
}

class CreateKeyResult {
  final ApiKey key;
  final String apiKey;

  const CreateKeyResult({required this.key, required this.apiKey});

  factory CreateKeyResult.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final raw = (map['api_key'] ?? '').toString();
    final keyMap = map['key'];
    return CreateKeyResult(
      key: ApiKey.fromJson(
        keyMap is Map ? Map<String, dynamic>.from(keyMap) : <String, dynamic>{},
        rawKey: raw.isEmpty ? null : raw,
      ),
      apiKey: raw,
    );
  }
}

class CancelSubscriptionResult {
  final Subscription subscription;
  final bool idempotent;
  final int keysRevoked;

  const CancelSubscriptionResult({
    required this.subscription,
    required this.idempotent,
    required this.keysRevoked,
  });

  factory CancelSubscriptionResult.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final sub = map['subscription'];
    return CancelSubscriptionResult(
      subscription: Subscription.fromJson(
        sub is Map ? Map<String, dynamic>.from(sub) : <String, dynamic>{},
      ),
      idempotent: asBool(map['idempotent']),
      keysRevoked: asInt(map['keys_revoked']),
    );
  }
}
