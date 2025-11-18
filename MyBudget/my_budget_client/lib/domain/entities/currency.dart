import 'package:equatable/equatable.dart';

class Currency extends Equatable {
  final int id;
  final String name;
  final String code;

  const Currency({
    required this.id,
    required this.name,
    required this.code,
  });

  Currency copyWith({
    int? id,
    String? name,
    String? code,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }

  @override
  List<Object?> get props => [id, name, code];
}
