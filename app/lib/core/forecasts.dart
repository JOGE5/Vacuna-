import '../models/entities.dart';

DateTime dayOf(DateTime value) => DateTime(value.year, value.month, value.day);

class CampaignPace {
  CampaignPace(
    this.dailyGoal,
    this.dailyAverage,
    this.estimatedFinish,
    this.onTrack,
  );
  final int dailyGoal;
  final double dailyAverage;
  final DateTime? estimatedFinish;
  final bool onTrack;
}

CampaignPace campaignPace(
  Campaign campaign,
  Iterable<Vaccination> records,
  DateTime now,
) {
  final today = dayOf(now);
  final remaining = (campaign.goal - campaign.applied).clamp(0, campaign.goal);
  final daysLeft = dayOf(campaign.end).difference(today).inDays + 1;
  final dailyGoal = remaining == 0
      ? 0
      : daysLeft <= 0
      ? remaining
      : (remaining / daysLeft).ceil();
  final count = records
      .where(
        (v) =>
            v.campaign == campaign &&
            !v.date.isBefore(today.subtract(const Duration(days: 6))) &&
            v.date.isBefore(today.add(const Duration(days: 1))),
      )
      .length;
  final average = count / 7;
  final daysToGoal = remaining == 0
      ? 0
      : average == 0
      ? null
      : (remaining / average).ceil();
  final finish = daysToGoal == null
      ? null
      : today.add(Duration(days: daysToGoal == 0 ? 0 : daysToGoal - 1));
  return CampaignPace(
    dailyGoal,
    average,
    finish,
    finish != null && !finish.isAfter(dayOf(campaign.end)),
  );
}

class StockForecast {
  StockForecast(this.days, this.atRisk);
  final int? days;
  final int atRisk;
}

StockForecast stockForecast(
  Stock stock,
  Iterable<Vaccination> records,
  DateTime now,
) {
  final today = dayOf(now);
  final used = records
      .where(
        (v) =>
            v.lot == stock.lot &&
            v.center == stock.center &&
            !v.date.isBefore(today.subtract(const Duration(days: 6))) &&
            v.date.isBefore(today.add(const Duration(days: 1))),
      )
      .length;
  if (used == 0) return StockForecast(null, 0);
  final perDay = used / 7;
  final days = (stock.quantity / perDay).ceil();
  final validDays = dayOf(stock.expiry).difference(today).inDays + 1;
  final risk = (stock.quantity - (validDays.clamp(0, 1000000) * perDay).floor())
      .clamp(0, stock.quantity);
  return StockForecast(days, risk);
}
