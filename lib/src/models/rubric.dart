class RubricRating {
  final String description;
  final num points;
  const RubricRating({required this.description, required this.points});
}

class RubricCriterion {
  final String slug;
  final String description;
  final List<RubricRating> ratings;
  const RubricCriterion({
    required this.slug,
    required this.description,
    required this.ratings,
  });
  num get maxPoints =>
      ratings.fold<num>(0, (m, r) => r.points > m ? r.points : m);
}

class Rubric {
  final String slug;
  final String title;
  final List<RubricCriterion> criteria;
  const Rubric({
    required this.slug,
    required this.title,
    required this.criteria,
  });
  num get totalPoints =>
      criteria.fold<num>(0, (s, c) => s + c.maxPoints);
}
