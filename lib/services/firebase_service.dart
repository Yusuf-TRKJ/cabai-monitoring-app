import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // stream sensor + control
  Stream<DatabaseEvent> getAllData() {
    return _db.onValue;
  }

  // ubah mode
  Future<void> setMode(String mode) async {
    await _db.child("control/mode").set(mode);
  }

  // ubah pompa
  Future<void> setPompa(String status) async {
    await _db.child("control/pompa").set(status);
  }
}