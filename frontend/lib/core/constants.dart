/// Project PARAKH — Constants and API Endpoints
class AppConstants {
  static const String appName = 'PARAKH';
  static const String appFullName = 'Project PARAKH — Legal Metrology Compliance';
  static const String ministryName = 'Ministry of Consumer Affairs, Food & Public Distribution';
  static const String departmentName = 'Department of Consumer Affairs (DoCA)';
  static const String problemStatementId = '26034';

  // API Key Authentication & Base Configuration
  static const String apiKey = 'parakh_sec_api_key_2026';
  static const String apiKeyHeaderName = 'X-API-Key';

  // Default points to the local FastAPI Gateway over Wi-Fi
  static const String defaultApiBaseUrl = 'http://172.17.12.24:8000/api/v1'; // Wi-Fi LAN IP for Physical Android Device
  static const String emulatorApiUrl = 'http://10.0.2.2:8000/api/v1';
  static const String localhostApiUrl = 'http://127.0.0.1:8000/api/v1';

  static Map<String, String> get baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    apiKeyHeaderName: apiKey,
  };

  // Endpoint routes matching FastAPI backend exactly
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authMe = '/auth/me';
  static const String scanUpload = '/scan/upload';
  static const String verifyCompliance = '/analysis/verify-compliance';
  static const String evidenceCommit = '/evidence/commit';
  static const String evidenceVerify = '/evidence/verify';
  static const String inspectionsList = '/inspections';
  static const String legalNotices = '/legal-notices';
  static const String syncStatus = '/sync/status';
  static const String healthCheck = '/health';

  // Legal Metrology Rules (Packaged Commodities Rules, 2011)
  static const Map<String, String> legalRules = {
    'RULE_MRP': 'Rule 6(1)(e): Maximum Retail Price (MRP) declaration with "incl. of all taxes" format',
    'RULE_NET_QTY': 'Rule 6(1)(f): Net Quantity standard units (g/kg/ml/l) & minimum font size verification',
    'RULE_DATE': 'Rule 6(1)(d): Month & Year of manufacture / packaging declaration',
    'RULE_CONSUMER_CARE': 'Rule 6(1)(h): Mandatory Consumer Care phone number & email/address',
    'RULE_MANUFACTURER': 'Rule 6(1)(a): Complete Manufacturer / Packer name and geographical address',
    'RULE_OPENFOODFACTS': 'Rule Open Food Facts: Barcode cross-verification against Open Food Facts registered database',
  };
}
