class ApiConfig {
  // URL base da API
  static const String baseUrl = 'https://seuservidor.com/api';
  
  // Endpoints específicos
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String ordersEndpoint = '$baseUrl/orders';
  static const String invoicesEndpoint = '$baseUrl/invoices';
  static const String financialEndpoint = '$baseUrl/financial';
  static const String profileEndpoint = '$baseUrl/profile';
  
  // Timeout para requisições (em segundos)
  static const int timeoutDuration = 30;
}