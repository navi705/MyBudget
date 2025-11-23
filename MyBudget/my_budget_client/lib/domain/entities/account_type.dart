import 'package:equatable/equatable.dart';

class AccountType extends Equatable {
  final String id;
  final String name;

  const AccountType({
    required this.id,
    required this.name,
  });

  AccountType copyWith({
    String? id,
    String? name,
  }) {
    return AccountType(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
