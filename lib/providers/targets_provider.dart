// Dart imports:
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/models/chaining/target_backup_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_export.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_import.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class AddTargetResult {
  bool success;
  String errorReason = "";
  String targetId = "";
  String targetName = "";

  AddTargetResult({@required this.success, this.errorReason, this.targetId, this.targetName});
}

class UpdateTargetsResult {
  bool success;
  int numberErrors;
  int numberSuccessful;

  UpdateTargetsResult(
      {@required this.success, @required this.numberErrors, @required this.numberSuccessful});
}

class TargetsProvider extends ChangeNotifier {
  List<TargetModel> _targets = [];
  UnmodifiableListView<TargetModel> get allTargets => UnmodifiableListView(_targets);

  List<TargetModel> _oldTargetsList = [];

  String _currentWordFilter = '';
  String get currentWordFilter => _currentWordFilter;

  List<String> _currentColorFilterOut = [];
  List<String> get currentColorFilterOut => _currentColorFilterOut;

  TargetSortType _currentSort;

  String _userKey = '';

  OwnProfileBasic _userDetails;
  TargetsProvider(this._userDetails) {
    restorePreferences();
  }

  /// If providing [notes] or [notesColor], ensure that they are within 200
  /// chars and of an acceptable color (green, blue, red).
  Future<AddTargetResult> addTarget({
    @required String targetId,
    @required dynamic attacks,
    String notes = '',
    String notesColor = '',
  }) async {
    for (var tar in _targets) {
      if (tar.playerId.toString() == targetId) {
        return AddTargetResult(
          success: false,
          errorReason: 'Target already exists!',
        );
      }
    }

    dynamic myNewTargetModel = await TornApiCaller.target(_userKey, targetId).getTarget;

    if (myNewTargetModel is TargetModel) {
      _getRespectFF(attacks, myNewTargetModel);
      _getTargetFaction(myNewTargetModel);
      myNewTargetModel.personalNote = notes;
      myNewTargetModel.personalNoteColor = notesColor;
      _targets.add(myNewTargetModel);
      sortTargets(_currentSort);
      notifyListeners();
      _saveTargetsSharedPrefs();
      return AddTargetResult(
        success: true,
        targetId: myNewTargetModel.playerId.toString(),
        targetName: myNewTargetModel.name,
      );
    } else {
      // myNewTargetModel is ApiError
      var myError = myNewTargetModel as ApiError;
      notifyListeners();
      return AddTargetResult(
        success: false,
        errorReason: myError.errorReason,
      );
    }
  }

  /// The result of this needs to be passed to several functions, so that we don't need
  /// to call several times if looping. Example: we can loop the addTarget method 100 times, but
  /// the attack variable we provide is the same and we only requested it once.
  dynamic getAttacks() async {
    return await TornApiCaller.attacks(_userKey).getAttacks;
  }

  void _getTargetFaction(TargetModel myNewTargetModel) {
    if (myNewTargetModel.faction.factionId != 0) {
      myNewTargetModel.hasFaction = true;
    } else {
      myNewTargetModel.hasFaction = false;
    }
  }

  void _getRespectFF(AttackModel attackModel, TargetModel myNewTargetModel) {
    double respect = -1;
    double fairFight = -1; // Unknown
    List<bool> userWonOrDefended = <bool>[];
    if (attackModel is AttackModel) {
      attackModel.attacks.forEach((key, value) {
        // We look for the our target in the the attacks list
        if (myNewTargetModel.playerId == value.defenderId ||
            myNewTargetModel.playerId == value.attackerId) {
          // Only update if we have still not found a positive value (because
          // we lost or we have no records)
          if (value.respectGain > 0) {
            fairFight = value.modifiers.fairFight;
            respect = fairFight * 0.25 * (log(myNewTargetModel.level) + 1);
          } else if (respect == -1) {
            respect = 0;
            fairFight = 1.00;
          }

          if (myNewTargetModel.playerId == value.defenderId) {
            if (value.result == Result.LOST || value.result == Result.STALEMATE) {
              // If we attacked and lost
              userWonOrDefended.add(false);
            } else {
              userWonOrDefended.add(true);
            }
          } else if (myNewTargetModel.playerId == value.attackerId) {
            if (value.result == Result.LOST || value.result == Result.STALEMATE) {
              // If we were attacked and the attacker lost
              userWonOrDefended.add(true);
            } else {
              userWonOrDefended.add(false);
            }
          }
        }
      });

      myNewTargetModel.respectGain = respect;
      myNewTargetModel.fairFight = fairFight;
      if (userWonOrDefended.isNotEmpty) {
        myNewTargetModel.userWonOrDefended = userWonOrDefended.first;
      } else {
        myNewTargetModel.userWonOrDefended = true; // Placeholder
      }
    }
  }

  void setTargetNote(TargetModel changedTarget, String note, String color) {
    // We are not updating the target directly, but instead looping for the correct one because
    // after an attack the targets get updated several times: if the user wants to change the note
    // right after the attack, the good target might have been replaced and the note does not get
    // updated. Therefore, we just loop whenever the user submits the new text.
    for (var tar in _targets) {
      if (tar.playerId == changedTarget.playerId) {
        tar.personalNote = note;
        tar.personalNoteColor = color;
        _saveTargetsSharedPrefs();
        notifyListeners();
        break;
      }
    }
  }

  Future<bool> updateTarget({
    @required TargetModel targetToUpdate,
    @required dynamic attacks,
  }) async {
    targetToUpdate.isUpdating = true;
    notifyListeners();

    try {
      dynamic myUpdatedTargetModel =
          await TornApiCaller.target(_userKey, targetToUpdate.playerId.toString()).getTarget;
      if (myUpdatedTargetModel is TargetModel) {
        _getRespectFF(attacks, myUpdatedTargetModel);
        _getTargetFaction(myUpdatedTargetModel);
        _targets[_targets.indexOf(targetToUpdate)] = myUpdatedTargetModel;
        var newTarget = _targets[_targets.indexOf(myUpdatedTargetModel)];
        _updateResultAnimation(newTarget, true);
        newTarget.personalNote = targetToUpdate.personalNote;
        newTarget.personalNoteColor = targetToUpdate.personalNoteColor;
        newTarget.lastUpdated = DateTime.now();
        _saveTargetsSharedPrefs();
        return true;
      } else {
        // myUpdatedTargetModel is ApiError
        targetToUpdate.isUpdating = false;
        _updateResultAnimation(targetToUpdate, false);
        return false;
      }
    } catch (e) {
      targetToUpdate.isUpdating = false;
      _updateResultAnimation(targetToUpdate, false);
      return false;
    }
  }

  Future<UpdateTargetsResult> updateAllTargets() async {
    bool wasSuccessful = true;
    int numberOfErrors = 0;
    int numberSuccessful = 0;
    // Activate every single update icon
    for (var tar in _targets) {
      tar.isUpdating = true;
    }
    notifyListeners();
    // Then start the real update
    dynamic attacks = await getAttacks();
    for (var i = 0; i < _targets.length; i++) {
      try {
        dynamic myUpdatedTargetModel =
            await TornApiCaller.target(_userKey, _targets[i].playerId.toString()).getTarget;
        if (myUpdatedTargetModel is TargetModel) {
          _getRespectFF(attacks, myUpdatedTargetModel);
          _getTargetFaction(myUpdatedTargetModel);
          var notes = _targets[i].personalNote;
          var notesColor = _targets[i].personalNoteColor;
          _targets[i] = myUpdatedTargetModel;
          _updateResultAnimation(_targets[i], true);
          _targets[i].personalNote = notes;
          _targets[i].personalNoteColor = notesColor;
          _targets[i].lastUpdated = DateTime.now();
          _saveTargetsSharedPrefs();
          numberSuccessful++;
        } else {
          // myUpdatedTargetModel is ApiError
          _updateResultAnimation(_targets[i], false);
          _targets[i].isUpdating = false;
          numberOfErrors++;
          wasSuccessful = false;
        }
        // Wait for the API limit (100 calls/minute)
        if (_targets.length > 75) {
          await Future.delayed(const Duration(seconds: 1), () {});
        }
      } catch (e) {
        _updateResultAnimation(_targets[i], false);
        _targets[i].isUpdating = false;
        numberOfErrors++;
        wasSuccessful = false;
      }
    }
    return UpdateTargetsResult(
      success: wasSuccessful,
      numberErrors: numberOfErrors,
      numberSuccessful: numberSuccessful,
    );
  }

  Future<void> updateTargetsAfterAttacks({@required List<String> targetsIds}) async {
    // Get attacks full to use later
    dynamic attacks = await getAttacks();

    // Local function for the update of several targets after attacking
    void updatePass(bool showUpdateAnimation) async {
      for (var tar in _targets) {
        for (var i = 0; i < targetsIds.length; i++) {
          if (tar.playerId.toString() == targetsIds[i]) {
            if (showUpdateAnimation) {
              tar.isUpdating = true;
              notifyListeners();
            }
            try {
              dynamic myUpdatedTargetModel =
                  await TornApiCaller.target(_userKey, tar.playerId.toString()).getTarget;
              if (myUpdatedTargetModel is TargetModel) {
                _getRespectFF(attacks, myUpdatedTargetModel);
                _getTargetFaction(myUpdatedTargetModel);
                _targets[_targets.indexOf(tar)] = myUpdatedTargetModel;
                var newTarget = _targets[_targets.indexOf(myUpdatedTargetModel)];
                if (showUpdateAnimation) {
                  _updateResultAnimation(newTarget, true);
                }
                newTarget.personalNote = tar.personalNote;
                newTarget.personalNoteColor = tar.personalNoteColor;
                newTarget.lastUpdated = DateTime.now();
                _saveTargetsSharedPrefs();
              } else {
                if (showUpdateAnimation) {
                  tar.isUpdating = false;
                  _updateResultAnimation(tar, false);
                }
              }
            } catch (e) {
              if (showUpdateAnimation) {
                tar.isUpdating = false;
                _updateResultAnimation(tar, false);
              }
            }
            if (targetsIds.length > 40) {
              await Future.delayed(const Duration(seconds: 1), () {});
            }
          }
        }
      }
    }

    await Future.delayed(Duration(seconds: 15));
    updatePass(true);
  }

  Future<void> _updateResultAnimation(TargetModel target, bool success) async {
    if (success) {
      target.justUpdatedWithSuccess = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 5), () {});
      target.justUpdatedWithSuccess = false;
      notifyListeners();
    } else {
      target.justUpdatedWithError = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 15), () {});
      target.justUpdatedWithError = false;
      notifyListeners();
    }
  }

  void deleteTarget(TargetModel target) {
    _oldTargetsList = List<TargetModel>.from(_targets);
    _targets.remove(target);
    notifyListeners();
    _saveTargetsSharedPrefs();
  }

  void deleteTargetById(String removedId) {
    _oldTargetsList = List<TargetModel>.from(_targets);
    for (var tar in _targets) {
      if (tar.playerId.toString() == removedId) {
        _targets.remove(tar);
        break;
      }
    }
    notifyListeners();
    _saveTargetsSharedPrefs();
  }

  void restoredDeleted() {
    _targets = List<TargetModel>.from(_oldTargetsList);
    _oldTargetsList.clear();
    notifyListeners();
  }

  /// CAREFUL!
  void wipeAllTargets() {
    _targets.clear();
    _saveTargetsSharedPrefs();
    notifyListeners();
  }

  void setFilterText(String newFilter) {
    _currentWordFilter = newFilter;
    notifyListeners();
  }

  void setFilterColorsOut(List<String> newFilter) {
    _currentColorFilterOut = newFilter;
    Prefs().setTargetsColorFilter(_currentColorFilterOut);
    notifyListeners();
  }

  void sortTargets(TargetSortType sortType) {
    _currentSort = sortType;
    switch (sortType) {
      case TargetSortType.levelDes:
        _targets.sort((a, b) => b.level.compareTo(a.level));
        break;
      case TargetSortType.levelAsc:
        _targets.sort((a, b) => a.level.compareTo(b.level));
        break;
      case TargetSortType.respectDes:
        _targets.sort((a, b) => b.respectGain.compareTo(a.respectGain));
        break;
      case TargetSortType.respectAsc:
        _targets.sort((a, b) => a.respectGain.compareTo(b.respectGain));
        break;
      case TargetSortType.nameDes:
        _targets.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case TargetSortType.nameAsc:
        _targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case TargetSortType.colorDes:
        _targets.sort((a, b) =>
            b.personalNoteColor.toLowerCase().compareTo(a.personalNoteColor.toLowerCase()));
        break;
      case TargetSortType.colorAsc:
        _targets.sort((a, b) =>
            a.personalNoteColor.toLowerCase().compareTo(b.personalNoteColor.toLowerCase()));
        break;
    }
    _saveSortSharedPrefs();
    _saveTargetsSharedPrefs();
    notifyListeners();
  }

  int getTargetNumber() {
    return _targets.length;
  }

  String exportTargets() {
    var output = <TargetBackup>[];
    for (var tar in _targets) {
      var export = TargetBackup();
      export.id = tar.playerId;
      export.notes = tar.personalNote;
      export.notesColor = tar.personalNoteColor;
      output.add(export);
    }
    return targetsBackupModelToJson(TargetsBackupModel(targetBackup: output));
  }

  void _saveTargetsSharedPrefs() {
    List<String> newPrefs = <String>[];
    for (var tar in _targets) {
      newPrefs.add(targetModelToJson(tar));
    }
    Prefs().setTargetsList(newPrefs);
  }

  void _saveSortSharedPrefs() {
    String sortToSave;
    switch (_currentSort) {
      case TargetSortType.levelDes:
        sortToSave = 'levelDes';
        break;
      case TargetSortType.levelAsc:
        sortToSave = 'levelAsc';
        break;
      case TargetSortType.respectDes:
        sortToSave = 'respectDes';
        break;
      case TargetSortType.respectAsc:
        sortToSave = 'respectDes';
        break;
      case TargetSortType.nameDes:
        sortToSave = 'nameDes';
        break;
      case TargetSortType.nameAsc:
        sortToSave = 'nameDes';
        break;
      case TargetSortType.colorDes:
        sortToSave = 'colorDes';
        break;
      case TargetSortType.colorAsc:
        sortToSave = 'colorAsc';
        break;
    }
    Prefs().setTargetsSort(sortToSave);
  }

  Future<void> restorePreferences() async {
    // User key
    if (_userDetails.userApiKeyValid) {
      _userKey = _userDetails.userApiKey;
    }

    // Target list
    bool needToSave = false;
    List<String> jsonTargets = await Prefs().getTargetsList();
    for (var jTar in jsonTargets) {
      var thisTarget = targetModelFromJson(jTar);

      // In v1.8.5 we change from blue to orange and we need to do the conversion
      // here. This can be later removed safely at some point.
      if (thisTarget.personalNoteColor == "blue") {
        thisTarget.personalNoteColor = "orange";
        needToSave = true;
      }

      // In v2.3.0 we adapt colors to be as per YATA, with black/white sorting at the end.
      // This can be later removed safely at some point.
      if (thisTarget.personalNoteColor == "") {
        thisTarget.personalNoteColor = "z";
        needToSave = true;
      }

      _targets.add(thisTarget);
    }

    if (needToSave) {
      _saveTargetsSharedPrefs();
    }

    // Target sort
    String targetSort = await Prefs().getTargetsSort();
    switch (targetSort) {
      case '':
        _currentSort = TargetSortType.levelDes;
        break;
      case 'levelDes':
        _currentSort = TargetSortType.levelDes;
        break;
      case 'levelAsc':
        _currentSort = TargetSortType.levelAsc;
        break;
      case 'respectDes':
        _currentSort = TargetSortType.respectDes;
        break;
      case 'respectAsc':
        _currentSort = TargetSortType.respectAsc;
        break;
      case 'nameDes':
        _currentSort = TargetSortType.nameDes;
        break;
      case 'nameAsc':
        _currentSort = TargetSortType.nameAsc;
        break;
    }

    // Targets color filter
    _currentColorFilterOut = await Prefs().getTargetsColorFilter();

    // Notification
    notifyListeners();
  }

  // YATA SYNC
  Future<YataTargetsImportModel> getTargetsFromYata() async {
    try {
      var response = await http.get(
        Uri.parse('https://yata.yt/api/v1/targets/export/?key=$_userKey'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        return yataTargetsImportModelFromJson(response.body);
      } else {
        if (response.body.contains("Player not found")) {
          return YataTargetsImportModel()..errorPlayer = true;
        } else {
          return YataTargetsImportModel()..errorConnection = true;
        }
      }
    } catch (e) {
      return YataTargetsImportModel()..errorConnection = true;
    }
  }

  Future<String> postTargetsToYata({
    @required List<TargetsOnlyLocal> onlyLocal,
    @required List<TargetsBothSides> bothSides,
  }) async {
    var modelOut = YataTargetsExportModel();
    modelOut.key = _userKey;
    //modelOut.user = "Torn PDA $appVersion";

    var targets = Map<String, YataExportTarget>();
    for (var localTarget in onlyLocal) {
      // Max chars in Yata notes is 128
      if (localTarget.noteLocal.length > 128) {
        localTarget.noteLocal = localTarget.noteLocal.substring(0, 127);
      }
      var exportDetails = YataExportTarget()
        ..note = localTarget.noteLocal
        ..color = localTarget.colorLocal;
      targets.addAll({localTarget.id: exportDetails});
    }
    for (var bothSidesTarget in bothSides) {
      // Max chars in Yata notes is 128
      if (bothSidesTarget.noteLocal.length > 128) {
        bothSidesTarget.noteLocal = bothSidesTarget.noteLocal.substring(0, 127);
      }
      var exportDetails = YataExportTarget()
        ..note = bothSidesTarget.noteLocal
        ..color = bothSidesTarget.colorLocal;
      targets.addAll({bothSidesTarget.id: exportDetails});
    }
    modelOut.targets = targets;

    var bodyOut = yataTargetsExportModelToJson(modelOut);

    try {
      var response = await http.post(
        Uri.parse('https://yata.yt/api/v1/targets/import/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyOut,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        var answer = result.values.first;
        if (answer.contains("No new targets added") || answer.contains("You added")) {
          answer += ". Any existing notes and colors have been exported and overwritten in YATA";
        }

        return answer;
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }
}
