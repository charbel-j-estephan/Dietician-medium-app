// This file contains the service for interacting with the Fatsecret API.

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oauth1/oauth1.dart' as oauth1;

// The FatsecretService class is a service that provides methods for interacting with the Fatsecret API.
class FatsecretService {
  // The API URL.
  static const String _apiUrl =
      "https://platform.fatsecret.com/rest/server.api";

  // The OAuth1 client.
  final oauth1.Client _client;

  // The constructor initializes the OAuth1 client.
  FatsecretService()
    : _client = oauth1.Client(
        oauth1.SignatureMethods.hmacSha1,
        oauth1.ClientCredentials(
          dotenv.env['FATSECRET_CONSUMER_KEY']!,
          dotenv.env['FATSECRET_CONSUMER_SECRET']!,
        ),
        null,
      );

  // Searches for foods using the Fatsecret API.
  Future<List<dynamic>> searchFoods(String query) async {
    try {
      final response = await _client.post(
        Uri.parse(_apiUrl),
        body: {
          'method': 'foods.search',
          'search_expression': query,
          'format': 'json',
        },
      );

      print('Food search API response status code: ${response.statusCode}');
      print('Food search API response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode != 200 || data.containsKey('error')) {
        return [
          {
            "error":
                "API Error: ${response.statusCode} - ${data['error']?['message'] ?? 'Unknown error'}",
          },
        ];
      } else if (data['foods'] != null && data['foods']['food'] != null) {
        final foods = data['foods']['food'];
        return foods is List ? foods : [foods];
      } else {
        return [
          {
            "error":
                "No food found for '$query'. Please try a different search.",
          },
        ];
      }
    } catch (e) {
      return [
        {"error": "A network error occurred: $e"},
      ];
    }
  }

  // Gets the food details for the given food ID.
  Future<Map<String, dynamic>> getFood(String foodId) async {
    try {
      final response = await _client.post(
        Uri.parse(_apiUrl),
        body: {'method': 'food.get.v2', 'food_id': foodId, 'format': 'json'},
      );
      print('Food get API response status code: ${response.statusCode}');
      print('Food get API response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          "error":
              "API Error: ${response.statusCode} - ${data['error']?['message'] ?? 'Unknown error'}",
        };
      } else if (data.containsKey('error')) {
        final errorObj = data['error'];
        if (errorObj is Map && errorObj.containsKey('message')) {
          return {"error": "FatSecret API Error: ${errorObj['message']}"};
        } else {
          return {
            "error":
                "Could not understand the food. An unknown API error occurred.",
          };
        }
      } else if (data['food'] != null) {
        return data['food'];
      } else {
        return {"error": "No details found for food ID '$foodId'."};
      }
    } catch (e) {
      return {"error": "A network error occurred: $e"};
    }
  }
}
