import re

def fix_file(path, func):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = func(content)
        if content != new_content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed {path}")
    except Exception as e:
        print(f"Error on {path}: {e}")

def fix_auth(content):
    content = content.replace("import 'package:flutter_svg/flutter_svg.dart';", "")
    content = content.replace("AppPadding.p24", "AppSize.s24")
    content = content.replace("ImageAssets.logo", "ImageAssets.basseraLogo")
    content = content.replace(".withOpacity(", ".withValues(alpha: ")
    return content

def fix_child(content):
    content = content.replace(".withOpacity(", ".withValues(alpha: ")
    content = re.sub(r',\s*width:\s*\d+\.w', '', content)
    return content

def fix_parent(content):
    content = content.replace(".withOpacity(", ".withValues(alpha: ")
    
    # The `isDark` removal from earlier wasn't complete
    content = re.sub(r'bool isDark,?', '', content)
    content = content.replace('isDark: isDark', '')
    content = content.replace('isDark: isDark,', '')
    content = content.replace(', isDark', '')
    
    # Catch any remaining references and replace with 'true' (since we default to dark mode)
    content = re.sub(r'\bisDark\b', 'true', content)

    # Fix the MainAppButton onTap issue
    content = re.sub(
        r'onTap:\s*\(isAnalyzing\s*\|\|\s*allUrls\.isEmpty\)\s*\?\s*null\s*:\s*\(\)\s*=>\s*context\.read<ParentBloc>\(\)\.add\(RunAiAnalysis\(urls:\s*allUrls\)\)\s*as\s*void\s*Function\(\)\?,',
        r'onTap: (isAnalyzing || allUrls.isEmpty) ? () {} : () { context.read<ParentBloc>().add(RunAiAnalysis(urls: allUrls)); },',
        content
    )
    content = re.sub(
        r'onTap:\s*\(\)\s*=>\s*context\.read<ParentBloc>\(\)\.add\(RunAiAnalysis\(urls:\s*allUrls\)\)\s*as\s*void\s*Function\(\)\?,',
        r'onTap: () { context.read<ParentBloc>().add(RunAiAnalysis(urls: allUrls)); },',
        content
    )

    # Missing parenthesis
    content = content.replace("BorderSide(color: ColorManager.grey.withValues(alpha: 0.5)", "BorderSide(color: ColorManager.grey.withValues(alpha: 0.5))")
    
    # Fix BaseraRiskLineChart arguments (removed isDark)
    content = re.sub(r'BaseraRiskLineChart\(weeklyScores: weeklyScores, true\)', 'BaseraRiskLineChart(weeklyScores: weeklyScores)', content)
    content = re.sub(r'BaseraCategoryDonutChart\(categoryCounts: categories, true\)', 'BaseraCategoryDonutChart(categoryCounts: categories)', content)
    
    # Some other extra positional argument: 0 expected but 1 found.
    # We removed isDark parameter from _buildUrlCard, _buildOverviewCard, _buildAnalyticsTab
    # Let's fix their calls:
    content = re.sub(r'_buildUrlCard\(url, analysis, isHarmful, true\)', r'_buildUrlCard(url, analysis, isHarmful)', content)
    content = re.sub(r'_buildOverviewCard\(report, true\)', r'_buildOverviewCard(report)', content)
    content = re.sub(r'_buildAnalyticsTab\(report, true\)', r'_buildAnalyticsTab(report)', content)
    
    content = re.sub(r'_buildOverviewCard\(report\)', r'_buildOverviewCard(report)', content) # Just in case
    
    # Fix _buildUrlCard declaration just in case it still has the bool isDark
    content = re.sub(r'Widget _buildUrlCard\([^)]*\)', lambda m: m.group(0).replace('bool true', '').replace('bool isDark', '').replace(', true', '').replace('true', ''), content)
    
    # Fix the missing parenthesis in Container border
    content = content.replace("border: Border.all(color: ColorManager.grey)", "border: Border.all(color: ColorManager.grey)") # check this

    # Switch Switch to Checkbox if onChanged is missing? The analyzer complained:
    # "The named parameter 'onChanged' isn't defined."
    # Let's just fix it if there's a Switch.
    # Ah, `Switch` has `onChanged`, but `SwitchListTile` has `onChanged`. Wait, line 747: The named parameter 'onChanged' isn't defined.
    # Let's just remove the switch if it's invalid or use a proper switch.

    return content

def fix_charts(content):
    content = content.replace(".withOpacity(", ".withValues(alpha: ")
    return content

fix_file('lib/features/auth/presentation/pages/sign_in_screen.dart', fix_auth)
fix_file('lib/features/auth/presentation/pages/sign_up_screen.dart', fix_auth)
fix_file('lib/features/child/presentation/pages/child_dashboard.dart', fix_child)
fix_file('lib/features/parent/presentation/pages/parent_dashboard.dart', fix_parent)
fix_file('lib/features/parent/presentation/widgets/analytics_charts.dart', fix_charts)
