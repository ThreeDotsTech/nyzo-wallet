// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_slidable/flutter_slidable.dart';

// Project imports:
import 'package:nyzo_wallet/Activities/MyTokensListWindow.dart';
import 'package:nyzo_wallet/Activities/WalletWindow.dart';
import 'package:nyzo_wallet/Data/AppLocalizations.dart';
import 'package:nyzo_wallet/Data/Contact.dart';
import 'package:nyzo_wallet/Data/Token.dart';
import 'package:nyzo_wallet/Data/TokensTransactionsResponse.dart';
import 'package:nyzo_wallet/Data/Transaction.dart';
import 'package:nyzo_wallet/Data/TransactionsSinceResponse.dart';
import 'package:nyzo_wallet/Data/Wallet.dart';
import 'package:nyzo_wallet/Widgets/ColorTheme.dart';
import 'package:nyzo_wallet/Widgets/SheetUtil.dart';
import 'package:nyzo_wallet/Widgets/TransactionsAllWidget.dart';

class TransactionsWidget extends StatefulWidget {
  final List<Transaction>? _transactions;
  const TransactionsWidget(this._transactions);
  @override
  TranSactionsWidgetState createState() =>
      TranSactionsWidgetState(_transactions!);
}

class TranSactionsWidgetState extends State<TransactionsWidget> {
  List<Transaction> _transactions;
  List<TokensTransactionsResponse> tokensTransactionsList =
      List<TokensTransactionsResponse>.empty(growable: true);
  TransactionsSinceResponse? transactionsSinceResponse;
  TranSactionsWidgetState(this._transactions);
  String _address = '';
  List<Contact>? _contactsList;
  WalletWindowState? walletWindowState;
  final SlidableController slidableController = SlidableController();

  @override
  void initState() {
    walletWindowState = context.findAncestorStateOfType<WalletWindowState>()!;
    getAddress().then((address) {
      _address = address;
      getTransactions(_address).then((List<Transaction> transactions) {
        setState(() {
          _transactions = transactions;
        });
      });
      getTokensTransactionsList(address)
          .then((List<TokensTransactionsResponse> _tokensTransactionsList) {
        setState(() {
          tokensTransactionsList = _tokensTransactionsList;
        });
      });
      getTransactionsSinceList(address).then((_transactionsSinceResponse) {
        transactionsSinceResponse = _transactionsSinceResponse;
      });
    });
    getContacts().then((List<Contact> contacts) {
      _contactsList = contacts;
    });
    super.initState();
  }

  Future<void> refresh() async {
    final WalletWindowState? walletWindowState =
        context.findAncestorStateOfType<WalletWindowState>();
    final Future transactions = getTransactions(_address);
    getBalance(_address).then((double _balance) {
      walletWindowState!.setState(() {
        walletWindowState.balance = _balance.floor();
        setSavedBalance(_balance);
      });
    });
    getTokensBalance(_address).then((List<Token> _myTokensList) {
      walletWindowState!.setState(() {
        walletWindowState.myTokensList = _myTokensList;
      });
    });
    transactions.then((transactionsList) {
      setState(() {
        _transactions = transactionsList;
      });
      //getBalance(_address).then((int balance){});
    });
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(),
          ),
          Center(
            child: Text(
              AppLocalizations.of(context)!.translate('String72'),
              style: TextStyle(
                  color: ColorTheme.of(context)!.secondaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  fontSize: 35),
            ),
          ),
          Expanded(
            child: Container(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppLocalizations.of(context)!.translate('String50'),
                      style: const TextStyle(
                          color: const Color(0xFF555555), fontSize: 15),
                    ),
                    RichText(
                      text: TextSpan(
                        text: walletWindowState!.balance == 0
                            ? walletWindowState!.balance.toString()
                            : (walletWindowState!.balance / 1000000).toString(),
                        style: TextStyle(
                            color: ColorTheme.of(context)!.secondaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 40),
                        children: <TextSpan>[
                          TextSpan(
                            text: ' ∩',
                            style: TextStyle(
                                color: ColorTheme.of(context)!.secondaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 20),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                walletWindowState!.myTokensList.length > 0
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [BoxShadow(color: Colors.transparent)],
                            ),
                            height: 35,
                            margin: EdgeInsetsDirectional.only(
                                start: 7, top: 0.0, end: 7.0),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    ColorTheme.of(context)!.secondaryColor,
                                elevation: 0.0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0)),
                              ),
                              child: Icon(Icons.scatter_plot_rounded,
                                  color: ColorTheme.of(context)!.baseColor,
                                  size: 20),
                              onPressed: () {
                                Sheets.showAppHeightEightSheet(
                                    color: ColorTheme.of(context)!.depthColor,
                                    context: context,
                                    widget: MyTokensListWindow(
                                        walletWindowState!.myTokensList));
                              },
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!
                                .translate('String102'),
                            style: TextStyle(
                                color: const Color(0xFF555555),
                                letterSpacing: 0,
                                fontSize: 15),
                          ),
                        ],
                      )
                    : const SizedBox(),
              ],
            ),
          ),
          const Divider(
            color: const Color(0xFF555555),
          ),
          transactionsSinceResponse == null
              ? const SizedBox()
              : TransactionsAllWidget.buildTransactionsDisplay(
                  context,
                  _address,
                  walletWindowState!,
                  transactionsSinceResponse!.txs,
                  _contactsList,
                  refresh),
        ],
      ),
    );
  }

  String splitJoinString(String address) {
    final String val = address.split('-').join('');
    return val;
  }
}
