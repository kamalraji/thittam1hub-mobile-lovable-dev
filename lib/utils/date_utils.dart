/// Returns a time-based greeting
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

/// Returns the greeting emoji based on time
String getGreetingEmoji() {
  final hour = DateTime.now().hour;
  if (hour < 12) return '☀️';
  if (hour < 17) return '🌤️';
  if (hour < 21) return '🌙';
  return '✨';
}
