/// Low-level eUICC channel contract used by embedded LPA transports.
abstract interface class EuiccChannel {
  Future<void> open();
  Future<List<int>> transmit(List<int> apdu);
  Future<void> close();
}
