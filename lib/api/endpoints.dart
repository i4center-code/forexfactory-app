/// API endpoints for Forex Factory Iran mobile API.
///
/// NOTE: the API lives on its own subdomain with an empty base path.
/// `https://forexfactoryiran.ir/api/v1` is NOT valid (404).
///
/// Override at build/run time:
///   --dart-define=API_BASE_URL=http://127.0.0.1:8792/api/v1
///   --dart-define=FFI_BASE_URL=...   (legacy alias)
// ignore_for_file: constant_identifier_names
const String _fromApi = String.fromEnvironment('API_BASE_URL');
const String _fromFfi = String.fromEnvironment(
  'FFI_BASE_URL',
  defaultValue: 'https://api-v1.forexfactoryiran.ir',
);
const String BASE_URL = _fromApi != '' ? _fromApi : _fromFfi;

class Endpoints {
  Endpoints._();
  static const String health = '/health';
  static String calendar(String type) => '/calendar/$type';
  static String dataCalendar(String type) => '/data/calendar/$type';
  static const String news = '/news';
  static const String siteOrigin = 'https://forexfactoryiran.ir';
  static String banner(String type) => '$siteOrigin/api/public/app-banners.php?page=$type';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/me';
  static const String plans = '/plans';
  static const String wallet = '/wallet';
  static const String subscriptions = '/subscriptions';
  static const String purchase = '/subscriptions/purchase';
  static String subscriptionCancel(int id) => '/subscriptions/$id/cancel';
  static String subscriptionRenew(int id) => '/subscriptions/$id/renew';
  static const String keys = '/keys';
  static String key(int id) => '/keys/$id';
  static const List<String> calendarTypes = ['forex', 'metals', 'energy', 'crypto'];
}
