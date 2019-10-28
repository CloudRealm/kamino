import 'package:kamino/database/database.dart';
import 'package:kamino/models/list.dart';
import 'package:objectdb/objectdb.dart';

class PlaylistCacheCollection {

  static Future<void> write(ContentListModel list) async {
    ObjectDB database = await Database.open();
    await database.insert({
      "docType": "cachedPlaylist",
      "timestamp": new DateTime.now().millisecondsSinceEpoch,
      "data": list.toMap()
    });
    database.close();
  }

  static Future<ContentListModel> select(int listId) async {
    ObjectDB database = await Database.open();
    List<Map> data = await database.find({
      "docType": "cachedPlaylist",
      "data.id": listId
    });

    if(data.length < 1) return null;
    ContentListModel cachedList = ContentListModel.fromJSON(data[0]['data']);
    database.close();
    return cachedList;
  }

  static Future<bool> contains(int listId) async {
    // Check if database needs to be updated
    ObjectDB database = await Database.open();
    bool inCache = (await database.find({
      "docType": "cachedPlaylist",
      "data.id": listId,
      Op.gte: {
        "timestamp": new DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch
      }
    })).length > 0;
    database.close();
    return inCache;
  }

}