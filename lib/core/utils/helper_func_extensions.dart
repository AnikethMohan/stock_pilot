extension StringTransformExtensions on String {
  String capitalizeFirstl() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);

  String capitalizeUnderscoreWords() =>
      split('_').map((str) => str.capitalizeFirstl()).join(' ');

  String capitalizeUnderscoreWordsOnlyFirst() {
    if (isEmpty) return this;
    final words = split('_');
    final firstWord = words.first.capitalizeFirstl();
    final remaining = words.skip(1).join(' ');
    return [firstWord, if (remaining.isNotEmpty) remaining].join(' ');
  }

  String capitalizeSpaceWords() =>
      split(' ').map((str) => str.capitalizeFirstl()).join(' ');
}
