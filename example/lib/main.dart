import 'package:astryx_flutter/astryx_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const AstryxExampleApp());

class AstryxExampleApp extends StatefulWidget {
  const AstryxExampleApp({super.key});

  @override
  State<AstryxExampleApp> createState() => _AstryxExampleAppState();
}

class _AstryxExampleAppState extends State<AstryxExampleApp> {
  late final AstryxFramework _framework = AstryxFramework.standard(
    restBaseUri: Uri.parse('https://api.example.com/'),
    graphqlEndpoint: Uri.parse('https://api.example.com/graphql'),
  );
  var _themeMode = ThemeMode.system;

  @override
  void dispose() {
    _framework.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astryx Flutter',
      debugShowCheckedModeBanner: false,
      theme: AstryxTheme.light(),
      darkTheme: AstryxTheme.dark(),
      themeMode: _themeMode,
      home: AstryxShowcasePage(
        registry: _framework.registry,
        onToggleBrightness: () {
          setState(() {
            _themeMode = switch (_themeMode) {
              ThemeMode.light => ThemeMode.dark,
              ThemeMode.dark || ThemeMode.system => ThemeMode.light,
            };
          });
        },
      ),
    );
  }
}
