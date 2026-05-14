import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/company.dart';
import '../../data/models/financial_target.dart';
import '../../data/models/quarterly_actual.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExcelService {
  static Future<void> exportToExcel({
    required List<Company> companies,
    required List<FinancialTarget> targets,
    required List<QuarterlyActual> actuals,
  }) async {
    var excel = Excel.createExcel();
    
    // 1. Companies Sheet
    Sheet sheetCompanies = excel['Sirketler'];
    sheetCompanies.appendRow([
      TextCellValue('ID'), 
      TextCellValue('Kod (Ticker)'), 
      TextCellValue('Ad'), 
      TextCellValue('Sektör')
    ]);
    for (var c in companies) {
      sheetCompanies.appendRow([
        TextCellValue(c.id), 
        TextCellValue(c.ticker), 
        TextCellValue(c.name), 
        TextCellValue(c.sector ?? '')
      ]);
    }

    // 2. Targets Sheet
    Sheet sheetTargets = excel['Hedefler'];
    sheetTargets.appendRow([
      TextCellValue('Borsa Kodu'), 
      TextCellValue('Yıl'), 
      TextCellValue('Satış Hedefi'), 
      TextCellValue('Satış Büyüme %'), 
      TextCellValue('FAVÖK Hedefi'), 
      TextCellValue('FAVÖK Büyüme %'), 
      TextCellValue('Marj %')
    ]);
    for (var t in targets) {
      final company = companies.firstWhere((c) => c.id == t.companyId, orElse: () => Company(id: '', ticker: 'UNK', name: ''));
      sheetTargets.appendRow([
        TextCellValue(company.ticker), 
        IntCellValue(t.year), 
        DoubleCellValue(t.sales ?? 0), 
        DoubleCellValue(t.salesGrowth ?? 0), 
        DoubleCellValue(t.ebitda ?? 0), 
        DoubleCellValue(t.ebitdaGrowth ?? 0), 
        DoubleCellValue(t.ebitdaMargin ?? 0)
      ]);
    }

    // 3. Actuals Sheet
    Sheet sheetActuals = excel['Gerceklesenler'];
    sheetActuals.appendRow([
      TextCellValue('Borsa Kodu'), 
      TextCellValue('Yıl'), 
      TextCellValue('Çeyrek'), 
      TextCellValue('Satış'), 
      TextCellValue('FAVÖK'), 
      TextCellValue('Yatırım'),
      TextCellValue('Girişi Yapan')
    ]);
    for (var a in actuals) {
      final company = companies.firstWhere((c) => c.id == a.companyId, orElse: () => Company(id: '', ticker: 'UNK', name: ''));
      sheetActuals.appendRow([
        TextCellValue(company.ticker), 
        IntCellValue(a.year), 
        IntCellValue(a.quarter), 
        DoubleCellValue(a.sales), 
        DoubleCellValue(a.ebitda), 
        DoubleCellValue(a.investment ?? 0),
        TextCellValue(a.addedBy ?? '')
      ]);
    }

    // Remove default sheet
    excel.delete('Sheet1');

    // Save & Download (Web specific)
    final bytes = excel.save();
    if (bytes != null) {
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'Borsa_Terminali_Export.xlsx';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      }
    }
  }

  static Future<Map<String, List<dynamic>>?> importFromExcel() async {
    try {
      print("Excel Seçici Başlatılıyor...");
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        print("Dosya seçildi: ${result.files.first.name}");
        var bytes = result.files.first.bytes;
        if (bytes == null) {
          print("Hata: Dosya içeriği boş (bytes null)");
          return null;
        }
        
        print("Excel Çözülüyor (Decoding)...");
        var excel = Excel.decodeBytes(bytes);
        
        List<Company> importedCompanies = [];
        List<FinancialTarget> importedTargets = [];
        List<QuarterlyActual> importedActuals = [];

        // Parse Companies
        var sheetCompanies = excel.tables['Sirketler'];
        if (sheetCompanies != null) {
          print("'Sirketler' sayfası bulundu. Satır sayısı: ${sheetCompanies.maxRows}");
          for (int i = 1; i < sheetCompanies.maxRows; i++) {
            var row = sheetCompanies.rows[i];
            if (row.length >= 4 && row[0]?.value != null) {
              importedCompanies.add(Company(
                id: row[0]?.value.toString() ?? '',
                ticker: row[1]?.value.toString() ?? '',
                name: row[2]?.value.toString() ?? '',
                sector: row[3]?.value.toString(),
              ));
            }
          }
        } else {
          print("Hata: 'Sirketler' sayfası bulunamadı!");
        }

        // Parse Targets
        var sheetTargets = excel.tables['Hedefler'];
        if (sheetTargets != null) {
          print("'Hedefler' sayfası bulundu. Satır sayısı: ${sheetTargets.maxRows}");
          for (int i = 1; i < sheetTargets.maxRows; i++) {
            var row = sheetTargets.rows[i];
            if (row.length >= 7 && row[0]?.value != null) {
              importedTargets.add(FinancialTarget(
                companyId: row[0]?.value.toString() ?? '',
                year: int.tryParse(row[1]?.value.toString() ?? '') ?? 2026,
                sales: double.tryParse(row[2]?.value.toString() ?? ''),
                salesGrowth: double.tryParse(row[3]?.value.toString() ?? ''),
                ebitda: double.tryParse(row[4]?.value.toString() ?? ''),
                ebitdaGrowth: double.tryParse(row[5]?.value.toString() ?? ''),
                ebitdaMargin: double.tryParse(row[6]?.value.toString() ?? ''),
              ));
            }
          }
        }

        // Parse Actuals
        var sheetActuals = excel.tables['Gerceklesenler'];
        if (sheetActuals != null) {
          print("'Gerceklesenler' sayfası bulundu. Satır sayısı: ${sheetActuals.maxRows}");
          for (int i = 1; i < sheetActuals.maxRows; i++) {
            var row = sheetActuals.rows[i];
            if (row.length >= 6 && row[0]?.value != null) {
              importedActuals.add(QuarterlyActual(
                companyId: row[0]?.value.toString() ?? '',
                year: int.tryParse(row[1]?.value.toString() ?? '') ?? 2026,
                quarter: int.tryParse(row[2]?.value.toString() ?? '') ?? 1,
                sales: double.tryParse(row[3]?.value.toString() ?? '') ?? 0,
                ebitda: double.tryParse(row[4]?.value.toString() ?? '') ?? 0,
                investment: double.tryParse(row[5]?.value.toString() ?? ''),
                addedBy: row.length >= 7 ? row[6]?.value.toString() : null,
              ));
            }
          }
        }

        print("Yükleme Başarılı! Şirket: ${importedCompanies.length}, Hedef: ${importedTargets.length}, Gerçekleşen: ${importedActuals.length}");
        return {
          'companies': importedCompanies,
          'targets': importedTargets,
          'actuals': importedActuals,
        };
      } else {
        print("Dosya seçimi iptal edildi.");
      }
    } catch (e) {
      print("Excel Import Hatası: $e");
    }
    return null;
  }
}
