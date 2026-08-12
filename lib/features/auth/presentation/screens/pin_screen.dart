import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/auth/presentation/providers/auth_provider.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/screens/main_screen.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String _setupFirstPin = '';
  bool _isConfirming = false;
  bool _hasError = false;

  void _onDigitPress(String digit) async {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
        _hasError = false;
      });
      
      if (_pin.length == 6) {
        await _processPin();
      }
    }
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
      });
    }
  }

  Future<void> _processPin() async {
    final authState = ref.read(authStateProvider);
    
    // DELAY FOR UX
    await Future.delayed(const Duration(milliseconds: 200));

    if (!authState.isPinSetup) {
      if (!_isConfirming) {
        // Step 1 of Setup
        setState(() {
          _setupFirstPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      } else {
        // Step 2 of Setup
        if (_pin == _setupFirstPin) {
          final success = await ref.read(authStateProvider.notifier).setupPin(_pin);
          if (success && mounted) {
            _navigateToHome();
          }
        } else {
          setState(() {
            _hasError = true;
            _pin = '';
            _setupFirstPin = '';
            _isConfirming = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN tidak sama. Silakan coba lagi.')));
          }
        }
      }
    } else {
      // Login
      final isValid = await ref.read(authStateProvider.notifier).verifyPin(_pin);
      if (isValid) {
        if (mounted) {
          _navigateToHome();
        }
      } else {
        setState(() {
          _hasError = true;
          _pin = '';
        });
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN salah. Silakan coba lagi.')));
        }
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    String title = 'Masukkan PIN Anda';
    if (!authState.isPinSetup) {
      title = _isConfirming ? 'Konfirmasi PIN Baru' : 'Buat PIN Baru (6 Digit)';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (_hasError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary)
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
            const Spacer(),
            // Numpad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  _buildNumpadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildNumpadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildNumpadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 80, height: 80), // Empty space
                      _buildNumpadButton('0'),
                      _buildDeleteButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumpadButton(d)).toList(),
    );
  }

  Widget _buildNumpadButton(String digit) {
    return InkWell(
      onTap: () => _onDigitPress(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDeletePress,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, size: 32),
      ),
    );
  }
}
