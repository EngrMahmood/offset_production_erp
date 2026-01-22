import 'dart:convert';

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



  void downloadCsvTemplate() {
    // CSV headers
    const headers = [
      'sku',
      'jobName',
      'material',
      'color',
      'application',
      'sizeWmm',
      'sizeHmm',
      'ups',
      'defaultSheetSizeHInch',
      'defaultSheetSizeWInch',
      'purchaseSheetSizeHInch',
      'purchaseSheetSizeWInch',
      'purchaseSheetUps',
      'remarks',
      'cost',
      'machineName',
      'purchaseMaterial',
      'dailyDemand',
      'awcNo',
      'die',
    ];

    // Example row
    const exampleRow = [
      'FLUFFINGINSTRUCTION-2024',
      'FLUFFINGINSTRUCTION-2024',
      'offset 75',
      '2+2',
      'No',
      '205',
      '295',
      '4',
      '18',
      '25',
      '25',
      '36',
      '2',
      'Fluffing F + B 2024',
      '2.2',
      'SM 74',
      'Imported',
      '13358',
      '1420',
      '',

    ];

    // Convert to CSV string
    final csvContent = StringBuffer();
    csvContent.writeln(headers.join(','));
    csvContent.writeln(exampleRow.join(','));

    // Encode and create a download link
    final bytes = html.Blob([csvContent.toString()], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(bytes);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'bulk_upload_template.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }


  void bulkUpload() async {
    // Pick CSV file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return; // user canceled

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          content: SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 100));

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final csvString = utf8.decode(bytes);
    final rows = const CsvToListConverter().convert(csvString, eol: '\n');

    if (rows.isEmpty) return;

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.sublist(1); // skip header

    final List<Map<String, dynamic>> jobsToUpload = [];
    final Map<int, List<String>> rowErrors = {}; // rowIndex -> list of errors
    final List<String> skippedSkus = [];

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final Map<String, dynamic> job = {};
      final List<String> errors = [];

      for (var j = 0; j < headers.length; j++) {
        final key = headers[j];
        final value = row[j].toString().trim();
        job[key] = value;

        // Check empty field
        if (value.isEmpty) {
          errors.add('$key is empty');
        }

        // Numeric conversion for specific fields
        if ([
          'cost',
          'dailyDemand',
          'defaultSheetSizeHInch',
          'defaultSheetSizeWInch',
          'purchaseSheetSizeHInch',
          'purchaseSheetWInch',
          'purchaseSheetUps',
          'sizeHmm',
          'sizeWmm',
          'ups'
        ].contains(key)) {
          final numValue = double.tryParse(value) ?? int.tryParse(value);
          if (numValue == null) {
            errors.add('$key is not a number');
          } else {
            job[key] = numValue;
          }
        }
      }

      final sku = job['sku']?.toString() ?? 'sku_$i';

      // Check duplicate in Firestore
      final doc = await jobsCollection.doc(sku).get();
      if (doc.exists) {
        skippedSkus.add(sku);
        errors.add('Duplicate SKU');
      }

      if (errors.isNotEmpty) {
        rowErrors[i] = errors;
      }

      jobsToUpload.add(job);
    }

    // Close loader / previous dialog
    Navigator.pop(context);

    final ScrollController horizontalController = ScrollController();
    final ScrollController verticalController = ScrollController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Preview Bulk Upload'),
          content: SizedBox(
            width: 1000,
            height: 500,
            child: Scrollbar(
              controller: verticalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: verticalController,
                scrollDirection: Axis.vertical,
                child: Scrollbar(
                  controller: horizontalController,
                  thumbVisibility: true,
                  notificationPredicate: (n) =>
                  n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: headers.length * 160, // table width
                      ),
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowHeight: 42,
                        columnSpacing: 20,
                        columns: headers
                            .map((h) => DataColumn(label: Text(h)))
                            .toList(),
                        rows: List.generate(jobsToUpload.length, (i) {
                          final job = jobsToUpload[i];
                          final errors = rowErrors[i] ?? [];

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                                  (_) {
                                if (errors.contains('Duplicate SKU')) {
                                  return Colors.orange[200];
                                }
                                if (errors.isNotEmpty) {
                                  return Colors.red[200];
                                }
                                return null;
                              },
                            ),
                            cells: headers
                                .map(
                                  (h) =>
                                  DataCell(
                                    Text(
                                      job[h]?.toString() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            )
                                .toList(),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
            onPressed: () async {
        List<String> skippedSkus = [];

        for (var job in jobsToUpload) {
        final sku = job['sku']?.toString().trim();

        // Validate SKU and required fields
        bool hasEmptyField = job.entries.any((e) {
        final key = e.key;
        final value = e.value?.toString().trim() ?? '';
        return value.isEmpty && key != 'die'&& key != 'awcNo'; // 'die,awcNo' is optional
        });

        if (sku == null || sku.isEmpty || hasEmptyField) {
        skippedSkus.add(sku ?? 'Unknown SKU');
        continue; // skip this row
        }

        // Check for duplicates in Firestore
        final docSnapshot = await jobsCollection.doc(sku).get();
        if (docSnapshot.exists) {
        skippedSkus.add(sku);
        continue; // skip duplicates
        }

        // Upload valid job
        await jobsCollection.doc(sku).set({
        ...job,
        'createdAt': DateTime.now(),
        });
        }

        Navigator.pop(context); // close preview dialog

        // Show result
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: Text(
        'Bulk upload completed! '
        '${jobsToUpload.length - skippedSkus.length} uploaded, '
        '${skippedSkus.length} skipped: ${skippedSkus.join(', ')}',
        ),
        duration: const Duration(seconds: 6),
        ),
        );
        },
        child: const Text('Confirm Upload'),
        ),
          ],
        );
      },
    );
  }


    // Controllers
  final TextEditingController skuController = TextEditingController();
  final TextEditingController applicationController = TextEditingController();
  final TextEditingController awcNoController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController dailyDemandController = TextEditingController();
  final TextEditingController defaultSheetHInchController =
  TextEditingController();
  final TextEditingController defaultSheetWInchController =
  TextEditingController();
  final TextEditingController dieController = TextEditingController();
  final TextEditingController jobNameController = TextEditingController();
  final TextEditingController machineNameController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController purchaseMaterialController =
  TextEditingController();
  final TextEditingController purchaseSheetHInchController =
  TextEditingController();
  final TextEditingController purchaseSheetWInchController =
  TextEditingController();
  final TextEditingController purchaseSheetUpsController =
  TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController sizeHmmController = TextEditingController();
  final TextEditingController sizeWmmController = TextEditingController();
  final TextEditingController upsController = TextEditingController();

  void saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    final sku = skuController.text.trim();
    if (sku.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SKU is required')));
      return;
    }

    final jobMap = {
      'application': applicationController.text.trim(),
      'awcNo': awcNoController.text.trim(),
      'color': colorController.text.trim(),
      'cost': double.tryParse(costController.text.trim()) ?? 0,
      'dailyDemand': int.tryParse(dailyDemandController.text.trim()) ?? 0,
      'defaultSheetSizeHInch':
      int.tryParse(defaultSheetHInchController.text.trim()) ?? 0,
      'defaultSheetSizeWInch':
      int.tryParse(defaultSheetWInchController.text.trim()) ?? 0,
      'die': dieController.text.trim(),
      'jobName': jobNameController.text.trim(),
      'machineName': machineNameController.text.trim(),
      'material': materialController.text.trim(),
      'purchaseMaterial': purchaseMaterialController.text.trim(),
      'purchaseSheetSizeHInch':
      int.tryParse(purchaseSheetHInchController.text.trim()) ?? 0,
      'purchaseSheetSizeWInch':
      int.tryParse(purchaseSheetWInchController.text.trim()) ?? 0,
      'purchaseSheetUps':
      int.tryParse(purchaseSheetUpsController.text.trim()) ?? 0,
      'remarks': remarksController.text.trim(),
      'sizeHmm': int.tryParse(sizeHmmController.text.trim()) ?? 0,
      'sizeWmm': int.tryParse(sizeWmmController.text.trim()) ?? 0,
      'ups': int.tryParse(upsController.text.trim()) ?? 0,
      'createdAt': DateTime.now(),
    };

    try {
      await jobsCollection.doc(sku).set(jobMap);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job saved!')));
      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving job: $e')));
    }
  }

  void fetchJobBySku(String sku) async {
    if (sku.isEmpty) return;

    try {
      final doc = await jobsCollection.doc(sku).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job not found')));
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      applicationController.text = data['application'] ?? '';
      awcNoController.text = data['awcNo'] ?? '';
      colorController.text = data['color'] ?? '';
      costController.text = data['cost']?.toString() ?? '';
      dailyDemandController.text = data['dailyDemand']?.toString() ?? '';
      defaultSheetHInchController.text =
          data['defaultSheetSizeHInch']?.toString() ?? '';
      defaultSheetWInchController.text =
          data['defaultSheetSizeWInch']?.toString() ?? '';
      dieController.text = data['die'] ?? '';
      jobNameController.text = data['jobName'] ?? '';
      machineNameController.text = data['machineName'] ?? '';
      materialController.text = data['material'] ?? '';
      purchaseMaterialController.text = data['purchaseMaterial'] ?? '';
      purchaseSheetHInchController.text =
          data['purchaseSheetSizeHInch']?.toString() ?? '';
      purchaseSheetWInchController.text =
          data['purchaseSheetSizeWInch']?.toString() ?? '';
      purchaseSheetUpsController.text =
          data['purchaseSheetUps']?.toString() ?? '';
      remarksController.text = data['remarks'] ?? '';
      sizeHmmController.text = data['sizeHmm']?.toString() ?? '';
      sizeWmmController.text = data['sizeWmm']?.toString() ?? '';
      upsController.text = data['ups']?.toString() ?? '';

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job loaded')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs Master')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // SKU + Search
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: skuController,
                      decoration: const InputDecoration(labelText: 'SKU'),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Enter SKU' : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => fetchJobBySku(skuController.text.trim()),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Column(
                children: [
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
                ],
              ),


              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: downloadCsvTemplate,
                child: const Text('Download CSV Template'),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: bulkUpload,
                child: const Text('Bulk Upload CSV'),
              ),


              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: saveJob, child: const Text('Save / Update Job')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}
