import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'model/component_type.dart';
import 'model/output_template.dart';
import 'model/template_component.dart';

/// Built-in starter templates with stable ids so re-seeding is idempotent.
abstract final class SampleTemplates {
  static const defaultId = 'tpl-barcode-enter';

  static List<OutputTemplate> all() => [barcodeEnter(), posLookup(), inventoryIntake(), stocktake()];

  static OutputTemplate _t(String id, String name, String description, List<TemplateComponent> components) {
    final now = nowUtc();
    return OutputTemplate(
      id: id,
      name: name,
      description: description,
      version: 1,
      components: components,
      createdAt: now,
      updatedAt: now,
    );
  }

  static TemplateComponent _c(String id, ComponentType type, [Map<String, Object?> config = const {}, String label = '']) =>
      TemplateComponent(id: id, typeId: type.id, config: config, label: label);

  static OutputTemplate barcodeEnter() => _t(defaultId, 'Barcode + Enter', 'Types the code and presses Enter.', [
    _c('bc', ComponentType.barcode),
    _c('en', ComponentType.enter),
  ]);

  static OutputTemplate posLookup() => _t('tpl-pos-lookup', 'POS Lookup', 'Barcode, optional quantity, Enter.', [
    _c('bc', ComponentType.barcode),
    _c('qty', ComponentType.number, {'name': 'qty', 'default': '1', 'min': 1}, 'Quantity'),
    _c('if1', ComponentType.ifStart, {'left': '{{qty}}', 'op': 'gt', 'right': '1'}),
    _c('tb', ComponentType.tab),
    _c('qtyOut', ComponentType.text, {'text': '{{qty}}'}),
    _c('end1', ComponentType.ifEnd),
    _c('en', ComponentType.enter),
  ]);

  static OutputTemplate inventoryIntake() => _t('tpl-inventory-intake', 'Inventory Intake',
      'Barcode, quantity, condition and timestamp; types a row and appends to CSV.', [
    _c('bc', ComponentType.barcode),
    _c('t1', ComponentType.tab),
    _c('qty', ComponentType.number, {'name': 'qty', 'default': '1', 'min': 0, 'required': true}, 'Quantity'),
    _c('t2', ComponentType.tab),
    _c('cond', ComponentType.selectOption, {'name': 'condition', 'options': ['New', 'Used', 'Damaged'], 'default': 'New'}, 'Condition'),
    _c('t3', ComponentType.tab),
    _c('ts', ComponentType.dateTime, {'name': 'time', 'format': 'yyyy-MM-dd HH:mm:ss', 'source': 'scan'}),
    _c('en', ComponentType.enter),
    _c('csv', ComponentType.csvOutput, {
      'path': 'inventory_intake.csv',
      'header': ['barcode', 'quantity', 'condition', 'time'],
      'columns': ['{{barcode}}', '{{qty}}', '{{condition}}', '{{time}}'],
    }),
  ]);

  static OutputTemplate stocktake() => _t('tpl-stocktake', 'Stocktake', 'Barcode, counted quantity and bin; CSV only.', [
    _c('bc', ComponentType.barcode),
    _c('qty', ComponentType.number, {'name': 'qty', 'default': '1', 'min': 0}, 'Counted'),
    _c('bin', ComponentType.text, {'name': 'bin', 'ask': true, 'default': 'A-01'}, 'Warehouse / bin'),
    _c('ts', ComponentType.timestamp, {'name': 'ts', 'format': 'iso'}),
    _c('skip', ComponentType.skipOutput),
    _c('csv', ComponentType.csvOutput, {
      'path': 'stocktake.csv',
      'header': ['barcode', 'quantity', 'bin', 'timestamp'],
      'columns': ['{{barcode}}', '{{qty}}', '{{bin}}', '{{ts}}'],
    }),
  ]);
}
