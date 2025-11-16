class CurrencyDesignation {
  final int id;
  final String value;

  CurrencyDesignation({
    required this.id,
    required this.value,
  });

  CurrencyDesignation copyWith({
    int? id,
    String? value,
  }) {
    return CurrencyDesignation(
      id: id ?? this.id,
      value: value ?? this.value,
    );
  }
}
