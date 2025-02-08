class UserModel {
  String uid;
  String name;
  String address;
  String dob;
  String gender;
  String identityProofUrl;
  String identityType;
  String verifiedName;

  UserModel({
    required this.uid,
    required this.name,
    required this.address,
    required this.dob,
    required this.gender,
    required this.identityProofUrl,
    required this.identityType,
    required this.verifiedName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'address': address,
      'dob': dob,
      'gender': gender,
      'identityProofUrl': identityProofUrl,
      'identityType': identityType,
      'verifiedName': verifiedName,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      address: map['address'],
      dob: map['dob'],
      gender: map['gender'],
      identityProofUrl: map['identityProofUrl'],
      identityType: map['identityType'],
      verifiedName: map['verifiedName'],
    );
  }
}
