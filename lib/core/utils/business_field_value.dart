const businessFieldUnavailableLabel = 'No publicado por la fuente';

String businessFieldValue(Map<String, dynamic> business, String field) {
  final value = (business[field] ?? '').toString().trim();
  return value.isEmpty ? businessFieldUnavailableLabel : value;
}
