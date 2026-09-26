param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot
)

$ErrorActionPreference = 'Stop'

$source = (Resolve-Path -LiteralPath $SourceRoot).Path.TrimEnd('\')
$destination = Join-Path $env:USERPROFILE '.agents\skills'
New-Item -ItemType Directory -Path $destination -Force | Out-Null

function Get-LinkTarget($item) {
    $target = [string]$item.Target
    # Windows PowerShell 5 reports UNC symlink targets as "UNC\server\share".
    if ($target.StartsWith('UNC\', [StringComparison]::OrdinalIgnoreCase)) {
        return '\\' + $target.Substring(4)
    }
    return $target
}

$skills = @(Get-ChildItem -LiteralPath $source -Directory | Where-Object { $_.Name -ne 'synced' })
$names = @{}
foreach ($skill in $skills) {
    $names[$skill.Name] = $true
    $link = Join-Path $destination $skill.Name
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq 'SymbolicLink' -and (Get-LinkTarget $existing) -eq $skill.FullName) {
            continue
        }
        if ($existing.LinkType -eq 'SymbolicLink' -and (Get-LinkTarget $existing).StartsWith("$source\", [StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $link -Force
        } else {
            Write-Warning "Keeping existing skill: $link"
            continue
        }
    }
    try {
        New-Item -ItemType SymbolicLink -Path $link -Target $skill.FullName -ErrorAction Stop | Out-Null
    } catch {
        throw "Cannot link $link. Enable Windows Developer Mode or run deploy-windows-skills.ps1 from an elevated PowerShell. $($_.Exception.Message)"
    }
    Write-Output "Linked $($skill.Name)"
}

foreach ($existing in Get-ChildItem -LiteralPath $destination -Force) {
    if ($existing.LinkType -eq 'SymbolicLink' -and
        (Get-LinkTarget $existing).StartsWith("$source\", [StringComparison]::OrdinalIgnoreCase) -and
        -not $names.ContainsKey($existing.Name)) {
        Remove-Item -LiteralPath $existing.FullName -Force
        Write-Output "Removed stale skill: $($existing.Name)"
    }
}
