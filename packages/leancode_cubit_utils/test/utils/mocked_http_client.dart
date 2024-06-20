import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockedHttpClient extends Mock implements http.Client {}
