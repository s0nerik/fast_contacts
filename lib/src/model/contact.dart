class Contact {
  Contact._({
    required this.id,
    required this.displayName,
    required this.phones,
    required this.emails,
    required this.structuredName,
    required this.organization,
  });

  factory Contact.fromMap(Map map) {
    return Contact._(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      phones: (map['phones'] as List).cast<Map>().map(Phone.fromMap).toList(),
      emails: (map['emails'] as List).cast<Map>().map(Email.fromMap).toList(),
      structuredName: map['structuredName'] != null
          ? StructuredName.fromMap(map['structuredName']!)
          : null,
      organization: map['organization'] != null
          ? Organization.fromMap(map['organization']!)
          : null,
    );
  }

  final String id;
  final String displayName;
  final List<Phone> phones;
  final List<Email> emails;
  final StructuredName? structuredName;
  final Organization? organization;
}

class Phone {
  Phone._({
    required this.number,
    required this.label,
  });

  factory Phone.fromMap(Map map) {
    return Phone._(
      number: map['number'] ?? '',
      label: map['label'] ?? '',
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
      address: map['address'] ?? '',
      label: map['label'] ?? '',
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
      namePrefix: map['namePrefix'] ?? '',
      givenName: map['givenName'] ?? '',
      middleName: map['middleName'] ?? '',
      familyName: map['familyName'] ?? '',
      nameSuffix: map['nameSuffix'] ?? '',
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
      company: map['company'] ?? '',
      department: map['department'] ?? '',
      jobDescription: map['jobDescription'] ?? '',
    );
  }

  final String company;
  final String department;
  final String jobDescription;
}
