import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:intl/intl.dart';


class AnimationHome extends StatefulWidget {
  @override
  _AnimationHomeState createState() => _AnimationHomeState();
}

class _AnimationHomeState extends State<AnimationHome> {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseVideoService _videoService = FirebaseVideoService();
  Timer? _timer;
  bool _processing = false;
  String _status = "Waiting for requests...";

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _checkAndProcessRequests());
  }

  Future<void> _checkAndProcessRequests() async {
    if (_processing) return;
    _processing = true;

    try {
      final requestRef = _db.ref('Request');
      final snapshot = await requestRef.get();

      if (!snapshot.exists) {
        setState(() => _status = "No requests found.");
        _processing = false;
        return;
      }

      final Map data = snapshot.value as Map;
      setState(() => _status = "Found ${data.length} request(s). Processing...");

      for (final entry in data.entries) {
        final reqKey = entry.key;
        final reqValue = entry.value as Map;

        final imageUrl = reqValue['Image_url'] ?? '';
        final audioUrl = reqValue['Audio_url'] ?? '';
        final templateId = reqValue['Template_id'] ?? '';
        final email = reqValue['Email'] ?? '';

        if (imageUrl.isEmpty || audioUrl.isEmpty || templateId.isEmpty || email.isEmpty) {
          print("⚠️ Skipping invalid request: $reqKey");
          continue;
        }

        final apiUrl =
            "http://127.0.0.1:8000/process?image_url=$imageUrl&animation=$templateId&audio_url=$audioUrl";
        print("🎯 Hitting API for $reqKey → $apiUrl");

        try {
          final response = await http.get(Uri.parse(apiUrl));

          if (response.statusCode == 200) {
            String body = response.body.trim();

            // Extract only .mp4 URL from API response
            String videoUrl = body;
            if (body.contains(".mp4")) {
              final regex = RegExp(r'(https?://[^\s"]+\.mp4)');
              final match = regex.firstMatch(body);
              if (match != null) {
                videoUrl = match.group(0)!;
              }
            }

            await _videoService.saveVideoToUserData(email, templateId, videoUrl);
            await requestRef.child(reqKey).remove();
            print("✅ Processed and removed $reqKey");
          } else {
            print("❌ API error for $reqKey: ${response.statusCode}");
          }
        } catch (e) {
          print("❌ API call failed for $reqKey: $e");
        }
      }

      setState(() => _status = "All requests processed ✅");
    } catch (e) {
      print("❌ Error: $e");
      setState(() => _status = "Error processing requests: $e");
    }

    _processing = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestService = FirebaseRequestService();

    return Scaffold(
      appBar: AppBar(
        title: Text("🤖 Auto Animation Processor"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.sync, size: 100, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text(
                "Auto-checking Firebase every 5 seconds...",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
              SizedBox(height: 30),

              // 🌈 Real-time Request List
              requestService.buildRequestList(),
            ],
          ),
        ),
      ),
    );
  }
}




class RequestModel {
  final String date;
  final String email;
  final String imageUrl;
  final String templateId;
  final String audiourl;

  RequestModel({
    required this.date,
    required this.email,
    required this.imageUrl,
    required this.templateId,
    required this.audiourl,
  });

  factory RequestModel.fromMap(Map<dynamic, dynamic> map) {
    return RequestModel(
      date: map['Date'] ?? '',
      email: map['Email'] ?? '',
      imageUrl: map['Image_url'] ?? '',
      templateId: map['Template_id'] ?? '',
      audiourl: map['Audio_url'] ?? '',
    );
  }
}

class FirebaseRequestService {
  final DatabaseReference _requestRef =
  FirebaseDatabase.instance.ref('Request');

  Stream<List<RequestModel>> getRequestsStream() {
    return _requestRef.onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((entry) {
        final value = entry.value as Map;
        return RequestModel.fromMap(value);
      }).toList();
    });
  }

  Widget buildRequestList() {
    return StreamBuilder<List<RequestModel>>(
      stream: getRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(child: Text("No Requests Found"));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📋 Recent Requests:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.purple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.animation, color: Colors.white),
                    ),
                    title: Text(
                      req.templateId,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.calendar_today, req.date),
                        _infoRow(Icons.person, req.email),
                        _infoRow(Icons.image, req.imageUrl),
                        _infoRow(Icons.audiotrack,
                            req.audiourl.isNotEmpty ? req.audiourl : "No Audio"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- FirebaseVideoService (paste at bottom of the same file) ----------
class FirebaseVideoService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> saveVideoToUserData(
      String email, String templateId, String videoUrl) async {
    final userRef = _db.ref('User_Data');
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      print("⚠️ No user data found.");
      return;
    }

    final Map userData = snapshot.value as Map;
    String? userKey;

    userData.forEach((key, value) {
      if (value is Map && value['Email'] == email) {
        userKey = key;
      }
    });

    if (userKey == null) {
      print("❌ User not found for email: $email");
      return;
    }

    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final videoRef = userRef.child("$userKey/Video");
    final userVideos = await videoRef.get();
    final nextIndex = (userVideos.exists) ? userVideos.children.length + 1 : 1;
    final videoKey = "V$nextIndex";

    final videoData = {
      "Date": now,
      "Template_id": templateId,
      "Title": "$templateId video generated",
      "Video_url": videoUrl,
    };

    await videoRef.child(videoKey).set(videoData);
    print("🎥 Saved $videoKey for user $userKey");
  }
}
