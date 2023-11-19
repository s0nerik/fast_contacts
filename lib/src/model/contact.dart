import 'package:flutter/foundation.dart';

@immutable
class Contact {
  const Contact({
    required this.id,
    required this.phones,
    required this.emails,
    required this.structuredName,
    required this.organization,
  });

  final String id;
  final List<Phone> phones;
  final List<Email> emails;
  final StructuredName? structuredName;
  final Organization? organization;

  String get displayName => structuredName?.displayName ?? '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          phones == other.phones &&
          emails == other.emails &&
          structuredName == other.structuredName &&
          organization == other.organization;

  @override
  int get hashCode =>
      id.hashCode ^
      phones.hashCode ^
      emails.hashCode ^
      structuredName.hashCode ^
      organization.hashCode;

  @override
  String toString() {
    return 'Contact{id: $id, phones: $phones, emails: $emails, structuredName: $structuredName, organization: $organization}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phones': phones.map((e) => e.toMap()).toList(),
      'emails': emails.map((e) => e.toMap()).toList(),
      if (structuredName != null) 'structuredName': structuredName!.toMap(),
      if (organization != null) 'organization': organization!.toMap(),
    };
  }

  factory Contact.fromMap(Map map) {
    return Contact(
      id: map['id'] ?? '',
      phones:
          (map['phones'] as List?)?.cast<Map>().map(Phone.fromMap).toList() ??
              const [],
      emails:
          (map['emails'] as List?)?.cast<Map>().map(Email.fromMap).toList() ??
              const [],
      structuredName: map['structuredName'] != null
          ? StructuredName.fromMap(map['structuredName']!)
          : null,
      organization: map['organization'] != null
          ? Organization.fromMap(map['organization']!)
          : null,
    );
  }
}

@immutable
class Phone {
  const Phone({
    required this.number,
    required this.label,
  });

  final String number;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Phone &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          label == other.label;

  @override
  int get hashCode => number.hashCode ^ label.hashCode;

  @override
  String toString() {
    return 'Phone{number: $number, label: $label}';
  }

  Map<String, dynamic> toMap() {
    return {
      'number': this.number,
      'label': this.label,
    };
  }

  factory Phone.fromMap(Map map) {
    return Phone(
      number: map['number'] ?? '',
      label: map['label'] ?? '',
    );
  }
}

@immutable
class Email {
  const Email({
    required this.address,
    required this.label,
  });

  final String address;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Email &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          label == other.label;

  @override
  int get hashCode => address.hashCode ^ label.hashCode;

  @override
  String toString() {
    return 'Email{address: $address, label: $label}';
  }

  Map<String, dynamic> toMap() {
    return {
      'address': this.address,
      'label': this.label,
    };
  }

  factory Email.fromMap(Map map) {
    return Email(
      address: map['address'] ?? '',
      label: map['label'] ?? '',
    );
  }
}

@immutable
class StructuredName {
  const StructuredName({
    required this.displayName,
    required this.namePrefix,
    required this.givenName,
    required this.middleName,
    required this.familyName,
    required this.nameSuffix,
  });

  final String displayName;
  final String namePrefix;
  final String givenName;
  final String middleName;
  final String familyName;
  final String nameSuffix;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredName &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          namePrefix == other.namePrefix &&
          givenName == other.givenName &&
          middleName == other.middleName &&
          familyName == other.familyName &&
          nameSuffix == other.nameSuffix;

  @override
  int get hashCode =>
      displayName.hashCode ^
      namePrefix.hashCode ^
      givenName.hashCode ^
      middleName.hashCode ^
      familyName.hashCode ^
      nameSuffix.hashCode;

  @override
  String toString() {
    return 'StructuredName{displayName: $displayName, namePrefix: $namePrefix, givenName: $givenName, middleName: $middleName, familyName: $familyName, nameSuffix: $nameSuffix}';
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': this.displayName,
      'namePrefix': this.namePrefix,
      'givenName': this.givenName,
      'middleName': this.middleName,
      'familyName': this.familyName,
      'nameSuffix': this.nameSuffix,
    };
  }

  factory StructuredName.fromMap(Map map) {
    return StructuredName(
      displayName: map['displayName'] ?? '',
      namePrefix: map['namePrefix'] ?? '',
      givenName: map['givenName'] ?? '',
      middleName: map['middleName'] ?? '',
      familyName: map['familyName'] ?? '',
      nameSuffix: map['nameSuffix'] ?? '',
    );
  }
}

@immutable
class Organization {
  const Organization({
    required this.company,
    required this.department,
    required this.jobDescription,
  });

  final String company;
  final String department;
  final String jobDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organization &&
          runtimeType == other.runtimeType &&
          company == other.company &&
          department == other.department &&
          jobDescription == other.jobDescription;

  @override
  int get hashCode =>
      company.hashCode ^ department.hashCode ^ jobDescription.hashCode;

  @override
  String toString() {
    return 'Organization{company: $company, department: $department, jobDescription: $jobDescription}';
  }

  Map<String, dynamic> toMap() {
    return {
      'company': this.company,
      'department': this.department,
      'jobDescription': this.jobDescription,
    };
  }

  factory Organization.fromMap(Map map) {
    return Organization(
      company: map['company'] ?? '',
      department: map['department'] ?? '',
      jobDescription: map['jobDescription'] ?? '',
    );
  }
}
