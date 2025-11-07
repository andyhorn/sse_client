import 'dart:async';
import 'dart:convert';

import 'package:simple_sse/sse_client.dart';

void main() {
  late final StreamSubscription subscription;
  final client = SseClient();
  final uri = Uri.parse(
    'https://sse.dev/test?jsonobj={"name":"werner","age":38}',
  );

  var count = 0;
  subscription = client
      .connect(uri)
      .listen(
        (event) {
          count++;
          print('Received event: $event');
          print('Event data: ${event.data}');
          print(jsonDecode(event.data));

          if (count == 5) {
            print('Received 5 events, closing connection.');
            // Note: In a real application, you would need to manage the subscription
            // to cancel it properly. This is just a simplified example.
            subscription.cancel();
          }
        },
        onError: (error) {
          print('Error: $error');
        },
        onDone: () {
          print('Connection closed.');
        },
      );
}
