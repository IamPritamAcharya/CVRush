import 'package:flutter/material.dart';

class Job {
  final String id;
  final List<String> showcase;
  final List<String> carousel;
  final String rate;
  final String company;
  final String logoUrl;
  final String bgColor;
  final String description;
  final DateTime datePosted;
  final String jobType;
  final bool startup;
  final bool remote;
  final String location;
  final String stipend;
  final int percentile;
  final int chance; // New field

  Job({
    required this.id,
    required this.showcase,
    required this.carousel,
    required this.rate,
    required this.company,
    required this.logoUrl,
    required this.bgColor,
    required this.description,
    required this.datePosted,
    required this.jobType,
    required this.startup,
    required this.remote,
    required this.location,
    required this.stipend,
    required this.percentile,
    required this.chance, // Initialize new field
  });

  /// Factory constructor for JSON conversion
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? json['uuid'] ?? '',
      showcase: List<String>.from(json['showcase'] ?? []),
      carousel: List<String>.from(json['carousel'] ?? []),
      rate: json['rate']?.toString() ?? 'N/A',
      company: json['company'] ?? 'Unknown',
      logoUrl: json['logoUrl'] ?? '',
      bgColor: json['bgColor'] ?? '#FFFFFF',
      description: json['description'] ?? 'No description available',
      datePosted: json['datePosted'] != null
          ? DateTime.tryParse(json['datePosted']) ?? DateTime.now()
          : DateTime.now(),
      jobType: json['jobType'] ?? 'Unknown',
      startup: json['startup'] ?? false,
      remote: json['remote'] ?? false,
      location: json['location'] ?? 'Unknown',
      stipend: json['stipend']?.toString() ?? 'N/A',
      percentile: json['percentile'] ?? 0,
      chance: json['chance'] ?? 30, // Default value for chance
    );
  }

  /// Converts the bgColor string (hex) to a Flutter Color object
  Color getBackgroundColor() {
    try {
      String hex = bgColor.trim().toUpperCase();
      if (hex.startsWith("#")) hex = hex.substring(1);
      if (hex.startsWith("0X")) hex = hex.substring(2);
      if (hex.length == 6) hex = "FF$hex"; // Ensure ARGB format
      return Color(int.parse("0x$hex"));
    } catch (e) {
      debugPrint("Error parsing bgColor: $bgColor");
      return Colors.white; // Default color on error
    }
  }

  /// Convert Job to JSON (for uploading to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'showcase': showcase,
      'carousel': carousel,
      'rate': rate,
      'company': company,
      'logoUrl': logoUrl,
      'bgColor': bgColor,
      'description': description,
      'datePosted': datePosted.toIso8601String(),
      'jobType': jobType,
      'startup': startup,
      'remote': remote,
      'location': location,
      'stipend': stipend,
      'percentile': percentile,
      'chance': chance, // Include new field
    };
  }
}
