
class ApiConstants {
  //fetchCurrencyRates
  static const String baseUrl = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String fetchCurrencyRates = '$baseUrl/ForexObjects/operations/Forex/fetchCurrencyRates';
  // getAccountsPostLogin 
  static const String baseUrl1 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String fetchAccounts = '$baseUrl1/RBObjects/operations/Accounts/getAccountsPostLogin';
//EbirrQuery
  static const String baseUrl2 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String performEbirrTransaction = '$baseUrl2/BillPayments/operations/Pay/EbirrQuery';
//createOneTimeTransfer
  static const String baseUrl3 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String performTransaction = '$baseUrl3/RBObjects/operations/Transactions/createOneTimeTransfer';

//KachaQuery
  static const String baseUrl4 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String performKachaTransaction = '$baseUrl4/BillPayments/operations/Pay/KachaQuery';

//getValidAccountId
  static const String baseUrl5 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String checkAccountValidity = '$baseUrl5/RBObjects/operations/Transactions/getValidAccountId';

//getCustomerBillData
  static const String baseUrl6 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String getBillAmount = '$baseUrl6/BillPayments/operations/Pay/getCustomerBillData';

//ERCATxn
  static const String baseUrl7 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String makePayment = '$baseUrl7/BillPayments/operations/Pay/ERCATxn';

//paymentInquiry
  static const String baseUrl8 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String getAirlineBillAmount = '$baseUrl8/BillPayments/operations/Pay/paymentInquiry';

//DbxUserLogin
  static const String baseUrl9 = 'https://infinityuat.cbe.com.et:443/authService/100000002';
  static const String login = '$baseUrl9/login?provider=DbxUserLogin';

//getRecentUserTransactions
  static const String baseUrl10 = 'https://infinityuat.cbe.com.et/services/data/v1';
  static const String fetchRecentTransactions = '$baseUrl10/RBObjects/operations/Transactions/getRecentUserTransactions';

  //Recipients/createExternalPayee
  static const String baseUrl11 = 'https://infinityuat.cbe.com.et/services/data/v1/PayeeObjects/operations/Recipients/createExternalPayee';
  static const String submitBeneficiary = '$baseUrl11/PayeeObjects/operations/Recipients/createExternalPayee';
}


class ApiHeaders {
  static const String appKey = 'a5c29017554c2c39be93665f235fa86f';
  static const String appSecret = 'a5835744b2eb19a03e0aa11502e905c9';
}
 