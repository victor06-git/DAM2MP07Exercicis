import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class CryptoService {
  // Lógica para Encriptar (Híbrido: AES para el archivo + RSA para la clave)
  static Future<void> encryptFile(String filePath, String publicKeyPath) async {
    final contents = await File(publicKeyPath).readAsString();

    // 1. Cargar clave RSA
    final parser = RSAKeyParser();
    final RSAPublicKey publicKey = parser.parse(contents) as RSAPublicKey;
    final rsaEncrypter = Encrypter(RSA(publicKey: publicKey));

    // 2. Generar clave AES aleatoria (32 bytes para AES-256)
    final aesKey = Key.fromSecureRandom(32);
    final aesIv = IV.fromSecureRandom(16);
    final aesEncrypter = Encrypter(AES(aesKey));

    // 3. Cifrar el archivo con AES
    final fileData = await File(filePath).readAsBytes();
    final encryptedFile = aesEncrypter.encryptBytes(fileData, iv: aesIv);

    // 4. Cifrar la clave AES con RSA (esto sí cabe en RSA)
    final encryptedAesKey = rsaEncrypter.encryptBytes(aesKey.bytes);

    // 5. Guardar todo en un solo archivo: [longitud_clave][clave_rsa][iv][contenido_aes]
    final result = BytesBuilder();
    result.addByte(
      encryptedAesKey.bytes.length,
    ); // Guardamos cuánto mide la clave cifrada
    result.add(encryptedAesKey.bytes);
    result.add(aesIv.bytes);
    result.add(encryptedFile.bytes);

    await File('$filePath.enc').writeAsBytes(result.toBytes());
  }

  // Lógica para Desencriptar
  static Future<void> decryptFile(
    String encryptedPath,
    String privateKeyPath,
    String destinationPath,
  ) async {
    final contents = await File(privateKeyPath).readAsString();
    final parser = RSAKeyParser();
    final RSAPrivateKey privateKey = parser.parse(contents) as RSAPrivateKey;
    final rsaEncrypter = Encrypter(RSA(privateKey: privateKey));

    final allData = await File(encryptedPath).readAsBytes();

    // 1. Extraer la clave AES cifrada
    int keyLength = allData[0];
    final encryptedAesKey = allData.sublist(1, 1 + keyLength);

    // 2. Desencriptar la clave AES con RSA
    final decryptedAesKeyBytes = rsaEncrypter.decryptBytes(
      Encrypted(encryptedAesKey),
    );
    final aesKey = Key(Uint8List.fromList(decryptedAesKeyBytes));

    // 3. Extraer el IV y el contenido del archivo
    final iv = IV(allData.sublist(1 + keyLength, 1 + keyLength + 16));
    final encryptedFileContent = allData.sublist(1 + keyLength + 16);

    // 4. Desencriptar el archivo con AES
    final aesEncrypter = Encrypter(AES(aesKey));
    final decryptedFile = aesEncrypter.decryptBytes(
      Encrypted(encryptedFileContent),
      iv: iv,
    );

    await File(destinationPath).writeAsBytes(decryptedFile);
  }
}
