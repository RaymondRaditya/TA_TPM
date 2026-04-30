import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kesanController = TextEditingController();
  final _saranController = TextEditingController();

  void _submitFeedback() {
    // Validate the form before proceeding
    if (_formKey.currentState!.validate()) {
      // Hide keyboard to prevent it from staying open
      FocusScope.of(context).unfocus();

      // Clear the form fields for the next submission
      _kesanController.clear();
      _saranController.clear();

      // Show a success message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Saran & Kesan Mata Kuliah TPM',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _kesanController,
              decoration: const InputDecoration(
                labelText: 'Kesan (Impressions)',
                hintText: 'What did you like about the course?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter your impressions.'
                  : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _saranController,
              decoration: const InputDecoration(
                labelText: 'Saran (Suggestions)',
                hintText: 'What could be improved?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter your suggestions.'
                  : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
