<#
.SYNOPSIS
    将WAV音频文件批量转换为降噪后的MP3文件。

.DESCRIPTION
    这个脚本使用ffmpeg将指定文件夹中的所有WAV文件转换为MP4格式，并应用降噪过滤器。
    处理包括：
    - 高通滤波器 (200Hz)
    - 低通滤波器 (3000Hz)
    - FFT降噪

.PARAMETER InputFolder
    包含WAV文件的输入文件夹路径。

.PARAMETER OutputFolder
    可选的输出文件夹路径。如果不指定，将使用输入文件夹作为输出位置。

.EXAMPLE
    .\Convert-WavToMp3.ps1 -InputFolder "D:\Downloads\audio_book_output"
    将指定文件夹中的所有WAV文件转换为MP3，并保存在相同目录。

.EXAMPLE
    .\Convert-WavToMp3.ps1 -InputFolder "D:\Downloads\audio_book_output" -OutputFolder "D:\Downloads\output"
    将指定文件夹中的所有WAV文件转换为MP3，并保存在指定的输出目录。

.NOTES
    作者: Dadong
    版本: 1.0
    日期: 2024-10-27
    要求:
    - PowerShell 3.0或更高版本
    - ffmpeg已安装并添加到系统PATH中

.LINK
    https://ffmpeg.org/
#>

[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true,
        Position=0,
        HelpMessage="输入文件夹路径，包含要处理的WAV文件"
    )]
    [ValidateScript({
        if (-not (Test-Path $_)) {
            throw "输入文件夹路径不存在: $_"
        }
        return $true
    })]
    [string]$InputFolder,

    [Parameter(
        Mandatory=$false,
        Position=1,
        HelpMessage="输出文件夹路径（可选）"
    )]
    [string]$OutputFolder
)

# 检查ffmpeg是否已安装
try {
    $null = Get-Command ffmpeg -ErrorAction Stop
}
catch {
    Write-Error "未找到ffmpeg。请确保ffmpeg已安装并添加到系统PATH中。"
    exit 1
}

# 如果没有指定输出文件夹，使用输入文件夹
if (-not $OutputFolder) {
    $OutputFolder = $InputFolder
    Write-Verbose "未指定输出文件夹，使用输入文件夹: $OutputFolder"
}

# 确保输出文件夹存在
if (-not (Test-Path -Path $OutputFolder)) {
    try {
        New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
        Write-Verbose "创建输出文件夹: $OutputFolder"
    }
    catch {
        Write-Error "创建输出文件夹失败: $_"
        exit 1
    }
}

# 获取所有WAV文件
$wavFiles = Get-ChildItem -Path $InputFolder -Filter "*.wav"
$totalFiles = $wavFiles.Count

if ($totalFiles -eq 0) {
    Write-Warning "在输入文件夹中未找到WAV文件"
    exit 0
}

Write-Host "找到 $totalFiles 个WAV文件需要处理" -ForegroundColor Cyan
$processedCount = 0

foreach ($wavFile in $wavFiles) {
    $processedCount++
    $outputFile = Join-Path $OutputFolder ($wavFile.BaseName + ".mp3")

    # 构建ffmpeg命令
    $ffmpegCommand = "ffmpeg -y -i `"$($wavFile.FullName)`" -af `"highpass=200,lowpass=3000,afftdn=nf=-25`" `"$outputFile`""

    Write-Progress -Activity "转换音频文件" -Status "处理中: $($wavFile.Name)" `
                   -PercentComplete (($processedCount / $totalFiles) * 100)

    Write-Host "[$processedCount/$totalFiles] 处理: $($wavFile.Name)" -ForegroundColor Yellow

    try {
        $result = Invoke-Expression $ffmpegCommand 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "完成: $($wavFile.Name)" -ForegroundColor Green
        }
        else {
            Write-Host "处理失败: $($wavFile.Name)" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
        }
    }
    catch {
        Write-Host "错误处理 $($wavFile.Name): $_" -ForegroundColor Red
    }

    Write-Host ("-" * 50)
}

Write-Progress -Activity "转换音频文件" -Completed
Write-Host "所有文件处理完成。" -ForegroundColor Green
Write-Host "处理了 $processedCount 个文件" -ForegroundColor Green
Write-Host "输出位置: $OutputFolder" -ForegroundColor Green
