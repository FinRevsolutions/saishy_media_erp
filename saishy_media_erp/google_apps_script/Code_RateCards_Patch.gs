// Add this SHEETS entry and HEADER_MAP entry to your existing Code.gs
// ── ADDITION to Code.gs ───────────────────────────────────────────────────
// In the SHEETS constant, add:
//     RateCards: 'RateCards',
// In the HEADER_MAP constant, add:
//     RateCards: ['id','media_house_id','media_house_name','rate_type','rate_per_unit','unit','is_active','notes','created_at','updated_at'],

// ── FULL PATCH (paste into your existing Code.gs) ──────────────────────────
// Replace your SHEETS and HEADER_MAP with:

const SHEETS = {
  Users:          'Users',
  Clients:        'Clients',
  MediaHouses:    'MediaHouses',
  AgencyMappings: 'AgencyMappings',
  ReleaseOrders:  'ReleaseOrders',
  Publications:   'Publications',
  Invoices:       'Invoices',
  Payments:       'Payments',
  Documents:      'Documents',
  Settings:       'Settings',
  RateCards:      'RateCards',   // ← ADD THIS LINE
};

const HEADER_MAP = {
  // ... (all existing sheets) ...
  RateCards: [
    'id', 'media_house_id', 'media_house_name', 'rate_type',
    'rate_per_unit', 'unit', 'is_active', 'notes', 'created_at', 'updated_at'
  ],
};

// ── CREATE THE SHEET ────────────────────────────────────────────────────────
// Run this function ONCE in Apps Script to create the RateCards sheet:
function createRateCardsSheet() {
  const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  let sheet = ss.getSheetByName('RateCards');
  if (!sheet) {
    sheet = ss.insertSheet('RateCards');
  }
  const headers = HEADER_MAP.RateCards;
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  sheet.getRange(1, 1, 1, headers.length)
    .setBackground('#1a237e')
    .setFontColor('#ffffff')
    .setFontWeight('bold');
  SpreadsheetApp.flush();
  Logger.log('RateCards sheet created successfully');
}

// ── SAMPLE DATA for testing ────────────────────────────────────────────────
function addSampleRateCards() {
  const ss    = SpreadsheetApp.openById(SPREADSHEET_ID);
  const sheet = ss.getSheetByName('RateCards');
  const sampleRates = [
    ['rc001', 'mh001', 'Prabhat Khabar', 'Black & White', '450', 'col×cm', 'true', '', new Date().toISOString(), new Date().toISOString()],
    ['rc002', 'mh001', 'Prabhat Khabar', 'Color',         '750', 'col×cm', 'true', '', new Date().toISOString(), new Date().toISOString()],
    ['rc003', 'mh001', 'Prabhat Khabar', 'Front Page',   '1200', 'col×cm', 'true', '', new Date().toISOString(), new Date().toISOString()],
    ['rc004', 'mh001', 'Prabhat Khabar', 'Jacket',       '2000', 'col×cm', 'true', '', new Date().toISOString(), new Date().toISOString()],
    ['rc005', 'mh001', 'Prabhat Khabar', 'Government',    '350', 'col×cm', 'true', '', new Date().toISOString(), new Date().toISOString()],
  ];
  sheet.getRange(2, 1, sampleRates.length, sampleRates[0].length).setValues(sampleRates);
  Logger.log('Sample rate cards added');
}
