import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted, one-way password hashing for the local demo.
///
/// Passwords are never stored directly. Each password is stretched with
/// PBKDF2-HMAC-SHA256 and stored in this format:
///
/// `pbkdf2-sha256$<iterations>$<base64 salt>$<base64 hash>`
///
/// This is the production-correct alternative to reversible "encryption":
/// even if the local JSON is read, the original password cannot be recovered.
class PasswordHasher {
  static const String algorithm = 'pbkdf2-sha256';

  /// Work factor for PBKDF2-HMAC-SHA256. High enough to make offline guessing
  /// expensive, while keeping the local demo responsive on mobile devices.
  static const int iterations = 100000;

  static const int saltLength = 16;
  static const int keyLength = 32;

  static final Random _random = Random.secure();

  /// Hashes a plain password with a new cryptographically random salt.
  static String hashPassword(String password) {
    final salt = Uint8List.fromList(
      List<int>.generate(saltLength, (_) => _random.nextInt(256)),
    );
    return _hashWithSalt(password, salt, iterations);
  }

  /// Hashes with a fixed salt. Used only to generate deterministic demo hashes.
  static String hashPasswordWithFixedSalt(String password, String saltBase64) {
    final salt = base64.decode(saltBase64);
    if (salt.isEmpty) {
      throw ArgumentError.value(saltBase64, 'saltBase64', 'Salt cannot be empty');
    }
    return _hashWithSalt(password, Uint8List.fromList(salt), iterations);
  }

  /// Verifies a plain password against a stored encoded hash.
  static bool verifyPassword(String password, String stored) {
    final parsed = _parse(stored);
    if (parsed == null) return false;
    final actual = _pbkdf2(password, parsed.salt, parsed.iterations, parsed.key.length);
    return _constantTimeEquals(actual, parsed.key);
  }

  /// Converts any old plaintext `password` values in a decoded state map into
  /// salted hashes and removes the plaintext key.
  ///
  /// Returns true when storage should be rewritten.
  static bool migrateLegacyState(Map<String, dynamic> stateJson) {
    final users = stateJson['users'];
    if (users is! List) return false;

    var changed = false;
    for (final entry in users) {
      if (entry is! Map<String, dynamic>) continue;

      final legacy = entry['password'];
      final hash = entry['passwordHash'];

      if ((hash == null || hash.toString().isEmpty) &&
          legacy is String &&
          legacy.isNotEmpty) {
        entry['passwordHash'] = hashPassword(legacy);
        entry.remove('password');
        changed = true;
      } else if (entry.containsKey('password')) {
        // A hash already exists, so any remaining plaintext is stale.
        entry.remove('password');
        changed = true;
      }
    }
    return changed;
  }

  static String _hashWithSalt(String password, Uint8List salt, int iterationCount) {
    final derived = _pbkdf2(password, salt, iterationCount, keyLength);
    return <String>[
      algorithm,
      iterationCount.toString(),
      base64.encode(salt),
      base64.encode(derived),
    ].join(r'$');
  }

  static _ParsedHash? _parse(String stored) {
    try {
      final parts = stored.split(r'$');
      if (parts.length != 4 || parts[0] != algorithm) return null;
      final iterationCount = int.tryParse(parts[1]);
      if (iterationCount == null || iterationCount <= 0) return null;
      final salt = base64.decode(parts[2]);
      final key = base64.decode(parts[3]);
      if (salt.isEmpty || key.isEmpty) return null;
      return _ParsedHash(salt: salt, key: key, iterations: iterationCount);
    } on FormatException {
      return null;
    }
  }

  static Uint8List _pbkdf2(
    String password,
    Uint8List salt,
    int iterationCount,
    int derivedLength,
  ) {
    const int hmacLength = 32; // SHA-256 output size.
    final hmac = Hmac(sha256, utf8.encode(password));
    final blockCount = (derivedLength / hmacLength).ceil();
    final output = BytesBuilder(copy: false);
    final blockIndexBytes = Uint8List(4);

    for (var block = 1; block <= blockCount; block++) {
      blockIndexBytes[0] = (block >> 24) & 0xff;
      blockIndexBytes[1] = (block >> 16) & 0xff;
      blockIndexBytes[2] = (block >> 8) & 0xff;
      blockIndexBytes[3] = block & 0xff;

      final input = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..setRange(salt.length, salt.length + 4, blockIndexBytes);

      var u = Uint8List.fromList(hmac.convert(input).bytes);
      final t = Uint8List.fromList(u);

      for (var i = 1; i < iterationCount; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.add(t);
    }

    final bytes = output.takeBytes();
    if (bytes.length == derivedLength) return bytes;
    return Uint8List.sublistView(bytes, 0, derivedLength);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}

class _ParsedHash {
  final Uint8List salt;
  final Uint8List key;
  final int iterations;

  const _ParsedHash({
    required this.salt,
    required this.key,
    required this.iterations,
  });
}
