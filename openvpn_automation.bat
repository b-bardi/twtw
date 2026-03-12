@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

REM ============================================================
REM  Passo 1 - Mensagem inicial
REM ============================================================
echo ============================================================
echo   Automatizacao de criacao de novos arquivos da OPENVPN
echo ============================================================
echo.

REM ============================================================
REM  Passo 2 - Solicitar nome do cliente
REM ============================================================
set /p CLIENTE="Insira o nome do cliente: "

REM ============================================================
REM  Passo 3 - Solicitar id da estacao
REM ============================================================
set /p ID_ESTACAO="Insira o id da estacao: "

REM ============================================================
REM  Passo 4 - Solicitar dominio publico do servidor
REM ============================================================
set /p DOMINIO="Insira o dominio publico do servidor: "

REM ============================================================
REM  Montar nome do certificado e destino
REM ============================================================
set "CERT_NAME=%CLIENTE%ST%ID_ESTACAO%"
set "DEST_DIR=%~dp0%CLIENTE%\%ID_ESTACAO%"

REM ============================================================
REM  Passo 5 - Alerta de repeticao de ID
REM ============================================================
if exist "%DEST_DIR%" (
    echo.
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo   AVISO: JA EXISTE UM CERTIFICADO PARA ESTE CLIENTE E ID!
    echo   Caminho: %DEST_DIR%
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo.
    set /p CONFIRM="Deseja sobrescrever e gerar um NOVO certificado? (S/N): "
    if /i "!CONFIRM!" NEQ "S" (
        echo.
        echo Operacao cancelada pelo usuario.
        pause
        exit /b
    )
)

REM ============================================================
REM  Passo 6 - Mensagem "CRIANDO PASTAS"
REM ============================================================
echo.
echo CRIANDO PASTAS

REM ============================================================
REM  Passo 7 - Criar pastas (Cliente e Estacao)
REM ============================================================
if not exist "%~dp0%CLIENTE%" (
    mkdir "%~dp0%CLIENTE%"
)

if not exist "%DEST_DIR%" (
    mkdir "%DEST_DIR%"
)

REM ============================================================
REM  Passo 8 - Mensagem "PASTAS CRIADAS COM SUCESSO"
REM ============================================================
echo PASTAS CRIADAS COM SUCESSO
echo.

REM ============================================================
REM  Passo 9 - Mensagem "AGUARDE, ARQUIVOS SENDO CRIADOS"
REM ============================================================
echo AGUARDE, ARQUIVOS SENDO CRIADOS

REM ============================================================
REM  Passo 10 - Ocultar saida dos proximos comandos
REM ============================================================

REM ============================================================
REM  Passo 11 - Acessar pasta do EasyRSA
REM ============================================================
cd /d "C:\Program Files\OpenVPN\easy-rsa"
set "PATH=%CD%\bin;%PATH%"

REM --- Limpeza de arquivos de trava (lock-files) que impedem a execucao ---
if exist "pki\.lock" del /f /q "pki\.lock" >nul 2>&1
if exist "pki\extensions.temp" del /f /q "pki\extensions.temp" >nul 2>&1

REM --- Limpeza de arquivos antigos com o mesmo nome para evitar erro de 'ja existe' ---
if exist "pki\reqs\%CERT_NAME%.req" del /f /q "pki\reqs\%CERT_NAME%.req" >nul 2>&1
if exist "pki\private\%CERT_NAME%.key" del /f /q "pki\private\%CERT_NAME%.key" >nul 2>&1
if exist "pki\issued\%CERT_NAME%.crt" del /f /q "pki\issued\%CERT_NAME%.crt" >nul 2>&1

REM ============================================================
REM  Passo 12 - Gerar requisicao do certificado (gen-req)
REM ============================================================
sh.exe easyrsa --batch --req-cn="%CERT_NAME%" gen-req %CERT_NAME% nopass

REM ============================================================
REM  Passo 13 - Assinar certificado (sign-req)
REM ============================================================
sh.exe easyrsa --batch --days=3650 sign-req client %CERT_NAME%

REM ============================================================
REM  Passo 15 - Copiar arquivo .key para pasta destino
REM ============================================================
copy /Y "C:\Program Files\OpenVPN\easy-rsa\pki\private\%CERT_NAME%.key" "%DEST_DIR%\%CERT_NAME%.key"

REM ============================================================
REM  Passo 16 - Copiar arquivo .crt para pasta destino
REM ============================================================
copy /Y "C:\Program Files\OpenVPN\easy-rsa\pki\issued\%CERT_NAME%.crt" "%DEST_DIR%\%CERT_NAME%.crt"

REM ============================================================
REM  Passo 17 - Copiar arquivo ta.key para pasta destino
REM ============================================================
copy /Y "C:\Program Files\OpenVPN\easy-rsa\keys\ta.key" "%DEST_DIR%\ta.key" >nul 2>&1

REM ============================================================
REM  Passo 18 - Copiar arquivo ca.crt para pasta destino
REM ============================================================
copy /Y "C:\Program Files\OpenVPN\easy-rsa\pki\ca.crt" "%DEST_DIR%\ca.crt" >nul 2>&1

REM ============================================================
REM  Passo 20 - Criar arquivo .ovpn
REM  Passo 21 - Inserir dominio publico do servidor
REM  Passo 22 - Embutir certificados no arquivo .ovpn
REM ============================================================

set "OVPN_FILE=%DEST_DIR%\%CERT_NAME%.ovpn"
set "CA_FILE=%DEST_DIR%\ca.crt"
set "CERT_FILE=%DEST_DIR%\%CERT_NAME%.crt"
set "KEY_FILE=%DEST_DIR%\%CERT_NAME%.key"
set "TA_FILE=%DEST_DIR%\ta.key"

REM --- Escrever cabecalho do .ovpn ---
(
    echo #
    echo # General
    echo #
    echo client
    echo persist-key
    echo persist-tun
    echo pull
    echo verb 0
    echo #
    echo # Binding
    echo #
    echo nobind
    echo #
    echo # Ciphers y Hardening
    echo #
    echo auth SHA1
    echo auth-nocache
    echo #Se agregan los dos formatos para que funcione con versiones nuevas y antiguas de OpenVPN
    echo data-ciphers AES-256-GCM:AES-256-CBC
    echo comp-lzo
    echo key-direction 1
    echo remote-cert-tls server
    echo tls-client
    echo #
    echo # Network
    echo #
    echo dev tun
    echo remote %DOMINIO% 1194
    echo resolv-retry infinite
    echo #
    echo # Certificates
    echo #
) > "%OVPN_FILE%"

REM --- Embutir ca.crt ---
echo ^<ca^>>> "%OVPN_FILE%"
type "%CA_FILE%" >> "%OVPN_FILE%"
echo ^</ca^>>> "%OVPN_FILE%"

REM --- Embutir certificado .crt (somente bloco BEGIN/END CERTIFICATE) ---
echo ^<cert^>>> "%OVPN_FILE%"
set "INSIDE_CERT=0"
for /f "usebackq delims=" %%L in ("%CERT_FILE%") do (
    if "%%L"=="-----BEGIN CERTIFICATE-----" (
        set "INSIDE_CERT=1"
    )
    if !INSIDE_CERT!==1 (
        echo %%L>> "%OVPN_FILE%"
    )
    if "%%L"=="-----END CERTIFICATE-----" (
        set "INSIDE_CERT=0"
    )
)
echo ^</cert^>>> "%OVPN_FILE%"

REM --- Embutir chave .key (somente bloco BEGIN/END PRIVATE KEY) ---
echo ^<key^>>> "%OVPN_FILE%"
set "INSIDE_KEY=0"
for /f "usebackq delims=" %%L in ("%KEY_FILE%") do (
    if "%%L"=="-----BEGIN PRIVATE KEY-----" (
        set "INSIDE_KEY=1"
    )
    if !INSIDE_KEY!==1 (
        echo %%L>> "%OVPN_FILE%"
    )
    if "%%L"=="-----END PRIVATE KEY-----" (
        set "INSIDE_KEY=0"
    )
)
echo ^</key^>>> "%OVPN_FILE%"

REM --- Embutir ta.key ---
echo ^<tls-auth^>>> "%OVPN_FILE%"
type "%TA_FILE%" >> "%OVPN_FILE%"
echo ^</tls-auth^>>> "%OVPN_FILE%"

REM ============================================================
REM  Finalizacao
REM ============================================================
echo.
echo ============================================================
echo   Processo concluido com sucesso!
echo   Arquivos gerados em: %DEST_DIR%
echo ============================================================
echo.
echo Arquivos na pasta:
dir /b "%DEST_DIR%"
echo.
pause
