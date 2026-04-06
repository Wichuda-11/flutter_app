class AppConfig {
  // system
  static String manualUrl(String base, String coopCode) =>
      '$base/$coopCode/';

  static String policyUrl(String base, String coopCode) =>
      '$base/$coopCode/';

  // common info
  static const appName = 'DOAE Saving';
  static const appNameForFilePath = 'DOAE_Saving';
  static const fullAppName = 'DOAE Saving Application';

  static const coopName =
      'สหกรณ์ออมทรัพย์กรมส่งเสริมการเกษตร จำกัด';

  static const coopNameEng =
      'DEPARTMENT OF AGRICULTURAL EXTENSION SAVINGS AND CREDIT COOPERATIVES LIMITED';

  static const coopTel = '025790885';
  static const coopMail = 'sahakorn_doae@hotmail.com';

  // default
  static const allowCoopTransaction = true;
  static const allowBankTransaction = true;
  static const minPasswordLength = 8;

  static const initHeaderGradientColor = ['#1F522A', '#1F522A'];
  static const transactionAuth = 'PIN';

  // login
  static const loginMaxPasswordAttempts = 5;

  // otp
  static const otpEnabled = true;
  static const otpLength = 6;
}