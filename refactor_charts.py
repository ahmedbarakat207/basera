import re

def refactor():
    with open('lib/features/parent/presentation/widgets/analytics_charts.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Imports
    content = content.replace(
        "import 'package:google_fonts/google_fonts.dart';",
        "import 'package:basera/core/resources/color_manager.dart';\nimport 'package:basera/core/resources/styles_manager.dart';"
    )

    # isDark boolean removals
    content = re.sub(r'final bool isDark;\s*', '', content)
    content = re.sub(r'this\.isDark = false,\s*', '', content)
    content = re.sub(r'required this\.isDark\s*', '', content)
    content = content.replace('isDark: isDark,', '')
    content = content.replace('isDark: isDark', '')
    
    # Color replacements
    content = content.replace('isDark ? const Color(0xFF1E1E24) : Colors.white', 'ColorManager.primary')
    content = content.replace('isDark ? const Color(0xFF2D2D35) : const Color(0xFFE2E8F0)', 'ColorManager.grey')
    content = content.replace('isDark ? Colors.white70 : Colors.black54', 'ColorManager.grey')
    content = content.replace('isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)', 'ColorManager.white.withOpacity(0.05)')
    content = content.replace('isDark ? Colors.white70 : Colors.black87', 'ColorManager.grey')
    content = content.replace('Colors.white', 'ColorManager.primary') # specifically for the inner donut hole

    # Typography replacements
    content = re.sub(
        r'GoogleFonts\.outfit\([\s\n]*fontSize:\s*14\.sp,[\s\n]*fontWeight:\s*FontWeight\.bold,[\s\n]*color:\s*ColorManager\.grey,[\s\n]*\)',
        r'StylesManager.lableLine().copyWith(color: ColorManager.grey)',
        content
    )
    content = re.sub(
        r'GoogleFonts\.outfit\([\s\n]*fontSize:\s*12\.sp,[\s\n]*color:\s*ColorManager\.grey,[\s\n]*fontWeight:\s*FontWeight\.w500,[\s\n]*\)',
        r'StylesManager.litlleHintLine().copyWith(color: ColorManager.grey)',
        content
    )
    content = re.sub(
        r'GoogleFonts\.outfit\([\s\n]*color:\s*Colors\.grey,[\s\n]*fontSize:\s*13\.sp,[\s\n]*\)',
        r'StylesManager.litlleHintLine().copyWith(color: ColorManager.grey)',
        content
    )

    with open('lib/features/parent/presentation/widgets/analytics_charts.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    refactor()
