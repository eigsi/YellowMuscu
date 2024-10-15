import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class WeeklyChartWidget extends StatelessWidget {
  final List<ActivityData> data;

  const WeeklyChartWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        title: ChartTitle(text: 'Activité Hebdomadaire'),
        series: <ChartSeries>[
          ColumnSeries<ActivityData, String>(
            dataSource: data,
            xValueMapper: (ActivityData activity, _) => activity.day,
            yValueMapper: (ActivityData activity, _) => activity.hours,
            color: Colors.yellow[700],
          ),
        ],
      ),
    );
  }
}

class ActivityData {
  final String day;
  final int hours;

  ActivityData(this.day, this.hours);
}
