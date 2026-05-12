class QuoteBlockContent {
  final String? quote;
  final String? author;
  final String? fetchedDate; // yyyy-MM-dd of the day this quote was locked in

  const QuoteBlockContent({this.quote, this.author, this.fetchedDate});

  factory QuoteBlockContent.fromMap(Map<String, dynamic> map) =>
      QuoteBlockContent(
        quote: map['quote'] as String?,
        author: map['author'] as String?,
        fetchedDate: map['fetchedDate'] as String?,
      );

  Map<String, dynamic> toMap() => {
    if (quote != null) 'quote': quote,
    if (author != null) 'author': author,
    if (fetchedDate != null) 'fetchedDate': fetchedDate,
  };
}
