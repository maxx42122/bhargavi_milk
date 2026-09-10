// Single translation dictionary for EN / HI / MR.
// Key → { 'en': ..., 'hi': ..., 'mr': ... }
// t(key) helper is provided via LocaleScope.of(context).t(key).

const Map<String, Map<String, String>> translations = {
  // ── App-wide ──────────────────────────────────────────────────────────────
  'app_name': {'en': 'BVH', 'hi': 'मिल्करूट', 'mr': 'मिल्करूट'},
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
  'today': {'en': 'Today', 'hi': 'आज', 'mr': 'आज'},
  'yesterday': {'en': 'Yesterday', 'hi': 'कल', 'mr': 'काल'},
  'tomorrow': {'en': 'Tomorrow', 'hi': 'कल', 'mr': 'उद्या'},
  'recently': {'en': 'Recently', 'hi': 'हाल ही में', 'mr': 'नुकतेच'},
  'just_now': {'en': 'Just now', 'hi': 'अभी-अभी', 'mr': 'आत्ताच'},

  'select_all': {'en': 'Select All', 'hi': 'सभी चुनें', 'mr': 'सर्व निवडा'},
  'deselect_all': {
    'en': 'Deselect All',
    'hi': 'सभी अचयनित करें',
    'mr': 'सर्व अननिवडा',
  },
  'mark_all_delivered': {
    'en': 'Mark All Delivered',
    'hi': 'सभी डिलीवर मार्क करें',
    'mr': 'सर्व डिलिव्हर्ड चिन्हांकित करा',
  },
  'mark_all_pending': {
    'en': 'Mark All Pending',
    'hi': 'सभी पेंडिंग मार्क करें',
    'mr': 'सर्व प्रलंबित चिन्हांकित करा',
  },

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
  'login_with_google': {
    'en': 'Sign in with Google',
    'hi': 'Google के साथ साइन इन करें',
    'mr': 'Google सह साइन इन करा',
  },
  'dont_have_account': {
    'en': "Don't have an account?",
    'hi': 'क्या आपका खाता नहीं है?',
    'mr': 'खाते नाही का?',
  },
  'already_have_account': {
    'en': 'Already have an account? Login',
    'hi': 'पहले से खाता है? लॉगिन करें',
    'mr': 'आधीच खाते आहे? लॉगिन करा',
  },
  'register_shop': {
    'en': 'Register Shop',
    'hi': 'दुकान रजिस्टर करें',
    'mr': 'दुकान नोंदणी करा',
  },
  'register_distributor': {
    'en': 'Register Distributor',
    'hi': 'वितरक रजिस्टर करें',
    'mr': 'वितरक नोंदणी करा',
  },
  'logout_shop_confirm': {
    'en': 'Are you sure you want to log out of your shop account?',
    'hi': 'क्या आप वाकई अपने दुकान खाते से लॉग आउट करना चाहते हैं?',
    'mr': 'तुम्हाला नक्की तुमच्या दुकान खात्यातून लॉग आउट करायचे आहे का?',
  },
  'logout_dist_confirm': {
    'en': 'Are you sure you want to log out of your distributor account?',
    'hi': 'क्या आप वाकई वितरक खाते से लॉग आउट करना चाहते हैं?',
    'mr': 'तुम्हाला नक्की वितरक खात्यातून लॉग आउट करायचे आहे का?',
  },

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
  'all_stocked': {
    'en': 'All products in stock',
    'hi': 'सभी उत्पाद स्टॉक में हैं',
    'mr': 'सर्व उत्पादने स्टॉकमध्ये आहेत',
  },
  'stock_healthy': {
    'en': 'Stock levels are healthy across all products.',
    'hi': 'सभी उत्पादों का स्टॉक स्तर सही है।',
    'mr': 'सर्व उत्पादनांची स्टॉक पातळी उत्तम आहे.',
  },
  'no_orders_yet': {
    'en': 'No orders received yet',
    'hi': 'अभी तक कोई ऑर्डर नहीं आया',
    'mr': 'अद्याप कोणतेही ऑर्डर नाही',
  },
  'no_orders_sub': {
    'en': 'Real-time orders placed by shops will appear here live.',
    'hi': 'दुकानों द्वारा दिए गए ऑर्डर यहां लाइव दिखाई देंगे।',
    'mr': 'दुकानांनी दिलेले ऑर्डर येथे थेट दिसतील.',
  },
  'no_sales_yet': {
    'en': 'No sales recorded yet',
    'hi': 'अभी तक कोई बिक्री दर्ज नहीं हुई',
    'mr': 'अद्याप कोणतीही विक्री नोंदवलेली नाही',
  },
  'manage_shops_requests': {
    'en': 'Manage your shops and requests',
    'hi': 'अपनी दुकानों और अनुरोधों को प्रबंधित करें',
    'mr': 'तुमची दुकाने आणि विनंत्या व्यवस्थापित करा',
  },
  'dist_orders_mgmt': {
    'en': 'Distributor Orders Management',
    'hi': 'वितरक ऑर्डर प्रबंधन',
    'mr': 'वितरक ऑर्डर व्यवस्थापन',
  },
  'send_reminder_all': {
    'en': 'Send Reminder to All',
    'hi': 'सभी को रिमाइंडर भेजें',
    'mr': 'सर्वांना रिमाइंडर पाठवा',
  },
  'reminder_sent_all': {
    'en': 'Payment reminder sent to all pending shops successfully! ✓',
    'hi': 'सभी लंबित दुकानों को भुगतान रिमाइंडर भेजा गया! ✓',
    'mr': 'सर्व प्रलंबित दुकानांना पेमेंट रिमाइंडर पाठवले! ✓',
  },
  'reminder_sent_shop': {
    'en': 'Payment reminder sent successfully! ✓',
    'hi': 'भुगतान रिमाइंडर सफलतापूर्वक भेजा गया! ✓',
    'mr': 'पेमेंट रिमाइंडर यशस्वीरित्या पाठवले! ✓',
  },
  'payment_reminder': {
    'en': 'Payment Reminder',
    'hi': 'भुगतान रिमाइंडर',
    'mr': 'पेमेंट रिमाइंडर',
  },
  'payment_due_notice': {
    'en': 'Payment Due Notice',
    'hi': 'भुगतान बकाया सूचना',
    'mr': 'पेमेंट बाकी सूचना',
  },
  'remind_me_later': {
    'en': 'Remind Me Later',
    'hi': 'बाद में याद दिलाएं',
    'mr': 'नंतर आठवण करा',
  },
  'pay_now': {
    'en': 'Pay Now',
    'hi': 'अभी भुगतान करें',
    'mr': 'आत्ता पेमेंट करा',
  },
  'pending_dues': {
    'en': 'Pending Dues',
    'hi': 'लंबित बकाया',
    'mr': 'प्रलंबित बाकी',
  },
  'from_distributor': {
    'en': 'From Distributor',
    'hi': 'वितरक की ओर से',
    'mr': 'वितरकाकडून',
  },
  'clear_dues_msg': {
    'en':
        'Please clear your pending payment to ensure continuous dairy supply.',
    'hi':
        'कृपया निरंतर डेयरी आपूर्ति सुनिश्चित करने के लिए अपना बकाया भुगतान करें।',
    'mr':
        'कृपया अखंडित दूध पुरवठा सुनिश्चित करण्यासाठी आपले उर्वरित पेमेंट करा.',
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
  'low_stock_label': {'en': 'Low Stock', 'hi': 'कम स्टॉक', 'mr': 'कमी स्टॉक'},
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

  // ── Product Names & Data Dictionary ────────────────────────────────────────
  'full_cream_milk': {
    'en': 'Full Cream Milk',
    'hi': 'फुल क्रीम दूध',
    'mr': 'फुल क्रीम दूध',
  },
  'toned_milk': {'en': 'Toned Milk', 'hi': 'टोन्ड दूध', 'mr': 'टोन्ड दूध'},
  'fresh_curd': {'en': 'Fresh Curd', 'hi': 'ताज़ा दही', 'mr': 'ताजे दही'},
  'curd': {'en': 'Curd', 'hi': 'दही', 'mr': 'दही'},
  'buttermilk': {'en': 'Buttermilk', 'hi': 'छाछ', 'mr': 'ताक'},
  'paneer': {'en': 'Paneer', 'hi': 'पनीर', 'mr': 'पनीर'},
  'white_butter': {
    'en': 'White Butter',
    'hi': 'सफेद मक्खन',
    'mr': 'पांढरे लोणी',
  },
  'butter': {'en': 'Butter', 'hi': 'मक्खन', 'mr': 'लोणी'},
  'ghee': {'en': 'Ghee', 'hi': 'घी', 'mr': 'तूप'},
  'cow_milk': {'en': 'Cow Milk', 'hi': 'गाय का दूध', 'mr': 'गायीचे दूध'},
  'buffalo_milk': {
    'en': 'Buffalo Milk',
    'hi': 'भैंस का दूध',
    'mr': 'म्हशीचे दूध',
  },
  'cream': {'en': 'Cream', 'hi': 'मलाई', 'mr': 'साय / क्रीम'},
  'sweets': {'en': 'Sweets', 'hi': 'मिठाई', 'mr': 'मिठाई'},

  // ── Categories ────────────────────────────────────────────────────────────
  'cat_all': {'en': 'All', 'hi': 'सभी', 'mr': 'सर्व'},
  'cat_milk': {'en': 'Milk', 'hi': 'दूध', 'mr': 'दूध'},
  'cat_curd': {'en': 'Curd', 'hi': 'दही', 'mr': 'दही'},
  'cat_butter': {'en': 'Butter', 'hi': 'मक्खन', 'mr': 'लोणी'},
  'cat_paneer': {'en': 'Paneer', 'hi': 'पनीर', 'mr': 'पनीर'},
  'cat_ghee': {'en': 'Ghee', 'hi': 'घी', 'mr': 'तूप'},
  'cat_buttermilk': {'en': 'Buttermilk', 'hi': 'छाछ', 'mr': 'ताक'},
  'cat_other': {'en': 'Other', 'hi': 'अन्य', 'mr': 'इतर'},

  // ── Units ─────────────────────────────────────────────────────────────────
  'unit_pouch': {'en': 'Pouch', 'hi': 'पाउच', 'mr': 'पाऊच'},
  'unit_bottle': {'en': 'Bottle', 'hi': 'बोतल', 'mr': 'बाटली'},
  'unit_cup': {'en': 'Cup', 'hi': 'कप', 'mr': 'कप'},
  'unit_pack': {'en': 'Pack', 'hi': 'पैक', 'mr': 'पॅक'},
  'unit_can': {'en': 'Can', 'hi': 'कैन', 'mr': 'कॅन'},
  'unit_kg': {'en': 'Kg', 'hi': 'किग्रा', 'mr': 'किलो'},
  'unit_litre': {'en': 'Litre', 'hi': 'लीटर', 'mr': 'लिटर'},
  'unit_l': {'en': 'L', 'hi': 'L', 'mr': 'L'},
  'unit_ml': {'en': 'ml', 'hi': 'ml', 'mr': 'ml'},
  'unit_g': {'en': 'g', 'hi': 'g', 'mr': 'g'},
  'unit_pcs': {'en': 'pcs', 'hi': 'पीस', 'mr': 'पीस'},
  'unit_boxes': {'en': 'boxes', 'hi': 'बॉक्स', 'mr': 'बॉक्स'},
  'units_left': {'en': 'units left', 'hi': 'इकाइयां शेष', 'mr': 'नग शिल्लक'},
  'items_sold': {'en': 'sold', 'hi': 'बिके', 'mr': 'विकले'},

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
  'requests': {'en': 'Requests', 'hi': 'अनुरोध', 'mr': 'विनंत्या'},
  'approved_partner': {
    'en': 'Approved Partner',
    'hi': 'स्वीकृत भागीदार',
    'mr': 'मंजूर भागीदार',
  },
  'account_summary': {
    'en': 'Account Summary',
    'hi': 'खाता सारांश',
    'mr': 'खाते सारांश',
  },
  'assigned_distributor': {
    'en': 'Assigned Milk Distributor',
    'hi': 'निर्दिष्ट दूध वितरक',
    'mr': 'नियुक्त दूध वितरक',
  },
  'contact_person': {
    'en': 'Contact Person',
    'hi': 'संपर्क व्यक्ति',
    'mr': 'संपर्क व्यक्ती',
  },
  'company': {'en': 'Company', 'hi': 'कंपनी', 'mr': 'कंपनी'},
  'location': {'en': 'Location', 'hi': 'स्थान', 'mr': 'स्थान'},
  'delivery_contact_info': {
    'en': 'Delivery & Contact Information',
    'hi': 'डिलीवरी और संपर्क जानकारी',
    'mr': 'डिलिव्हरी आणि संपर्क माहिती',
  },
  'not_specified': {
    'en': 'Not specified',
    'hi': 'निर्दिष्ट नहीं',
    'mr': 'नमूद केलेले नाही',
  },
  'email': {'en': 'Email', 'hi': 'ईमेल', 'mr': 'ईमेल'},
  'edit_profile': {
    'en': 'Edit Profile',
    'hi': 'प्रोफ़ाइल संपादित करें',
    'mr': 'प्रोफाइल संपादित करा',
  },
  'no_shop_requests': {
    'en': 'No Shop Requests',
    'hi': 'कोई दुकान अनुरोध नहीं',
    'mr': 'कोणतीही दुकान विनंती नाही',
  },
  'no_active_shops': {
    'en': 'No Active Shops',
    'hi': 'कोई सक्रिय दुकान नहीं',
    'mr': 'कोणतीही सक्रिय दुकाने नाहीत',
  },
  'no_shop_requests_sub': {
    'en':
        'When a shop selects you as their distributor, their request will appear here.',
    'hi':
        'जब कोई दुकान आपको अपने वितरक के रूप में चुनेगी, तो उनका अनुरोध यहां दिखाई देगा।',
    'mr':
        'जेव्हा एखादे दुकान तुम्हाला त्यांचा वितरक म्हणून निवडेल, तेव्हा त्यांची विनंती येथे दिसेल.',
  },
  'no_active_shops_sub': {
    'en': 'Approved shops will appear here.',
    'hi': 'स्वीकृत दुकानें यहां दिखाई देंगी।',
    'mr': 'मंजूर केलेली दुकाने येथे दिसतील.',
  },
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
  'qty': {'en': 'Qty', 'hi': 'मात्रा', 'mr': 'प्रमाण'},
  'items': {'en': 'Items', 'hi': 'आइटम', 'mr': 'आयटम'},
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
  'order_prepared': {'en': 'Prepared', 'hi': 'तैयार', 'mr': 'तयार'},
  'order_out_delivery': {
    'en': 'Out for Delivery',
    'hi': 'डिलीवरी पर',
    'mr': 'डिलिव्हरीसाठी',
  },
  'order_delivered': {'en': 'Delivered', 'hi': 'डिलीवर', 'mr': 'डिलिव्हर'},
  'order_completed': {'en': 'Completed', 'hi': 'पूर्ण', 'mr': 'पूर्ण'},
  'order_cancelled': {'en': 'Cancelled', 'hi': 'रद्द', 'mr': 'रद्द'},
  'order_rejected': {'en': 'Rejected', 'hi': 'अस्वीकृत', 'mr': 'नाकारले'},
  'pay_paid': {'en': 'Paid', 'hi': 'भुगतान हो गया', 'mr': 'भरले'},
  'pay_partial': {
    'en': 'Partially Paid',
    'hi': 'आंशिक भुगतान',
    'mr': 'अंशतः भरले',
  },
  'pay_pending': {'en': 'Pending', 'hi': 'लंबित', 'mr': 'प्रलंबित'},
  'pay_failed': {'en': 'Failed', 'hi': 'विफल', 'mr': 'अयशस्वी'},
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
  'expected_delivery': {
    'en': 'Expected Delivery',
    'hi': 'अपेक्षित डिलीवरी',
    'mr': 'अपेक्षित डिलिव्हरी',
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
  'tomorrow_morning': {
    'en': 'Tomorrow Morning',
    'hi': 'कल सुबह',
    'mr': 'उद्या सकाळी',
  },
  'morning_slot': {
    'en': 'Morning (6–9 AM)',
    'hi': 'सुबह (6–9 बजे)',
    'mr': 'सकाळी (६–९ वा.)',
  },
  'shop_orders': {
    'en': 'Shop Orders',
    'hi': 'दुकान ऑर्डर',
    'mr': 'दुकान ऑर्डर',
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
  'pay_cash': {'en': 'Cash', 'hi': 'नकद', 'mr': 'रोख'},
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
  'pay_card': {'en': 'Card', 'hi': 'कार्ड', 'mr': 'कार्ड'},
  'pay_cheque': {'en': 'Cheque', 'hi': 'चेक', 'mr': 'धनादेश / चेक'},
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
  'payment_processed_success': {
    'en': 'Your payment has been processed and recorded successfully.',
    'hi': 'आपका भुगतान सफलतापूर्वक संसाधित और दर्ज कर लिया गया है।',
    'mr': 'तुमचे पेमेंट यशस्वीरित्या प्रक्रिया करून नोंदवले गेले आहे.',
  },
  'make_another_payment': {
    'en': 'Make Another Payment',
    'hi': 'एक और भुगतान करें',
    'mr': 'आणखी एक पेमेंट करा',
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
  'bill_to': {'en': 'Bill To', 'hi': 'बिल पाने वाला', 'mr': 'बिल प्राप्तकर्ता'},
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
  'payment_received': {
    'en': 'Payment Received',
    'hi': 'भुगतान प्राप्त हुआ',
    'mr': 'पेमेंट मिळाले',
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
  'total_sales': {'en': 'Total Sales', 'hi': 'कुल बिक्री', 'mr': 'एकूण विक्री'},
  'avg_order': {'en': 'Avg. Order', 'hi': 'औसत ऑर्डर', 'mr': 'सरासरी ऑर्डर'},

  // ── Days of Week ──────────────────────────────────────────────────────────
  'day_mon': {'en': 'Mon', 'hi': 'सोम', 'mr': 'सोम'},
  'day_tue': {'en': 'Tue', 'hi': 'मंगल', 'mr': 'मंगळ'},
  'day_wed': {'en': 'Wed', 'hi': 'बुध', 'mr': 'बुध'},
  'day_thu': {'en': 'Thu', 'hi': 'गुरु', 'mr': 'गुरू'},
  'day_fri': {'en': 'Fri', 'hi': 'शुक्र', 'mr': 'शुक्र'},
  'day_sat': {'en': 'Sat', 'hi': 'शनि', 'mr': 'शनि'},
  'day_sun': {'en': 'Sun', 'hi': 'रवि', 'mr': 'रवि'},

  // ── Months ────────────────────────────────────────────────────────────────
  'month_jan': {'en': 'Jan', 'hi': 'जन', 'mr': 'जाने'},
  'month_feb': {'en': 'Feb', 'hi': 'फर', 'mr': 'फेब्रु'},
  'month_mar': {'en': 'Mar', 'hi': 'मार्च', 'mr': 'मार्च'},
  'month_apr': {'en': 'Apr', 'hi': 'अप्रैल', 'mr': 'एप्रिल'},
  'month_may': {'en': 'May', 'hi': 'मई', 'mr': 'मे'},
  'month_jun': {'en': 'Jun', 'hi': 'जून', 'mr': 'जून'},
  'month_jul': {'en': 'Jul', 'hi': 'जुलाई', 'mr': 'जुलै'},
  'month_aug': {'en': 'Aug', 'hi': 'अगस्त', 'mr': 'ऑगस्ट'},
  'month_sep': {'en': 'Sep', 'hi': 'सित', 'mr': 'सप्टें'},
  'month_oct': {'en': 'Oct', 'hi': 'अक्टू', 'mr': 'ऑक्टो'},
  'month_nov': {'en': 'Nov', 'hi': 'नव', 'mr': 'नोव्हें'},
  'month_dec': {'en': 'Dec', 'hi': 'दिस', 'mr': 'डिसें'},

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
  'unread': {'en': 'unread', 'hi': 'अपठित', 'mr': 'न वाचलेले'},
  'all_caught_up': {
    'en': 'All caught up',
    'hi': 'सब कुछ पढ़ा हुआ है',
    'mr': 'सर्व वाचून पूर्ण',
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
  'no_matching_products': {
    'en': 'No matching products',
    'hi': 'कोई मेल खाते उत्पाद नहीं',
    'mr': 'कोणतीही जुळणारी उत्पादने नाहीत',
  },
  'reset_filter': {
    'en': 'Reset filter',
    'hi': 'फ़िल्टर रीसेट करें',
    'mr': 'फिल्टर रीसेट करा',
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
  'broadcast_quick_tags': {'en': 'Category', 'hi': 'श्रेणी', 'mr': 'श्रेणी'},
  'broadcast_templates': {
    'en': 'Quick Templates',
    'hi': 'त्वरित संदेश',
    'mr': 'द्रुत संदेश',
  },
  'tag_notice': {'en': 'Notice', 'hi': 'सूचना', 'mr': 'सूचना'},
  'tag_delivery': {'en': 'Delivery', 'hi': 'डिलीवरी', 'mr': 'डिलिव्हरी'},
  'tag_stock': {'en': 'Stock', 'hi': 'स्टॉक', 'mr': 'स्टॉक'},
  'tag_urgent': {'en': 'Urgent', 'hi': 'अति आवश्यक', 'mr': 'तातडीचे'},
  'tag_offer': {'en': 'Offer', 'hi': 'ऑफ़र', 'mr': 'ऑफर'},
  'tag_price': {'en': 'Price', 'hi': 'मूल्य', 'mr': 'किंमत'},
  'tag_holiday': {'en': 'Holiday', 'hi': 'छुट्टी', 'mr': 'सुट्टी'},
  'tag_rate': {'en': 'Rate', 'hi': 'दर', 'mr': 'दर'},
  'broadcast_auto_24h_notice': {
    'en': 'Messages automatically disappear after 24 hours',
    'hi': 'संदेश 24 घंटे बाद अपने आप हट जाते हैं',
    'mr': 'संदेश 24 तासांनंतर आपोआप हटवले जातात',
  },
  'broadcast_expires_in': {
    'en': 'Expires in',
    'hi': 'समाप्ति',
    'mr': 'कालबाह्य',
  },
  'broadcast_sent_24h': {
    'en': 'Broadcast sent! Active on shop dashboards for 24 hours.',
    'hi': 'संदेश भेजा गया! सभी दुकानों पर 24 घंटे तक सक्रिय रहेगा।',
    'mr': 'संदेश पाठवला! सर्व दुकानांवर 24 तासांसाठी सक्रिय राहील.',
  },
  'broadcast_active_24h': {
    'en': 'Live on shop dashboards (Auto-deletes in 24 hrs)',
    'hi': 'दुकानों पर सक्रिय (24 घंटे में स्वतः हट जाएगा)',
    'mr': 'दुकानांवर थेट (24 तासांत आपोआप हटवले जाईल)',
  },
  'broadcast_idle_24h': {
    'en': 'Send instant announcement to shops (24h validity)',
    'hi': 'दुकानों को तुरंत संदेश भेजें (24 घंटे की वैधता)',
    'mr': 'दुकानांना त्वरित संदेश पाठवा (24 तास वैधता)',
  },

  // ── Total Orders & Brand Summary ──────────────────────────────────────────
  'total_orders_summary': {
    'en': 'Total Orders Summary',
    'hi': 'कुल ऑर्डर सारांश',
    'mr': 'एकूण ऑर्डर्स सारांश',
  },
  'total_orders_brand_summary': {
    'en': 'Brand-Wise Product Summary',
    'hi': 'ब्रांड-वार उत्पाद सारांश',
    'mr': 'ब्रँड-निहाय उत्पादन सारांश',
  },
  'view_total_orders': {
    'en': 'Total Orders',
    'hi': 'कुल ऑर्डर',
    'mr': 'एकूण ऑर्डर्स',
  },
  'view_brand_wise_quantities': {
    'en': 'Brand-wise 500ml/1L quantities, rupees & PDF export',
    'hi': 'ब्रांड-वार 500ml/1L मात्रा, आय और PDF डाउनलोड',
    'mr': 'ब्रँड-निहाय 500ml/1L प्रमाण, रक्कम आणि PDF डाउनलोड',
  },
  'total_quantity': {
    'en': 'Total Quantity',
    'hi': 'कुल मात्रा',
    'mr': 'एकूण प्रमाण',
  },
  'total_rupees': {'en': 'Total Rupees', 'hi': 'कुल राशि', 'mr': 'एकूण रक्कम'},
  'brand_name': {
    'en': 'Brand Name',
    'hi': 'ब्रांड का नाम',
    'mr': 'ब्रँडचे नाव',
  },
  'product_variant': {
    'en': 'Product / Variant',
    'hi': 'उत्पाद / प्रकार',
    'mr': 'उत्पादन / प्रकार',
  },
  'no_orders_matching': {
    'en': 'No orders found matching the selected filter.',
    'hi': 'चयनित फ़िल्टर के लिए कोई ऑर्डर नहीं मिला।',
    'mr': 'निवडलेल्या फिल्टरसाठी कोणतीही ऑर्डर सापडली नाही.',
  },

  // ── Extra Auth, Invoice & Notification keys ───────────────────────────────
  'required': {'en': 'Required', 'hi': 'आवश्यक', 'mr': 'आवश्यक'},
  'enter_email': {
    'en': 'Enter email',
    'hi': 'ईमेल दर्ज करें',
    'mr': 'ईमेल प्रविष्ट करा',
  },
  'enter_valid_email': {
    'en': 'Enter a valid email',
    'hi': 'वैध ईमेल दर्ज करें',
    'mr': 'वैध ईमेल प्रविष्ट करा',
  },
  'enter_password': {
    'en': 'Enter password',
    'hi': 'पासवर्ड दर्ज करें',
    'mr': 'पासवर्ड प्रविष्ट करा',
  },
  'enter_valid_mobile': {
    'en': 'Enter valid mobile',
    'hi': 'वैध मोबाइल नंबर दर्ज करें',
    'mr': 'वैध मोबाईल नंबर प्रविष्ट करा',
  },
  'passwords_not_match': {
    'en': 'Passwords do not match',
    'hi': 'पासवर्ड मेल नहीं खाते',
    'mr': 'पासवर्ड जुळत नाहीत',
  },
  'approval_pending': {
    'en': 'Approval Pending',
    'hi': 'अनुमोदन लंबित',
    'mr': 'मंजुरी प्रलंबित',
  },
  'approval_pending_desc': {
    'en':
        'Your shop registration has been sent to the selected distributor.\n\nYou can login, but you cannot access the shop dashboard until the distributor approves your request.',
    'hi':
        'आपके दुकान का पंजीकरण चयनित वितरक को भेज दिया गया है।\n\nआप लॉगिन कर सकते हैं, लेकिन वितरक द्वारा आपके अनुरोध को स्वीकृत करने तक आप दुकान डैशबोर्ड का उपयोग नहीं कर सकते।',
    'mr':
        'तुमची दुकान नोंदणी निवडलेल्या वितरकाकडे पाठवली गेली आहे.\n\nतुम्ही लॉगिन करू शकता, परंतु वितरकाने तुमची विनंती मंजूर करेपर्यंत तुम्ही दुकान डॅशबोर्ड वापरू शकत नाही.',
  },
  'reg_rejected': {
    'en': 'Registration Rejected',
    'hi': 'पंजीकरण अस्वीकृत',
    'mr': 'नोंदणी नाकारली',
  },
  'reg_rejected_desc': {
    'en':
        'Your shop registration request was rejected by the distributor.\n\nPlease contact the distributor for more information.',
    'hi':
        'आपका दुकान पंजीकरण अनुरोध वितरक द्वारा अस्वीकार कर दिया गया था।\n\nकृपया अधिक जानकारी के लिए वितरक से संपर्क करें।',
    'mr':
        'तुमची दुकान नोंदणी विनंती वितरकाने नाकारली आहे.\n\nकृपया अधिक माहितीसाठी वितरकाशी संपर्क साधा.',
  },
  'request_sent': {
    'en': 'Request Sent',
    'hi': 'अनुरोध भेजा गया',
    'mr': 'विनंती पाठवली',
  },
  'loading_distributors': {
    'en': 'Loading distributors...',
    'hi': 'वितरक लोड हो रहे हैं...',
    'mr': 'वितरक लोड होत आहेत...',
  },
  'no_distributors_found': {
    'en': 'No distributors found in system.',
    'hi': 'सिस्टम में कोई वितरक नहीं मिला।',
    'mr': 'प्रणालीमध्ये कोणताही वितरक आढळला नाही.',
  },
  'distributor_registration': {
    'en': 'Distributor Registration',
    'hi': 'वितरक पंजीकरण',
    'mr': 'वितरक नोंदणी',
  },
  'create_distributor_account': {
    'en': 'Create your distributor account',
    'hi': 'अपना वितरक खाता बनाएं',
    'mr': 'तुमचे वितरक खाते तयार करा',
  },
  'register_as_distributor': {
    'en': 'Register as Distributor',
    'hi': 'वितरक के रूप में पंजीकरण करें',
    'mr': 'वितरक म्हणून नोंदणी करा',
  },
  'company_name': {
    'en': 'Company Name',
    'hi': 'कंपनी का नाम',
    'mr': 'कंपनीचे नाव',
  },
  'distributor_name': {
    'en': 'Distributor Name',
    'hi': 'वितरक का नाम',
    'mr': 'वितरकाचे नाव',
  },
  'mobile_number': {
    'en': 'Mobile Number',
    'hi': 'मोबाइल नंबर',
    'mr': 'मोबाईल नंबर',
  },
  'confirm_password': {
    'en': 'Confirm Password',
    'hi': 'पासवर्ड की पुष्टि करें',
    'mr': 'पासवर्डची पुष्टी करा',
  },
  'or': {'en': 'or', 'hi': 'या', 'mr': 'किंवा'},
  'continue_with_google': {
    'en': 'Continue with Google',
    'hi': 'Google के साथ जारी रखें',
    'mr': 'Google सह सुरू ठेवा',
  },
  'ok': {'en': 'OK', 'hi': 'ठीक है', 'mr': 'ठीक आहे'},
  'retry': {
    'en': 'Retry',
    'hi': 'पुनः प्रयास करें',
    'mr': 'पुन्हा प्रयत्न करा',
  },
  'refresh': {'en': 'Refresh', 'hi': 'रिफ्रेश करें', 'mr': 'रिफ्रेश करा'},
  'today_orders': {
    'en': "Today's Orders",
    'hi': 'आज के ऑर्डर',
    'mr': 'आजच्या ऑर्डर्स',
  },
  'total_today_orders': {
    'en': "Total Today's Orders",
    'hi': 'आज के कुल ऑर्डर',
    'mr': 'आजच्या एकूण ऑर्डर्स',
  },
  'customer_checklist': {
    'en': 'Customer Checklist',
    'hi': 'ग्राहक चेकलिस्ट',
    'mr': 'ग्राहक चेकलिस्ट',
  },
  'customer_wise_list': {
    'en': 'Customer-Wise List',
    'hi': 'ग्राहक वार सूची',
    'mr': 'ग्राहकनिहाय यादी',
  },
  'brand_wise_summary': {
    'en': 'Brand-Wise Totals',
    'hi': 'ब्रांड वार योग',
    'mr': 'ब्रँडनिहाय बेरीज',
  },
  'delivery_checklist': {
    'en': 'Delivery Checklist',
    'hi': 'डिलीवरी चेकलिस्ट',
    'mr': 'वितरण चेकलिस्ट',
  },
  'items_ordered': {
    'en': 'Items Ordered',
    'hi': 'ऑर्डर किए गए आइटम',
    'mr': 'मागवलेले आयटम',
  },
};
