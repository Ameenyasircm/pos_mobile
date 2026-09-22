import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';

class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _billsCollection = 'bills';
  static const String _ordersCollection = 'orders';
  static const String _tablesCollection = 'tables';

  /// Stream of all bills within a date range sorted by createdAt descending
  Stream<List<BillModel>> getBillsStream(DateTime startDate, DateTime endDate) {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    return _firestore
        .collection(_billsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BillModel.fromMap(doc.data(), doc.id))
          .where((bill) {
        if (bill.createdAt == null) return true;
        if (bill.createdAt is Timestamp) {
          final ts = bill.createdAt as Timestamp;
          return ts.compareTo(startTimestamp) >= 0 && ts.compareTo(endTimestamp) <= 0;
        }
        return true;
      }).toList();

      list.sort((a, b) {
        if (a.createdAt is Timestamp && b.createdAt is Timestamp) {
          return (b.createdAt as Timestamp).compareTo(a.createdAt as Timestamp);
        }
        return 0;
      });

      return list;
    });
  }

  /// Create a new official Bill document in `bills` collection and complete table session checkout
  Future<String> createBillAndCheckoutSession(BillModel bill, List<String> orderIds) async {
    // Generate bill number based on count
    final countSnap = await _firestore.collection(_billsCollection).get();
    final nextNumber = countSnap.docs.length + 1001;
    final generatedBillNum = '#B-$nextNumber';

    final billDocRef = _firestore.collection(_billsCollection).doc();
    final finalBill = BillModel(
      id: billDocRef.id,
      billNumber: generatedBillNum,
      tableId: bill.tableId,
      tableName: bill.tableName,
      sessionId: bill.sessionId,
      orderIds: orderIds,
      items: bill.items,
      totalAmount: bill.totalAmount,
      paymentMethod: bill.paymentMethod,
      billedBy: bill.billedBy,
      createdAt: FieldValue.serverTimestamp(),
    );

    final batch = _firestore.batch();

    // 1. Write official Bill document
    batch.set(billDocRef, finalBill.toMap());

    // 2. Mark consolidated orders as billed
    for (final orderId in orderIds) {
      final orderRef = _firestore.collection(_ordersCollection).doc(orderId);
      batch.update(orderRef, {
        'isBilled': true,
        'status': 'Billed',
        'billedBy': bill.billedBy,
        'billedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Reset table status to AVAILABLE
    if (bill.tableId != null && bill.tableId!.isNotEmpty) {
      final tableRef = _firestore.collection(_tablesCollection).doc(bill.tableId);
      batch.update(tableRef, {'status': 'AVAILABLE'});
    }

    await batch.commit();
    return billDocRef.id;
  }
}
