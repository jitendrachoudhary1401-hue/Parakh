/// User Role definition
enum UserRole { inspector, admin, citizen }

/// User Model
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String officialId;
  final UserRole role;
  final String zone;
  final String token;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.officialId,
    required this.role,
    required this.zone,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String token = ''}) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? 'Enforcement Officer',
      officialId:
          json['official_id'] ?? json['badge_number'] ?? 'DOCA-INSP-2026',
      role: (json['role'] == 'admin')
          ? UserRole.admin
          : (json['role'] == 'citizen')
              ? UserRole.citizen
              : UserRole.inspector,
      zone: json['zone'] ?? 'North Zone (New Delhi Division)',
      token: token,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'official_id': officialId,
        'role': role.name,
        'zone': zone,
        'token': token,
      };
}

/// OCR / NLP Extracted Fields
class OCRExtractedData {
  final String rawText;
  final String mrp;
  final double mrpValue;
  final String netQuantity;
  final String mfgDate;
  final String expiryDate;
  final String consumerCarePhone;
  final String consumerCareEmail;
  final String manufacturerName;
  final String manufacturerAddress;
  final String barcode;
  final double confidenceScore;
  final List<BoundingBox> boundingBoxes;

  OCRExtractedData({
    required this.rawText,
    required this.mrp,
    required this.mrpValue,
    required this.netQuantity,
    required this.mfgDate,
    required this.expiryDate,
    required this.consumerCarePhone,
    required this.consumerCareEmail,
    required this.manufacturerName,
    required this.manufacturerAddress,
    required this.barcode,
    required this.confidenceScore,
    this.boundingBoxes = const [],
  });

  factory OCRExtractedData.empty() {
    return OCRExtractedData(
      rawText: '',
      mrp: '₹ 0.00',
      mrpValue: 0.0,
      netQuantity: '',
      mfgDate: '',
      expiryDate: '',
      consumerCarePhone: '',
      consumerCareEmail: '',
      manufacturerName: '',
      manufacturerAddress: '',
      barcode: '',
      confidenceScore: 0.0,
    );
  }

  factory OCRExtractedData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('extracted_entities')) {
      return OCRExtractedData.fromAnalysisResponse(json);
    }
    return OCRExtractedData(
      rawText: json['raw_text'] ?? json['raw_ocr_text'] ?? '',
      mrp: json['mrp'] ?? '',
      mrpValue: (json['mrp_value'] as num?)?.toDouble() ?? 0.0,
      netQuantity: json['net_quantity'] ?? json['net_weight'] ?? '',
      mfgDate: json['mfg_date'] ?? json['manufacturing_date'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
      consumerCarePhone: json['consumer_care_phone'] ?? '',
      consumerCareEmail: json['consumer_care_email'] ?? '',
      manufacturerName: json['manufacturer_name'] ?? '',
      manufacturerAddress: json['manufacturer_address'] ?? '',
      barcode: json['barcode'] ?? json['product_barcode'] ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.94,
      boundingBoxes: (json['bounding_boxes'] as List<dynamic>?)
              ?.map((e) => BoundingBox.fromJson(e))
              .toList() ??
          [],
    );
  }

  factory OCRExtractedData.fromAnalysisResponse(Map<String, dynamic> json) {
    final entities = (json['extracted_entities'] as List<dynamic>?) ?? [];
    String mrp = '';
    double mrpValue = 0.0;
    String netQuantity = '';
    String mfgDate = '';
    String expiryDate = '';
    String consumerCarePhone = '';
    String consumerCareEmail = '';
    String manufacturerName = '';
    String manufacturerAddress = '';

    for (final item in entities) {
      if (item is Map<String, dynamic>) {
        final type = (item['entity'] ?? '').toString().toUpperCase();
        final value = (item['value'] ?? '').toString();
        switch (type) {
          case 'MRP':
            mrp = value.startsWith('₹') || value.startsWith('Rs') ? value : '₹ $value';
            mrpValue = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
            break;
          case 'NET_QUANTITY':
            netQuantity = value;
            break;
          case 'MFG_DATE':
          case 'PKG_DATE':
            mfgDate = value;
            break;
          case 'EXPIRY_DATE':
          case 'BEST_BEFORE':
            expiryDate = value;
            break;
          case 'CONSUMER_CARE_PHONE':
            consumerCarePhone = value;
            break;
          case 'CONSUMER_CARE_EMAIL':
            consumerCareEmail = value;
            break;
          case 'MANUFACTURER_NAME':
            manufacturerName = value;
            break;
          case 'MANUFACTURER_ADDRESS':
            manufacturerAddress = value;
            break;
        }
      }
    }

    return OCRExtractedData(
      rawText: json['raw_ocr_text'] ?? json['raw_text'] ?? '',
      mrp: mrp.isNotEmpty ? mrp : (json['mrp'] ?? ''),
      mrpValue: mrpValue != 0.0 ? mrpValue : ((json['mrp_value'] as num?)?.toDouble() ?? 0.0),
      netQuantity: netQuantity.isNotEmpty ? netQuantity : (json['net_quantity'] ?? ''),
      mfgDate: mfgDate.isNotEmpty ? mfgDate : (json['mfg_date'] ?? ''),
      expiryDate: expiryDate.isNotEmpty ? expiryDate : (json['expiry_date'] ?? ''),
      consumerCarePhone: consumerCarePhone.isNotEmpty ? consumerCarePhone : (json['consumer_care_phone'] ?? ''),
      consumerCareEmail: consumerCareEmail.isNotEmpty ? consumerCareEmail : (json['consumer_care_email'] ?? ''),
      manufacturerName: manufacturerName.isNotEmpty ? manufacturerName : (json['manufacturer_name'] ?? ''),
      manufacturerAddress: manufacturerAddress.isNotEmpty ? manufacturerAddress : (json['manufacturer_address'] ?? ''),
      barcode: json['product_barcode'] ?? json['barcode'] ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.92,
      boundingBoxes: [],
    );
  }

  Map<String, dynamic> toJson() => {
        'raw_text': rawText,
        'mrp': mrp,
        'mrp_value': mrpValue,
        'net_quantity': netQuantity,
        'mfg_date': mfgDate,
        'expiry_date': expiryDate,
        'consumer_care_phone': consumerCarePhone,
        'consumer_care_email': consumerCareEmail,
        'manufacturer_name': manufacturerName,
        'manufacturer_address': manufacturerAddress,
        'barcode': barcode,
        'confidence_score': confidenceScore,
      };
}

/// AR Bounding Box coordinate representation
class BoundingBox {
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
  final bool isCompliant;
  final double confidence;

  BoundingBox({
    required this.label,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.isCompliant,
    required this.confidence,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      label: json['label'] ?? '',
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      top: (json['top'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      isCompliant: json['is_compliant'] ?? true,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.95,
    );
  }
}

/// Statutory Legal Document / Rule Version Entity
class LegalDocument {
  final String lawId;
  final String title;
  final String versionHash;
  final String effectiveDate;
  final String documentUrl;
  final String? gazetteNotification;

  LegalDocument({
    required this.lawId,
    required this.title,
    required this.versionHash,
    required this.effectiveDate,
    required this.documentUrl,
    this.gazetteNotification,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      lawId: json['law_id'] ?? json['id'] ?? 'lm-doc-2011',
      title: json['title'] ?? 'The Legal Metrology (Packaged Commodities) Rules, 2011',
      versionHash: json['version_hash'] ?? '48cd6acdb5475709631b741d71b2948d45713e7e8758ce531c19948a7e31f890',
      effectiveDate: json['effective_date'] ?? '2011-04-01',
      documentUrl: json['document_url'] ?? 'https://consumeraffairs.nic.in/acts-and-rules/legal-metrology',
      gazetteNotification: json['gazette_notification'] ?? 'G.S.R. 202(E)',
    );
  }

  factory LegalDocument.defaultActive() {
    return LegalDocument(
      lawId: 'lm-doca-2011-gsr202',
      title: 'The Legal Metrology (Packaged Commodities) Rules, 2011',
      versionHash: '48cd6acdb5475709631b741d71b2948d45713e7e8758ce531c19948a7e31f890',
      effectiveDate: '2011-04-01',
      documentUrl: 'https://consumeraffairs.nic.in/sites/default/files/8_1732871406.pdf',
      gazetteNotification: 'G.S.R. 202(E) (as amended)',
    );
  }

  Map<String, dynamic> toJson() => {
        'law_id': lawId,
        'title': title,
        'version_hash': versionHash,
        'effective_date': effectiveDate,
        'document_url': documentUrl,
        'gazette_notification': gazetteNotification,
      };
}

/// Rule Violation with Statutory Metrology References
class RuleViolation {
  final String ruleCode;
  final String ruleName;
  final String description;
  final String severity; // Critical, High, Medium, Low
  final bool isPassed;
  final String? clauseId;
  final String? actSection;
  final String? noticeClause;

  RuleViolation({
    required this.ruleCode,
    required this.ruleName,
    required this.description,
    required this.severity,
    required this.isPassed,
    this.clauseId,
    this.actSection,
    this.noticeClause,
  });

  factory RuleViolation.fromJson(Map<String, dynamic> json) {
    return RuleViolation(
      ruleCode: json['rule_code'] ?? json['rule_id'] ?? json['rule_number'] ?? '',
      ruleName: json['rule_name'] ?? json['rule_title'] ?? '',
      description: json['description'] ?? json['explanation'] ?? '',
      severity: json['severity'] ?? 'High',
      isPassed: json['is_passed'] ?? (json['status'] == 'PASS'),
      clauseId: json['clause_id'],
      actSection: json['act_section'],
      noticeClause: json['notice_clause'] ?? json['default_notice_clause'],
    );
  }

  Map<String, dynamic> toJson() => {
        'rule_code': ruleCode,
        'rule_name': ruleName,
        'description': description,
        'severity': severity,
        'is_passed': isPassed,
        'clause_id': clauseId,
        'act_section': actSection,
        'notice_clause': noticeClause,
      };
}

/// Open Food Facts Product Lookup Entity
class OpenFoodFactsProduct {
  final String gtin;
  final String productName;
  final String registeredCompany;
  final String companyAddress;
  final String brand;
  final bool isVerified;

  OpenFoodFactsProduct({
    required this.gtin,
    required this.productName,
    required this.registeredCompany,
    required this.companyAddress,
    required this.brand,
    required this.isVerified,
  });

  factory OpenFoodFactsProduct.fromJson(Map<String, dynamic> json) {
    return OpenFoodFactsProduct(
      gtin: json['gtin'] ?? json['barcode'] ?? '',
      productName:
          json['product_name'] ?? json['item_name'] ?? 'Product Information',
      registeredCompany: json['registered_manufacturer'] ??
          json['registered_company'] ??
          json['company'] ??
          'Unknown Manufacturer',
      companyAddress: json['manufacturer_address'] ?? json['company_address'] ?? '',
      brand: json['brand'] ?? '',
      isVerified: json['status'] == 'FOUND' || json['is_verified'] == true,
    );
  }
}

typedef GS1Product = OpenFoodFactsProduct;

/// Blockchain Receipt
class BlockchainReceipt {
  final String txHash;
  final String evidenceHash; // SHA-256
  final String blockNumber;
  final String timestamp;
  final String channel;
  final bool isAnchored;

  BlockchainReceipt({
    required this.txHash,
    required this.evidenceHash,
    required this.blockNumber,
    required this.timestamp,
    required this.channel,
    required this.isAnchored,
  });

  factory BlockchainReceipt.fromJson(Map<String, dynamic> json) {
    return BlockchainReceipt(
      txHash: json['tx_hash'] ?? json['transaction_id'] ?? '',
      evidenceHash: json['evidence_hash'] ?? json['sha256_hash'] ?? '',
      blockNumber: json['block_number']?.toString() ?? '10482',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      channel: json['channel'] ?? 'doca-evidentiary-channel',
      isAnchored: json['is_anchored'] ?? true,
    );
  }
}

/// Comprehensive Inspection Record
class InspectionRecord {
  final String id;
  final String barcode;
  final String productName;
  final String storeName;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isCompliant;
  final String imagePath;
  final String unwarpedImagePath;
  final OCRExtractedData extractedData;
  final List<RuleViolation> violations;
  final BlockchainReceipt? blockchainReceipt;
  final String legalNoticePdfUrl;
  final bool isSynced;

  InspectionRecord({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.storeName,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.isCompliant,
    required this.imagePath,
    this.unwarpedImagePath = '',
    required this.extractedData,
    required this.violations,
    this.blockchainReceipt,
    this.legalNoticePdfUrl = '',
    this.isSynced = true,
  });

  factory InspectionRecord.fromJson(Map<String, dynamic> json) {
    return InspectionRecord(
      id: json['id'] ?? '',
      barcode: json['barcode'] ?? '',
      productName: json['product_name'] ?? 'Packaged Commodity',
      storeName: json['store_name'] ?? 'Retail Outlet',
      locationAddress: json['location_address'] ?? 'New Delhi, India',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 28.6139,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.2090,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isCompliant: json['is_compliant'] ??
          (json['violations'] == null || (json['violations'] as List).isEmpty),
      imagePath: json['image_path'] ?? json['image_url'] ?? '',
      unwarpedImagePath: json['unwarped_image_path'] ?? '',
      extractedData: json['extracted_data'] != null
          ? OCRExtractedData.fromJson(json['extracted_data'])
          : OCRExtractedData.empty(),
      violations: (json['violations'] as List<dynamic>?)
              ?.map((e) => RuleViolation.fromJson(e))
              .toList() ??
          [],
      blockchainReceipt: json['blockchain_receipt'] != null
          ? BlockchainReceipt.fromJson(json['blockchain_receipt'])
          : null,
      legalNoticePdfUrl: json['legal_notice_pdf_url'] ?? '',
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'product_name': productName,
        'store_name': storeName,
        'location_address': locationAddress,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'is_compliant': isCompliant,
        'image_path': imagePath,
        'unwarped_image_path': unwarpedImagePath,
        'extracted_data': extractedData.toJson(),
        'violations': violations.map((e) => e.toJson()).toList(),
        'legal_notice_pdf_url': legalNoticePdfUrl,
        'is_synced': isSynced,
      };
}

/// Offline Sync Queue Item
class SyncQueueItem {
  final String id;
  final String inspectionId;
  final String localImagePath;
  final String barcode;
  final String storeName;
  final DateTime createdAt;
  final int retryCount;
  final String status; // 'pending', 'syncing', 'failed'

  SyncQueueItem({
    required this.id,
    required this.inspectionId,
    required this.localImagePath,
    required this.barcode,
    required this.storeName,
    required this.createdAt,
    this.retryCount = 0,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'inspection_id': inspectionId,
        'local_image_path': localImagePath,
        'barcode': barcode,
        'store_name': storeName,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'status': status,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] ?? '',
      inspectionId: json['inspection_id'] ?? '',
      localImagePath: json['local_image_path'] ?? '',
      barcode: json['barcode'] ?? '',
      storeName: json['store_name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
      status: json['status'] ?? 'pending',
    );
  }
}
