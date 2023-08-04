// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/utils/userscript_examples.dart';

class UserScriptsRevertDialog extends StatefulWidget {
  @override
  _UserScriptsRevertDialogState createState() => _UserScriptsRevertDialogState();
}

class _UserScriptsRevertDialogState extends State<UserScriptsRevertDialog> {
  late ThemeProvider _themeProvider;
  late UserScriptsProvider _userScriptsProvider;

  bool _onlyRestoreNew = true;
  int _missingScripts = 0;

  @override
  void initState() {
    super.initState();
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);

    // Get number missing example scripts
    final exampleScripts = List<UserScriptModel>.from(ScriptsExamples.getScriptsExamples());
    _missingScripts = exampleScripts.length;
    int overwrite = 0;
    for (final existing in _userScriptsProvider.userScriptList) {
      for (final example in exampleScripts) {
        if (existing.exampleCode == example.exampleCode) {
          _missingScripts--;
          overwrite++;
        }
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: _themeProvider.secondBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the card compact
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Flexible(
                      child: Text(
                        "This will restore the example scripts that come with Torn PDA by default!",
                        style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _onlyRestoreNew
                                    ? "Only add example scripts that are not in the list "
                                        "(you are missing $_missingScripts example "
                                        "${_missingScripts == 1 ? "script" : "scripts"})"
                                    : "This will add all missing example scripts and overwrite any "
                                        "changes if they are already in your list "
                                        "(found $overwrite)",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _onlyRestoreNew ? Colors.green[600] : Colors.orange[600],
                                ),
                              ),
                            ),
                            Switch(
                              value: _onlyRestoreNew,
                              inactiveThumbColor: Colors.orange[300],
                              onChanged: (value) {
                                setState(() {
                                  _onlyRestoreNew = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Do it!"),
                          onPressed: () {
                            _userScriptsProvider.restoreExamples(_onlyRestoreNew);
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text("Better not!"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _themeProvider.secondBackground,
                child: CircleAvatar(
                  backgroundColor: _themeProvider.secondBackground,
                  radius: 22,
                  child: const SizedBox(
                    height: 34,
                    width: 34,
                    child: Icon(MdiIcons.backupRestore),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
