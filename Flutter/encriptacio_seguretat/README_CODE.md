# Explicació del Codi - Encriptació i Seguretat

## 📋 Índex

1. [Estructura General](#estructura-general)
2. [main.dart - Punt d'entrada](#maindart)
3. [encryption_form.dart - Interfície d'Usuari](#encryption_formdart)
4. [crypto_service.dart - Lògica Criptogràfica](#crypto_servicedart)
5. [Algoritme Híbrid RSA+AES](#algoritme-híbrid-rsaaes)
6. [Format Binari del Fitxer .enc](#format-binari-del-fitxer-enc)

---

## Estructura General

```
encriptacio_seguretat/
├── lib/
│   ├── main.dart              # Entrada i navegació (NavigationBar)
│   ├── encryption_form.dart   # UI - Formularis i interfície
│   └── crypto_service.dart    # Lògica de xifrat/desxifrat
└── pubspec.yaml               # Dependencies
```

### Flux de l'Aplicació

```
┌─────────────────┐
│  main.dart      │  ← Inicia app, crea NavigationBar
└────────┬────────┘
         │
    ┌────▼─────────────────────────────────────────┐
    │  encryption_form.dart - Interfície           │
    │  ┌─────────────────────────────────────────┐ │
    │  │ TAB: Encriptar                          │ │
    │  │ - Selecciona arxiu                      │ │
    │  │ - Selecciona clau pública               │ │
    │  │ - Clica "Encripta Arxiu"                │ │
    │  └─────────────────────────────────────────┘ │
    │  ┌─────────────────────────────────────────┐ │
    │  │ TAB: Desencriptar                       │ │
    │  │ - Selecciona arxiu .enc                 │ │
    │  │ - Selecciona clau privada               │ │
    │  │ - Selecciona ubicació destin            │ │
    │  │ - Clica "Desencripta Arxiu"             │ │
    │  └─────────────────────────────────────────┘ │
    └────┬──────────────────────────────────────────┘
         │
    ┌────▼──────────────────────────────────────────┐
    │  crypto_service.dart - Criptografia          │
    │  ┌─────────────────────────────────────────┐ │
    │  │ encryptFile()                           │ │
    │  │ 1. Generar clau AES aleatòria           │ │
    │  │ 2. Xifrar arxiu amb AES-256-CBC         │ │
    │  │ 3. Xifrar clau AES amb RSA públic       │ │
    │  │ 4. Guardar format binari: [len][key]... │ │
    │  └─────────────────────────────────────────┘ │
    │  ┌─────────────────────────────────────────┐ │
    │  │ decryptFile()                           │ │
    │  │ 1. Llegir longitud i clau RSA xifrada   │ │
    │  │ 2. Desxifrar clau AES amb RSA privat    │ │
    │  │ 3. Desxifrar arxiu amb AES-256-CBC      │ │
    │  │ 4. Guardar arxiu original                │ │
    │  └─────────────────────────────────────────┘ │
    └────┬──────────────────────────────────────────┘
         │
    ┌────▼─────────────────┐
    │  Arxiu .enc xifrat   │
    └──────────────────────┘
```

---

## main.dart

### Propòsit
Punt d'entrada de l'aplicació. Configura la navegació principal amb NavigationBar (tabs).

### Codi Clau

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encriptació i Seguretat',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
      ),
      home: const MainScreen(),
    );
  }
}
```

**Què fa:**
- `runApp()` - Inicia l'aplicació Flutter
- `MaterialApp` - Configura tema i diseño global (Material Design 3)
- `primarySwatch: Colors.green` - Color principal de la UI

### Navegació

```dart
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encriptació i Seguretat')),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          EncryptionForm(mode: 'encrypt'),  // TAB 0
          EncryptionForm(mode: 'decrypt'),  // TAB 1
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lock), label: 'Encriptar'),
          NavigationDestination(icon: Icon(Icons.lock_open), label: 'Desencriptar'),
        ],
      ),
    );
  }
}
```

**Què fa:**
- `IndexedStack` - Mostra un widget segons l'índex (actua com a contenidor de tabs)
- `NavigationBar` - Barra inferior amb botons per canviar de tab
- `selectedIndex` - Tab actual seleccionat
- `onDestinationSelected` - Es crida quan l'usuari clica un botó de navegació

---

## encryption_form.dart

### Propòsit
Interfície gràfica per seleccionar fitxers, claus i executar encriptació/desencriptació.

### Estructura de Widgets

```dart
class EncryptionForm extends StatefulWidget {
  final String mode; // 'encrypt' o 'decrypt'
  
  @override
  State<EncryptionForm> createState() => _EncryptionFormState();
}
```

### Funció Principal: _handleAction()

```dart
Future<void> _handleAction() async {
  try {
    if (mode == 'encrypt') {
      // Validar que hi ha arxiu i clau pública
      if (selectedFilePath == null || publicKeyPath == null) {
        _showError('Selecciona arxiu i clau pública');
        return;
      }
      
      // Cridar servei de xifrat
      await CryptoService.encryptFile(selectedFilePath!, publicKeyPath!);
      _showSuccess('Arxiu xifrat: ${selectedFilePath}.enc');
      
    } else { // decrypt
      // Validar que hi ha arxiu .enc, clau privada i destí
      if (selectedFilePath == null || privateKeyPath == null || destinationPath == null) {
        _showError('Selecciona arxiu .enc, clau privada i destí');
        return;
      }
      
      // Cridar servei de desxifrat
      await CryptoService.decryptFile(
        selectedFilePath!,
        privateKeyPath!,
        destinationPath!,
      );
      _showSuccess('Arxiu desxifrat: $destinationPath');
    }
  } catch (e) {
    _showError('Error: $e');
  }
}
```

**Què fa:**
1. Valida que els usuari ha seleccionat els fitxers necessaris
2. Crida `CryptoService.encryptFile()` o `decryptFile()`
3. Mostra missatge d'èxit o error

### Funció: _pickFile()

```dart
Future<void> _pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
      });
    }
  } catch (e) {
    _showError('Error seleccionant fitxer: $e');
  }
}
```

**Què fa:**
- Abre un selector de fitxers natiu (del sistema operatiu)
- Guarda la ruta del fitxer seleccionat
- `setState()` - Redibuja la interfície amb el nou fitxer

### Funció: _buildFileSelector()

```dart
Widget _buildFileSelector(
  String label,
  String? selectedPath,
  VoidCallback onTap,
  IconData icon,
  Color color,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            selectedPath ?? 'No seleccionat',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
```

**Què fa:**
- Component reutilitzable que mostra un selector de fitxer
- Mostra icona, etiqueta i ruta del fitxer
- Al clicar, executa la funció `onTap` (que obri el selector de fitxers)
- Disseny visual amb colors personalizats

---

## crypto_service.dart

### Propòsit
Lògica de xifrat i desxifrat RSA+AES híbrid. Aquí està tota la criptografia.

### Dependencies

```dart
import 'package:encrypt/encrypt.dart';           // RSA, AES, claus
import 'package:pointycastle/asymmetric/api.dart'; // Parsing de claus RSA
import 'dart:typed_data';                         // Bytes i operacions binàries
```

---

## Algoritme Híbrid RSA+AES

### Per què Híbrid?

**RSA pura seria lenta i insegura per a fitxers grans:**
- RSA només pot xifrar ~117 bytes (amb 1024-bit) o ~245 bytes (amb 2048-bit)
- RSA és >100x més lent que AES

**Solució: Hybrid encryption**
```
┌─────────────────────────────┐
│   Arxiu original (qualsevol mida)
└──────────────┬──────────────┘
               │
      ┌────────▼─────────┐
      │ AES-256-CBC      │  ← Ràpid per a qualsevol mida
      │ (clau aleatòria) │
      └────────┬─────────┘
               │
      ┌────────▼──────────────────────────┐
      │ Resultat: [IV (16B)][Contingut]   │
      └────────┬──────────────────────────┘
               │
      ┌────────▼──────────────────────────┐
      │ RSA públic xifra la clau AES      │  ← Criptografia segura
      │ (~512 bytes per a RSA-4096)       │
      └────────┬──────────────────────────┘
               │
      ┌────────▼──────────────────────────────────────────────┐
      │ Format final: [longitud(2B)][RSA_key(512B)][IV+content]
      └────────────────────────────────────────────────────────┘
```

---

## Funcions de crypto_service.dart

### 1. _processSSHPublicKey()

```dart
static Future<String> _processSSHPublicKey(String filePath) async {
  final contents = await File(filePath).readAsString();

  if (contents.trim().startsWith('ssh-rsa ')) {
    // Detectar clau SSH i retornar instruccions
    throw 'Clau SSH .pub detectada.\n\n'
        'Executa aquesta comanda al terminal:\n'
        '  ssh-keygen -e -m pem -f "${filePath.replaceAll('.pub', '')}.pub" > ...\n\n'
        'Merci!';
  }

  return contents;
}
```

**Què fa:**
- Llegeix el fitxer de clau
- Detecta si és format SSH (comença per `ssh-rsa `)
- Si és SSH, llança error amb instruccions de conversió
- Si és PEM, retorna el contingut

**Per què:**
- La biblioteca `pointycastle` no entén format SSH
- Necessita PEM per funcionar
- En lloc de fallar silenciosament, mostrem instruccions clares

---

### 2. _validatePrivateKey()

```dart
static Future<String> _validatePrivateKey(String filePath) async {
  final contents = await File(filePath).readAsString();
  final trimmed = contents.trim();

  // Detectar claus SSH privades
  if (trimmed.startsWith('-----BEGIN OPENSSH PRIVATE KEY-----')) {
    throw 'Clau SSH privada detectada.\n\n'
        'Per a esta app, necessites crear un nou parell de claus PEM.\n'
        'La teva clau SSH seguirà intacta per a altres usos.\n\n'
        'Genera:\n'
        '  openssl genrsa -out private_key.pem 4096\n'
        '  openssl rsa -in private_key.pem -pubout -out public_key.pem';
  }

  // Detectar si no és PEM
  if (!trimmed.startsWith('-----BEGIN RSA PRIVATE KEY-----') &&
      !trimmed.startsWith('-----BEGIN PRIVATE KEY-----')) {
    throw 'Format no reconegut...';
  }

  return contents;
}
```

**Què fa:**
- Valida que la clau privada és en format PEM
- Detecta claus SSH privades (format OpenSSH)
- Mostra error si format no és vàlid

**Per què:**
- Protegeix contra formats incompatibles
- Ofereix solucions clares a l'usuari

---

### 3. encryptFile()

**ENCRIPTACIÓ - Pas a Pas**

```dart
static Future<void> encryptFile(String filePath, String publicKeyPath) async {
  try {
    // VALIDACIÓ
    if (!File(filePath).existsSync()) {
      throw 'L\'arxiu a encriptar no existeix: $filePath';
    }
    if (!File(publicKeyPath).existsSync()) {
      throw 'La clau pública no existeix: $publicKeyPath';
    }

    // PAS 1: Llegir i validar clau pública
    String contents = await _processSSHPublicKey(publicKeyPath);
    
    final parser = RSAKeyParser();
    final RSAPublicKey publicKey;

    try {
      publicKey = parser.parse(contents) as RSAPublicKey;
    } catch (e) {
      throw 'Error al llegir la clau pública RSA.\n$e';
    }

    final rsaEncrypter = Encrypter(RSA(publicKey: publicKey));
```

**Explica:**
- Verifica que els fitxers existeixen
- Llegeix el contingut de la clau pública
- Valida que és SSH i pot convertir-se
- Parseja la clau PEM amb `RSAKeyParser()`
- Crea un `Encrypter` per xifrar amb RSA

```dart
    // PAS 2: Generar clau AES aleatòria
    final aesKey = Key.fromSecureRandom(32);  // 32 bytes = 256 bits
    final aesIv = IV.fromSecureRandom(16);    // 16 bytes = 128 bits
    final aesEncrypter = Encrypter(AES(aesKey));
```

**Explica:**
- `Key.fromSecureRandom(32)` - Genera clau AES de 256 bits (aleatòria, segura)
- `IV.fromSecureRandom(16)` - Genera Vector Inicial de 128 bits (aleatòri)
- `Encrypter(AES(aesKey))` - Crea xifrador AES amb la clau generada

**Per què dos claus?**
- Clau AES: Per xifrar el contingut del fitxer (ràpid)
- Clau RSA pública: Per xifrar la clau AES (segur)

```dart
    // PAS 3: Xifrar arxiu amb AES
    final fileData = await File(filePath).readAsBytes();
    final encryptedFile = aesEncrypter.encryptBytes(fileData, iv: aesIv);
```

**Explica:**
- `readAsBytes()` - Llegeix arxiu complet com bytes
- `encryptBytes()` - Xifra els bytes amb AES-256-CBC
- `iv: aesIv` - Usa el IV generat per a deterministicitat d'encriptació

**Format AES-256-CBC:**
```
┌──────────────────────┐
│ IV (sempre 16 bytes) │ ← Necessari per a CBC mode
├──────────────────────┤
│ Contingut xifrat     │ ← Arxiu original xifrat
└──────────────────────┘
```

```dart
    // PAS 4: Xifrar clau AES amb RSA
    final encryptedAesKey = rsaEncrypter.encryptBytes(aesKey.bytes);
```

**Explica:**
- `aesKey.bytes` - Extrae els 32 bytes de la clau AES
- `encryptBytes()` - Xifra amb RSA públic
- Resultat: ~512 bytes (per a RSA-4096)

**Per què?**
- RSA públic xifra → només RSA privat pot desxifrar
- Seguretat: Els bytes desxifrats només amb clau privada

```dart
    // PAS 5: Guardar format binari
    final result = BytesBuilder();
    
    // Longitud en 2 bytes (big-endian)
    int keyLength = encryptedAesKey.bytes.length;
    result.addByte((keyLength >> 8) & 0xFF);  // Byte superior
    result.addByte(keyLength & 0xFF);        // Byte inferior
    
    result.add(encryptedAesKey.bytes);
    result.add(aesIv.bytes);
    result.add(encryptedFile.bytes);

    await File('$filePath.enc').writeAsBytes(result.toBytes());
```

**Explica:**
- `BytesBuilder()` - Construtor para ensamblar bytes
- `addByte()` - Afegeix 1 byte
- `add()` - Afegeix array de bytes
- 2 bytes per longitud: Permet fins a 65.535 bytes (RSA-4096 = ~512 bytes ✓)

**Ordre Final:**
```
[Byte alto (>>8)][Byte bajo]   ← Longitud clau RSA (2 bytes)
[... 512 bytes ...]            ← Clau AES xifrada amb RSA
[... 16 bytes ...]             ← IV
[... rest ...]                 ← Arxiu xifrat amb AES
```

---

### 4. decryptFile()

**DESENCRIPTACIÓ - Pas a Pas**

```dart
static Future<void> decryptFile(
  String encryptedPath,
  String privateKeyPath,
  String destinationPath,
) async {
  try {
    // VALIDACIÓ
    if (!File(encryptedPath).existsSync()) {
      throw 'L\'arxiu encriptat no existeix: $encryptedPath';
    }
    if (!File(privateKeyPath).existsSync()) {
      throw 'La clau privada no existeix: $privateKeyPath';
    }

    // Validar format PEM
    final contents = await _validatePrivateKey(privateKeyPath);
```

**Explica:**
- Verifica fitxers existents
- Valida que clau privada és PEM

```dart
    final parser = RSAKeyParser();
    final RSAPrivateKey privateKey;

    try {
      privateKey = parser.parse(contents) as RSAPrivateKey;
    } catch (e) {
      throw 'Error al llegir la clau privada RSA.\n$e';
    }

    final rsaEncrypter = Encrypter(RSA(privateKey: privateKey));
```

**Explica:**
- Parseja clau privada PEM
- Crea xifrador RSA per desxifrar

```dart
    final allData = await File(encryptedPath).readAsBytes();

    // PAS 1: Extraer longitud clau AES (2 bytes, big-endian)
    int keyLength = ((allData[0] & 0xFF) << 8) | (allData[1] & 0xFF);
    final encryptedAesKey = allData.sublist(2, 2 + keyLength);
```

**Explica:**
- `allData[0]` - Primer byte (part superior longitud)
- `allData[1]` - Segon byte (part inferior longitud)
- `(byte_superior << 8) | byte_inferior` - Reconstrueix número de 2 bytes
- `sublist(2, 2 + keyLength)` - Extrea els N bytes siguents (clau RSA xifrada)

**Exemple:**
```
Fitxer xifrat: [0x01, 0xFF, ... 511 more bytes ..., IV, Contingut]

byte[0] = 0x01      (byte superior)
byte[1] = 0xFF      (byte inferior)
keyLength = (0x01 << 8) | 0xFF = 0x01FF = 511

encryptedAesKey = bytes[2:2+511] = els 511 bytes de la clau RSA xifrada
```

```dart
    // PAS 2: Desxifrar clau AES amb RSA privat
    final decryptedAesKeyBytes = rsaEncrypter.decryptBytes(
      Encrypted(encryptedAesKey),
    );
    final aesKey = Key(Uint8List.fromList(decryptedAesKeyBytes));
```

**Explica:**
- `decryptBytes()` - Desxifra amb RSA privat
- `Encrypted()` - Envoltora para bytes xifrats
- Resultat: 32 bytes (clau AES original)

```dart
    // PAS 3: Extraer IV i contingut xifrat
    final iv = IV(allData.sublist(2 + keyLength, 2 + keyLength + 16));
    final encryptedFileContent = allData.sublist(2 + keyLength + 16);
```

**Explica:**
- IV: 16 bytes després de la clau RSA
- Contingut: Tots els bytes restants

**Visualització:**
```
Fitxer: [Longitud(2B)][RSA_key(511B)][IV(16B)][Contingut xifrat]
                                       ↑       ↑
                   índex = 2+511=513   |       |
                                       IV[513:529]
                                       Content[529:]
```

```dart
    // PAS 4: Desxifrar arxiu amb AES
    final aesEncrypter = Encrypter(AES(aesKey));
    final decryptedFile = aesEncrypter.decryptBytes(
      Encrypted(encryptedFileContent),
      iv: iv,
    );
```

**Explica:**
- Crea xifrador AES amb clau recuperada
- Desxifra contingut amb IV original
- Resultat: Arxiu original

```dart
    // PAS 5: Guardar arxiu original
    await File(destinationPath).writeAsBytes(decryptedFile);
```

**Explica:**
- Escriu els bytes desxifrats a la ubicació destí

---

## Format Binari del Fitxer .enc

### Estructura

```
┌─────────────────────────────────────────────────────┐
│ Offset | Longitud | Contingut                       │
├─────────────────────────────────────────────────────┤
│ 0      │ 2 bytes  │ Longitud clau RSA (big-endian) │
│ 2      │ 512 B    │ Clau AES xifrada amb RSA       │
│ 514    │ 16 B     │ Vector Inicial (IV) AES        │
│ 530    │ N bytes  │ Arxiu xifrat amb AES           │
└─────────────────────────────────────────────────────┘
```

### Exemple Concret

```
Fitxer original: "hola.txt" (4 bytes)

1. Generar clau AES aleatòria:
   AES_key = [0x1a, 0x2b, 0x3c, ..., 32 bytes total]

2. Generar IV:
   IV = [0x9d, 0x8e, 0x7f, ..., 16 bytes total]

3. Xifrar arxiu:
   plaintext  = "hola"
   ciphertext = [0xff, 0xaa, 0x33, 0x77, ...]  (4 bytes, igual mida)

4. Xifrar clau AES amb RSA:
   rsa_encrypted_key = [0x12, 0x34, ..., 511 bytes]

5. Construir fitxer .enc:
   [0x01, 0xFF]                         ← Longitud = 511 (0x01FF big-endian)
   [0x12, 0x34, ..., 511 bytes]         ← Clau RSA xifrada
   [0x9d, 0x8e, 0x7f, ..., 16 bytes]    ← IV
   [0xff, 0xaa, 0x33, 0x77, ...]        ← Arxiu xifrat

Result: File "hola.txt.enc" (~545 bytes)
```

### Avantatges del Format

✅ **Segur:** Longitud de clau no revela informació  
✅ **Flexible:** Suporta qualsevol mida de fitxer  
✅ **Standard:** Segueix convencions de criptografia  
✅ **Compacte:** Cap metadades innecessàries  

---

## Resum de Seguretat

| Aspecto | Implementació |
|---------|---------------|
| **Algoritme RSA** | 4096-bit (seguretat moderna) |
| **Algoritme AES** | AES-256-CBC (estàndard US NIST) |
| **Clau aleatòria** | `fromSecureRandom()` (CSPRNG) |
| **IV aleatòri** | `fromSecureRandom()` per a cada fitxer |
| **Padding** | PKCS#7 (automàtic amb `pointycastle`) |
| **Format** | Big-endian (portabilitat) |

---

## Errors i Validacions

### Validacions Pre-encriptació

```dart
if (!File(filePath).existsSync()) {
  throw 'L\'arxiu a encriptar no existeix';
}
```

✅ Evita errores silents  
✅ Feedback immediat a l'usuari

### Detectió de Format

```dart
if (contents.trim().startsWith('ssh-rsa ')) {
  throw 'Clau SSH detectada. Usa: ssh-keygen -e -m pem...';
}
```

✅ Detecta problemes comuns  
✅ Ofereix solucions automàtiques

### Try-Catch en Funcions Criptogràfiques

```dart
try {
  privateKey = parser.parse(contents) as RSAPrivateKey;
} catch (e) {
  throw 'Error al llegir la clau privada RSA.\n$e';
}
```

✅ Captura errors de parsing  
✅ Mostra error complet a l'usuari

---

## Com Explicar-ho

### Nivel 1: Usuari Final

> "L'app usa dos tipus de criptografia:
> 1. **RSA** per protegir la clau (com una caixa forta)
> 2. **AES** per xifrar el fitxer (ràpid i segur)
> 
> Genera una clau AES aleatòria cada vegada, xifra el fitxer, i tanca la clau AES dins la caixa forta RSA."

### Nivel 2: Estudiant

> "La encriptació **híbrida** combina RSA (asimètric, segur) amb AES (simètric, ràpid):
> - Genera clau AES aleatòria
> - Xifra arxiu amb AES (ràpid)
> - Xifra clau AES amb RSA públic (segur)
> - Desxifra: RSA privat desxifra clau AES, AES desxifra arxiu"

### Nivel 3: Programador

> "Implementó criptografía hibrida en Flutter:
> - `CryptoService` gestiona RSA-4096 + AES-256-CBC
> - Format binari eficiente: [longitud(2B)][RSA_key][IV][contenido_AES]
> - Validaciones de formato: SSH .pub detection + mensajes claros
> - Cifrado determinista con IV fijo para reproducibilidad en desencriptación"

---

## Fitxers de Referència

- **[USAGE.md](USAGE.md)** - Com usar l'app
- **[SSH_TO_PEM.md](SSH_TO_PEM.md)** - Conversió de claus
- **[TECHNICAL.md](TECHNICAL.md)** - Detalls tècnics avançats
- **[SECURITY.md](SECURITY.md)** - Análisis de seguretat
