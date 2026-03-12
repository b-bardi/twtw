@echo off
setlocal enabledelayedexpansion

:: 1. Verificacao de Administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERRO] VOCE PRECISA EXECUTAR COMO ADMINISTRADOR.
    pause
    exit /b
)

echo ============================================================
echo   GERADOR OPENVPN - VERSAO CORRIGIDA (LOCK-FIX)
echo ============================================================

:: 2. Coleta de Dados
set /p CLIENTE="Insira o nome do cliente: "
set /p ID_ESTACAO="Insira o id da estacao: "
set /p DOMINIO="Insira o dominio publico do servidor: "

set "CERT_NAME=%CLIENTE%ST%ID_ESTACAO%"
set "DEST_DIR=%~dp0%CLIENTE%\%ID_ESTACAO%"

:: 3. Alerta de Repeticao
if exist "%DEST_DIR%" (
    echo.
    echo [!] AVISO: JA EXISTE UM CERTIFICADO PARA ESTE ID.
    set /p CONFIRM="Deseja sobrescrever? (S/N): "
    if /i "!CONFIRM!" NEQ "S" exit /b
)

:: 4. Acesso e Destravamento do Easy-RSA
set "EASYRSA_PATH=C:\Program Files\OpenVPN\easy-rsa"
cd /d "%EASYRSA_PATH%"

echo Destravando ambiente Easy-RSA... (Isso nao afeta a VPN ativa)
:: Remove apenas processos de geracao, nao o da VPN
taskkill /F /IM openssl.exe /T >nul 2>&1
taskkill /F /IM sh.exe /T >nul 2>&1

:: Remove o arquivo de trava
if exist "pki\.lock" del /f /q "pki\.lock" >nul 2>&1
if exist "pki\lock.file" del /f /q "pki\lock.file" >nul 2>&1
if exist "pki\index.txt.lock" del /f /q "pki\index.txt.lock" >nul 2>&1

:: 5. Criacao de Pastas
echo Criando pastas destino...
if not exist "%~dp0%CLIENTE%" mkdir "%~dp0%CLIENTE%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

:: 6. Limpeza de Certificados Antigos com mesmo nome
echo Preparando certificados...
del /f /q "pki\reqs\%CERT_NAME%.req" >nul 2>&1
del /f /q "pki\private\%CERT_NAME%.key" >nul 2>&1
del /f /q "pki\issued\%CERT_NAME%.crt" >nul 2>&1

:: 7. Geracao dos Certificados
set "PATH=%CD%\bin;%PATH%"
echo Gerando novos arquivos...
sh.exe easyrsa --batch --req-cn="%CERT_NAME%" gen-req %CERT_NAME% nopass
if %errorlevel% neq 0 (
    echo [ERRO] Falha na geracao. Verifique se a pasta pki esta integra.
    pause
    exit /b
)

echo Assinando certificado...
sh.exe easyrsa --batch --days=3650 sign-req client %CERT_NAME%
if %errorlevel% neq 0 (
    echo [ERRO] Falha na assinatura.
    pause
    exit /b
)

:: 8. Copia de Arquivos e Criacao OVPN
echo Finalizando arquivos...
copy /Y "pki\private\%CERT_NAME%.key" "%DEST_DIR%\" >nul
copy /Y "pki\issued\%CERT_NAME%.crt" "%DEST_DIR%\" >nul
copy /Y "keys\ta.key" "%DEST_DIR%\" >nul 2>&1
copy /Y "pki\ca.crt" "%DEST_DIR%\" >nul 2>&1

set "OVPN_FILE=%DEST_DIR%\%CERT_NAME%.ovpn"
(
    echo client
    echo dev tun
    echo proto udp
    echo remote %DOMINIO% 1194
    echo resolv-retry infinite
    echo nobind
    echo persist-key
    echo persist-tun
    echo remote-cert-tls server
    echo auth SHA1
    echo data-ciphers AES-256-GCM:AES-256-CBC
    echo comp-lzo
    echo key-direction 1
    echo verb 3
    echo.
    echo ^<ca^>
    type "%DEST_DIR%\ca.crt"
    echo ^</ca^>
    echo.
    echo ^<cert^>
    set "in_cert=0"
    for /f "usebackq delims=" %%l in ("%DEST_DIR%\%CERT_NAME%.crt") do (
        if "%%l"=="-----BEGIN CERTIFICATE-----" set "in_cert=1"
        if !in_cert!==1 echo %%l
        if "%%l"=="-----END CERTIFICATE-----" set "in_cert=0"
    )
    echo ^</cert^>
    echo.
    echo ^<key^>
    set "in_key=0"
    for /f "usebackq delims=" %%l in ("%DEST_DIR%\%CERT_NAME%.key") do (
        if "%%l"=="-----BEGIN PRIVATE KEY-----" set "in_key=1"
        if !in_key!==1 echo %%l
        if "%%l"=="-----END PRIVATE KEY-----" set "in_key=0"
    )
    echo ^</key^>
    echo.
    echo ^<tls-auth^>
    type "%DEST_DIR%\ta.key"
    echo ^</tls-auth^>
) > "%OVPN_FILE%"

echo.
echo ============================================================
echo   PROCESSO CONCLUIDO COM SUCESSO!
echo ============================================================
pause
