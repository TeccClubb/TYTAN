// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart' show AppInfo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

class Tunneling extends StatefulWidget {
  const Tunneling({super.key});

  @override
  State<Tunneling> createState() => _TunnelingState();
}

class _TunnelingState extends State<Tunneling> {
  bool _isLoading = false;
  SharedPreferences? _prefs;
  List<String> _selectedApps = [];
  List<AppInfo> _installedApps = [];

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await loadPreferences();
    await loadInstalledApps();
  }

  Future<void> loadPreferences() async {
    if (_prefs != null) {
      setState(() {
        _selectedApps = _prefs!.getStringList('selected_apps') ?? [];
      });
    }
  }

  Future<void> savePreferences() async {
    if (_prefs != null) {
      await _prefs!.setStringList('selected_apps', _selectedApps);
    }
  }

  Future<void> loadInstalledApps() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<AppInfo> apps = await InstalledApps.getInstalledApps();
      setState(() {
        _installedApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void toggleApp(String packageName) {
    setState(() {
      if (_selectedApps.contains(packageName)) {
        _selectedApps.remove(packageName);
      } else {
        _selectedApps.add(packageName);
      }
      savePreferences();
    });
  }

  Widget _buildAppsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _installedApps.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          final app = _installedApps[index];
          final isSelected = _selectedApps.contains(app.packageName);

          return ListTile(
            leading: _buildAppIcon(app),
            title: Text(
              app.name,
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF00417B), width: 2),
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Color(0xFF00417B) : Colors.transparent,
                  ),
                ),
              ),
            ),
            onTap: () => toggleApp(app.packageName),
          );
        },
      ),
    );
  }

  Widget _buildAppIcon(AppInfo app) {
    // Try to show icon if available
    if (app.icon != null && app.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          color: Colors.grey[200],
          child: Image.memory(
            app.icon!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
            cacheWidth: 40,
            cacheHeight: 40,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialIcon(app.name);
            },
          ),
        ),
      );
    }

    // If no icon data, show app name initials
    return _buildInitialIcon(app.name);
  }

  Widget _buildInitialIcon(String appName) {
    // Get first letter of app name
    final initial = appName.isNotEmpty ? appName[0].toUpperCase() : '?';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getColorForLetter(initial),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getColorForLetter(String letter) {
    final colors = [
      const Color(0xFF00417B),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
      const Color(0xFFA8D8EA),
      const Color(0xFFAA96DA),
      const Color(0xFFFCBB4B),
    ];

    // Use first letter to pick a consistent color
    final index = letter.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  Text(
                    'Split Tunneling',
                    style: GoogleFonts.daysOne(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // placeholder
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: Color(0xFF00417B),
                    ), // Blue switch),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Do not allow selected apps to use VPN',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Icon(
                        Icons.lock,
                        color: Color(0xFF00417B),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : _buildAppsList(),
          ],
        ),
      ),
    );
  }
}
