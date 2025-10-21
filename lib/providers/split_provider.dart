import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/split.dart';
import '../models/split_item.dart';
import '../models/person_assignment.dart';
import '../services/supabase_service.dart';
import '../utils/error_handler.dart';

/// Provider for split management
class SplitProvider with ChangeNotifier {
  final _supabaseService = SupabaseService();
  final _uuid = const Uuid();

  List<SplitItem> _receiptItems = [];
  String _splitType = 'even'; // 'even' or 'custom'
  int _numPeople = 2;
  List<PersonAssignment> _assignments = [];
  Split? _currentSplit;

  bool _isProcessing = false;
  String? _error;

  List<SplitItem> get receiptItems => _receiptItems;
  String get splitType => _splitType;
  int get numPeople => _numPeople;
  List<PersonAssignment> get assignments => _assignments;
  Split? get currentSplit => _currentSplit;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  bool get hasAssignments => _assignments.isNotEmpty;

  /// Initialize with receipt items
  void initializeWithReceipt(List<SplitItem> items) {
    _receiptItems = items;
    _assignments = [];
    notifyListeners();
  }

  /// Set split type
  void setSplitType(String type) {
    _splitType = type;
    notifyListeners();
  }

  /// Set number of people for even split
  void setNumPeople(int num) {
    _numPeople = num;
    notifyListeners();
  }

  /// Calculate even split
  void calculateEvenSplit({List<String>? personNames}) {
    if (_receiptItems.isEmpty) return;

    _assignments = [];
    final total = _receiptItems.fold(0.0, (sum, item) => sum + item.price);
    final perPerson = total / _numPeople;

    for (int i = 0; i < _numPeople; i++) {
      final name = personNames != null && i < personNames.length
          ? personNames[i]
          : 'Person ${i + 1}';

      _assignments.add(PersonAssignment(
        name: name,
        items: [], // Even split doesn't assign specific items
        total: perPerson,
      ));
    }

    notifyListeners();
  }

  /// Add person for custom split
  void addPerson(String name) {
    _assignments.add(PersonAssignment(
      name: name,
      items: [],
      total: 0.0,
    ));
    notifyListeners();
  }

  /// Remove person
  void removePerson(int index) {
    if (index >= 0 && index < _assignments.length) {
      _assignments.removeAt(index);
      notifyListeners();
    }
  }

  /// Update person name
  void updatePersonName(int index, String name) {
    if (index >= 0 && index < _assignments.length) {
      _assignments[index] = _assignments[index].copyWith(name: name);
      notifyListeners();
    }
  }

  /// Assign item to person
  void assignItemToPerson(int personIndex, SplitItem item) {
    if (personIndex >= 0 && personIndex < _assignments.length) {
      final person = _assignments[personIndex];
      final updatedItems = List<SplitItem>.from(person.items)..add(item);
      final updatedTotal = updatedItems.fold(0.0, (sum, i) => sum + i.price);

      _assignments[personIndex] = person.copyWith(
        items: updatedItems,
        total: updatedTotal,
      );
      notifyListeners();
    }
  }

  /// Remove item from person
  void removeItemFromPerson(int personIndex, int itemIndex) {
    if (personIndex >= 0 && personIndex < _assignments.length) {
      final person = _assignments[personIndex];
      if (itemIndex >= 0 && itemIndex < person.items.length) {
        final updatedItems = List<SplitItem>.from(person.items)
          ..removeAt(itemIndex);
        final updatedTotal = updatedItems.fold(0.0, (sum, i) => sum + i.price);

        _assignments[personIndex] = person.copyWith(
          items: updatedItems,
          total: updatedTotal,
        );
        notifyListeners();
      }
    }
  }

  /// Check if item is assigned to anyone
  bool isItemAssigned(SplitItem item) {
    for (final assignment in _assignments) {
      if (assignment.items.any((i) => i.name == item.name && i.price == item.price)) {
        return true;
      }
    }
    return false;
  }

  /// Get unassigned items
  List<SplitItem> get unassignedItems {
    return _receiptItems.where((item) => !isItemAssigned(item)).toList();
  }

  /// Validate that all items are assigned
  bool get allItemsAssigned {
    if (_splitType == 'even') return true;
    return unassignedItems.isEmpty;
  }

  /// Save split to database
  Future<String> saveSplit({
    required String receiptId,
    required String userId,
  }) async {
    _setProcessing(true);
    _error = null;

    try {
      if (_assignments.isEmpty) {
        throw Exception('No assignments to save');
      }

      // Generate unique share link ID
      final shareLinkId = _uuid.v4().substring(0, 8);

      final splitId = await _supabaseService.saveSplit(
        receiptId: receiptId,
        userId: userId,
        splitType: _splitType,
        numPeople: _splitType == 'even' ? _numPeople : null,
        assignments: _assignments,
        shareLinkId: shareLinkId,
      );

      // Load the saved split
      _currentSplit = await _supabaseService.getSplit(splitId);
      notifyListeners();

      return splitId;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError('SplitProvider.saveSplit', e);
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  /// Load split by ID
  Future<void> loadSplit(String splitId) async {
    _setProcessing(true);
    _error = null;

    try {
      _currentSplit = await _supabaseService.getSplit(splitId);
      if (_currentSplit != null) {
        _splitType = _currentSplit!.splitType;
        _numPeople = _currentSplit!.numPeople ?? 2;
        _assignments = _currentSplit!.assignments;
        notifyListeners();
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      ErrorHandler.logError('SplitProvider.loadSplit', e);
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  /// Clear split data
  void clear() {
    _receiptItems = [];
    _splitType = 'even';
    _numPeople = 2;
    _assignments = [];
    _currentSplit = null;
    _error = null;
    notifyListeners();
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
