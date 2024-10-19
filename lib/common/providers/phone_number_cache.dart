import 'package:hive/hive.dart';

class PhoneNumberCache {
  final Map<String, String> _cache = {};
  final Box _hiveBox = Hive.box('phoneNumberCache');

  String? getUidFromCache(String phoneNumber) {
    // Vérifier d'abord dans le cache en mémoire
    if (_cache.containsKey(phoneNumber)) {
      return _cache[phoneNumber];
    }

    // Si non trouvé en mémoire, vérifier dans Hive
    if (_hiveBox.containsKey(phoneNumber)) {
      return _hiveBox.get(phoneNumber);
    }

    // Si non trouvé dans Hive non plus
    return null;
  }

  void addPhoneNumberToCache(String phoneNumber, String uid) {
    // Ajouter au cache en mémoire
    _cache[phoneNumber] = uid;

    // Ajouter au cache persistant Hive
    _hiveBox.put(phoneNumber, uid);
  }
}
