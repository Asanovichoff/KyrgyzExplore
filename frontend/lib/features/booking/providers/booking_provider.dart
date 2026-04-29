import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

final myBookingsProvider = FutureProvider.autoDispose<List<BookingModel>>(
  (ref) => ref.read(bookingRepositoryProvider).myBookings(),
);
