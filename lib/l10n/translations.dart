// Single translation dictionary for EN / HI / MR.
// Key → { 'en': ..., 'hi': ..., 'mr': ... }
// t(key) helper is provided via LocaleScope.of(context).t(key).

const Map<String, Map<String, String>> translations = {
  // ── App-wide ──────────────────────────────────────────────────────────────
  'app_name': {'en': 'MilkRoute', 'hi': 'मिल्करूट', 'mr': 'मिल्करूट'},
  'language': {'en': 'Language', 'hi': 'भाषा', 'mr': 'भाषा'},
  'english': {'en': 'English', 'hi': 'English', 'mr': 'English'},
  'hindi': {'en': 'Hindi', 'hi': 'हिंदी', 'mr': 'हिंदी'},
  'marathi': {'en': 'Marathi', 'hi': 'मराठी', 'mr': 'मराठी'},
  'save': {'en': 'Save', 'hi': 'सेव करें', 'mr': 'सेव करा'},
  'cancel': {'en': 'Cancel', 'hi': 'रद्द करें', 'mr': 'रद्द करा'},
  'close': {'en': 'Close', 'hi': 'बंद करें', 'mr': 'बंद करा'},
  'confirm': {'en': 'Confirm', 'hi': 'पुष्टि करें', 'mr': 'पुष्टी करा'},
  'delete': {'en': 'Delete', 'hi': 'हटाएं', 'mr': 'हटवा'},
  'edit': {'en': 'Edit', 'hi': 'संपादित करें', 'mr': 'संपादित करा'},
  'add': {'en': 'Add', 'hi': 'जोड़ें', 'mr': 'जोडा'},
  'view': {'en': 'View', 'hi': 'देखें', 'mr': 'पहा'},
  'search': {'en': 'Search', 'hi': 'खोजें', 'mr': 'शोधा'},
  'filter': {'en': 'Filter', 'hi': 'फ़िल्टर', 'mr': 'फिल्टर'},
  'download': {'en': 'Download', 'hi': 'डाउनलोड', 'mr': 'डाउनलोड'},
  'print': {'en': 'Print', 'hi': 'प्रिंट करें', 'mr': 'प्रिंट करा'},
  'share': {'en': 'Share', 'hi': 'शेयर करें', 'mr': 'शेअर करा'},
  'back': {'en': 'Back', 'hi': 'वापस', 'mr': 'मागे'},
  'all': {'en': 'All', 'hi': 'सभी', 'mr': 'सर्व'},
  'loading': {'en': 'Loading…', 'hi': 'लोड हो रहा है…', 'mr': 'लोड होत आहे…'},
  'no_data': {
    'en': 'No data found',
    'hi': 'कोई डेटा नहीं मिला',
    'mr': 'कोणताही डेटा आढळला नाही',
  },
  'export': {'en': 'Export', 'hi': 'निर्यात', 'mr': 'निर्यात'},
  'send_reminder': {
    'en': 'Send Reminder',
    'hi': 'रिमाइंडर भेजें',
    'mr': 'रिमाइंडर पाठवा',
  },
  'record_payment': {
    'en': 'Record Payment',
    'hi': 'भुगतान दर्ज करें',
    'mr': 'पेमेंट नोंदवा',
  },
  'generate': {'en': 'Generate', 'hi': 'जनरेट करें', 'mr': 'जनरेट करा'},
  'select_date': {
    'en': 'Select Date',
    'hi': 'तारीख चुनें',
    'mr': 'तारीख निवडा',
  },
  'date_range': {'en': 'Date Range', 'hi': 'तारीख सीमा', 'mr': 'तारीख श्रेणी'},
  'from_date': {'en': 'From', 'hi': 'से', 'mr': 'पासून'},
  'to_date': {'en': 'To', 'hi': 'तक', 'mr': 'पर्यंत'},

  // ── Login / Auth ──────────────────────────────────────────────────────────
  'login': {'en': 'Login', 'hi': 'लॉग इन', 'mr': 'लॉग इन'},
  'logout': {'en': 'Logout', 'hi': 'लॉग आउट', 'mr': 'लॉग आउट'},
  'role_shop': {'en': 'Shop', 'hi': 'दुकान', 'mr': 'दुकान'},
  'role_distributor': {'en': 'Distributor', 'hi': 'वितरक', 'mr': 'वितरक'},
  'mobile_email': {
    'en': 'Mobile / Email',
    'hi': 'मोबाइल / ईमेल',
    'mr': 'मोबाइल / ईमेल',
  },
  'password': {'en': 'Password', 'hi': 'पासवर्ड', 'mr': 'पासवर्ड'},
  'remember_me': {
    'en': 'Remember me',
    'hi': 'मुझे याद रखें',
    'mr': 'मला लक्षात ठेवा',
  },
  'forgot_password': {
    'en': 'Forgot Password?',
    'hi': 'पासवर्ड भूल गए?',
    'mr': 'पासवर्ड विसरलात?',
  },
  'create_account': {
    'en': 'Create Account',
    'hi': 'खाता बनाएं',
    'mr': 'खाते तयार करा',
  },
  'login_tagline': {
    'en': 'Fresh milk. Smart distribution.',
    'hi': 'ताज़ा दूध। स्मार्ट वितरण।',
    'mr': 'ताजे दूध. स्मार्ट वितरण.',
  },
  'trust_shops': {
    'en': 'Shops Onboard',
    'hi': 'दुकानें जुड़ी हैं',
    'mr': 'दुकाने जोडलेल्या',
  },
  'trust_cities': {'en': 'Cities', 'hi': 'शहर', 'mr': 'शहरे'},
  'trust_rating': {'en': 'Rating', 'hi': 'रेटिंग', 'mr': 'रेटिंग'},

  // ── Navigation ────────────────────────────────────────────────────────────
  'nav_dashboard': {'en': 'Dashboard', 'hi': 'डैशबोर्ड', 'mr': 'डॅशबोर्ड'},
  'nav_orders': {'en': 'Orders', 'hi': 'ऑर्डर', 'mr': 'ऑर्डर'},
  'nav_products': {'en': 'Products', 'hi': 'उत्पाद', 'mr': 'उत्पादने'},
  'nav_customers': {'en': 'Customers', 'hi': 'ग्राहक', 'mr': 'ग्राहक'},
  'nav_payments': {'en': 'Payments', 'hi': 'भुगतान', 'mr': 'पेमेंट'},
  'nav_bills': {
    'en': 'Bills & Invoices',
    'hi': 'बिल और चालान',
    'mr': 'बिल आणि चालान',
  },
  'nav_statements': {'en': 'Statements', 'hi': 'विवरण', 'mr': 'विवरण'},
  'nav_reports': {'en': 'Reports', 'hi': 'रिपोर्ट', 'mr': 'अहवाल'},
  'nav_settings': {'en': 'Settings', 'hi': 'सेटिंग', 'mr': 'सेटिंग'},
  'nav_home': {'en': 'Home', 'hi': 'होम', 'mr': 'होम'},
  'nav_cart': {'en': 'Cart', 'hi': 'कार्ट', 'mr': 'कार्ट'},
  'nav_history': {'en': 'History', 'hi': 'इतिहास', 'mr': 'इतिहास'},
  'nav_profile': {'en': 'Profile', 'hi': 'प्रोफ़ाइल', 'mr': 'प्रोफाइल'},
  'nav_notifications': {'en': 'Notifications', 'hi': 'सूचनाएं', 'mr': 'सूचना'},

  // ── Dashboard ─────────────────────────────────────────────────────────────
  'total_shops': {
    'en': 'Total Shops',
    'hi': 'कुल दुकानें',
    'mr': 'एकूण दुकाने',
  },
  'todays_orders': {
    'en': "Today's Orders",
    'hi': 'आज के ऑर्डर',
    'mr': 'आजचे ऑर्डर',
  },
  'todays_sales': {
    'en': "Today's Sales",
    'hi': 'आज की बिक्री',
    'mr': 'आजची विक्री',
  },
  'pending_payments': {
    'en': 'Pending Payments',
    'hi': 'लंबित भुगतान',
    'mr': 'प्रलंबित पेमेंट',
  },
  'outstanding_amount': {
    'en': 'Outstanding',
    'hi': 'बकाया राशि',
    'mr': 'थकबाकी',
  },
  'sales_overview': {
    'en': 'Sales Overview',
    'hi': 'बिक्री अवलोकन',
    'mr': 'विक्री आढावा',
  },
  'payment_summary': {
    'en': 'Payment Summary',
    'hi': 'भुगतान सारांश',
    'mr': 'पेमेंट सारांश',
  },
  'recent_orders': {
    'en': 'Recent Orders',
    'hi': 'हाल के ऑर्डर',
    'mr': 'अलीकडील ऑर्डर',
  },
  'top_products': {
    'en': 'Top Selling Products',
    'hi': 'सर्वाधिक बिकने वाले',
    'mr': 'सर्वाधिक विकले जाणारे',
  },
  'low_stock': {
    'en': 'Low Stock Alert',
    'hi': 'कम स्टॉक अलर्ट',
    'mr': 'कमी स्टॉक अलर्ट',
  },
  'recent_customers': {
    'en': 'Recent Customers',
    'hi': 'हाल के ग्राहक',
    'mr': 'अलीकडील ग्राहक',
  },
  'collected': {'en': 'Collected', 'hi': 'वसूल', 'mr': 'जमा'},
  'pending': {'en': 'Pending', 'hi': 'लंबित', 'mr': 'प्रलंबित'},
  'overdue': {'en': 'Overdue', 'hi': 'अतिदेय', 'mr': 'थकलेले'},
  'view_all': {'en': 'View All', 'hi': 'सभी देखें', 'mr': 'सर्व पहा'},
  '7_day_sales': {
    'en': '7-Day Sales',
    'hi': '7 दिन की बिक्री',
    'mr': '7 दिवसांची विक्री',
  },

  // ── Products ──────────────────────────────────────────────────────────────
  'product_name': {
    'en': 'Product Name',
    'hi': 'उत्पाद का नाम',
    'mr': 'उत्पादनाचे नाव',
  },
  'category': {'en': 'Category', 'hi': 'श्रेणी', 'mr': 'श्रेणी'},
  'pack_size': {'en': 'Pack Size', 'hi': 'पैक साइज़', 'mr': 'पॅक साइज'},
  'unit': {'en': 'Unit', 'hi': 'इकाई', 'mr': 'घटक'},
  'price': {'en': 'Price', 'hi': 'मूल्य', 'mr': 'किंमत'},
  'stock_qty': {'en': 'Stock Qty', 'hi': 'स्टॉक मात्रा', 'mr': 'स्टॉक प्रमाण'},
  'status': {'en': 'Status', 'hi': 'स्थिति', 'mr': 'स्थिती'},
  'description': {'en': 'Description', 'hi': 'विवरण', 'mr': 'वर्णन'},
  'add_product': {
    'en': 'Add Product',
    'hi': 'उत्पाद जोड़ें',
    'mr': 'उत्पादन जोडा',
  },
  'edit_product': {
    'en': 'Edit Product',
    'hi': 'उत्पाद संपादित करें',
    'mr': 'उत्पादन संपादित करा',
  },
  'product_active': {'en': 'Active', 'hi': 'सक्रिय', 'mr': 'सक्रिय'},
  'product_inactive': {'en': 'Inactive', 'hi': 'निष्क्रिय', 'mr': 'निष्क्रिय'},
  'image': {'en': 'Image', 'hi': 'छवि', 'mr': 'प्रतिमा'},
  'upload_image': {
    'en': 'Upload Image',
    'hi': 'छवि अपलोड करें',
    'mr': 'प्रतिमा अपलोड करा',
  },
  'selling_price': {
    'en': 'Selling Price',
    'hi': 'विक्रय मूल्य',
    'mr': 'विक्री किंमत',
  },
  'delete_product': {
    'en': 'Delete Product',
    'hi': 'उत्पाद हटाएं',
    'mr': 'उत्पादन हटवा',
  },
  'seed_products': {
    'en': 'Load Sample Catalog',
    'hi': 'नमूना कैटलॉग लोड करें',
    'mr': 'नमुना कॅटलॉग लोड करा',
  },
  'confirm_delete_product': {
    'en': 'Are you sure you want to delete this product?',
    'hi': 'क्या आप वाकई इस उत्पाद को हटाना चाहते हैं?',
    'mr': 'तुम्हाला नक्की हे उत्पादन हटवायचे आहे का?',
  },
  'cat_milk': {'en': 'Milk', 'hi': 'दूध', 'mr': 'दूध'},
  'cat_curd': {'en': 'Curd', 'hi': 'दही', 'mr': 'दही'},
  'cat_butter': {'en': 'Butter', 'hi': 'मक्खन', 'mr': 'लोणी'},
  'cat_paneer': {'en': 'Paneer', 'hi': 'पनीर', 'mr': 'पनीर'},
  'cat_buttermilk': {'en': 'Buttermilk', 'hi': 'छाछ', 'mr': 'ताक'},
  'cat_other': {'en': 'Other', 'hi': 'अन्य', 'mr': 'इतर'},

  // ── Customers / Shops ──────────────────────────────────────────────────────
  'shop_name': {'en': 'Shop Name', 'hi': 'दुकान का नाम', 'mr': 'दुकानाचे नाव'},
  'owner_name': {'en': 'Owner Name', 'hi': 'मालिक का नाम', 'mr': 'मालकाचे नाव'},
  'phone': {'en': 'Phone', 'hi': 'फ़ोन', 'mr': 'फोन'},
  'address': {'en': 'Address', 'hi': 'पता', 'mr': 'पत्ता'},
  'total_orders': {'en': 'Total Orders', 'hi': 'कुल ऑर्डर', 'mr': 'एकूण ऑर्डर'},
  'total_purchase': {
    'en': 'Total Purchase',
    'hi': 'कुल खरीदारी',
    'mr': 'एकूण खरेदी',
  },
  'paid_amount': {
    'en': 'Paid Amount',
    'hi': 'भुगतान राशि',
    'mr': 'भरलेली रक्कम',
  },
  'outstanding': {'en': 'Outstanding', 'hi': 'बकाया', 'mr': 'थकबाकी'},
  'create_order': {
    'en': 'Create Order',
    'hi': 'ऑर्डर बनाएं',
    'mr': 'ऑर्डर तयार करा',
  },
  'add_shop': {'en': 'Add Shop', 'hi': 'दुकान जोड़ें', 'mr': 'दुकान जोडा'},
  'shop_active': {'en': 'Active', 'hi': 'सक्रिय', 'mr': 'सक्रिय'},
  'shop_inactive': {'en': 'Inactive', 'hi': 'निष्क्रिय', 'mr': 'निष्क्रिय'},
  'customer_profile': {
    'en': 'Customer Profile',
    'hi': 'ग्राहक प्रोफ़ाइल',
    'mr': 'ग्राहक प्रोफाइल',
  },
  'order_history': {
    'en': 'Order History',
    'hi': 'ऑर्डर इतिहास',
    'mr': 'ऑर्डर इतिहास',
  },
  'payment_history': {
    'en': 'Payment History',
    'hi': 'भुगतान इतिहास',
    'mr': 'पेमेंट इतिहास',
  },
  'monthly_purchase': {
    'en': 'Monthly Purchase',
    'hi': 'मासिक खरीदारी',
    'mr': 'मासिक खरेदी',
  },

  // ── Orders ────────────────────────────────────────────────────────────────
  'order_id': {'en': 'Order ID', 'hi': 'ऑर्डर आईडी', 'mr': 'ऑर्डर आईडी'},
  'order_date': {'en': 'Date', 'hi': 'तारीख', 'mr': 'तारीख'},
  'products': {'en': 'Products', 'hi': 'उत्पाद', 'mr': 'उत्पादने'},
  'quantity': {'en': 'Quantity', 'hi': 'मात्रा', 'mr': 'प्रमाण'},
  'total_amount': {'en': 'Total Amount', 'hi': 'कुल राशि', 'mr': 'एकूण रक्कम'},
  'payment_status': {
    'en': 'Payment Status',
    'hi': 'भुगतान स्थिति',
    'mr': 'पेमेंट स्थिती',
  },
  'order_status': {
    'en': 'Order Status',
    'hi': 'ऑर्डर स्थिति',
    'mr': 'ऑर्डर स्थिती',
  },
  'order_new': {'en': 'New', 'hi': 'नया', 'mr': 'नवीन'},
  'order_confirmed': {'en': 'Confirmed', 'hi': 'पुष्टि', 'mr': 'पुष्टी'},
  'order_packed': {'en': 'Packed', 'hi': 'पैक', 'mr': 'पॅक'},
  'order_out_delivery': {
    'en': 'Out for Delivery',
    'hi': 'डिलीवरी पर',
    'mr': 'डिलिव्हरीसाठी',
  },
  'order_delivered': {'en': 'Delivered', 'hi': 'डिलीवर', 'mr': 'डिलिव्हर'},
  'order_cancelled': {'en': 'Cancelled', 'hi': 'रद्द', 'mr': 'रद्द'},
  'pay_paid': {'en': 'Paid', 'hi': 'भुगतान हो गया', 'mr': 'भरले'},
  'pay_partial': {
    'en': 'Partially Paid',
    'hi': 'आंशिक भुगतान',
    'mr': 'अंशतः भरले',
  },
  'pay_pending': {'en': 'Pending', 'hi': 'लंबित', 'mr': 'प्रलंबित'},
  'order_details': {
    'en': 'Order Details',
    'hi': 'ऑर्डर विवरण',
    'mr': 'ऑर्डर तपशील',
  },
  'delivery_address': {
    'en': 'Delivery Address',
    'hi': 'डिलीवरी पता',
    'mr': 'डिलिव्हरी पत्ता',
  },
  'delivery_date': {
    'en': 'Preferred Date',
    'hi': 'पसंदीदा तारीख',
    'mr': 'पसंतीची तारीख',
  },
  'delivery_time': {
    'en': 'Preferred Time',
    'hi': 'पसंदीदा समय',
    'mr': 'पसंतीचा वेळ',
  },
  'place_order': {'en': 'Place Order', 'hi': 'ऑर्डर दें', 'mr': 'ऑर्डर द्या'},
  'order_timeline': {
    'en': 'Order Timeline',
    'hi': 'ऑर्डर टाइमलाइन',
    'mr': 'ऑर्डर टाइमलाइन',
  },

  // ── Cart / Checkout ───────────────────────────────────────────────────────
  'cart': {'en': 'Cart', 'hi': 'कार्ट', 'mr': 'कार्ट'},
  'checkout': {'en': 'Checkout', 'hi': 'चेकआउट', 'mr': 'चेकआउट'},
  'subtotal': {'en': 'Subtotal', 'hi': 'उप-योग', 'mr': 'उप-एकूण'},
  'discount': {'en': 'Discount', 'hi': 'छूट', 'mr': 'सवलत'},
  'tax': {'en': 'Tax', 'hi': 'कर', 'mr': 'कर'},
  'grand_total': {'en': 'Grand Total', 'hi': 'कुल योग', 'mr': 'एकूण बेरीज'},
  'delivery_charge': {
    'en': 'Delivery Charge',
    'hi': 'डिलीवरी शुल्क',
    'mr': 'डिलिव्हरी शुल्क',
  },
  'payment_method': {
    'en': 'Payment Method',
    'hi': 'भुगतान विधि',
    'mr': 'पेमेंट पद्धत',
  },
  'pay_upi': {'en': 'UPI', 'hi': 'UPI', 'mr': 'UPI'},
  'pay_cod': {
    'en': 'Cash on Delivery',
    'hi': 'कैश ऑन डिलीवरी',
    'mr': 'कॅश ऑन डिलिव्हरी',
  },
  'pay_bank': {
    'en': 'Bank Transfer',
    'hi': 'बैंक ट्रांसफर',
    'mr': 'बँक ट्रान्सफर',
  },
  'pay_credit': {
    'en': 'Credit / Outstanding',
    'hi': 'क्रेडिट / बकाया',
    'mr': 'क्रेडिट / थकबाकी',
  },
  'empty_cart': {
    'en': 'Your cart is empty',
    'hi': 'आपका कार्ट खाली है',
    'mr': 'तुमचा कार्ट रिकामा आहे',
  },
  'add_items': {
    'en': 'Add items to get started',
    'hi': 'शुरू करने के लिए आइटम जोड़ें',
    'mr': 'सुरू करण्यासाठी आयटम जोडा',
  },

  // ── Payments ──────────────────────────────────────────────────────────────
  'invoice_no': {'en': 'Invoice No.', 'hi': 'चालान नं.', 'mr': 'चालान क्र.'},
  'amount_due': {'en': 'Amount Due', 'hi': 'देय राशि', 'mr': 'देय रक्कम'},
  'amount_paid': {
    'en': 'Amount Paid',
    'hi': 'भुगतान राशि',
    'mr': 'भरलेली रक्कम',
  },
  'prev_outstanding': {
    'en': 'Previous Outstanding',
    'hi': 'पिछला बकाया',
    'mr': 'मागील थकबाकी',
  },
  'total_payable': {'en': 'Total Payable', 'hi': 'कुल देय', 'mr': 'एकूण देय'},
  'balance_due': {'en': 'Balance Due', 'hi': 'शेष राशि', 'mr': 'शिल्लक रक्कम'},
  'transaction_id': {
    'en': 'Transaction ID',
    'hi': 'ट्रांजेक्शन आईडी',
    'mr': 'व्यवहार आईडी',
  },
  'payment_success': {
    'en': 'Payment Successful',
    'hi': 'भुगतान सफल',
    'mr': 'पेमेंट यशस्वी',
  },
  'view_receipt': {'en': 'View Receipt', 'hi': 'रसीद देखें', 'mr': 'पावती पहा'},
  'download_receipt': {
    'en': 'Download Receipt',
    'hi': 'रसीद डाउनलोड करें',
    'mr': 'पावती डाउनलोड करा',
  },
  'remaining_balance': {
    'en': 'Remaining Balance',
    'hi': 'शेष शेषांश',
    'mr': 'उर्वरित शिल्लक',
  },
  'total_collected': {
    'en': 'Total Collected',
    'hi': 'कुल वसूल',
    'mr': 'एकूण जमा',
  },
  'todays_collection': {
    'en': "Today's Collection",
    'hi': 'आज की वसूली',
    'mr': 'आजची जमा',
  },

  // ── Invoice / Bill ─────────────────────────────────────────────────────────
  'invoice': {'en': 'Invoice', 'hi': 'चालान', 'mr': 'चालान'},
  'bill': {'en': 'Bill', 'hi': 'बिल', 'mr': 'बिल'},
  'invoice_date': {
    'en': 'Invoice Date',
    'hi': 'चालान तारीख',
    'mr': 'चालान तारीख',
  },
  'unit_price': {'en': 'Unit Price', 'hi': 'इकाई मूल्य', 'mr': 'एकक किंमत'},
  'amount': {'en': 'Amount', 'hi': 'राशि', 'mr': 'रक्कम'},
  'gst': {'en': 'GST', 'hi': 'जीएसटी', 'mr': 'जीएसटी'},
  'generate_bill': {
    'en': 'Generate Bill',
    'hi': 'बिल बनाएं',
    'mr': 'बिल तयार करा',
  },
  'download_pdf': {
    'en': 'Download PDF',
    'hi': 'PDF डाउनलोड',
    'mr': 'PDF डाउनलोड',
  },

  // ── Statements ────────────────────────────────────────────────────────────
  'statement': {
    'en': 'Account Statement',
    'hi': 'खाता विवरण',
    'mr': 'खाते विवरण',
  },
  'opening_balance': {
    'en': 'Opening Balance',
    'hi': 'प्रारंभिक शेष',
    'mr': 'उघडणे शिल्लक',
  },
  'closing_balance': {
    'en': 'Closing Balance',
    'hi': 'अंतिम शेष',
    'mr': 'बंद शिल्लक',
  },
  'debit': {'en': 'Debit', 'hi': 'डेबिट', 'mr': 'डेबिट'},
  'credit': {'en': 'Credit', 'hi': 'क्रेडिट', 'mr': 'क्रेडिट'},
  'balance': {'en': 'Balance', 'hi': 'शेष', 'mr': 'शिल्लक'},
  'date': {'en': 'Date', 'hi': 'तारीख', 'mr': 'तारीख'},
  'desc': {'en': 'Description', 'hi': 'विवरण', 'mr': 'वर्णन'},

  // ── Reports ───────────────────────────────────────────────────────────────
  'reports': {'en': 'Reports', 'hi': 'रिपोर्ट', 'mr': 'अहवाल'},
  'daily_sales': {
    'en': 'Daily Sales',
    'hi': 'दैनिक बिक्री',
    'mr': 'दैनिक विक्री',
  },
  'weekly_sales': {
    'en': 'Weekly Sales',
    'hi': 'साप्ताहिक बिक्री',
    'mr': 'साप्ताहिक विक्री',
  },
  'monthly_sales': {
    'en': 'Monthly Sales',
    'hi': 'मासिक बिक्री',
    'mr': 'मासिक विक्री',
  },
  'product_sales': {
    'en': 'Product-wise Sales',
    'hi': 'उत्पाद-वार बिक्री',
    'mr': 'उत्पाद-निहाय विक्री',
  },
  'shop_sales': {
    'en': 'Shop-wise Sales',
    'hi': 'दुकान-वार बिक्री',
    'mr': 'दुकान-निहाय विक्री',
  },
  'collection_report': {
    'en': 'Payment Collection',
    'hi': 'भुगतान संग्रह',
    'mr': 'पेमेंट संकलन',
  },
  'outstanding_report': {
    'en': 'Outstanding Payments',
    'hi': 'बकाया भुगतान',
    'mr': 'थकबाकी पेमेंट',
  },
  'order_volume': {
    'en': 'Order Volume',
    'hi': 'ऑर्डर मात्रा',
    'mr': 'ऑर्डर प्रमाण',
  },

  // ── Notifications ─────────────────────────────────────────────────────────
  'notifications': {'en': 'Notifications', 'hi': 'सूचनाएं', 'mr': 'सूचना'},
  'notif_new_order': {
    'en': 'New Order Received',
    'hi': 'नया ऑर्डर मिला',
    'mr': 'नवीन ऑर्डर मिळाला',
  },
  'notif_order_confirmed': {
    'en': 'Order Confirmed',
    'hi': 'ऑर्डर पुष्टि',
    'mr': 'ऑर्डर पुष्टी',
  },
  'notif_payment_received': {
    'en': 'Payment Received',
    'hi': 'भुगतान मिला',
    'mr': 'पेमेंट मिळाले',
  },
  'notif_payment_pending': {
    'en': 'Payment Pending',
    'hi': 'भुगतान लंबित',
    'mr': 'पेमेंट प्रलंबित',
  },
  'notif_low_stock': {
    'en': 'Low Stock Alert',
    'hi': 'कम स्टॉक अलर्ट',
    'mr': 'कमी स्टॉक अलर्ट',
  },
  'notif_delivery_update': {
    'en': 'Delivery Update',
    'hi': 'डिलीवरी अपडेट',
    'mr': 'डिलिव्हरी अपडेट',
  },
  'notif_new_shop': {
    'en': 'New Shop Added',
    'hi': 'नई दुकान जोड़ी',
    'mr': 'नवीन दुकान जोडली',
  },
  'mark_all_read': {
    'en': 'Mark all as read',
    'hi': 'सभी पढ़े हुए चिह्नित करें',
    'mr': 'सर्व वाचलेले चिन्हांकित करा',
  },

  // ── Shop home / products ──────────────────────────────────────────────────
  'good_morning': {'en': 'Good Morning', 'hi': 'सुप्रभात', 'mr': 'सुप्रभात'},
  'browse_products': {
    'en': 'Browse Products',
    'hi': 'उत्पाद देखें',
    'mr': 'उत्पादने पहा',
  },
  'in_stock': {'en': 'In Stock', 'hi': 'स्टॉक में', 'mr': 'स्टॉकमध्ये'},
  'out_of_stock': {
    'en': 'Out of Stock',
    'hi': 'स्टॉक में नहीं',
    'mr': 'स्टॉक संपला',
  },
  'add_to_cart': {
    'en': 'Add to Cart',
    'hi': 'कार्ट में जोड़ें',
    'mr': 'कार्टमध्ये जोडा',
  },
  'items_in_cart': {
    'en': 'items in cart',
    'hi': 'आइटम कार्ट में',
    'mr': 'आयटम कार्टमध्ये',
  },
  'proceed_checkout': {
    'en': 'Proceed to Checkout',
    'hi': 'चेकआउट पर जाएं',
    'mr': 'चेकआउटवर जा',
  },
  'order_placed': {
    'en': 'Order Placed!',
    'hi': 'ऑर्डर दिया!',
    'mr': 'ऑर्डर दिला!',
  },
  'order_placed_msg': {
    'en': 'Your order has been placed successfully',
    'hi': 'आपका ऑर्डर सफलतापूर्वक दिया गया',
    'mr': 'तुमचा ऑर्डर यशस्वीरित्या दिला गेला',
  },
  'continue_shopping': {
    'en': 'Continue Shopping',
    'hi': 'खरीदारी जारी रखें',
    'mr': 'खरेदी सुरू ठेवा',
  },

  // ── Broadcast to Shops ──────────────────────────────────────────────────
  'broadcast_to_shops': {
    'en': 'Broadcast to Shops',
    'hi': 'दुकानों को संदेश',
    'mr': 'दुकानांना संदेश',
  },
  'broadcast_title': {
    'en': 'Broadcast Announcement',
    'hi': 'प्रसारण घोषणा',
    'mr': 'प्रसारण घोषणा',
  },
  'broadcast_hint': {
    'en': 'Type message to broadcast to all shops…',
    'hi': 'सभी दुकानों के लिए संदेश लिखें…',
    'mr': 'सर्व दुकानांसाठी संदेश लिहा…',
  },
  'send_broadcast': {
    'en': 'Send Broadcast',
    'hi': 'संदेश भेजें',
    'mr': 'संदेश पाठवा',
  },
  'active_broadcast': {
    'en': 'Live Broadcast',
    'hi': 'सक्रिय संदेश',
    'mr': 'सक्रिय संदेश',
  },
  'clear_broadcast': {
    'en': 'Clear Message',
    'hi': 'संदेश हटाएं',
    'mr': 'संदेश काढा',
  },
  'broadcast_sent': {
    'en': 'Broadcast message sent to all shops!',
    'hi': 'सभी दुकानों को संदेश भेजा गया!',
    'mr': 'सर्व दुकानांना संदेश पाठवला!',
  },
  'broadcast_cleared': {
    'en': 'Broadcast cleared',
    'hi': 'संदेश हटा दिया गया',
    'mr': 'संदेश काढला',
  },
  'broadcast_quick_tags': {
    'en': 'Category',
    'hi': 'श्रेणी',
    'mr': 'श्रेणी',
  },
  'broadcast_templates': {
    'en': 'Quick Templates',
    'hi': 'त्वरित संदेश',
    'mr': 'द्रुत संदेश',
  },
};
