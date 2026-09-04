import 'dart:convert';
import 'dart:typed_data';
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
  bool _isEvaluating = false;
  bool _isCommittingBlockchain = false;
  String? _statusMessage;

  ReportWorkflowRecord? _activeReport;
  List<ReportWorkflowRecord> _nodalQueue = [];
  List<ReportWorkflowRecord> _commissionerQueue = [];
  bool _isLoadingWorkflow = false;

  ReportWorkflowRecord? get activeReport => _activeReport;
  List<ReportWorkflowRecord> get nodalQueue => _nodalQueue;
  List<ReportWorkflowRecord> get commissionerQueue => _commissionerQueue;
  bool get isLoadingWorkflow => _isLoadingWorkflow;

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  ComplianceProvider(this._apiClient, this._storage) {
    _loadHistory();
    fetchRemoteInspections();
  }

  InspectionRecord? get currentInspection => _currentInspection;
  List<InspectionRecord> get inspectionHistory => _inspectionHistory;
  bool get isEvaluating => _isEvaluating;
  bool get isCommittingBlockchain => _isCommittingBlockchain;
  String? get statusMessage => _statusMessage;

  void _loadHistory() {
    _inspectionHistory = _storage.getInspections();
    notifyListeners();
  }

  Future<void> fetchRemoteInspections() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final response = await _apiClient.get(AppConstants.inspectionsList);
      if (response.success && response.data != null) {
        final List<dynamic> items;
        if (response.data is List) {
          items = response.data as List<dynamic>;
        } else if (response.data is Map) {
          final map = response.data as Map;
          items = (map['items'] ?? map['data'] ?? []) as List<dynamic>;
        } else {
          items = [];
        }
        final remoteRecords = items
            .map((item) =>
                InspectionRecord.fromJson(item as Map<String, dynamic>))
            .toList();

        final localRecords = _storage.getInspections();
        final Set<String> seenIds = {};
        final List<InspectionRecord> merged = [];

        for (final r in localRecords) {
          if (seenIds.add(r.id)) {
            merged.add(r);
          }
        }
        for (final r in remoteRecords) {
          if (seenIds.add(r.id)) {
            merged.add(r);
          }
        }

        _inspectionHistory = merged;
      }
    } catch (_) {
      // Retain local history if offline
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void setCurrentInspection(InspectionRecord record) {
    _currentInspection = record;
    notifyListeners();
  }

  /// Run Rule Engine against extracted OCR/NLP data
  Future<InspectionRecord> evaluateCompliance({
    required OCRExtractedData extracted,
    required GS1Product gs1,
    required String storeName,
    required String locationAddress,
    bool isOffline = false,
  }) async {
    _isEvaluating = true;
    _statusMessage =
        'Validating extracted data against Legal Metrology Rules, 2011...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    final List<RuleViolation> violations = [];

    // Rule 1: MRP Check
    if (extracted.mrp.isEmpty ||
        !extracted.mrp.contains('₹') && !extracted.mrp.contains('Rs')) {
      violations.add(RuleViolation(
        ruleCode: 'RULE_MRP',
        ruleName: 'Rule 6(1)(e): MRP Declaration',
        description: 'Missing or malformed Maximum Retail Price declaration.',
        severity: 'High',
        isPassed: false,
      ));
    }

    // Rule 2: Net Quantity Check
    if (extracted.netQuantity.isEmpty) {
      violations.add(RuleViolation(
        ruleCode: 'RULE_NET_QTY',
        ruleName: 'Rule 6(1)(f): Net Quantity Unit',
        description: 'Net Quantity not declared in prescribed standard units.',
        severity: 'High',
        isPassed: false,
      ));
    }

    // Rule 3: Date Check
    if (extracted.mfgDate.isEmpty) {
      violations.add(RuleViolation(
        ruleCode: 'RULE_DATE',
        ruleName: 'Rule 6(1)(d): Month & Year of Mfg/Packaging',
        description: 'Mandatory month and year of manufacture is missing.',
        severity: 'Medium',
        isPassed: false,
      ));
    }

    // Rule 4: Consumer Care
    if (extracted.consumerCareEmail.isEmpty ||
        extracted.consumerCarePhone.isEmpty) {
      violations.add(RuleViolation(
        ruleCode: 'RULE_CONSUMER_CARE',
        ruleName: 'Rule 6(1)(h): Consumer Care Details',
        description:
            'Incomplete consumer grievance contact details (Mandatory phone and email address required).',
        severity: 'High',
        isPassed: false,
      ));
    }

    // Rule 5: Open Food Facts Product Registry Cross-check
    if (gs1.gtin.isEmpty) {
      violations.add(RuleViolation(
        ruleCode: 'RULE_OPENFOODFACTS',
        ruleName: 'Open Food Facts Registry Check',
        description:
            'Manufacturer barcode mismatch or missing in official Open Food Facts registry.',
        severity: 'High',
        isPassed: false,
      ));
    }

    final isPassed = violations.isEmpty;
    final inspectionId =
        'INSP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    _currentInspection = InspectionRecord(
      id: inspectionId,
      barcode: extracted.barcode.isNotEmpty ? extracted.barcode : gs1.gtin,
      productName: gs1.productName,
      storeName: storeName,
      locationAddress: locationAddress,
      latitude: 28.6139,
      longitude: 77.2090,
      timestamp: DateTime.now(),
      isCompliant: isPassed,
      imagePath: '',
      extractedData: extracted,
      violations: violations,
      isSynced: !isOffline,
    );

    await _storage.saveInspection(_currentInspection!);
    _inspectionHistory.insert(0, _currentInspection!);

    _isEvaluating = false;
    _statusMessage = null;
    notifyListeners();
    return _currentInspection!;
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
        locationAddress: old.locationAddress,
        latitude: old.latitude,
        longitude: old.longitude,
        timestamp: old.timestamp,
        isCompliant: old.isCompliant,
        imagePath: old.imagePath,
        extractedData: old.extractedData,
        violations: old.violations,
        blockchainReceipt: old.blockchainReceipt,
        legalNoticePdfUrl: old.legalNoticePdfUrl,
        isSynced: isSynced,
      );
      _storage.saveInspection(_inspectionHistory[index]);
      notifyListeners();
    }
  }

  /// Commit SHA-256 Tamper-Proof Evidence to Hyperledger Fabric
  Future<BlockchainReceipt> commitEvidenceToBlockchain(
      InspectionRecord record) async {
    _isCommittingBlockchain = true;
    _statusMessage =
        'Anchoring cryptographic SHA-256 hash to Hyperledger Fabric...';
    notifyListeners();

    // Compute deterministic SHA-256 hash of (InspectionId + Timestamp + Barcode + Violations)
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
        locationAddress: _currentInspection!.locationAddress,
        latitude: _currentInspection!.latitude,
        longitude: _currentInspection!.longitude,
        timestamp: _currentInspection!.timestamp,
        isCompliant: _currentInspection!.isCompliant,
        imagePath: _currentInspection!.imagePath,
        extractedData: _currentInspection!.extractedData,
        violations: _currentInspection!.violations,
        blockchainReceipt: receipt,
        legalNoticePdfUrl: '/api/v1/legal-notices/download/$id',
        isSynced: true,
      );
      _storage.saveInspection(_currentInspection!);
    }

    final index = _inspectionHistory.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _inspectionHistory[index] = _currentInspection!;
    }
  }

  /// Download or generate statutory PDF notice from backend
  Future<Uint8List?> generateOrDownloadNoticePdf(String inspectionId) async {
    final bytes = await _apiClient
        .downloadBytes('/legal-notices/download/$inspectionId');
    return bytes;
  }

  /// Stage 1: Load or create draft report for an inspection
  Future<ReportWorkflowRecord?> loadOrCreateReport(String inspectionId, {String? inspectorNotes}) async {
    _isLoadingWorkflow = true;
    _statusMessage = 'Generating official inspection dossier...';
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '${AppConstants.reports}/create-or-get/$inspectionId',
        body: inspectorNotes != null ? {'inspector_notes': inspectorNotes} : {},
      );

      if (response.success && response.data != null) {
        _activeReport = ReportWorkflowRecord.fromJson(response.data!);
        _isLoadingWorkflow = false;
        _statusMessage = null;
        notifyListeners();
        return _activeReport;
      } else {
        _isLoadingWorkflow = false;
        _statusMessage = response.message ?? 'Failed to initialize dossier';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoadingWorkflow = false;
      _statusMessage = 'Report Error: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Stage 1 Submit: Food Inspector sends report to Nodal Officer
  Future<ReportWorkflowRecord?> submitToNodal(String reportId, String inspectorNotes) async {
    _isLoadingWorkflow = true;
    _statusMessage = 'Submitting report to Nodal Officer for verification...';
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '${AppConstants.reports}/$reportId/submit-to-nodal',
        body: {'inspector_notes': inspectorNotes},
      );

      if (response.success && response.data != null) {
        _activeReport = ReportWorkflowRecord.fromJson(response.data!);
        _isLoadingWorkflow = false;
        _statusMessage = null;
        notifyListeners();
        return _activeReport;
      } else {
        _isLoadingWorkflow = false;
        _statusMessage = response.message ?? 'Failed to submit report';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoadingWorkflow = false;
      _statusMessage = 'Submission Error: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Stage 2: Nodal Officer queue
  Future<List<ReportWorkflowRecord>> fetchNodalQueue() async {
    _isLoadingWorkflow = true;
    notifyListeners();

    try {
      final response = await _apiClient.getList('${AppConstants.reports}/queue/nodal');
      if (response.success && response.data != null) {
        _nodalQueue = response.data!
            .map((e) => ReportWorkflowRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    _isLoadingWorkflow = false;
    notifyListeners();
    return _nodalQueue;
  }

  /// Stage 2 Review & Forward: Nodal Officer comments and forwards to Commissioner
  Future<ReportWorkflowRecord?> nodalForwardToCommissioner(String reportId, String comments) async {
    _isLoadingWorkflow = true;
    _statusMessage = 'Forwarding verified dossier to Food Safety Commissioner...';
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '${AppConstants.reports}/$reportId/nodal-forward',
        body: {'nodal_comments': comments},
      );

      if (response.success && response.data != null) {
        _activeReport = ReportWorkflowRecord.fromJson(response.data!);
        _nodalQueue.removeWhere((r) => r.reportId == reportId);
        _isLoadingWorkflow = false;
        _statusMessage = null;
        notifyListeners();
        return _activeReport;
      } else {
        _isLoadingWorkflow = false;
        _statusMessage = response.message ?? 'Failed to forward report';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoadingWorkflow = false;
      _statusMessage = 'Forwarding Error: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Stage 3: Commissioner queue
  Future<List<ReportWorkflowRecord>> fetchCommissionerQueue() async {
    _isLoadingWorkflow = true;
    notifyListeners();

    try {
      final response = await _apiClient.getList('${AppConstants.reports}/queue/commissioner');
      if (response.success && response.data != null) {
        _commissionerQueue = response.data!
            .map((e) => ReportWorkflowRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    _isLoadingWorkflow = false;
    notifyListeners();
    return _commissionerQueue;
  }

  /// Stage 3 Certify: Food Safety Commissioner certifies & digitally signs
  Future<ReportWorkflowRecord?> commissionerCertifyReport(String reportId, String comments) async {
    _isLoadingWorkflow = true;
    _statusMessage = 'Applying statutory digital signature and seal...';
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '${AppConstants.reports}/$reportId/certify',
        body: {'commissioner_comments': comments},
      );

      if (response.success && response.data != null) {
        _activeReport = ReportWorkflowRecord.fromJson(response.data!);
        _commissionerQueue.removeWhere((r) => r.reportId == reportId);
        _isLoadingWorkflow = false;
        _statusMessage = null;
        notifyListeners();
        return _activeReport;
      } else {
        _isLoadingWorkflow = false;
        _statusMessage = response.message ?? 'Failed to certify report';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoadingWorkflow = false;
      _statusMessage = 'Certification Error: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Download official signed statutory PDF
  Future<Uint8List?> downloadCertifiedPdf(String reportId) async {
    final bytes = await _apiClient.downloadBytes('${AppConstants.reports}/$reportId/pdf');
    return bytes;
  }
}
