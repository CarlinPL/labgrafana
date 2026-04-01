# Projeto IaC com Terraform

Este repositório contém a infraestrutura como código (IaC) usando **Terraform** para provisionar recursos na nuvem.

## Objetivo

Automatizar a criação de uma infraestrutura em nuvem com Zabbix e Grafana

## Infraestrutura provisionada

- Security Groups
- Instâncias EC2

##  Tecnologias utilizadas

- Terraform
- Ansible
- AWS
- Git & GitHub
- Docker Compose

##  Pré-requisitos

Antes de começar, você precisa ter instalado:

- Terraform
- AWS CLI configurado
- Conta na AWS
- Ansible
- IDE de sua preferência

## Configuração

Configure suas credenciais AWS:

```bash
aws configure ## Ao rodar esse comando Irá pedir a chave de acesso gerada no console AWS em IAM > Credenciais de Segurança > Chaves de Acesso > Criar Chave de Acesso > Chave de Acesso secreta. Basta colar a Chave secreta e colar no terminal que seu AWS estará configurado.

```

## Usando Terraform

No terminal Dentro do Diretório terraform rodar o comando
```bash
terraform init
```
Isso faz com que o terraform inicie

Após isso vamos validar os arquivos terraform
```bash
terraform validate
```

Podemos ver o plano de execução para verificar quais mudanças serão feitas
```bash
terraform plan
```

Se não houver erros podemos partir para a ação rodando
```bash
terraform apply
```

Se tudo estiver configurado corretamente o código irá rodar sem nenhum problema e subir as instância na AWS EC2

## Usando Ansible

Após executar o código Terraform, será retornado para nós no terminal o IP Publico e IP privado da instância

Com isso precisamos ir ao código ansible e alterar o ip publico da instancia em inventory > hosts.ini
```bash
ip_publico_da_instancia ansible_user=ubuntu ansible_ssh_private_key_file=/home/user/nome_chave_ssh
```

Com isso já conseguimos rodar a parte de configuração do Ansible com o comando
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

Se tudo ocorrer como o planejado o ansible vai configurar zabbix e grafana em uma instância utilizando docker e irá configurar os hosts apontando para o ip do zabbix

## Como acessar o zabbix e o grafana

Para acessar o Zabbix basta digitar no navegador de sua preferência
```bash
http://IP_INSTANCIA_ZABBIX_SRV:8080 
```
Irá abrir uma tela pedindo o usuário e senha do zabbix, basta apenas digitar o usuário e senha setados no código que já terás acesso ao zabbix web

Para acessar o Grafana basta digitar no navegador de sua preferência 
```bash
http://IP_DA_INSTANCIA_ZABBIX_SRV:3000
```
Irá abrir a tela do Grafana pedindo usuário e senha, basta digitar as informações setadas no código.

Para aplicar o dashboard desenvolvido no grafana vamos criar uma dashboard com painel tipo texto e colar o código html dos arquivos panel1grafana.hmtl e do panel2grafana.html

Como fonte de dados é necessário configurar a api do zabbix utilizando usuário e senha de acesso ao zabbix para coleta de informações.








