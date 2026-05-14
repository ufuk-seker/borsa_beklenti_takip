import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../data/models/company.dart';
import '../../data/models/quarterly_actual.dart';
import '../providers/borsa_provider.dart';
import 'package:provider/provider.dart';

class ActualEntryForm extends StatefulWidget {
  final Company company;
  final QuarterlyActual? existingActual;

  const ActualEntryForm({super.key, required this.company, this.existingActual});

  @override
  State<ActualEntryForm> createState() => _ActualEntryFormState();
}

class _ActualEntryFormState extends State<ActualEntryForm> {
  final _salesController = TextEditingController();
  final _ebitdaController = TextEditingController();
  final _investmentController = TextEditingController();
  final _addedByController = TextEditingController();
  late int _selectedQuarter;

  @override
  void initState() {
    super.initState();
    if (widget.existingActual != null) {
      _salesController.text = widget.existingActual!.sales.toStringAsFixed(0);
      _ebitdaController.text = widget.existingActual!.ebitda.toStringAsFixed(0);
      _investmentController.text = widget.existingActual!.investment?.toStringAsFixed(0) ?? '';
      _addedByController.text = widget.existingActual!.addedBy ?? '';
    }
    _selectedQuarter = widget.existingActual?.quarter ?? 1;
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (_addedByController.text.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      if (name != null) {
        setState(() => _addedByController.text = name);
      }
    }
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.company.ticker} - Çeyreklik Veri Girişi",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Önemli: Lütfen seçilen döneme ait kümülatif (toplam) rakamları giriniz.",
                    style: TextStyle(fontSize: 12, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text("Dönem Seçimi", style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 2, 3, 4].map((q) => ChoiceChip(
              label: Text("Q$q"),
              selected: _selectedQuarter == q,
              onSelected: (val) => setState(() => _selectedQuarter = q),
            )).toList(),
          ),
          
          const SizedBox(height: 32),
          _buildField("Gerçekleşen Satış", _salesController),
          const SizedBox(height: 16),
          _buildField("Gerçekleşen FAVÖK", _ebitdaController),
          const SizedBox(height: 16),
          _buildField("Yatırım Miktarı (Opsiyonel)", _investmentController),
          const SizedBox(height: 16),
          _buildField("Girişi Yapan", _addedByController),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final provider = Provider.of<BorsaProvider>(context, listen: false);
                
                if (_addedByController.text.isNotEmpty) {
                  _saveUserName(_addedByController.text);
                }

                provider.addActual(QuarterlyActual(
                  companyId: widget.company.id,
                  year: provider.selectedYear,
                  quarter: _selectedQuarter,
                  sales: double.tryParse(_salesController.text) ?? 0,
                  ebitda: double.tryParse(_ebitdaController.text) ?? 0,
                  investment: double.tryParse(_investmentController.text),
                  addedBy: _addedByController.text,
                ));

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen, foregroundColor: Colors.black),
              child: const Text("Veriyi Kaydet", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDim)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        ),
      ],
    );
  }
}
