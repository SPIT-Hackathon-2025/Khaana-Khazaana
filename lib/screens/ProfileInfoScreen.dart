import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pokemon_go/constants.dart';
import 'dart:convert';

import '../models/user_model.dart';

class ProfileUploadPage extends StatefulWidget {
  @override
  _ProfileUploadPageState createState() => _ProfileUploadPageState();
}

class _ProfileUploadPageState extends State<ProfileUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _age = '';
  String _address = '';
  Position? _currentLoc;
  String? _selectedGender;
  File? _identityFile;
  String? _identityProofUrl;
  String? _verifiedName;
  String? _identityType;
  bool _isLoading = false;

  Future<void> _pickIdentityProof() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _identityFile = File(result.files.single.path!);
      });
    }
  }

  Future<String> _uploadIdentityProof(String uid) async {
    if (_identityFile == null) return "";
    final storageRef =
        FirebaseStorage.instance.ref().child('identityProofs/$uid.pdf');
    await storageRef.putFile(_identityFile!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _sendVerificationRequest(String identityUrl) async {
    final response = await http.post(
      Uri.parse("$url/get-id"),
      body: jsonEncode({
        "url": identityUrl,
        "lat": _currentLoc!.latitude.toString(),
        "long": _currentLoc!.longitude.toString(),
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _verifiedName = data['name'];
        _identityType = data['document'];
        _age = data['dob'];
        _address = data['address'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Verification failed, try again!"),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _identityFile == null) return;

    setState(() {
      _isLoading = true;
    });

    String uid = 'FirebaseAuth.instance.currentUser!.uid';

    Position position = await determinePosition();
    setState(() {
      _currentLoc = position;
    });

    String identityUrl = await _uploadIdentityProof(uid);
    setState(() {
      _identityProofUrl = identityUrl;
    });

    // Verify the uploaded document
    await _sendVerificationRequest(identityUrl);

    // Create user model
    UserModel user = UserModel(
      uid: uid,
      name: _nameController.text,
      address: _address,
      dob: _age,
      gender: _selectedGender!,
      identityProofUrl: identityUrl,
      identityType: _identityType ?? "Unknown",
      verifiedName: _verifiedName ?? "Unknown",
    );

    // Store in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(user.toMap());

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Profile Uploaded Successfully!"),
          backgroundColor: Colors.green),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Extend body behind app bar to show the full gradient background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Complete Your Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: Colors.black45,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Enter Your Details",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        // Display verified name if available
                        if (_verifiedName != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Name:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _verifiedName!,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 20),
                        // Address Field
                        if (_address != "")
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Address:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _address,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 20),
                        // Display Date of Birth if available
                        if (_age.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Date of Birth:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _age,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 20),
                        // Gender Dropdown Field
                        DropdownButtonFormField<String>(
                          focusColor: Colors.white,
                          value: _selectedGender,
                          items: ["Male", "Female", "Other"]
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedGender = value),
                          decoration: InputDecoration(
                            labelText: "Gender",
                            prefixIcon: Icon(Icons.wc, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.black), // Black border
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors
                                      .black), // Black border when not focused
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.black,
                                  width:
                                      2), // Thicker black border when focused
                            ),
                          ),
                          validator: (value) =>
                              value == null ? "Select Gender" : null,
                        ),
                        SizedBox(height: 20),
                        // Identity Proof Upload Button
                        ElevatedButton.icon(
                          onPressed: _pickIdentityProof,
                          icon: Icon(Icons.upload_file, color: Colors.white),
                          label: Text(
                            _identityFile == null
                                ? "Upload ID Proof"
                                : "File Selected",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Submit Profile Button
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Colors.deepPurple,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _saveProfile,
                                child: Text("Submit Profile",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
