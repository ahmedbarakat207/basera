import re

def fix_parent():
    path = 'lib/features/parent/presentation/pages/parent_dashboard.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to aggressively fix the `true ? A : B` expressions because they trigger dart analyzer "dead_code" warnings.
    # We will use regex to find them. They look like `true ? const Color(...) : ColorManager.primary`
    
    # 1. Colors and Constants
    content = re.sub(r'true\s*\?\s*(const\s*Color\([^)]+\))\s*:\s*const\s*Color\([^)]+\)', 'ColorManager.primary', content)
    content = re.sub(r'true\s*\?\s*Colors\.white\s*:\s*Colors\.black87', 'ColorManager.white', content)
    content = re.sub(r'true\s*\?\s*Colors\.white70\s*:\s*Colors\.black54', 'ColorManager.grey', content)
    content = re.sub(r'true\s*\?\s*Colors\.white70\s*:\s*ColorManager\.grey', 'ColorManager.grey', content)
    content = re.sub(r'true\s*\?\s*Colors\.white\s*:\s*ColorManager\.white', 'ColorManager.white', content)
    content = re.sub(r'true\s*\?\s*(const\s*Color\([^)]+\))\s*:\s*Colors\.white', 'ColorManager.primary', content)
    content = re.sub(r'true\s*\?\s*(const\s*Color\([^)]+\))\s*:\s*ColorManager\.grey', 'ColorManager.primary', content)
    content = re.sub(r'true\s*\?\s*(const\s*Color\([^)]+\))\s*:\s*ColorManager\.primary', 'ColorManager.primary', content)
    content = re.sub(r'true\s*\?\s*ColorManager\.grey\s*:\s*ColorManager\.primary', 'ColorManager.grey', content)
    
    # Specifically for BorderSide color
    content = re.sub(r'true\s*\?\s*const Color\(0xFF2D2D35\)\s*:\s*ColorManager\.grey', 'ColorManager.primary', content)
    
    # 2. Method positional arguments
    content = re.sub(r'_buildOverviewCard\(report,\s*true\)', '_buildOverviewCard(report)', content)
    content = re.sub(r'_buildUrlCard\(url,\s*analysis,\s*isHarmful,\s*true\)', '_buildUrlCard(url, analysis, isHarmful)', content)
    content = re.sub(r'_buildAnalyticsTab\(report,\s*true\)', '_buildAnalyticsTab(report)', content)
    
    # 3. onTap logic
    content = content.replace('() => context.read<ParentBloc>().add(RunAiAnalysis(urls: allUrls)) as void Function()?,', '() { context.read<ParentBloc>().add(RunAiAnalysis(urls: allUrls)); },')
    
    # Sometimes it spans lines:
    content = re.sub(r'onTap:\s*\(isAnalyzing\s*\|\|\s*allUrls\.isEmpty\)\s*\?\s*null\s*:\s*\(\)\s*\{', 'onTap: (isAnalyzing || allUrls.isEmpty) ? () {} : () {', content)
    content = re.sub(r'onTap:\s*\(isAnalyzing\s*\|\|\s*allUrls\.isEmpty\)\s*\?\s*null\s*:\s*\(\)\s*=>\s*context\.read<ParentBloc>\(\)\.add\(RunAiAnalysis\(urls:\s*allUrls\)\)\s*as\s*void\s*Function\(\)\?,', 'onTap: (isAnalyzing || allUrls.isEmpty) ? () {} : () { context.read<ParentBloc>().add(RunAiAnalysis(urls: allUrls)); },', content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_parent()
