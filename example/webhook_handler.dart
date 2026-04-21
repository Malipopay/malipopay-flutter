import 'dart:convert';
import 'dart:io';

import 'package:malipopay/malipopay.dart';

Future<void> main() async {
  final webhooks = Webhooks(secret: 'whsec_your_webhook_secret');

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
  print('Webhook server listening on port 3000');

  await for (final request in server) {
    if (request.method == 'POST' && request.uri.path == '/webhooks/malipopay') {
      try {
        final rawBody = await utf8.decoder.bind(request).join();
        final signature = request.headers.value('x-malipopay-signature') ?? '';

        final event = webhooks.constructEvent(rawBody, signature);

        switch (event.type) {
          case WebhookEventType.paymentCompleted:
            print('Payment completed: ${event.data['reference']}');
          case WebhookEventType.paymentFailed:
            print('Payment failed: ${event.data['reference']}');
          case WebhookEventType.disbursementCompleted:
            print('Disbursement sent: ${event.data['reference']}');
          default:
            print('Unhandled event: ${event.type}');
        }

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'received': true}));
        await request.response.close();
      } catch (e) {
        print('Webhook error: $e');
        request.response.statusCode = 400;
        request.response.write(jsonEncode({'error': e.toString()}));
        await request.response.close();
      }
    } else {
      request.response.statusCode = 404;
      await request.response.close();
    }
  }
}
