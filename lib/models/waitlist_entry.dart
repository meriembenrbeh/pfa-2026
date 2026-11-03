class WaitlistEntry {
  final String userId;
  final DateTime? joinedAt;

  const WaitlistEntry({
    required this.userId,
    this.joinedAt,
  });
}
