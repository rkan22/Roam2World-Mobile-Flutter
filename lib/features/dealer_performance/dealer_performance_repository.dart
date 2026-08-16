import '../orders/order_history.dart';
import '../orders/orders_repository.dart';

class DealerPerformanceData {
  const DealerPerformanceData({required this.orders});
  final List<MobileOrderSummary> orders;

  int get totalOrders => orders.length;
  int get completedOrders => orders.where((order) {
    final status = order.status.toLowerCase();
    return status == 'completed' || status == 'success';
  }).length;
  double get completedRevenue => orders
      .where((order) {
        final status = order.status.toLowerCase();
        return status == 'completed' || status == 'success';
      })
      .fold<double>(0, (sum, order) => sum + order.amount);
  double get successRate =>
      totalOrders == 0 ? 0 : completedOrders / totalOrders * 100;
  double get averageCompletedOrder =>
      completedOrders == 0 ? 0 : completedRevenue / completedOrders;
}

class DealerPerformanceRepository {
  DealerPerformanceRepository({OrdersRepository? ordersRepository})
    : _ordersRepository = ordersRepository ?? OrdersRepository();

  final OrdersRepository _ordersRepository;

  Future<DealerPerformanceData> fetch() async {
    final history = await _ordersRepository.fetchOrders();
    return DealerPerformanceData(orders: history.orders);
  }
}
