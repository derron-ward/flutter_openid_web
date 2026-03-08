import 'package:web/web.dart' as web;

class WebUtils {
  static Uri get currentUrl => Uri.parse(web.window.location.href);
  static String get currentPath => web.window.location.pathname;

  static void replaceUrlState(String url) =>
    web.window.history.replaceState(null, '', url);
  
  static void redirect(String url) =>
    web.window.location.assign(url);

  static void setSessionValue(String key, String value) =>
    web.window.sessionStorage.setItem(key, value);

  static String? getSessionValue(String key) =>
    web.window.sessionStorage.getItem(key);

  static void removeSessionValue(String key) =>
    web.window.sessionStorage.removeItem(key);

    static void setLocalValue(String key, String value) =>
    web.window.localStorage.setItem(key, value);

  static String? getLocalValue(String key) =>
    web.window.localStorage.getItem(key);

  static void removeLocalValue(String key) =>
    web.window.localStorage.removeItem(key);
}