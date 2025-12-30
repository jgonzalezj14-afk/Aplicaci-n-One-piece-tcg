import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';

class PdfService {
  
  Future<List<String>> generateDeckPdf({
    required DeckModel deck,
    required String deckName,
    required Function(double progress, String message) onProgress,
    required Function(String error) onError,
  }) async {
    
    List<String> errorReport = [];

    if (deck.cards.isEmpty && deck.leader == null) {
      onError("El mazo está vacío.");
      return [];
    }

    List<CardModel> allCardsToPrint = [];
    if (deck.leader != null) allCardsToPrint.add(deck.leader!);
    allCardsToPrint.addAll(deck.cards);

    int totalCards = allCardsToPrint.length;
    int downloadedCount = 0;

    try {
      final doc = pw.Document();
      Map<int, Uint8List> imagesMap = {};
      
      int batchSize = kIsWeb ? 8 : 4; 

      for (int i = 0; i < totalCards; i += batchSize) {
        int end = (i + batchSize < totalCards) ? i + batchSize : totalCards;
        List<Future<void>> batchFutures = [];

        for (int j = i; j < end; j++) {
          batchFutures.add(Future(() async {
            var card = allCardsToPrint[j];
            try {
              String url = card.imageUrl;
              
              if (kIsWeb) {
                if (url.contains('?')) {
                  url += "&t=${DateTime.now().millisecondsSinceEpoch}";
                } else {
                  url += "?t=${DateTime.now().millisecondsSinceEpoch}";
                }
              }

              final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
              
              if (response.statusCode == 200) {
                imagesMap[j] = response.bodyBytes;
              } else {
                errorReport.add("- ${card.name} (${card.cardNumber}): Error ${response.statusCode}");
              }
            } catch (e) {
              debugPrint("Fallo descarga carta $j: $e");
              errorReport.add("- ${card.name} (${card.cardNumber}): No se pudo descargar.");
            } finally {
              downloadedCount++;
              onProgress(downloadedCount / totalCards, "Procesando carta $downloadedCount de $totalCards...");
            }
          }));
        }
        
        await Future.wait(batchFutures);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      List<Uint8List> sortedImages = [];
      for (int i = 0; i < totalCards; i++) {
        if (imagesMap.containsKey(i)) sortedImages.add(imagesMap[i]!);
      }

      if (sortedImages.isEmpty) {
        onError("Error crítico: Ninguna imagen se pudo descargar.");
        return errorReport;
      }

      if (errorReport.isNotEmpty) {
        onProgress(1.0, "Generando PDF con ${errorReport.length} avisos...");
      } else {
        onProgress(1.0, "Generando documento...");
      }
      
      await Future.delayed(const Duration(milliseconds: 100));

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return [
              pw.Wrap(
                spacing: 2,
                runSpacing: 2,
                children: sortedImages.map((imageBytes) {
                  return pw.Container(
                    width: 180,
                    height: 252,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                    ),
                    child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.fill),
                  );
                }).toList(),
              )
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Mazo_${deckName.isEmpty ? "OnePiece" : deckName}',
      );

      return errorReport;

    } catch (e) {
      onError("Error interno: $e");
      return ["Error crítico del sistema"];
    }
  }
}