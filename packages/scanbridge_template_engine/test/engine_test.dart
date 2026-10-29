import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:test/test.dart';

ExecutionContext _ctx({String barcode = '000123', Map<String, String> values = const {}, Map<String, int> counters = const {}}) =>
    ExecutionContext(
      barcode: barcode,
      quantity: '1',
      capturedAt: DateTime.utc(2026, 10, 29, 8, 30),
      sessionName: 'Shelf A',
      deviceName: 'Phone',
      now: DateTime.utc(2026, 10, 29, 9),
      values: values,
      counters: counters,
    );

OutputTemplate _tpl(List<TemplateComponent> c) => OutputTemplate(
  id: 't',
  name: 'T',
  version: 1,
  components: c,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

TemplateComponent _c(String id, ComponentType t, [Map<String, Object?> config = const {}]) =>
    TemplateComponent(id: id, typeId: t.id, config: config);

void main() {
  const engine = TemplateEngine();

  test('barcode + enter types value then Enter', () async {
    final r = await engine.run(SampleTemplates.barcodeEnter(), _ctx());
    expect(r.typedText, '000123\n');
    expect(r.actions.last, isA<KeyPressAction>());
  });

  test('IF branches on numeric comparison and nests', () async {
    final t = _tpl([
      _c('q', ComponentType.number, {'name': 'qty'}),
      _c('i', ComponentType.ifStart, {'left': '{{qty}}', 'op': 'gt', 'right': '1'}),
      _c('x', ComponentType.text, {'text': 'MANY'}),
      _c('i2', ComponentType.ifStart, {'left': '{{qty}}', 'op': 'gt', 'right': '10'}),
      _c('y', ComponentType.text, {'text': '!'}),
      _c('e2', ComponentType.ifEnd),
      _c('e', ComponentType.ifEnd),
    ]);
    expect((await engine.run(t, _ctx(values: {'q': '5'}))).typedText, '5MANY');
    expect((await engine.run(t, _ctx(values: {'q': '20'}))).typedText, '20MANY!');
    expect((await engine.run(t, _ctx(values: {'q': '1'}))).typedText, '1');
  });

  test('NUMBER validation failure stops with typed failure', () async {
    final t = _tpl([_c('q', ComponentType.number, {'min': 1, 'max': 5})]);
    final r = await engine.run(t, _ctx(values: {'q': '9'}));
    expect(r.ok, isFalse);
    expect(r.failure!.code, FailureCode.templateValidationFailure);
    expect(r.actions, isEmpty);
  });

  test('SELECT_OPTION rejects values outside options', () async {
    final t = _tpl([_c('s', ComponentType.selectOption, {'options': ['A', 'B']})]);
    expect((await engine.run(t, _ctx(values: {'s': 'B'}))).typedText, 'B');
    expect((await engine.run(t, _ctx(values: {'s': 'Z'}))).ok, isFalse);
  });

  test('CONFIRM declined halts with no output', () async {
    final t = _tpl([_c('b', ComponentType.barcode), _c('c', ComponentType.confirm)]);
    final r = await engine.run(t, _ctx(values: {'c': 'no'}));
    expect(r.halted, isTrue);
    expect(r.actions, isEmpty);
  });

  test('SKIP_OUTPUT drops keyboard actions but keeps file output', () async {
    final r = await engine.run(SampleTemplates.stocktake(), _ctx(values: {'qty': '3', 'bin': 'B-2'}));
    expect(r.actions.whereType<TypeTextAction>(), isEmpty);
    final file = r.actions.whereType<FileAppendAction>().single;
    expect(file.cells, ['000123', '3', 'B-2', '2026-10-29T08:30:00.000Z']);
  });

  test('INCREMENT uses and returns counters; UUID and TIMESTAMP', () async {
    final t = _tpl([
      _c('n', ComponentType.increment, {'counter': 'c', 'pad': 3}),
      _c('ts', ComponentType.timestamp, {'format': 'unix'}),
    ]);
    final first = await engine.run(t, _ctx());
    expect(first.typedText, startsWith('001'));
    final second = await engine.run(t, _ctx(counters: first.counters));
    expect(second.typedText, startsWith('002'));
    expect(second.typedText, endsWith('${DateTime.utc(2026, 10, 29, 8, 30).millisecondsSinceEpoch ~/ 1000}'));
  });

  test('variables from earlier components and built-ins interpolate', () async {
    final t = _tpl([
      _c('a', ComponentType.text, {'name': 'loc', 'text': 'BIN7'}),
      _c('b', ComponentType.text, {'text': '{{session.name}}|{{device.name}}|{{loc}}|{{barcode}}'}),
    ]);
    expect((await engine.run(t, _ctx())).typedText, 'BIN7Shelf A|Phone|BIN7|000123');
  });

  test('unknown and unavailable components are preserved and skipped', () async {
    final parsed = OutputTemplate.tryParse('{"schemaVersion":1,"name":"X","components":['
        '{"id":"a","type":"FUTURE_THING","config":{"k":1}},'
        '{"id":"b","type":"HTTP_REQUEST"},'
        '{"id":"c","type":"BARCODE"}]}');
    final t = parsed.valueOrNull!;
    expect(t.components.first.enabled, isFalse);
    expect(t.toJson()['components'], hasLength(3));
    final r = await engine.run(t, _ctx());
    expect(r.typedText, '000123');
    expect(engine.lint(t), hasLength(2));
  });

  test('malformed template import names the failing field', () {
    final r = OutputTemplate.tryParse('{"schemaVersion":1,"name":"X","components":[{"id":"","type":"TEXT"}]}');
    expect(r.failureOrNull!.message, contains('components[0].id'));
    expect(OutputTemplate.tryParse('[1]').isOk, isFalse);
    expect(OutputTemplate.tryParse('{"schemaVersion":99,"name":"X","components":[]}').failureOrNull!.message,
        contains('schemaVersion'));
  });

  test('delay is clamped per step and bounded in total', () async {
    final big = _tpl([for (var i = 0; i < 7; i++) _c('d$i', ComponentType.delay, {'ms': 999999})]);
    final r = await engine.run(big, _ctx());
    expect(r.ok, isFalse);
    final one = await engine.run(_tpl([_c('d', ComponentType.delay, {'ms': 999999})]), _ctx());
    expect((one.actions.single as DelayAction).duration, const Duration(seconds: 10));
  });

  test('sample templates are lint-clean and json round-trips', () {
    for (final t in SampleTemplates.all()) {
      expect(engine.lint(t), isEmpty, reason: t.name);
      final back = OutputTemplate.tryParse(t.toPrettyJson()).valueOrNull!;
      expect(back.components.length, t.components.length);
    }
  });
}
