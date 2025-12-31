# Salt Stack - Monitoring States

Repositório de estados Salt para configuração automatizada de agentes de monitoramento em Windows.

## O que é Salt Stack?

Salt é uma ferramenta de automação e gerenciamento de configuração baseada em Python. Utiliza o modelo **master-minion** para gerenciar infraestrutura de forma centralizada.

## Arquitetura

```
                    ┌─────────────────────────────────────┐
                    │           SALT MASTER               │
                    │  - Armazena estados (SLS)           │
                    │  - Distribui configurações          │
                    │  - Gerencia chaves PKI              │
                    └──────────────┬──────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │ ZeroMQ (4505/4506) │                    │
              ▼                    ▼                    ▼
     ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
     │ SALT MINION │      │ SALT MINION │      │ SALT MINION │
     │  (windows)  │      │   (linux)   │      │   (linux)   │
     └─────────────┘      └─────────────┘      └─────────────┘
```

### Componentes

| Componente | Descrição |
|------------|-----------|
| **Salt Master** | Servidor central que armazena estados e distribui configurações |
| **Salt Minion** | Agente instalado em cada host gerenciado |
| **States (SLS)** | Arquivos YAML que descrevem o estado desejado do sistema |
| **Pillars** | Dados sensíveis/variáveis específicas por minion |
| **Grains** | Informações estáticas coletadas do minion (OS, IP, etc.) |

## Como Funciona

### 1. Comunicação Master-Minion

O Salt usa **ZeroMQ** para comunicação assíncrona de alta performance:

- **Porta 4505**: Publisher - Master envia comandos para minions
- **Porta 4506**: Returner - Minions retornam resultados para o Master

### 2. Autenticação PKI

Cada minion possui um par de chaves RSA. O fluxo de autenticação:

```
1. Minion gera par de chaves
2. Minion envia chave pública ao Master
3. Administrador aceita a chave (salt-key -a)
4. Comunicação passa a ser criptografada
```

### 3. Targeting (Seleção de Minions)

O Salt permite selecionar minions de várias formas:

```bash
# Por nome (glob)
salt 'web*' test.ping

# Por grain (característica do sistema)
salt -G 'os:Windows' test.ping

# Por expressão composta
salt -C 'G@os:Linux and web*' test.ping

# Por lista
salt -L 'minion1,minion2,minion3' test.ping
```

### 4. Estados (State System)

Estados são declarações **idempotentes** do que você quer que o sistema seja:

```yaml
# Exemplo: garantir que nginx está instalado e rodando
nginx_installed:
  pkg.installed:
    - name: nginx

nginx_running:
  service.running:
    - name: nginx
    - enable: True
    - require:
      - pkg: nginx_installed
```

**Idempotência**: Executar o mesmo estado múltiplas vezes sempre resulta no mesmo estado final, sem efeitos colaterais.

### 5. Top File (Mapeamento)

O arquivo `top.sls` mapeia quais estados aplicar em quais minions:

```yaml
base:
  'web*':
    - nginx
    - security
  'db*':
    - postgresql
  '*':
    - common
```

### 6. Execução de Estados

```bash
# Aplicar todos os estados mapeados no top.sls
salt '*' state.apply

# Aplicar estado específico
salt 'web*' state.apply nginx

# Dry-run (ver o que seria alterado)
salt '*' state.apply test=True

# Ver highstate (estados que seriam aplicados)
salt '*' state.show_top
```

## Estrutura do Repositório

```
salt-stack/
├── README.md
└── salt/
    ├── top.sls              # Mapeamento de estados por minion
    └── monitoring/
        ├── init.sls         # Estado principal de monitoramento
        ├── blackbox.yml     # Config do Blackbox Exporter
        └── vmagent.yml      # Config do VictoriaMetrics Agent
```

## Comandos Úteis

### Gerenciamento de Chaves

```bash
salt-key -L              # Listar todas as chaves
salt-key -a <minion>     # Aceitar minion
salt-key -d <minion>     # Remover minion
salt-key -A              # Aceitar todos pendentes
```

### Execução Remota

```bash
salt '*' test.ping                    # Testar conectividade
salt '*' cmd.run 'hostname'           # Executar comando
salt '*' grains.items                 # Ver grains do minion
salt '*' pillar.items                 # Ver pillars do minion
salt '*' sys.doc pkg.installed        # Ver documentação
```

### Estados

```bash
salt '*' state.apply                  # Aplicar highstate
salt '*' state.apply monitoring       # Aplicar estado específico
salt '*' state.single pkg.installed vim  # Estado único ad-hoc
```

## Stack de Monitoramento

Este repositório configura o seguinte stack nos minions Windows:

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  Blackbox       │────▶│  VictoriaMetrics     │────▶│  VictoriaMetrics│
│  Exporter       │     │  Agent (vmagent)     │     │  Server         │
│  (ICMP probes)  │     │  (scrape + forward)  │     │  (storage)      │
└─────────────────┘     └──────────────────────┘     └─────────────────┘
     :9115                                               :8431
```

## Referências

- [Salt Documentation](https://docs.saltproject.io/)
- [Salt States Tutorial](https://docs.saltproject.io/en/latest/topics/tutorials/starting_states.html)
- [Salt Best Practices](https://docs.saltproject.io/en/latest/topics/best_practices.html)
