import 'package:kamino/database/database.dart';
import 'package:objectdb/objectdb.dart';

class SearchHistoryCollection {

  static Future<List<String>> getAll() async {
    ObjectDB database = await Database.open();
    List<Map> results = await database.find({
      "docType": "pastSearch"
    });
    database.close();

    results = results.take(40).toList(growable: false)
    // Sort by timestamp
      ..sort(
              (Map current, Map next) =>
              current['timestamp'].compareTo(next['timestamp'])
      );
    // ...and map to a simple List<String>
    return results.map((Map result) => result['text']).toList().reversed.toList(growable: false).cast<String>();
  }

  static Future<void> write(String text) async {
    // Ignore if text is null.
    if(text == null || text.isEmpty) return;

    ObjectDB database = await Database.open();

    // If already in the database, remove it.
    await database.remove({
      "docType": "pastSearch",
      "text": text
    });

    await database.insert({
      "docType": "pastSearch",
      "text": text,
      "timestamp": new DateTime.now().millisecondsSinceEpoch
    });

    await database.close();
  }

  static Future<void> remove(String text) async {
    ObjectDB database = await Database.open();
    database.remove({
      "docType": "pastSearch",
      "text": text
    });
    database.close();
  }

  static Future<void> clear() async {
    ObjectDB database = await Database.open();
    database.remove({
      "docType": "pastSearch"
    });
    database.close();
  }

}