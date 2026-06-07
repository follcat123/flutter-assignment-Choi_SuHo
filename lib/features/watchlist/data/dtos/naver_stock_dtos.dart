// ignore_for_file: unused_element

import '../../domain/services/watchlist_sorting.dart';

class NaverAutocompleteItemDto {
  const NaverAutocompleteItemDto({
    required this.code,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.url,
    required this.nationCode,
    required this.category,
  });

  factory NaverAutocompleteItemDto.fromJson(Map<String, dynamic> json) {
    // 네이버 자동완성 API 응답에서 각 항목을 파싱한다.
    // isDomesticStock 판별에 category, nationCode, code 패턴, url이 모두 쓰이므로
    // 필드를 그대로 저장하고 getter에서 판별한다.
    return NaverAutocompleteItemDto(
      code: _readString(json['code']),
      name: _readString(json['name']),
      typeCode: _readString(json['typeCode']),
      typeName: _readString(json['typeName']),
      url: _readString(json['url']),
      nationCode: _readString(json['nationCode']),
      category: _readString(json['category']),
    );
  }

  final String code;
  final String name;
  final String typeCode;
  final String typeName;
  final String url;
  final String nationCode;
  final String category;

  bool get isDomesticStock =>
      category == 'stock' &&
      nationCode == 'KOR' &&
      RegExp(r'^\d{6}$').hasMatch(code) &&
      url.contains('/domestic/stock/');
}

class NaverRealtimeQuoteDto {
  const NaverRealtimeQuoteDto({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
    required this.countOfListedStock,
  });

  factory NaverRealtimeQuoteDto.fromJson(Map<String, dynamic> json) {
    // polling.finance.naver.com 실시간 시세 응답 파싱.
    // countOfListedStock은 없을 수 있으므로 nullable 처리.
    return NaverRealtimeQuoteDto(
      symbol: _readString(json['cd']),
      currentPrice: _readDouble(json['nv']),
      previousClose: _readDouble(json['pcv']),
      openPrice: _readDouble(json['ov']),
      highPrice: _readDouble(json['hv']),
      lowPrice: _readDouble(json['lv']),
      accumulatedTradingVolume: _readInt(json['aq']),
      countOfListedStock: _readNullableInt(json['countOfListedStock']) ?? 0,
    );
  }

  final String symbol;
  final double currentPrice;
  final double previousClose;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final int accumulatedTradingVolume;
  final int countOfListedStock;

  double get changeAmount => currentPrice - previousClose;

  double get changeRate {
    if (previousClose == 0) {
      return 0;
    }
    return double.parse(
      (((currentPrice - previousClose) / previousClose) * 100).toStringAsFixed(
        2,
      ),
    );
  }
}

class NaverChartMetadataDto {
  const NaverChartMetadataDto({
    required this.symbol,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  factory NaverChartMetadataDto.fromJson(Map<String, dynamic> json) {
    // stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol} 응답 파싱.
    return NaverChartMetadataDto(
      symbol: _readString(json['symbolCode']),
      stockName: _readString(json['stockName']),
      stockExchangeNameKor: _readString(json['stockExchangeNameKor']),
    );
  }

  final String symbol;
  final String stockName;
  final String stockExchangeNameKor;
}

class NaverHistoricalPriceDto {
  const NaverHistoricalPriceDto({
    required this.localDate,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });

  factory NaverHistoricalPriceDto.fromJson(Map<String, dynamic> json) {
    // JSON 차트 API 또는 HTML 파싱 결과를 동일한 DTO로 수용한다.
    return NaverHistoricalPriceDto(
      localDate: _readLocalDate(json['localDate']),
      closePrice: _readDouble(json['closePrice']),
      openPrice: _readDouble(json['openPrice']),
      highPrice: _readDouble(json['highPrice']),
      lowPrice: _readDouble(json['lowPrice']),
      accumulatedTradingVolume: _readInt(json['accumulatedTradingVolume']),
    );
  }

  final DateTime localDate;
  final double closePrice;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final int accumulatedTradingVolume;
}

class NaverHistoricalChartDto {
  const NaverHistoricalChartDto({
    required this.symbol,
    required this.periodType,
    required this.priceInfos,
  });

  factory NaverHistoricalChartDto.fromJson(Map<String, dynamic> json) {
    // 차트 래퍼 파싱. priceInfos 배열의 각 항목을 NaverHistoricalPriceDto로 변환한다.
    final rawInfos = json['priceInfos'] as List<dynamic>? ?? [];
    return NaverHistoricalChartDto(
      symbol: _readString(json['code']),
      periodType: _readString(json['periodType']),
      priceInfos: rawInfos
          .cast<Map<String, dynamic>>()
          .map(NaverHistoricalPriceDto.fromJson)
          .toList(growable: false),
    );
  }

  final String symbol;
  final String periodType;
  final List<NaverHistoricalPriceDto> priceInfos;
}

class NaverDailyHistoryPageDto {
  const NaverDailyHistoryPageDto({
    required this.symbol,
    required this.page,
    required this.lastPage,
    required this.priceInfos,
  });

  final String symbol;
  final int page;
  final int lastPage;
  final List<NaverHistoricalPriceDto> priceInfos;
}

DateTime _readLocalDate(Object? value) {
  final text = _readString(value);
  if (text.length != 8) {
    throw FormatException('Invalid Naver localDate "$text"');
  }

  return normalizeAsOfDate(
    DateTime(
      int.parse(text.substring(0, 4)),
      int.parse(text.substring(4, 6)),
      int.parse(text.substring(6, 8)),
    ),
  );
}

String _readString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    throw FormatException('Missing string value for "$value"');
  }
  return text;
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.parse(_readString(value).replaceAll(',', ''));
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.parse(_readString(value).replaceAll(',', ''));
}

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  return _readInt(value);
}
