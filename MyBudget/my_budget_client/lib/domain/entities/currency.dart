import 'package:equatable/equatable.dart';

class Currency extends Equatable {
  final String name;
  final String code;
  final String languageCode;

  const Currency({
    required this.name,
    required this.code,
    required this.languageCode
  });

  Currency copyWith({
    String? name,
    String? code,
    String? languageCode
  }) {
    return Currency(
      name: name ?? this.name,
      code: code ?? this.code,
      languageCode: languageCode ?? this.languageCode
    );
  }

  @override
  List<Object?> get props => [name, code, languageCode];
}
