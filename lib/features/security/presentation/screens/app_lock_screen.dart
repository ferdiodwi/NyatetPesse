import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/security/presentation/providers/security_provider.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  final Widget child; // The main app content to show when unlocked
  
  const AppLockScreen({super.key, required this.child});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> with WidgetsBindingObserver {
  String _pinInput = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Automatically try biometric auth when screen opens if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(securityControllerProvider);
      if (state.isBiometricEnabled && state.isBiometricSupported) {
        _tryBiometric();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
       ref.read(securityControllerProvider.notifier).lockApp();
    } else if (state == AppLifecycleState.resumed) {
       final securityState = ref.read(securityControllerProvider);
       if (securityState.isAppLocked && securityState.isBiometricEnabled && securityState.isBiometricSupported) {
         _tryBiometric();
       }
    }
  }

  Future<void> _tryBiometric() async {
    await ref.read(securityControllerProvider.notifier).authenticateWithBiometric();
  }

  void _onNumberPressed(String number) async {
    if (_pinInput.length < 6) {
      setState(() {
        _pinInput += number;
        _hasError = false;
      });

      if (_pinInput.length == 6) {
        // Verify PIN
        final success = await ref.read(securityControllerProvider.notifier).verifyPin(_pinInput);
        if (!success) {
          setState(() {
            _hasError = true;
            _pinInput = '';
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_pinInput.isNotEmpty) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityControllerProvider);

    // If not locked, show the main app
    if (!securityState.isAppLocked) {
      return widget.child;
    }

    // Otherwise show the lock screen
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(
              Icons.lock,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Masukkan PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pinInput.length
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: _hasError
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_hasError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'PIN Salah',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            _buildNumberPad(securityState),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(SecurityState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (state.isBiometricEnabled && state.isBiometricSupported)
                _buildActionButton(Icons.fingerprint, _tryBiometric)
              else
                const SizedBox(width: 72, height: 72), // Placeholder to keep alignment
              _buildNumberButton('0'),
              _buildActionButton(Icons.backspace_outlined, _onDeletePressed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 28,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
