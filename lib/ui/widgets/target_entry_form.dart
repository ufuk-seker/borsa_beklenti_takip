import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/borsa_provider.dart';
import '../../core/app_theme.dart';
import '../../data/models/company.dart';
import '../../data/models/financial_target.dart';

class TargetEntryForm extends StatefulWidget {
  final Company company;
  final FinancialTarget? existingTarget;
  final Map<String, double> previousYearData; // e.g. {'sales': 1000, 'ebitda': 200}

  const TargetEntryForm({
    super.key, 
    required this.company, 
    this.existingTarget,
    this.previousYearData = const {},
  });

  @override
  State<TargetEntryForm> createState() => _TargetEntryFormState();
}

class _TargetEntryFormState extends State<TargetEntryForm> {
  final _salesController = TextEditingController();
  final _salesGrowthController = TextEditingController();
  final _ebitdaController = TextEditingController();
  final _ebitdaMarginController = TextEditingController();
  final _investmentController = TextEditingController();
  final _notesController = TextEditingController();
  final _tickerController = TextEditingController();
  final _nameController = TextEditingController();
  final _sectorController = TextEditingController();
  String? _tickerError;
  final _ebitdaGrowthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingTarget != null) {
      _salesController.text = widget.existingTarget!.sales?.toString() ?? "";
      _salesGrowthController.text = widget.existingTarget!.salesGrowth?.toString() ?? "";
      _ebitdaController.text = widget.existingTarget!.ebitda?.toString() ?? "";
      _ebitdaMarginController.text = widget.existingTarget!.ebitdaMargin?.toString() ?? "";
      _ebitdaGrowthController.text = widget.existingTarget!.ebitdaGrowth?.toString() ?? "";
      _investmentController.text = widget.existingTarget!.investment?.toString() ?? "";
      _notesController.text = widget.existingTarget!.notes ?? "";
    }
  }

  void _onSalesChanged(String value) {
    final sales = double.tryParse(value);
    final prevSales = widget.previousYearData['sales'];
    if (sales != null && prevSales != null && prevSales != 0) {
      final growth = ((sales / prevSales) - 1) * 100;
      _salesGrowthController.text = growth.toStringAsFixed(1);
    }
    _recalculateMargin(); // Recalculate margin if sales change
  }

  void _onSalesGrowthChanged(String value) {
    final growth = double.tryParse(value);
    final prevSales = widget.previousYearData['sales'];
    if (growth != null && prevSales != null) {
      final sales = prevSales * (1 + growth / 100);
      _salesController.text = sales.toStringAsFixed(0);
    }
    _recalculateMargin();
  }

  void _onEbitdaChanged(String value) {
    final ebitda = double.tryParse(value);
    final prevEbitda = widget.previousYearData['ebitda'];
    if (ebitda != null && prevEbitda != null && prevEbitda != 0) {
      final growth = ((ebitda / prevEbitda) - 1) * 100;
      _ebitdaGrowthController.text = growth.toStringAsFixed(1);
    }
    _recalculateMargin();
  }

  void _onEbitdaGrowthChanged(String value) {
    final growth = double.tryParse(value);
    final prevEbitda = widget.previousYearData['ebitda'];
    if (growth != null && prevEbitda != null) {
      final ebitda = prevEbitda * (1 + growth / 100);
      _ebitdaController.text = ebitda.toStringAsFixed(0);
    }
    _recalculateMargin();
  }

  void _onMarginChanged(String value) {
    _recalculateEbitda();
  }

  void _recalculateEbitda() {
    final sales = double.tryParse(_salesController.text);
    final margin = double.tryParse(_ebitdaMarginController.text);
    if (sales != null && margin != null) {
      final ebitda = sales * (margin / 100);
      _ebitdaController.text = ebitda.toStringAsFixed(0);
      
      // Update growth too
      final prevEbitda = widget.previousYearData['ebitda'];
      if (prevEbitda != null && prevEbitda != 0) {
        final growth = ((ebitda / prevEbitda) - 1) * 100;
        _ebitdaGrowthController.text = growth.toStringAsFixed(1);
      }
    }
  }

  void _recalculateMargin() {
    final sales = double.tryParse(_salesController.text);
    final ebitda = double.tryParse(_ebitdaController.text);
    if (sales != null && sales != 0 && ebitda != null) {
      final margin = (ebitda / sales) * 100;
      _ebitdaMarginController.text = margin.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BorsaProvider>(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.company.id == 'new' 
                ? "${provider.selectedYear} Yeni Hedef Girişi" 
                : "${widget.company.ticker} - ${provider.selectedYear} Hedef Girişi",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Eldeki verileri girin, kalanlar otomatik hesaplanacaktır.", style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            
            _buildSectionTitle("Şirket Bilgileri"),
            if (widget.company.id == 'new') ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildField("Borsa Kodu (Ticker)*", _tickerController, keyboardType: TextInputType.text, errorText: _tickerError)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField("Şirket Adı", _nameController, keyboardType: TextInputType.text)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField("Sektör", _sectorController, keyboardType: TextInputType.text),
              const SizedBox(height: 24),
            ],
            
            _buildSectionTitle("Satış Hedefleri"),
            Row(
              children: [
                Expanded(
                  child: _buildField("Yıllık Satış Hedefi", _salesController, onChanged: _onSalesChanged),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField("Satış Büyümesi (%)", _salesGrowthController, onChanged: _onSalesGrowthChanged, suffix: "%"),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle("Karlılık Hedefleri"),
            Row(
              children: [
                Expanded(
                  child: _buildField("Hedef FAVÖK", _ebitdaController, onChanged: _onEbitdaChanged),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField("FAVÖK Büyümesi (%)", _ebitdaGrowthController, onChanged: _onEbitdaGrowthChanged, suffix: "%"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField("FAVÖK Marjı (%)", _ebitdaMarginController, onChanged: _onMarginChanged, suffix: "%"),
            
            const SizedBox(height: 24),
            _buildSectionTitle("Yatırım & Notlar"),
            _buildField("Yatırım Miktarı", _investmentController),
            const SizedBox(height: 16),
            _buildField("Analist Notları", _notesController, maxLines: 3),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final provider = Provider.of<BorsaProvider>(context, listen: false);
                  if (widget.company.id == 'new') {
                    if (_tickerController.text.trim().isEmpty) {
                      setState(() => _tickerError = "Borsa kodu zorunludur!");
                      return;
                    }
                    setState(() => _tickerError = null);
                    
                    final company = Company(
                      id: '', 
                      ticker: _tickerController.text.trim().toUpperCase(),
                      name: _nameController.text.trim().isEmpty ? _tickerController.text.trim().toUpperCase() : _nameController.text.trim(),
                      sector: _sectorController.text.trim(),
                    );

                    final target = FinancialTarget(
                      companyId: '', 
                      year: provider.selectedYear,
                      sales: double.tryParse(_salesController.text),
                      salesGrowth: double.tryParse(_salesGrowthController.text),
                      ebitda: double.tryParse(_ebitdaController.text),
                      ebitdaGrowth: double.tryParse(_ebitdaGrowthController.text),
                      ebitdaMargin: double.tryParse(_ebitdaMarginController.text),
                      investment: double.tryParse(_investmentController.text),
                      notes: _notesController.text.trim(),
                    );

                    provider.addCompany(company, target);
                  } else {
                    final target = FinancialTarget(
                      companyId: widget.company.id,
                      year: provider.selectedYear,
                      sales: double.tryParse(_salesController.text),
                      salesGrowth: double.tryParse(_salesGrowthController.text),
                      ebitda: double.tryParse(_ebitdaController.text),
                      ebitdaGrowth: double.tryParse(_ebitdaGrowthController.text),
                      ebitdaMargin: double.tryParse(_ebitdaMarginController.text),
                      investment: double.tryParse(_investmentController.text),
                      notes: _notesController.text.trim(),
                    );
                    provider.updateTarget(target);
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen, foregroundColor: Colors.black),
                child: const Text("Hedefi Kaydet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {Function(String)? onChanged, String? suffix, int maxLines = 1, TextInputType keyboardType = TextInputType.number, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDim)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (val) {
            if (onChanged != null) onChanged(val);
          },
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            suffixText: suffix,
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
