class JobMaster {
  final String application;
  final String awcNo;
  final String color;
  final double cost;
  final int dailyDemand;
  final int defaultSheetSizeHInch;
  final int defaultSheetSizeWInch;
  final String die;
  final String jobName;
  final String machineName;
  final String material;
  final String purchaseMaterial;
  final int purchaseSheetSizeHInch;
  final int purchaseSheetSizeWInch;
  final int purchaseSheetUps;
  final String remarks;
  final int sizeHmm;
  final int sizeWmm;
  final int ups;

  JobMaster({
    required this.application,
    required this.awcNo,
    required this.color,
    required this.cost,
    required this.dailyDemand,
    required this.defaultSheetSizeHInch,
    required this.defaultSheetSizeWInch,
    required this.die,
    required this.jobName,
    required this.machineName,
    required this.material,
    required this.purchaseMaterial,
    required this.purchaseSheetSizeHInch,
    required this.purchaseSheetSizeWInch,
    required this.purchaseSheetUps,
    required this.remarks,
    required this.sizeHmm,
    required this.sizeWmm,
    required this.ups,
  });

  Map<String, dynamic> toMap() {
    return {
      'application': application,
      'awcNo': awcNo,
      'color': color,
      'cost': cost,
      'dailyDemand': dailyDemand,
      'defaultSheetSizeHInch': defaultSheetSizeHInch,
      'defaultSheetSizeWInch': defaultSheetSizeWInch,
      'die': die,
      'jobName': jobName,
      'machineName': machineName,
      'material': material,
      'purchaseMaterial': purchaseMaterial,
      'purchaseSheetSizeHInch': purchaseSheetSizeHInch,
      'purchaseSheetSizeWInch': purchaseSheetSizeWInch,
      'purchaseSheetUps': purchaseSheetUps,
      'remarks': remarks,
      'sizeHmm': sizeHmm,
      'sizeWmm': sizeWmm,
      'ups': ups,
      'createdAt': DateTime.now(),
    };
  }
}
