import 'dart:io';

void main() async {
  final file = File('lib/data/app_state.dart');
  var content = await file.readAsString();

  final startStr = 'const List<Product> sampleProducts = [';
  final startIdx = content.indexOf(startStr);
  if (startIdx == -1) {
    print('Not found');
    return;
  }
  final endIdx = content.indexOf('];', startIdx) + 2;

  final listContent = content.substring(startIdx, endIdx);
  final productSplit = listContent.split('Product(');

  final categoryCounts = <String, int>{};

  for (var i = 1; i < productSplit.length; i++) {
    var prodBody = productSplit[i];
    final categoryMatch = RegExp(r"category:\s*'([^']+)'").firstMatch(prodBody);
    
    if (categoryMatch != null) {
      final category = categoryMatch.group(1)!;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

      // Remove originalPrice for approx 50%
      if (categoryCounts[category]! % 2 == 0) {
        prodBody = prodBody.replaceAll(RegExp(r'\s*originalPrice:\s*\d+(\.\d+)?,?'), '');
        productSplit[i] = prodBody;
      }
    }
  }

  final newListContent = productSplit.join('Product(');
  content = content.replaceRange(startIdx, endIdx, newListContent);

  await file.writeAsString(content);
  print('Done in Dart!');
}
