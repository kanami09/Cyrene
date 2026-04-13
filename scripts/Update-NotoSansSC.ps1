param()

$ErrorActionPreference = "Stop"

# 获取最新信息
try {
    $response = (Invoke-WebRequest "https://fonts.google.com/download/list?family=Noto+Sans+SC" -ErrorAction Stop).Content
} catch {
    Write-Error "Failed to fetch font list: $_"
    exit 1
}
$json = $response -replace "^\)\]\}'\r?\n", "" | ConvertFrom-Json

# 读取当前 manifest
$manifestPath = "$PSScriptRoot\..\bucket\noto-sans-sc.json"
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

# 提取版本号
$firstUrl = $json.manifest.fileRefs[0].url
if ($firstUrl -notmatch '/v(\d+)/') {
    Write-Error 'Cannot extract version from URL'
    exit 1
}
$newVersion = $matches[1]

# 检查是否有新版本
if ($manifest.version -eq $newVersion) {
    Write-Host "Already up to date (v$newVersion)"
    exit 0
}
Write-Host "Updating v$($manifest.version) -> v$newVersion"

# 构造下载链接。只取 static/ 下的文件，跳过 Variable Font
$manifest.url = @(
    $json.manifest.fileRefs |
    Where-Object { $_.filename -like 'static/*' } |
    ForEach-Object {
        $fname = $_.filename -replace '^static/', ''
        "$($_.url)#/$fname"
    }
)

# 计算新的文件 hash
Write-Host "Computing hashes..."
$hashes = foreach ($url in ($manifest.url | ForEach-Object { ($_ -split '#')[0] })) {
    $tmp = New-TemporaryFile
    for ($i = 1; $i -le 3; $i++) {
        try {
            Invoke-WebRequest $url -OutFile $tmp -ErrorAction Stop
            break
        } catch {
            if ($i -ge 3) {
                Write-Error "Failed to download $url after 3 attempts: $_"
                exit 1
            }
            Write-Host "Attempt $i failed, retrying..."
            Start-Sleep -Seconds 2
        }
    }
    (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
    Remove-Item $tmp
}
$manifest.hash = $hashes
$manifest.version = $newVersion

# 写回 manifest 并格式化
$manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding UTF8
Write-Host "Updated to v$newVersion"
& "$PSScriptRoot\..\bin\formatjson.ps1" noto-sans-sc

# 将版本号写入环境变量以便CI使用
if ($env:GITHUB_ENV) {
    Add-Content -Path $env:GITHUB_ENV -Value "NOTO_SANS_SC_VERSION=$newVersion"
}
