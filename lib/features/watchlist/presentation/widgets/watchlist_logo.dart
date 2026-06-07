import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/clients/naver_domestic_stock_client.dart';
import '../../domain/models/watchlist_models.dart';
import '../../../../theme/app_theme.dart';

String fallbackMonogram(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }

  final asciiTokens = RegExp(
    r'[A-Za-z0-9]+',
  ).allMatches(trimmed).map((match) => match.group(0)!).toList(growable: false);

  if (asciiTokens.isNotEmpty) {
    if (asciiTokens.length == 1) {
      final token = asciiTokens.first;
      return token.substring(0, token.length > 1 ? 2 : 1).toUpperCase();
    }
    return asciiTokens.take(2).map((token) => token[0]).join().toUpperCase();
  }

  return String.fromCharCode(trimmed.runes.first);
}

bool isSvgLogoUrl(String url) => url.toLowerCase().endsWith('.svg');

Color fallbackLogoColor(String seed) {
  const palette = [
    Color(0xFF4780FF),
    Color(0xFFF93F62),
    Color(0xFF00C27A),
    Color(0xFFFF8A00),
    Color(0xFF8E7CFF),
    Color(0xFF26A69A),
  ];

  final code = seed.runes.fold<int>(0, (total, value) => total + value);
  return palette[code % palette.length];
}

class WatchlistLogo extends StatelessWidget {
  const WatchlistLogo({required this.item, super.key});

  final WatchlistItem item;

  @override
  Widget build(BuildContext context) {
    if (item.logoUrl case final String url?) {
      final fallback = _FallbackLogo(
        label: fallbackMonogram(item.name),
        seed: item.id,
      );
      final normalizedUrl = url.toLowerCase();

      if (isSvgLogoUrl(normalizedUrl)) {
        return _SvgNetworkLogo(url: url, fallback: fallback);
      }

      return ClipOval(
        child: Image.network(
          url,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => fallback,
        ),
      );
    }

    return _FallbackLogo(label: fallbackMonogram(item.name), seed: item.id);
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.label, required this.seed});

  final String label;
  final String seed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = fallbackLogoColor(seed);
    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: AppTypography.listName.copyWith(
              color: AppColors.grays.white,
              fontWeight: FontWeight.w700,
              fontSize: label.length > 1 ? 9 : 10,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SvgNetworkLogo extends StatefulWidget {
  const _SvgNetworkLogo({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  State<_SvgNetworkLogo> createState() => _SvgNetworkLogoState();
}

class _SvgNetworkLogoState extends State<_SvgNetworkLogo> {
  static final Dio _dio = Dio();
  static final Map<String, Future<String?>> _svgMarkupCache = {};

  late final Future<String?> _svgMarkupFuture = _svgMarkupCache.putIfAbsent(
    widget.url,
    () => _loadSvgMarkup(widget.url),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _svgMarkupFuture,
      builder: (context, snapshot) {
        final svgMarkup = snapshot.data;
        if (svgMarkup == null || svgMarkup.isEmpty) {
          return widget.fallback;
        }

        return ClipOval(
          child: SvgPicture.string(
            svgMarkup,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            placeholderBuilder: (context) => widget.fallback,
          ),
        );
      },
    );
  }

  static Future<String?> _loadSvgMarkup(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          headers: naverDesktopLikeHeaders(),
          responseType: ResponseType.bytes,
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      final contentType = response.headers.value(Headers.contentTypeHeader);
      if (contentType == null || !contentType.toLowerCase().contains('svg')) {
        return null;
      }

      final body = utf8.decode(bytes, allowMalformed: true).trimLeft();
      final svgMatch = RegExp(r'<svg[\s\S]*</svg>').firstMatch(body);
      return svgMatch?.group(0);
    } catch (_) {
      return null;
    }
  }
}
