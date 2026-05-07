enum ModuleItemKind { assignment, wikiPage, quiz, subHeader, externalUrl }

class ModuleItem {
  final ModuleItemKind kind;
  final String? referenceSlug; // for assignment / wikiPage / quiz
  final String? subHeaderTitle;
  final String? externalUrl;
  final String? externalUrlTitle;
  final int indent;

  const ModuleItem.assignment(this.referenceSlug, {this.indent = 1})
      : kind = ModuleItemKind.assignment,
        subHeaderTitle = null,
        externalUrl = null,
        externalUrlTitle = null;

  const ModuleItem.wikiPage(this.referenceSlug, {this.indent = 1})
      : kind = ModuleItemKind.wikiPage,
        subHeaderTitle = null,
        externalUrl = null,
        externalUrlTitle = null;

  const ModuleItem.quiz(this.referenceSlug, {this.indent = 1})
      : kind = ModuleItemKind.quiz,
        subHeaderTitle = null,
        externalUrl = null,
        externalUrlTitle = null;

  const ModuleItem.subHeader(this.subHeaderTitle, {this.indent = 0})
      : kind = ModuleItemKind.subHeader,
        referenceSlug = null,
        externalUrl = null,
        externalUrlTitle = null;

  const ModuleItem.externalUrl(this.externalUrlTitle, this.externalUrl,
      {this.indent = 1})
      : kind = ModuleItemKind.externalUrl,
        referenceSlug = null,
        subHeaderTitle = null;
}
