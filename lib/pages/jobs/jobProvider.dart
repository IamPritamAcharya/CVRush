import 'package:supabase_flutter/supabase_flutter.dart';
import 'jobmodel.dart';

class JobProvider {
  final supabase = Supabase.instance.client;

  List<Job> jobs = [];

  Future<void> fetchJobs() async {
    final response = await supabase.from('jobs').select('*').order('datePosted', ascending: false);

    if (response.isNotEmpty) {
      jobs = response.map((jobData) => Job.fromJson(jobData)).toList();
    }
  }
}

final jobProvider = JobProvider();
