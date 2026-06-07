// ignore_for_file: unused_element, unused_field

import 'dart:convert';

import 'package:dio/dio.dart';

import '../dtos/naver_stock_dtos.dart';

abstract interface class NaverStockDataClient {
  Future<List<NaverAutocompleteItemDto>> searchStocks(String query);

  Future<Map<String, NaverRealtimeQuoteDto>> fetchRealtimeQuotes(
    Iterable<String> symbols,
  );

  Future<NaverChartMetadataDto> fetchChartMetadata(String symbol);

  Future<NaverDailyHistoryPageDto> fetchDailyHistoryPage({
    required String symbol,
    required int page,
  });
}

class NaverDomesticStockClient implements NaverStockDataClient {
  const NaverDomesticStockClient(this._dio);

  final Dio _dio;

  static const Map<String, String> _defaultHeaders = {
    'accept': 'application/json, text/plain, */*',
    'referer': 'https://m.stock.naver.com/',
    'accept-language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
    'user-agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/123.0.0.0 Safari/537.36',
  };

  static Map<String, dynamic> _decodeJsonObjectBody(
    Object? data,
    String contextLabel,
  ) {
    if (data == null) {
      throw FormatException('$contextLabel response body is empty');
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('$contextLabel response is not a JSON object');
    }

    if (data is List<int>) {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('$contextLabel response is not a JSON object');
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    throw FormatException('$contextLabel response body has unsupported shape');
  }

  static Map<String, dynamic> _asStringKeyedMap(
    Object? value,
    String contextLabel,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    throw FormatException('$contextLabel is not a JSON object');
  }

  @override
  Future<List<NaverAutocompleteItemDto>> searchStocks(String query) async {
    // 네이버 자동완성 API 호출. 응답이 plain text JSON으로 올 수 있어 ResponseType.plain 사용.
    // items 배열 안에 검색 결과가 들어 있으며 각 항목을 DTO로 변환한다.
    final response = await _dio.get<Object>(
      'https://ac.stock.naver.com/ac',
      queryParameters: {
        'q': query,
        'target': 'stock,ipo,index,marketindicator',
      },
      options: Options(headers: _defaultHeaders, responseType: ResponseType.plain),
    );

    final body = _decodeJsonObjectBody(response.data, 'searchStocks');
    final items = body['items'];
    if (items == null) {
      return [];
    }

    // items는 배열의 배열([[code, name, typeCode, typeName, url, nationCode, category]])이거나
    // 객체 배열일 수 있다. 객체 배열 형태로 통일한다.
    final list = items as List<dynamic>;
    return list.map((item) {
      if (item is List) {
        // 배열 형태: [code, name, typeCode, typeName, url, nationCode, category]
        return NaverAutocompleteItemDto.fromJson({
          'code': item[0],
          'name': item[1],
          'typeCode': item[2],
          'typeName': item[3],
          'url': item[4],
          'nationCode': item[5],
          'category': item[6],
        });
      }
      return NaverAutocompleteItemDto.fromJson(
        _asStringKeyedMap(item, 'searchStocks item'),
      );
    }).toList(growable: false);
  }

  @override
  Future<Map<String, NaverRealtimeQuoteDto>> fetchRealtimeQuotes(
    Iterable<String> symbols,
  ) async {
    // 심볼 중복 제거. 빈 목록이면 네트워크 요청 없이 빈 맵 반환.
    final uniqueSymbols = symbols.toSet();
    if (uniqueSymbols.isEmpty) {
      return {};
    }

    // SERVICE_ITEM:005930,000660 형태의 쿼리 파라미터 생성
    final query = 'SERVICE_ITEM:${uniqueSymbols.join(',')}';

    final response = await _dio.get<Object>(
      'https://polling.finance.naver.com/api/realtime',
      queryParameters: {'query': query},
      options: Options(headers: _defaultHeaders, responseType: ResponseType.plain),
    );

    final body = _decodeJsonObjectBody(response.data, 'fetchRealtimeQuotes');

    // 응답 구조: result -> areas -> [{ datas: [...] }]
    final result = _asStringKeyedMap(body['result'], 'result');
    final areas = result['areas'] as List<dynamic>? ?? [];
    final quotes = <String, NaverRealtimeQuoteDto>{};

    for (final area in areas) {
      final areaMap = _asStringKeyedMap(area, 'area');
      final datas = areaMap['datas'] as List<dynamic>? ?? [];
      for (final data in datas) {
        final dto = NaverRealtimeQuoteDto.fromJson(
          _asStringKeyedMap(data, 'realtime data'),
        );
        quotes[dto.symbol] = dto;
      }
    }

    return quotes;
  }

  @override
  Future<NaverChartMetadataDto> fetchChartMetadata(String symbol) async {
    // 종목 메타데이터(이름, 거래소명) 조회. 결과를 DTO로 변환한다.
    final response = await _dio.get<Object>(
      'https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/$symbol',
      options: Options(headers: _defaultHeaders),
    );

    final body = _decodeJsonObjectBody(response.data, 'fetchChartMetadata');
    return NaverChartMetadataDto.fromJson(body);
  }

  @override
  Future<NaverDailyHistoryPageDto> fetchDailyHistoryPage({
    required String symbol,
    required int page,
  }) async {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'page must be >= 1');
    }

    // HTML 응답을 bytes로 받아 latin1로 디코딩한다. (EUC-KR 혼용 페이지도 latin1로 읽어야 한다)
    final response = await _dio.get<List<int>>(
      'https://finance.naver.com/item/sise_day.naver',
      queryParameters: {'code': symbol, 'page': page},
      options: Options(
        headers: {
          ..._defaultHeaders,
          'referer': 'https://finance.naver.com/item/sise.naver?code=$symbol',
        },
        responseType: ResponseType.bytes,
      ),
    );

    final html = latin1.decode(response.data ?? []);

    // 날짜 패턴으로 데이터 행을 찾는다.
    // 테이블 열 순서: 날짜 | 종가 | 전일비 | 시가 | 고가 | 저가 | 거래량
    final rowPattern = RegExp(
      r'<td class="date">(\d{4}\.\d{2}\.\d{2})</td>\s*'
      r'<td class="number_1"><span[^>]*>([0-9,]+)</span></td>\s*' // 종가
      r'<td[^>]*>.*?</td>\s*'                                      // 전일비 (생략)
      r'<td class="number_1">([0-9,]+)</td>\s*'                    // 시가
      r'<td class="number_1">([0-9,]+)</td>\s*'                    // 고가
      r'<td class="number_1">([0-9,]+)</td>\s*'                    // 저가
      r'<td class="number_1">([0-9,]+)</td>',                      // 거래량
      dotAll: true,
    );

    final priceInfos = <NaverHistoricalPriceDto>[];
    for (final match in rowPattern.allMatches(html)) {
      final dateRaw = match.group(1)!.replaceAll('.', ''); // yyyyMMdd
      priceInfos.add(
        NaverHistoricalPriceDto.fromJson({
          'localDate': dateRaw,
          'closePrice': _parseInt(match.group(2)!).toDouble(),
          'openPrice': _parseInt(match.group(3)!).toDouble(),
          'highPrice': _parseInt(match.group(4)!).toDouble(),
          'lowPrice': _parseInt(match.group(5)!).toDouble(),
          'accumulatedTradingVolume': _parseInt(match.group(6)!),
        }),
      );
    }

    // 페이지네이션 영역에서 lastPage를 추출한다.
    // 형태: <a href="...page=N">맨뒤</a> 혹은 <a ... href="sise_day.naver?code=...&page=N">
    int lastPage = page;
    final lastPagePattern = RegExp(r'pgRR.*?page=(\d+)', dotAll: true);
    final lastPageMatch = lastPagePattern.firstMatch(html);
    if (lastPageMatch != null) {
      lastPage = int.parse(lastPageMatch.group(1)!);
    }

    return NaverDailyHistoryPageDto(
      symbol: symbol,
      page: page,
      lastPage: lastPage,
      priceInfos: priceInfos,
    );
  }
}

double _parseDouble(String value) {
  return double.parse(value.replaceAll(',', ''));
}

int _parseInt(String value) {
  return int.parse(value.replaceAll(',', ''));
}

Map<String, String> naverDesktopLikeHeaders() =>
    Map<String, String>.unmodifiable(NaverDomesticStockClient._defaultHeaders);
