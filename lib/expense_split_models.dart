enum ExpenseSplitMode { equal, unequal, whoPaid }

extension ExpenseSplitModeLabel on ExpenseSplitMode {
  String get label {
    switch (this) {
      case ExpenseSplitMode.equal:
        return 'Equal';
      case ExpenseSplitMode.unequal:
        return 'Unequal';
      case ExpenseSplitMode.whoPaid:
        return 'Who paid?';
    }
  }
}

enum ExpenseCategory { rent, groceries, utilities, furniture, travel }

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.groceries:
        return 'Groceries';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.furniture:
        return 'Furniture';
      case ExpenseCategory.travel:
        return 'Travel';
    }
  }
}

enum RecurringFrequency { weekly, fortnightly, monthly }

extension RecurringFrequencyLabel on RecurringFrequency {
  String get label {
    switch (this) {
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.fortnightly:
        return 'Fortnightly';
      case RecurringFrequency.monthly:
        return 'Monthly';
    }
  }
}
