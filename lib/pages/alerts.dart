// Dart imports:
import 'dart:io';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/faction/faction_attacks_model.dart';
// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/pages/alerts/stockmarket_alerts_page.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/alerts/events_filter_dialog.dart';
import 'package:torn_pda/widgets/alerts/loot_npc_dialog.dart';
import 'package:torn_pda/widgets/alerts/refills_requested_dialog.dart';
import 'package:torn_pda/widgets/loot/loot_rangers_explanation.dart';

class AlertsSettings extends StatefulWidget {
  final Function stockMarketInMenuCallback;

  const AlertsSettings(this.stockMarketInMenuCallback);

  @override
  AlertsSettingsState createState() => AlertsSettingsState();
}

class AlertsSettingsState extends State<AlertsSettings> {
  FirebaseUserModel? _firebaseUserModel;

  Future? _getFirebaseAndTornDetails;

  bool _factionApiAccess = false;
  bool _factionApiAccessCheckError = false;

  late SettingsProvider _settingsProvider;
  ThemeProvider? _themeProvider;
  late WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _getFirebaseAndTornDetails = Future.wait([
      firestore.getUserProfile(),
      _getFactionApiAccess(),
    ]);
    analytics.setCurrentScreen(screenName: 'alerts');

    routeWithDrawer = true;
    routeName = "alerts";
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider!.canvas,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider!.canvas,
        child: FutureBuilder(
          future: _getFirebaseAndTornDetails,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data[0] is FirebaseUserModel) {
                _firebaseUserModel ??= snapshot.data[0] as FirebaseUserModel?;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Alerts are automatic notifications that you only "
                          "need to activate once. However, you will normally be notified "
                          "earlier than with manual notifications; also, notifications might be delayed "
                          "due to network status or device throttling.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.travelNotification ?? false,
                          title: const Text("Travel"),
                          subtitle: const Text(
                            "Get notified just before you arrive",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.travelNotification = value;
                            });
                            firestore.subscribeToTravelNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.foreignRestockNotification ?? false,
                          title: const Text("Foreign stocks"),
                          subtitle: const Text(
                            "Get notified whenever new stocks are put in the market abroad. NOTE: in order to activate "
                            "specific stock alerts, you need to go to the stocks page (Travel section) to activate the ones you are interested in!",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.foreignRestockNotification = value;
                            });
                            firestore.subscribeToForeignRestockNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.energyNotification ?? false,
                          title: const Text("Energy full"),
                          subtitle: const Text(
                            "Get notified once you reach full energy",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.energyNotification = value;
                            });
                            firestore.subscribeToEnergyNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.nerveNotification ?? false,
                          title: const Text("Nerve full"),
                          subtitle: const Text(
                            "Get notified once you reach full nerve",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.nerveNotification = value;
                            });
                            firestore.subscribeToNerveNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.hospitalNotification ?? false,
                          title: const Text("Hospital admission and release"),
                          subtitle: const Text(
                            "If you are offline, you'll be notified if you are "
                            "hospitalized, revived or out of hospital",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.hospitalNotification = value;
                            });
                            firestore.subscribeToHospitalNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.drugsNotification ?? false,
                          title: const Text("Drugs cooldown"),
                          subtitle: const Text(
                            "Get notified when your drugs cooldown "
                            "has expired",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.drugsNotification = value;
                            });
                            firestore.subscribeToDrugsNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.medicalNotification ?? false,
                          title: const Text("Medical cooldown"),
                          subtitle: const Text(
                            "Get notified when your medical cooldown "
                            "has expired",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.medicalNotification = value;
                            });
                            firestore.subscribeToMedicalNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.boosterNotification ?? false,
                          title: const Text("Booster cooldown"),
                          subtitle: const Text(
                            "Get notified when your booster cooldown "
                            "has expired",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.boosterNotification = value;
                            });
                            firestore.subscribeToBoosterNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.lootAlerts.isNotEmpty,
                          title: const Text("Loot"),
                          subtitle: const Text(
                            "Get notified when an NPC is about to reach level 4 or 5 (between 5 and 6 "
                            "minutes in advance)",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) async {
                            await showDialog(
                              useRootNavigator: false,
                              context: context,
                              barrierDismissible: true,
                              builder: (BuildContext context) {
                                return LootAlertsDialog(
                                  userModel: _firebaseUserModel,
                                );
                              },
                            );
                            setState(() {
                              // Refresh lootAlerts (check or uncheck box)
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.lootRangersAlerts ?? false,
                          title: Row(
                            children: [
                              const Text("Loot Rangers attack"),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () async {
                                  await showDialog(
                                    useRootNavigator: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return LootRangersExplanationDialog(themeProvider: _themeProvider);
                                    },
                                  );
                                },
                                child: const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                ),
                              )
                            ],
                          ),
                          subtitle: const Text(
                            "Get notified shortly before a Loot Ranger attack is about to take place "
                            ", including attack order",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) async {
                            setState(() {
                              _firebaseUserModel?.lootRangersAlerts = value;
                            });
                            firestore.subscribeToLootRangersNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.racingNotification ?? false,
                          title: const Text("Racing"),
                          subtitle: const Text(
                            "Get notified when you cross the finish line",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.racingNotification = value;
                            });
                            firestore.subscribeToRacingNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.messagesNotification ?? false,
                          title: const Text("Messages"),
                          subtitle: const Text(
                            "Get notified when you receive new messages",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.messagesNotification = value;
                            });
                            firestore.subscribeToMessagesNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.eventsNotification ?? false,
                          title: const Text("Events"),
                          subtitle: const Text(
                            "Get notified when you receive new events",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.eventsNotification = value;
                            });
                            firestore.subscribeToEventsNotification(value);
                          },
                        ),
                      ),
                      if (_firebaseUserModel!.eventsNotification!)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  "Filter out events",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right_outlined),
                                onPressed: () {
                                  showDialog(
                                    useRootNavigator: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return EventsFilterDialog(
                                        userModel: _firebaseUserModel,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.refillsNotification ?? false,
                          title: const Text("Refills"),
                          subtitle: const Text(
                            "Get notified if you still have unused refills",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.refillsNotification = value;
                            });
                            firestore.subscribeToRefillsNotification(value);
                          },
                        ),
                      ),
                      if (_firebaseUserModel!.refillsNotification!)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  "Time",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              DropdownButton<int>(
                                value: _firebaseUserModel?.refillsTime,
                                items: const [
                                  DropdownMenuItem(
                                    value: 16,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "16:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 17,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "17:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 18,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "18:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 19,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "19:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 20,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "20:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 21,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "21:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 22,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "22:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 23,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "23:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) async {
                                  setState(() {
                                    _firebaseUserModel?.refillsTime = value;
                                  });
                                  firestore.setRefillTime(value);
                                },
                              ),
                            ],
                          ),
                        ),
                      if (_firebaseUserModel!.refillsNotification!)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  "Choose refills",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right_outlined),
                                onPressed: () {
                                  showDialog(
                                    useRootNavigator: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return RefillsRequestedDialog(
                                        userModel: _firebaseUserModel,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 15, 0),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Stock market gain/loss"),
                              GestureDetector(
                                child: const Icon(Icons.keyboard_arrow_right_outlined),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return StockMarketAlertsPage(
                                          fbUser: _firebaseUserModel,
                                          calledFromMenu: false,
                                          stockMarketInMenuCallback: widget.stockMarketInMenuCallback,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          subtitle: const Text(
                            "Configure price gain/loss alerts for any traded company",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.factionAssistMessage ?? false,
                          title: const Text("Faction assist messages"),
                          subtitle: const Text(
                            "Receive attack assist messages manually triggered by your faction mates",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.factionAssistMessage = value;
                            });
                            firestore.toggleFactionAssistMessage(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel!.retalsNotification ?? false,
                          title: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Text(
                                  "Retaliation",
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: _factionApiAccess ? Colors.green : Colors.orange,
                                  ),
                                  // Quick update
                                  onTap: () async {
                                    await showDialog(
                                      useRootNavigator: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return _retalsGeneralExplanation();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          subtitle: const Text(
                            "Get notified whenever it is possible to initiate a retaliation attack.",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (enabled) async {
                            if (!enabled!) {
                              setState(() {
                                _firebaseUserModel?.retalsNotification = enabled;
                              });
                              firestore.toggleRetaliationNotification(enabled);
                              return;
                            }

                            if (_factionApiAccess) {
                              setState(() {
                                _firebaseUserModel?.retalsNotification = enabled;
                              });
                              firestore.toggleRetaliationNotification(enabled);
                            } else {
                              String message = "";
                              int seconds = 0;

                              if (!_factionApiAccessCheckError) {
                                setState(() {
                                  _firebaseUserModel?.retalsNotification = enabled;
                                });
                                firestore.toggleRetaliationNotification(enabled, host: false);
                                message = "You have no faction API permissions (talk to your leadership about it).\n\n"
                                    "This alert has been activated, but it won't work unless someone with proper "
                                    "permissions in your faction activates it as well.";
                                seconds = 10;
                              } else {
                                message = "It's not possible to activate this alert now (Torn PDA can't verify whether "
                                    "you have proper Faction API permissions).\n\nPlease try again later!";
                                seconds = 6;
                              }

                              BotToast.showText(
                                clickClose: true,
                                text: message,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.orange[900]!,
                                duration: Duration(seconds: seconds),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            }
                          },
                        ),
                      ),
                      if (_firebaseUserModel!.retalsNotification! && _factionApiAccess)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: Row(
                                  children: [
                                    const Flexible(
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 10, right: 5),
                                        child: Text(
                                          "Single target opens browser",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: GestureDetector(
                                        child: const Icon(Icons.info_outline_rounded),
                                        // Quick update
                                        onTap: () async {
                                          await showDialog(
                                            useRootNavigator: false,
                                            context: context,
                                            builder: (BuildContext context) {
                                              return _retalsNotificationExplanation();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _settingsProvider.singleRetaliationOpensBrowser,
                                onChanged: (enabled) {
                                  setState(() {
                                    _settingsProvider.setSingleRetaliationOpensBrowser = enabled;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 60),
                    ],
                  ),
                );
              } else {
                return _connectError();
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text('Alerts'),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
          if (scaffoldState != null) {
            if (_webViewProvider.webViewSplitActive &&
                _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
              scaffoldState.openEndDrawer();
            } else {
              scaffoldState.openDrawer();
            }
          }
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(
            MdiIcons.hammer,
          ),
          onPressed: () {
            showDialog(
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) {
                return _troubleShootingDialog();
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.info_outline,
          ),
          onPressed: () {
            showDialog(
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) {
                return _alertsInfoDialog();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _connectError() {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'There was an error contacting the server!',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Please try again later.',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'If this problem reoccurs, please log out from Torn API (remove '
            'you API Key in the Settings section and insert it again). Sorry for '
            'the inconvenience!',
          ),
        ],
      ),
    );
  }

  Widget _alertsInfoDialog() {
    return AlertDialog(
      title: const Text(
        "Alerts",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      content: const SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Note: if you don't use Torn PDA for more than 5 days, "
                "all notifications will be turned off automatically. "
                "\n\nThis is to prevent the over usage of resources. "
                "Please make sure you return back to the app once a "
                "week to get uninterrupted service.",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  Widget _troubleShootingDialog() {
    return AlertDialog(
      title: const Text(
        "Troubleshooting",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      content: const SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "If you are having issues receiving alerts, this will try to reset your server-based "
                "configuration and notifications channels. "
                "\n\nYou won't lose any settings or configurations. "
                "If it doesn't solve the problem, however, you can contact us directly in Discord."
                "\n\nTap Reset below to proceed.",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Reset"),
          onPressed: () async {
            Navigator.of(context).pop();

            try {
              final userProv = context.read<UserDetailsProvider>();

              // We save the key because the API call will reset it
              final savedKey = userProv.basic!.userApiKey;

              final dynamic myProfile = await Get.find<ApiCallerController>().getOwnProfileBasic();

              if (myProfile is OwnProfileBasic) {
                myProfile
                  ..userApiKey = savedKey
                  ..userApiKeyValid = true;

                FirebaseUserModel? fb = await firestore.uploadUsersProfileDetail(myProfile, userTriggered: true);
                setState(() {
                  _firebaseUserModel = fb;
                });
                await firestore.uploadLastActiveTime(DateTime.now().millisecondsSinceEpoch);

                if (Platform.isAndroid) {
                  final alertsVibration = await Prefs().getVibrationPattern();
                  // Deletes current channels and create new ones
                  reconfigureNotificationChannels(mod: alertsVibration);
                  // Update channel preferences
                  firestore.setVibrationPattern(alertsVibration);
                }

                BotToast.showText(
                  text: "Reset successful",
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.green[800]!,
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );

                return;
              }
            } catch (e) {
              // Same message below
            }

            BotToast.showText(
              text: "There was an error updating the database, try again later!",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.orange[800]!,
              duration: const Duration(seconds: 5),
              contentPadding: const EdgeInsets.all(10),
            );
          },
        ),
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  AlertDialog _retalsGeneralExplanation() {
    return AlertDialog(
      title: const Text("Retaliation alerts"),
      content: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NOTE: you will not receive retaliation alerts when traveling, nor when the attack took place abroad "
                  "and you are in Torn, nor if the attack took place in Torn and you are abroad.\n\nHowever, due to API limits, "
                  "you might receive spurious notifications when you are abroad but in a different country from the attack.\n\n"
                  "Depending on your API permissions, more detailed information about the attack, location, etc., "
                  "will be available in the Chaining section of the app, as explained below:\n\n",
                  style: TextStyle(fontSize: 13),
                ),
                if (!_factionApiAccess)
                  const Text(
                    "You DO NOT HAVE Faction API access\n\n",
                    style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    "You HAVE Faction API access\n\n",
                    style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                if (!_factionApiAccess)
                  const Text(
                    "For retaliation notifications to work, at least one member of your faction with API access "
                    " privileges must have this alert active in Torn PDA. If this condition is not met at some point, "
                    "Torn PDA will notify you about it so that you can discuss this internally.\n\n",
                    style: TextStyle(fontSize: 13),
                  )
                else
                  const Text(
                    "For retaliation notifications to work, at least one member of your faction with API access "
                    " privileges must have this alert active in Torn PDA. This can be you or any other member.\n\n",
                    style: TextStyle(fontSize: 13),
                  ),
                if (!_factionApiAccess)
                  const Text(
                    "As you have no Faction API access, but the above criteria is met, you will be able to receive "
                    "notifications, but you won't be able to access the Retaliation target list (in Chaining).",
                    style: TextStyle(fontSize: 13),
                  )
                else
                  const Text(
                    "Members of your faction with no Faction API access will be able to receive "
                    "notifications, but they won't be able to access the Retaliation target list (in Chaining).",
                    style: TextStyle(fontSize: 13),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  AlertDialog _retalsNotificationExplanation() {
    return AlertDialog(
      title: const Text("Retaliation notification"),
      content: const Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "By default, on tapping a retaliation notification you will be redirected to the Retaliation "
                  "section (inside of Chaining); this is independent of how many targets are available for retaliation "
                  "at the same time.\n\nIn this section you can have a look at the stats, target status, etc."
                  "\n\nHowever, if you enable this option, retaliation notifications with a single target "
                  "will automatically open the browser and take you straight to the attack page.\n\n"
                  "NOTE: this will have no effect if you have no faction API permissions, as the browser will "
                  "open in any case.",
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  Future _getFactionApiAccess() async {
    // Assess whether we have permits
    final attacksResult = await Get.find<ApiCallerController>().getFactionAttacks();
    if (attacksResult is FactionAttacksModel) {
      _factionApiAccess = true;
    } else if (attacksResult is ApiError) {
      _factionApiAccess = false;
      if (!attacksResult.errorReason.contains("incorrect ID-entity relation")) {
        _factionApiAccessCheckError = true;
      }
    }
  }
}
