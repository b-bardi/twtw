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

