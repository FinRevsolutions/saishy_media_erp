class ApiConstants {
  ApiConstants._();

  static const String defaultBaseUrl =
      'https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec';

  // Sheet names
  static const String sheetUsers = 'Users';
  static const String sheetClients = 'Clients';
  static const String sheetMediaHouses = 'MediaHouses';
  static const String sheetAgencyMappings = 'AgencyMappings';
  static const String sheetReleaseOrders = 'ReleaseOrders';
  static const String sheetPublications = 'Publications';
  static const String sheetInvoices = 'Invoices';
  static const String sheetPayments = 'Payments';
  static const String sheetDocuments = 'Documents';
  static const String sheetSettings = 'Settings';

  // Actions
  static const String actionLogin = 'login';
  static const String actionGetRecords = 'getRecords';
  static const String actionCreateRecord = 'createRecord';
  static const String actionUpdateRecord = 'updateRecord';
  static const String actionDeleteRecord = 'deleteRecord';
  static const String actionGetDashboard = 'getDashboard';
  static const String actionGetReports = 'getReports';
  static const String actionUploadFile = 'uploadFile';
  static const String actionGetNextNumber = 'getNextNumber';
  static const String actionBatchSync = 'batchSync';

  // HTTP timeouts (seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 60;
}
