import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/icon_new.png');
  final bytes = file.readAsBytesSync();
  final original = img.decodeImage(bytes);
  
  if (original == null) {
    print('Failed to decode image');
    return;
  }
  
  final newWidth = (original.width * 1.6).toInt();
  final newHeight = (original.height * 1.6).toInt();
  
  final padded = img.Image(width: newWidth, height: newHeight, numChannels: 4);
  // Isi dengan putih buram (opaque white) secara eksplisit agar Android tidak bisa mengubahnya jadi hitam!
  for (var p in padded) {
    p.r = 255;
    p.g = 255;
    p.b = 255;
    p.a = 255; // OPAQUE WHITE
  }
  
  final dstX = (newWidth - original.width) ~/ 2;
  final dstY = (newHeight - original.height) ~/ 2;
  
  img.compositeImage(padded, original, dstX: dstX, dstY: dstY);
  
  final outBytes = img.encodePng(padded);
  File('assets/images/icon_new_padded.png').writeAsBytesSync(outBytes);
  print('Success');
}
