import re

def refactor():
    with open('lib/features/parent/presentation/pages/parent_dashboard.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Imports
    content = content.replace(
        "import 'package:basera/core/resources/app_colors.dart';",
        "import 'package:basera/core/resources/color_manager.dart';\nimport 'package:basera/core/resources/styles_manager.dart';"
    )
    content = content.replace(
        "import 'package:basera/core/widgets/custom_button.dart';",
        "import 'package:basera/core/widgets/main_botton.dart';"
    )

    # isDark boolean removals
    content = re.sub(r'final isDark = Theme\.of\(context\)\.brightness == Brightness\.dark;\s*', '', content)
    content = content.replace('bool isDark,', '')
    content = content.replace('bool isDark', '')
    content = content.replace(', isDark', '')
    
    # Color replacements
    content = content.replace('isDark ? const Color(0xFF1E1E24) : Colors.white', 'ColorManager.primary')
    content = content.replace('isDark ? const Color(0xFF1E1E24) : AppColors.primary', 'ColorManager.primary')
    content = content.replace('isDark ? const Color(0xFF2D2D35) : const Color(0xFFF8FAFC)', 'ColorManager.primary')
    content = content.replace('isDark ? const Color(0xFF3D3D45) : AppColors.border', 'ColorManager.grey')
    content = content.replace('isDark ? Colors.white60 : Colors.black54', 'ColorManager.grey')
    content = content.replace('isDark ? const Color(0xFF2D2D35) : const Color(0xFFFFF7ED)', 'ColorManager.primary')
    content = content.replace('isDark ? const Color(0xFF1E1E24) : AppColors.surface', 'ColorManager.primary')
    content = content.replace('isDark ? const Color(0xFF2D2D35) : AppColors.border.withValues(alpha: 0.5)', 'ColorManager.grey')
    content = content.replace('isDark ? Colors.white70 : AppColors.textSecondary', 'ColorManager.grey')
    content = content.replace('isDark ? Colors.white : Colors.black87', 'ColorManager.white')
    content = content.replace('isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F5F9)', 'ColorManager.primary')
    content = content.replace('isDark ? Colors.white70 : Colors.black54', 'ColorManager.grey')
    content = content.replace('isDark ? Colors.white54 : AppColors.textSecondary', 'ColorManager.grey')
    content = content.replace('isDark ? Colors.white : AppColors.selectedText', 'ColorManager.white')
    content = content.replace('isDark ? const Color(0xFF2D2D35) : AppColors.backGround', 'ColorManager.primary')
    content = content.replace('isDark ? const Color(0xFF2D2D35) : AppColors.border.withValues(alpha: 0.3)', 'ColorManager.grey')

    content = content.replace('AppColors.surface', 'ColorManager.primary')
    content = content.replace('AppColors.border', 'ColorManager.grey')
    content = content.replace('AppColors.backGround', 'ColorManager.primary')
    content = content.replace('AppColors.error', 'ColorManager.error')
    content = content.replace('AppColors.textSecondary', 'ColorManager.grey')
    content = content.replace('AppColors.textDisabled', 'ColorManager.grey')
    content = content.replace('AppColors.selectedText', 'ColorManager.white')
    content = content.replace('AppColors.success', 'Colors.green')
    content = content.replace('AppColors.greenWhite', 'Colors.green.withOpacity(0.1)')
    content = content.replace('AppColors.redWhite', 'ColorManager.error.withOpacity(0.1)')
    content = content.replace('AppColors.primary', 'ColorManager.primary')

    # Fix CustomButton -> MainAppButton
    custom_btn_pattern = r'''CustomButton\(
\s*text:\s*(.*?),
\s*onPressed:\s*(.*?),
\s*isLoading:\s*(.*?),
\s*backgroundColor:\s*.*?,
\s*textColor:\s*.*?,
\s*borderRadius:\s*.*?,
\s*\)'''
    content = re.sub(custom_btn_pattern, r'MainAppButton(\n  text: \1,\n  onTap: \2 as void Function()?,\n)', content, flags=re.DOTALL)

    # Some widget styles (GoogleFonts)
    content = content.replace('GoogleFonts.outfit(fontWeight: FontWeight.bold)', 'StylesManager.lableLine().copyWith(fontWeight: FontWeight.bold, color: ColorManager.white)')
    content = content.replace('GoogleFonts.outfit(color: Colors.grey)', 'StylesManager.lableLine().copyWith(color: ColorManager.grey)')

    with open('lib/features/parent/presentation/pages/parent_dashboard.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    refactor()
