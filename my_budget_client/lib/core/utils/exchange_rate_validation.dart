/// Whether [rate] can actually convert an amount.
///
/// A rate is a multiplier, so the only usable ones are finite and above zero.
/// Zero writes the converted side of a transfer as nothing - the money leaves
/// the source account and arrives nowhere - and a negative rate writes it with
/// the sign flipped, so both accounts lose. Infinity and NaN come out of a
/// division by an earlier zero and poison every balance they reach.
///
/// The import path has always refused these, which is why an imported file
/// cannot carry one; this is the same test, so a rate typed by hand is held to
/// what an imported one already was.
bool isUsableExchangeRate(double? rate) =>
    rate != null && rate.isFinite && rate > 0;
