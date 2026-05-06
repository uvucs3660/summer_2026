import 'module_item.dart';

class Module {
  final String slug;
  final String title;
  final List<ModuleItem> items;
  final bool published;

  const Module({
    required this.slug,
    required this.title,
    required this.items,
    this.published = true,
  });
}
