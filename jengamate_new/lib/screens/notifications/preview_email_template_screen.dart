import 'package:flutter/material.dart';
import 'package:jengamate/models/email_template.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/tokens/typography.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PreviewEmailTemplateScreen extends StatelessWidget {
  final EmailTemplate template;

  const PreviewEmailTemplateScreen({Key? key, required this.template}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${template.name}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(JMSpacing.md),
            child: Text(
              'Subject: ${template.subject}',
              style: JMTypography.bodyStrong.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          Expanded(
            child: WebViewWidget(
              controller: WebViewController()
                ..loadHtmlString(template.body)
                ..setJavaScriptMode(JavaScriptMode.unrestricted),
            ),
          ),
        ],
      ),
    );
  }
}
