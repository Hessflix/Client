import 'package:hessflix/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:hessflix/models/items/item_shared_models.dart';

extension PeopleExtension on List<Person> {
  List<Person> get guestActors => where((person) => person.type == PersonKind.gueststar).toList();
  List<Person> get mainCast => where((person) => person.type != PersonKind.gueststar).toList();
}
