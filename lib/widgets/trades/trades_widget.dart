// Flutter imports:
import 'dart:convert';

import 'package:animations/animations.dart';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/trades/awh_out.dart';
// Project imports:
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_full_awh.dart';

class TradesWidget extends StatefulWidget {
  final ThemeProvider? themeProv;
  final UserDetailsProvider? userProv;
  final InAppWebViewController? webView;

  const TradesWidget({
    required this.themeProv,
    required this.userProv,
    required this.webView,
  });

  @override
  TradesWidgetState createState() => TradesWidgetState();
}

class TradesWidgetState extends State<TradesWidget> {
  static const ttColor = Color(0xffd186cf);

  final _scrollController = ScrollController();
  final _moneyFormat = NumberFormat("#,##0", "en_US");
  final _moneyDecimalFormat = NumberFormat("#,##0.##", "en_US");

  late TradesProvider _tradesProv;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tradesProv = Provider.of<TradesProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ExpandablePanel(
        collapsed: Container(),
        theme: const ExpandableThemeData(
          hasIcon: false,
          iconColor: Colors.grey,
          tapBodyToExpand: true,
          tapBodyToCollapse: true,
        ),
        header: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (!_tradesProv.container.awhActive)
                  const SizedBox(width: 90)
                else
                  SizedBox(width: 90, child: _awhContainer()),
                const Column(
                  children: [
                    Text(
                      'Trade Calculator',
                      style: TextStyle(
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      '(TAP TO EXPAND)',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                if (!_tradesProv.container.ttActive)
                  const SizedBox(width: 90)
                else
                  SizedBox(
                    width: 90,
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10, right: 5),
                          child: Image(
                            image: AssetImage('images/icons/torntrader_logo.png'),
                            width: 16,
                            color: ttColor,
                            fit: BoxFit.fill,
                          ),
                        ),
                        if (_tradesProv.container.ttServerError || _tradesProv.container.ttAuthError)
                          Row(
                            children: [
                              const Text(
                                'ERROR',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: IconButton(
                                  padding: const EdgeInsets.all(0),
                                  iconSize: 20,
                                  onPressed: () {
                                    String errorString = "";
                                    if (_tradesProv.container.ttServerError) {
                                      errorString = "There was an error contacting Torn Trader, "
                                          "please try again later!";
                                    } else if (_tradesProv.container.ttAuthError) {
                                      errorString = "There was an error authenticating in Torn "
                                          "Trades, is your account active?";
                                    }
                                    BotToast.showText(
                                      text: errorString,
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.orange[800]!,
                                      duration: const Duration(seconds: 5),
                                      contentPadding: const EdgeInsets.all(10),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.info_outline,
                                    size: 15,
                                    color: Colors.orange,
                                  ),
                                ),
                              )
                            ],
                          )
                        else
                          const Text(
                            'SYNC',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xffd186cf),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(child: _headerTotals('left')),
                  Flexible(child: _headerTotals('right')),
                ],
              ),
            ),
          ],
        ),
        expanded: Column(
          children: [
            Center(
              child: Divider(
                color: Colors.grey,
                indent: MediaQuery.sizeOf(context).width / 4,
                endIndent: MediaQuery.sizeOf(context).width / 4,
              ),
            ),
            ConstrainedBox(
              // Take into account Torn Trader to leave more or less space
              constraints: _tradesProv.container.ttActive &&
                      (!_tradesProv.container.ttServerError || _tradesProv.container.ttAuthError)
                  ? BoxConstraints.loose(
                      Size.fromHeight(
                            MediaQuery.sizeOf(context).height - kToolbarHeight * 3 - AppBar().preferredSize.height,
                          ) /
                          3,
                    )
                  : BoxConstraints.loose(
                      Size.fromHeight(
                            MediaQuery.sizeOf(context).height - kToolbarHeight - AppBar().preferredSize.height,
                          ) /
                          3,
                    ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sideDetailed('left'),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: sideDetailed('right'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerTotals(String side) {
    int total = 0;
    bool hasProperty = false;
    if (side == 'left') {
      total += _tradesProv.container.leftMoney;
      for (final item in _tradesProv.container.leftItems) {
        total += item.totalPrice;
      }
      for (final share in _tradesProv.container.leftShares) {
        total += share.totalPrice;
      }
      for (final property in _tradesProv.container.leftProperties) {
        if (property.name != 'No properties in trade') {
          hasProperty = true;
          break;
        }
      }
    } else {
      total += _tradesProv.container.rightMoney;
      for (final item in _tradesProv.container.rightItems) {
        total += item.totalPrice;
      }
      for (final share in _tradesProv.container.rightShares) {
        total += share.totalPrice;
      }
      for (final property in _tradesProv.container.rightProperties) {
        if (property.name != 'No properties in trade') {
          hasProperty = true;
          break;
        }
      }
    }

    Widget propertyIcon() {
      if (!hasProperty) {
        return const SizedBox.shrink();
      } else {
        return const Row(
          children: [
            SizedBox(width: 5),
            Text('(+', style: TextStyle(color: Colors.white)),
            Icon(
              MdiIcons.home,
              color: Colors.white,
              size: 14,
            ),
            Text(')', style: TextStyle(color: Colors.white)),
          ],
        );
      }
    }

    final Widget clipboardIcon = SizedBox(
      height: 23,
      width: 23,
      child: IconButton(
        padding: const EdgeInsets.all(0),
        iconSize: 23,
        onPressed: () {
          String amountCopied;
          // Also takes into account ttServerError, in which case we copy the standard value below
          if (_tradesProv.container.ttActive && !_tradesProv.container.ttServerError && side == 'right') {
            amountCopied = _tradesProv.container.ttTotalMoney.replaceAll("\$", "").replaceAll(",", "");
            _copyToClipboard(amountCopied, _tradesProv.container.ttTotalMoney);
          } else {
            amountCopied = _moneyFormat.format(total);
            _copyToClipboard(amountCopied, amountCopied);
          }
        },
        icon: const Icon(
          Icons.content_copy,
          size: 23,
          color: Colors.grey,
        ),
      ),
    );

    // This prevents showing totals as 0 when the widget is first loaded with existing items
    if (_tradesProv.container.firstLoad) {
      return const SizedBox.shrink();
    }

    if (!_tradesProv.container.ttActive ||
        (_tradesProv.container.ttActive &&
            (_tradesProv.container.ttServerError || _tradesProv.container.ttAuthError))) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (side == 'left')
            Padding(padding: const EdgeInsets.only(right: 5), child: clipboardIcon)
          else
            const SizedBox.shrink(),
          Flexible(
            child: Text(
              '\$${_moneyFormat.format(total)}',
              textAlign: side == 'left' ? TextAlign.start : TextAlign.end,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          propertyIcon(),
          if (side == 'right')
            Padding(padding: const EdgeInsets.only(left: 5), child: clipboardIcon)
          else
            const SizedBox.shrink(),
        ],
      );
    } else {
      if (side == 'left') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.only(right: 5), child: clipboardIcon),
            Flexible(
              child: Text(
                '\$${_moneyFormat.format(total)}',
                textAlign: side == 'left' ? TextAlign.start : TextAlign.end,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            propertyIcon(),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _tradesProv.container.ttTotalMoney,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: ttColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '\$${_moneyFormat.format(total)} market',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${_tradesProv.container.ttProfit} profit',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(padding: const EdgeInsets.only(right: 10), child: clipboardIcon),
                SizedBox(
                  height: 23,
                  width: 23,
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    iconSize: 23,
                    onPressed: () {
                      _copyToClipboard(_tradesProv.container.ttUrl!, "Receipt URL");
                    },
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      size: 23,
                      color: ttColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 23,
                  width: 23,
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    iconSize: 23,
                    onPressed: () {
                      _copyTornTraderMessages();
                    },
                    icon: const Icon(
                      Icons.message_outlined,
                      size: 23,
                      color: ttColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    }
  }

  List<Widget> sideDetailed(String side) {
    final items = <Widget>[];
    int sideMoney = 0;
    var sideItems = <TradeItem>[];
    var sideProperties = <TradeItem>[];
    var sideShares = <TradeItem>[];
    bool noItemsFound = true;

    if (side == 'left') {
      sideMoney = _tradesProv.container.leftMoney;
      sideItems = _tradesProv.container.leftItems;
      sideProperties = _tradesProv.container.leftProperties;
      sideShares = _tradesProv.container.leftShares;
    } else {
      sideMoney = _tradesProv.container.rightMoney;
      sideItems = _tradesProv.container.rightItems;
      sideProperties = _tradesProv.container.rightProperties;
      sideShares = _tradesProv.container.rightShares;
    }

    // Torn Trades appears before rest of items
    if (_tradesProv.container.ttActive &&
        side == 'right' &&
        (!_tradesProv.container.ttServerError || _tradesProv.container.ttAuthError)) {
      final ttItems = _tradesProv.container.ttItems!;

      for (final ttProduct in ttItems) {
        if (ttProduct.price == null) {
          continue;
        }

        String itemName = ttProduct.name!;
        if (ttProduct.quantity! > 1) {
          itemName += ' x${ttProduct.quantity}';
        }

        items.add(
          Text(
            itemName,
            style: const TextStyle(
              color: ttColor,
              fontSize: 13,
            ),
          ),
        );

        // Item price
        final String itemPriceTotal = ttProduct.total!.replaceAll(" ", "");
        String itemPriceIndividual = "";
        if (ttProduct.quantity! > 1) {
          itemPriceIndividual += '(@ ${ttProduct.price!.replaceAll(" ", "")})';
        }
        String itemProfit;
        if (ttProduct.profit! >= 0) {
          itemProfit = '\$${_moneyFormat.format(ttProduct.profit)}';
        } else {
          itemProfit = '\$-${_moneyFormat.format(ttProduct.profit)}';
        }

        items.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      itemPriceTotal,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      itemPriceIndividual,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '$itemProfit profit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );

        items.add(const SizedBox(height: 10));

        // We need to remove this product from the ones we have in the normal list,
        // so that only non-TornTrader products remain there
        final newSideItemList = List<TradeItem>.from(sideItems);
        for (final standardItem in sideItems) {
          if (standardItem.name == ttProduct.name) {
            newSideItemList.remove(standardItem);
          }
        }
        sideItems = List<TradeItem>.from(newSideItemList);

        // If we only find TornTrader items, the standard item list will be empty
        // and a warning will show. We need to prevent it with this setting
        noItemsFound = false;
      }

      // If after comparing there are still items in sideItems, there are items not captured
      // by Torn Trades, so we'll give a warning
      if (sideItems.isNotEmpty) {
        items.add(
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: SizedBox(
              width: 80,
              child: Divider(color: Colors.orange),
            ),
          ),
        );
        items.add(
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  'NOT IN TORN TRADER',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                  ),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.warning_amber_outlined, size: 16, color: Colors.orange),
            ],
          ),
        );

        // Recalculate remaining total
        int remainingTotal = 0;
        remainingTotal += _tradesProv.container.rightMoney;
        for (final rem in sideItems) {
          remainingTotal += rem.totalPrice;
        }
        for (final sha in sideShares) {
          remainingTotal += sha.totalPrice;
        }
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '(additional \$${_moneyFormat.format(remainingTotal)} market value)',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 10,
              ),
            ),
          ),
        );
      }
    }

    // CASH
    if (sideMoney > 0) {
      noItemsFound = false;
      items.add(
        Text(
          '\$${_moneyFormat.format(sideMoney)} in cash',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 13,
          ),
        ),
      );
      items.add(const SizedBox(height: 10));
    }

    // Item name
    for (final item in sideItems) {
      String? itemName = item.name;
      if (itemName == 'No items in trade') {
        continue;
      } else {
        noItemsFound = false;
      }

      if (item.quantity > 1) {
        itemName += ' x${item.quantity}';
      }

      items.add(
        Text(
          itemName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      );

      // Item price
      String itemPrice = '\$${_moneyFormat.format(item.totalPrice)}';
      if (item.quantity > 1) {
        itemPrice += ' (@ \$${_moneyFormat.format(item.priceUnit)})';
      }

      items.add(
        Text(
          itemPrice,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(const SizedBox(height: 10));
    }

    // PROPERTIES
    for (final property in sideProperties) {
      String? propertyName = property.name;
      if (propertyName == 'No properties in trade') {
        continue;
      } else {
        noItemsFound = false;
      }

      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(MdiIcons.home, size: 18, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              propertyName,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

      items.add(
        Text(
          property.happiness,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(const SizedBox(height: 10));
    }

    // SHARES
    for (final share in sideShares) {
      String? shareName = share.name;
      if (shareName == 'No shares in trade') {
        continue;
      } else {
        noItemsFound = false;
      }

      if (share.quantity > 1) {
        shareName += ' x${share.quantity}';
      } else if (share.quantity == 1) {
        shareName += ' x1';
      }

      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(MdiIcons.chartTimelineVariant, size: 18, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              shareName,
              style: const TextStyle(
                color: Colors.pink,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

      // Share price
      String sharePrice = '\$${_moneyFormat.format(share.totalPrice)}';
      if (share.quantity > 1) {
        sharePrice += ' (@ \$${_moneyDecimalFormat.format(share.shareUnit)})';
      }

      items.add(
        Text(
          sharePrice,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(const SizedBox(height: 10));
    }

    if (noItemsFound) {
      items.add(
        const Text(
          'No items found',
          style: TextStyle(color: Colors.orange, fontSize: 13),
        ),
      );
    }

    return items;
  }

  Future _copyToClipboard(String copy, String toast) async {
    if (copy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: copy));
      BotToast.showText(
        text: "$toast copied to the clipboard!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.green,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    } else {
      BotToast.showText(
        text: "${toast}There was an error, no information copied!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red[800]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  void _copyTornTraderMessages() {
    if (_tradesProv.container.ttMessages!.isEmpty) {
      BotToast.showText(
        text: "You have no predefined messages!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.orange[800]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    } else if (_tradesProv.container.ttMessages!.length == 1) {
      final String thisMessage = _tradesProv.container.ttMessages![0].message!;
      _copyToClipboard(thisMessage, 'Message "$thisMessage"');
    } else {
      final options = <Widget>[];
      for (final msg in _tradesProv.container.ttMessages!) {
        options.add(
          SimpleDialogOption(
            onPressed: () {
              _copyToClipboard(msg.message!, 'Message "${msg.message}"');
              Navigator.of(context).pop();
            },
            child: Text(
              msg.message!,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        );
      }
      options.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ElevatedButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      );
      showDialog(
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text(
              'Choose message to copy',
              style: TextStyle(
                color: ttColor,
                fontSize: 15,
              ),
            ),
            children: options,
          );
        },
      );
    }
  }

  Widget _awhContainer() {
    var dark = "";
    if (widget.themeProv!.currentTheme == AppTheme.dark) {
      dark = "dark&";
    }

    final awhBaseUrl = "https://arsonwarehouse.com/pda?$dark&trade=";
    final awhContainer = ArsonWarehouseOut();

    final theirItems = <AwhItem>[];
    for (final item in _tradesProv.container.rightItems) {
      if (!item.name.contains("No items in trade")) {
        final awhItem = AwhItem()
          ..name = item.name
          ..quantity = item.quantity;
        theirItems.add(awhItem);
      }
    }

    final myItems = <AwhItem>[];
    for (final item in _tradesProv.container.leftItems) {
      if (!item.name.contains("No items in trade")) {
        final awhItem = AwhItem()
          ..name = item.name
          ..quantity = item.quantity;
        myItems.add(awhItem);
      }
    }

    awhContainer
      ..me = widget.userProv!.basic!.playerId
      ..them = _tradesProv.container.sellerName
      ..tradeId = _tradesProv.container.tradeId
      ..version = 1
      ..theirItems = theirItems
      ..myItems = myItems;

    final awhJson = arsonWarehouseOutToJson(awhContainer);
    final bytes = utf8.encode(awhJson);
    final jsonEncoded = base64.encode(bytes);
    final ticketURL = awhBaseUrl + jsonEncoded;

    return OpenContainer(
      transitionDuration: const Duration(seconds: 1),
      transitionType: ContainerTransitionType.fadeThrough,
      openBuilder: (BuildContext context, VoidCallback _) {
        return WebViewFullAwh(
          customUrl: ticketURL,
          customTitle: "Arson Warehouse",
          awhMessageCallback: _backFromAwhWithMessage,
          sellerName: _tradesProv.container.sellerName,
          sellerId: _tradesProv.container.sellerId,
        );
      },
      closedElevation: 0,
      closedColor: Colors.transparent,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return SizedBox(
          height: 30,
          width: 40,
          child: Center(
            child: Image.asset(
              'images/icons/awh_logo.png',
              width: 35,
              color: Colors.orange,
            ),
          ),
        );
      },
    );
  }

  Future<void> _backFromAwhWithMessage() async {
    await widget.webView!.evaluateJavascript(source: "chat.r(${_tradesProv.container.sellerId})");
  }
}
