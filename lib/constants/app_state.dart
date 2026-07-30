import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/product_faq_model.dart';
import '../models/wishlist_model.dart';
import '../models/cart_model.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/product_faq_service.dart';
import '../services/wishlist_service.dart';
import '../services/cart_service.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';
import '../models/shipping_address_model.dart';
import '../services/shipping_address_service.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

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
  String? itemId;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.prescriptionFile,
    this.itemId,
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
  final String? orderNo;
  final String? paymentMode;
  final String? deliveryAddress;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.discount,
    this.status = 'Placed',
    required this.orderDate,
    this.orderNo,
    this.paymentMode,
    this.deliveryAddress,
  });
}

class Clinic {
  final String id;
  final String name;
  final String image;
  final double rating;
  final String location;
  final String specialty;
  final List<String> availableServices;
  final int doctorsCount;
  final bool isVerified;
  final bool isPremium;
  final double fee;
  final bool availableToday;
  final bool availableThisWeek;

  const Clinic({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.location,
    required this.specialty,
    required this.availableServices,
    required this.doctorsCount,
    this.isVerified = false,
    this.isPremium = false,
    required this.fee,
    this.availableToday = true,
    this.availableThisWeek = true,
  });
}

class AppState extends ChangeNotifier {
  // Singleton Pattern
  AppState._internal() {
    fetchProductsFromApi();
  }
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  bool _isLoggedIn = false;
  String? _authToken;
  String? _doctorToken;
  UserModel? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  String? get authToken => _authToken;
  String? get doctorToken => _doctorToken;
  UserModel? get currentUser => _currentUser;
  bool get isDoctorLoggedIn => _doctorToken != null && _doctorToken!.isNotEmpty;

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _doctorToken = prefs.getString('doctor_token');
    final userStr = prefs.getString('user_data');

    if (_authToken != null && userStr != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userStr));
        _isLoggedIn = true;
        fetchUserWishlistProducts();
        fetchCartFromApi();
        fetchShippingAddresses();
        fetchMyOrders();
      } catch (e) {
        _isLoggedIn = false;
      }
    }
    notifyListeners();
  }

  Future<void> setDoctorToken(String token) async {
    _doctorToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_token', token);
    notifyListeners();
  }

  Future<void> clearDoctorSession() async {
    _doctorToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('doctor_token');
    notifyListeners();
  }

  Future<void> setSession({required String token, required UserModel user}) async {
    _isLoggedIn = true;
    _authToken = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    fetchUserWishlistProducts();
    fetchCartFromApi();
    fetchShippingAddresses();
    fetchMyOrders();
    notifyListeners();
  }

  Future<UserModel?> fetchUserProfile() async {
    if (_authToken == null || _authToken!.isEmpty) return null;
    final profileRes = await AuthService.getUserProfile(token: _authToken!);
    if (profileRes.success && profileRes.user != null) {
      _currentUser = profileRes.user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
    }
    return _currentUser;
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _authToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }

  // Active User Lists
  final List<CartItem> _cart = [];
  final List<String> _wishlistProductIds = [];
  final List<String> _wishlistDoctorIds = [];
  final List<Appointment> _appointments = [];
  final List<Order> _orders = [];
  List<Product> _apiProducts = [];
  bool _isLoadingProducts = false;
  String? _productsError;
  List<UserWishlistProductItem> _userWishlistItems = [];
  bool _isLoadingWishlist = false;
  bool _isLoadingCart = false;

  List<ShippingAddressModel> _shippingAddresses = [];
  ShippingAddressModel? _selectedShippingAddress;
  bool _isLoadingAddresses = false;

  List<MyOrderItem> _myOrders = [];
  bool _isLoadingMyOrders = false;

  List<CartItem> get cart => _cart;
  List<String> get wishlistProductIds => _wishlistProductIds;
  List<String> get wishlistDoctorIds => _wishlistDoctorIds;
  List<Appointment> get appointments => _appointments;
  List<Order> get orders => _orders;
  List<MyOrderItem> get myOrders => _myOrders;
  bool get isLoadingMyOrders => _isLoadingMyOrders;
  List<UserWishlistProductItem> get userWishlistItems => _userWishlistItems;
  bool get isLoadingWishlist => _isLoadingWishlist;
  bool get isLoadingCart => _isLoadingCart;

  List<ShippingAddressModel> get shippingAddresses => _shippingAddresses;
  ShippingAddressModel? get selectedShippingAddress => _selectedShippingAddress;
  bool get isLoadingAddresses => _isLoadingAddresses;

  List<Product> get products => _apiProducts;
  List<Product> get apiProducts => _apiProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;

  Future<void> fetchProductsFromApi({String? categoryId, String? search}) async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    final response = await ProductService.getProducts(
      categoryId: categoryId,
      search: search,
    );
    _isLoadingProducts = false;

    if (response.success) {
      final activeApiProds = response.products
          .where((p) => p.isActive && !p.isDeleted)
          .map((p) => p.toProduct())
          .toList();

      _apiProducts = activeApiProds;
    } else {
      _productsError = response.message ?? 'Failed to load products from API';
    }
    notifyListeners();
  }

  Future<Product?> fetchProductDetails(String productId) async {
    final response = await ProductService.getProductById(productId);
    if (response.success && response.product != null) {
      return response.product!.toProduct();
    }
    return null;
  }

  Future<List<ProductFaqModel>> fetchProductFaqs(String productId) async {
    final response = await ProductFaqService.getFaqsByProductId(productId);
    if (response.success) {
      return response.faqs.where((f) => f.isActive).toList();
    }
    return [];
  }  // Deprecated: System uses live API products exclusively
  final List<Product> mockProducts = [];

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
      about:
          'Dr. Anjali Sharma is a highly esteemed Ayurvedic practitioner dedicated to the principles of holistic healing. With a profound belief in treating the root cause rather than merely managing symptoms, she integrates traditional Ayurvedic wisdom with modern lifestyle adjustments to create personalized wellness plans for her patients.',
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
      about:
          'Dr. Rajesh Patel is a seasoned homeopath with 20+ years of healing practice. He specializes in treating chronic allergies, skin disorders, and autoimmune symptoms through individualistic constitutional treatments.',
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
      about:
          'Dr. Tariq Khan is a dedicated Unani physician focused on natural herbal regimens and bodily humor balance. His therapies offer successful clinical restoration for digestive ailments and metabolism deficiencies.',
    ),
  ];

  final List<Clinic> mockClinics = const [
    Clinic(
      id: 'c1',
      name: 'St. Marina Medical Center',
      image: 'assets/cl1.jpg',
      rating: 4.9,
      location: 'Connaught Place, Delhi',
      specialty: 'Cardiology',
      availableServices: ['Panchkarma', 'IPD', 'Cupping'],
      doctorsCount: 8,
      isVerified: true,
      isPremium: false,
      fee: 1500,
      availableToday: true,
      availableThisWeek: true,
    ),
    Clinic(
      id: 'c2',
      name: 'Apex General Hospital',
      image: 'assets/cl2.jpg',
      rating: 4.7,
      location: 'Sector 18, Noida',
      specialty: 'General Medicine',
      availableServices: ['IPD', 'Leech Therapy', 'Agni Karma'],
      doctorsCount: 12,
      isVerified: false,
      isPremium: true,
      fee: 2500,
      availableToday: true,
      availableThisWeek: true,
    ),
    Clinic(
      id: 'c3',
      name: 'Cedar Skin & Wellness',
      image: 'assets/cl3.jpg',
      rating: 4.8,
      location: 'DLF Cyber City, Gurgaon',
      specialty: 'Dermatology',
      availableServices: ['Kerali Panchkarma', 'Agni Karma'],
      doctorsCount: 6,
      isVerified: true,
      isPremium: false,
      fee: 1800,
      availableToday: false,
      availableThisWeek: true,
    ),
    Clinic(
      id: 'c4',
      name: 'AyurHeal Clinical Care',
      image: 'assets/cl1.jpg',
      rating: 4.6,
      location: 'South Extension, Delhi',
      specialty: 'Pediatrics',
      availableServices: ['Panchkarma', 'Rakt Mokshan'],
      doctorsCount: 10,
      isVerified: true,
      isPremium: false,
      fee: 1200,
      availableToday: true,
      availableThisWeek: true,
    ),
    Clinic(
      id: 'c5',
      name: 'Medicity Oncology & Specialty',
      image: 'assets/cl2.jpg',
      rating: 4.9,
      location: 'Golf Course Road, Gurgaon',
      specialty: 'Oncology',
      availableServices: ['IPD', 'Agni Karma'],
      doctorsCount: 15,
      isVerified: false,
      isPremium: true,
      fee: 3500,
      availableToday: true,
      availableThisWeek: true,
    ),
    Clinic(
      id: 'c6',
      name: 'Vedic Healing Sanctuary',
      image: 'assets/cl3.jpg',
      rating: 4.8,
      location: 'Indirapuram, Ghaziabad',
      specialty: 'Cardiology',
      availableServices: ['Kerali Panchkarma', 'Leech Therapy'],
      doctorsCount: 7,
      isVerified: true,
      isPremium: false,
      fee: 1600,
      availableToday: true,
      availableThisWeek: true,
    ),
  ];

  // Cart Operations
  Future<GetCartApiResponse> fetchCartFromApi() async {
    if (_authToken == null || _authToken!.isEmpty) {
      return GetCartApiResponse(
        success: false,
        message: 'User not authenticated',
      );
    }

    _isLoadingCart = true;
    notifyListeners();

    final response = await CartService.getCart(token: _authToken);
    _isLoadingCart = false;

    if (response.success && response.data != null) {
      final localUnsynced = _cart.where((item) => item.itemId == null).toList();

      List<CartItem> updatedCart = [];
      for (final itemData in response.data!.items) {
        final existingProd = _apiProducts.firstWhere(
          (p) => p.id == itemData.productId,
          orElse: () => Product(
            id: itemData.productId,
            name: itemData.productName ?? 'Product',
            brand: itemData.skuName ?? '',
            image: 'assets/img2.png',
            price: itemData.priceAtAdd,
            originalPrice:
                itemData.mrp > 0 ? itemData.mrp : itemData.priceAtAdd,
            rating: 4.5,
            reviewsCount: 10,
            category: 'General',
            description: '',
          ),
        );

        final localIdx =
            _cart.indexWhere((c) => c.product.id == itemData.productId);
        final String? localPrescription =
            localIdx != -1 ? _cart[localIdx].prescriptionFile : null;

        updatedCart.add(CartItem(
          product: existingProd,
          quantity: itemData.quantity,
          itemId: itemData.id,
          prescriptionFile: localPrescription,
        ));
      }

      for (final unsynced in localUnsynced) {
        if (!updatedCart.any((c) => c.product.id == unsynced.product.id)) {
          updatedCart.add(unsynced);
        }
      }

      _cart.clear();
      _cart.addAll(updatedCart);
    }
    notifyListeners();
    return response;
  }

  Future<AddToCartApiResponse> addToCart(Product product, {int qty = 1}) async {
    final existingIdx = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIdx != -1) {
      _cart[existingIdx].quantity += qty;
    } else {
      _cart.add(CartItem(product: product, quantity: qty));
    }
    notifyListeners();

    if (_authToken != null && _authToken!.isNotEmpty) {
      final response = await CartService.addToCart(
        productId: product.id,
        quantity: qty,
        token: _authToken,
      );

      if (response.success && response.data != null) {
        final idx = _cart.indexWhere((item) => item.product.id == product.id);
        if (idx != -1) {
          _cart[idx].itemId = response.data!.id;
        }
      }
      return response;
    }

    return AddToCartApiResponse(
      success: true,
      message: 'Added to cart locally',
    );
  }

  Future<AddToCartApiResponse> addToCartApi(Product product, {int qty = 1}) async {
    return await addToCart(product, qty: qty);
  }

  Future<CartActionApiResponse?> updateCartQty(Product product, int newQty) async {
    final idx = _cart.indexWhere((item) => item.product.id == product.id);
    if (idx == -1) return null;

    final String? itemId = _cart[idx].itemId;

    if (newQty <= 0) {
      _cart.removeAt(idx);
      notifyListeners();
      if (itemId != null &&
          itemId.isNotEmpty &&
          _authToken != null &&
          _authToken!.isNotEmpty) {
        return await CartService.removeCartItem(
          itemId: itemId,
          token: _authToken,
        );
      }
      return null;
    } else {
      _cart[idx].quantity = newQty;
      notifyListeners();
      if (itemId != null &&
          itemId.isNotEmpty &&
          _authToken != null &&
          _authToken!.isNotEmpty) {
        return await CartService.updateCartItemQuantity(
          itemId: itemId,
          quantity: newQty,
          token: _authToken,
        );
      }
      return null;
    }
  }

  void attachPrescription(Product product, String path) {
    final idx = _cart.indexWhere((item) => item.product.id == product.id);
    if (idx != -1) {
      _cart[idx].prescriptionFile = path;
      notifyListeners();
    }
  }

  Future<CartActionApiResponse?> removeFromCart(Product product) async {
    final idx = _cart.indexWhere((item) => item.product.id == product.id);
    String? itemId;
    if (idx != -1) {
      itemId = _cart[idx].itemId;
      _cart.removeAt(idx);
      notifyListeners();
    }
    if (itemId != null &&
        itemId.isNotEmpty &&
        _authToken != null &&
        _authToken!.isNotEmpty) {
      return await CartService.removeCartItem(
        itemId: itemId,
        token: _authToken,
      );
    }
    return null;
  }

  Future<CartActionApiResponse?> clearCart() async {
    _cart.clear();
    notifyListeners();
    if (_authToken != null && _authToken!.isNotEmpty) {
      return await CartService.clearCart(token: _authToken);
    }
    return null;
  }

  // Wishlist Operations
  Future<WishlistActionResponse> toggleProductWishlist(String productId) async {
    final bool wasInWishlist = _wishlistProductIds.contains(productId);
    if (wasInWishlist) {
      _wishlistProductIds.remove(productId);
    } else {
      _wishlistProductIds.add(productId);
    }
    notifyListeners();

    final response = await WishlistService.toggleWishlist(
      productId: productId,
      token: _authToken,
    );

    if (!response.success) {
      if (wasInWishlist) {
        _wishlistProductIds.add(productId);
      } else {
        _wishlistProductIds.remove(productId);
      }
      notifyListeners();
    }

    return response;
  }

  Future<WishlistActionResponse> addToWishlistApi(String productId) async {
    final response = await WishlistService.addToWishlist(
      productId: productId,
      token: _authToken,
    );
    if (response.success && !_wishlistProductIds.contains(productId)) {
      _wishlistProductIds.add(productId);
      notifyListeners();
    }
    return response;
  }

  Future<WishlistActionResponse> removeFromWishlistApi(String productId) async {
    final response = await WishlistService.removeFromWishlist(
      productId: productId,
      token: _authToken,
    );
    if (response.success && _wishlistProductIds.contains(productId)) {
      _wishlistProductIds.remove(productId);
      notifyListeners();
    }
    return response;
  }

  Future<UserWishlistProductsApiResponse> fetchUserWishlistProducts() async {
    _isLoadingWishlist = true;
    notifyListeners();

    final response = await WishlistService.getUserWishlistProducts(
      token: _authToken,
    );
    _isLoadingWishlist = false;

    if (response.success) {
      _userWishlistItems = response.data;
      _wishlistProductIds.clear();
      for (final item in response.data) {
        if (item.productId.isNotEmpty &&
            !_wishlistProductIds.contains(item.productId)) {
          _wishlistProductIds.add(item.productId);
        }
      }
    }
    notifyListeners();
    return response;
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
  void addAppointment(
    Doctor doctor,
    String date,
    String time,
    String notes, {
    List<String> files = const [],
  }) {
    final id = 'AYC-${100000 + _appointments.length}';
    _appointments.add(
      Appointment(
        id: id,
        doctor: doctor,
        date: date,
        time: time,
        notes: notes,
        uploadedFiles: files,
      ),
    );
    notifyListeners();
  }

  // Order Operations
  Future<MyOrdersApiResponse> fetchMyOrders() async {
    if (_authToken == null || _authToken!.isEmpty) {
      return MyOrdersApiResponse(
        success: false,
        message: 'User not authenticated',
        data: [],
      );
    }
    _isLoadingMyOrders = true;
    notifyListeners();

    final response = await OrderService.getUsersOrders(token: _authToken);
    _isLoadingMyOrders = false;

    if (response.success) {
      _myOrders = response.data;
      _orders.clear();
      for (final item in _myOrders) {
        _orders.add(item.toOrder(_apiProducts));
      }
    }
    notifyListeners();
    return response;
  }

  Future<SingleOrderDetailApiResponse> fetchOrderDetail(String orderId) async {
    return await OrderService.getOrderById(
      orderId: orderId,
      token: _authToken,
    );
  }

  Future<CheckoutApiResponse> checkoutOrder({
    required String shippingAddressId,
    required String paymentMode,
    String paymentStatus = 'pending',
  }) async {
    final response = await OrderService.checkout(
      shippingAddressId: shippingAddressId,
      paymentMode: paymentMode,
      paymentStatus: paymentStatus,
      token: _authToken,
    );

    if (response.success && response.data != null) {
      final newOrder = response.data!.toOrder(_apiProducts);
      _orders.add(newOrder);
      await clearCart();
      await fetchMyOrders();
      notifyListeners();
    }
    return response;
  }

  void placeOrder(double total, double discount) {
    if (_cart.isEmpty) return;
    final orderId = 'OD050${62026100 + _orders.length}';
    _orders.add(
      Order(
        id: orderId,
        items: List.from(_cart),
        totalAmount: total,
        discount: discount,
        orderDate: 'July 16, 2026',
      ),
    );
    clearCart();
    notifyListeners();
  }

  // Rating Operations
  Future<AddRatingResponse> submitRating({
    required String targetId,
    required String targetType,
    required int score,
    required String review,
  }) async {
    final response = await RatingService.addRating(
      targetId: targetId,
      targetType: targetType,
      score: score,
      review: review,
      token: _authToken,
    );
    notifyListeners();
    return response;
  }

  // Shipping Address Operations
  Future<ShippingAddressesApiResponse> fetchShippingAddresses() async {
    if (_authToken == null || _authToken!.isEmpty) {
      return ShippingAddressesApiResponse(
        success: false,
        data: [],
        message: 'User not authenticated',
      );
    }
    _isLoadingAddresses = true;
    notifyListeners();

    final response = await ShippingAddressService.getShippingAddresses(token: _authToken);
    _isLoadingAddresses = false;

    if (response.success) {
      _shippingAddresses = response.data;
      if (_shippingAddresses.isNotEmpty) {
        final defaultAddress = _shippingAddresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _shippingAddresses.first,
        );
        if (_selectedShippingAddress == null ||
            !_shippingAddresses.any((a) => a.id == _selectedShippingAddress!.id)) {
          _selectedShippingAddress = defaultAddress;
        }
      } else {
        _selectedShippingAddress = null;
      }
    }
    notifyListeners();
    return response;
  }

  void selectShippingAddress(ShippingAddressModel address) {
    _selectedShippingAddress = address;
    notifyListeners();
  }

  Future<ShippingAddressApiResponse> addShippingAddress({
    required String fullName,
    required String phone,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    bool isDefault = false,
  }) async {
    final response = await ShippingAddressService.addShippingAddress(
      fullName: fullName,
      phone: phone,
      addressLine: addressLine,
      city: city,
      state: state,
      pincode: pincode,
      landmark: landmark,
      isDefault: isDefault,
      token: _authToken,
    );

    if (response.success && response.data != null) {
      await fetchShippingAddresses();
      if (isDefault || _selectedShippingAddress == null) {
        _selectedShippingAddress = response.data;
      }
    }
    notifyListeners();
    return response;
  }

  Future<ShippingAddressApiResponse> updateShippingAddress({
    required String id,
    required String fullName,
    required String phone,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    bool isDefault = false,
  }) async {
    final response = await ShippingAddressService.updateShippingAddress(
      id: id,
      fullName: fullName,
      phone: phone,
      addressLine: addressLine,
      city: city,
      state: state,
      pincode: pincode,
      landmark: landmark,
      isDefault: isDefault,
      token: _authToken,
    );

    if (response.success) {
      await fetchShippingAddresses();
    }
    notifyListeners();
    return response;
  }

  Future<ShippingAddressActionResponse> deleteShippingAddress(String id) async {
    final response = await ShippingAddressService.deleteShippingAddress(
      id: id,
      token: _authToken,
    );

    if (response.success) {
      _shippingAddresses.removeWhere((a) => a.id == id);
      if (_selectedShippingAddress?.id == id) {
        _selectedShippingAddress = _shippingAddresses.isNotEmpty
            ? (_shippingAddresses.firstWhere((a) => a.isDefault, orElse: () => _shippingAddresses.first))
            : null;
      }
      notifyListeners();
    }
    return response;
  }
}

