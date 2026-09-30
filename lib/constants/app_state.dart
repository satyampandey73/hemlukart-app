import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
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
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../models/doctor_model.dart';
import '../models/clinic_model.dart';
import '../models/my_appointments_model.dart';
import '../services/appointment_service.dart';
import '../services/doctor_auth_service.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ProductVariant {
  final String id;
  final String packSize;
  final double price;
  final double originalPrice;
  final String? skuCode;
  final bool isOutOfStock;
  final double? doctorDiscount;
  final bool? doctorActive;
  final double? consumerDiscount;
  final bool? consumerActive;

  const ProductVariant({
    required this.id,
    required this.packSize,
    required this.price,
    required this.originalPrice,
    this.skuCode,
    this.isOutOfStock = false,
    this.doctorDiscount,
    this.doctorActive,
    this.consumerDiscount,
    this.consumerActive,
  });
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String image;
  final double? _basePrice;
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
  final double? _doctorDiscount;
  final bool? _doctorActive;
  final double? _consumerDiscount;
  final bool? _consumerActive;
  final List<ProductVariant> variants;
  // Selected variant's SKU ID — sent to backend when adding to cart
  final String? skuId;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.image,
    required double price,
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
    double? doctorDiscount,
    bool? doctorActive,
    double? consumerDiscount,
    bool? consumerActive,
    this.variants = const [],
    this.skuId,
  })  : _basePrice = price,
        _doctorDiscount = doctorDiscount,
        _doctorActive = doctorActive,
        _consumerDiscount = consumerDiscount,
        _consumerActive = consumerActive;

  double get basePrice => _basePrice ?? 0.0;
  double get doctorDiscount => _doctorDiscount ?? 0.0;
  bool get doctorActive => _doctorActive ?? true;
  double get consumerDiscount => _consumerDiscount ?? 0.0;
  bool get consumerActive => _consumerActive ?? true;

  /// Effective price evaluated dynamically based on active role (Doctor vs Patient)
  double get price {
    final bp = basePrice;
    if (AppState().isDoctorLoggedIn) {
      if (doctorActive && doctorDiscount > 0) {
        final docP = (originalPrice - doctorDiscount).clamp(0.0, originalPrice);
        return docP > 0 ? docP : bp;
      }
      // If doctor is logged in and doctor discount not explicitly specified,
      // apply 15% professional doctor role discount.
      final docP = (originalPrice * 0.85).roundToDouble();
      return (docP < bp) ? docP : bp;
    }
    // Patient role
    if (consumerActive && consumerDiscount > 0) {
      final consumerP = (originalPrice - consumerDiscount).clamp(0.0, originalPrice);
      return consumerP > 0 ? consumerP : bp;
    }
    return bp;
  }

  /// Returns effective discount amount for current user role
  double get effectiveDiscount {
    if (AppState().isDoctorLoggedIn) {
      if (doctorActive && doctorDiscount > 0) {
        return doctorDiscount;
      }
      final calculated = (originalPrice - price).clamp(0.0, originalPrice);
      return calculated > 0 ? calculated : (originalPrice * 0.15).roundToDouble();
    }
    if (consumerActive && consumerDiscount > 0) {
      return consumerDiscount;
    }
    return (originalPrice - price).clamp(0.0, originalPrice);
  }

  /// Returns discount percentage for current user role
  int get effectiveDiscountPercent {
    if (originalPrice <= 0) return 0;
    final disc = (originalPrice - price).clamp(0.0, originalPrice);
    return ((disc / originalPrice) * 100).round();
  }

  /// Role discount label to display on badges
  String get roleDiscountLabel {
    if (AppState().isDoctorLoggedIn) {
      final pct = effectiveDiscountPercent;
      return pct > 0 ? 'Dr. $pct% OFF' : 'Doctor Special';
    } else {
      final pct = effectiveDiscountPercent;
      return pct > 0 ? '$pct% OFF' : '';
    }
  }

  /// Returns available bottle/pack variants for this product from the backend.
  List<ProductVariant> get availableVariants {
    if (variants.isNotEmpty) return variants;

    return [
      ProductVariant(
        id: id,
        packSize: packSize.trim().isNotEmpty ? packSize : '1 Unit',
        price: price,
        originalPrice: originalPrice,
        isOutOfStock: isOutOfStock,
        doctorDiscount: _doctorDiscount,
        doctorActive: _doctorActive,
        consumerDiscount: _consumerDiscount,
        consumerActive: _consumerActive,
      ),
    ];
  }

  /// Creates a copy of this product with the selected variant's attributes.
  /// Stores variant.id as skuId ONLY if it differs from productId.
  /// When the dummy fallback variant (id==productId) is used, skuId stays null
  /// so CartService doesn't send a redundant/wrong skuId to the backend.
  Product copyWithVariant(ProductVariant variant) {
    return Product(
      id: id,
      name: name,
      brand: brand,
      image: image,
      price: variant.price,
      originalPrice: variant.originalPrice,
      rating: rating,
      reviewsCount: reviewsCount,
      isPrescriptionRequired: isPrescriptionRequired,
      isOutOfStock: variant.isOutOfStock,
      category: category,
      description: description,
      potency: potency,
      packSize: variant.packSize,
      flavour: flavour,
      doctorDiscount: variant.doctorDiscount ?? _doctorDiscount,
      doctorActive: variant.doctorActive ?? _doctorActive,
      consumerDiscount: variant.consumerDiscount ?? _consumerDiscount,
      consumerActive: variant.consumerActive ?? _consumerActive,
      variants: variants,
      // Only store skuId if variant has a real/distinct ID (not the dummy fallback)
      skuId: variant.id.isNotEmpty && variant.id != id
          ? variant.id
          : (skuId != null && skuId!.isNotEmpty && skuId != id ? skuId : null),
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String degree;
  final String system; // Ayurveda, Homeopathy, Unani
  final int experienceYears;
  final double consultationFee;
  final List<DoctorConsultationFee> consultationFees;
  final double rating;
  final int reviewsCount;
  final String image;
  final List<String> languages;
  final String clinicName;
  final String clinicAddress;
  final String? clinicId;
  final String about;
  final ApiDoctor? rawApiDoctor;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.degree,
    required this.system,
    required this.experienceYears,
    required this.consultationFee,
    this.consultationFees = const [],
    required this.rating,
    required this.reviewsCount,
    required this.image,
    required this.languages,
    required this.clinicName,
    required this.clinicAddress,
    this.clinicId,
    required this.about,
    this.rawApiDoctor,
  });

  double getFeeForType([String? type]) {
    if (consultationFees.isNotEmpty) {
      if (type != null && type.isNotEmpty) {
        final reqType = type.toLowerCase().trim();
        final match = consultationFees.firstWhere((f) {
          final t = f.consultationType.toLowerCase().trim();
          if (reqType == 'in_person' || reqType == 'offline') {
            return t == 'in_person' ||
                t == 'in-person' ||
                t.contains('person') ||
                t.contains('clinic');
          }
          if (reqType == 'video' || reqType == 'online') {
            return t == 'video' ||
                t == 'online' ||
                t.contains('video') ||
                t.contains('online');
          }
          return t == reqType || t.contains(reqType);
        }, orElse: () => consultationFees.first);
        final parsed = double.tryParse(match.fee);
        if (parsed != null && parsed > 0) return parsed;
      } else {
        final parsed = double.tryParse(consultationFees.first.fee);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return consultationFee;
  }

  List<DoctorSchedule> get schedules => rawApiDoctor?.schedules ?? [];

  bool get hasInPerson {
    if (rawApiDoctor == null) return true;
    final scheds = rawApiDoctor?.schedules ?? [];
    if (scheds.isEmpty) return false;

    return scheds.any((s) {
      if (!s.isAvailable) return false;
      final t = s.consultationType.toLowerCase().trim();
      return t == 'in_person' ||
          t == 'in-person' ||
          t == 'inperson' ||
          t.contains('person') ||
          t.contains('clinic') ||
          t.contains('offline');
    });
  }

  bool get hasOnline {
    if (rawApiDoctor == null) return true;
    final scheds = rawApiDoctor?.schedules ?? [];
    if (scheds.isEmpty) return false;

    return scheds.any((s) {
      if (!s.isAvailable) return false;
      final t = s.consultationType.toLowerCase().trim();
      return t == 'video' ||
          t == 'online' ||
          t == 'audio' ||
          t == 'chat' ||
          t.contains('video') ||
          t.contains('online') ||
          t.contains('audio') ||
          t.contains('chat') ||
          t.contains('tele');
    });
  }

  factory Doctor.fromApiDoctor(
    ApiDoctor apiDoc, {
    double? rating,
    int? reviewsCount,
  }) {
    String nameStr = apiDoc.fullName.trim();
    if (nameStr.isEmpty) nameStr = 'Dr. Practitioner';
    if (!nameStr.toLowerCase().startsWith('dr.')) {
      nameStr = 'Dr. $nameStr';
    }

    String sys = 'Ayurveda';
    final rawSys = (apiDoc.ayushSystem ?? '').toLowerCase();
    if (rawSys.contains('homeopathy')) {
      sys = 'Homeopathy';
    } else if (rawSys.contains('unani')) {
      sys = 'Unani';
    } else if (rawSys.contains('ayurveda')) {
      sys = 'Ayurveda';
    } else if (apiDoc.ayushSystem != null &&
        apiDoc.ayushSystem!.trim().isNotEmpty) {
      sys = apiDoc.ayushSystem!.trim();
    }

    String spec = apiDoc.highestQualification?.specialization ?? '';
    if (spec.isEmpty) {
      if (apiDoc.expertise?.areasOfExpertise != null &&
          apiDoc.expertise!.areasOfExpertise!.isNotEmpty) {
        spec = apiDoc.expertise!.areasOfExpertise!.join(', ');
      } else {
        spec = 'Ayush Specialist';
      }
    }

    String deg = apiDoc.highestQualification?.degree ?? '';
    if (deg.isEmpty) {
      deg = apiDoc.ayushSystem ?? 'BAMS';
    }

    String img = apiDoc.documents?.profilePhoto ?? '';
    if (img.trim().isEmpty) {
      img = apiDoc.documents?.registrationCertificate ?? '';
    }

    String cName = apiDoc.currentClinicOrHospital ?? '';
    if (cName.trim().isEmpty) {
      cName = apiDoc.city != null && apiDoc.city!.trim().isNotEmpty
          ? '${apiDoc.city} Wellness Clinic'
          : 'Ayush Care Clinic';
    }

    List<String> addrParts = [
      if (apiDoc.address != null && apiDoc.address!.trim().isNotEmpty)
        apiDoc.address!.trim(),
      if (apiDoc.city != null && apiDoc.city!.trim().isNotEmpty)
        apiDoc.city!.trim(),
      if (apiDoc.state != null && apiDoc.state!.trim().isNotEmpty)
        apiDoc.state!.trim(),
      if (apiDoc.pinCode != null && apiDoc.pinCode!.trim().isNotEmpty)
        apiDoc.pinCode!.trim(),
    ];
    String cAddr = addrParts.isNotEmpty
        ? addrParts.join(', ')
        : 'Main Hospital Road';

    String abt = apiDoc.about ?? '';
    if (abt.trim().isEmpty) {
      abt = apiDoc.consultationPhilosophy ?? '';
    }
    if (abt.trim().isEmpty) {
      abt =
          'Experienced Ayush practitioner dedicated to patient wellness and holistic healing.';
    }

    String? clinicIdValue;
    for (final schedule in apiDoc.schedules ?? <DoctorSchedule>[]) {
      if (schedule.clinicId != null && schedule.clinicId!.trim().isNotEmpty) {
        clinicIdValue = schedule.clinicId!.trim();
        break;
      }
    }

    List<DoctorConsultationFee> cFees = apiDoc.consultationFees ?? [];
    double dynamicFee = 500.0;
    if (cFees.isNotEmpty) {
      for (final f in cFees) {
        final parsed = double.tryParse(f.fee);
        if (parsed != null && parsed > 0) {
          dynamicFee = parsed;
          break;
        }
      }
    }
    if (dynamicFee == 500.0 &&
        apiDoc.schedules != null &&
        apiDoc.schedules!.isNotEmpty) {
      for (final s in apiDoc.schedules!) {
        final parsed = double.tryParse(s.consultationFee);
        if (parsed != null && parsed > 0) {
          dynamicFee = parsed;
          break;
        }
      }
    }

    return Doctor(
      id: apiDoc.id,
      name: nameStr,
      specialty: spec,
      degree: deg,
      system: sys,
      experienceYears: apiDoc.totalExperience ?? 5,
      consultationFee: dynamicFee,
      consultationFees: cFees,
      rating: rating ?? 4.8,
      reviewsCount: reviewsCount ?? 124,
      image: img,
      languages:
          (apiDoc.expertise?.consultationLanguages != null &&
              apiDoc.expertise!.consultationLanguages!.isNotEmpty)
          ? apiDoc.expertise!.consultationLanguages!
          : ['English', 'Hindi'],
      clinicName: cName,
      clinicAddress: cAddr,
      clinicId: clinicIdValue,
      about: abt,
      rawApiDoctor: apiDoc,
    );
  }
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
  final double shippingCharge;
  final String status; // Placed, Confirmed, Dispatched, Delivered
  final String orderDate;
  final String? orderNo;
  final String? paymentMode;
  final String? deliveryAddress;
  final String? prescription;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.discount,
    this.shippingCharge = 0.0,
    this.status = 'Placed',
    required this.orderDate,
    this.orderNo,
    this.paymentMode,
    this.deliveryAddress,
    this.prescription,
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
  final ApiClinic? rawApiClinic;

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
    this.rawApiClinic,
  });

  factory Clinic.fromApiClinic(ApiClinic apiClinic) {
    String nameStr = apiClinic.clinicName.trim();
    if (nameStr.isEmpty) nameStr = 'Care Clinic';

    List<String> locParts = [
      if (apiClinic.address != null && apiClinic.address!.trim().isNotEmpty)
        apiClinic.address!.trim(),
      if (apiClinic.city != null && apiClinic.city!.trim().isNotEmpty)
        apiClinic.city!.trim(),
      if (apiClinic.state != null && apiClinic.state!.trim().isNotEmpty)
        apiClinic.state!.trim(),
      if (apiClinic.pincode != null && apiClinic.pincode!.trim().isNotEmpty)
        apiClinic.pincode!.trim(),
    ];
    String locationStr = locParts.isNotEmpty
        ? locParts.join(', ')
        : 'Main Market Area';

    String imgUrl = 'assets/clinical_marketplace.jpg';
    if (apiClinic.images != null &&
        apiClinic.images!.isNotEmpty &&
        apiClinic.images!.first.trim().isNotEmpty) {
      imgUrl = apiClinic.images!.first.trim();
    }

    return Clinic(
      id: apiClinic.id,
      name: nameStr,
      image: imgUrl,
      rating: 4.8,
      location: locationStr,
      specialty: 'General Clinic',
      availableServices: const [
        'In-Person Consult',
        'Ayush Therapy',
        'Diagnostics',
        'Pharmacy',
      ],
      doctorsCount: 8,
      isVerified: apiClinic.isActive ?? true,
      isPremium: true,
      fee: 799.0,
      availableToday: true,
      availableThisWeek: true,
      rawApiClinic: apiClinic,
    );
  }
}

class AppState extends ChangeNotifier {
  // Singleton Pattern
  AppState._internal() {
    fetchProductsFromApi();
    fetchCoupons();
  }
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  bool _isNotificationScheduled = false;

  @override
  void notifyListeners() {
    try {
      final binding = WidgetsBinding.instance;
      if (binding.schedulerPhase != SchedulerPhase.idle &&
          binding.schedulerPhase != SchedulerPhase.postFrameCallbacks) {
        if (!_isNotificationScheduled) {
          _isNotificationScheduled = true;
          binding.addPostFrameCallback((_) {
            _isNotificationScheduled = false;
            super.notifyListeners();
          });
        }
        return;
      }
    } catch (_) {}
    super.notifyListeners();
  }

  bool _isLoggedIn = false;
  String? _authToken;
  String? _doctorToken;
  UserModel? _currentUser;
  ApiDoctor? _currentDoctorProfile;

  bool get isLoggedIn => _isLoggedIn || isDoctorLoggedIn;
  String? get authToken => _authToken;
  String? get doctorToken => _doctorToken;
  String? get activeToken => (_authToken != null && _authToken!.isNotEmpty) ? _authToken : _doctorToken;
  UserModel? get currentUser {
    if (_currentUser != null) return _currentUser;
    if (_currentDoctorProfile != null) {
      final docName = _currentDoctorProfile!.fullName.trim();
      final phone = _currentDoctorProfile!.mobile ?? '';
      return UserModel(
        id: _currentDoctorProfile!.id,
        fullName: docName.startsWith('Dr.') ? docName : 'Dr. $docName',
        mobile: phone,
        whatsappNumber: phone,
        email: _currentDoctorProfile!.email ?? '',
        role: 'doctor',
        address: _currentDoctorProfile!.address,
        city: _currentDoctorProfile!.city,
        state: _currentDoctorProfile!.state,
        pincode: _currentDoctorProfile!.pinCode,
        isMobileVerified: _currentDoctorProfile!.isMobileVerified ?? true,
        isActive: _currentDoctorProfile!.isActive ?? true,
      );
    }
    return null;
  }
  ApiDoctor? get currentDoctorProfile => _currentDoctorProfile;
  void setCurrentDoctorProfile(ApiDoctor doc) {
    _currentDoctorProfile = doc;
    notifyListeners();
  }
  bool get isDoctorLoggedIn => _doctorToken != null && _doctorToken!.isNotEmpty;

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _doctorToken = prefs.getString('doctor_token');
    final userStr = prefs.getString('user_data');

    if (_doctorToken != null && _doctorToken!.isNotEmpty) {
      fetchDoctorProfile();
      fetchDoctorAppointments();
      fetchUnreadChatCount();
      startChatPolling();
      fetchCartFromApi();
      fetchShippingAddresses();
      fetchMyOrders();
    }

    if (_authToken != null && userStr != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userStr));
        _isLoggedIn = true;
        fetchUserWishlistProducts();
        fetchUserWishlistDoctors();
        fetchCartFromApi();
        fetchShippingAddresses();
        fetchMyOrders();
        fetchUnreadChatCount();
        startChatPolling();
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
    fetchDoctorProfile();
    fetchDoctorAppointments();
    fetchUnreadChatCount();
    startChatPolling();
    fetchCartFromApi();
    fetchShippingAddresses();
    fetchMyOrders();
    notifyListeners();
  }

  Future<void> clearDoctorSession() async {
    _doctorToken = null;
    _currentDoctorProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('doctor_token');
    _cart.clear();
    _orders.clear();
    _myOrders.clear();
    _shippingAddresses.clear();
    notifyListeners();
  }

  Future<ApiDoctor?> fetchDoctorProfile() async {
    if (_doctorToken == null || _doctorToken!.isEmpty) return null;
    final res = await DoctorAuthService.getProfile(token: _doctorToken!);
    if (res.success && res.doctor != null) {
      _currentDoctorProfile = res.doctor;
      notifyListeners();
    }
    return _currentDoctorProfile;
  }

  Future<void> setSession({
    required String token,
    required UserModel user,
  }) async {
    _isLoggedIn = true;
    _authToken = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    fetchUserWishlistProducts();
    fetchUserWishlistDoctors();
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

  Future<UpdateProfileResponse> updateUserProfile({
    required String fullName,
    required String email,
    required String mobile,
    required String dateOfBirth,
    required String gender,
    required String address,
    required String city,
    required String state,
    required String pincode,
    File? profileImage,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      return UpdateProfileResponse(success: false, message: 'Not authenticated');
    }
    final res = await AuthService.updateProfile(
      token: _authToken!,
      fullName: fullName,
      email: email,
      mobile: mobile,
      dateOfBirth: dateOfBirth,
      gender: gender,
      address: address,
      city: city,
      state: state,
      pincode: pincode,
      profileImage: profileImage,
    );
    if (res.success && res.user != null) {
      _currentUser = res.user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
    }
    return res;
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
  List<UserWishlistDoctorItem> _userWishlistDoctorItems = [];
  bool _isLoadingDoctorWishlist = false;
  bool _isLoadingCart = false;

  List<ShippingAddressModel> _shippingAddresses = [];
  ShippingAddressModel? _selectedShippingAddress;
  bool _isLoadingAddresses = false;

  List<MyOrderItem> _myOrders = [];
  bool _isLoadingMyOrders = false;

  List<UserAppointmentItem> _myAppointments = [];
  bool _isLoadingMyAppointments = false;

  List<UserAppointmentItem> _doctorAppointments = [];
  bool _isLoadingDoctorAppointments = false;

  List<CouponModel> _coupons = [];
  bool _isLoadingCoupons = false;
  CouponModel? _appliedCoupon;

  List<CartItem> get cart => _cart;

  int getProductQuantity(String productId, {String? packSize}) {
    final idx = _cart.indexWhere((item) =>
        item.product.id == productId &&
        (packSize == null || item.product.packSize == packSize));
    return idx != -1 ? _cart[idx].quantity : 0;
  }

  List<String> get wishlistProductIds => _wishlistProductIds;
  List<String> get wishlistDoctorIds => _wishlistDoctorIds;
  List<Appointment> get appointments => _appointments;
  List<Order> get orders => _orders;
  List<MyOrderItem> get myOrders => _myOrders;
  bool get isLoadingMyOrders => _isLoadingMyOrders;
  List<UserAppointmentItem> get myAppointments => _myAppointments;
  bool get isLoadingMyAppointments => _isLoadingMyAppointments;
  List<UserAppointmentItem> get doctorAppointments => _doctorAppointments;
  bool get isLoadingDoctorAppointments => _isLoadingDoctorAppointments;

  Future<List<UserAppointmentItem>> fetchDoctorAppointments({String? status}) async {
    if (_doctorToken == null || _doctorToken!.isEmpty) return [];
    _isLoadingDoctorAppointments = true;
    notifyListeners();

    final res = await AppointmentService.getDoctorAppointments(
      token: _doctorToken!,
      status: status,
      limit: 100,
    );

    _isLoadingDoctorAppointments = false;
    if (res.success) {
      _doctorAppointments = res.appointments;
    }
    notifyListeners();
    return _doctorAppointments;
  }

  Future<SingleAppointmentApiResponse> confirmDoctorAppointment(String appointmentId) async {
    if (_doctorToken == null || _doctorToken!.isEmpty) {
      return SingleAppointmentApiResponse(success: false, message: 'Doctor is not logged in');
    }
    final res = await AppointmentService.confirmDoctorAppointment(
      appointmentId: appointmentId,
      token: _doctorToken!,
    );
    if (res.success) {
      await fetchDoctorAppointments();
    }
    return res;
  }

  Future<SingleAppointmentApiResponse> completeDoctorAppointment(String appointmentId) async {
    if (_doctorToken == null || _doctorToken!.isEmpty) {
      return SingleAppointmentApiResponse(success: false, message: 'Doctor is not logged in');
    }
    final res = await AppointmentService.completeDoctorAppointment(
      appointmentId: appointmentId,
      token: _doctorToken!,
    );
    if (res.success) {
      await fetchDoctorAppointments();
    }
    return res;
  }

  int _unreadChatCount = 0;
  int get unreadChatCount => _unreadChatCount;
  Timer? _chatPollingTimer;

  void Function(int count)? onNewChatNotification;

  String? get activeChatToken => (_doctorToken != null && _doctorToken!.isNotEmpty) ? _doctorToken : _authToken;

  void startChatPolling() {
    _chatPollingTimer?.cancel();
    // Poll unread messages count every 6 seconds
    _chatPollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      fetchUnreadChatCount();
    });
  }

  void stopChatPolling() {
    _chatPollingTimer?.cancel();
    _chatPollingTimer = null;
  }

  Future<int> fetchUnreadChatCount() async {
    final token = activeChatToken;
    if (token == null || token.isEmpty) return 0;
    final res = await ChatService.getUnreadCount(token: token);
    if (res.success) {
      final int previousCount = _unreadChatCount;
      _unreadChatCount = res.unreadCount;
      notifyListeners();

      if (_unreadChatCount > previousCount) {
        onNewChatNotification?.call(_unreadChatCount);
      }
    }
    return _unreadChatCount;
  }

  Future<SendMessageApiResponse> sendChatMessage({
    required String appointmentId,
    required String message,
  }) async {
    final token = activeChatToken;
    if (token == null || token.isEmpty) {
      return SendMessageApiResponse(success: false, message: 'You are not logged in');
    }
    final res = await ChatService.sendMessage(
      appointmentId: appointmentId,
      message: message,
      token: token,
    );
    fetchUnreadChatCount();
    return res;
  }

  Future<ChatMessagesApiResponse> fetchChatMessages(String appointmentId) async {
    final token = activeChatToken;
    if (token == null || token.isEmpty) {
      return ChatMessagesApiResponse(success: false, messages: [], message: 'Not logged in');
    }
    return await ChatService.getMessages(
      appointmentId: appointmentId,
      token: token,
    );
  }

  Future<ChatThreadsApiResponse> fetchChatThreads() async {
    final token = activeChatToken;
    if (token == null || token.isEmpty) {
      return ChatThreadsApiResponse(success: false, threads: [], message: 'Not logged in');
    }
    return await ChatService.getThreads(token: token);
  }

  Future<void> markChatMessagesRead(String appointmentId) async {
    final token = activeChatToken;
    if (token == null || token.isEmpty) return;
    final ok = await ChatService.markMessagesAsRead(
      appointmentId: appointmentId,
      token: token,
    );
    if (ok) {
      fetchUnreadChatCount();
    }
  }

  Future<Map<String, dynamic>> uploadConsultationDocument({
    required String appointmentId,
    required String description,
    required String filePath,
  }) async {
    final token = activeChatToken;
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'You are not logged in'};
    }
    return await ChatService.uploadDocument(
      appointmentId: appointmentId,
      description: description,
      filePath: filePath,
      token: token,
    );
  }

  Future<List<ConsultationDocumentModel>> fetchConsultationDocuments(String appointmentId) async {
    final token = activeChatToken;
    if (token == null || token.isEmpty) return [];
    return await ChatService.getDocuments(
      appointmentId: appointmentId,
      token: token,
    );
  }

  List<UserWishlistProductItem> get userWishlistItems => _userWishlistItems;
  bool get isLoadingWishlist => _isLoadingWishlist;
  List<UserWishlistDoctorItem> get userWishlistDoctorItems =>
      _userWishlistDoctorItems;
  bool get isLoadingDoctorWishlist => _isLoadingDoctorWishlist;
  bool get isLoadingCart => _isLoadingCart;

  List<CouponModel> get coupons => _coupons;
  bool get isLoadingCoupons => _isLoadingCoupons;
  CouponModel? get appliedCoupon => _appliedCoupon;

  List<ShippingAddressModel> get shippingAddresses => _shippingAddresses;
  ShippingAddressModel? get selectedShippingAddress => _selectedShippingAddress;
  bool get isLoadingAddresses => _isLoadingAddresses;

  int _productsCurrentPage = 1;
  int _productsTotalPages = 1;
  int _productsTotalCount = 0;
  bool _isLoadingMoreProducts = false;

  int get productsCurrentPage => _productsCurrentPage;
  int get productsTotalPages => _productsTotalPages;
  int get productsTotalCount => _productsTotalCount;
  bool get isLoadingMoreProducts => _isLoadingMoreProducts;
  bool get hasMoreProducts => _productsCurrentPage < _productsTotalPages;

  List<Product> get products => _apiProducts;
  List<Product> get apiProducts => _apiProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;

  Future<void> fetchProductsFromApi({
    String? categoryId,
    String? search,
    int page = 1,
    int? limit,
  }) async {
    if (page == 1) {
      _isLoadingProducts = true;
      _productsError = null;
      notifyListeners();
    } else {
      _isLoadingMoreProducts = true;
      notifyListeners();
    }

    final response = await ProductService.getProducts(
      categoryId: categoryId,
      search: search,
      page: page,
      limit: limit,
    );
    _isLoadingProducts = false;
    _isLoadingMoreProducts = false;

    if (response.success) {
      final activeApiProds = response.products
          .where((p) => p.isActive && !p.isDeleted)
          .map((p) => p.toProduct())
          .toList();

      if (response.pagination != null) {
        _productsCurrentPage = response.pagination!['page'] is int
            ? response.pagination!['page']
            : int.tryParse(response.pagination!['page']?.toString() ?? '1') ?? 1;
        _productsTotalPages = response.pagination!['pages'] is int
            ? response.pagination!['pages']
            : int.tryParse(response.pagination!['pages']?.toString() ?? '1') ?? 1;
        _productsTotalCount = response.pagination!['total'] is int
            ? response.pagination!['total']
            : int.tryParse(response.pagination!['total']?.toString() ?? '0') ?? 0;
      } else {
        _productsCurrentPage = page;
      }

      if (page == 1) {
        _apiProducts = activeApiProds;
      } else {
        final existingIds = _apiProducts.map((p) => p.id).toSet();
        for (final p in activeApiProds) {
          if (!existingIds.contains(p.id)) {
            _apiProducts.add(p);
          }
        }
      }
    } else {
      if (page == 1) {
        _productsError = response.message ?? 'Failed to load products from API';
      }
    }
    notifyListeners();
  }

  Future<bool> loadMoreProductsFromApi({
    String? categoryId,
    String? search,
    int? limit,
  }) async {
    if (_isLoadingMoreProducts || _isLoadingProducts) return false;
    if (_productsCurrentPage >= _productsTotalPages) return false;

    final nextPage = _productsCurrentPage + 1;
    await fetchProductsFromApi(
      categoryId: categoryId,
      search: search,
      page: nextPage,
      limit: limit,
    );
    return true;
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
  } // Deprecated: System uses live API products exclusively

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
      image: 'assets/clinical_marketplace.jpg',
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
      image: 'assets/clinical_marketplace.jpg',
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
      image: 'assets/clinical_marketplace.jpg',
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
      image: 'assets/clinical_marketplace.jpg',
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
      image: 'assets/clinical_marketplace.jpg',
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
      image: 'assets/clinical_marketplace.jpg',
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

  // ─── Cart Operations ────────────────────────────────────────────────────────

  Future<GetCartApiResponse> fetchCartFromApi() async {
    final token = activeToken;
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint('│ [CART] FETCH CART FROM API');
    debugPrint('│ Token    : ${token != null && token.isNotEmpty ? token : "null / empty"}');
    debugPrint('│ TokenType: ${_authToken != null && _authToken!.isNotEmpty ? "USER" : (_doctorToken != null && _doctorToken!.isNotEmpty ? "DOCTOR" : "NONE")}');
    if (token == null || token.isEmpty) {
      debugPrint('└ SKIP — user not authenticated');
      return GetCartApiResponse(
        success: false,
        message: 'User not authenticated',
      );
    }

    _isLoadingCart = true;
    notifyListeners();

    final response = await CartService.getCart(token: token);
    _isLoadingCart = false;

    debugPrint('│ Response success: ${response.success}');
    if (response.message != null) debugPrint('│ Message: ${response.message}');

    if (response.success && response.data != null) {
      final serverItems = response.data!.items;
      debugPrint('│ Server cart items: ${serverItems.length}');
      for (final item in serverItems) {
        debugPrint('│   • itemId=${item.id} | productId=${item.productId} | skuId=${item.skuId ?? "null"} | qty=${item.quantity} | price=₹${item.priceAtAdd}');
      }

      final localUnsynced = _cart.where((item) => item.itemId == null).toList();
      if (localUnsynced.isNotEmpty) {
        debugPrint('│ Local unsynced items: ${localUnsynced.length}');
        for (final u in localUnsynced) {
          debugPrint('│   • product=${u.product.name} | qty=${u.quantity}');
        }
      }

      List<CartItem> updatedCart = [];
      for (final itemData in serverItems) {
        final existingProd = _apiProducts.firstWhere(
          (p) => p.id == itemData.productId,
          orElse: () => Product(
            id: itemData.productId,
            name: itemData.productName ?? 'Product',
            brand: itemData.skuName ?? '',
            image: 'assets/img2.png',
            price: itemData.priceAtAdd,
            originalPrice: itemData.mrp > 0
                ? itemData.mrp
                : itemData.priceAtAdd,
            rating: 4.5,
            reviewsCount: 10,
            category: 'General',
            description: '',
          ),
        );

        final localIdx = _cart.indexWhere(
          (c) => c.product.id == itemData.productId,
        );
        final String? localPrescription = localIdx != -1
            ? _cart[localIdx].prescriptionFile
            : null;

        Product resolvedProd = existingProd;
        if (itemData.skuId != null && itemData.skuId!.isNotEmpty) {
          // Level 1: match by skuId (most precise)
          ProductVariant? matchedVariant = existingProd.variants.where(
            (v) => v.id == itemData.skuId,
          ).firstOrNull;

          if (matchedVariant != null) {
            resolvedProd = existingProd.copyWithVariant(matchedVariant);
            debugPrint('│   ✓ Variant matched by skuId=${itemData.skuId} → packSize=${matchedVariant.packSize}');
          } else {
            // Level 2: match by skuCode
            if (itemData.skuCode != null && itemData.skuCode!.isNotEmpty) {
              matchedVariant = existingProd.variants.where(
                (v) => v.skuCode != null && v.skuCode == itemData.skuCode,
              ).firstOrNull;
              if (matchedVariant != null) {
                resolvedProd = existingProd.copyWithVariant(matchedVariant);
                debugPrint('│   ✓ Variant matched by skuCode=${itemData.skuCode} → packSize=${matchedVariant.packSize}');
              }
            }

            // Level 3: match by priceAtAdd
            if (matchedVariant == null && itemData.priceAtAdd > 0) {
              matchedVariant = existingProd.variants.where(
                (v) => v.price == itemData.priceAtAdd,
              ).firstOrNull;
              if (matchedVariant != null) {
                resolvedProd = existingProd.copyWithVariant(matchedVariant);
                debugPrint('│   ✓ Variant matched by priceAtAdd=₹${itemData.priceAtAdd} → packSize=${matchedVariant.packSize}');
              }
            }

            // Level 4: match by skuName == packSize
            if (matchedVariant == null && itemData.skuName != null && itemData.skuName!.isNotEmpty) {
              matchedVariant = existingProd.variants.where(
                (v) => v.packSize.trim().toLowerCase() == itemData.skuName!.trim().toLowerCase(),
              ).firstOrNull;
              if (matchedVariant != null) {
                resolvedProd = existingProd.copyWithVariant(matchedVariant);
                debugPrint('│   ✓ Variant matched by skuName=${itemData.skuName} → packSize=${matchedVariant.packSize}');
              }
            }

            if (matchedVariant == null) {
              debugPrint('│   ⚠ Variant NOT matched for skuId=${itemData.skuId} in product=${existingProd.name} (all 4 levels tried)');
              debugPrint('│     Available variants: ${existingProd.variants.map((v) => "id=${v.id} pack=${v.packSize} price=₹${v.price}").join(" | ")}');
            }
          }
        }

        updatedCart.add(
          CartItem(
            product: resolvedProd,
            quantity: itemData.quantity,
            itemId: itemData.id,
            prescriptionFile: localPrescription,
          ),
        );
      }

      for (final unsynced in localUnsynced) {
        if (!updatedCart.any((c) => c.product.id == unsynced.product.id)) {
          updatedCart.add(unsynced);
        }
      }

      _cart.clear();
      _cart.addAll(updatedCart);
      debugPrint('│ Final local cart: ${_cart.length} items');
      for (final c in _cart) {
        debugPrint('│   • ${c.product.name} | packSize=${c.product.packSize} | qty=${c.quantity} | itemId=${c.itemId ?? "null"}');
      }
    } else {
      debugPrint('│ ✗ Fetch failed — cart not updated');
    }
    debugPrint('└─────────────────────────────────────────────');
    notifyListeners();
    return response;
  }

  Future<AddToCartApiResponse> addToCart(Product product, {int qty = 1}) async {
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint('│ [CART] ADD TO CART');
    debugPrint('│ Product : ${product.name}');
    debugPrint('│ ProductId: ${product.id}');
    debugPrint('│ SkuId   : ${product.skuId ?? "null (no variant selected)"}');
    debugPrint('│ PackSize: ${product.packSize}');
    debugPrint('│ Price   : ₹${product.price}');
    debugPrint('│ Qty     : $qty');

    final existingIdx = _cart.indexWhere(
      (item) => item.product.id == product.id && item.product.packSize == product.packSize,
    );
    if (existingIdx != -1) {
      _cart[existingIdx].quantity += qty;
      debugPrint('│ Action: Updated existing local item → new qty=${_cart[existingIdx].quantity}');
    } else {
      _cart.add(CartItem(product: product, quantity: qty));
      debugPrint('│ Action: Added new item to local cart');
    }
    notifyListeners();

    final token = activeToken;
    final tokenType = _authToken != null && _authToken!.isNotEmpty
        ? 'USER'
        : (_doctorToken != null && _doctorToken!.isNotEmpty ? 'DOCTOR' : 'NONE');
    if (token == null || token.isEmpty) {
      debugPrint('│ TokenType: $tokenType');
      debugPrint('│ Token    : null / empty');
      debugPrint('│ ⚠ No token — added locally only');
      debugPrint('└─────────────────────────────────────────────');
      return AddToCartApiResponse(success: true, message: 'Added to cart locally');
    }
    debugPrint('│ TokenType: $tokenType');
    debugPrint('│ Token    : $token');

    debugPrint('│ → Calling API: POST /api/cart');
    debugPrint('│   Body: { productId: ${product.id}, skuId: ${product.skuId ?? ""}, quantity: $qty }');

    final response = await CartService.addToCart(
      productId: product.id,
      skuId: product.skuId,
      quantity: qty,
      token: token,
    );

    debugPrint('│ Response success: ${response.success}');
    debugPrint('│ Response message: ${response.message}');

    if (response.success && response.data != null) {
      final newItemId = response.data!.id;
      debugPrint('│ ✓ Server itemId assigned: $newItemId');
      final idx = _cart.indexWhere((item) =>
          item.product.id == product.id && item.product.packSize == product.packSize);
      if (idx != -1) {
        _cart[idx].itemId = newItemId;
        debugPrint('│ ✓ Local cart itemId updated');
      }
    } else {
      debugPrint('│ ✗ API failed — item may not be synced to backend!');
    }
    debugPrint('└─────────────────────────────────────────────');
    return response;
  }

  Future<AddToCartApiResponse> addToCartApi(
    Product product, {
    int qty = 1,
  }) async {
    return await addToCart(product, qty: qty);
  }

  Future<CartActionApiResponse?> updateCartQty(
    Product product,
    int newQty,
  ) async {
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint('│ [CART] UPDATE QUANTITY');
    debugPrint('│ Product : ${product.name}');
    debugPrint('│ PackSize: ${product.packSize}');
    debugPrint('│ New Qty : $newQty');

    int idx = _cart.indexWhere(
      (item) => item.product.id == product.id && item.product.packSize == product.packSize,
    );
    if (idx == -1) {
      idx = _cart.indexWhere((item) => item.product.id == product.id);
      if (idx != -1) debugPrint('│ ⚠ Matched by productId only (packSize mismatch)');
    }

    if (idx == -1) {
      debugPrint('│ ✗ Product not found in local cart!');
      debugPrint('└─────────────────────────────────────────────');
      return null;
    }

    final String? itemId = _cart[idx].itemId;
    final token = activeToken;
    final tokenType = _authToken != null && _authToken!.isNotEmpty
        ? 'USER'
        : (_doctorToken != null && _doctorToken!.isNotEmpty ? 'DOCTOR' : 'NONE');
    debugPrint('│ Local itemId: ${itemId ?? "null ⚠"}');
    debugPrint('│ TokenType   : $tokenType');
    debugPrint('│ Token       : ${token ?? "null / empty"}');

    if (newQty <= 0) {
      debugPrint('│ Action: REMOVE (qty <= 0)');
      _cart.removeAt(idx);
      notifyListeners();
      debugPrint('│ ✓ Removed from local cart');

      if (token == null || token.isEmpty) {
        debugPrint('└ SKIP API — no token');
        return null;
      }

      if (itemId != null && itemId.isNotEmpty) {
        debugPrint('│ → Calling API: DELETE /api/cart/items/$itemId');
        final res = await CartService.removeCartItem(itemId: itemId, token: token);
        debugPrint('│ Response success: ${res.success}');
        debugPrint('│ Response message: ${res.message}');
        if (!res.success) {
          debugPrint('│ ✗ Remove API failed! Re-syncing from server...');
          fetchCartFromApi();
        } else {
          debugPrint('│ ✓ Item successfully removed from backend');
        }
        debugPrint('└─────────────────────────────────────────────');
        return res;
      } else {
        debugPrint('│ ⚠ itemId is null — cannot call delete API!');
        debugPrint('│ → Re-syncing cart from server to get correct itemIds...');
        await fetchCartFromApi();
        debugPrint('└─────────────────────────────────────────────');
        return null;
      }
    } else {
      debugPrint('│ Action: UPDATE qty → $newQty');
      _cart[idx].quantity = newQty;
      notifyListeners();
      debugPrint('│ ✓ Updated local cart');

      if (token == null || token.isEmpty) {
        debugPrint('└ SKIP API — no token');
        return null;
      }

      if (itemId != null && itemId.isNotEmpty) {
        debugPrint('│ → Calling API: PUT /api/cart/items/$itemId');
        debugPrint('│   Body: { quantity: $newQty }');
        final res = await CartService.updateCartItemQuantity(
          itemId: itemId,
          quantity: newQty,
          token: token,
        );
        debugPrint('│ Response success: ${res.success}');
        debugPrint('│ Response message: ${res.message}');
        if (!res.success) {
          debugPrint('│ ✗ Update API failed! Re-syncing from server...');
          fetchCartFromApi();
        } else {
          debugPrint('│ ✓ Quantity updated on backend');
        }
        debugPrint('└─────────────────────────────────────────────');
        return res;
      } else {
        debugPrint('│ ⚠ itemId is null — cannot call update API!');
        debugPrint('│ → Re-syncing cart from server...');
        await fetchCartFromApi();
        debugPrint('└─────────────────────────────────────────────');
        return null;
      }
    }
  }

  void attachPrescription(Product product, String path) {
    int idx = _cart.indexWhere(
      (item) => item.product.id == product.id && item.product.packSize == product.packSize,
    );
    if (idx == -1) {
      idx = _cart.indexWhere((item) => item.product.id == product.id);
    }
    if (idx != -1) {
      _cart[idx].prescriptionFile = path;
      notifyListeners();
    }
  }

  Future<CartActionApiResponse?> removeFromCart(Product product) async {
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint('│ [CART] REMOVE FROM CART (Direct Remove Button)');
    debugPrint('│ Product : ${product.name}');
    debugPrint('│ PackSize: ${product.packSize}');
    debugPrint('│ ProductId: ${product.id}');

    int idx = _cart.indexWhere(
      (item) => item.product.id == product.id && item.product.packSize == product.packSize,
    );
    if (idx == -1) {
      idx = _cart.indexWhere((item) => item.product.id == product.id);
      if (idx != -1) debugPrint('│ ⚠ Matched by productId only (packSize mismatch)');
    }

    String? itemId;
    if (idx != -1) {
      itemId = _cart[idx].itemId;
      debugPrint('│ Local itemId: ${itemId ?? "null ⚠"}');
      _cart.removeAt(idx);
      notifyListeners();
      debugPrint('│ ✓ Removed from local cart');
    } else {
      debugPrint('│ ⚠ Product not found in local cart');
    }

    final token = activeToken;
    final tokenType = _authToken != null && _authToken!.isNotEmpty
        ? 'USER'
        : (_doctorToken != null && _doctorToken!.isNotEmpty ? 'DOCTOR' : 'NONE');
    debugPrint('│ TokenType: $tokenType');
    debugPrint('│ Token    : ${token ?? "null / empty"}');

    if (token == null || token.isEmpty) {
      debugPrint('└ SKIP API — no token');
      return null;
    }

    if (itemId != null && itemId.isNotEmpty) {
      debugPrint('│ → Calling API: DELETE /api/cart/items/$itemId');
      final res = await CartService.removeCartItem(itemId: itemId, token: token);
      debugPrint('│ Response success: ${res.success}');
      debugPrint('│ Response message: ${res.message}');
      if (!res.success) {
        debugPrint('│ ✗ Remove API failed! Re-syncing from server...');
        fetchCartFromApi();
      } else {
        debugPrint('│ ✓ Item successfully removed from backend');
      }
      debugPrint('└─────────────────────────────────────────────');
      return res;
    } else {
      debugPrint('│ ⚠ itemId is null — cannot call delete API!');
      debugPrint('│ → Re-syncing cart from server...');
      await fetchCartFromApi();
      debugPrint('└─────────────────────────────────────────────');
      return null;
    }
  }

  Future<CartActionApiResponse?> clearCart() async {
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint('│ [CART] CLEAR ALL CART');
    debugPrint('│ Items before clear: ${_cart.length}');
    for (final c in _cart) {
      debugPrint('│   • ${c.product.name} | itemId=${c.itemId ?? "null"}');
    }
    _cart.clear();
    notifyListeners();
    debugPrint('│ ✓ Local cart cleared');

    final token = activeToken;
    final tokenType = _authToken != null && _authToken!.isNotEmpty
        ? 'USER'
        : (_doctorToken != null && _doctorToken!.isNotEmpty ? 'DOCTOR' : 'NONE');
    debugPrint('│ TokenType: $tokenType');
    debugPrint('│ Token    : ${token ?? "null / empty"}');

    if (token == null || token.isEmpty) {
      debugPrint('└ SKIP API — no token');
      return null;
    }

    debugPrint('│ → Calling API: DELETE /api/cart/clear');
    final res = await CartService.clearCart(token: token);
    debugPrint('│ Response success: ${res.success}');
    debugPrint('│ Response message: ${res.message}');
    if (res.success) {
      debugPrint('│ ✓ Backend cart cleared successfully');
    } else {
      debugPrint('│ ✗ Clear API failed!');
    }
    debugPrint('└─────────────────────────────────────────────');
    return res;
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

  Future<UserWishlistDoctorsApiResponse> fetchUserWishlistDoctors() async {
    _isLoadingDoctorWishlist = true;
    notifyListeners();

    final response = await WishlistService.getUserWishlistDoctors(
      token: _authToken,
    );
    _isLoadingDoctorWishlist = false;

    if (response.success) {
      _userWishlistDoctorItems = response.data;
      _wishlistDoctorIds.clear();
      for (final item in response.data) {
        if (item.targetDoctorId.isNotEmpty &&
            !_wishlistDoctorIds.contains(item.targetDoctorId)) {
          _wishlistDoctorIds.add(item.targetDoctorId);
        }
      }
    }
    notifyListeners();
    return response;
  }

  Future<WishlistActionResponse> toggleDoctorWishlist(String doctorId) async {
    final bool wasInWishlist = _wishlistDoctorIds.contains(doctorId);
    if (wasInWishlist) {
      _wishlistDoctorIds.remove(doctorId);
    } else {
      _wishlistDoctorIds.add(doctorId);
    }
    notifyListeners();

    final response = await WishlistService.toggleDoctorWishlist(
      targetDoctorId: doctorId,
      token: _authToken,
    );

    if (!response.success) {
      if (wasInWishlist) {
        _wishlistDoctorIds.add(doctorId);
      } else {
        _wishlistDoctorIds.remove(doctorId);
      }
      notifyListeners();
    }

    return response;
  }

  // Appointment Operations
  void addAppointment(
    Doctor doctor,
    String date,
    String time,
    String notes, {
    List<String> files = const [],
    String? customId,
  }) {
    final id = customId ?? 'AYC-${100000 + _appointments.length}';
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

  Future<MyAppointmentsApiResponse> fetchMyAppointments({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      return MyAppointmentsApiResponse(
        success: false,
        appointments: [],
        message: 'User not authenticated',
      );
    }

    _isLoadingMyAppointments = true;
    notifyListeners();

    final response = await AppointmentService.getMyAppointments(
      page: page,
      limit: limit,
      status: status,
      token: _authToken,
    );

    _isLoadingMyAppointments = false;

    if (response.success) {
      _myAppointments = response.appointments;
    }
    notifyListeners();
    return response;
  }

  Future<SingleAppointmentApiResponse> fetchAppointmentDetail(
    String appointmentId,
  ) async {
    return await AppointmentService.getAppointmentById(
      appointmentId: appointmentId,
      token: _authToken,
    );
  }

  Future<SingleAppointmentApiResponse> cancelAppointment({
    required String appointmentId,
    required String cancelReason,
  }) async {
    final response = await AppointmentService.cancelAppointment(
      appointmentId: appointmentId,
      cancelReason: cancelReason,
      token: _authToken,
    );
    if (response.success) {
      fetchMyAppointments();
    }
    return response;
  }

  // Order Operations
  Future<MyOrdersApiResponse> fetchMyOrders() async {
    final token = activeToken;
    if (token == null || token.isEmpty) {
      return MyOrdersApiResponse(
        success: false,
        message: 'User not authenticated',
        data: [],
      );
    }
    _isLoadingMyOrders = true;
    notifyListeners();

    final response = await OrderService.getUsersOrders(token: token);
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
    return await OrderService.getOrderById(orderId: orderId, token: activeToken);
  }

  // Coupon Operations
  Future<CouponsApiResponse> fetchCoupons() async {
    _isLoadingCoupons = true;
    notifyListeners();

    final response = await CouponService.getCoupons(token: activeToken);
    _isLoadingCoupons = false;

    if (response.success) {
      _coupons = response.data;
    }
    notifyListeners();
    return response;
  }

  void applyCoupon(CouponModel? coupon) {
    _appliedCoupon = coupon;
    notifyListeners();
  }

  bool applyCouponByCode(String code, double subtotal) {
    final trimmed = code.trim().toLowerCase();
    if (trimmed.isEmpty) {
      _appliedCoupon = null;
      notifyListeners();
      return false;
    }

    final matchIndex = _coupons.indexWhere(
      (c) => c.code.toLowerCase() == trimmed,
    );
    if (matchIndex != -1) {
      final coupon = _coupons[matchIndex];
      if (coupon.isValidForOrder(subtotal)) {
        _appliedCoupon = coupon;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void clearAppliedCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  Future<CheckoutApiResponse> checkoutOrder({
    required String shippingAddressId,
    required String paymentMode,
    String paymentStatus = 'pending',
    String? prescription,
    String? couponCode,
  }) async {
    String? effectivePrescription = prescription;
    if (effectivePrescription == null || effectivePrescription.trim().isEmpty) {
      for (final item in _cart) {
        if (item.prescriptionFile != null &&
            item.prescriptionFile!.trim().isNotEmpty) {
          effectivePrescription = item.prescriptionFile;
          break;
        }
      }
    }

    final String? effectiveCouponCode =
        (couponCode != null && couponCode.trim().isNotEmpty)
        ? couponCode.trim()
        : _appliedCoupon?.code;

    final response = await OrderService.checkout(
      shippingAddressId: shippingAddressId,
      paymentMode: paymentMode,
      paymentStatus: paymentStatus,
      prescription: effectivePrescription,
      couponCode: effectiveCouponCode,
      token: activeToken,
    );

    if (response.success && response.data != null) {
      final cartItemsBeforeClear = List<CartItem>.from(_cart);
      final newOrderFromApi = response.data!.toOrder(_apiProducts);

      final orderWithItems = newOrderFromApi.items.isNotEmpty
          ? newOrderFromApi
          : Order(
              id: newOrderFromApi.id,
              items: cartItemsBeforeClear,
              totalAmount: newOrderFromApi.totalAmount > 0
                  ? newOrderFromApi.totalAmount
                  : cartItemsBeforeClear.fold(
                      0.0,
                      (sum, i) => sum + (i.product.price * i.quantity),
                    ),
              discount: newOrderFromApi.discount,
              shippingCharge: newOrderFromApi.shippingCharge,
              status: newOrderFromApi.status,
              orderDate: newOrderFromApi.orderDate,
              orderNo: newOrderFromApi.orderNo,
              paymentMode: newOrderFromApi.paymentMode,
              deliveryAddress: newOrderFromApi.deliveryAddress,
              prescription:
                  newOrderFromApi.prescription ?? effectivePrescription,
            );

      _orders.add(orderWithItems);
      _appliedCoupon = null;
      await clearCart();
      await fetchMyOrders();

      if (_orders.isNotEmpty) {
        final lastIndex = _orders.length - 1;
        if (_orders[lastIndex].items.isEmpty &&
            orderWithItems.items.isNotEmpty) {
          _orders[lastIndex] = Order(
            id: _orders[lastIndex].id,
            items: orderWithItems.items,
            totalAmount: _orders[lastIndex].totalAmount,
            discount: _orders[lastIndex].discount,
            shippingCharge: _orders[lastIndex].shippingCharge > 0
                ? _orders[lastIndex].shippingCharge
                : orderWithItems.shippingCharge,
            status: _orders[lastIndex].status,
            orderDate: _orders[lastIndex].orderDate,
            orderNo: _orders[lastIndex].orderNo,
            paymentMode: _orders[lastIndex].paymentMode,
            deliveryAddress: _orders[lastIndex].deliveryAddress,
            prescription:
                _orders[lastIndex].prescription ?? orderWithItems.prescription,
          );
        }
      } else {
        _orders.add(orderWithItems);
      }

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
    final token = activeToken;
    if (token == null || token.isEmpty) {
      return ShippingAddressesApiResponse(
        success: false,
        data: [],
        message: 'User not authenticated',
      );
    }
    _isLoadingAddresses = true;
    notifyListeners();

    final response = await ShippingAddressService.getShippingAddresses(
      token: token,
    );
    _isLoadingAddresses = false;

    if (response.success) {
      _shippingAddresses = response.data;
      if (_shippingAddresses.isNotEmpty) {
        final defaultAddress = _shippingAddresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _shippingAddresses.first,
        );
        if (_selectedShippingAddress == null ||
            !_shippingAddresses.any(
              (a) => a.id == _selectedShippingAddress!.id,
            )) {
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
      token: activeToken,
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
      token: activeToken,
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
      token: activeToken,
    );

    if (response.success) {
      _shippingAddresses.removeWhere((a) => a.id == id);
      if (_selectedShippingAddress?.id == id) {
        _selectedShippingAddress = _shippingAddresses.isNotEmpty
            ? (_shippingAddresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => _shippingAddresses.first,
              ))
            : null;
      }
      notifyListeners();
    }
    return response;
  }
}
