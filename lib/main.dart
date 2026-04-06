import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kIsWeb
import 'dart:io' as io;
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 👈 สำคัญ

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class Transaction {
  String title;
  double amount;
  bool isIncome;
  DateTime date;

  Transaction({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> transactions = [];

  DateTime selectedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  List<Transaction> get filteredTransactions {
    return transactions.where((t) {
      return t.date.year == selectedDate.year &&
            t.date.month == selectedDate.month &&
            t.date.day == selectedDate.day;
    }).toList();
  }

  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => !t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  

  // void addTransaction(String title, double amount, bool isIncome) {
  //   setState(() {
  //     transactions.add(Transaction(
  //       title: title,
  //       amount: amount,
  //       isIncome: isIncome,
  //       //date: DateTime.now(),
  //       date: selectedDate,
  //     ));
  //   });
  // }
  void addTransaction(String title, double amount, bool isIncome, DateTime date) {
    setState(() {
      transactions.add(Transaction(
        title: title,
        amount: amount,
        isIncome: isIncome,
        date: date, // 👈 ใช้ค่าที่ส่งมา
      ));
    });
  }

  void showAddDialog() {
    String title = '';
    double amount = 0;
    bool isIncome = true;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('เพิ่มรายการ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'ชื่อรายการ'),
                  onChanged: (value) => title = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'จำนวนเงิน'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      amount = double.tryParse(value) ?? 0,
                ),

                SizedBox(height: 10),

                // 👇 เลือกวันที่
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "วันที่: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text("เลือกวันที่"),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isIncome ? 'รายรับ 💰' : 'รายจ่าย 💸'),
                    Switch(
                      value: isIncome,
                      onChanged: (value) {
                        setStateDialog(() {
                          isIncome = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  addTransaction(title, amount, isIncome, selectedDate); // 👈 ใช้ตัวนี้
                  Navigator.pop(context);
                },
                child: Text('บันทึก'),
              )
            ],
          );
        },
      ),
    );
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
  Future<void> generateAndSharePdf(
  BuildContext context,
  List<Transaction> transactions,
) async {
  final pdf = pw.Document();

  // โหลดฟอนต์
  final fontData = await rootBundle.load("assets/fonts/Prompt-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  final boldFontData =
      await rootBundle.load("assets/fonts/Prompt-Bold.ttf");
  final ttfBold = pw.Font.ttf(boldFontData);

  final formatter = NumberFormat('#,###');

  double totalIncome = transactions
      .where((t) => t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  double totalExpense = transactions
      .where((t) => !t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  double balance = totalIncome - totalExpense;

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.DefaultTextStyle(
          style: pw.TextStyle(font: ttf, fontSize: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('รายงานรายรับรายจ่าย',
                  style: pw.TextStyle(font: ttfBold, fontSize: 20)),
              pw.SizedBox(height: 10),
              pw.Text('รายรับ: ${formatter.format(totalIncome)}'),
              pw.Text('รายจ่าย: ${formatter.format(totalExpense)}'),
              pw.Text('คงเหลือ: ${formatter.format(balance)}'),
              pw.SizedBox(height: 20),

              pw.Table.fromTextArray(
                headers: ['วันที่','รายการ', 'ประเภท', 'จำนวนเงิน'],
                data: transactions.map((t) {
                  return [
                    DateFormat('dd/MM/yyyy').format(t.date),
                    t.title,
                    t.isIncome ? 'รายรับ' : 'รายจ่าย',
                    formatter.format(t.amount),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(font: ttfBold),
                cellStyle: pw.TextStyle(font: ttf),
              ),
            ],
          ),
        );
      },
    ),
  );

  final bytes = await pdf.save();

  // ✅ แยก platform ตรงนี้
  if (kIsWeb) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // ✅ ดาวน์โหลด
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "report.pdf")
      ..click();

    // ✅ เปิดดูใน tab ใหม่ (เพิ่ม UX)
    html.window.open(url, "_blank");

    // ✅ delay revoke กันไฟล์โหลดไม่ทัน
    Future.delayed(Duration(seconds: 1), () {
      html.Url.revokeObjectUrl(url);
    });

  } else {
    final dir = await getTemporaryDirectory();
    final file = io.File("${dir.path}/report.pdf");
    await file.writeAsBytes(bytes);

    final box = context.findRenderObject() as RenderBox?;

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'รายงานรายรับรายจ่าย',
      sharePositionOrigin:
          box!.localToGlobal(Offset.zero) & box.size,
    );
  }
}

  // Future<void> generateAndSharePdf(List<Transaction> transactions) async {
  //   final pdf = pw.Document();

  //   // โหลดฟอนต์ไทย
  //   final fontData = await rootBundle.load("assets/fonts/Prompt-Regular.ttf");
  //   final ttf = pw.Font.ttf(fontData);

  //   final boldFontData =
  //       await rootBundle.load("assets/fonts/Prompt-Bold.ttf");
  //   final ttfBold = pw.Font.ttf(boldFontData);

  //   final formatter = NumberFormat('#,###');

  //   double totalIncome = transactions
  //       .where((t) => t.isIncome)
  //       .fold(0, (sum, t) => sum + t.amount);

  //   double totalExpense = transactions
  //       .where((t) => !t.isIncome)
  //       .fold(0, (sum, t) => sum + t.amount);

  //   double balance = totalIncome - totalExpense;

  //   pdf.addPage(
  //     pw.Page(
  //       build: (context) {
  //         return pw.DefaultTextStyle(
  //           style: pw.TextStyle(font: ttf, fontSize: 12),
  //           child: pw.Column(
  //             crossAxisAlignment: pw.CrossAxisAlignment.start,
  //             children: [
  //               pw.Text(
  //                 'รายงานรายรับรายจ่าย',
  //                 style: pw.TextStyle(
  //                   font: ttfBold,
  //                   fontSize: 20,
  //                 ),
  //               ),

  //               pw.SizedBox(height: 10),

  //               pw.Text('รายรับ: ${formatter.format(totalIncome)}'),
  //               pw.Text('รายจ่าย: ${formatter.format(totalExpense)}'),
  //               pw.Text('คงเหลือ: ${formatter.format(balance)}'),

  //               pw.SizedBox(height: 20),

  //               pw.Table.fromTextArray(
  //                 headers: ['วันที่','รายการ', 'ประเภท', 'จำนวนเงิน'],
  //                 data: transactions.map((t) {
  //                   return [
  //                     DateFormat('dd/MM/yyyy').format(t.date),
  //                     t.title,
  //                     t.isIncome ? 'รายรับ' : 'รายจ่าย',
  //                     formatter.format(t.amount),
  //                   ];
  //                 }).toList(),
  //                 headerStyle: pw.TextStyle(font: ttfBold),
  //                 cellStyle: pw.TextStyle(font: ttf),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );

  //   final output = await getTemporaryDirectory();
  //   final file = File("${output.path}/report.pdf");
  //   await file.writeAsBytes(await pdf.save());

  //   final box = context.findRenderObject() as RenderBox?;

  //   await Share.shareXFiles(
  //     [XFile(file.path)],
  //     text: 'รายงานรายรับรายจ่าย',
  //     sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    double balance = totalIncome - totalExpense;
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: Text('รายรับรายจ่าย'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: pickDate,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 🔵 Balance Card
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ยอดคงเหลือ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '฿ ${formatter.format(balance)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 🔘 Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await generateAndSharePdf(context, transactions);
                  },
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('แชร์ PDF'),
                ),
              ],
            ),
          ),
          //Padding( padding: const EdgeInsets.symmetric(horizontal: 16),  child: ElevatedButton.icon( onPressed: () { generateAndSharePdf(filteredTransactions); }, icon: Icon(Icons.picture_as_pdf), label: Text('แชร์ PDF'), ), ),

          // 📅 แสดงวันที่ที่เลือก
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "วันที่: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 8),
          //   child: Text(
          //     "วันที่: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
          //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          //   ),
          // ),

          SizedBox(height: 8),

          // 📋 List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final t = filteredTransactions[index];

                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: t.isIncome
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      child: Icon(
                        t.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      t.title,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '${t.isIncome ? '+' : '-'}฿${formatter.format(t.amount)}',
                      style: TextStyle(
                        color: t.isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}