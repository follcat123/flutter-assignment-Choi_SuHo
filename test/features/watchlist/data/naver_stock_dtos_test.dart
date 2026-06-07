import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/watchlist/data/dtos/naver_stock_dtos.dart';

void main() {
  test('parses domestic autocomplete results from Naver', () {
    final item = NaverAutocompleteItemDto.fromJson(const {
      'code': '005930',
      'name': '삼성전자',
      'typeCode': 'KOSPI',
      'typeName': '코스피',
      'url': '/domestic/stock/005930/total',
      'nationCode': 'KOR',
      'category': 'stock',
    });

    expect(item.code, '005930');
    expect(item.name, '삼성전자');
    expect(item.typeName, '코스피');
    expect(item.isDomesticStock, isTrue);
  });

  test('filters out non six-digit domestic stock codes', () {
    final item = NaverAutocompleteItemDto.fromJson(const {
      'code': '0115H0',
      'name': '기타',
      'typeCode': 'KOSPI',
      'typeName': '코스피',
      'url': '/domestic/stock/0115H0/total',
      'nationCode': 'KOR',
      'category': 'stock',
    });

    expect(item.isDomesticStock, isFalse);
  });

  test('computes realtime change from current price and previous close', () {
    final quote = NaverRealtimeQuoteDto.fromJson(const {
      'cd': '005930',
      'nv': 179700,
      'pcv': 180100,
      'ov': 172100,
      'hv': 181700,
      'lv': 172000,
      'aq': 29113466,
      'countOfListedStock': 5919637922,
    });

    expect(quote.changeAmount, -400);
    expect(quote.changeRate, closeTo(-0.22, 0.001));
  });

  test('parses monthly historical chart rows', () {
    final chart = NaverHistoricalChartDto.fromJson(const {
      'code': '005930',
      'periodType': 'month',
      'priceInfos': [
        {
          'localDate': '20260326',
          'closePrice': 180100,
          'openPrice': 185500,
          'highPrice': 185900,
          'lowPrice': 178900,
          'accumulatedTradingVolume': 32074131,
        },
        {
          'localDate': '20260327',
          'closePrice': 179700,
          'openPrice': 172100,
          'highPrice': 181700,
          'lowPrice': 172000,
          'accumulatedTradingVolume': 29113466,
        },
      ],
    });

    expect(chart.symbol, '005930');
    expect(chart.periodType, 'month');
    expect(chart.priceInfos, hasLength(2));
    expect(chart.priceInfos.last.localDate, DateTime(2026, 3, 27));
    expect(chart.priceInfos.last.closePrice, 179700);
  });
}
