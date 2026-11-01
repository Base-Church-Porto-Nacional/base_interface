import '../models/models.dart';

PageResponse<T> paginate<T>(List<T> items, {int page = 0, int size = 20}) {
  final start = page * size;
  final content = items.skip(start).take(size).toList();
  return PageResponse(
    content: content,
    totalElements: items.length,
    totalPages: (items.length / size).ceil().clamp(1, 999),
    page: page,
    size: size,
  );
}
