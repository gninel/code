// Web平台调试辅助工具
// 此文件用于Chrome调试时的辅助功能

import 'dart:html' as html;
import 'dart:js' as js;

/// Web调试辅助类
class WebDebugHelper {
  static bool get isDebugMode {
    return !const bool.fromEnvironment('dart.vm.product');
  }

  /// 在控制台输出调试信息
  static void log(String message, [String level = 'info']) {
    if (!isDebugMode) return;

    switch (level.toLowerCase()) {
      case 'error':
        html.window.console.error(message);
        break;
      case 'warn':
        html.window.console.warn(message);
        break;
      case 'info':
      default:
        html.window.console.info(message);
        break;
    }
  }

  /// 记录性能指标
  static void logPerformance(String operation, int milliseconds) {
    log('Performance: $operation took ${milliseconds}ms', 'info');
  }

  /// 记录内存使用情况
  static void logMemoryUsage() {
    if (js.context.hasProperty('performance') &&
        js.context['performance'].hasProperty('memory')) {
      final memory = js.context['performance']['memory'];
      log('Memory: used=${memory['usedJSHeapSize']}, total=${memory['totalJSHeapSize']}', 'info');
    }
  }

  /// 启用性能监控
  static void enablePerformanceMonitoring() {
    if (!isDebugMode) return;

    // 监控页面加载时间
    html.window.addEventListener('load', (event) {
      if (js.context.hasProperty('performance') &&
          js.context['performance'].hasProperty('timing')) {
        final timing = js.context['performance']['timing'];
        final loadTime = timing['loadEventEnd'] - timing['navigationStart'];
        logPerformance('Page Load', loadTime);
      }
    });

    // 监控API请求
    final originalFetch = js.context['fetch'];
    js.context['fetch'] = (input, [init]) {
      final start = DateTime.now().millisecondsSinceEpoch;
      return originalFetch(input, init).then((response) {
        final duration = DateTime.now().millisecondsSinceEpoch - start;
        logPerformance('API Request: $input', duration);
        return response;
      });
    };
  }

  /// 创建调试面板
  static void createDebugPanel() {
    if (!isDebugMode) return;

    final panel = html.DivElement()
      ..id = 'flutter-debug-panel'
      ..style.position = 'fixed'
      ..style.top = '10px'
      ..style.right = '10px'
      ..style.width = '200px'
      ..style.backgroundColor = 'rgba(0, 0, 0, 0.8)'
      ..style.color = 'white'
      ..style.padding = '10px'
      ..style.borderRadius = '8px'
      ..style.zIndex = '9999'
      ..style.fontSize = '12px';

    final title = html.DivElement()
      ..text = '🐛 Debug Panel'
      ..style.fontWeight = 'bold'
      ..style.marginBottom = '10px';

    final memoryBtn = html.ButtonElement()
      ..text = 'Memory Usage'
      ..style.width = '100%'
      ..style.marginBottom = '5px'
      ..onClick.listen((event) {
        logMemoryUsage();
      });

    final performanceBtn = html.ButtonElement()
      ..text = 'Performance'
      ..style.width = '100%'
      ..style.marginBottom = '5px'
      ..onClick.listen((event) {
        if (js.context.hasProperty('performance') &&
            js.context['performance'].hasProperty('getEntriesByType')) {
          final entries = js.context['performance'].getEntriesByType('navigation');
          if (entries.length > 0) {
            final nav = entries[0];
            log('Navigation Performance: ${nav}', 'info');
          }
        }
      });

    final clearBtn = html.ButtonElement()
      ..text = 'Clear Storage'
      ..style.width = '100%'
      ..onClick.listen((event) {
        html.window.localStorage.clear();
        html.window.sessionStorage.clear();
        log('Storage cleared', 'info');
      });

    final closeBtn = html.ButtonElement()
      ..text = '✕ Close'
      ..style.position = 'absolute'
      ..style.top = '5px'
      ..style.right = '5px'
      ..style.border = 'none'
      ..style.background = 'transparent'
      ..style.color = 'white'
      ..style.cursor = 'pointer'
      ..onClick.listen((event) {
        panel.remove();
      });

    panel.children.addAll([
      title,
      memoryBtn,
      performanceBtn,
      clearBtn,
      closeBtn
    ]);

    html.document.body?.append(panel);
  }

  /// 监控网络请求
  static void monitorNetworkRequests() {
    if (!isDebugMode) return;

    final originalOpen = js.context['XMLHttpRequest']['prototype']['open'];
    js.context['XMLHttpRequest']['prototype']['open'] = (method, url, async, user, password) {
      final start = DateTime.now().millisecondsSinceEpoch;

      final originalOnLoad = js.this['onload'];
      js.this['onload'] = (event) {
        final duration = DateTime.now().millisecondsSinceEpoch - start;
        logPerformance('XHR: ${method} ${url}', duration);
        if (originalOnLoad != null) {
          originalOnLoad(event);
        }
      };

      originalOpen(method, url, async, user, password);
    };
  }

  /// 添加Flutter调试桥接
  static void setupFlutterBridge() {
    if (!isDebugMode) return;

    // 暴露给Flutter的JavaScript接口
    js.context['flutterDebug'] = {
      'log': (String message) => log(message),
      'logPerformance': (String operation, int ms) => logPerformance(operation, ms),
      'logMemory': () => logMemoryUsage(),
      'createPanel': () => createDebugPanel(),
    };

    log('Flutter Debug Bridge initialized', 'info');
  }
}