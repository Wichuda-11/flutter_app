import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get manualUrl => dotenv.env['MANUAL_URL'] ?? '';
  static String get policyUrl => dotenv.env['POLICY_URL'] ?? '';
  static String get coopCode => dotenv.env['COOP_CODE'] ?? '';
}