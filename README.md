# labgrafana

Laboratório de monitoramento de infraestrutura com **Zabbix + Grafana**, totalmente provisionado como código na AWS.

O projeto combina **Terraform** (provisionamento da infraestrutura), **Ansible** (configuração dos servidores) e **GitHub Actions** (pipelines de CI/CD) para subir, do zero, um ambiente de monitoramento pronto para uso: um servidor Zabbix + Grafana rodando em containers Docker e uma ou mais instâncias monitoradas via Zabbix Agent.

## Sumário

- [Visão geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Pré-requisitos](#pré-requisitos)
- [Como usar](#como-usar)
  - [1. Configurar credenciais AWS](#1-configurar-credenciais-aws)
  - [2. Provisionar a infraestrutura com Terraform](#2-provisionar-a-infraestrutura-com-terraform)
  - [3. Configurar os servidores com Ansible](#3-configurar-os-servidores-com-ansible)
  - [4. Acessar Zabbix e Grafana](#4-acessar-zabbix-e-grafana)
  - [5. Importar os dashboards do Grafana](#5-importar-os-dashboards-do-grafana)
- [CI/CD com GitHub Actions](#cicd-com-github-actions)
- [Destruindo o ambiente](#destruindo-o-ambiente)
- [Avisos de segurança](#avisos-de-segurança)

## Visão geral

O objetivo do laboratório é automatizar, de ponta a ponta, a criação de um ambiente de observabilidade:

1. O **Terraform** cria na AWS as instâncias EC2 (um servidor Zabbix/Grafana e N hosts a serem monitorados), o Security Group com as portas necessárias e IPs elásticos.
2. O **Ansible** entra em ação logo depois, usando o **inventário dinâmico da AWS** (`aws_ec2.yml`) para descobrir automaticamente as instâncias recém-criadas, e:
   - instala Docker no servidor e sobe a stack (Zabbix Server, banco Postgres, Zabbix Web e Grafana) via Docker Compose;
   - instala o Zabbix Agent 2 nos demais hosts, apontando para o IP do servidor Zabbix.
3. Os **workflows do GitHub Actions** permitem rodar todo esse processo (`terraform plan/apply` e o `playbook` do Ansible) direto pelo GitHub, autenticando na AWS via OIDC (sem chaves fixas salvas no repositório).
4. Os arquivos em `paineis_grafana/` trazem dashboards prontos (em HTML) para colar em painéis do tipo texto no Grafana.

## Arquitetura

```
                 ┌───────────────────────────┐
                 │        Terraform          │
                 │  (EC2, Security Group,    │
                 │   Elastic IP, backend S3) │
                 └─────────────┬─────────────┘
                                │ provisiona
                                ▼
        ┌────────────────────────────────────────────┐
        │                  AWS (sa-east-1)            │
        │                                              │
        │  ┌────────────────────┐   ┌────────────────┐ │
        │  │  zabbix_server     │   │ zabbix_agent(s)│ │
        │  │  - Docker          │   │  - Zabbix       │ │
        │  │  - zabbix-db (PG)  │   │    Agent 2      │ │
        │  │  - zabbix-server   │◄──┤  reporta para   │ │
        │  │  - zabbix-web:8080 │   │  o server       │ │
        │  │  - grafana:3000    │   └────────────────┘ │
        │  └────────────────────┘                      │
        └────────────────────────────────────────────┘
                                ▲
                                │ configura via SSH
                                │ (inventário dinâmico aws_ec2)
                 ┌──────────────┴─────────────┐
                 │           Ansible          │
                 │  roles: monitoring,        │
                 │         zabbix-agent       │
                 └─────────────────────────────┘
```

## Estrutura do repositório

```
labgrafana/
├── terraform/                  # Infraestrutura como código (AWS)
│   ├── main.tf                 # Configuração do provider Terraform/AWS
│   ├── provider.tf             # Região AWS (sa-east-1)
│   ├── backend.tf              # State remoto em bucket S3 (com lock)
│   ├── ec2.tf                  # Instância do servidor Zabbix + hosts monitorados
│   ├── security_group.tf       # Portas liberadas (SSH, Grafana, Zabbix, SNMP, ICMP)
│   ├── elastic_ip.tf           # IPs elásticos para o servidor e para os hosts
│   ├── variables.tf            # Variáveis (tipo de instância, key pair, quantidade de hosts)
│   └── outputs.tf              # IP público e URLs de acesso ao Grafana/Zabbix
│
├── ansible/                    # Configuração automatizada dos servidores
│   ├── ansible.cfg              # Habilita o plugin de inventário dinâmico da AWS
│   ├── playbook.yml             # Playbook principal (roles por grupo de host)
│   ├── inventory/
│   │   └── aws_ec2.yml          # Inventário dinâmico (agrupa instâncias pela tag "role")
│   └── roles/
│       ├── monitoring/          # Instala Docker e sobe Zabbix + Grafana (docker-compose)
│       └── zabbix-agent/        # Instala e configura o Zabbix Agent 2 nos hosts monitorados
│
├── paineis_grafana/             # Dashboards prontos em HTML para o Grafana
│   ├── panel1grafana.html
│   └── panel2grafana.html
│
└── .github/workflows/           # Pipelines de CI/CD
    ├── terraform.yaml           # Executa terraform init/validate/plan/apply
    └── ansible.yaml             # Executa o playbook do Ansible contra a infra criada
```

## Pré-requisitos

Antes de começar, você precisa ter:

- Conta na AWS com permissão para criar EC2, Security Group, Elastic IP e um bucket S3 (para o state do Terraform)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.3.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/) configurado
- [Ansible](https://docs.ansible.com/) instalado, com a collection `amazon.aws`:
  ```bash
  ansible-galaxy collection install amazon.aws
  pip install boto3 botocore
  ```
- Um **key pair** (`.pem`) já criado na AWS na região `sa-east-1`, para acesso SSH às instâncias
- Um bucket S3 chamado `labgrafana` (ou ajuste o nome em `terraform/backend.tf`) para armazenar o state remoto do Terraform

## Como usar

### 1. Configurar credenciais AWS

```bash
aws configure
```

O comando pedirá a **Access Key** e a **Secret Key**, geradas no console AWS em *IAM > Credenciais de Segurança > Chaves de Acesso > Criar Chave de Acesso*.

### 2. Provisionar a infraestrutura com Terraform

Dentro do diretório `terraform/`:

```bash
cd terraform
terraform init      # inicializa o backend e baixa os providers
terraform validate  # valida a sintaxe dos arquivos
terraform plan       # mostra o que será criado/alterado
terraform apply      # cria os recursos na AWS
```

Se tudo estiver configurado corretamente, o Terraform irá criar:

- 1 instância EC2 para o servidor Zabbix/Grafana
- N instâncias EC2 para os hosts monitorados (`var.instance_count`, padrão 4)
- Um Security Group liberando SSH (22), Grafana (3000), Zabbix Web (8080), Zabbix Agent (10050/10051), SNMP (161) e ICMP
- IPs elásticos para todas as instâncias

Ao final, o Terraform mostra no terminal o IP público do servidor Zabbix (saída `public_ip`) e as URLs prontas de acesso (`grafana_url`, `zabbix_url`).

### 3. Configurar os servidores com Ansible

O inventário **não é estático** — ele é gerado dinamicamente a partir da AWS, agrupando as instâncias pela tag `role` (`zabbix_server` ou `zabbix_agent`) definida no Terraform. Não é necessário editar nenhum arquivo de hosts manualmente.

Dentro do diretório `ansible/`, ajuste apenas o caminho da sua chave `.pem` em `inventory/aws_ec2.yml` (campo `ansible_ssh_private_key_file`) e rode:

```bash
cd ansible
ansible-playbook -i inventory/aws_ec2.yml playbook.yml
```

O playbook executa duas roles:

- **`monitoring`** (no host com a tag `zabbix_server`): instala Docker/Docker Compose e sobe a stack completa (Postgres, Zabbix Server, Zabbix Web, Grafana) definida em `roles/monitoring/files/docker-compose.yml`.
- **`zabbix-agent`** (nos demais hosts, com a tag `zabbix_agent`): instala o Zabbix Agent 2 e o configura para reportar ao IP do servidor Zabbix.

> **Nota:** a variável `zabbix_server_ip` usada no template do agente precisa apontar para o IP do servidor Zabbix criado pelo Terraform — no pipeline de CI/CD isso já é tratado automaticamente pelo inventário dinâmico.

### 4. Acessar Zabbix e Grafana

Com o IP público do servidor em mãos (saída do Terraform):

- **Zabbix Web:** `http://IP_DA_INSTANCIA:8080`
- **Grafana:** `http://IP_DA_INSTANCIA:3000` (usuário `admin`, senha padrão definida em `GF_SECURITY_ADMIN_PASSWORD` no `docker-compose.yml`)

### 5. Importar os dashboards do Grafana

O Grafana já sobe com o plugin **Zabbix App** instalado (`alexanderzobnin-zabbix-app`). Para usar os painéis prontos:

1. Configure uma *data source* do tipo Zabbix apontando para a API do Zabbix Web, usando um usuário/senha com acesso à API.
2. Crie um dashboard novo com um painel do tipo **Texto (HTML)**.
3. Cole o conteúdo de `paineis_grafana/panel1grafana.html` ou `panel2grafana.html` no painel.

## CI/CD com GitHub Actions

O repositório já vem com dois workflows manuais (`workflow_dispatch`), em `.github/workflows/`:

- **`terraform.yaml`** — roda `terraform init/validate/plan` e, opcionalmente, `apply` (via input `apply: true/false`).
- **`ansible.yaml`** — instala Ansible + collection `amazon.aws`, recria a chave SSH a partir do secret `EC2_SSH_PRIVATE_KEY`, testa a conectividade (`ansible all -m ping`) e roda o playbook contra o inventário dinâmico da AWS.

Ambos autenticam na AWS via **OIDC**, assumindo uma IAM Role (`role-to-assume`) — não há credenciais fixas salvas no repositório. Para usar os workflows no seu próprio fork/conta, você precisa:

1. Criar uma IAM Role configurada para *trust* do GitHub Actions (OIDC) e ajustar o ARN em ambos os arquivos de workflow.
2. Cadastrar o secret `EC2_SSH_PRIVATE_KEY` no repositório, com o conteúdo da chave `.pem` usada nas instâncias.

## Destruindo o ambiente

Para evitar custos na AWS, quando terminar os testes:

```bash
cd terraform
terraform destroy
```

## Avisos de segurança

Este é um **laboratório de estudos**, não um ambiente de produção. Vale destacar:

- O Security Group libera as portas de acesso (SSH, Grafana, Zabbix, SNMP, ICMP) para `0.0.0.0/0` — em um ambiente real, restrinja os `cidr_blocks` ao seu IP ou a uma VPN.
- As senhas do Postgres e do Grafana estão fixas em texto plano no `docker-compose.yml` (`zabbix_pass`, `admin123`) — troque-as antes de qualquer uso além de testes locais.