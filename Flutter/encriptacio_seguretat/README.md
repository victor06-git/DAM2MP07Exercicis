# Encriptació i Seguretat

Aplicació Flutter per a encriptar i desencriptar arxius de manera segura usant **criptografia RSA** de clau pública/privada.

## 🎯 Funcionalitats Principals

- **Encriptar Arxius**: Usa una clau pública RSA per protegir els teus arxius
- **Desencriptar Arxius**: Recupera els arxius originals amb la clau privada
- **Xifratge Híbrid**: Combina RSA per a claus i AES-256 per a contingut
- **Interfície Intuïtiva**: Navegador de fitxers integrat i interfície clara

## 🚀 Inici Ràpid

### Requisits

- Flutter 3.10.7+
- Dart 3.10.7+

### Instal·lació de Dependències

```bash
flutter pub get
```

### Execució en Desenvolupament

```bash
flutter run
```

## 📦 Compilació per a Distribució

### Linux

```bash
flutter build linux --release
# Executable: build/linux/x64/release/bundle/encriptacio_seguretat
```

### Windows

```bash
flutter build windows --release
# Executable: build/windows/runner/Release/encriptacio_seguretat.exe
```

### macOS

```bash
flutter build macos --release
# App: build/macos/Build/Products/Release/encriptacio_seguretat.app
```

## 📖 Documentació Completa

Consulta [USAGE.md](USAGE.md) per a:

- Instruccions detallades d'ús
- Com generar claus RSA
- Descripció tècnica del format
- Resolució de problemes
- Consideracions de seguretat

## 🔒 Seguretat

- **RSA 4096-bit** per a xifratge de claus de sessió
- **AES-256-CBC** per a xifratge de contingut
- Claus aleatòries generades per a cada encriptació
- No es guarden claus en memòria innecessàriament

## 🏗️ Estructura del Projecte

```text
lib/
├── main.dart              # Punt d'entrada i navegació
├── encryption_form.dart   # Interfície gràfica
└── crypto_service.dart    # Lògica de criptografia
```

## 📚 Tecnologies

- **Flutter**: Framework per a interfície gràfica
- **Dart**: Llenguatge de programació
- **encrypt**: Biblioteca de criptografia
- **file_picker**: Selector de fitxers
- **pointycastle**: Primitives criptogràfiques

## ⚖️ Llicència

Exercici 09 - DAM2MP07 - Albert Palacios Jiménez, 2024

