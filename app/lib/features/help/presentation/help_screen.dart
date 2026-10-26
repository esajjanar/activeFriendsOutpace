import 'package:activefriends/core/data/vacation_service.dart';
import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool _loading = true;
  bool _vacationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadVacation();
  }

  Future<void> _loadVacation() async {
    final enabled = await VacationService.isEnabled();
    if (!mounted) return;
    setState(() {
      _vacationEnabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggleVacation(bool value) async {
    await VacationService.setEnabled(value);
    if (!mounted) return;
    setState(() => _vacationEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Outpace helps you stay active with your friends.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Use vacation mode when you want to take a break without losing your status in the club context.',
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vacation / stretching mode'),
                    subtitle: const Text('Show “On stretching mode” on your leaderboard name'),
                    value: _vacationEnabled,
                    onChanged: _toggleVacation,
                  ),
                ],
              ),
      ),
    );
  }
}
