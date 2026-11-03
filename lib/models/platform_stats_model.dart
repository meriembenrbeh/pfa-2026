class PlatformStats {
  final double averageRating;
  final int totalReviews;
  final int completedSessions;
  final int attendanceConfirmed;
  final int attendanceNoShow;
  final double attendanceRate;

  const PlatformStats({
    required this.averageRating,
    required this.totalReviews,
    required this.completedSessions,
    required this.attendanceConfirmed,
    required this.attendanceNoShow,
    required this.attendanceRate,
  });

  int get attendanceTotal => attendanceConfirmed + attendanceNoShow;
}
