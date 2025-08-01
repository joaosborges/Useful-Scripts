# Caminho do arquivo .sql que será incluído no backup
$sqlFilePath = "C:\sqlbackup\teste.sql"

# Caminho do diretório que será incluído no backup (com tudo dentro)
$folderToBackup = "C:\appbackup\docs"

# Caminho do arquivo .zip de destino
$dataAtual = Get-Date -Format "yyyyMMdd_HHmmss"
$zipDestination = "E:\Backup\Backup_$dataAtual.zip"

# Nome do "remote" que você configurou no rclone para o Google Drive
$rcloneRemoteName = ""

# Pasta de destino no Google Drive
$gdriveDestinationFolder = ""

# Verifica se os arquivos existem antes de tentar compactar
if (-Not (Test-Path $sqlFilePath)) {
    Write-Error "Arquivo SQL não encontrado: $sqlFilePath"
    exit 1
}

if (-Not (Test-Path $folderToBackup)) {
    Write-Error "Diretório para backup não encontrado: $folderToBackup"
    exit 1
}

# Criar uma pasta temporária para agrupar os itens a serem zipados
$tempFolder = "C:\Backup\Temp_$dataAtual"
New-Item -Path $tempFolder -ItemType Directory | Out-Null

# Copia o arquivo .sql para a pasta temporária
Copy-Item -Path $sqlFilePath -Destination $tempFolder

# Copia o diretório e todo o conteúdo para a pasta temporária
Copy-Item -Path $folderToBackup -Destination $tempFolder -Recurse

# Usa o comando tar para criar o arquivo compactado
tar -a -c -f $zipDestination -C $tempFolder .

# Remove a pasta temporária após a compactação
Remove-Item -Path $tempFolder -Recurse -Force

Write-Output "Backup local concluído com sucesso em: $zipDestination"
---
### Enviando o backup para o Google Drive

try {
    # Comando rclone para copiar o arquivo para o Google Drive
    Write-Output "Iniciando o envio do backup para o Google Drive..."
    rclone copy $zipDestination "$rcloneRemoteName:$gdriveDestinationFolder"
    Write-Output "Backup enviado para o Google Drive com sucesso!"
} catch {
    Write-Error "Erro ao enviar o backup para o Google Drive: $_"
}

# Opcional: remover o arquivo de backup local após o envio bem-sucedido
# Se você quiser manter uma cópia local, comente a linha abaixo.
# Remove-Item -Path $zipDestination