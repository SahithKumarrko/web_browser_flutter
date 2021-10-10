import 'package:http/http.dart' as http;

main() async {
  var url = "https://www.financialexpress.com/favicon.ico";

  http.Response response1 = await http.get(Uri.parse(url));
  print('Response status: ${response1.statusCode}');
  print('Response body: ${response1.body}');
  print('Response body: ${response1.headers}');
  print('Response body: ${response1.reasonPhrase}');
  print('Response body: ${response1.request}');
}
