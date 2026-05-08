import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

// Servei encarregat de tota la lògica criptogràfica de l'app.
// Usa encriptació híbrida: AES-256 per al contingut + RSA per a la clau AES.
// Això permet xifrar arxius de qualsevol mida (RSA sol té límit de bytes).
class CryptoService {
  // Comprova si el fitxer és una clau SSH .pub (format no compatible).
  // Si ho és, llança un error amb instruccions per convertir-la a PEM.
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

  // Valida que la clau privada sigui en format PEM compatible (RSA o PKCS#8).
  // Rebutja claus SSH privades (OpenSSH) i formats no reconeguts.
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

  // Encripta un arxiu usant el sistema híbrid RSA + AES.
  // Resultat: arxiu original + extensió .enc
  static Future<void> encryptFile(String filePath, String publicKeyPath) async {
    try {
      // Verificar que els arxius existeixen abans de continuar
      if (!File(filePath).existsSync()) {
        throw 'L\'arxiu a encriptar no existeix: $filePath';
      }
      if (!File(publicKeyPath).existsSync()) {
        throw 'La clau pública no existeix: $publicKeyPath';
      }

      // Llegeix i valida la clau pública (detecta si és SSH i avisa)
      String contents = await _processSSHPublicKey(publicKeyPath);

      // 1. Parseja la clau pública RSA des del contingut PEM
      final parser = RSAKeyParser();
      final RSAPublicKey publicKey;
      try {
        publicKey = parser.parse(contents) as RSAPublicKey;
      } catch (e) {
        throw 'Error al llegir la clau pública RSA.\n$e';
      }
      final rsaEncrypter = Encrypter(RSA(publicKey: publicKey));

      // 2. Genera una clau AES aleatòria de 256 bits (32 bytes) i un IV de 128 bits (16 bytes).
      //    Cada encriptació usa claus diferents → més seguretat.
      final aesKey = Key.fromSecureRandom(32);
      final aesIv = IV.fromSecureRandom(16);
      final aesEncrypter = Encrypter(AES(aesKey));

      // 3. Xifra el contingut de l'arxiu amb AES-256
      //    AES pot xifrar arxius de qualsevol mida, RSA no.
      final fileData = await File(filePath).readAsBytes();
      final encryptedFile = aesEncrypter.encryptBytes(fileData, iv: aesIv);

      // 4. Xifra la clau AES amb RSA (la clau AES és petita, cabe en RSA)
      //    Només qui tingui la clau privada podrà recuperar la clau AES.
      final encryptedAesKey = rsaEncrypter.encryptBytes(aesKey.bytes);

      // 5. Construeix l'arxiu final amb tot concatenat:
      //    [ 2 bytes: longitud clau RSA ] [ clau AES xifrada ] [ IV 16B ] [ contingut AES ]
      //    Els 2 primers bytes (big-endian) indiquen quants bytes ocupa la clau xifrada,
      //    necessari per saber on acaba la clau i on comença l'IV al desxifrar.
      final result = BytesBuilder();
      int keyLength = encryptedAesKey.bytes.length;
      result.addByte(
        (keyLength >> 8) & 0xFF,
      ); // byte superior (més significatiu)
      result.addByte(keyLength & 0xFF); // byte inferior (menys significatiu)
      result.add(encryptedAesKey.bytes); // clau AES xifrada amb RSA
      result.add(aesIv.bytes); // IV necessari per desxifrar AES
      result.add(encryptedFile.bytes); // contingut de l'arxiu xifrat amb AES

      // Guarda l'arxiu resultant amb extensió .enc
      await File('$filePath.enc').writeAsBytes(result.toBytes());
    } catch (e) {
      throw 'Error encriptant l\'arxiu: $e';
    }
  }

  // Desxifra un arxiu .enc generat per encryptFile.
  // Necessita la clau privada RSA corresponent a la pública usada per xifrar.
  static Future<void> decryptFile(
    String encryptedPath,
    String privateKeyPath,
    String destinationPath,
  ) async {
    try {
      // Verificar que els arxius existeixen abans de continuar
      if (!File(encryptedPath).existsSync()) {
        throw 'L\'arxiu encriptat no existeix: $encryptedPath';
      }
      if (!File(privateKeyPath).existsSync()) {
        throw 'La clau privada no existeix: $privateKeyPath';
      }

      // Valida i llegeix la clau privada en format PEM
      final contents = await _validatePrivateKey(privateKeyPath);

      // Parseja la clau privada RSA
      final parser = RSAKeyParser();
      final RSAPrivateKey privateKey;
      try {
        privateKey = parser.parse(contents) as RSAPrivateKey;
      } catch (e) {
        throw 'Error al llegir la clau privada RSA.\n$e';
      }
      final rsaEncrypter = Encrypter(RSA(privateKey: privateKey));

      // Llegeix tots els bytes de l'arxiu xifrat
      final allData = await File(encryptedPath).readAsBytes();

      // 1. Llegeix els 2 primers bytes per saber la longitud de la clau AES xifrada
      //    (big-endian: byte[0] és el més significatiu)
      int keyLength = ((allData[0] & 0xFF) << 8) | (allData[1] & 0xFF);
      final encryptedAesKey = allData.sublist(2, 2 + keyLength);

      // 2. Desxifra la clau AES usant la clau privada RSA
      //    Només la clau privada correcta pot recuperar la clau AES original
      final decryptedAesKeyBytes = rsaEncrypter.decryptBytes(
        Encrypted(encryptedAesKey),
      );
      final aesKey = Key(Uint8List.fromList(decryptedAesKeyBytes));

      // 3. Extreu l'IV (16 bytes just després de la clau) i el contingut xifrat
      final iv = IV(
        allData.sublist(2 + keyLength, 2 + keyLength + 16),
      ); // Initialization Vector
      final encryptedFileContent = allData.sublist(2 + keyLength + 16);

      // 4. Desxifra el contingut de l'arxiu amb AES usant la clau i l'IV recuperats
      final aesEncrypter = Encrypter(AES(aesKey));
      final decryptedFile = aesEncrypter.decryptBytes(
        Encrypted(encryptedFileContent),
        iv: iv,
      );

      // 5. Guarda l'arxiu desxifrat a la ruta de destinació
      await File(destinationPath).writeAsBytes(decryptedFile);
    } catch (e) {
      throw 'Error desencriptant l\'arxiu: $e';
    }
  }
}
