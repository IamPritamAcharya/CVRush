import 'package:flutter/material.dart';
import 'package:horz/pages/cvMaker/community/communityDetailPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'communities_data.dart';

class CommunitiesSection extends StatefulWidget {
  @override
  _CommunitiesSectionState createState() => _CommunitiesSectionState();
}

class _CommunitiesSectionState extends State<CommunitiesSection> {
  List<Map<String, dynamic>> communities = communitiesData["communities"];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Popular Communities",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommunityDetailPage(community: community),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(community['logo_url'])),
                      SizedBox(height: 8),
                      Text(community['name'],
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
