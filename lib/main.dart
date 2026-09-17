import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System - DB Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'POS - Firebase DB Connection Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _dbStatusMessage = 'Press a button below to test database connection';
  bool _isLoading = false;
  List<Map<String, dynamic>> _testRecords = [];

  // Function to test writing data to Firestore
  Future<void> _testWriteToDb() async {
    setState(() {
      _isLoading = true;
      _dbStatusMessage = 'Connecting & writing to Firestore...';
    });

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('test_connection')
          .add({
        'message': 'Database connection test successful!',
        'timestamp': FieldValue.serverTimestamp(),
        'device': 'POS Mobile App',
      });

      setState(() {
        _isLoading = false;
        _dbStatusMessage =
            '✅ Success! Created document ID: ${docRef.id} in collection "test_connection"';
      });

      // Refresh list after write
      _testReadFromDb();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _dbStatusMessage = '❌ Error writing to DB: $e';
      });
    }
  }

  // Function to test reading data from Firestore
  Future<void> _testReadFromDb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('test_connection')
          .limit(10)
          .get();

      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _isLoading = false;
        _testRecords = records;
        if (_dbStatusMessage.startsWith('Press') ||
            _dbStatusMessage.startsWith('Connecting')) {
          _dbStatusMessage =
              '✅ Successfully fetched ${records.length} document(s) from Firestore!';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _dbStatusMessage = '❌ Error reading from DB: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Database status header card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.storage,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Firebase Connection Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Project ID: pos-system-95357',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const Divider(height: 24),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Text(
                        _dbStatusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _dbStatusMessage.startsWith('❌')
                              ? Colors.red
                              : _dbStatusMessage.startsWith('✅')
                                  ? Colors.green.shade800
                                  : Colors.black87,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testWriteToDb,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Test DB Write'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _testReadFromDb,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Test DB Read'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Records List
            const Text(
              'Firestore Test Records:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_testRecords.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text(
                    'No records fetched yet. Click "Test DB Write" or "Test DB Read".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _testRecords.length,
                itemBuilder: (context, index) {
                  final record = _testRecords[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.description, size: 20),
                      ),
                      title: Text(record['message'] ?? 'No message'),
                      subtitle: Text(
                        'Doc ID: ${record['id']}\nDevice: ${record['device'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
