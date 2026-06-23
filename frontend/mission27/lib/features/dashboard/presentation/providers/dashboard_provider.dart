import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/dashboard_model.dart';
import '../../domain/entities/dashboard_entity.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/dashboard/summary');
  return DashboardSummaryModel.fromJson(response.data as Map<String, dynamic>);
}
