class Transaction {
  String title;
  double amount;
  bool isIncome;
  DateTime date;   // 🔥 เพิ่ม

  Transaction({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}