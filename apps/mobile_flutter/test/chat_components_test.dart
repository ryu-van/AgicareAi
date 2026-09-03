import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agricare_ai_mobile/data/api_client.dart';
import 'package:agricare_ai_mobile/widgets/chat_components.dart';

void main() {
  testWidgets('chat bubble exposes citations and urgent safety message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBubble(
            message: ChatMessage(
              text: 'Cần kiểm tra ngay.',
              isUser: false,
              safetyLevel: 'urgent',
              citations: const ['Bài viết sâu bệnh'],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cần kiểm tra ngay.'), findsOneWidget);
    expect(
      find.text('Cảnh báo khẩn cấp: hãy liên hệ chuyên gia.'),
      findsOneWidget,
    );
    expect(find.text('Nguồn: Bài viết sâu bệnh'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Nguồn tham khảo: Bài viết sâu bệnh'),
      findsOneWidget,
    );
  });
}
