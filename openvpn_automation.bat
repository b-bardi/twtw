@echo off
setlocal enabledelayedexpansion

:: 1. Verificacao de Administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERRO] VOCE PRECISA EXECUTAR COMO ADMINISTRADOR.
    echo Clique com o botao direito e escolha 'Executar como administrador'.
    echo.
    pause
    exit /b
)

echo ============================================================
echo   AUTORIZACAO OPENVPN - GERADOR DE CERTIFICADOS
echo ============================================================
echo.

:: 2. Coleta de Dados
set /p CLIENTE="Insira o nome do cliente: "
set /p ID_ESTACAO="Insira o id da estacao: "
set /p DOMINIO="Insira o dominio publico do servidor: "

set "CERT_NAME=%CLIENTE%ST%ID_ESTACAO%"
set "DEST_DIR=%~dp0%CLIENTE%\%ID_ESTACAO%"

:: 3. Alerta de Repeticao
if exist "%DEST_DIR%" (
    echo.
    echo [!] AVISO: JA EXISTE UM CERTIFICADO PARA ESTE ID (%ID_ESTACAO%).
    set /p CONFIRM="Deseja sobrescrever? (S/N): "
    if /i "!CONFIRM!" NEQ "S" (
        echo Cancelado.
        pause
        exit /b
    )
)

:: 4. Criacao de Pastas
echo Criando pastas...
if not exist "%~dp0%CLIENTE%" mkdir "%~dp0%CLIENTE%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

:: 5. Acesso ao Easy-RSA
set "EASYRSA_PATH=C:\Program Files\OpenVPN\easy-rsa"
if not exist "%EASYRSA_PATH%" (
    echo [ERRO] Pasta nao encontrada: %EASYRSA_PATH%
    pause
    exit /b
)

cd /d "%EASYRSA_PATH%"
set "PATH=%CD%\bin;%PATH%"

:: 6. Limpeza de Travas (Lock-files)
if exist "pki\.lock" (
    echo Removendo trava residual (lock-file)...
    del /f /q "pki\.lock" >nul 2>&1
)

:: 7. Limpeza de Certificados Antigos com mesmo nome
echo Preparando ambiente para o novo certificado...
del /f /q "pki\reqs\%CERT_NAME%.req" >nul 2>&1
del /f /q "pki\private\%CERT_NAME%.key" >nul 2>&1
del /f /q "pki\issued\%CERT_NAME%.crt" >nul 2>&1

:: 8. Geracao dos Certificados
echo Gerando arquivos... (Aguarde)
sh.exe easyrsa --batch --req-cn="%CERT_NAME%" gen-req %CERT_NAME% nopass
if %errorlevel% neq 0 (
    echo [ERRO] Falha na geracao da requisicao.
    pause
    exit /b
)

echo Assinando certificado...
sh.exe easyrsa --batch --days=3650 sign-req client %CERT_NAME%
if %errorlevel% neq 0 (
    echo [ERRO] Falha na assinatura do certificado.
    pause
    exit /b
)

:: 9. Copia de Arquivos
echo Coletando arquivos gerados...
copy /Y "pki\private\%CERT_NAME%.key" "%DEST_DIR%\%CERT_NAME%.key" >nul
copy /Y "pki\issued\%CERT_NAME%.crt" "%DEST_DIR%\%CERT_NAME%.crt" >nul
copy /Y "keys\ta.key" "%DEST_DIR%\ta.key" >nul 2>&1
copy /Y "pki\ca.crt" "%DEST_DIR%\ca.crt" >nul 2>&1

:: 10. Criacao do .ovpn
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
echo   Local: %DEST_DIR%
echo ============================================================
echo.
pause
