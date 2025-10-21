import 'constants.dart';

/// Input validation utilities
class Validators {
  // Prevent instantiation
  Validators._();

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate Venmo username (must start with @)
  static String? validateVenmoUsername(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (!value.startsWith(AppConstants.venmoUsernamePrefix)) {
      return 'Venmo username must start with @';
    }

    if (value.length < 2) {
      return 'Please enter a valid Venmo username';
    }

    // Check for valid characters (alphanumeric, hyphen, underscore)
    final venmoRegex = RegExp(r'^@[a-zA-Z0-9_-]+$');
    if (!venmoRegex.hasMatch(value)) {
      return 'Venmo username can only contain letters, numbers, hyphens, and underscores';
    }

    return null;
  }

  /// Validate PayPal email
  static String? validatePayPalEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    return validateEmail(value);
  }

  /// Validate that at least one payment method is provided
  static String? validatePaymentInfo(String? venmo, String? paypal) {
    if ((venmo == null || venmo.isEmpty) &&
        (paypal == null || paypal.isEmpty)) {
      return 'Please provide at least one payment method';
    }
    return null;
  }

  /// Validate item name
  static String? validateItemName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Item name is required';
    }

    if (value.trim().isEmpty) {
      return 'Item name cannot be empty';
    }

    return null;
  }

  /// Validate price
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid number';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (price > 999999.99) {
      return 'Price is too large';
    }

    return null;
  }

  /// Validate number of people for even split
  static String? validateNumPeople(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number of people is required';
    }

    final num = int.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }

    if (num < 2) {
      return 'Must split between at least 2 people';
    }

    if (num > 100) {
      return 'Cannot split between more than 100 people';
    }

    return null;
  }

  /// Validate person name
  static String? validatePersonName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.trim().isEmpty) {
      return 'Name cannot be empty';
    }

    if (value.length > 50) {
      return 'Name is too long';
    }

    return null;
  }
}
