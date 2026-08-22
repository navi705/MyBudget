import 'package:equatable/equatable.dart';

class AccountType extends Equatable {
  final String id;
  final String name;
  final String languageCode;

  const AccountType({
    required this.id,
    required this.name,
    required this.languageCode,
  });

  AccountType copyWith({String? id, String? name, String? languageCode}) {
    return AccountType(
      id: id ?? this.id,
      name: name ?? this.name,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  List<Object?> get props => [id, name, languageCode];
}
