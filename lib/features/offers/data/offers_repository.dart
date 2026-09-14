import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/offer_model.dart';

class OffersRepository {
  Future<List<OfferModel>> fetchOffers() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    final jsonString = await rootBundle.loadString('assets/data/mock_responses.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> offersJson = data['offers'];
    return offersJson.map((e) => OfferModel.fromJson(e)).toList();
  }
}

final offersRepositoryProvider = Provider((ref) => OffersRepository());
