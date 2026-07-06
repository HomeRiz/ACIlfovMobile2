import 'package:flutter/material.dart';

class DeleteAccountView extends StatelessWidget {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmare',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF335C80)),
                ),
                SizedBox(height: 12),
                Text(
                  'Sunteti sigur ca doriti sa stergeti contul? Aceasta operatie va sterge toate datele legate de acest cont din portal!',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stergerea contului nu este activata in aplicatia mobila.')),
                ),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Da'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Nu'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
