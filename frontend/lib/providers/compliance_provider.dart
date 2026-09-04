import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import '../models/models.dart';

/// Compliance Provider managing Rule Engine, Blockchain Ledger commit, and Legal Notice creation
class ComplianceProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  InspectionRecord? _currentInspection;
  List<InspectionRecord> _inspectionHistory = [];
  List<Map<String, dynamic>> _statutoryRules = [];
  bool _isEvaluating = false;
  bool _isCommittingBlockchain = false;
  String? _statusMessage;

  ComplianceProvider(this._apiClient, this._storage) {
    _loadHistory();
    fetchStatutoryRules();
  }

  InspectionRecord? get currentInspection => _currentInspection;
  List<InspectionRecord> get inspectionHistory => _inspectionHistory;
  List<Map<String, dynamic>> get statutoryRules => _statutoryRules;
  bool get isEvaluating => _isEvaluating;
  bool get isCommittingBlockchain => _isCommittingBlockchain;
  String? get statusMessage => _statusMessage;

  void _loadHistory() {
    _inspectionHistory = _storage.getInspections();
    notifyListeners();
  }

  /// Fetch all 12 statutory rules from backend legal_metrology_rules.json
  Future<List<Map<String, dynamic>>> fetchStatutoryRules() async {
    try {
      final response = await _apiClient.get('/compliance/rules');
      if (response.success && response.data != null && response.data!['rules'] != null) {
        _statutoryRules = List<Map<String, dynamic>>.from(response.data!['rules']);
        notifyListeners();
        return _statutoryRules;
      }
    } catch (_) {}
    return _statutoryRules;
  }

  /// Run Rule Engine against extracted OCR/NLP data
  Future<InspectionRecord> evaluateCompliance({
    String? inspectionId,
    required OCRExtractedData extracted,
    required GS1Product gs1,
    required String storeName,
    String shopOwnerName = '',
    required String locationAddress,
    double latitude = 28.6139,
    double longitude = 77.2090,
    String imagePath = '',
    String unwarpedImagePath = '',
    bool isOffline = false,
  }) async {
    _isEvaluating = true;
    _statusMessage =
        'Evaluating extracted packaging labels against Legal Metrology Rules, 2011...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final List<RuleViolation> violations = [];

    // Rule 1: MRP Check (Rule 6(1)(e))
    if (extracted.mrp.isEmpty ||
        (!extracted.mrp.contains('₹') && !extracted.mrp.contains('Rs'))) {
      violations.add(RuleViolation(
        ruleCode: 'LM-006',
        ruleName: 'Rule 6(1)(e): Maximum Retail Price (MRP) Declaration',
        description:
            'Missing or non-standard Maximum Retail Price declaration (mandatory "inclusive of all taxes" format).',
        severity: 'Critical',
        isPassed: false,
      ));
    }

    // Rule 2: Net Quantity Check (Rule 6(1)(c))
    if (extracted.netQuantity.isEmpty) {
      violations.add(RuleViolation(
        ruleCode: 'LM-003',
        ruleName: 'Rule 6(1)(c): Net Quantity Declaration & Units',
        description:
            'Net Quantity not declared in standard units of weight, measure, or number (g, kg, ml, l).',
        severity: 'Critical',
        isPassed: false,
      ));
    }

    // Rule 3: Date Check (Rule 6(1)(d))
    if (extracted.mfgDate.isEmpty) {
      violations.add(RuleViolation(
        ruleCode: 'LM-004',
        ruleName: 'Rule 6(1)(d): Month & Year of Manufacture / Packaging',
        description:
            'Mandatory month and year of manufacture or pre-packaging is absent on the principal display panel.',
        severity: 'High',
        isPassed: false,
      ));
    }

    // Rule 4: Manufacturer / Packer Name & Address (Rule 6(1)(a))
    if (extracted.manufacturerName.isEmpty) {
      violations.add(RuleViolation(
        ruleCode: 'LM-001',
        ruleName: 'Rule 6(1)(a): Complete Manufacturer / Packer Details',
        description:
            'Absence of complete name and geographical address of the manufacturer or packer.',
        severity: 'Critical',
        isPassed: false,
      ));
    }

    // Rule 5: Consumer Care (Rule 6(1)(h))
    if (extracted.consumerCareEmail.isEmpty && extracted.consumerCarePhone.isEmpty) {
      violations.add(RuleViolation(
        ruleCode: 'LM-008',
        ruleName: 'Rule 6(1)(h): Mandatory Consumer Care Details',
        description:
            'Incomplete consumer grievance contact details (telephone number and email address required).',
        severity: 'High',
        isPassed: false,
      ));
    }

    final isPassed = violations.isEmpty;
    final realId = (inspectionId != null && inspectionId.isNotEmpty)
        ? inspectionId
        : 'INSP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    _currentInspection = InspectionRecord(
      id: realId,
      barcode: extracted.barcode.isNotEmpty ? extracted.barcode : gs1.gtin,
      productName: gs1.productName,
      storeName: storeName,
      shopOwnerName: shopOwnerName,
      locationAddress: locationAddress,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      isCompliant: isPassed,
      imagePath: imagePath,
      unwarpedImagePath: unwarpedImagePath,
      extractedData: extracted,
      violations: violations,
      isSynced: !isOffline,
      status: isPassed ? 'COMPLIANT' : 'VIOLATION',
    );

    await _storage.saveInspection(_currentInspection!);
    _inspectionHistory.removeWhere((e) => e.id == realId);
    _inspectionHistory.insert(0, _currentInspection!);

    _isEvaluating = false;
    _statusMessage = null;
    notifyListeners();
    return _currentInspection!;
  }

  /// Submit Finalized Dossier directly to Nodal Verifier
  Future<bool> submitToNodalVerifier({
    required String inspectionId,
    required String shopName,
    required String shopOwnerName,
    required String shopAddress,
    required String inspectorNotes,
    required List<Map<String, dynamic>> violationRules,
    List<String>? evidenceImages,
  }) async {
    _isCommittingBlockchain = true;
    _statusMessage =
        'Transmitting inspection dossier to Nodal Verification Authority (S. K. Sharma)...';
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/inspections/$inspectionId/submit-nodal',
        body: {
          'shop_name': shopName,
          'shop_owner_name': shopOwnerName,
          'shop_address': shopAddress,
          'notes': inspectorNotes,
          'violation_rules': violationRules,
          if (evidenceImages != null && evidenceImages.isNotEmpty)
            'evidence_images': evidenceImages,
        },
      );

      if (response.success) {
        if (_currentInspection != null && _currentInspection!.id == inspectionId) {
          _currentInspection = InspectionRecord(
            id: _currentInspection!.id,
            barcode: _currentInspection!.barcode,
            productName: _currentInspection!.productName,
            storeName: shopName.isNotEmpty ? shopName : _currentInspection!.storeName,
            shopOwnerName: shopOwnerName.isNotEmpty ? shopOwnerName : _currentInspection!.shopOwnerName,
            locationAddress: shopAddress.isNotEmpty ? shopAddress : _currentInspection!.locationAddress,
            latitude: _currentInspection!.latitude,
            longitude: _currentInspection!.longitude,
            timestamp: _currentInspection!.timestamp,
            isCompliant: _currentInspection!.isCompliant,
            imagePath: _currentInspection!.imagePath,
            unwarpedImagePath: _currentInspection!.unwarpedImagePath,
            extractedData: _currentInspection!.extractedData,
            violations: _currentInspection!.violations,
            blockchainReceipt: _currentInspection!.blockchainReceipt,
            legalNoticePdfUrl: _currentInspection!.legalNoticePdfUrl,
            isSynced: true,
            inspectorRemarks: inspectorNotes,
            status: 'unverified',
          );
          await _storage.saveInspection(_currentInspection!);
          final idx = _inspectionHistory.indexWhere((e) => e.id == inspectionId);
          if (idx >= 0) _inspectionHistory[idx] = _currentInspection!;
        }

        _isCommittingBlockchain = false;
        _statusMessage = null;
        notifyListeners();
        return true;
      } else {
        _isCommittingBlockchain = false;
        _statusMessage = response.message ?? 'Failed to submit to Nodal Verifier';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isCommittingBlockchain = false;
      _statusMessage = 'Nodal Submission Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void setInspectionSynced(String id, {required bool isSynced}) {
    final index = _inspectionHistory.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final old = _inspectionHistory[index];
      _inspectionHistory[index] = InspectionRecord(
        id: old.id,
        barcode: old.barcode,
        productName: old.productName,
        storeName: old.storeName,
        shopOwnerName: old.shopOwnerName,
        locationAddress: old.locationAddress,
        latitude: old.latitude,
        longitude: old.longitude,
        timestamp: old.timestamp,
        isCompliant: old.isCompliant,
        imagePath: old.imagePath,
        unwarpedImagePath: old.unwarpedImagePath,
        extractedData: old.extractedData,
        violations: old.violations,
        blockchainReceipt: old.blockchainReceipt,
        legalNoticePdfUrl: old.legalNoticePdfUrl,
        isSynced: isSynced,
        inspectorRemarks: old.inspectorRemarks,
        status: old.status,
      );
      _storage.saveInspection(_inspectionHistory[index]);
      notifyListeners();
    }
  }

  /// Commit SHA-256 Tamper-Proof Evidence to Ledger
  Future<BlockchainReceipt> commitEvidenceToBlockchain(
      InspectionRecord record) async {
    _isCommittingBlockchain = true;
    _statusMessage =
        'Anchoring cryptographic SHA-256 hash to Hyperledger Fabric...';
    notifyListeners();

    final payload =
        '${record.id}|${record.timestamp.toIso8601String()}|${record.barcode}|${record.violations.length}';
    final bytes = utf8.encode(payload);
    final sha256Hash = sha256.convert(bytes).toString();

    try {
      final response = await _apiClient.post(
        AppConstants.evidenceCommit,
        body: {
          'inspection_id': record.id,
          'sha256_hash': sha256Hash,
          'timestamp': record.timestamp.toIso8601String(),
          'violations': record.violations.map((e) => e.toJson()).toList(),
        },
      );

      if (response.success && response.data != null) {
        final receipt = BlockchainReceipt.fromJson(response.data!);
        _updateRecordWithReceipt(record.id, receipt);
        _isCommittingBlockchain = false;
        _statusMessage = null;
        notifyListeners();
        return receipt;
      } else {
        final errorMsg = response.message ?? 'Failed to anchor evidence to blockchain';
        _isCommittingBlockchain = false;
        _statusMessage = errorMsg;
        notifyListeners();
        throw Exception(errorMsg);
      }
    } catch (e) {
      _isCommittingBlockchain = false;
      _statusMessage = 'Blockchain Anchor Error: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void _updateRecordWithReceipt(String id, BlockchainReceipt receipt) {
    if (_currentInspection?.id == id) {
      _currentInspection = InspectionRecord(
        id: _currentInspection!.id,
        barcode: _currentInspection!.barcode,
        productName: _currentInspection!.productName,
        storeName: _currentInspection!.storeName,
        shopOwnerName: _currentInspection!.shopOwnerName,
        locationAddress: _currentInspection!.locationAddress,
        latitude: _currentInspection!.latitude,
        longitude: _currentInspection!.longitude,
        timestamp: _currentInspection!.timestamp,
        isCompliant: _currentInspection!.isCompliant,
        imagePath: _currentInspection!.imagePath,
        unwarpedImagePath: _currentInspection!.unwarpedImagePath,
        extractedData: _currentInspection!.extractedData,
        violations: _currentInspection!.violations,
        blockchainReceipt: receipt,
        legalNoticePdfUrl: 'https://doca.gov.in/notices/LEGAL-NOTICE-$id.pdf',
        isSynced: true,
        inspectorRemarks: _currentInspection!.inspectorRemarks,
        status: _currentInspection!.status,
      );
      _storage.saveInspection(_currentInspection!);
    }

    final index = _inspectionHistory.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _inspectionHistory[index] = _currentInspection!;
    }
  }

  /// Update inspector comments/notes on an inspection record
  Future<bool> updateInspectionNotes(String id, String notes) async {
    if (_currentInspection != null && _currentInspection!.id == id) {
      _currentInspection = InspectionRecord(
        id: _currentInspection!.id,
        barcode: _currentInspection!.barcode,
        productName: _currentInspection!.productName,
        storeName: _currentInspection!.storeName,
        shopOwnerName: _currentInspection!.shopOwnerName,
        locationAddress: _currentInspection!.locationAddress,
        latitude: _currentInspection!.latitude,
        longitude: _currentInspection!.longitude,
        timestamp: _currentInspection!.timestamp,
        isCompliant: _currentInspection!.isCompliant,
        imagePath: _currentInspection!.imagePath,
        unwarpedImagePath: _currentInspection!.unwarpedImagePath,
        extractedData: _currentInspection!.extractedData,
        violations: _currentInspection!.violations,
        blockchainReceipt: _currentInspection!.blockchainReceipt,
        legalNoticePdfUrl: _currentInspection!.legalNoticePdfUrl,
        isSynced: _currentInspection!.isSynced,
        inspectorRemarks: notes,
        status: _currentInspection!.status,
      );
      _storage.saveInspection(_currentInspection!);
    }

    final index = _inspectionHistory.indexWhere((e) => e.id == id);
    if (index >= 0 && _currentInspection != null) {
      _inspectionHistory[index] = _currentInspection!;
    }
    notifyListeners();

    try {
      final response = await _apiClient.patch(
        '/inspections/$id/comment',
        body: {'notes': notes},
      );
      return response.success;
    } catch (_) {
      return false;
    }
  }

  /// Fetch live inspection status from backend
  Future<InspectionRecord?> fetchInspectionStatus(String id) async {
    try {
      final response = await _apiClient.get('/inspections/$id');
      if (response.success && response.data != null) {
        final updatedRecord = InspectionRecord.fromJson(response.data!);
        if (_currentInspection?.id == id) {
          _currentInspection = updatedRecord;
        }
        final index = _inspectionHistory.indexWhere((e) => e.id == id);
        if (index >= 0) {
          _inspectionHistory[index] = updatedRecord;
        } else {
          _inspectionHistory.insert(0, updatedRecord);
        }
        _storage.saveInspection(updatedRecord);
        notifyListeners();
        return updatedRecord;
      }
    } catch (_) {}
    return _currentInspection;
  }

  /// Nodal Verifier: Fetch all pending dossiers awaiting scrutiny
  Future<List<InspectionRecord>> fetchPendingNodalInspections() async {
    try {
      final response = await _apiClient.get('/inspections/pending-nodal');
      if (response.success && response.data != null && response.data is List) {
        final list = (response.data as List)
            .map((item) => InspectionRecord.fromJson(item as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (_) {}

    // Fallback to local storage records with unverified / pending status
    return _inspectionHistory
        .where((e) => e.status.toLowerCase() == 'unverified' || e.status.toLowerCase().contains('pending'))
        .toList();
  }

  /// Nodal Verifier: Record scrutiny decision (Accept & Send to Commissioner OR Deny & Reject)
  Future<bool> submitNodalDecision({
    required String inspectionId,
    required String decision,
    required String comment,
    String verifierName = 'Nodal Officer S. K. Sharma',
  }) async {
    _isCommittingBlockchain = true;
    _statusMessage = 'Recording Nodal Verifier decision ($decision)...';
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/inspections/$inspectionId/nodal-decision',
        body: {
          'decision': decision,
          'verifier_comment': comment,
          'verifier_name': verifierName,
        },
      );

      final isAccept = decision.toUpperCase() == 'ACCEPT';
      final newStatus = isAccept ? 'verified_accepted' : 'verified_rejected';

      if (response.success) {
        if (_currentInspection != null && _currentInspection!.id == inspectionId) {
          _currentInspection = InspectionRecord(
            id: _currentInspection!.id,
            barcode: _currentInspection!.barcode,
            productName: _currentInspection!.productName,
            storeName: _currentInspection!.storeName,
            shopOwnerName: _currentInspection!.shopOwnerName,
            locationAddress: _currentInspection!.locationAddress,
            latitude: _currentInspection!.latitude,
            longitude: _currentInspection!.longitude,
            timestamp: _currentInspection!.timestamp,
            isCompliant: _currentInspection!.isCompliant,
            imagePath: _currentInspection!.imagePath,
            unwarpedImagePath: _currentInspection!.unwarpedImagePath,
            extractedData: _currentInspection!.extractedData,
            violations: _currentInspection!.violations,
            blockchainReceipt: _currentInspection!.blockchainReceipt,
            legalNoticePdfUrl: _currentInspection!.legalNoticePdfUrl,
            isSynced: true,
            inspectorRemarks: _currentInspection!.inspectorRemarks,
            status: newStatus,
            verifierComment: comment,
            verifierDecision: isAccept ? 'ACCEPTED' : 'REJECTED',
            commissionerStatus: isAccept ? 'FORWARDED_FOR_DIGITAL_SIGNATURE' : 'NOT_FORWARDED',
            verifiedAt: DateTime.now().toIso8601String(),
          );
          await _storage.saveInspection(_currentInspection!);
        }

        final idx = _inspectionHistory.indexWhere((e) => e.id == inspectionId);
        if (idx >= 0 && _currentInspection != null) {
          _inspectionHistory[idx] = _currentInspection!;
          await _storage.saveInspection(_currentInspection!);
        }

        _isCommittingBlockchain = false;
        _statusMessage = null;
        notifyListeners();
        return true;
      } else {
        _isCommittingBlockchain = false;
        _statusMessage = response.message ?? 'Failed to record Nodal decision';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isCommittingBlockchain = false;
      _statusMessage = 'Nodal Decision Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}

