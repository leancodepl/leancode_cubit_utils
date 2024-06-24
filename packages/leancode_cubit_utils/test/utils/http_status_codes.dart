enum StatusCode {
  ok(200),
  badRequest(400),
  notFound(404);

  const StatusCode(this.value);
  final int value;
}
