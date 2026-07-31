$ErrorActionPreference = 'Stop'
$port = 8000
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-ContentType([string]$path) {
    switch ([System.IO.Path]::GetExtension($path).ToLowerInvariant()) {
        '.html' { 'text/html; charset=utf-8' }
        '.htm'  { 'text/html; charset=utf-8' }
        '.js'   { 'application/javascript; charset=utf-8' }
        '.css'  { 'text/css; charset=utf-8' }
        '.json' { 'application/json; charset=utf-8' }
        '.png'  { 'image/png' }
        '.jpg'  { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.gif'  { 'image/gif' }
        '.svg'  { 'image/svg+xml' }
        '.webp' { 'image/webp' }
        '.ico'  { 'image/x-icon' }
        '.pdf'  { 'application/pdf' }
        '.mp3'  { 'audio/mpeg' }
        '.wav'  { 'audio/wav' }
        default { 'application/octet-stream' }
    }
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
} catch {
    Write-Host "Nao foi possivel iniciar o servidor na porta $port." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Read-Host "Pressione Enter para fechar"
    exit 1
}

Write-Host "Servidor do Jardim da Rotina iniciado." -ForegroundColor Green
Write-Host "Pasta: $root"
Write-Host "Endereco: http://localhost:$port/index.html"
Write-Host "Mantenha esta janela aberta enquanto usar o app." -ForegroundColor Yellow
Write-Host "Para encerrar, pressione Ctrl+C."

Start-Process "http://localhost:$port/index.html"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $relative = [System.Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
            if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }

            $requested = Join-Path $root ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            $fullPath = [System.IO.Path]::GetFullPath($requested)
            $rootFull = [System.IO.Path]::GetFullPath($root)

            if (-not $fullPath.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                $context.Response.StatusCode = 403
                $bytes = [System.Text.Encoding]::UTF8.GetBytes('Acesso negado.')
            }
            elseif (Test-Path $fullPath -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($fullPath)
                $context.Response.StatusCode = 200
                $context.Response.ContentType = Get-ContentType $fullPath
            }
            else {
                $context.Response.StatusCode = 404
                $bytes = [System.Text.Encoding]::UTF8.GetBytes('Arquivo nao encontrado.')
                $context.Response.ContentType = 'text/plain; charset=utf-8'
            }

            $context.Response.ContentLength64 = $bytes.Length
            $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        catch {
            $context.Response.StatusCode = 500
            $bytes = [System.Text.Encoding]::UTF8.GetBytes('Erro interno do servidor.')
            $context.Response.ContentLength64 = $bytes.Length
            $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        finally {
            $context.Response.OutputStream.Close()
        }
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
