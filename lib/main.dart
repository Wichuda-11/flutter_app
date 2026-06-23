import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class Transaction {
  String title;
  double incomeAmount;
  double amount;
  bool isIncome;
  DateTime date;
  int quantity;
  double pricePerItem;

  Transaction({
    required this.title,
    required this.incomeAmount,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.quantity,
    required this.pricePerItem,
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

  void addTransaction(
    String title,
    double amount,
    double incomeAmount,
    bool isIncome,
    DateTime date,
    int quantity,
    double pricePerItem,
  ) {
    setState(() {
      transactions.add(
        Transaction(
          title: title,
          amount: amount,
          incomeAmount: incomeAmount,
          isIncome: isIncome,
          date: date,
          quantity: quantity,
          pricePerItem: pricePerItem,
        ),
      );
    });
  }

  void updateTransaction(int index, Transaction transaction) {
    if (index < 0 || index >= transactions.length) return;

    setState(() {
      transactions[index] = transaction;
    });
  }

  void showAddDialog() {
    String title = '';
    int quantity = 1;
    double pricePerItem = 0;
    double incomeAmount = 0;
    double amount = 0;
    bool isIncome = true;
    DateTime addDate = selectedDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('เพิ่มรายการ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'ชื่อรายการ',
                    ),
                    onChanged: (value) => title = value,
                  ),

                  if (!isIncome)
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'จำนวนชิ้น',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        quantity = int.tryParse(value) ?? 1;
                        setStateDialog(() {
                          amount = quantity * pricePerItem;
                        });
                      },
                    ),

                  if (isIncome)
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'รายรับเข้า',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        incomeAmount = double.tryParse(value) ?? 0;
                        setStateDialog(() {
                          amount = incomeAmount;
                        });
                      },
                    )
                  else
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'ราคาต่อชิ้น',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        pricePerItem = double.tryParse(value) ?? 0;
                        setStateDialog(() {
                          amount = quantity * pricePerItem;
                        });
                      },
                    ),

                  const SizedBox(height: 10),

                  Text(
                    'รวม: ${amount.toStringAsFixed(2)} บาท',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "วันที่: ${addDate.day}/${addDate.month}/${addDate.year}",
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: addDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setStateDialog(() {
                              addDate = picked;
                            });
                          }
                        },
                        child: const Text("เลือกวันที่"),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isIncome ? 'รายรับ 💰' : 'รายจ่าย 💸'),
                      Switch(
                        value: isIncome,
                        onChanged: (value) {
                          setStateDialog(() {
                            isIncome = value;
                            amount = 0;
                            incomeAmount = 0;
                            pricePerItem = 0;
                            quantity = 1;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (title.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('กรุณากรอกชื่อรายการ')),
                    );
                    return;
                  }

                  if (isIncome) {
                    if (incomeAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกรายรับเข้า')),
                      );
                      return;
                    }

                    addTransaction(
                      title,
                      incomeAmount,
                      incomeAmount,
                      true,
                      addDate,
                      0,
                      0,
                    );
                  } else {
                    if (quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('จำนวนชิ้นต้องมากกว่า 0')),
                      );
                      return;
                    }

                    if (pricePerItem <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกราคาต่อชิ้น')),
                      );
                      return;
                    }

                    final total = quantity * pricePerItem;

                    addTransaction(
                      title,
                      total,
                      0,
                      false,
                      addDate,
                      quantity,
                      pricePerItem,
                    );
                  }

                  Navigator.pop(context);
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  void showEditDialog(int index, Transaction transaction) {
    if (index < 0 || index >= transactions.length) return;

    String title = transaction.title;
    int quantity = transaction.quantity == 0 ? 1 : transaction.quantity;
    double pricePerItem = transaction.pricePerItem;
    double incomeAmount = transaction.incomeAmount;
    double amount = transaction.amount;
    bool isIncome = transaction.isIncome;
    DateTime editDate = transaction.date;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('แก้ไขรายการ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อรายการ',
                    ),
                    onChanged: (v) => title = v,
                  ),

                  if (!isIncome)
                    TextFormField(
                      initialValue: quantity.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'จำนวนชิ้น',
                      ),
                      onChanged: (v) {
                        quantity = int.tryParse(v) ?? 1;
                        setStateDialog(() {
                          amount = quantity * pricePerItem;
                        });
                      },
                    ),

                  if (isIncome)
                    TextFormField(
                      initialValue: incomeAmount.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'รายรับเข้า',
                      ),
                      onChanged: (v) {
                        incomeAmount = double.tryParse(v) ?? 0;
                        setStateDialog(() {
                          amount = incomeAmount;
                        });
                      },
                    )
                  else
                    TextFormField(
                      initialValue: pricePerItem.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ราคาต่อชิ้น',
                      ),
                      onChanged: (v) {
                        pricePerItem = double.tryParse(v) ?? 0;
                        setStateDialog(() {
                          amount = quantity * pricePerItem;
                        });
                      },
                    ),

                  const SizedBox(height: 10),

                  Text(
                    'รวม ${amount.toStringAsFixed(2)} บาท',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "วันที่: ${editDate.day}/${editDate.month}/${editDate.year}",
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: editDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setStateDialog(() {
                              editDate = picked;
                            });
                          }
                        },
                        child: const Text("เลือกวันที่"),
                      ),
                    ],
                  ),

                  SwitchListTile(
                    value: isIncome,
                    title: Text(isIncome ? 'รายรับ 💰' : 'รายจ่าย 💸'),
                    onChanged: (value) {
                      setStateDialog(() {
                        isIncome = value;
                        amount = 0;
                        incomeAmount = 0;
                        pricePerItem = 0;
                        quantity = 1;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'ลบ',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('ยืนยันการลบ'),
                      content: Text('ต้องการลบ "$title" ใช่หรือไม่'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('ยกเลิก'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('ลบ'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    setState(() {
                      transactions.removeAt(index);
                    });

                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),

              ElevatedButton(
                onPressed: () {
                  if (title.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('กรุณากรอกชื่อรายการ')),
                    );
                    return;
                  }

                  if (isIncome) {
                    if (incomeAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกรายรับเข้า')),
                      );
                      return;
                    }

                    updateTransaction(
                      index,
                      Transaction(
                        title: title,
                        amount: incomeAmount,
                        incomeAmount: incomeAmount,
                        isIncome: true,
                        date: editDate,
                        quantity: 0,
                        pricePerItem: 0,
                      ),
                    );
                  } else {
                    if (quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('จำนวนชิ้นต้องมากกว่า 0')),
                      );
                      return;
                    }

                    if (pricePerItem <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกราคาต่อชิ้น')),
                      );
                      return;
                    }

                    final total = quantity * pricePerItem;

                    updateTransaction(
                      index,
                      Transaction(
                        title: title,
                        amount: total,
                        incomeAmount: 0,
                        isIncome: false,
                        date: editDate,
                        quantity: quantity,
                        pricePerItem: pricePerItem,
                      ),
                    );
                  }

                  Navigator.pop(context);
                },
                child: const Text('บันทึก'),
              ),
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
    List<Transaction> pdfTransactions,
  ) async {
    if (pdfTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลสำหรับสร้าง PDF')),
      );
      return;
    }

    final pdf = pw.Document();

    final fontData = await rootBundle.load("assets/fonts/Prompt-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final boldFontData = await rootBundle.load("assets/fonts/Prompt-Bold.ttf");
    final ttfBold = pw.Font.ttf(boldFontData);

    final formatter = NumberFormat('#,###.##');

    final totalIncome = pdfTransactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = pdfTransactions
        .where((t) => !t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpense;

    pw.Widget headerCell(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: ttfBold, fontSize: 9),
        ),
      );
    }

    pw.Widget cell(String text, {pw.Font? font, PdfColor? color}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: font ?? ttf,
            fontSize: 9,
            color: color,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'รายงานรายรับรายจ่าย',
              style: pw.TextStyle(font: ttfBold, fontSize: 20),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'หน้า ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(font: ttf, fontSize: 10),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.8),
              1: const pw.FlexColumnWidth(3.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.3),
              6: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  headerCell('วันที่'),
                  headerCell('รายการ'),
                  headerCell('จำนวน'),
                  headerCell('ราคาต่อชิ้น'),
                  headerCell('รายรับเข้า'),
                  headerCell('ประเภท'),
                  headerCell('จำนวนเงิน'),
                ],
              ),
              ...pdfTransactions.map(
                (t) => pw.TableRow(
                  children: [
                    cell(DateFormat('dd/MM/yyyy').format(t.date)),
                    cell(t.title),
                    cell(t.isIncome ? '-' : t.quantity.toString()),
                    cell(t.isIncome ? '-' : formatter.format(t.pricePerItem)),
                    cell(t.isIncome ? formatter.format(t.incomeAmount) : '-'),
                    cell(
                      t.isIncome ? 'รายรับ' : 'รายจ่าย',
                      font: ttfBold,
                      color: t.isIncome ? PdfColors.green : PdfColors.red,
                    ),
                    cell(
                      '${t.isIncome ? '+' : '-'}${formatter.format(t.amount)}',
                      font: ttfBold,
                      color: t.isIncome ? PdfColors.green : PdfColors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 250,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('รวมรายรับ', style: pw.TextStyle(font: ttfBold)),
                      pw.Text(formatter.format(totalIncome),
                          style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('รวมรายจ่าย',
                          style: pw.TextStyle(font: ttfBold)),
                      pw.Text(formatter.format(totalExpense),
                          style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'คงเหลือ',
                        style: pw.TextStyle(font: ttfBold, fontSize: 14),
                      ),
                      pw.Text(
                        formatter.format(balance),
                        style: pw.TextStyle(font: ttfBold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute("download", "report.pdf")
        ..click();

      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final file = io.File("${dir.path}/report.pdf");

      await file.writeAsBytes(bytes, flush: true);

      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            name: 'report.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'รายงานรายรับรายจ่าย',
        text: 'รายงานรายรับรายจ่าย',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double balance = totalIncome - totalExpense;
    final formatter = NumberFormat('#,###.##');

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายรับรายจ่าย'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickDate,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
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
                const Text(
                  'ยอดคงเหลือ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${formatter.format(balance)} บาท',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    if (transactions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ไม่มีข้อมูลสำหรับสร้าง PDF'),
                        ),
                      );
                      return;
                    }

                    await generateAndSharePdf(context, transactions);
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('แชร์ PDF'),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "วันที่: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final t = filteredTransactions[index];
                final realIndex = transactions.indexOf(t);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: ListTile(
                    onTap: () {
                      showEditDialog(realIndex, t);
                    },
                    leading: CircleAvatar(
                      backgroundColor:
                          t.isIncome ? Colors.greenAccent : Colors.redAccent,
                      child: Icon(
                        t.isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      t.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      t.isIncome
                          ? 'รายรับเข้า ${formatter.format(t.incomeAmount)} บาท'
                          : '${t.quantity} ชิ้น x ${formatter.format(t.pricePerItem)} บาท',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${t.isIncome ? '+' : '-'} ${formatter.format(t.amount)} บาท',
                          style: TextStyle(
                            color: t.isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('ยืนยันการลบ'),
                                content: Text('ต้องการลบ "${t.title}" ใช่ไหม?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('ยกเลิก'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        transactions.removeAt(realIndex);
                                      });

                                      Navigator.pop(context);
                                    },
                                    child: const Text('ลบ'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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