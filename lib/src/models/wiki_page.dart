class WikiPage {
  final String slug;
  final String title;
  final String htmlBody;
  final bool frontPage;

  const WikiPage({
    required this.slug,
    required this.title,
    required this.htmlBody,
    this.frontPage = false,
  });
}
