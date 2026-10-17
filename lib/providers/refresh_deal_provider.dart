import 'package:flutter/foundation.dart';

class RefreshDealProvider with ChangeNotifier {
  bool refreshDeal = false;
  bool refreshProperties = false;
  var dealId;
  changeState(bool newState) {
    refreshDeal = newState;
    notifyListeners();
  }

  shouldRefreshProperty(bool newState) {
    this.refreshProperties = newState;
    notifyListeners();
  }

  shouldRefreshPropertyWithoutNoti(bool newState) {
    this.refreshProperties = newState;
  }

  getShouldRefreshState() {
    return refreshProperties;
  }

  setDealId(dId) {
    dealId = dId;
  }

  getDealId() {
    return dealId;
  }

  changeStateWithoutNotif(bool newState) {
    refreshDeal = newState;
  }

  getState() {
    return refreshDeal;
  }
}
