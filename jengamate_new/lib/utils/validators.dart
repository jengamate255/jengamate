class Validators {
  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-()]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  /// Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid number';
    }
    if (price < 0) {
      return 'Price must be positive';
    }
    if (price > 1000000) {
      return 'Price must be less than 1,000,000';
    }
    return null;
  }

  /// Description validation
  static String? validateDescription(String? value,
      {int minLength = 10, int maxLength = 1000}) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    if (value.length < minLength) {
      return 'Description must be at least $minLength characters';
    }
    if (value.length > maxLength) {
      return 'Description must be less than $maxLength characters';
    }
    return null;
  }

  /// URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Rating validation
  static String? validateRating(String? value) {
    if (value == null || value.isEmpty) {
      return 'Rating is required';
    }
    final rating = int.tryParse(value);
    if (rating == null) {
      return 'Please enter a valid number';
    }
    if (rating < 1 || rating > 5) {
      return 'Rating must be between 1 and 5';
    }
    return null;
  }

  /// Phone number with country code validation
  static String? validatePhoneWithCountryCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number with country code (e.g., +1234567890)';
    }
    return null;
  }

  /// Business name validation
  static String? validateBusinessName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Business name is required';
    }
    if (value.length < 3) {
      return 'Business name must be at least 3 characters';
    }
    if (value.length > 100) {
      return 'Business name must be less than 100 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9\s&.,-]+$').hasMatch(value)) {
      return 'Business name contains invalid characters';
    }
    return null;
  }

  /// Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 10) {
      return 'Please enter a complete address';
    }
    if (value.length > 500) {
      return 'Address is too long';
    }
    return null;
  }

  /// ZIP/Postal code validation
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Postal code is required';
    }
    final postalRegex = RegExp(r'^\d{5}(-\d{4})?$');
    if (!postalRegex.hasMatch(value)) {
      return 'Please enter a valid postal code';
    }
    return null;
  }

  /// Sanitize input to prevent XSS
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'&[^;]*;'), '') // Remove HTML entities
        .trim();
  }

  /// Validate file upload
  static String? validateFileUpload({
    required String fileName,
    required int fileSize,
    required List<String> allowedExtensions,
    required int maxSizeInBytes,
  }) {
    final extension = fileName.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'File type not allowed. Allowed types: ${allowedExtensions.join(', ')}';
    }

    if (fileSize > maxSizeInBytes) {
      final maxSizeInMB = maxSizeInBytes / (1024 * 1024);
      return 'File size exceeds ${maxSizeInMB.toStringAsFixed(1)}MB limit';
    }

    return null;
  }

  /// Validate image dimensions
  static String? validateImageDimensions({
    required int width,
    required int height,
    required int maxWidth,
    required int maxHeight,
  }) {
    if (width > maxWidth || height > maxHeight) {
      return 'Image dimensions exceed ${maxWidth}x${maxHeight} pixels';
    }
    return null;
  }
}
