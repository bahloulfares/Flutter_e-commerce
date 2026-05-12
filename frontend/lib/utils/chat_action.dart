// Chat action for bot responses that trigger navigation or external actions

enum ActionType {
  message, // Simple message response
  redirect, // Navigate within the app
  url, // Open external URL
  filter, // Navigate with product filters
}

class ChatAction {
  final ActionType type;
  final String? target; // Route name for redirect or URL for external
  final Map<String, String>?
      params; // Additional parameters (e.g., category filter)
  final String? message; // Display message alongside action

  ChatAction({
    required this.type,
    this.target,
    this.params,
    this.message,
  });

  // Factory constructor for JSON deserialization from backend
  factory ChatAction.fromJson(Map<String, dynamic> json) {
    return ChatAction(
      type: ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'] as String,
        orElse: () => ActionType.message,
      ),
      target: json['target'],
      params: Map<String, String>.from(json['params'] ?? {}),
      message: json['message'],
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() => {
        'type': type.toString().split('.').last,
        'target': target,
        'params': params,
        'message': message,
      };
}
