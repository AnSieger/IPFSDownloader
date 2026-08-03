import 'package:flutter/widgets.dart';

import 'src/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await bootstrapApplication();
  runApp(app);
}
