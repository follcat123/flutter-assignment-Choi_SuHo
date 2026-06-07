// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '../models/watchlist_date_picker_options.dart';
import '../../../../theme/app_theme.dart';

class WatchlistDateBottomSheet extends StatefulWidget {
  const WatchlistDateBottomSheet({
    required this.availableDates,
    required this.initialDate,
    this.controller,
    this.onSubmitted,
    this.onCancelled,
    super.key,
  });

  final List<DateTime> availableDates;
  final DateTime initialDate;
  final WatchlistDateBottomSheetController? controller;
  final ValueChanged<DateTime>? onSubmitted;
  final VoidCallback? onCancelled;

  @override
  State<WatchlistDateBottomSheet> createState() =>
      _WatchlistDateBottomSheetState();
}

class _WatchlistDateBottomSheetState extends State<WatchlistDateBottomSheet> {
  static const double _itemExtent = 44;
  static const double _pickerHeight = 220;

  late final WatchlistDatePickerOptions _options;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _options = WatchlistDatePickerOptions.fromDates(widget.availableDates);
    final resolvedDate = _options.coerce(widget.initialDate);
    _selectedYear = resolvedDate.year;
    _selectedMonth = resolvedDate.month;
    _selectedDay = resolvedDate.day;
    _yearController = FixedExtentScrollController(
      initialItem: _yearIndex(_selectedYear),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _monthIndex(_selectedMonth),
    );
    _dayController = FixedExtentScrollController(
      initialItem: _dayIndex(_selectedDay),
    );
    widget.controller?._attach(
      selectDate: _selectDateValue,
      confirm: _confirm,
      dismiss: _dismiss,
    );
  }

  @override
  void didUpdateWidget(covariant WatchlistDateBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller?._detach();
    widget.controller?._attach(
      selectDate: _selectDateValue,
      confirm: _confirm,
      dismiss: _dismiss,
    );
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  List<int> get _years => _options.years;

  List<int> get _months => _options.monthsForYear(_selectedYear);

  List<int> get _days =>
      _options.daysForMonth(year: _selectedYear, month: _selectedMonth);

  int _yearIndex(int year) => _years.indexOf(year).clamp(0, _years.length - 1);

  int _monthIndex(int month) =>
      _months.indexOf(month).clamp(0, _months.length - 1);

  int _dayIndex(int day) => _days.indexOf(day).clamp(0, _days.length - 1);

  void _scheduleWheelSync({bool syncMonth = false, bool syncDay = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (syncMonth && _monthController.hasClients) {
        _monthController.jumpToItem(_monthIndex(_selectedMonth));
      }

      if (syncDay && _dayController.hasClients) {
        _dayController.jumpToItem(_dayIndex(_selectedDay));
      }
    });
  }

  void _selectYear(int index) {
    final year = _years[index];
    if (year == _selectedYear) {
      return;
    }

    var shouldSyncMonth = false;
    setState(() {
      _selectedYear = year;
      if (!_months.contains(_selectedMonth)) {
        _selectedMonth = _months.first;
        shouldSyncMonth = true;
      }
      if (!_days.contains(_selectedDay)) {
        _selectedDay = _days.first;
      }
    });

    _scheduleWheelSync(syncMonth: shouldSyncMonth, syncDay: true);
  }

  void _selectMonth(int index) {
    final month = _months[index];
    if (month == _selectedMonth) {
      return;
    }

    setState(() {
      _selectedMonth = month;
      if (!_days.contains(_selectedDay)) {
        _selectedDay = _days.first;
      }
    });

    _scheduleWheelSync(syncDay: true);
  }

  void _selectDay(int index) {
    final day = _days[index];
    if (day == _selectedDay) {
      return;
    }

    setState(() {
      _selectedDay = day;
    });
  }

  void _selectDateValue(DateTime value) {
    final resolvedDate = _options.coerce(value);
    setState(() {
      _selectedYear = resolvedDate.year;
      _selectedMonth = resolvedDate.month;
      _selectedDay = resolvedDate.day;
    });
    _scheduleWheelSync(syncMonth: true, syncDay: true);
  }

  void _confirm() {
    final resolvedDate = _options.resolve(
      year: _selectedYear,
      month: _selectedMonth,
      day: _selectedDay,
    );
    final onSubmitted = widget.onSubmitted;
    if (onSubmitted != null) {
      onSubmitted(resolvedDate);
      return;
    }
    Navigator.of(context).pop(resolvedDate);
  }

  void _dismiss() {
    final onCancelled = widget.onCancelled;
    if (onCancelled != null) {
      onCancelled();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Figma 기준: 헤더 + 연/월/일 wheel picker + 취소/확인 버튼
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          key: const Key('watchlist-date-sheet'),
          decoration: BoxDecoration(
            color: AppColors.bg.bg_2_212121,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('날짜 선택', style: AppTypography.sheetTitle),
                  ),
                ),
              ),
              // 연/월/일 피커 영역
              SizedBox(
                height: _pickerHeight,
                child: Row(
                  children: [
                    // 연도 피커
                    Expanded(
                      child: _DateWheelPicker(
                        pickerKey: const Key('watchlist-date-picker-year'),
                        itemKeyPrefix: 'watchlist-date-item-year',
                        controller: _yearController,
                        values: _years,
                        selectedValue: _selectedYear,
                        formatter: (v) => '$v년',
                        onSelectedItemChanged: _selectYear,
                      ),
                    ),
                    // 월 피커
                    Expanded(
                      child: _DateWheelPicker(
                        pickerKey: const Key('watchlist-date-picker-month'),
                        itemKeyPrefix: 'watchlist-date-item-month',
                        controller: _monthController,
                        values: _months,
                        selectedValue: _selectedMonth,
                        formatter: (v) => '$v월',
                        onSelectedItemChanged: _selectMonth,
                      ),
                    ),
                    // 일 피커
                    Expanded(
                      child: _DateWheelPicker(
                        pickerKey: const Key('watchlist-date-picker-day'),
                        itemKeyPrefix: 'watchlist-date-item-day',
                        controller: _dayController,
                        values: _days,
                        selectedValue: _selectedDay,
                        formatter: (v) => '$v일',
                        onSelectedItemChanged: _selectDay,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 취소 / 확인 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        buttonKey: const Key('watchlist-date-cancel'),
                        label: '취소',
                        backgroundColor: AppColors.bg.bg_4_333333,
                        onTap: _dismiss,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SheetButton(
                        buttonKey: const Key('watchlist-date-confirm'),
                        label: '확인',
                        backgroundColor: AppColors.mainAndAccent.primary_ff8a00,
                        onTap: _confirm,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class WatchlistDateBottomSheetController {
  void Function(DateTime value)? _selectDate;
  VoidCallback? _confirm;
  VoidCallback? _dismiss;

  void _attach({
    required void Function(DateTime value) selectDate,
    required VoidCallback confirm,
    required VoidCallback dismiss,
  }) {
    _selectDate = selectDate;
    _confirm = confirm;
    _dismiss = dismiss;
  }

  void _detach() {
    _selectDate = null;
    _confirm = null;
    _dismiss = null;
  }

  void selectDate(DateTime value) {
    _selectDate?.call(value);
  }

  void confirm() {
    _confirm?.call();
  }

  void dismiss() {
    _dismiss?.call();
  }
}

class _DateWheelPicker extends StatelessWidget {
  const _DateWheelPicker({
    required this.pickerKey,
    required this.itemKeyPrefix,
    required this.controller,
    required this.values,
    required this.selectedValue,
    required this.formatter,
    required this.onSelectedItemChanged,
  });

  final Key pickerKey;
  final String itemKeyPrefix;
  final FixedExtentScrollController controller;
  final List<int> values;
  final int selectedValue;
  final String Function(int value) formatter;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      key: pickerKey,
      controller: controller,
      physics: const FixedExtentScrollPhysics(),
      itemExtent: _WatchlistDateBottomSheetState._itemExtent,
      diameterRatio: 100,
      perspective: 0.00001,
      squeeze: 1,
      overAndUnderCenterOpacity: 1,
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final value = values[index];
          final isSelected = value == selectedValue;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              controller.animateToItem(
                index,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
              );
            },
            child: SizedBox(
              height: _WatchlistDateBottomSheetState._itemExtent,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  width: 100,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.bg.bg_4_333333
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatter(value),
                    key: Key('$itemKeyPrefix-$value'),
                    style: tabularTextStyle(
                      (isSelected
                              ? AppTypography.sheetPickerValue
                              : AppTypography.sheetOption)
                          .copyWith(
                            color: isSelected
                                ? AppColors.text.text_fafafa
                                : AppColors.text.text_3_9e9e9e,
                          ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.buttonKey,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        key: buttonKey,
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.text.text_fafafa,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: AppTypography.sheetButton.copyWith(
            color: AppColors.text.text_fafafa,
          ),
        ),
      ),
    );
  }
}
