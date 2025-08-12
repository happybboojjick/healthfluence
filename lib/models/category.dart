class SubCategory {
  final String id;
  final String name;

  SubCategory({required this.id, required this.name});
}

class Category {
  final String id;
  final String name;
  final List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.name,
    required this.subCategories,
  });
}