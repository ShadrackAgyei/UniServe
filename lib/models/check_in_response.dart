enum CheckInResultType { success, alreadyCheckedIn, invalid }

class CheckInResponse {
  final CheckInResultType result;
  final String? name;
  /// ISO 8601 timestamp string from Supabase created_at — format for display before use
  final String? checkedInAt;

  CheckInResponse({required this.result, this.name, this.checkedInAt});
}
