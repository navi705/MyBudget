part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class ChangeTab extends DashboardEvent {
  final int index;
  const ChangeTab(this.index);

  @override
  List<Object?> get props => [index];
}

class ChangeDateRange extends DashboardEvent {
  final DateTime start;
  final DateTime end;
  const ChangeDateRange(this.start, this.end);

  @override
  List<Object?> get props => [start, end];
}

class SelectDay extends DashboardEvent {
  final DateTime day;
  const SelectDay(this.day);

  @override
  List<Object?> get props => [day];
}

class ToggleChartType extends DashboardEvent {
  final bool isIncome;
  const ToggleChartType(this.isIncome);

  @override
  List<Object?> get props => [isIncome];
}
