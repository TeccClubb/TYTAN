class GuestUserResponse {
  final GuestUser? user;
  final List<dynamic>? subscriptions;

  GuestUserResponse({this.user, this.subscriptions});

  factory GuestUserResponse.fromJson(Map<String, dynamic> json) {
    return GuestUserResponse(
      user: json['user'] != null ? GuestUser.fromJson(json['user']) : null,
      subscriptions: json['subscriptions'] as List<dynamic>?,
    );
  }
}

class GuestUser {
  final int? id;
  final String? name;
  final String? email;
  final String? appAccountToken;
  final bool? isGuest;
  final bool? isTemporary;

  GuestUser({
    this.id,
    this.name,
    this.email,
    this.appAccountToken,
    this.isGuest,
    this.isTemporary,
  });

  factory GuestUser.fromJson(Map<String, dynamic> json) {
    return GuestUser(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      appAccountToken: json['app_account_token'] as String?,
      isGuest: json['is_guest'] as bool?,
      isTemporary: json['is_temporary'] as bool?,
    );
  }
}
