import 'package:flutter/material.dart';
import 'chat_page.dart';

class NotePage extends StatelessWidget {
  const NotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤱 ASK MOMTEEN'),
        backgroundColor: Colors.pink,
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Shelf Guide:",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Vitamins:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("  • Folic Acid", style: TextStyle(fontSize: 18)),
            Text("  • Vitamin D", style: TextStyle(fontSize: 18)),
            Text("  • Multivitamins", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              "Birth Control:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("  • Pills", style: TextStyle(fontSize: 18)),
            Text("  • Condoms", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              "Pregnancy Care:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("  • Iron Supplements", style: TextStyle(fontSize: 18)),
            Text("  • Mosquito Nets", style: TextStyle(fontSize: 18)),
            Text("  • Avocado (prenatal food)", style: TextStyle(fontSize: 18)),
            SizedBox(height: 40),
            Text(
              "Drag items to correct shelves!",
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/chat');
        },
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text(
          "ASK MOMTEEN",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
