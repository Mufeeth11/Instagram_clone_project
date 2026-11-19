import 'package:flutter_test/flutter_test.dart';

import 'package:instagram_clone/core/services/password_hasher.dart';
import 'package:instagram_clone/models/user_model.dart';

void main() {
  test('password hashes verify without storing plain text', () {
    final hash = PasswordHasher.hashPassword('demo123');

    expect(hash, isNot(contains('demo123')));
    expect(hash.startsWith('pbkdf2-sha256\$'), isTrue);
    expect(PasswordHasher.verifyPassword('demo123', hash), isTrue);
    expect(PasswordHasher.verifyPassword('wrong-pass', hash), isFalse);

    final user = UserModel(
      id: 'u_test',
      username: 'test_user',
      displayName: 'Test User',
      passwordHash: hash,
    );

    expect(user.toJson().containsKey('password'), isFalse);
    expect(user.toJson()['passwordHash'], hash);
  });

  test('legacy plaintext passwords are migrated to hashes', () {
    final state = <String, dynamic>{
      'users': <dynamic>[
        <String, dynamic>{
          'id': 'u0',
          'password': 'demo123',
        },
      ],
    };

    final changed = PasswordHasher.migrateLegacyState(state);
    final migrated = (state['users'] as List).first as Map<String, dynamic>;

    expect(changed, isTrue);
    expect(migrated.containsKey('password'), isFalse);
    expect(
      PasswordHasher.verifyPassword(
        'demo123',
        migrated['passwordHash'] as String,
      ),
      isTrue,
    );
  });
}
