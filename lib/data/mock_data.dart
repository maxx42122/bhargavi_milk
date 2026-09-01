// Static mock data — swap with real API/Firestore calls in production.

class MockProduct {
  final String id;
  final String name;
  final String category;
  final String packSize;
  final String unit;
  final double price;
  final int stock;
  final bool active;
  final String description;
  final String emoji;

  const MockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.packSize,
    required this.unit,
    required this.price,
    required this.stock,
    this.active = true,
    this.description = '',
    this.emoji = '🥛',
  });
}

class MockOrder {
  final String id;
  final String shopName;
  final String date;
  final List<String> products;
  final int quantity;
  final double total;
  final String paymentStatus;
  final String orderStatus;

  const MockOrder({
    required this.id,
    required this.shopName,
    required this.date,
    required this.products,
    required this.quantity,
    required this.total,
    required this.paymentStatus,
    required this.orderStatus,
  });
}

class MockShop {
  final String id;
  final String shopName;
  final String ownerName;
  final String phone;
  final String address;
  final int totalOrders;
  final double totalPurchase;
  final double paidAmount;
  final double outstanding;
  final bool active;

  const MockShop({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.totalOrders,
    required this.totalPurchase,
    required this.paidAmount,
    required this.outstanding,
    this.active = true,
  });
}

class MockPayment {
  final String date;
  final String shopName;
  final String invoiceNo;
  final double amount;
  final String method;
  final String transactionId;
  final String status;

  const MockPayment({
    required this.date,
    required this.shopName,
    required this.invoiceNo,
    required this.amount,
    required this.method,
    required this.transactionId,
    required this.status,
  });
}

class MockStatementEntry {
  final String date;
  final String description;
  final String refId;
  final double? debit;
  final double? credit;
  final double balance;

  const MockStatementEntry({
    required this.date,
    required this.description,
    required this.refId,
    this.debit,
    this.credit,
    required this.balance,
  });
}

// ── Data ──────────────────────────────────────────────────────────────────────

final List<MockProduct> mockProducts = [
  const MockProduct(
    id: 'P001',
    name: 'Full Cream Milk',
    category: 'Milk',
    packSize: '500ml',
    unit: 'Pouch',
    price: 28.0,
    stock: 240,
    description: 'Rich and creamy full-fat milk, fresh daily.',
    emoji: '🥛',
  ),
  const MockProduct(
    id: 'P002',
    name: 'Full Cream Milk',
    category: 'Milk',
    packSize: '1L',
    unit: 'Pouch',
    price: 54.0,
    stock: 180,
    description: 'Rich and creamy full-fat milk, 1 litre pack.',
    emoji: '🥛',
  ),
  const MockProduct(
    id: 'P003',
    name: 'Toned Milk',
    category: 'Milk',
    packSize: '500ml',
    unit: 'Pouch',
    price: 24.0,
    stock: 300,
    description: 'Low-fat toned milk, perfect for everyday use.',
    emoji: '🥛',
  ),
  const MockProduct(
    id: 'P004',
    name: 'Toned Milk',
    category: 'Milk',
    packSize: '1L',
    unit: 'Pouch',
    price: 46.0,
    stock: 8,
    description: 'Low-fat toned milk, 1 litre pack.',
    emoji: '🥛',
  ),
  const MockProduct(
    id: 'P005',
    name: 'Fresh Curd',
    category: 'Curd',
    packSize: '500g',
    unit: 'Cup',
    price: 40.0,
    stock: 120,
    description: 'Thick, creamy curd set fresh daily.',
    emoji: '🍶',
  ),
  const MockProduct(
    id: 'P006',
    name: 'Buttermilk',
    category: 'Buttermilk',
    packSize: '500ml',
    unit: 'Bottle',
    price: 22.0,
    stock: 5,
    description: 'Light, refreshing buttermilk with a hint of spice.',
    emoji: '🥤',
  ),
  const MockProduct(
    id: 'P007',
    name: 'Paneer',
    category: 'Paneer',
    packSize: '200g',
    unit: 'Pack',
    price: 90.0,
    stock: 60,
    description: 'Fresh paneer, soft and crumbly.',
    emoji: '🧀',
  ),
  const MockProduct(
    id: 'P008',
    name: 'White Butter',
    category: 'Butter',
    packSize: '100g',
    unit: 'Pack',
    price: 65.0,
    stock: 45,
    description: 'Pure white butter, made from fresh cream.',
    emoji: '🧈',
  ),
];

final List<MockOrder> mockOrders = [
  const MockOrder(
    id: '#ORD-1042',
    shopName: 'Sharma Kirana',
    date: '23 Aug 2026',
    products: ['Full Cream Milk 1L', 'Curd 500g'],
    quantity: 15,
    total: 1200.0,
    paymentStatus: 'Paid',
    orderStatus: 'Delivered',
  ),
  const MockOrder(
    id: '#ORD-1041',
    shopName: 'Patel General Store',
    date: '23 Aug 2026',
    products: ['Toned Milk 500ml'],
    quantity: 30,
    total: 720.0,
    paymentStatus: 'Pending',
    orderStatus: 'Out for Delivery',
  ),
  const MockOrder(
    id: '#ORD-1040',
    shopName: 'Ravi Dairy',
    date: '22 Aug 2026',
    products: ['Full Cream Milk 500ml', 'Buttermilk 500ml'],
    quantity: 20,
    total: 960.0,
    paymentStatus: 'Partially Paid',
    orderStatus: 'Confirmed',
  ),
  const MockOrder(
    id: '#ORD-1039',
    shopName: 'Laxmi Provision',
    date: '22 Aug 2026',
    products: ['Paneer 200g', 'Butter 100g'],
    quantity: 8,
    total: 1240.0,
    paymentStatus: 'Paid',
    orderStatus: 'Packed',
  ),
  const MockOrder(
    id: '#ORD-1038',
    shopName: 'Kumar Mart',
    date: '21 Aug 2026',
    products: ['Toned Milk 1L'],
    quantity: 25,
    total: 1150.0,
    paymentStatus: 'Pending',
    orderStatus: 'New',
  ),
  const MockOrder(
    id: '#ORD-1037',
    shopName: 'City Grocery',
    date: '21 Aug 2026',
    products: ['Full Cream Milk 1L', 'Paneer 200g'],
    quantity: 12,
    total: 1428.0,
    paymentStatus: 'Paid',
    orderStatus: 'Delivered',
  ),
];

final List<MockShop> mockShops = [
  const MockShop(
    id: 'S001',
    shopName: 'Sharma Kirana',
    ownerName: 'Rajesh Sharma',
    phone: '9876543210',
    address: '12, MG Road, Pune',
    totalOrders: 48,
    totalPurchase: 32400.0,
    paidAmount: 30000.0,
    outstanding: 2400.0,
  ),
  const MockShop(
    id: 'S002',
    shopName: 'Patel General Store',
    ownerName: 'Suresh Patel',
    phone: '9812345678',
    address: '5, Station Road, Nashik',
    totalOrders: 35,
    totalPurchase: 21000.0,
    paidAmount: 18000.0,
    outstanding: 3000.0,
  ),
  const MockShop(
    id: 'S003',
    shopName: 'Ravi Dairy',
    ownerName: 'Ravi Kumar',
    phone: '9988776655',
    address: '8, Lal Bahadur Nagar, Mumbai',
    totalOrders: 62,
    totalPurchase: 48600.0,
    paidAmount: 48600.0,
    outstanding: 0.0,
  ),
  const MockShop(
    id: 'S004',
    shopName: 'Laxmi Provision',
    ownerName: 'Anita Verma',
    phone: '9765432100',
    address: '3, Gandhi Chowk, Nagpur',
    totalOrders: 29,
    totalPurchase: 17400.0,
    paidAmount: 12000.0,
    outstanding: 5400.0,
  ),
  const MockShop(
    id: 'S005',
    shopName: 'Kumar Mart',
    ownerName: 'Vijay Kumar',
    phone: '9654321098',
    address: '17, Bus Stand Road, Aurangabad',
    totalOrders: 41,
    totalPurchase: 24600.0,
    paidAmount: 20000.0,
    outstanding: 4600.0,
  ),
];

final List<MockPayment> mockPayments = [
  const MockPayment(
    date: '23 Aug 2026',
    shopName: 'Sharma Kirana',
    invoiceNo: 'INV-1042',
    amount: 1200.0,
    method: 'UPI',
    transactionId: 'TXN9876543',
    status: 'Paid',
  ),
  const MockPayment(
    date: '22 Aug 2026',
    shopName: 'Laxmi Provision',
    invoiceNo: 'INV-1039',
    amount: 1240.0,
    method: 'Bank Transfer',
    transactionId: 'TXN8765432',
    status: 'Paid',
  ),
  const MockPayment(
    date: '22 Aug 2026',
    shopName: 'Ravi Dairy',
    invoiceNo: 'INV-1040',
    amount: 500.0,
    method: 'Cash',
    transactionId: 'CASH001',
    status: 'Partially Paid',
  ),
  const MockPayment(
    date: '21 Aug 2026',
    shopName: 'City Grocery',
    invoiceNo: 'INV-1037',
    amount: 1428.0,
    method: 'UPI',
    transactionId: 'TXN7654321',
    status: 'Paid',
  ),
  const MockPayment(
    date: '21 Aug 2026',
    shopName: 'Patel General Store',
    invoiceNo: 'INV-1041',
    amount: 720.0,
    method: 'Credit',
    transactionId: '—',
    status: 'Pending',
  ),
];

final List<MockStatementEntry> mockStatement = [
  const MockStatementEntry(
    date: '01 Aug 2026',
    description: 'Opening Balance',
    refId: '—',
    balance: 1500.0,
  ),
  const MockStatementEntry(
    date: '03 Aug 2026',
    description: 'Invoice — Full Cream Milk',
    refId: 'INV-1020',
    debit: 840.0,
    balance: 2340.0,
  ),
  const MockStatementEntry(
    date: '05 Aug 2026',
    description: 'Payment Received',
    refId: 'TXN8123456',
    credit: 2340.0,
    balance: 0.0,
  ),
  const MockStatementEntry(
    date: '10 Aug 2026',
    description: 'Invoice — Curd + Buttermilk',
    refId: 'INV-1025',
    debit: 620.0,
    balance: 620.0,
  ),
  const MockStatementEntry(
    date: '12 Aug 2026',
    description: 'Payment Received',
    refId: 'TXN8234567',
    credit: 500.0,
    balance: 120.0,
  ),
  const MockStatementEntry(
    date: '15 Aug 2026',
    description: 'Invoice — Toned Milk',
    refId: 'INV-1030',
    debit: 960.0,
    balance: 1080.0,
  ),
  const MockStatementEntry(
    date: '20 Aug 2026',
    description: 'Payment Received',
    refId: 'TXN8345678',
    credit: 1000.0,
    balance: 80.0,
  ),
  const MockStatementEntry(
    date: '22 Aug 2026',
    description: 'Invoice — Full Cream Milk 1L',
    refId: 'INV-1040',
    debit: 960.0,
    balance: 1040.0,
  ),
  const MockStatementEntry(
    date: '23 Aug 2026',
    description: 'Invoice — Curd 500g',
    refId: 'INV-1042',
    debit: 1200.0,
    balance: 2240.0,
  ),
];

// 7-day bar chart data: [day, amount]
final List<Map<String, dynamic>> salesChartData = [
  {'day': 'Mon', 'amount': 8400.0},
  {'day': 'Tue', 'amount': 6200.0},
  {'day': 'Wed', 'amount': 9800.0},
  {'day': 'Thu', 'amount': 7500.0},
  {'day': 'Fri', 'amount': 11200.0},
  {'day': 'Sat', 'amount': 13400.0},
  {'day': 'Sun', 'amount': 10600.0},
];
