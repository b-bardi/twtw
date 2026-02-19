# Automatização de Criação de Arquivos OpenVPN

Script `.bat` para automatização de criação e configuração de certificados OpenVPN.

## Pré-requisitos

- OpenVPN instalado em `C:\Program Files\OpenVPN\`
- EasyRSA configurado em `C:\Program Files\OpenVPN\easy-rsa\`
- Executar o script como **Administrador**

## Como Usar

Execute o arquivo `openvpn_automation.bat` e siga as instruções na tela. O script irá solicitar:
- **Nome do cliente** (ex: `Cliente`)
- **ID da estação** (ex: `1`)
- **Domínio público do servidor** (ex: `meuservidor.com`)

## Estrutura de Saída

Após a execução, a seguinte estrutura será criada:

```
[local do .bat]/
└── Cliente/
    └── 1/
        ├── ClienteST1.key
        ├── ClienteST1.crt
        ├── ClienteST1.ovpn
        ├── ta.key
        └── ca.crt
```

## Comandos do Script (.bat)

### Passo 1 — Configurações Iniciais

```bat
@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
```

### Passo 2 — Mensagem Inicial

```bat
echo ============================================================
echo   Automatizacao de criacao de novos arquivos da OPENVPN
echo ============================================================
```

### Passo 3 — Coleta de Dados do Usuário

```bat
set /p CLIENTE="Insira o nome do cliente: "
set /p ID_ESTACAO="Insira o id da estacao: "
set /p DOMINIO="Insira o dominio publico do servidor: "
```

### Passo 4 — Montagem do Nome do Certificado

O nome do certificado é composto por: `cliente + ST + id da estação`.

```bat
set "CERT_NAME=%CLIENTE%ST%ID_ESTACAO%"
```

### Passo 5 — Criação de Pastas

```bat
echo CRIANDO PASTAS

if not exist "%~dp0%CLIENTE%" (
    mkdir "%~dp0%CLIENTE%"
)

set "DEST_DIR=%~dp0%CLIENTE%\%ID_ESTACAO%"
if not exist "%DEST_DIR%" (
    mkdir "%DEST_DIR%"
)

echo PASTAS CRIADAS COM SUCESSO
```

### Passo 6 — Geração dos Certificados (EasyRSA)

A partir deste ponto a saída é ocultada do usuário com `>nul 2>&1`.

```bat
echo AGUARDE, ARQUIVOS SENDO CRIADOS

cd /d "C:\Program Files\OpenVPN\easy-rsa"
call EasyRSA-Start.bat >nul 2>&1
```

#### Gerar requisição do certificado (gen-req)

```bat
call .\easyrsa --batch --silent --silent-ssl --req-cn="%CERT_NAME%" gen-req %CERT_NAME% nopass >nul 2>&1
```

#### Assinar certificado (sign-req)

```bat
call .\easyrsa --batch --silent --silent-ssl --days=3650 sign-req client %CERT_NAME% >nul 2>&1
```

### Passo 7 — Cópia dos Arquivos Gerados

```bat
REM Copiar .key
copy /Y "C:\Program Files\OpenVPN\easy-rsa\pki\private\%CERT_NAME%.key" "%DEST_DIR%\%CERT_NAME%.key" >nul 2>&1

REM Copiar .crt
copy /Y "C:\Program Files\OpenVPN\easy-rsa\pki\issued\%CERT_NAME%.crt" "%DEST_DIR%\%CERT_NAME%.crt" >nul 2>&1

REM Copiar ta.key
copy /Y "C:\Program Files\OpenVPN\easy-rsa\keys\ta.key" "%DEST_DIR%\ta.key" >nul 2>&1

REM Copiar ca.crt
copy /Y "C:\Program Files\OpenVPN\easy-rsa\pki\ca.crt" "%DEST_DIR%\ca.crt" >nul 2>&1
```

### Passo 8 — Criação do Arquivo .ovpn

O arquivo `.ovpn` é criado com o domínio público informado pelo usuário e com os certificados embutidos.

#### Cabeçalho do .ovpn

```bat
set "OVPN_FILE=%DEST_DIR%\%CERT_NAME%.ovpn"
set "CA_FILE=%DEST_DIR%\ca.crt"
set "CERT_FILE=%DEST_DIR%\%CERT_NAME%.crt"
set "KEY_FILE=%DEST_DIR%\%CERT_NAME%.key"
set "TA_FILE=%DEST_DIR%\ta.key"

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
```

#### Embutir certificado CA (ca.crt)

```bat
echo ^<ca^>>> "%OVPN_FILE%"
type "%CA_FILE%" >> "%OVPN_FILE%"
echo ^</ca^>>> "%OVPN_FILE%"
```

#### Embutir certificado do cliente (.crt)

Extrai somente o bloco entre `-----BEGIN CERTIFICATE-----` e `-----END CERTIFICATE-----`.

```bat
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
```

#### Embutir chave privada (.key)

Extrai somente o bloco entre `-----BEGIN PRIVATE KEY-----` e `-----END PRIVATE KEY-----`.

```bat
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
```

#### Embutir ta.key

```bat
echo ^<tls-auth^>>> "%OVPN_FILE%"
type "%TA_FILE%" >> "%OVPN_FILE%"
echo ^</tls-auth^>>> "%OVPN_FILE%"
```

### Passo 9 — Finalização

```bat
echo ============================================================
echo   Processo concluido com sucesso!
echo   Arquivos gerados em: %DEST_DIR%
echo ============================================================

dir /b "%DEST_DIR%"
pause
```