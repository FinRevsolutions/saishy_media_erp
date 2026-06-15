// =====================================================
// SAISHY Media ERP - Google Apps Script Backend
// Version: 1.0.0 | Production Ready
// =====================================================
// DEPLOYMENT STEPS:
// 1. Open Google Sheets → Extensions → Apps Script
// 2. Paste this entire file
// 3. Run setupSpreadsheet() once
// 4. Deploy → New deployment → Web App
//    Execute as: Me | Access: Anyone
// 5. Copy the Web App URL to Flutter app settings
// =====================================================

const SHEETS = {
  USERS: 'Users',
  CLIENTS: 'Clients',
  MEDIA_HOUSES: 'MediaHouses',
  AGENCY_MAPPINGS: 'AgencyMappings',
  RELEASE_ORDERS: 'ReleaseOrders',
  PUBLICATIONS: 'Publications',
  INVOICES: 'Invoices',
  PAYMENTS: 'Payments',
  DOCUMENTS: 'Documents',
  SETTINGS: 'Settings',
  RATE_CARDS: 'RateCards',
};

// ── Entry Points ──────────────────────────────────────
function doGet(e) {
  try {
    const action = e.parameter.action;
    const params = e.parameter;
    let result;
    switch (action) {
      case 'getRecords':      result = getRecords(params.sheet); break;
      case 'getDashboard':    result = getDashboard(); break;
      case 'getNextNumber':   result = getNextNumber(params.type); break;
      case 'getReports':      result = getReports(params.type, params.from, params.to); break;
      default: throw new Error('Unknown GET action: ' + action);
    }
    return ok(result);
  } catch (err) {
    return fail(err.message);
  }
}

function doPost(e) {
  try {
    const payload = JSON.parse(e.postData.contents);
    const action = payload.action;
    let result;
    switch (action) {
      case 'login':         result = login(payload.username, payload.password_hash); break;
      case 'createRecord':  result = createRecord(payload.sheet, payload.record); break;
      case 'updateRecord':  result = updateRecord(payload.sheet, payload.id, payload.record); break;
      case 'deleteRecord':  result = deleteRecord(payload.sheet, payload.id); break;
      case 'uploadFile':    result = uploadFileToDrive(payload); break;
      case 'batchSync':     result = batchSync(payload.changes); break;
      default: throw new Error('Unknown POST action: ' + action);
    }
    return ok(result);
  } catch (err) {
    return fail(err.message);
  }
}

function ok(data)   { return json({ success: true,  data: data }); }
function fail(msg)  { return json({ success: false, error: msg }); }
function json(obj)  { return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON); }

// ── Authentication ─────────────────────────────────────
function login(username, passwordHash) {
  const sheet = getSheet(SHEETS.USERS);
  const users = sheetToObjects(sheet);
  const user  = users.find(u =>
    u.username === username &&
    u.password_hash === passwordHash &&
    u.is_active !== 'false'
  );
  if (!user) throw new Error('Invalid username or password');
  updateRecord(SHEETS.USERS, user.id, { ...user, last_login: new Date().toISOString() });
  return { id: user.id, username: user.username, role: user.role,
           full_name: user.full_name, email: user.email || '', mobile: user.mobile || '' };
}

// ── CRUD ──────────────────────────────────────────────
function getRecords(sheetName) {
  const sheet = getSheet(sheetName);
  return sheetToObjects(sheet);
}

function createRecord(sheetName, record) {
  const sheet   = getSheet(sheetName);
  const headers = getHeaders(sheet);
  if (!record.id && !record.ro_number && !record.invoice_number) {
    record.id = Utilities.getUuid();
  }
  if (!record.created_at) record.created_at = new Date().toISOString();
  const row = headers.map(h => (record[h] !== undefined && record[h] !== null) ? record[h] : '');
  sheet.appendRow(row);
  if (sheetName === SHEETS.PUBLICATIONS && record.status === 'Published') {
    triggerAutoBilling(record.ro_number);
  }
  return record;
}

function updateRecord(sheetName, id, record) {
  const sheet   = getSheet(sheetName);
  const headers = getHeaders(sheet);
  const data    = sheet.getDataRange().getValues();
  const idCols  = ['id', 'ro_number', 'invoice_number'];
  let idColIdx  = -1;
  for (const c of idCols) { const i = headers.indexOf(c); if (i >= 0) { idColIdx = i; break; } }
  if (idColIdx < 0) throw new Error('No ID column in ' + sheetName);
  let rowIdx = -1;
  for (let i = 1; i < data.length; i++) {
    if (data[i][idColIdx]?.toString() === id.toString()) { rowIdx = i + 1; break; }
  }
  if (rowIdx < 0) return createRecord(sheetName, record);
  record.updated_at = new Date().toISOString();
  const row = headers.map(h => (record[h] !== undefined && record[h] !== null) ? record[h] : '');
  sheet.getRange(rowIdx, 1, 1, row.length).setValues([row]);
  if (sheetName === SHEETS.PUBLICATIONS && record.status === 'Published') {
    triggerAutoBilling(record.ro_number);
  }
  return record;
}

function deleteRecord(sheetName, id) {
  const sheet   = getSheet(sheetName);
  const headers = getHeaders(sheet);
  const data    = sheet.getDataRange().getValues();
  const idCols  = ['id', 'ro_number', 'invoice_number'];
  let idColIdx  = -1;
  for (const c of idCols) { const i = headers.indexOf(c); if (i >= 0) { idColIdx = i; break; } }
  for (let i = 1; i < data.length; i++) {
    if (data[i][idColIdx]?.toString() === id.toString()) {
      const isActiveIdx = headers.indexOf('is_active');
      if (isActiveIdx >= 0) {
        sheet.getRange(i + 1, isActiveIdx + 1).setValue('false');
      } else {
        sheet.deleteRow(i + 1);
      }
      return { deleted: true, id };
    }
  }
  throw new Error('Record not found: ' + id);
}

// ── Auto Billing Trigger ──────────────────────────────
function triggerAutoBilling(roNumber) {
  if (!roNumber) return;
  const rosData  = sheetToObjects(getSheet(SHEETS.RELEASE_ORDERS));
  const ro       = rosData.find(r => r.ro_number === roNumber);
  if (!ro) return;
  const invData  = sheetToObjects(getSheet(SHEETS.INVOICES));
  if (invData.find(i => i.ro_number === roNumber)) return; // Already exists

  const invNumber  = generateInvoiceNumber();
  const amount     = parseFloat(ro.amount)         || 0;
  const discount   = parseFloat(ro.trade_discount)  || 0;
  const taxable    = parseFloat(ro.taxable_amount)  || 0;
  const gstAmt     = parseFloat(ro.gst_amount)      || 0;
  const total      = parseFloat(ro.net_payable)     || 0;

  const clients    = sheetToObjects(getSheet(SHEETS.CLIENTS));
  const party      = clients.find(c => c.id === ro.party_id);

  const invoice = {
    invoice_number: invNumber,
    ro_number:       roNumber,
    party_id:        ro.party_id,
    party_name:      ro.party_name,
    party_gstin:     party?.gstin     || '',
    party_address:   party?.address   || '',
    media_house_id:  ro.media_house_id,
    media_house_name:ro.media_house_name,
    publication_date:ro.publication_date,
    invoice_date:    new Date().toISOString().split('T')[0],
    amount:          amount.toFixed(2),
    trade_discount:  discount.toFixed(2),
    taxable_amount:  taxable.toFixed(2),
    gst_type:        ro.gst_type,
    cgst:            (gstAmt / 2).toFixed(2),
    sgst:            (gstAmt / 2).toFixed(2),
    gst_amount:      gstAmt.toFixed(2),
    total_amount:    total.toFixed(2),
    amount_paid:     '0.00',
    status:          'Pending',
    is_gst_invoice:  (ro.gst_type !== 'none' && ro.gst_type !== '').toString(),
    created_by:      'System (Auto)',
    notes:           'Auto-generated from RO ' + roNumber,
    due_date:        '',
    created_at:      new Date().toISOString(),
    updated_at:      new Date().toISOString(),
  };
  createRecord(SHEETS.INVOICES, invoice);
  updateRecord(SHEETS.RELEASE_ORDERS, roNumber, { ...ro, status: 'Billed' });
}

// ── Auto Numbering ─────────────────────────────────────
function getNextNumber(type) {
  if (type === 'RO')  return generateRONumber();
  if (type === 'INV') return generateInvoiceNumber();
  return Utilities.getUuid();
}

function generateRONumber() {
  const now    = new Date();
  const ym     = now.getFullYear().toString() + (now.getMonth()+1).toString().padStart(2,'0');
  const data   = sheetToObjects(getSheet(SHEETS.RELEASE_ORDERS));
  const count  = data.filter(r => r.ro_number && r.ro_number.includes('-'+ym+'-')).length;
  return 'RO-' + ym + '-' + (count + 1).toString().padStart(4, '0');
}

function generateInvoiceNumber() {
  const now    = new Date();
  const ym     = now.getFullYear().toString() + (now.getMonth()+1).toString().padStart(2,'0');
  const data   = sheetToObjects(getSheet(SHEETS.INVOICES));
  const count  = data.filter(i => i.invoice_number && i.invoice_number.includes('-'+ym+'-')).length;
  return 'INV-' + ym + '-' + (count + 1).toString().padStart(4, '0');
}

// ── Dashboard ─────────────────────────────────────────
function getDashboard() {
  const clients     = sheetToObjects(getSheet(SHEETS.CLIENTS)).filter(c => c.is_active !== 'false');
  const mediaHouses = sheetToObjects(getSheet(SHEETS.MEDIA_HOUSES)).filter(m => m.is_active !== 'false');
  const ros         = sheetToObjects(getSheet(SHEETS.RELEASE_ORDERS));
  const invoices    = sheetToObjects(getSheet(SHEETS.INVOICES));

  const now = new Date();
  const ym  = now.getFullYear().toString() + '-' + (now.getMonth()+1).toString().padStart(2,'0');

  const pendingPubs = ros.filter(ro =>
    ro.status !== 'Published' && ro.status !== 'Billed' && ro.status !== 'Paid').length;

  const pendingBills = invoices.filter(i => i.status === 'Pending' || i.status === 'Partial').length;

  const outstanding = invoices.reduce((s, inv) => {
    if (inv.status !== 'Paid') {
      return s + ((parseFloat(inv.total_amount)||0) - (parseFloat(inv.amount_paid)||0));
    }
    return s;
  }, 0);

  const monthlyRevenue = invoices
    .filter(i => (i.invoice_date||'').startsWith(ym))
    .reduce((s, i) => s + (parseFloat(i.amount_paid)||0), 0);

  const totalRevenue = invoices.reduce((s, i) => s + (parseFloat(i.amount_paid)||0), 0);
  const monthlyROs   = ros.filter(r => (r.created_at||'').startsWith(ym)).length;

  const chartData = getMonthlyChartData(invoices, 6);

  const statusDist = {};
  ros.forEach(ro => { statusDist[ro.status] = (statusDist[ro.status]||0) + 1; });

  const recentROs = ros
    .sort((a, b) => (b.created_at||'').localeCompare(a.created_at||''))
    .slice(0, 5);

  return {
    total_clients:       clients.length,
    total_media_houses:  mediaHouses.length,
    total_ros:           ros.length,
    monthly_ros:         monthlyROs,
    pending_publications:pendingPubs,
    pending_bills:       pendingBills,
    outstanding_amount:  outstanding.toFixed(2),
    monthly_revenue:     monthlyRevenue.toFixed(2),
    total_revenue:       totalRevenue.toFixed(2),
    chart_data:          chartData,
    recent_ros:          recentROs,
    status_distribution: statusDist,
  };
}

function getMonthlyChartData(invoices, months) {
  const now  = new Date();
  const data = [];
  for (let i = months - 1; i >= 0; i--) {
    const d   = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const ym  = d.getFullYear().toString() + '-' + (d.getMonth()+1).toString().padStart(2,'0');
    const lbl = d.toLocaleString('default', { month: 'short' }) + ' ' + d.getFullYear().toString().slice(-2);
    const rev = invoices
      .filter(inv => (inv.invoice_date||'').startsWith(ym))
      .reduce((s, inv) => s + (parseFloat(inv.amount_paid)||0), 0);
    data.push({ month: lbl, revenue: rev.toFixed(2) });
  }
  return data;
}

// ── Reports ───────────────────────────────────────────
function getReports(type, fromDate, toDate) {
  switch (type) {
    case 'client_wise':     return getClientWiseReport(fromDate, toDate);
    case 'media_wise':      return getMediaWiseReport(fromDate, toDate);
    case 'revenue':         return getRevenueReport(fromDate, toDate);
    case 'outstanding':     return getOutstandingReport();
    case 'monthly_summary': return getMonthlySummary(fromDate, toDate);
    default: throw new Error('Unknown report type: ' + type);
  }
}

function filterByDate(data, from, to, field) {
  return data.filter(item => {
    const d = item[field] || '';
    if (from && d && d < from) return false;
    if (to   && d && d > to)   return false;
    return true;
  });
}

function getClientWiseReport(from, to) {
  const invoices = filterByDate(sheetToObjects(getSheet(SHEETS.INVOICES)), from, to, 'invoice_date');
  const summary  = {};
  invoices.forEach(inv => {
    const k = inv.party_name;
    if (!summary[k]) summary[k] = { party_name: k, party_id: inv.party_id, total: 0, paid: 0, count: 0 };
    summary[k].total += parseFloat(inv.total_amount)||0;
    summary[k].paid  += parseFloat(inv.amount_paid)||0;
    summary[k].count++;
  });
  return Object.values(summary).sort((a,b) => b.total - a.total);
}

function getMediaWiseReport(from, to) {
  const ros     = filterByDate(sheetToObjects(getSheet(SHEETS.RELEASE_ORDERS)), from, to, 'date');
  const summary = {};
  ros.forEach(ro => {
    const k = ro.media_house_name;
    if (!summary[k]) summary[k] = { media_house_name: k, ro_count: 0, total: 0 };
    summary[k].ro_count++;
    summary[k].total += parseFloat(ro.net_payable)||0;
  });
  return Object.values(summary).sort((a,b) => b.total - a.total);
}

function getRevenueReport(from, to) {
  const invoices = filterByDate(sheetToObjects(getSheet(SHEETS.INVOICES)), from, to, 'invoice_date');
  return {
    total_invoiced:   invoices.reduce((s,i)=>s+(parseFloat(i.total_amount)||0),0).toFixed(2),
    total_collected:  invoices.reduce((s,i)=>s+(parseFloat(i.amount_paid)||0),0).toFixed(2),
    total_outstanding:invoices.filter(i=>i.status!=='Paid')
      .reduce((s,i)=>s+((parseFloat(i.total_amount)||0)-(parseFloat(i.amount_paid)||0)),0).toFixed(2),
    invoice_count:    invoices.length,
    invoices:         invoices,
  };
}

function getOutstandingReport() {
  const invoices = sheetToObjects(getSheet(SHEETS.INVOICES)).filter(i => i.status !== 'Paid');
  return invoices.map(inv => ({
    ...inv,
    balance: ((parseFloat(inv.total_amount)||0)-(parseFloat(inv.amount_paid)||0)).toFixed(2),
    days_overdue: inv.due_date
      ? Math.max(0, Math.floor((new Date()-new Date(inv.due_date))/86400000)) : 0,
  })).sort((a,b) => parseFloat(b.balance)-parseFloat(a.balance));
}

function getMonthlySummary(from, to) {
  const invoices = filterByDate(sheetToObjects(getSheet(SHEETS.INVOICES)), from, to, 'invoice_date');
  const ros      = filterByDate(sheetToObjects(getSheet(SHEETS.RELEASE_ORDERS)), from, to, 'date');
  const m = {};
  invoices.forEach(inv => {
    const k = (inv.invoice_date||'').substring(0,7);
    if (!m[k]) m[k] = { month: k, invoiced: 0, collected: 0, ros: 0 };
    m[k].invoiced   += parseFloat(inv.total_amount)||0;
    m[k].collected  += parseFloat(inv.amount_paid)||0;
  });
  ros.forEach(ro => {
    const k = (ro.date||'').substring(0,7);
    if (m[k]) m[k].ros++;
  });
  return Object.values(m).sort((a,b) => a.month.localeCompare(b.month));
}

// ── File Upload (Google Drive) ─────────────────────────
function uploadFileToDrive(payload) {
  const { file_name, data, mime_type } = payload;
  const bytes  = Utilities.base64Decode(data);
  const blob   = Utilities.newBlob(bytes, mime_type, file_name);

  let folder = DriveApp.getRootFolder();
  try {
    const iter = DriveApp.getFoldersByName('SAISHY Media ERP Files');
    folder = iter.hasNext() ? iter.next() : DriveApp.createFolder('SAISHY Media ERP Files');
  } catch (_) {}

  const file = folder.createFile(blob);
  file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  return {
    file_id:      file.getId(),
    file_url:     file.getUrl(),
    download_url: 'https://drive.google.com/uc?id=' + file.getId(),
    file_name:    file.getName(),
    size:         file.getSize(),
  };
}

// ── Batch Sync ─────────────────────────────────────────
function batchSync(changes) {
  if (!changes || !Array.isArray(changes)) return [];
  const results = [];
  for (const ch of changes) {
    try {
      const sheet = tableToSheet(ch.table_name);
      if (ch.action === 'upsert') {
        try { updateRecord(sheet, ch.record_id, ch.data); }
        catch(_) { createRecord(sheet, ch.data); }
        results.push({ id: ch.record_id, status: 'synced' });
      } else if (ch.action === 'delete') {
        deleteRecord(sheet, ch.record_id);
        results.push({ id: ch.record_id, status: 'deleted' });
      }
    } catch (err) {
      results.push({ id: ch.record_id, status: 'error', error: err.message });
    }
  }
  return results;
}

function tableToSheet(t) {
  return ({ parties:'Clients', media_houses:'MediaHouses', agency_mappings:'AgencyMappings',
    release_orders:'ReleaseOrders', publications:'Publications', invoices:'Invoices',
    payments:'Payments', documents:'Documents' })[t] || t;
}

// ── Sheet Helpers ─────────────────────────────────────
function getSheet(name) {
  const ss    = SpreadsheetApp.getActiveSpreadsheet();
  let sheet   = ss.getSheetByName(name);
  if (!sheet) { sheet = ss.insertSheet(name); initHeaders(sheet, name); }
  return sheet;
}

function getHeaders(sheet) {
  const lastCol = sheet.getLastColumn();
  if (lastCol < 1) return [];
  return sheet.getRange(1,1,1,lastCol).getValues()[0].map(h=>h.toString().trim()).filter(h=>h);
}

function sheetToObjects(sheet) {
  const lr = sheet.getLastRow();
  const lc = sheet.getLastColumn();
  if (lr < 2 || lc < 1) return [];
  const data    = sheet.getRange(1, 1, lr, lc).getValues();
  const headers = data[0].map(h => h.toString().trim());
  return data.slice(1).map(row => {
    const obj = {};
    headers.forEach((h, i) => { obj[h] = row[i]?.toString() || ''; });
    return obj;
  }).filter(obj => Object.values(obj).some(v => v !== ''));
}

// ── Header Definitions ─────────────────────────────────
const HEADER_MAP = {
  Users:          ['id','username','password_hash','role','full_name','email','mobile','is_active','created_at','last_login'],
  Clients:        ['id','name','address','mobile','email','gst_applicable','gstin','contact_person','state','state_code','notes','is_active','created_at','updated_at'],
  MediaHouses:    ['id','name','edition','language','contact_person','mobile','email','gst_percentage','address','notes','is_active','created_at'],
  AgencyMappings: ['id','media_house_id','media_house_name','agency_name','agency_address','agency_gstin','agency_phone','agency_email','is_default','created_at'],
  ReleaseOrders:  ['ro_number','date','party_id','party_name','media_house_id','media_house_name','agency_name','publication_date','category','ad_width','ad_height','ad_unit','rate','gst_type','amount','trade_discount','taxable_amount','gst_amount','net_payable','status','created_by','notes','is_draft','created_at','updated_at'],
  Publications:   ['id','ro_number','party_name','media_house_name','agency_name','publication_date','status','published_edition','proof_url','epaper_url','cutting_url','notes','status_updated_at','status_updated_by','created_at'],
  Invoices:       ['invoice_number','ro_number','party_id','party_name','party_gstin','party_address','media_house_id','media_house_name','publication_date','invoice_date','amount','trade_discount','taxable_amount','gst_type','cgst','sgst','gst_amount','total_amount','amount_paid','status','is_gst_invoice','created_by','notes','due_date','created_at','updated_at'],
  Payments:       ['id','invoice_number','party_id','party_name','amount_paid','invoice_total','payment_date','payment_mode','cheque_number','bank_name','transaction_id','status','received_by','notes','receipt_url','created_at'],
  Documents:      ['id','reference_number','reference_type','document_type','file_url','drive_file_id','file_name','file_size_bytes','mime_type','description','uploaded_by','uploaded_at'],
  Settings:       ['key','value','updated_at'],
  RateCards:      ['id','media_house_id','media_house_name','rate_type','rate_per_unit','unit','is_active','notes','created_at','updated_at'],
};

function initHeaders(sheet, name) {
  const headers = HEADER_MAP[name] || [];
  if (!headers.length) return;
  sheet.getRange(1,1,1,headers.length).setValues([headers]);
  const r = sheet.getRange(1,1,1,headers.length);
  r.setBackground('#1A73E8');
  r.setFontColor('#FFFFFF');
  r.setFontWeight('bold');
  r.setFontSize(10);
  sheet.setFrozenRows(1);
  try { sheet.autoResizeColumns(1, headers.length); } catch(_) {}
}

// ── ONE-TIME SETUP ─────────────────────────────────────
function setupSpreadsheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  ss.setName('SAISHY Media ERP Database');

  for (const name of Object.values(SHEETS)) {
    let sheet = ss.getSheetByName(name);
    if (!sheet) sheet = ss.insertSheet(name);
    if (sheet.getLastColumn() < 1 || sheet.getRange(1,1).getValue() === '') {
      sheet.clearContents();
      initHeaders(sheet, name);
    }
  }

  // Create default Super Admin (password: 123)
  const usersSheet = getSheet(SHEETS.USERS);
  if (sheetToObjects(usersSheet).length === 0) {
    // SHA-256 of "123" = a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3
    createRecord(SHEETS.USERS, {
      id: Utilities.getUuid(),
      username: 'admin',
      password_hash: 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
      role: 'Super Admin',
      full_name: 'System Administrator',
      email: 'admin@saishymedia.com',
      mobile: '',
      is_active: 'true',
      created_at: new Date().toISOString(),
      last_login: '',
    });
  }

  try {
    SpreadsheetApp.getUi().alert(
      '✅ SAISHY Media ERP Setup Complete!\n\n' +
      'Default Login:\nUsername: admin\nPassword: 123\n\n' +
      'Next Steps:\n1. Deploy as Web App\n2. Copy URL to Flutter app settings\n3. Change admin password'
    );
  } catch(_) { Logger.log('Setup done. Default login: admin / 123'); }
}

// ── CHANGE PASSWORD UTILITY ────────────────────────────
function changePassword(username, newPassword) {
  const hash = computeSha256(newPassword);
  const users = sheetToObjects(getSheet(SHEETS.USERS));
  const user  = users.find(u => u.username === username);
  if (!user) throw new Error('User not found: ' + username);
  updateRecord(SHEETS.USERS, user.id, { ...user, password_hash: hash });
  Logger.log('Password changed for: ' + username);
}

function computeSha256(text) {
  const bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, text);
  return bytes.map(b => (b < 0 ? b + 256 : b).toString(16).padStart(2, '0')).join('');
}

// ── CREATE USER UTILITY ────────────────────────────────
function createUser(username, password, role, fullName, email) {
  const hash = computeSha256(password);
  return createRecord(SHEETS.USERS, {
    id:            Utilities.getUuid(),
    username:      username,
    password_hash: hash,
    role:          role || 'Operator',
    full_name:     fullName || username,
    email:         email || '',
    mobile:        '',
    is_active:     'true',
    created_at:    new Date().toISOString(),
    last_login:    '',
  });
}
