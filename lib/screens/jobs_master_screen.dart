import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_html/html.dart' as html;

class JobsMasterScreen extends StatefulWidget {
  final bool isAdmin;
  const JobsMasterScreen({super.key, this.isAdmin = true});

  @override
  State<JobsMasterScreen> createState() => _JobsMasterScreenState();
}

class _JobsMasterScreenState extends State<JobsMasterScreen> {
  final _formKey = GlobalKey<FormState>();

  final CollectionReference jobsCollection =
  FirebaseFirestore.instance.collection('jobs_master');

  // Controllers
  final TextEditingController skuController = TextEditingController();
  final TextEditingController applicationController = TextEditingController();
  final TextEditingController awcNoController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController dailyDemandController = TextEditingController();
  final TextEditingController defaultSheetHInchController = TextEditingController();
  final TextEditingController defaultSheetWInchController = TextEditingController();
  final TextEditingController dieController = TextEditingController();
  final TextEditingController jobNameController = TextEditingController();
  final TextEditingController machineNameController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController purchaseMaterialController = TextEditingController();
  final TextEditingController purchaseSheetHInchController = TextEditingController();
  final TextEditingController purchaseSheetWInchController = TextEditingController();
  final TextEditingController purchaseSheetUpsController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController sizeHmmController = TextEditingController();
  final TextEditingController sizeWmmController = TextEditingController();
  final TextEditingController upsController = TextEditingController();

  // Scroll Controllers
  final ScrollController previewHorizontalController = ScrollController();
  final ScrollController previewVerticalController = ScrollController();
  final ScrollController existingHorizontalController = ScrollController();
  final ScrollController existingVerticalController = ScrollController();

  // Search filter
  final TextEditingController searchController = TextEditingController();

  // -------------------- CSV Template Download --------------------
  void downloadCsvTemplate() {
    const headers = [
      'sku', 'jobName', 'material', 'color', 'application', 'sizeWmm', 'sizeHmm', 'ups',
      'defaultSheetSizeHInch', 'defaultSheetSizeWInch', 'purchaseSheetSizeHInch',
      'purchaseSheetSizeWInch', 'purchaseSheetUps', 'remarks', 'cost', 'machineName',
      'purchaseMaterial', 'dailyDemand', 'awcNo', 'die',
    ];

    const exampleRow = [
      'FLUFFINGINSTRUCTION-2024', 'FLUFFINGINSTRUCTION-2024', 'offset 75', '2+2', 'No',
      '205', '295', '4', '18', '25', '25', '36', '2', 'Fluffing F + B 2024', '2.2',
      'SM 74', 'Imported', '13358', '1420', '',
    ];

    final csvContent = StringBuffer();
    csvContent.writeln(headers.join(','));
    csvContent.writeln(exampleRow.join(','));

    final bytes = html.Blob([csvContent.toString()], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(bytes);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'bulk_upload_template.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // -------------------- Save / Update Single Job --------------------
  void saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    final sku = skuController.text.trim();
    if (sku.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SKU is required')));
      return;
    }

    final jobMap = {
      'application': applicationController.text.trim(),
      'awcNo': awcNoController.text.trim(),
      'color': colorController.text.trim(),
      'cost': double.tryParse(costController.text.trim()) ?? 0,
      'dailyDemand': int.tryParse(dailyDemandController.text.trim()) ?? 0,
      'defaultSheetSizeHInch': int.tryParse(defaultSheetHInchController.text.trim()) ?? 0,
      'defaultSheetSizeWInch': int.tryParse(defaultSheetWInchController.text.trim()) ?? 0,
      'die': dieController.text.trim(),
      'jobName': jobNameController.text.trim(),
      'machineName': machineNameController.text.trim(),
      'material': materialController.text.trim(),
      'purchaseMaterial': purchaseMaterialController.text.trim(),
      'purchaseSheetSizeHInch': int.tryParse(purchaseSheetHInchController.text.trim()) ?? 0,
      'purchaseSheetSizeWInch': int.tryParse(purchaseSheetWInchController.text.trim()) ?? 0,
      'purchaseSheetUps': int.tryParse(purchaseSheetUpsController.text.trim()) ?? 0,
      'remarks': remarksController.text.trim(),
      'sizeHmm': int.tryParse(sizeHmmController.text.trim()) ?? 0,
      'sizeWmm': int.tryParse(sizeWmmController.text.trim()) ?? 0,
      'ups': int.tryParse(upsController.text.trim()) ?? 0,
      'createdAt': DateTime.now(),
    };

    try {
      await jobsCollection.doc(sku).set(jobMap);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job saved!')));
      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving job: $e')));
    }
  }

  void fetchJobBySku(String sku) async {
    if (sku.isEmpty) return;
    try {
      final doc = await jobsCollection.doc(sku).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job not found')));
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      applicationController.text = data['application'] ?? '';
      awcNoController.text = data['awcNo'] ?? '';
      colorController.text = data['color'] ?? '';
      costController.text = data['cost']?.toString() ?? '';
      dailyDemandController.text = data['dailyDemand']?.toString() ?? '';
      defaultSheetHInchController.text = data['defaultSheetSizeHInch']?.toString() ?? '';
      defaultSheetWInchController.text = data['defaultSheetSizeWInch']?.toString() ?? '';
      dieController.text = data['die'] ?? '';
      jobNameController.text = data['jobName'] ?? '';
      machineNameController.text = data['machineName'] ?? '';
      materialController.text = data['material'] ?? '';
      purchaseMaterialController.text = data['purchaseMaterial'] ?? '';
      purchaseSheetHInchController.text = data['purchaseSheetSizeHInch']?.toString() ?? '';
      purchaseSheetWInchController.text = data['purchaseSheetSizeWInch']?.toString() ?? '';
      purchaseSheetUpsController.text = data['purchaseSheetUps']?.toString() ?? '';
      remarksController.text = data['remarks'] ?? '';
      sizeHmmController.text = data['sizeHmm']?.toString() ?? '';
      sizeWmmController.text = data['sizeWmm']?.toString() ?? '';
      upsController.text = data['ups']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job loaded')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // -------------------- Bulk Upload with RESTORED Error Tracking --------------------
  Future<void> bulkUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    final bytes = result.files.first.bytes ?? await File(result.files.first.path!).readAsBytes();
    final csvString = utf8.decode(bytes);
    final rows = const CsvToListConverter().convert(csvString, eol: '\n');
    if (rows.isEmpty) return;

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.sublist(1);

    final existingDocs = await jobsCollection.get();
    final existingSkus = existingDocs.docs.map((d) => d.id).toSet();

    final List<Map<String, dynamic>> jobsToUpload = [];
    final Map<int, List<String>> rowErrors = {}; // RESTORED
    final List<String> skippedSkus = []; // RESTORED

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final Map<String, dynamic> job = {};
      final List<String> errors = [];

      for (var j = 0; j < headers.length; j++) {
        final key = headers[j];
        final value = row[j].toString().trim();
        job[key] = value;

        if (value.isEmpty && key != 'die' && key != 'awcNo') {
          errors.add('$key is empty');
        }

        if ([
          'cost', 'dailyDemand', 'defaultSheetSizeHInch', 'defaultSheetSizeWInch',
          'purchaseSheetSizeHInch', 'purchaseSheetSizeWInch', 'purchaseSheetUps',
          'sizeHmm', 'sizeWmm', 'ups'
        ].contains(key)) {
          final numValue = double.tryParse(value) ?? int.tryParse(value);
          if (numValue == null) {
            errors.add('$key is not a number');
          } else {
            job[key] = numValue;
          }
        }
      }

      final sku = job['sku']?.toString() ?? '';
      if (sku.isEmpty) errors.add('SKU is empty');
      if (existingSkus.contains(sku)) errors.add('Duplicate SKU');

      if (errors.isNotEmpty) {
        rowErrors[i] = errors;
        skippedSkus.add(sku.isEmpty ? 'Unknown SKU' : sku);
      }
      jobsToUpload.add(job);
    }

    Navigator.pop(context); // close loader

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Preview Bulk Upload'),
        content: SizedBox(
          width: 1200,
          height: 600,
          child: Scrollbar(
            controller: previewVerticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: previewVerticalController,
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                controller: previewHorizontalController,
                thumbVisibility: true,
                notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: previewHorizontalController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: headers.length * 150.0),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowHeight: 42,
                      columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
                      rows: List.generate(jobsToUpload.length, (i) {
                        final job = jobsToUpload[i];
                        final errors = rowErrors[i] ?? []; // RESTORED
                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((_) {
                            if (errors.contains('Duplicate SKU')) return Colors.orange[200];
                            if (errors.isNotEmpty) return Colors.red[200];
                            return null;
                          }),
                          cells: headers.map((h) => DataCell(Text(job[h]?.toString() ?? ''))).toList(),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              for (var i = 0; i < jobsToUpload.length; i++) {
                final job = jobsToUpload[i];
                final sku = job['sku']?.toString() ?? '';
                if (sku.isEmpty || rowErrors.containsKey(i)) continue;
                await jobsCollection.doc(sku).set({...job, 'createdAt': DateTime.now()});
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Bulk upload complete! Skipped: ${skippedSkus.join(', ')}'),
                duration: const Duration(seconds: 6),
              ));
            },
            child: const Text('Confirm Upload'),
          ),
        ],
      ),
    );
  }

  // -------------------- Existing Jobs Table (Full Search & Scrolling) --------------------
  Widget existingJobsTable() {
    final headers = [
      'sku','jobName','material','color','application','sizeWmm','sizeHmm','ups',
      'defaultSheetSizeHInch','defaultSheetSizeWInch','purchaseSheetSizeHInch',
      'purchaseSheetSizeWInch','purchaseSheetUps','remarks','cost','machineName',
      'purchaseMaterial','dailyDemand','awcNo','die'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search SKU / Job Name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Row(
          children: [
            ElevatedButton(onPressed: downloadExistingJobsCsv, child: const Text('Download CSV')),
            const SizedBox(width: 16),
            const Text('Existing Jobs Table', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 500,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
          child: StreamBuilder<QuerySnapshot>(
            stream: jobsCollection.orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No jobs found'));

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final search = searchController.text.trim().toLowerCase();
                if (search.isEmpty) return true;
                return (data['sku']?.toString().toLowerCase().contains(search) ?? false) ||
                    (data['jobName']?.toString().toLowerCase().contains(search) ?? false);
              }).toList();

              return Scrollbar(
                controller: existingVerticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: existingVerticalController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: existingHorizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: existingHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: headers.length * 150.0),
                        child: DataTable(
                          headingRowHeight: 48,
                          dataRowHeight: 45,
                          columnSpacing: 20,
                          columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                          rows: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DataRow(
                              cells: headers.map((h) => DataCell(Text(data[h]?.toString() ?? ''))).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void downloadExistingJobsCsv() async {
    final snapshot = await jobsCollection.get();
    if (snapshot.docs.isEmpty) return;
    final headers = ['sku','jobName','material','color','application','sizeWmm','sizeHmm','ups','defaultSheetSizeHInch','defaultSheetSizeWInch','purchaseSheetSizeHInch','purchaseSheetSizeWInch','purchaseSheetUps','remarks','cost','machineName','purchaseMaterial','dailyDemand','awcNo','die'];
    final csvBuffer = StringBuffer()..writeln(headers.join(','));
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      csvBuffer.writeln(headers.map((h) => '"${data[h] ?? ''}"').join(','));
    }
    final bytes = html.Blob([csvBuffer.toString()], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(bytes);
    html.AnchorElement(href: url)..setAttribute('download', 'existing_jobs.csv')..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs Master')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: skuController,
                          decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                          validator: (val) => val == null || val.isEmpty ? 'Enter SKU' : null,
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.search), onPressed: () => fetchJobBySku(skuController.text.trim())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(jobNameController, 'Job Name'),
                  _buildTextField(applicationController, 'Application'),
                  _buildTextField(awcNoController, 'AWC No'),
                  _buildTextField(colorController, 'Color'),
                  _buildTextField(costController, 'Cost', isNumber: true),
                  _buildTextField(dailyDemandController, 'Daily Demand', isNumber: true),
                  _buildTextField(defaultSheetHInchController, 'Default Sheet H Inch', isNumber: true),
                  _buildTextField(defaultSheetWInchController, 'Default Sheet W Inch', isNumber: true),
                  _buildTextField(dieController, 'Die'),
                  _buildTextField(machineNameController, 'Machine Name'),
                  _buildTextField(materialController, 'Material'),
                  _buildTextField(purchaseMaterialController, 'Purchase Material'),
                  _buildTextField(purchaseSheetHInchController, 'Purchase Sheet H Inch', isNumber: true),
                  _buildTextField(purchaseSheetWInchController, 'Purchase Sheet W Inch', isNumber: true),
                  _buildTextField(purchaseSheetUpsController, 'Purchase Sheet Ups', isNumber: true),
                  _buildTextField(remarksController, 'Remarks'),
                  _buildTextField(sizeHmmController, 'Size H mm', isNumber: true),
                  _buildTextField(sizeWmmController, 'Size W mm', isNumber: true),
                  _buildTextField(upsController, 'UPS', isNumber: true),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(onPressed: downloadCsvTemplate, child: const Text('Download Template')),
                      ElevatedButton(onPressed: bulkUpload, child: const Text('Bulk Upload')),
                      ElevatedButton(onPressed: saveJob, child: const Text('Save / Update')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            existingJobsTable(),
          ],
        ),
      ),
    );
  }
}