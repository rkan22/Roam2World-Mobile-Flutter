#!/bin/bash

FILE="vendor/NekokoLPA2/lib/pages/settings_page.dart"

python3 <<'PY'
from pathlib import Path

file = Path("vendor/NekokoLPA2/lib/pages/settings_page.dart")

text = file.read_text()

start = text.index("final List<Widget> allSections = [")
end = text.index("];", start) + 2

new_block = r'''final List<Widget> allSections = [
                _buildSection(
                  context,
                  title: l10n.appearance,
                  children: [
                    _buildLanguageSelector(context, width),
                    _buildThemeSwitcher(context, width),
                    _buildResponsiveTile(
                      context,
                      screenWidth: width,
                      icon: const Icon(Icons.palette_outlined),
                      title: l10n.displaySettings,
                      subtitle: l10n.appearanceSubtitle,
                      child: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DisplaySettingsPage(),
                        ),
                      ),
                    ),
                  ],
                ),

                _buildNotificationsSection(context, width),

                _buildTagsAndRemindersLink(context, width),

                _buildSection(
                  context,
                  title: l10n.about,
                  children: [
                    _buildVersionTile(context, width),
                    _buildUpdateCheckSwitcher(context, width),
                  ],
                ),
              ];'''

text = text[:start] + new_block + text[end:]

file.write_text(text)

print("Settings UI sadeleştirildi")
PY
