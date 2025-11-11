bool methodSupportsBody(String method) {
  const methods = {'POST', 'PUT', 'PATCH'};
  return methods.contains(method.toUpperCase());
}

bool isSuccessStatusCode(int statusCode) {
  return statusCode >= 200 && statusCode < 300;
}
