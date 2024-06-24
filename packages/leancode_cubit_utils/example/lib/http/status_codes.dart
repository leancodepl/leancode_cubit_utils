enum StatusCode {
  ok(200),
  badRequest(400);

  const StatusCode(this.value);

  final int value;
}
