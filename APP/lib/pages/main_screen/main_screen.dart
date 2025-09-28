import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:animations/animations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:APP/pages/home_screen/home_screen.dart';
import 'package:APP/pages/stats/stats_view.dart';
import 'package:APP/pages/recommend/recommend_view.dart';
import 'package:APP/pages/mypage/my_page_screen.dart';
import 'package:APP/widget/nav_bar.dart';
import 'package:APP/auth/auth_api.dart'; // reissueRaw 사용

enum AuthStatus { valid, refreshed, failed, networkFail }

class _TokenManager {
    _TokenManager._();
    static final _TokenManager I = _TokenManager._();

    Future<(String?, String?)> _load() async {
        final a = await TokenStore.access();
        final r = await TokenStore.refresh();
        return (a, r);
    }

    Map<String, dynamic>? _decode(String jwt) {
        try {
            final p = jwt.split('.');
            if (p.length != 3) return null;
            var b = p[1].replaceAll('-', '+').replaceAll('_', '/');
            switch (b.length % 4) { case 2: b += '=='; break; case 3: b += '='; break; }
            return json.decode(utf8.decode(base64Url.decode(b))) as Map<String, dynamic>;
        } catch (_) { return null; }
    }

    bool _expired(String? jwt, {int leewayMs = 30000}) {
        if (jwt == null || jwt.isEmpty) return true;
        final m = _decode(jwt);
        if (m == null || !m.containsKey('exp')) return true;
        final expMs = ((m['exp'] as num).toInt()) * 1000;
        final now = DateTime.now().millisecondsSinceEpoch;
        return now + leewayMs >= expMs;
    }

    // 서버 응답(String/Map, data 래핑 유무 상관없이)에서 access/refresh 키 자동 탐지
    (String?, String?) _extractTokens(dynamic raw) {
        try {
            dynamic body = raw;
            if (body is String) { body = jsonDecode(body); }
            if (body is Map) {
                final Map src = body['data'] is Map ? body['data'] as Map : body;
                String? at, rt;
                for (final k in src.keys) {
                    final key = k.toString().toLowerCase();
                    if (key.contains('access') && key.contains('token')) {
                        at = src[k]?.toString();
                    } else if (key.contains('refresh') && key.contains('token')) {
                        rt = src[k]?.toString();
                    }
                }
                return (at, rt);
            }
        } catch (_) {}
        return (null, null);
    }

    Future<AuthStatus> ensureValidTokens(BuildContext context) async {
        final (at, rt) = await _load();
        if (!_expired(at)) return AuthStatus.valid;

        try {
            if (kDebugMode) debugPrint('[auth] access expired, reissue');
            if (rt == null || rt.isEmpty) {
                if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (r) => false);
                }
                return AuthStatus.failed;
            }
            final rsp = await AuthApi.reissueRaw(rt);
            if (rsp.statusCode == 200) {
                final (na, nr) = _extractTokens(rsp.data);
                if (na != null && na.isNotEmpty && nr != null && nr.isNotEmpty) {
                    await TokenStore.save(na, nr);
                    final sp = await SharedPreferences.getInstance();
                    await sp.setString('access_token', na);
                    await sp.setString('refresh_token', nr);
                    await sp.setString('accessToken', na);
                    await sp.setString('refreshToken', nr);
                    if (kDebugMode) debugPrint('[auth] reissue ok');
                    return AuthStatus.refreshed;
                }
            }
            if (kDebugMode) debugPrint('[auth] reissue fail code=${rsp.statusCode}');
            if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (r) => false);
            }
            return AuthStatus.failed;
        } catch (e) {
            if (kDebugMode) debugPrint('[auth] reissue error=$e');
            return AuthStatus.networkFail;
        }
    }
}

class _TabObserver extends NavigatorObserver {
    final int tabIndex;
    final void Function(int tabIndex, bool canPop) onStackChanged;
    _TabObserver(this.tabIndex, this.onStackChanged);
    void _notify() => onStackChanged(tabIndex, navigator?.canPop() ?? false);
    @override
    void didPush(Route route, Route? previousRoute) { super.didPush(route, previousRoute); _notify(); }
    @override
    void didPop(Route route, Route? previousRoute) { super.didPop(route, previousRoute); _notify(); }
    @override
    void didRemove(Route route, Route? previousRoute) { super.didRemove(route, previousRoute); _notify(); }
    @override
    void didReplace({Route? newRoute, Route? oldRoute}) { super.didReplace(newRoute: newRoute, oldRoute: oldRoute); _notify(); }
}

class MainScreen extends StatefulWidget {
    const MainScreen({super.key});
    @override
    State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
    int _selectedIndex = 0;
    final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());
    final List<bool> _hideBarForTab = [false, false, false, false];
    final List<int> _tabHistory = [0];

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
        WidgetsBinding.instance.addPostFrameCallback((_) async { await _checkAndNotify(); });
    }

    @override
    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
        super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) async {
        if (state == AppLifecycleState.resumed && mounted) { await _checkAndNotify(); }
    }

    Future<void> _checkAndNotify() async {
        final st = await _TokenManager.I.ensureValidTokens(context);
        if (!mounted) return;
        if (!kDebugMode) return;
        if (st == AuthStatus.refreshed) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('토큰 자동 갱신 완료'), duration: Duration(seconds: 1)));
        } else if (st == AuthStatus.failed) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('토큰 갱신 실패'), duration: Duration(seconds: 2)));
        } else if (st == AuthStatus.networkFail) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('네트워크 문제로 갱신 보류'), duration: Duration(seconds: 2)));
        }
    }

    void _onStackChanged(int tab, bool canPop) {
        if (_hideBarForTab[tab] != canPop) setState(() => _hideBarForTab[tab] = canPop);
    }

    void _popCurrentTabToRoot() {
        final nav = navigatorKeys[_selectedIndex].currentState;
        nav?.popUntil((r) => r.isFirst);
    }

    Widget _rootFor(int index) {
        switch (index) {
            case 0: return const HomeScreen();
            case 1: return const StatsView();
            case 2: return const RecommendView();
            case 3: return const MyPageScreen();
            default: return const HomeScreen();
        }
    }

    PageRoute _fadeThroughTo(Widget child) {
        return PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (_, __, ___) => child,
            transitionsBuilder: (_, a, sa, c) => FadeThroughTransition(animation: a, secondaryAnimation: sa, child: c),
        );
    }

    void _rebuildTab(int index) {
        final nav = navigatorKeys[index].currentState;
        if (nav == null) return;
        nav.popUntil((r) => r.isFirst);
        nav.pushReplacement(_fadeThroughTo(_rootFor(index)));
    }

    Future<void> _onItemTapped(int index) async {
        final st = await _TokenManager.I.ensureValidTokens(context);
        if (kDebugMode && mounted) {
            if (st == AuthStatus.refreshed) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('탭 $index: 토큰 자동 갱신'), duration: const Duration(seconds: 1)));
            } else if (st == AuthStatus.failed) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('탭 $index: 갱신 실패'), duration: const Duration(seconds: 2)));
            } else if (st == AuthStatus.networkFail) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('탭 $index: 네트워크 보류'), duration: const Duration(seconds: 2)));
            }
        }
        if (st == AuthStatus.failed) return;
        if (_selectedIndex == index) { _rebuildTab(index); return; }
        final prev = _selectedIndex;
        _popCurrentTabToRoot();
        setState(() {
            _selectedIndex = index;
            _tabHistory.remove(index);
            _tabHistory.add(index);
        });
        if (index == 1 && prev != 1) _rebuildTab(1);
    }

    Future<bool> _confirmExit() async {
        final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
                title: const Text('앱을 종료하시겠습니까?'),
                content: const Text('뒤로가기를 눌러 앱을 종료합니다.'),
                actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('아니요')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('예')),
                ],
            ),
        );
        return result ?? false;
    }

    Future<void> _handleBack() async {
        final currentNav = navigatorKeys[_selectedIndex].currentState;
        if (currentNav != null && currentNav.canPop()) { currentNav.pop(); return; }
        if (_tabHistory.length > 1) { _tabHistory.removeLast(); setState(() => _selectedIndex = _tabHistory.last); return; }
        final ok = await _confirmExit();
        if (ok) { if (Platform.isAndroid) { SystemNavigator.pop(); } else { exit(0); } }
    }

    Widget _buildTabNavigator({required int tabIndex, required GlobalKey<NavigatorState> key, required Widget root}) {
        return Navigator(
            key: key,
            observers: [_TabObserver(tabIndex, _onStackChanged)],
            onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => root, settings: settings),
        );
    }

    List<Widget> get _tabs => [
        _buildTabNavigator(tabIndex: 0, key: navigatorKeys[0], root: const HomeScreen()),
        _buildTabNavigator(tabIndex: 1, key: navigatorKeys[1], root: const StatsView()),
        _buildTabNavigator(tabIndex: 2, key: navigatorKeys[2], root: const RecommendView()),
        _buildTabNavigator(tabIndex: 3, key: navigatorKeys[3], root: const MyPageScreen()),
    ];

    @override
    Widget build(BuildContext context) {
        final hideBar = _hideBarForTab[_selectedIndex];
        final tabs = _tabs;
        return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async { if (!didPop) await _handleBack(); },
            child: Scaffold(
                body: Stack(
                    children: List.generate(tabs.length, (i) {
                        final child = tabs[i];
                        return Offstage(
                            offstage: _selectedIndex != i,
                            child: TickerMode(
                                enabled: _selectedIndex == i,
                                child: PageTransitionSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    reverse: false,
                                    transitionBuilder: (c, a, sa) => SharedAxisTransition(
                                        animation: a,
                                        secondaryAnimation: sa,
                                        transitionType: SharedAxisTransitionType.scaled,
                                        child: c,
                                    ),
                                    child: KeyedSubtree(
                                        key: ValueKey('tab-$i-rev-${_hideBarForTab[i]}'),
                                        child: child,
                                    ),
                                ),
                            ),
                        );
                    }),
                ),
                bottomNavigationBar: hideBar ? null : CustomNavBar(currentIndex: _selectedIndex, onTap: (i) async => await _onItemTapped(i)),
            ),
        );
    }
}
