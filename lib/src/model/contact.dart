abstract class Contact {
  String get id;
  String get displayName;
  List<Phone> get phones;
  List<Email> get emails;
  StructuredName? get structuredName;
  Organization? get organization;
}

class Phone {
  Phone._({
    required this.number,
    required this.label,
  });

  factory Phone.fromMap(Map map) {
    return Phone._(
      number: map['number'],
      label: map['label'],
    );
  }

  final String number;
  final String label;
}

class Email {
  Email._({
    required this.address,
    required this.label,
  });

  factory Email.fromMap(Map map) {
    return Email._(
      address: map['address'],
      label: map['label'],
    );
  }

  final String address;
  final String label;
}

class StructuredName {
  StructuredName._({
    required this.namePrefix,
    required this.givenName,
    required this.middleName,
    required this.familyName,
    required this.nameSuffix,
  });

  factory StructuredName.fromMap(Map map) {
    return StructuredName._(
      namePrefix: map['namePrefix'] as String,
      givenName: map['givenName'] as String,
      middleName: map['middleName'] as String,
      familyName: map['familyName'] as String,
      nameSuffix: map['nameSuffix'] as String,
    );
  }

  final String namePrefix;
  final String givenName;
  final String middleName;
  final String familyName;
  final String nameSuffix;
}

class Organization {
  Organization._({
    required this.company,
    required this.department,
    required this.jobDescription,
  });

  factory Organization.fromMap(Map map) {
    return Organization._(
      company: map['company'] as String,
      department: map['department'] as String,
      jobDescription: map['jobDescription'] as String,
    );
  }

  final String company;
  final String department;
  final String jobDescription;
}
