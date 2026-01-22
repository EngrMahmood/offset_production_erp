import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_master.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Stream<QuerySnapshot> getJobMasters() {
    return _db.collection('jobs_master').orderBy('createdAt', descending: true).snapshots();
  }
}
