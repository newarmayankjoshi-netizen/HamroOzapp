class RentCalculator {
  static double monthlyFromWeekly(double weeklyRent) {
    return weeklyRent * 52 / 12;
  }

  static double yearlyFromWeekly(double weeklyRent) {
    return weeklyRent * 52;
  }

  static double bondFromWeekly(double weeklyRent) {
    return weeklyRent * 4;
  }

  static double rentPerPersonWeekly(double weeklyRent, int people) {
    final safePeople = people <= 0 ? 1 : people;
    return weeklyRent / safePeople;
  }

  static double utilitiesPerPersonWeekly(double utilitiesPerWeek, int people) {
    final safePeople = people <= 0 ? 1 : people;
    return utilitiesPerWeek / safePeople;
  }

  static double moveInCost(double weeklyRent) {
    // Per spec: moveInCost = bond + firstWeekRent.
    return bondFromWeekly(weeklyRent) + weeklyRent;
  }
}
