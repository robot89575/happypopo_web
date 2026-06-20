# deploy-web.ps1 — 把 Godot 导出的 web 构建同步到 happypopo_web 仓库并推送。
#
# 用法：在 Godot 里重新导出 web（输出到 happy-po-po/web）后，运行：
#   powershell -ExecutionPolicy Bypass -File S:\GodotProject\happypopo_web\deploy-web.ps1
# 或在终端里： & 'S:\GodotProject\happypopo_web\deploy-web.ps1'

$ErrorActionPreference = 'Stop'

# --- 配置 ---
$Src = 'S:\GodotProject\happy-po-po\web'      # Godot web 导出目录
$Dst = 'S:\GodotProject\happypopo_web'         # 部署仓库目录（本脚本所在目录）
$Remote = 'origin'
$Branch = 'main'

# --- 检查导出是否存在 ---
if (-not (Test-Path "$Src\web.pck")) {
    Write-Error "未在 $Src 找到 web.pck —— 请先在 Godot 里重新导出 web 构建。"
    exit 1
}

# --- 运行时文件（跳过 .import 这类编辑器缓存） ---
$files = @(
    'web.js',
    'web.wasm',
    'web.pck',
    'web.png',
    'web.icon.png',
    'web.apple-touch-icon.png',
    'web.audio.position.worklet.js',
    'web.audio.worklet.js'
)

Write-Host "从 $Src 同步到 $Dst ..." -ForegroundColor Cyan
foreach ($f in $files) {
    Copy-Item "$Src\$f" "$Dst\$f" -Force
}

# web.html 改名为 index.html，这样仓库根 URL 直接进游戏
Copy-Item "$Src\web.html" "$Dst\index.html" -Force

# .nojekyll：让 GitHub Pages 原样输出 .wasm/.pck，不走 Jekyll
if (-not (Test-Path "$Dst\.nojekyll")) {
    New-Item "$Dst\.nojekyll" -ItemType File | Out-Null
}

# --- 提交并推送 ---
git -C $Dst add -A
$status = git -C $Dst status --porcelain
if ($status) {
    $msg = 'deploy: web export ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
    git -C $Dst commit -m $msg
    git -C $Dst push $Remote $Branch
    Write-Host "已提交并推送。" -ForegroundColor Green
} else {
    Write-Host "无变更，跳过提交。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "完成。游玩地址（Pages 生效后）：https://robot89575.github.io/happypopo_web/" -ForegroundColor Green
Write-Host "提示：首次部署后若改过仓库结构，记得在 GitHub 仓库 Settings → Pages 确认 Source = main / (root)。" -ForegroundColor DarkGray
