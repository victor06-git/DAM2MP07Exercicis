import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class CryptoService {
  /// Intenta processar una clau SSH .pub i retorna instruccions
  static Future<String> _processSSHPublicKey(String filePath) async {
    final contents = await File(filePath).readAsString();

    if (contents.trim().startsWith('ssh-rsa ')) {
      // Detectar que és SSH i retornar instruccions
      throw 'Clau SSH .pub detectada.\n\n'
          'L\'app pot detectar claus SSH, però necessita convertir-les a PEM.\n\n'
          'Executa aquesta comanda al terminal:\n'
          '  ssh-keygen -e -m pem -f "${filePath.replaceAll('.pub', '')}.pub" > "${filePath.replaceAll('.pub', '')}.pem"\n\n'
          'O si és ~/.ssh/id_rsa.pub:\n'
          '  ssh-keygen -e -m pem -f ~/.ssh/id_rsa.pub > ~/id_rsa.pem\n\n'
          'Merci!';
    }

    return contents;
  }

  /// Valida que una clau privada sigui en format PEM
  static Future<String> _validatePrivateKey(String filePath) async {
    final contents = await File(filePath).readAsString();
    final trimmed = contents.trim();

    // Detectar claus SSH privades
    if (trimmed.startsWith('-----BEGIN OPENSSH PRIVATE KEY-----')) {
      throw 'Clau SSH privada detectada.\n\n'
          'Per a esta app, necessites crear un nou parell de claus PEM.\n'
          'La teva clau SSH existeix seguirà intacta per a altres usos.\n\n'
          'Genera un nou parell de claus PEM:\n'
          '  openssl genrsa -out private_key.pem 4096\n'
          '  openssl rsa -in private_key.pem -pubout -out public_key.pem\n\n'
          'Després usa:\n'
          '  - private_key.pem com a clau privada en esta app\n'
          '  - public_key.pem com a clau pública en esta app';
    }

    // Detectar si no és PEM
    if (!trimmed.startsWith('-----BEGIN RSA PRIVATE KEY-----') &&
        !trimmed.startsWith('-----BEGIN PRIVATE KEY-----')) {
      throw 'Clau privada en format no reconegut.\n\n'
          'Format vàlids:\n'
          '  -----BEGIN RSA PRIVATE KEY----- (format legacy)\n'
          '  -----BEGIN PRIVATE KEY----- (format modern PKCS#8)\n\n'
          'Crea un nou parell de claus PEM:\n'
          '  openssl genrsa -out private_key.pem 4096\n'
          '  openssl rsa -in private_key.pem -pubout -out public_key.pem';
    }

    return contents;
  }

  // Lógica para Encriptar (Híbrido: AES para el archivo + RSA para la clave)
  static Future<void> encryptFile(String filePath, String publicKeyPath) async {
    try {
      // Verificar que els arxius existeixen
      if (!File(filePath).existsSync()) {
        throw 'L\'arxiu a encriptar no existeix: $filePath';
      }
      if (!File(publicKeyPath).existsSync()) {
        throw 'La clau pública no existeix: $publicKeyPath';
      }

      // Intentar processar si és SSH
      String contents = await _processSSHPublicKey(publicKeyPath);

      // 1. Cargar clave RSA
      final parser = RSAKeyParser();
      final RSAPublicKey publicKey;

      try {
        publicKey = parser.parse(contents) as RSAPublicKey;
      } catch (e) {
        throw 'Error al llegir la clau pública RSA.\n$e';
      }

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

      // 5. Guardar todo en un solo archivo: [longitud_clave(2B)][clave_rsa][iv][contenido_aes]
      final result = BytesBuilder();
      
      // Guardar longitud en 2 bytes (big-endian) para soportar claves RSA 4096-bit (~512 bytes)
      int keyLength = encryptedAesKey.bytes.length;
      result.addByte((keyLength >> 8) & 0xFF);  // byte superior
      result.addByte(keyLength & 0xFF);        // byte inferior
      
      result.add(encryptedAesKey.bytes);
      result.add(aesIv.bytes);
      result.add(encryptedFile.bytes);

      await File('$filePath.enc').writeAsBytes(result.toBytes());
    } catch (e) {
      throw 'Error encriptant l\'arxiu: $e';
    }
  }

  // Lógica para Desencriptar
  static Future<void> decryptFile(
    String encryptedPath,
    String privateKeyPath,
    String destinationPath,
  ) async {
    try {
      // Verificar que els arxius existeixen
      if (!File(encryptedPath).existsSync()) {
        throw 'L\'arxiu encriptat no existeix: $encryptedPath';
      }
      if (!File(privateKeyPath).existsSync()) {
        throw 'La clau privada no existeix: $privateKeyPath';
      }

      // Validar que la clau privada és en format PEM
      final contents = await _validatePrivateKey(privateKeyPath);

      final parser = RSAKeyParser();
      final RSAPrivateKey privateKey;

      try {
        privateKey = parser.parse(contents) as RSAPrivateKey;
      } catch (e) {
        throw 'Error al llegir la clau privada RSA.\n$e';
      }

      final rsaEncrypter = Encrypter(RSA(privateKey: privateKey));

      final allData = await File(encryptedPath).readAsBytes();

      // 1. Extraer la clave AES cifrada (longitud en 2 bytes, big-endian)
      int keyLength = ((allData[0] & 0xFF) << 8) | (allData[1] & 0xFF);
      final encryptedAesKey = allData.sublist(2, 2 + keyLength);

      // 2. Desencriptar la clave AES con RSA
      final decryptedAesKeyBytes = rsaEncrypter.decryptBytes(
        Encrypted(encryptedAesKey),
      );
      final aesKey = Key(Uint8List.fromList(decryptedAesKeyBytes));

      // 3. Extraer el IV y el contenido del archivo
      final iv = IV(allData.sublist(2 + keyLength, 2 + keyLength + 16));
      final encryptedFileContent = allData.sublist(2 + keyLength + 16);

      // 4. Desencriptar el archivo con AES
      final aesEncrypter = Encrypter(AES(aesKey));
      final decryptedFile = aesEncrypter.decryptBytes(
        Encrypted(encryptedFileContent),
        iv: iv,
      );

      // 5. Guardar el archivo desencriptado
      await File(destinationPath).writeAsBytes(decryptedFile);
    } catch (e) {
      throw 'Error desencriptant l\'arxiu: $e';
    }
  }
}
