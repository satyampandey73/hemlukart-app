import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final String image;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviewsCount;
  final bool isPrescriptionRequired;
  final bool isOutOfStock;
  final String category;
  final String description;
  final String potency;
  final String packSize;
  final String flavour;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewsCount,
    this.isPrescriptionRequired = false,
    this.isOutOfStock = false,
    required this.category,
    required this.description,
    this.potency = '500mg',
    this.packSize = '60 Tabs',
    this.flavour = 'Orange',
  });
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String degree;
  final String system; // Ayurveda, Homeopathy, Unani
  final int experienceYears;
  final double consultationFee;
  final double rating;
  final int reviewsCount;
  final String image;
  final List<String> languages;
  final String clinicName;
  final String clinicAddress;
  final String about;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.degree,
    required this.system,
    required this.experienceYears,
    required this.consultationFee,
    required this.rating,
    required this.reviewsCount,
    required this.image,
    required this.languages,
    required this.clinicName,
    required this.clinicAddress,
    required this.about,
  });
}

class CartItem {
  final Product product;
  int quantity;
  String? prescriptionFile;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.prescriptionFile,
  });
}

class Appointment {
  final String id;
  final Doctor doctor;
  final String date;
  final String time;
  final String notes;
  final String status;
  final List<String> uploadedFiles;

  Appointment({
    required this.id,
    required this.doctor,
    required this.date,
    required this.time,
    required this.notes,
    this.status = 'Confirmed',
    this.uploadedFiles = const [],
  });
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final double discount;
  final String status; // Placed, Confirmed, Dispatched, Delivered
  final String orderDate;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.discount,
    this.status = 'Placed',
    required this.orderDate,
  });
}

class AppState extends ChangeNotifier {
  // Singleton Pattern
  AppState._internal();
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // Active User Lists
  final List<CartItem> _cart = [];
  final List<String> _wishlistProductIds = [];
  final List<String> _wishlistDoctorIds = [];
  final List<Appointment> _appointments = [];
  final List<Order> _orders = [];

  List<CartItem> get cart => _cart;
  List<String> get wishlistProductIds => _wishlistProductIds;
  List<String> get wishlistDoctorIds => _wishlistDoctorIds;
  List<Appointment> get appointments => _appointments;
  List<Order> get orders => _orders;

  // Global Mock Database
  final List<Product> mockProducts = [
    const Product(
      id: 'p1',
      name: 'Ashwagandha Extract 500mg',
      brand: 'Vedic Naturals',
      image: 'assets/img2.png', // Placeholder layout in UI
      price: 450.00,
      originalPrice: 500.00,
      rating: 4.8,
      reviewsCount: 124,
      isPrescriptionRequired: true,
      category: 'Ayurveda',
      description: 'Experience peak vitality with our organic Ashwagandha capsules formulated for maximum stress reduction, energy enhancement, and immune support.',
    ),
    const Product(
      id: 'p2',
      name: 'Himalaya Pain Relief Balm',
      brand: 'Himalaya Wellness',
      image: 'assets/img2.png',
      price: 120.00,
      originalPrice: 150.00,
      rating: 4.6,
      reviewsCount: 89,
      category: 'Ayurveda',
      description: 'Rapid cooling pain relief balm infused with peppermint extracts and essential oil extracts to soothe joint, neck, and back distress.',
    ),
    const Product(
      id: 'p3',
      name: 'Rhuma Oil',
      brand: 'AyurVeda Naturals',
      image: 'assets/img2.png',
      price: 140.00,
      originalPrice: 180.00,
      rating: 4.5,
      reviewsCount: 54,
      category: 'Ayurveda',
      description: 'Traditional Ayurvedic joint and muscle massage oil designed to treat chronic pain, stiffness, and inflammation naturally.',
    ),
    const Product(
      id: 'p4',
      name: 'Yograj Guggul Tablets',
      brand: 'Baidyanath',
      image: 'assets/img2.png',
      price: 360.00,
      originalPrice: 400.00,
      rating: 4.7,
      reviewsCount: 62,
      category: 'Ayurveda',
      description: 'Highly effective Guggul formulation targeting joint health, joint flexibility, and healthy uric acid balance in the body.',
    ),
    const Product(
      id: 'p5',
      name: 'Amoxicillin 500mg',
      brand: 'Medisynth',
      image: 'assets/img2.png',
      price: 185.00,
      originalPrice: 210.00,
      rating: 4.4,
      reviewsCount: 34,
      isPrescriptionRequired: true,
      category: 'Allopathy',
      description: 'Broad-spectrum antibiotic medicine used for treating bacterial infections. To be taken only under clinical consultation.',
    ),
    const Product(
      id: 'p6',
      name: 'Vitality Daily Multivitamin',
      brand: 'GreenLeaf Nutrition',
      image: 'assets/img2.png',
      price: 699.00,
      originalPrice: 999.00,
      rating: 4.8,
      reviewsCount: 2450,
      category: 'Supplements',
      description: 'Premium multivitamin formula enriched with daily essential micronutrients, minerals, and antioxidants for continuous metabolic boost.',
    ),
  ];

  final List<Doctor> mockDoctors = [
    const Doctor(
      id: 'd1',
      name: 'Dr. Anjali Sharma',
      specialty: 'Ayurvedic Internist',
      degree: 'BAMS, MD (Ayurveda)',
      system: 'Ayurveda',
      experienceYears: 12,
      consultationFee: 800.00,
      rating: 4.8,
      reviewsCount: 124,
      image: 'assets/doctor_profile.png',
      languages: ['English', 'Hindi', 'Sanskrit'],
      clinicName: 'AyurHeal Wellness Center',
      clinicAddress: '124 Wellness Blvd, Suite 200, Healthcare District, 90210',
      about: 'Dr. Anjali Sharma is a highly esteemed Ayurvedic practitioner dedicated to the principles of holistic healing. With a profound belief in treating the root cause rather than merely managing symptoms, she integrates traditional Ayurvedic wisdom with modern lifestyle adjustments to create personalized wellness plans for her patients.',
    ),
    const Doctor(
      id: 'd2',
      name: 'Dr. Rajesh Patel',
      specialty: 'Homeopathy Specialist',
      degree: 'BHMS',
      system: 'Homeopathy',
      experienceYears: 20,
      consultationFee: 3000.00,
      rating: 4.9,
      reviewsCount: 215,
      image: 'assets/doctor_profile.png',
      languages: ['English', 'Gujarati', 'Hindi'],
      clinicName: 'Holistic Care Homeopathy Clinic',
      clinicAddress: '45 Lotus Road, Ground Floor, Sector 4, 380009',
      about: 'Dr. Rajesh Patel is a seasoned homeopath with 20+ years of healing practice. He specializes in treating chronic allergies, skin disorders, and autoimmune symptoms through individualistic constitutional treatments.',
    ),
    const Doctor(
      id: 'd3',
      name: 'Dr. Tariq Khan',
      specialty: 'Unani Medicine Expert',
      degree: 'BUMS',
      system: 'Unani',
      experienceYears: 8,
      consultationFee: 2000.00,
      rating: 4.6,
      reviewsCount: 96,
      image: 'assets/doctor_profile.png',
      languages: ['English', 'Urdu'],
      clinicName: 'Avicenna Unani Healing Studio',
      clinicAddress: '78 Shifa Plaza, Aligarh Road, 202001',
      about: 'Dr. Tariq Khan is a dedicated Unani physician focused on natural herbal regimens and bodily humor balance. His therapies offer successful clinical restoration for digestive ailments and metabolism deficiencies.',
    ),
  ];

  // Cart Operations
  void addToCart(Product product, {int qty = 1}) {
    final existingIdx = _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIdx != -1) {
      _cart[existingIdx].quantity += qty;
    } else {
      _cart.add(CartItem(product: product, quantity: qty));
    }
    notifyListeners();
  }

  void updateCartQty(Product product, int newQty) {
    final idx = _cart.indexWhere((item) => item.product.id == product.id);
    if (idx != -1) {
      if (newQty <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx].quantity = newQty;
      }
      notifyListeners();
    }
  }

  void attachPrescription(Product product, String path) {
    final idx = _cart.indexWhere((item) => item.product.id == product.id);
    if (idx != -1) {
      _cart[idx].prescriptionFile = path;
      notifyListeners();
    }
  }

  void removeFromCart(Product product) {
    _cart.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // Wishlist Operations
  void toggleProductWishlist(String productId) {
    if (_wishlistProductIds.contains(productId)) {
      _wishlistProductIds.remove(productId);
    } else {
      _wishlistProductIds.add(productId);
    }
    notifyListeners();
  }

  void toggleDoctorWishlist(String doctorId) {
    if (_wishlistDoctorIds.contains(doctorId)) {
      _wishlistDoctorIds.remove(doctorId);
    } else {
      _wishlistDoctorIds.add(doctorId);
    }
    notifyListeners();
  }

  // Appointment Operations
  void addAppointment(Doctor doctor, String date, String time, String notes, {List<String> files = const []}) {
    final id = 'AYC-${100000 + _appointments.length}';
    _appointments.add(Appointment(
      id: id,
      doctor: doctor,
      date: date,
      time: time,
      notes: notes,
      uploadedFiles: files,
    ));
    notifyListeners();
  }

  // Order Operations
  void placeOrder(double total, double discount) {
    if (_cart.isEmpty) return;
    final orderId = 'OD050${62026100 + _orders.length}';
    _orders.add(Order(
      id: orderId,
      items: List.from(_cart),
      totalAmount: total,
      discount: discount,
      orderDate: 'July 16, 2026',
    ));
    clearCart();
    notifyListeners();
  }
}
