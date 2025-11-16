class Account {
  final int? id;
  final String name;
  final double balance;
  final int currencyId;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.currencyId,
  });

  Account copyWith({
    int? id,
    String? name,
    double? balance,
    int? currencyId,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currencyId: currencyId ?? this.currencyId,
    );
  }
}
