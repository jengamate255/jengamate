import 'package:flutter/material.dart';
import 'package:jengamate/models/email_template.dart';
import 'package:jengamate/services/email_service.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/tokens/typography.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';

class EditEmailTemplateScreen extends StatefulWidget {
  final EmailTemplate template;

  const EditEmailTemplateScreen({Key? key, required this.template}) : super(key: key);

  @override
  State<EditEmailTemplateScreen> createState() => _EditEmailTemplateScreenState();
}

class _EditEmailTemplateScreenState extends State<EditEmailTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _subjectController = TextEditingController(text: widget.template.subject);
    _bodyController = TextEditingController(text: widget.template.body);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _updateTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final emailService = Provider.of<EmailService>(context, listen: false);
      final updatedTemplate = widget.template.copyWith(
        name: _nameController.text,
        subject: _subjectController.text,
        body: _bodyController.text,
        updatedAt: DateTime.now(),
      );

      await emailService.updateEmailTemplate(updatedTemplate);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Email template updated successfully!')),
      );
      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating template: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.template.name}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a template name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                controller: _bodyController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a body for the email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: JMSpacing.lg),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updateTemplate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: JMSpacing.lg, vertical: JMSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(JMSpacing.sm),
                        ),
                      ),
                      child: Text(
                        'Update Template',
                        style: JMTypography.button.copyWith(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
