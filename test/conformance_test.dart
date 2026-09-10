import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:malipopay/malipopay.dart';
import 'package:test/test.dart';

/// Runs the cross-SDK behaviour scenarios in `malipopay-sdk-tests/scenarios/`.
///
/// The scenarios are the contract every Malipopay SDK is measured against.
/// This asserts the Dart SDK puts the method, path and body on the wire that
/// each scenario declares, and that it decodes the declared response shape.
/// It uses a mock transport, so it is offline and deterministic: it checks
/// this SDK against the contract, not the live API against it.
///
/// Point it elsewhere with `--define=SCENARIOS=/path/to/scenarios`.
void main() {
  final dir = Directory(
    const String.fromEnvironment(
      'SCENARIOS',
      defaultValue: '../malipopay-sdk-tests/scenarios',
    ),
  );

  if (!dir.existsSync()) {
    // Not a failure: the conformance repo is a sibling checkout that a CI
    // runner or a fresh clone will not have.
    test('conformance scenarios', () {
      printOnFailure('No scenarios at ${dir.path}');
    }, skip: 'malipopay-sdk-tests not checked out beside this repo');
    return;
  }

  /// Maps a scenario to the SDK call that is supposed to produce it.
  ///
  /// A scenario with no entry here is reported rather than skipped silently:
  /// an unmapped scenario means the SDK has no binding for a documented
  /// endpoint, which is exactly what this test exists to surface.
  Future<void> Function(Malipopay)? invoke(Map<String, dynamic> s) {
    final body = (s['request_body'] as Map?)?.cast<String, dynamic>() ?? {};
    final pathParams =
        (s['path_params'] as Map?)?.cast<String, dynamic>() ?? {};
    final query = (s['query_params'] as Map?)?.cast<String, dynamic>();
    final ref = pathParams['reference']?.toString() ?? 'REF';
    final id = pathParams['id']?.toString() ??
        pathParams['customer_id']?.toString() ??
        pathParams['invoiceId']?.toString() ??
        pathParams['productId']?.toString() ??
        'ID';

    switch ('${s['method']} ${s['path']}') {
      case 'POST /api/v1/payment/collection':
        return (c) => c.payments.collect(body);
      case 'POST /api/v1/payment/disbursement':
        return (c) => c.payments.disburse(body);
      case 'POST /api/v1/payment':
        return (c) => c.payments.initiate(body);
      case 'GET /api/v1/payment/verify/{reference}':
        return (c) => c.payments.verify(ref);
      case 'GET /api/v1/payment/reference/{reference}':
        return (c) => c.payments.get(ref);
      case 'GET /api/v1/payment':
        return (c) => c.payments.list(params: query);
      case 'GET /api/v1/payment/search':
        return (c) => c.payments.search(query ?? {});
      case 'POST /api/v1/payment/link':
        return (c) => c.payments.createLink(body);
      case 'POST /api/v1/customer':
        return (c) => c.customers.create(body);
      case 'GET /api/v1/customer':
        return (c) => c.customers.list(params: query);
      case 'GET /api/v1/customer/{id}':
      case 'GET /api/v1/customer/{customer_id}':
        return (c) => c.customers.get(id);
      case 'GET /api/v1/customer/search':
        return (c) => c.customers.search(query ?? {});
      case 'POST /api/v1/customer/verify':
        return (c) => c.customers.verify(body['phoneNumber'].toString());
      case 'POST /api/v1/invoice':
        return (c) => c.invoices.create(body);
      case 'GET /api/v1/invoice':
        return (c) => c.invoices.list(params: query);
      case 'GET /api/v1/invoice/{id}':
      case 'GET /api/v1/invoice/{invoiceId}':
        return (c) => c.invoices.get(id);
      case 'POST /api/v1/invoice/record-payment':
        return (c) => c.invoices.recordPayment(body);
      case 'POST /api/v1/product':
        return (c) => c.products.create(body);
      case 'GET /api/v1/product':
        return (c) => c.products.list(params: query);
      case 'GET /api/v1/product/{id}':
      case 'GET /api/v1/product/{productId}':
        return (c) => c.products.get(id);
      case 'POST /sms/':
        return (c) => c.sms.send(body);
      case 'POST /sms/bulk':
        return (c) => c.sms.sendBulk(body);
      case 'POST /sms/schedule':
        return (c) => c.sms.schedule(body);
      case 'GET /api/v1/standard/banks':
        return (c) => c.references.banks();
      case 'GET /api/v1/standard/currency':
        return (c) => c.references.currencies();
      case 'GET /api/v1/standard/countries':
        return (c) => c.references.countries();
      case 'GET /api/v1/standard/institutions':
        return (c) => c.references.institutions();
      default:
        return null;
    }
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final unmapped = <String>[];

  for (final file in files) {
    final group_ = file.uri.pathSegments.last.replaceAll('.json', '');
    final scenarios = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

    group('conformance: $group_', () {
      for (final s in scenarios) {
        final call = invoke(s);
        if (call == null) {
          unmapped.add('$group_/${s['name']} (${s['method']} ${s['path']})');
          continue;
        }

        test('${s['name']}: ${s['description']}', () async {
          http.BaseRequest? sent;
          String? sentBody;

          final client = Malipopay(
            'test-key',
            environment: MalipopayEnvironment.uat,
            httpClient: MockClient((request) async {
              sent = request;
              sentBody = request.body;
              return http.Response(
                jsonEncode(s['expected_response']),
                s['expected_status'] as int? ?? 200,
                headers: {'content-type': 'application/json'},
              );
            }),
          );

          final status = s['expected_status'] as int? ?? 200;
          if (status >= 400) {
            // The scenario documents a failure. The contract is that the SDK
            // raises a typed exception rather than returning a body.
            await expectLater(call(client), throwsA(isA<MalipopayException>()));
          } else {
            await call(client);
          }

          expect(sent, isNotNull, reason: 'the SDK made no request');
          expect(sent!.method, s['method']);

          // The scenario path carries {placeholders}; compare the literal
          // segments so a substitution mismatch still fails loudly.
          final expected = (s['path'] as String).split('/');
          final actual = sent!.url.path.split('/');
          expect(actual, hasLength(expected.length),
              reason: 'path shape differs: ${sent!.url.path} vs ${s['path']}');
          for (var i = 0; i < expected.length; i++) {
            if (expected[i].startsWith('{')) continue;
            expect(actual[i], expected[i],
                reason: 'segment $i of ${sent!.url.path}');
          }

          final wanted = s['request_body'];
          if (wanted is Map && wanted.isNotEmpty) {
            final actualBody = jsonDecode(sentBody!) as Map<String, dynamic>;
            for (final entry in wanted.entries) {
              expect(actualBody[entry.key], entry.value,
                  reason: 'request body field ${entry.key}');
            }
          }
        });
      }
    });
  }

  test('every scenario has an SDK binding', () {
    expect(
      unmapped,
      isEmpty,
      reason: 'These documented endpoints have no method on the Dart SDK:\n'
          '${unmapped.join('\n')}',
    );
  });
}
