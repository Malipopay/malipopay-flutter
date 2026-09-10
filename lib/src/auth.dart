/// How a [MalipopayHttpClient] proves who it is.
///
/// Malipopay backends accept two personas on the same routes, and both are
/// first class. Neither is legacy.
///
/// - **API token.** A project-wide secret minted from the dashboard, sent as
///   the `apiToken` header. This is how server-side integrations connect.
/// - **Session.** A user's JWT plus the id of the project they are acting on,
///   sent as `Authorization: Bearer` and `project`. This is how the dashboard
///   and a mobile app connect.
///
/// **Never both.** The backend branches on `apiToken` first, so sending both
/// silently discards the JWT and acts as the whole project instead of as the
/// signed-in user.
///
/// **Never ship an API token in a mobile binary.** It is extractable from any
/// APK or IPA and grants the full SDK surface with no user scoping.
sealed class MalipopayAuth {
  const MalipopayAuth();

  /// Headers for a request to [path]. Empty when the endpoint is public.
  Future<Map<String, String>> headers(String path);
}

/// Persona 2: a single project-wide `apiToken` header.
class ApiTokenAuth extends MalipopayAuth {
  /// Creates an [ApiTokenAuth] from a dashboard-minted key.
  const ApiTokenAuth(this.apiKey);

  /// The project's API token.
  final String apiKey;

  @override
  Future<Map<String, String>> headers(String path) async => {
        'apiToken': apiKey,
      };
}

/// Persona 1: a user's JWT plus the project they are acting on.
///
/// Both values are read through callbacks rather than captured once, because a
/// mobile app refreshes its token and switches business without rebuilding the
/// client.
///
/// ```dart
/// final client = Malipopay.session(
///   SessionAuth(
///     token: () => secureStorage.read(key: 'access_token'),
///     projectId: () => scope.current?.id,
///     projectSlug: () => scope.current?.slug,
///   ),
///   environment: MalipopayEnvironment.uat,
/// );
/// ```
class SessionAuth extends MalipopayAuth {
  /// Creates a [SessionAuth].
  ///
  /// [projectSlug] is only needed if the app calls the messaging endpoints;
  /// see [needsSlug].
  const SessionAuth({
    required this.token,
    required this.projectId,
    this.projectSlug,
  });

  /// Reads the current access token, or null when signed out.
  final Future<String?> Function() token;

  /// Reads the id of the project the user is acting on.
  final String? Function() projectId;

  /// Reads that project's slug, for the messaging endpoints.
  final String? Function()? projectSlug;

  /// Path prefixes whose `project` header carries the SLUG, not the id.
  ///
  /// These proxy to the SMS service, which keys companies by slug while
  /// everything else keys projects by their Mongo id. Sending an id here
  /// resolves nothing and the request fails as if the project did not exist.
  static const slugPrefixes = <String>[
    '/sms',
    '/company',
    '/billing',
    '/waba',
    '/email',
    '/whatsapp',
  ];

  /// Whether [path] takes the slug rather than the project id.
  static bool needsSlug(String path) {
    final p = _stripVersion(path);
    return slugPrefixes.any((s) => p == s || p.startsWith('$s/'));
  }

  /// Strips a leading `/api/vN` so prefix matching works on either form.
  static String _stripVersion(String path) {
    final m = RegExp(r'^/api/v\d+').firstMatch(path);
    return m == null ? path : path.substring(m.end);
  }

  @override
  Future<Map<String, String>> headers(String path) async {
    final headers = <String, String>{};
    final jwt = await token();
    if (jwt != null && jwt.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwt';
    }
    final project = needsSlug(path) ? projectSlug?.call() : projectId();
    if (project != null && project.isNotEmpty) {
      headers['project'] = project;
    }
    return headers;
  }
}
