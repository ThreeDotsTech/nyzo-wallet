// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:intl/intl.dart';
import 'package:titled_navigation_bar/titled_navigation_bar.dart';

// Project imports:
import 'package:nyzo_wallet/Activities/ContactsWindow.dart';
import 'package:nyzo_wallet/Activities/SendWindow.dart';
import 'package:nyzo_wallet/Activities/SettingsWindow.dart';
import 'package:nyzo_wallet/Activities/verifiersWindow.dart';
import 'package:nyzo_wallet/Data/AppLocalizations.dart';
import 'package:nyzo_wallet/Data/Contact.dart';
import 'package:nyzo_wallet/Data/Transaction.dart';
import 'package:nyzo_wallet/Data/Wallet.dart';
import 'package:nyzo_wallet/Widgets/ColorTheme.dart';
import 'package:nyzo_wallet/Widgets/TransactionsWidget.dart';
import 'package:nyzo_wallet/Widgets/Unicorndial.dart';
import 'package:nyzo_wallet/Widgets/verifierDialog.dart';

class WalletWindow extends StatefulWidget {
  final _password;
  const WalletWindow(this._password);
  @override
  WalletWindowState createState() => WalletWindowState(_password);
}

class WalletWindowState extends State<WalletWindow> {
  WalletWindowState(this.password);
  ContactsWindow contactsWindow = ContactsWindow(contactsList!);
  TranSactionsWidget tranSactionsWidgetInstance =
      TranSactionsWidget(List<Transaction>.empty(growable: true));
  VerifiersWindow? verifiersWindow;
  SendWindow? sendWindowInstance;
  SettingsWindow? settingsWindow = SettingsWindow();
  String password;
  double? screenHeight;
  int balance = 0;
  String _address = '';
  static List<Transaction>? transactions;
  static List<Contact>? contactsList = List<Contact>.empty(growable: true);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var f = NumberFormat('###.0#', 'en_US');
  bool _compactFormat = true;
  int pageIndex = 0;

  bool sentinels = false;

  final textControllerAmount = TextEditingController();
  final textControllerAddress = TextEditingController();
  final textControllerData = TextEditingController();
  final amountFormKey = GlobalKey<FormFieldState>();
  final addressFormKey = GlobalKey<FormFieldState>();
  final dataFormKey = GlobalKey<FormFieldState>();

  AddVerifierDialog floatingdialog = AddVerifierDialog();

  changeTheme(fn) {
    super.setState(fn);
  }

  @override
  void initState() {
    //The first thing we do is load the last balance saved on disk.
    getSavedBalance().then((double _balance) {
      setState(() {
        balance = _balance.floor();
      });
    });
    //We initialize the verifiers Window
    verifiersWindow = VerifiersWindow();
    //This is the saved preference to know if we mus display the verifiers window or not.
    watchSentinels().then((bool? val) {
      setState(() {
        sentinels = val!;
      });
    });

    getAddress().then((address) {
      //load the wallet's address from disk
      setState(() {
        _address = address;
        //Now that we have the address, we instantialize  the send window.
        sendWindowInstance =
            SendWindow(password, nyzoStringFromPublicIdentifier(_address));

        getBalance(_address).then((_balance) {
          //get the balance value from the network
          setState(() {
            balance = _balance.floor();
            setSavedBalance(double.parse(balance.toString())); //set the balance
          });
          getTransactions(_address).then((List? _transactions) {
            transactions = _transactions!.cast<Transaction>();
          });
        }); //set the address
      });
      getContacts().then((contactList) {
        contactsList = contactList;
      });
    });

    super.initState();

    //SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
    //prevent the screen from rotating
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  changeFormat() {
    setState(() {
      _compactFormat = !_compactFormat;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;

    final childButtons = List<UnicornButton>.empty(growable: true);

    childButtons.add(UnicornButton(
        hasLabel: false,
        //labelText: 	AppLocalizations.of(context)!.translate("String96"),
        labelText: '',
        currentButton: FloatingActionButton(
          heroTag: 'verifier',
          backgroundColor: Colors.white,
          mini: true,
          child: Container(
              margin: const EdgeInsets.all(8),
              child: Image.asset(
                'images/normal.png',
                color: Colors.black,
              )),
          onPressed: () {
            floatingdialog.information(
                context,
                AppLocalizations.of(context)!.translate('String97'),
                true, onClose: () {
              ColorTheme.of(context)!.updateVerifiers!();
            });
          },
        )));

    childButtons.add(UnicornButton(
        hasLabel: false,
        //labelText: 	AppLocalizations.of(context)!.translate("String98"),

        currentButton: FloatingActionButton(
          heroTag: 'address',
          backgroundColor: Colors.white,
          mini: true,
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              floatingdialog.information(
                  context,
                  AppLocalizations.of(context)!.translate('String97'),
                  false, onClose: () {
                ColorTheme.of(context)!.updateAddressesToWatch!();
              });
            });
          },
        )));
    return WillPopScope(
      // widget to control the moving between activities
      onWillPop: () async =>
          false, //don't let the user go back to the previous activity
      child: Scaffold(
        floatingActionButton: sentinels
            ? pageIndex == 3
                ? UnicornDialer(
                    parentHeroTag: 'ParenTagg',
                    childButtons: childButtons,
                    parentButtonBackground: Colors.white,
                    backgroundColor: Colors.black12,
                    finalButtonIcon: const Icon(
                      Icons.close,
                      color: Colors.black,
                    ),
                    parentButton: const Icon(
                      Icons.add,
                      color: Colors.black,
                    ),
                  )
                : null
            : null,
        //resizeToAvoidBottomInset: false,
        // resizeToAvoidBottomPadding: false,
        key: _scaffoldKey,
        backgroundColor: ColorTheme.of(context)!.baseColor!,
        bottomNavigationBar: TitledBottomNavigationBar(
            indicatorColor: ColorTheme.of(context)!.secondaryColor,
            inactiveColor: ColorTheme.of(context)!.secondaryColor,
            activeColor: ColorTheme.of(context)!.secondaryColor,
            reverse: true,
            currentIndex:
                pageIndex, // Use this to update the Bar giving a position
            onTap: (index) {
              setState(() {
                FocusScope.of(context).requestFocus(FocusNode());
                pageIndex = index;
              });
            },
            items: sentinels
                ? [
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: Text(AppLocalizations.of(context)!
                            .translate('String72')),
                        icon: const Icon(Icons.history)),
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: Text(
                            AppLocalizations.of(context)!.translate('String8')),
                        icon: const Icon(Icons.contacts)),
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: Text(AppLocalizations.of(context)!
                            .translate('String21')),
                        icon: const Icon(Icons.send)),
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: Text(AppLocalizations.of(context)!
                            .translate('String94')),
                        icon: const Icon(Icons.remove_red_eye)),
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: Text(AppLocalizations.of(context)!
                            .translate('String30')),
                        icon: const Icon(Icons.settings)),
                  ]
                : [
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: const Text('History'),
                        icon: const Icon(Icons.history)),
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: const Text('Contacts'),
                        icon: const Icon(Icons.contacts)),
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: const Text('Transfer'),
                        icon: const Icon(Icons.send)),
                    TitledNavigationBarItem(
                        backgroundColor: ColorTheme.of(context)!.baseColor!,
                        title: const Text('Settings'),
                        icon: const Icon(Icons.settings)),
                  ]),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    child: Opacity(
                        opacity: pageIndex == 0 ? 1.0 : 0.0,
                        child: IgnorePointer(
                            child: tranSactionsWidgetInstance,
                            ignoring: pageIndex != 0)),
                  ),
                  Positioned(
                    child: Opacity(
                        opacity: pageIndex == 1 ? 1.0 : 0.0,
                        child: IgnorePointer(
                            child: contactsWindow, ignoring: pageIndex != 1)),
                  ),
                  Positioned(
                    child: Opacity(
                        opacity: pageIndex == 2 ? 1.0 : 0.0,
                        child: IgnorePointer(
                            child: sendWindowInstance,
                            ignoring: pageIndex != 2)),
                  ),
                  Positioned(
                    child: Opacity(
                        opacity: sentinels
                            ? pageIndex == 4
                                ? 1.0
                                : 0.0
                            : pageIndex == 3
                                ? 1.0
                                : 0.0,
                        child: IgnorePointer(
                            child: settingsWindow,
                            ignoring:
                                sentinels ? pageIndex != 4 : pageIndex != 3)),
                  ),
                  Positioned(
                    child: Opacity(
                        opacity: sentinels
                            ? pageIndex == 3
                                ? 1.0
                                : 0.0
                            : pageIndex == 4
                                ? 1.0
                                : 0.0,
                        child: IgnorePointer(
                            child: verifiersWindow,
                            ignoring:
                                sentinels ? pageIndex != 3 : pageIndex != 4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
