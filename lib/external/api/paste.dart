import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/struct/paste.dart';

class PasteEE extends PasteService {

  static PasteEEIdentity identity;

  PasteEE(PasteEEIdentity _identity) : super(
    "Paste.ee",
    types: const [ServiceType.PASTE],
    isPrimaryService: true
  ){ identity = _identity; }

  @override
  Future<String> paste(String data, {String title, String fileFormat}) async {
    var response = await http.post("https://api.paste.ee/v1/pastes", body: jsonEncode({
      "description": title,
      "sections": [{
        "name": "Device Information",
        "syntax": fileFormat,
        "contents": data
      }]
    }), headers: {
      'Content-Type': 'application/json',
      'X-Auth-Token': identity.token
    });

    return jsonDecode(response.body)["link"];
  }

}

class PasteEEIdentity {
  String token;

  PasteEEIdentity({
    String token
  }) : this.token = token;
}