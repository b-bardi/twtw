Arquivo no formato .bat para automatização de criação de novos arquivos da OPENVPN.

O arquivo deve seguir os passos abaixo.

1 - Ao Iniciar o arquivo .bat, ele deve apresentar na tela a mensagem "Automatização de criação de novos arquivos da OPENVPN"

2 - Solicitar ao usuario que insira o nome do cliente, ex: "Cliente" e guardar essa informação em uma variavel.

3 - Solicitar ao usuario que insira o id da estação, ex: "1" e guardar essa informação em uma variavel.

4 - Solicitar ao usuario que insira o dominio publico do servidor e guardar essa informação em uma variavel.

5 - Deve apresentar na tela a mensagem "CRIANDO PASTAS"

6 - Deve criar uma pasta no mesmo local de execução do .bat com o nome do cliente.

7 - Deve criar uma pasta dentro da pasta do cliente com o nome do id da estação.

8 - Deve apresentar na tela a mensagem "PASTAS CRIADAS COM SUCESSO"

9 - Deve apresentar na tela "AGUARDE, ARQUIVOS SENDO CRIADOS".

10 - As proximas etapas não devem ser mostradas para o usuario.

11 - Execute o comando cd C:\Program Files\OpenVPN\easy-rsa\
EasyRSA-Start.bat

12 - Execute o comando ./easyrsa --batch --silent --silent-ssl --req-cn="Nombre del Certificado" gen-req Nombre del Certificado nopass onde o "Nombre del Certificado" será a variavel do nome do cliente + ST + id da estação. Neste comando onde tiver "" deve ser mantido

13 - Execute o comando ./easyrsa --batch --silent --silent-ssl --days=3650 sign-req client Nombre del Certificado onde o Nombre del Certificado será a variavel do nome do cliente + ST + id da estação.

14 - As proximas etapas será pegar os arquivos criados com o comando 11 e 12.

15 - Acesse a pasta C:\Program Files\OpenVPN\easy-rsa\pki\private e copie o arquivo que tem o nome do cliente + ST + id da estação com a extensão .key e cole na pasta do cliente + id da estação.

16 - Acesse a pasta C:\Program Files\OpenVPN\easy-rsa\pki\issued e copie o arquivo que tem o nome do cliente + ST + id da estação com a extensão .crt e cole na pasta do cliente + id da estação.

17 - Acesse a pasta C:\Program Files\OpenVPN\easy-rsa\keys e copie o arquivo ta.key e cole na pasta do cliente + id da estação. 

18 - Acesse a pasta C:\Program Files\OpenVPN\easy-rsa\pki e copei o arquivo ca.crt e cole na pasta do cliente + id da estação. 

19 -Dentro da pasta do cliente + id da estação deve ter os arquivos: 
- cliente + ST + id da estação.key
- cliente + ST + id da estação.crt
- ta.key
- ca.crt

20 - Crie um arquivo .ovpn dentro da pasta do cliente + id da estação com o nome do cliente + ST + id da estação.ovpn e cole o conteudo abaixo:

#
# General
#
client
persist-key
persist-tun
pull
verb 0
#
# Binding
#
nobind
#
# Ciphers y Hardening
#
auth SHA1
auth-nocache
#Se agregan los dos formatos para que funcione con versiones nuevas y antiguas de OpenVPN
data-ciphers AES-256-GCM:AES-256-CBC 
comp-lzo
key-direction 1
remote-cert-tls server
tls-client
#
# Network
#
dev tun
remote Centinela.orpak-la.com 1194
resolv-retry infinite
#
# Certificates
#
<ca>
Pegar el Certificado CA.crt del Servidor
</ca>
<cert>
Pegar el Certificado Centinela_JP_V3.2.2.crt del Certificado creado
</cert>
<key>
Pegar el Certificado Centinela_JP_V3.2.2.key del Certificado creado
</key>
<tls-auth>
Pegar el Certificado TA.Key del Servidor
</tls-auth>

21 - Altere o conteudo da linha 28 do arquivo ovpn para que ele receba o dominio publico do servidor, deve trocar o parametro Centinela.orpak-la.com pelo dominio publico do servidor. 

22 - As proximas etapas serão a edição dos certificados dentro do arquivo ovpn, deve trocar o conteudo entre as tags <ca>, <cert>, <key> e <tls-auth> pelos certificados criados. Na tag <ca> deve ser colado o conteudo do arquivo ca.crt, na tag <cert> deve ser colado o conteudo entre -----BEGIN CERTIFICATE----- e -----END CERTIFICATE----- do arquivo cliente + ST + id da estação.crt, na tag <key> deve ser colado o conteudo entre -----BEGIN PRIVATE KEY----- e -----END PRIVATE KEY----- do arquivo cliente + ST + id da estação.key e na tag <tls-auth> deve ser colado o conteudo do arquivo ta.key.  