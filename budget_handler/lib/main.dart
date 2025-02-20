import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

/// --------------------- MAIN FUNCTION ---------------------
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BudgetProvider(),
      child: const MyApp(),
    ),
  );
}

/// --------------------- ENUM FOR TRANSACTION CATEGORIES ---------------------
enum TransactionCategory { food, transportation, entertainment, other, tech }

/// --------------------- MYAPP CLASS ---------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Handler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          secondary: Colors.green,
          background: Colors.grey.shade100,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// --------------------- TRANSACTION MODEL ---------------------
class Transaction {
  final String title;
  final double amount;
  final DateTime date;
  final TransactionCategory category;
  
  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
}

/// --------------------- BUDGET PROVIDER ---------------------
class BudgetProvider extends ChangeNotifier {
  double _budget = 0;
  final List<Transaction> _transactions = [];
  
  double get budget => _budget;
  List<Transaction> get transactions => _transactions;
  double get totalSpent => _transactions.fold(0, (sum, item) => sum + item.amount);
  double get remainingBudget => _budget - totalSpent;
  
  /// Returns the spending per category.
  Map<TransactionCategory, double> get categorySpending {
    final Map<TransactionCategory, double> map = {};
    for (final transaction in _transactions) {
      map.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return map;
  }
  
  /// Sets the total budget.
  void setBudget(double amount) {
    _budget = amount;
    notifyListeners();
  }
  
  /// Adds a new transaction.
  void addTransaction(String title, double amount, DateTime date, TransactionCategory category) {
    _transactions.add(Transaction(
      title: title,
      amount: amount,
      date: date,
      category: category,
    ));
    notifyListeners();
  }
  
  /// Deletes a transaction at the given index.
  void deleteTransaction(int index) {
    _transactions.removeAt(index);
    notifyListeners();
  }
  
  /// Resets budget and transactions.
  void resetAll() {
    _budget = 0;
    _transactions.clear();
    notifyListeners();
  }
}

/// --------------------- HOMESCREEN CLASS ---------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// --------------------- HOMESCREEN STATE ---------------------
class _HomeScreenState extends State<HomeScreen> {
  // Controllers and keys
  final _transactionFormKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TransactionCategory _selectedCategory = TransactionCategory.other;
  
  final Map<TransactionCategory, Color> categoryColors = {
    TransactionCategory.food: Colors.amber,
    TransactionCategory.transportation: Colors.blue,
    TransactionCategory.entertainment: Colors.pink,
    TransactionCategory.other: Colors.grey,
    TransactionCategory.tech: Colors.teal,
  };
  
  /// --------------------- FUNCTION: _submitTransaction ---------------------
  /// Validates and adds a new transaction. If adding the transaction would exceed the budget,
  /// it shows an error message.
  void _submitTransaction() {
    if (!_transactionFormKey.currentState!.validate()) return;
    
    final provider = context.read<BudgetProvider>();
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    // Check if adding this transaction exceeds the budget.
    if (provider.totalSpent + amount > provider.budget) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Transaction exceeds the remaining budget')),
      );
      return;
    }
    
    if (title.isNotEmpty && amount > 0) {
      provider.addTransaction(
        title,
        amount,
        _selectedDate,
        _selectedCategory,
      );
      _titleController.clear();
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );
    }
  }
  
  /// --------------------- FUNCTION: _selectDate ---------------------
  /// Opens a date picker to select a transaction date.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
  
  /// --------------------- FUNCTION: _buildCategorySelector ---------------------
  /// Builds a dropdown selector for transaction categories.
  Widget _buildCategorySelector() {
    return DropdownButtonFormField<TransactionCategory>(
      value: _selectedCategory,
      items: TransactionCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(Icons.circle, color: categoryColors[category], size: 16),
              const SizedBox(width: 8),
              Text(category.toString().split('.').last),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
      decoration: const InputDecoration(labelText: 'Category'),
    );
  }
  
  /// --------------------- FUNCTION: _buildTransactionList ---------------------
  /// Builds the list of transactions with a delete button for each entry.
  Widget _buildTransactionList() {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.transactions.length,
          itemBuilder: (context, index) {
            final transaction = provider.transactions[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(Icons.circle, color: categoryColors[transaction.category]),
                title: Text(transaction.title),
                subtitle: Text(DateFormat.yMd().format(transaction.date)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '-\$${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.deleteTransaction(index),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  /// --------------------- FUNCTION: _buildPieChart ---------------------
  /// Builds the pie chart showing spending by category and the remaining budget.
  Widget _buildPieChart() {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.budget <= 0) {
          return const Center(child: Text('Please set a budget to view the chart.'));
        }
  
        final totalBudget = provider.budget;
        final categoryData = provider.categorySpending;
        final spent = provider.totalSpent;
        final remaining = provider.remainingBudget;
  
        // If no spending has occurred, display the entire budget as remaining.
        if (spent == 0 && remaining > 0) {
          return Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Spending by Category',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: [
                            PieChartSectionData(
                              value: remaining,
                              title: '${(remaining / totalBudget * 100).toStringAsFixed(1)}%',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              color: Colors.green,
                              radius: 25,
                            ),
                          ],
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.circle, color: Colors.green),
                      title: const Text('Remaining'),
                      trailing: Text('\$${remaining.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
  
        // Build sections for each category plus a section for the remaining budget.
        final sections = [
          ...categoryData.entries.map((entry) {
            return PieChartSectionData(
              value: entry.value,
              title: '${(entry.value / totalBudget * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              color: categoryColors[entry.key],
              radius: 25,
            );
          }),
          if (remaining > 0)
            PieChartSectionData(
              value: remaining,
              title: '${(remaining / totalBudget * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              color: Colors.green,
              radius: 25,
            )
        ];
  
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Spending by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: sections,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...categoryData.entries.map((entry) => ListTile(
                        leading: Icon(Icons.circle, color: categoryColors[entry.key]),
                        title: Text(entry.key.toString().split('.').last),
                        trailing: Text('\$${entry.value.toStringAsFixed(2)}'),
                      )),
                  if (remaining > 0)
                    ListTile(
                      leading: Icon(Icons.circle, color: Colors.green),
                      title: const Text('Remaining'),
                      trailing: Text('\$${remaining.toStringAsFixed(2)}'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// --------------------- FUNCTION: _setBudget ---------------------
  /// Sets the total budget based on user input.
  void _setBudget() {
    final input = _budgetController.text.trim();
    if (input.isNotEmpty && double.tryParse(input) != null) {
      final budgetValue = double.parse(input);
      context.read<BudgetProvider>().setBudget(budgetValue);
      print('Budget set to: $budgetValue'); // Debug statement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget set to \$${budgetValue.toStringAsFixed(2)}')),
      );
      _budgetController.clear();
    } else {
      print('Invalid budget input'); // Debug statement
    }
  }
  
  /// --------------------- FUNCTION: _resetAll ---------------------
  /// Resets the budget and transactions.
  void _resetAll() {
    context.read<BudgetProvider>().resetAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data has been reset')),
    );
  }
  
  /// --------------------- FUNCTION: build ---------------------
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Budget Handler'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Transactions'),
              Tab(icon: Icon(Icons.pie_chart), text: 'Chart'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _resetAll,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset All',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --------------------- BUDGET INPUT SECTION ---------------------
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Set Total Budget',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _setBudget,
                        child: const Text('Set Budget'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const BudgetSummaryCard(),
                  const SizedBox(height: 20),
                  // --------------------- TRANSACTION FORM SECTION ---------------------
                  Form(
                    key: _transactionFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Transaction Title'),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Title required' : null,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Amount'),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter amount';
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) return 'Invalid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildCategorySelector(),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Date: ${DateFormat.yMd().format(_selectedDate)}'),
                            ),
                            TextButton(
                              onPressed: () => _selectDate(context),
                              child: const Text('Choose Date'),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _submitTransaction,
                          child: const Text('Add Transaction'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTransactionList(),
                ],
              ),
            ),
            _buildPieChart(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _resetAll,
          tooltip: 'Reset All',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

/// --------------------- BUDGET SUMMARY CARD ---------------------
class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key});
  
  /// --------------------- FUNCTION: build ---------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final progress = provider.budget > 0 
            ? (provider.totalSpent / provider.budget).clamp(0.0, 1.0)
            : 0.0;
        
        print('Budget: ${provider.budget}'); // Debug statement
        print('Total Spent: ${provider.totalSpent}'); // Debug statement
        print('Remaining Budget: ${provider.remainingBudget}'); // Debug statement
        
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Remaining: \$${provider.remainingBudget.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 0.9 ? Colors.red : Theme.of(context).colorScheme.secondary,
                  ),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Spent: \$${provider.totalSpent.toStringAsFixed(2)}'),
                    Text('Total: \$${provider.budget.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
