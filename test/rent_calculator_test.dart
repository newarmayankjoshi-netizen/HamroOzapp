import 'package:hamro_oz/services/rent_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekly → monthly uses 52/12', () {
    final monthly = RentCalculator.monthlyFromWeekly(240);
    expect(monthly, closeTo(1040, 0.0001));
  });

  test('bond is 4 weeks', () {
    expect(RentCalculator.bondFromWeekly(240), 960);
  });

  test('split rent between roommates', () {
    expect(RentCalculator.rentPerPersonWeekly(240, 3), 80);
  });

  test('move-in cost is bond + first week', () {
    expect(RentCalculator.moveInCost(240), 1200);
  });
}
