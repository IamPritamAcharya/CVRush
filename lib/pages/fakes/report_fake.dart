import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportFakePage extends StatefulWidget {
  const ReportFakePage({super.key});

  @override
  State<ReportFakePage> createState() => _ReportFakePageState();
}

class _ReportFakePageState extends State<ReportFakePage> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  String _message = "";

  Future<void> _submitReport() async {
    final company = _companyController.text.trim();
    final experience = _experienceController.text.trim();
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? "Anonymous";

    if (company.isEmpty || experience.isEmpty) {
      setState(() => _message = "All fields are required.");
      return;
    }

    final existingCompany = await Supabase.instance.client
        .from('fake_internships')
        .select()
        .eq('company_name', company)
        .maybeSingle();

    if (existingCompany != null) {
      // Update existing record: increase count & add experience
      await Supabase.instance.client.from('fake_internships').update({
        'report_count': existingCompany['report_count'] + 1,
        'experiences': [...existingCompany['experiences'], experience],
        'reported_by': [...existingCompany['reported_by'], userEmail],
      }).eq('company_name', company);
      
      setState(() => _message = "Report updated! This company has been reported ${existingCompany['report_count'] + 1} times.");
    } else {
      // Insert new record
      await Supabase.instance.client.from('fake_internships').insert({
        'company_name': company,
        'experiences': [experience],
        'reported_by': [userEmail],
      });

      setState(() => _message = "Report submitted! This is the first report for this company.");
    }

    _companyController.clear();
    _experienceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Fake Internship")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _companyController, decoration: const InputDecoration(labelText: "Company Name")),
            TextField(controller: _experienceController, decoration: const InputDecoration(labelText: "Your Experience")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _submitReport, child: const Text("Submit Report")),
            Text(_message, style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
