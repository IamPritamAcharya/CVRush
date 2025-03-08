import 'package:flutter/material.dart';
import 'package:horz/pages/cvMaker/community/communityDetailPage.dart';
import 'package:horz/pages/cvMaker/community/communities_data.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Popular Communities",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 130,
          child: communities.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
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
                        width: 100, // Set fixed width to prevent overflow
                        margin: EdgeInsets.only(right: 16),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage:
                                  NetworkImage(community['logo_url']),
                            ),
                            SizedBox(height: 6),
                            SizedBox(
                              width:
                                  80, // Constrain text width to avoid overflow
                              child: Text(
                                community['name'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis, // Prevent overflow
                                softWrap: true,
                              ),
                            ),
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
