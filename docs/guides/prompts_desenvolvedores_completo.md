Modelos de Prompt para Ollama e Open WebUI (Desenvolvedores)
🔍 1. Análise de Repositórios GitHub
Exemplo 1 – Análise geral
Você é um especialista em arquitetura de software. Analise o repositório a seguir:
[cole aqui a URL do repositório do GitHub]

1. Identifique as principais tecnologias usadas.
2. Explique a estrutura do projeto e sua lógica principal.
3. Liste pontos fortes e fracos da implementação.
4. Sugira melhorias em arquitetura, organização de código e boas práticas.
5. Dê exemplos de como implementar as melhorias sugeridas.

Exemplo 2 – Comparação de projetos
Analise e compare os dois repositórios abaixo:
[repo 1]
[repo 2]

- Quais são as diferenças na arquitetura, qualidade do código e organização?
- Qual parece mais escalável e fácil de manter?
- Sugira como unir o melhor dos dois em um novo projeto.

💻 2. Projetos Locais
Exemplo 3 – Análise de projeto local
Sou desenvolvedor e tenho este projeto local (arquivo ou código colado abaixo).
Analise:

- Estrutura de pastas e organização
- Qualidade do código (clareza, legibilidade, modularidade)
- Possíveis problemas de segurança ou performance
- Sugestões para melhorar manutenibilidade e escalabilidade

🛠 3. Melhoria de Código
Exemplo 4 – Refatoração
Refatore o seguinte código para deixá-lo mais limpo, eficiente e legível:

[código aqui]

Explique:
- Quais problemas existiam
- Como corrigiu
- Por que a nova versão é melhor

Exemplo 5 – Adicionar testes
Crie testes unitários para o código abaixo usando pytest:

[código aqui]

- Explique os casos de teste escolhidos
- Sugira como aumentar a cobertura de testes no projeto

📚 4. Documentação
Exemplo 6 – Gerar README
Com base no seguinte código/projeto, crie um README.md profissional contendo:

- Nome do projeto
- Descrição
- Tecnologias utilizadas
- Como instalar e rodar
- Exemplos de uso
- Próximos passos/sugestões de evolução

Exemplo 7 – Documentação de API
Analise este projeto FastAPI e gere a documentação da API em formato Markdown, incluindo:

- Endpoints disponíveis
- Métodos suportados
- Estrutura de request e response
- Exemplos de uso em curl

🔒 5. Segurança
Exemplo 8 – Análise de vulnerabilidades
Analise este código/projeto e identifique possíveis vulnerabilidades:

[código aqui]

- Riscos de injeção SQL, XSS, CSRF ou outros
- Má gestão de autenticação/autorização
- Boas práticas de segurança ausentes
- Sugira correções práticas

⚡ 6. Performance e Escalabilidade
Exemplo 9 – Otimização
Analise o seguinte código:

[código aqui]

- Identifique gargalos de performance
- Sugira melhorias de algoritmos ou estruturas de dados
- Se possível, reescreva a versão otimizada

🤖 7. Prompts Avançados para Projetos
Exemplo 10 – Planejamento de features
Tenho este projeto em andamento: [descrição].  
Preciso de ajuda para:

1. Mapear novas features possíveis
2. Definir roadmap de evolução
3. Estruturar um backlog inicial (com histórias de usuário)

Exemplo 11 – Integração com IA
Tenho este projeto [descrição/código].  
Explique como posso integrar funcionalidades de IA (exemplo: NLP, recomendação, classificação).  
Liste bibliotecas recomendadas em Python e dê exemplos de implementação.

✅ Sugestões de Uso no Ollama/Open WebUI

Copiar/colar direto no chat

Criar uma coleção de prompts pré-salvos no Open WebUI (fica rápido para reutilizar)

Adaptar os blocos [código aqui] / [repo aqui] para o seu caso específico

👉 Quer que eu organize esses prompts em um arquivo .md pronto para importar no Open WebUI (tipo uma "biblioteca de prompts de desenvolvedor")?

Você disse:
crie mais exemplos, outros prompts uteis, etc
O ChatGPT disse:

Perfeito 🙌
Vou expandir bastante a lista de prompts úteis para desenvolvedores no Ollama / Open WebUI, cobrindo diversos cenários reais: análise, refatoração, arquitetura, documentação, DevOps, CI/CD, bancos de dados, APIs, cloud, boas práticas, etc.

📘 Biblioteca de Prompts para Desenvolvedores (Ollama & Open WebUI)
🔍 1. Análise e Revisão de Código
Prompt – Code Review Detalhado
Faça um code review do seguinte trecho de código:

[código aqui]

- Liste problemas de clareza, manutenção e estilo
- Aponte possíveis bugs ou edge cases
- Sugira melhorias
- Explique como deixá-lo aderente ao PEP8 (se Python) ou padrões recomendados

Prompt – Comparar Implementações
Compare as duas versões de código abaixo:

[código versão A]
[código versão B]

- Qual é mais eficiente?
- Qual é mais legível?
- Qual é mais fácil de manter?
- Qual você recomenda e por quê?

🛠 2. Refatoração e Melhoria
Prompt – Modularização
Transforme o seguinte código monolítico em uma versão modular, separando em funções e/ou classes, e explique os benefícios dessa abordagem:

[código aqui]

Prompt – Padrões de Projeto
Reescreva este código aplicando um padrão de projeto adequado (ex: Strategy, Factory, Observer):

[código aqui]

Explique:
- Qual padrão escolheu
- Por que ele melhora o código
- Como aplicar esse padrão em outros pontos do projeto

📚 3. Documentação
Prompt – Documentar Funções
Adicione docstrings ao seguinte código, no estilo Google ou NumPy:

[código aqui]

Prompt – Gerar Changelog
Gere um changelog organizado com base nessas mudanças de código:

[lista de commits ou diffs]

🔒 4. Segurança
Prompt – Revisão de Segurança
Analise este código e identifique riscos de segurança:

[código aqui]

- Validação de entradas
- Gerenciamento de sessão e autenticação
- Uso de bibliotecas desatualizadas
- Boas práticas ausentes

Prompt – Compliance
Verifique se este projeto segue boas práticas de privacidade e LGPD/GDPR:

[descrição do projeto ou código]

⚡ 5. Performance
Prompt – Perf Tuning
Identifique gargalos de performance neste código:

[código aqui]

- Sugira melhorias em algoritmos
- Substitua loops ineficientes por soluções mais rápidas
- Explique o impacto estimado da melhoria

Prompt – Escalabilidade
Analise esta API:

[código aqui]

Sugira como escalá-la para suportar milhões de requisições:
- Estratégias de cache
- Load balancing
- Uso de filas (RabbitMQ, Kafka)
- Melhorias de banco de dados

🚀 6. DevOps e Infraestrutura
Prompt – Dockerfile
Crie um Dockerfile otimizado para este projeto:

[estrutura ou código do projeto]

Prompt – CI/CD
Crie um pipeline de CI/CD (GitHub Actions) para este projeto que:
- Rode testes automáticos
- Faça linting
- Gere build
- Faça deploy em ambiente de staging

🗄 7. Bancos de Dados
Prompt – Otimizar Query
Otimize a seguinte query SQL:

[query aqui]

Explique:
- Problemas de performance
- Índices recomendados
- Alternativas mais eficientes

Prompt – Modelagem
Sugira um modelo de banco de dados para este projeto:

[descrição do sistema]

Liste:
- Tabelas
- Relacionamentos
- Tipos de dados

🌐 8. APIs e Integrações
Prompt – Especificação OpenAPI
Gere uma especificação OpenAPI (YAML) para os endpoints abaixo:

[descrição dos endpoints ou código da API]

Prompt – Integração Externa
Explique como integrar este sistema com a API do [serviço X].  
Forneça exemplos em Python com requests ou httpx.

☁ 9. Cloud e Deploy
Prompt – Arquitetura AWS
Sugira uma arquitetura na AWS para este projeto:

[descrição]

- Serviços necessários
- Custos estimados
- Estratégia de escalabilidade

Prompt – Deploy Kubernetes
Crie um manifesto Kubernetes (YAML) para rodar este serviço:

[código ou imagem docker]

🧠 10. Prompts de Aprendizado
Prompt – Explicar Código
Explique este código como se eu fosse um iniciante:

[código aqui]

Prompt – Tutor de Conceito
Me ensine o conceito de [ex: Programação Reativa] com exemplos práticos em Python.

🎯 11. Prompts de Gestão e Planejamento
Prompt – Roadmap
Crie um roadmap de evolução para este projeto:

[descrição do projeto]

Inclua:
- Features a curto, médio e longo prazo
- Priorização
- Dependências

Prompt – User Stories
Com base neste sistema [descrição], escreva user stories no formato:

"Como [persona], quero [ação] para [benefício]".

🧩 12. Outros Prompts Úteis

Gerar scripts de migração

Converter código entre linguagens (ex: Python → Go)

Explicar logs de erro complexos

Simular entrevistas técnicas com base no código do projeto

Gerar exemplos de uso para APIs internas

Recomendar bibliotecas modernas que substituem dependências antigas

👉 Quer que eu organize toda essa biblioteca de prompts em um único arquivo .md estruturado por categorias, pronto para importar no Open WebUI?

Você disse:
sim crie todos esse sugeridos e tambem prompts para reestruturação e/ou refatoração, e crie mais exemplos
O ChatGPT disse:

Show 👊 agora sim vamos montar um super arquivo completo .md com todos os prompts sugeridos + novos para reestruturação e refatoração de projetos inteiros. A ideia é virar uma biblioteca de prompts para devs, pronta para importar ou consultar no Ollama / Open WebUI.

Vou organizar em seções, cada uma com vários prompts prontos para copiar/colar.

📘 Biblioteca Completa de Prompts para Desenvolvedores

Para Ollama & Open WebUI

🔍 1. Análise e Revisão de Código
Prompt – Code Review Detalhado
Faça um code review do seguinte trecho de código:

[código aqui]

- Liste problemas de clareza, manutenção e estilo
- Aponte possíveis bugs ou edge cases
- Sugira melhorias
- Explique como deixá-lo aderente ao padrão da linguagem (PEP8 no Python, ESLint no JS, etc.)

Prompt – Comparar Implementações
Compare as duas versões de código abaixo:

[código versão A]
[código versão B]

- Qual é mais eficiente?
- Qual é mais legível?
- Qual é mais fácil de manter?
- Qual você recomenda e por quê?

🛠 2. Refatoração e Reestruturação
Prompt – Reestruturar Projeto
Tenho o seguinte projeto:

[cole estrutura de diretórios ou link do repo]

Sugira uma nova organização de pastas e módulos para:
- Melhorar a escalabilidade
- Separar responsabilidades
- Seguir boas práticas da linguagem/framework

Prompt – Refatoração Progressiva
Sugira um plano de refatoração progressiva para este projeto:

[descrição ou código]

Inclua:
- Mudanças imediatas (baixo risco, alto impacto)
- Refatorações intermediárias
- Reestruturações de longo prazo

Prompt – Transformar Código Procedural em Orientado a Objetos
Converta o seguinte código procedural em uma versão orientada a objetos:

[código aqui]

Explique:
- Quais classes e métodos criou
- Como isso melhora manutenibilidade e reuso

Prompt – Aplicar Clean Code
Reescreva este código aplicando princípios de Clean Code:

[código aqui]

- Simplifique nomes
- Elimine duplicações
- Reduza complexidade ciclomática

📚 3. Documentação
Prompt – Gerar README Profissional
Com base neste projeto:

[código/descrição]

Crie um README.md contendo:
- Nome e descrição
- Tecnologias utilizadas
- Instalação e execução
- Exemplos de uso
- Roadmap
- Contribuições

Prompt – Documentação Automática
Analise o seguinte código e gere documentação automática em Markdown, incluindo:

- Lista de funções/métodos com descrição
- Parâmetros e retornos
- Exemplos de uso

🔒 4. Segurança
Prompt – Security Review
Analise este código e identifique riscos de segurança:

[código aqui]

- Validação de entradas
- Autenticação/autorização
- Uso de dependências inseguras
- Sugestões de correção

Prompt – Hardening
Sugira técnicas de hardening para este sistema:

[descrição ou código]

- Banco de dados
- API
- Infraestrutura

⚡ 5. Performance e Escalabilidade
Prompt – Performance Profiling
Analise este código:

[código aqui]

- Identifique gargalos
- Sugira estruturas de dados melhores
- Reescreva o trecho mais crítico de forma otimizada

Prompt – Escalabilidade de API
Tenho esta API:

[código ou descrição]

Como escalá-la para suportar milhares de usuários simultâneos?
- Estratégias de cache
- Load balancing
- Sharding de banco
- Uso de filas

🚀 6. DevOps e Infraestrutura
Prompt – Criar Dockerfile
Crie um Dockerfile otimizado para este projeto:

[código ou estrutura de pastas]

Prompt – CI/CD Pipeline
Gere um pipeline de CI/CD no GitHub Actions para este projeto que:
- Rode testes
- Faça linting
- Gere build
- Faça deploy em staging

🗄 7. Bancos de Dados
Prompt – Modelagem
Crie um modelo de banco de dados para este sistema:

[descrição do projeto]

Liste:
- Tabelas
- Relacionamentos
- Tipos de dados

Prompt – Query Optimization
Otimize a seguinte query SQL:

[query aqui]

Explique:
- Problemas atuais
- Índices recomendados
- Alternativas mais eficientes

🌐 8. APIs e Integrações
Prompt – OpenAPI
Gere uma especificação OpenAPI (YAML) para os endpoints abaixo:

[descrição ou código]

Prompt – Integração Externa
Explique como integrar este sistema com a API do [serviço X].
Forneça exemplos em Python usando httpx.

☁ 9. Cloud e Deploy
Prompt – Arquitetura Cloud
Sugira uma arquitetura na AWS para este projeto:

[descrição]

Inclua:
- Serviços
- Custos estimados
- Estratégia de escalabilidade

Prompt – Kubernetes
Crie manifestos Kubernetes (YAML) para rodar este serviço em produção:

[imagem docker ou código]

🧠 10. Aprendizado e Ensino
Prompt – Explicar Código
Explique o seguinte código como se eu fosse um iniciante:

[código aqui]

Prompt – Tutor de Conceito
Me ensine o conceito de [ex: programação reativa] com exemplos práticos em Python.

🎯 11. Planejamento e Gestão
Prompt – Roadmap
Crie um roadmap para este projeto:

[descrição]

Inclua:
- Features curto, médio e longo prazo
- Priorização
- Dependências

Prompt – User Stories
Com base neste sistema:

[descrição]

Escreva user stories no formato:
"Como [persona], quero [ação] para [benefício]".

🧩 12. Outros Prompts Avançados

Migrar de framework

Sugira como migrar este projeto de Flask para FastAPI:

[código/descrição]


Converter linguagem

Converta este código Python para Go, mantendo a mesma lógica e boas práticas:

[código aqui]


Gerar testes automáticos

Crie testes unitários para este código usando pytest:

[código aqui]


Explicar logs de erro complexos

Explique este log de erro, possíveis causas e soluções:

[log aqui]


Recomendar bibliotecas modernas

Estou usando [biblioteca antiga].  
Recomende alternativas modernas mais seguras e eficientes.


⚡ Isso vira praticamente um kit dev IA 🎒 com prompts prontos para:

Revisar e refatorar código

Criar infra e pipelines

Melhorar performance e segurança

Documentar

Planejar evolução de projetos

👉 Quer que eu já prepare esse material em um único arquivo Prompts_Desenvolvedores.md para você baixar direto?

Você disse:
melhora mais ainda e inclua mais modelos de prompts que podem ser uteis
O ChatGPT disse:

Boa 👊 vamos deixar esse material ainda mais completo e poderoso:
Vou expandir bastante a biblioteca, cobrindo mais cenários práticos que desenvolvedores enfrentam no dia a dia, desde prototipagem rápida até engenharia reversa, código legado, manutenção, testes avançados, automação, inteligência artificial aplicada, etc.

A ideia é montar um guia definitivo de prompts para devs no Ollama/Open WebUI 🚀.

📘 Biblioteca Completa de Prompts para Desenvolvedores

Para Ollama & Open WebUI

🔍 1. Análise e Revisão de Código
Code Review Avançado
Revise o seguinte código como se fosse um revisor sênior de um PR no GitHub:

[código aqui]

- Estilo e clareza
- Padrões de projeto aplicados ou faltando
- Possíveis bugs ocultos
- Impacto em performance e segurança
- Sugestão de melhorias com exemplos

Engenharia Reversa de Código
Explique o que este código faz em alto nível, como se fosse uma documentação:

[código aqui]

- Fluxo principal
- Dependências externas
- Entradas e saídas
- Propósito do sistema

🛠 2. Refatoração e Reestruturação
Código Legado → Código Moderno
Refatore este código legado para padrões modernos:

[código aqui]

- Use recursos modernos da linguagem
- Substitua libs desatualizadas
- Explique diferenças entre a versão antiga e a nova

Modularização Extrema
Transforme este projeto monolítico em módulos independentes:

[código ou estrutura de pastas]

Sugira:
- Módulos principais
- Interfaces entre módulos
- Benefícios para escalabilidade

Padrões de Projeto
Aplique um padrão de projeto adequado ao código abaixo:

[código aqui]

Explique:
- Qual padrão foi aplicado
- Quais problemas resolveu
- Quando reutilizar esse padrão

📚 3. Documentação
AutoDoc para Classes
Gere documentação detalhada para as classes abaixo:

[código aqui]

Inclua:
- Descrição da classe
- Métodos e parâmetros
- Exemplos de uso

Gerar Wiki Técnica
Crie uma documentação estilo Wiki para este projeto:

[código/descrição]

Com seções:
- Introdução
- Arquitetura
- Guia de instalação
- Casos de uso
- Roadmap

🔒 4. Segurança
Checklist de Segurança
Analise este projeto e faça um checklist de segurança:

[código/descrição]

Inclua:
- Validação de dados
- Gestão de tokens e senhas
- Criptografia em uso
- Logs e auditoria

Exploração Simulada
Simule possíveis formas de explorar falhas de segurança neste código:

[código aqui]

Depois sugira correções para cada risco.

⚡ 5. Performance e Escalabilidade
Benchmark Simulado
Com base neste código, onde estariam os gargalos de performance em um cenário de alta carga?

[código aqui]

Sugira métricas a coletar e pontos de otimização.

Melhor Estrutura de Dados
Este código usa listas para tudo:

[código aqui]

Sugira substituições por estruturas mais eficientes (sets, dicts, árvores, etc) e explique ganhos.

🚀 6. DevOps e Infraestrutura
Infra como Código
Gere um arquivo Terraform para provisionar este sistema em AWS:

[descrição/projeto]

Observabilidade
Sugira como adicionar logs estruturados, métricas e tracing neste projeto:

[código aqui]

🗄 7. Bancos de Dados
Migração de Esquema
Sugira migrações para evoluir este banco de dados:

[esquema atual]

Explique:
- Novas colunas ou tabelas
- Índices necessários
- Impacto em queries existentes

ORM vs SQL Puro
Compare vantagens e desvantagens de usar ORM vs SQL puro para este projeto:

[descrição/código]

🌐 8. APIs e Integrações
Validação de API
Analise os endpoints desta API e sugira melhorias:

[código/descrição]

- Segurança
- Padronização de respostas
- Documentação
- Testes

Mock de API
Gere mocks de respostas JSON para os seguintes endpoints:

[lista de endpoints]

☁ 9. Cloud e Deploy
Multi-Cloud
Sugira uma arquitetura multi-cloud (AWS + GCP) para este sistema:

[descrição]

Deploy Automatizado
Crie um script de deploy automatizado para este projeto em Linux usando Ansible:

[descrição]

🧠 10. Aprendizado e Ensino
Explicar em Diferentes Níveis
Explique este conceito de 3 formas:
- Para uma criança de 10 anos
- Para um estudante de programação
- Para um engenheiro sênior

Conceito: [ex: concorrência em sistemas]

Criar Exercícios
Crie 5 exercícios práticos sobre [tema X], incluindo código inicial e objetivo a ser atingido.

🎯 11. Planejamento e Gestão
Kanban Board
Crie um board Kanban com tarefas para desenvolver este sistema:

[descrição]

Separe em:
- Backlog
- Em andamento
- Revisão
- Concluído

Estimativas Ágeis
Faça estimativas em pontos de história para as seguintes tasks:

[listagem de tasks]

🧩 12. Outros Prompts Avançados
Geração de Testes Automáticos
Crie testes unitários e de integração para este código:

[código aqui]

Use pytest e explique cobertura.

Explicar Logs Complexos
Explique este log de erro:

[log aqui]

- O que significa
- Possíveis causas
- Como corrigir

Protótipo Rápido
Crie um protótipo de aplicação web simples em Flask que:

- Tenha 2 rotas
- Leia dados de um JSON
- Retorne respostas em HTML

IA em Projetos
Sugira como integrar IA a este sistema:

[descrição]

Inclua bibliotecas recomendadas e exemplos de uso.

🎁 13. Prompts Extras Super Úteis

Comparar tecnologias

Compare [framework A] e [framework B] para este projeto: [descrição]


Gerar cheatsheet

Crie uma cheatsheet com comandos mais usados de [tecnologia X]


Migrar versões

Sugira como migrar este projeto de Python 3.8 para 3.12, apontando mudanças necessárias.


Automação

Crie um script Python que leia arquivos CSV em lote e os insira no banco PostgreSQL.


Code Smells

Liste code smells neste código e como removê-los:

[código aqui]


Testes de Carga

Sugira como testar a performance desta API usando Locust ou JMeter.


⚡ Agora temos uma biblioteca com mais de 70 prompts prontos, cobrindo praticamente todas as áreas de desenvolvimento.

👉 Quer que eu gere agora o arquivo único Prompts_Desenvolvedores.md já formatado, para você baixar direto e usar como manual?

Você disse:
consegue criar os modelos faltantes de prompt para atingir mais areas ou criar novos para melhorar a biblioteca
O ChatGPT disse:

Perfeito ⚡ — vamos expandir ainda mais essa biblioteca de prompts para devs para deixá-la realmente coberta em 360°.
Até agora já temos prompts para análise, refatoração, documentação, DevOps, bancos, APIs, cloud, segurança, testes, planejamento, ensino...

Mas ainda podemos criar novas categorias e modelos faltantes que ajudam no dia a dia de desenvolvimento:

🔥 Expansão da Biblioteca de Prompts para Desenvolvedores
🎨 14. UI/UX e Frontend
Prompt – Revisão de UI/UX
Analise esta interface web (HTML/CSS/JS):

[código aqui]

Sugira melhorias de:
- Acessibilidade (WCAG)
- Responsividade
- Usabilidade
- Padrões modernos de UI/UX

Prompt – Componentização
Transforme este código em componentes reutilizáveis:

[código frontend aqui]

Sugira:
- Componentes básicos
- Componentes compostos
- Benefícios da componentização

Prompt – Acessibilidade
Revise este frontend e sugira ajustes para torná-lo mais acessível:

[código aqui]

Inclua:
- ARIA
- Navegação por teclado
- Contraste

🤖 15. Machine Learning / Data Science
Prompt – Data Cleaning
Analise este dataset (CSV/JSON):

[exemplo de dados]

- Identifique problemas (valores nulos, duplicados, inconsistências)
- Sugira estratégias de limpeza
- Gere código Python (pandas) para corrigir

Prompt – Feature Engineering
Sugira features úteis para este dataset:

[descrição/dados]

Explique como cada feature pode melhorar um modelo de ML.

Prompt – Escolha de Modelo
Tenho este problema: [descrição]

Sugira algoritmos de ML adequados e explique prós e contras de cada.

🧪 16. Testes Avançados
Prompt – Testes End-to-End
Crie testes E2E para esta aplicação web usando Playwright:

[descrição ou código]

Prompt – Testes de Performance
Sugira um plano de testes de performance para esta API:

[endpoints ou código]

Inclua:
- Ferramentas recomendadas
- Métricas a coletar
- Exemplos de scripts

Prompt – Testes de Segurança
Crie testes automatizados para verificar vulnerabilidades comuns (SQL Injection, XSS, CSRF) nesta aplicação:

[código aqui]

🕵️ 17. Observabilidade e Monitoramento
Prompt – Logs Estruturados
Transforme este código para usar logs estruturados (JSON):

[código aqui]

Explique benefícios e como integrá-los com ELK Stack.

Prompt – Alertas
Sugira alertas importantes para monitorar este sistema em produção.
Inclua métricas e thresholds recomendados.

💼 18. Integração com Negócio
Prompt – Geração de Relatórios
Gere um relatório executivo a partir desses dados técnicos:

[logs, métricas ou código]

Explique em termos de negócio, sem jargões técnicos.

Prompt – User Journey
Com base neste sistema, descreva a jornada típica de um usuário final e identifique pontos de atrito.

📦 19. Microserviços e Arquitetura
Prompt – Quebrar em Microserviços
Tenho este projeto monolítico:

[descrição/código]

Sugira como quebrá-lo em microserviços:
- Serviços principais
- Comunicação entre eles
- Benefícios e riscos

Prompt – Mensageria
Explique como integrar RabbitMQ ou Kafka neste projeto para desacoplar serviços:

[código/descrição]

⚙️ 20. Automação e Scripting
Prompt – Automação de Tarefas
Crie um script em Python que:

- Leia arquivos em uma pasta
- Extraia informações específicas
- Gere um relatório em CSV

Prompt – CI/CD Avançado
Crie um pipeline CI/CD que:
- Execute testes
- Gere imagens Docker
- Rode análise de segurança (SAST/DAST)
- Faça deploy em Kubernetes

🌍 21. Internacionalização e Localização
Prompt – i18n
Adapte este projeto para suportar múltiplos idiomas:

[código aqui]

Explique:
- Onde usar placeholders
- Como estruturar arquivos de tradução

Prompt – Localização
Sugira boas práticas para adaptar este sistema ao mercado [país X], considerando:
- Moeda
- Datas
- Idioma
- Leis locais

📡 22. API Avançada
Prompt – Versionamento
Sugira estratégia de versionamento para esta API:

[endpoints/código]

Explique vantagens de cada abordagem.

Prompt – Rate Limiting
Adicione suporte a rate limiting nesta API:

[código aqui]

Sugira bibliotecas ou middlewares para implementar.

🧩 23. Integrações e Plugins
Prompt – Integração com Pagamentos
Explique como integrar este sistema com a API do Stripe/PagSeguro/Pix.

Forneça exemplos de endpoints e fluxos.

Prompt – Plugin System
Sugira como transformar este projeto em um sistema com suporte a plugins:

[descrição ou código]

🛡 24. Confiabilidade e Resiliência
Prompt – Retry Strategy
Implemente uma estratégia de retries com backoff exponencial para este código:

[código aqui]

Prompt – Chaos Engineering
Sugira experimentos de Chaos Engineering para testar a resiliência deste sistema.

🧭 25. Roadmaps Técnicos
Prompt – Evolução Tecnológica
Crie um roadmap para migrar este projeto de monólito para microserviços em 12 meses.

Inclua:
- Fases
- Riscos
- Métricas de sucesso

Prompt – Upgrade Tecnológico
Sugira como atualizar este projeto para usar as versões mais recentes das dependências, minimizando riscos.


✅ Agora a biblioteca cobre:

Frontend/UI/UX

ML/Data Science

Testes avançados

Observabilidade

Negócio & UX

Microserviços

Automação/Scripting

i18n & Localização

APIs avançadas

Integrações & Plugins

Resiliência

Roadmaps técnicos

Ou seja: quase todas as áreas que um desenvolvedor moderno enfrenta.

👉 Quer que eu una tudo (as versões anteriores + esses novos prompts) em um único arquivo Prompts_Desenvolvedores.md pronto para você baixar e usar como manual definitivo?

Você disse:
consegue criar prompts voltados para github, versionamento, e gerar mais modelos deixando ainda mais completo
O ChatGPT disse:

Boa! 🚀
Agora vamos reforçar a biblioteca com uma seção dedicada a Git, GitHub, versionamento, workflows de repositórios e mais alguns modelos extras para completar de vez.

📘 Biblioteca de Prompts para Desenvolvedores (Expansão Git/GitHub + Extras)
🐙 26. Git & GitHub
Prompt – Análise de Commits
Analise os seguintes commits e gere um resumo de mudanças em linguagem clara:

[lista de commits ou diff]

Inclua:
- Funcionalidades adicionadas
- Bugs corrigidos
- Impacto no sistema

Prompt – Melhoria de Mensagens de Commit
Reescreva as mensagens de commit abaixo no padrão Conventional Commits:

[lista de commits]

Prompt – Gitignore Automático
Com base neste projeto (estrutura de pastas):

[lista de arquivos]

Gere um arquivo .gitignore adequado.

Prompt – Estratégia de Branches
Sugira uma estratégia de branches para este projeto em GitHub:

[descrição]

Explique:
- Branch principal
- Branches de release
- Branches de feature
- Fluxo de merge

Prompt – PR Template
Crie um template de Pull Request para este projeto, incluindo:
- Descrição da mudança
- Checklist de revisão
- Screenshots (quando aplicável)
- Issues relacionadas

Prompt – Issue Template
Crie um template de issue para bugs que contenha:
- Título claro
- Passos para reproduzir
- Resultado esperado vs obtido
- Logs ou prints

Prompt – Changelog Automático
Com base nos commits abaixo, gere um CHANGELOG.md estruturado por versão:

[commits aqui]

Prompt – Análise de PR
Faça um code review deste Pull Request:

[diff do PR]

- Pontos positivos
- Problemas identificados
- Sugestões de melhoria

Prompt – Actions de Qualidade
Crie um workflow do GitHub Actions que:
- Rode testes
- Execute linting
- Verifique segurança com Dependabot
- Gere relatório de cobertura

📊 27. Versionamento e Lançamentos
Prompt – Estratégia de Versionamento
Defina uma estratégia de versionamento para este projeto:
[descrição]

Explique:
- Como aplicar SemVer (major.minor.patch)
- Quando quebrar compatibilidade
- Como manter releases estáveis

Prompt – Release Notes
Gere notas de release para a versão X.Y.Z deste projeto com base nos commits:

[commits aqui]

Inclua:
- Novas features
- Correções
- Melhorias
- Breaking changes

Prompt – Automação de Tags
Sugira como automatizar criação de tags e releases neste projeto usando GitHub Actions.

⚡ 28. Colaboração & Fluxos de Trabalho
Prompt – Contributing.md
Crie um arquivo CONTRIBUTING.md para este projeto, incluindo:
- Como abrir issues
- Como criar PRs
- Estilo de commits
- Padrões de código

Prompt – Code Owners
Sugira um CODEOWNERS para este projeto com base nas pastas:

[src/auth]
[src/frontend]
[src/api]

Prompt – Pair Programming AI
Atue como par de programação revisando este código linha a linha:

[código aqui]

📂 29. Organização de Repositórios
Prompt – Estrutura Multi-Repo vs Monorepo
Analise este projeto:

[descrição]

Sugira se é melhor usar monorepo ou múltiplos repositórios. Explique prós e contras.

Prompt – Submódulos
Explique como organizar este sistema usando Git Submodules ou Git Subtree:

[descrição]

⚙️ 30. Extras Úteis
Prompt – Política de Code Review
Crie uma política de code review para este repositório, incluindo:
- Número mínimo de aprovadores
- Regras de merge
- Checklist obrigatório antes de aprovar

Prompt – Badges
Sugira badges úteis para o README deste repositório:
- Build status
- Test coverage
- Último release
- Licença

Prompt – Licença
Sugira a licença mais adequada para este projeto (MIT, Apache, GPL) e explique por quê.

✅ Agora a biblioteca cobre também:

Git e GitHub (commits, PRs, issues, workflows, tags, releases, actions)

Versionamento SemVer e notas de release automáticas

Fluxos de contribuição e colaboração

Organização de repositórios (monorepo, submódulos)

Políticas de code review e governança de projeto

Ou seja: um dev pode pegar esse material e aplicar em todo o ciclo de vida de software, do código até o deploy e gestão do repositório.

👉 Quer que eu una TODAS as seções já criadas (1 a 30) em um único Prompts_Desenvolvedores.md gigante e bem formatado, pronto para baixar e usar como manual definitivo?

Você disse:
sim
O ChatGPT disse:

Pronto! ✅
Gerei o arquivo consolidado com todos os modelos de prompt:

📂 Baixar Prompts_Desenvolvedores.md

Esse documento é um manual completo com prompts organizados por categorias, incluindo Git, GitHub, refatoração, versionamento, colaboração, documentação, segurança, CI/CD e muito mais.


📦 Prompts para Deploy (DevOps & CI/CD)
🔹 1. Deploy Local (Linux/Servidor Próprio)
Exemplo 1 – Checklist de Deploy
Quero fazer o deploy de uma aplicação FastAPI em um servidor Ubuntu.  
Liste todos os passos necessários, incluindo:
- Instalação de dependências
- Configuração do ambiente virtual
- Configuração do banco de dados
- Servidor WSGI/ASGI (Uvicorn/Gunicorn)
- Reverse proxy com Nginx
- Boas práticas de segurança (firewall, SSL, usuários não-root)

Exemplo 2 – Automação com Systemd
Crie um arquivo de configuração systemd para rodar minha aplicação Python (FastAPI) em produção usando Gunicorn + Uvicorn.
- A aplicação roda na pasta /home/app/fastapi
- Deve iniciar automaticamente no boot
- Usuário do serviço: appuser

🐳 2. Deploy com Docker
Exemplo 3 – Dockerfile otimizado
Analise meu projeto Python abaixo e gere um Dockerfile otimizado:
- Usar multistage build para reduzir tamanho
- Fixar dependências em requirements.txt
- Minimizar camadas
- Configurar variável de ambiente para produção
[código/projeto aqui]

Exemplo 4 – Docker Compose
Preciso de um docker-compose.yml para rodar:
- Um container com minha API FastAPI
- Um container com PostgreSQL
- Um volume persistente para o banco
- Um container com pgadmin para administração

☁️ 3. Deploy em Nuvem
Exemplo 5 – AWS EC2
Explique passo a passo como fazer deploy de uma aplicação Python/FastAPI em uma instância AWS EC2 com Ubuntu:
- Configuração inicial da instância
- Acesso via SSH seguro
- Instalação de Docker
- Deploy da aplicação em container
- Configuração de DNS + SSL (Let's Encrypt)

Exemplo 6 – Kubernetes (K8s)
Crie os manifests YAML para rodar minha aplicação FastAPI no Kubernetes:
- Deployment com 3 réplicas
- Service para expor internamente
- Ingress para expor externamente na porta 80
- ConfigMap para variáveis de ambiente
- Secret para credenciais do banco

⚙️ 4. Deploy com GitHub Actions (CI/CD)
Exemplo 7 – Pipeline básico
Crie um arquivo .github/workflows/deploy.yml que faça:
- Build e testes da aplicação Python
- Build da imagem Docker
- Push para DockerHub
- Deploy automático em servidor com SSH

Exemplo 8 – Deploy contínuo na Vercel
Crie um workflow GitHub Actions que faça deploy contínuo de um projeto Next.js na Vercel sempre que houver push na branch main.

🔒 5. Segurança no Deploy
Exemplo 9 – Checklist de segurança
Liste as boas práticas de segurança para deploy em produção de uma API Python/Node.js, incluindo:
- Gestão de variáveis de ambiente (secrets)
- Atualização e hardening do servidor
- Monitoramento e logging
- Configuração de SSL
- Controle de acesso via firewall

📊 6. Monitoramento Pós-Deploy
Exemplo 10 – Monitoramento com Prometheus + Grafana
Crie um docker-compose.yml que rode:
- Minha aplicação FastAPI
- Prometheus configurado para coletar métricas da aplicação
- Grafana com dashboards pré-configurados para monitorar requisições e erros


📌 Esses prompts podem ser usados direto no Ollama/OpenWebUI para gerar scripts, arquivos YAML, workflows, tutoriais passo a passo ou até mesmo refatoração de Dockerfiles e pipelines.
📌 


Guia Rápido de Uso:
Ollama/OpenWebUI: Esses sistemas normalmente executam modelos Llama 2, CodeLlama, Mistral, Mixtral, Codestral ou outros modelos especializados em código.

Forneça Contexto: Antes de usar prompts que pedem análise de código, você geralmente precisa colar o código relevante no chat. A OpenWebUI tem um recurso de "contexto" (um botão de clipe de papel) para upload de arquivos, o que é perfeito para isso.

Especifique o Modelo: Para tarefas complexas de código, use um modelo especializado (ex: codellama, wizardcoder, mistral, codestral). Inicie seu prompt com [Instrução: Atue como um engenheiro de software sênior especialista em [Linguagem].].

Categoria 1: Análise e Exploração de Repositórios GitHub
1. Análise Geral de um README.md
(Ideal para entender um projeto rapidamente)
Prompt:

text
Atue como um arquiteto de software experiente. Vou fornecer o conteúdo do arquivo README.md de um repositório GitHub. Analise-o e me forneça um resumo conciso com os seguintes tópicos:

1.  **Objetivo Principal:** O que este projeto se propõe a fazer?
2.  **Tecnologias Chave:** Quais linguagens, frameworks e ferramentas são utilizadas?
3.  **Estado do Projeto:** O README indica se está em desenvolvimento, estável ou abandonado?
4.  **Destaques:** Há alguma característica única ou ponto de venda?
5.  **Complexidade:** Com base na descrição, o projeto parece simples, moderado ou complexo?

Aqui está o conteúdo do README:
[COLE O CONTEÚDO DO README AQUI]

text
2. Análise de Estrutura de Diretórios
(Para entender a organização e arquitetura de um projeto)
Prompt:

text
Atue como um engenheiro de software sênior. Analise a estrutura de diretórios abaixo de um projeto e me diga:

1.  **Padrão Arquitetural:** Isso segue MVC, Component-based, Monolítico, etc.?
2.  **Organização:** A estrutura é clara e lógica? Há algo incomum ou fora do padrão?
3.  **Possíveis Problemas:** Há pastas com nomes genéricos como "misc" ou "outros"? Há mistura de conceitos (ex: lógica de negócio na camada de visualização)?
4.  **Recomendações:** Como você melhoraria esta estrutura?

Estrutura do diretório:
[COLE A SAÍDA DE tree OU A LISTA DE PASTAS/ARQUIVOS AQUI]

text
3. Análise de Código-Fonte para Identificar a Lógica Principal
Prompt:

text
[Instrução: Atue como um desenvolvedor especialista em [Python/JavaScript/Java/etc.]]

Analise o trecho de código abaixo e explique de forma clara e detalhada:

1.  **Qual é a função principal deste código?** Descreva sua entrada, processamento e saída.
2.  **Quebre a lógica** em etapas simples.
3.  **Identifique** quaisquer padrões de design ou algoritmos evidentes.
4.  **Destaque** pontos positivos e possíveis pontos de atenção (ex: tratamento de erro, performance).

Código:
```[Linguagem]
[COLE O CÓDIGO AQUI]
text

---

### **Categoria 2: Melhoria e Refatoração de Código**

**4. Sugestões de Refatoração para Legibilidade e Performance**
**Prompt:**
Atue como um especialista em código limpo ([Clean Code]). Analise o seguinte código e forneça sugestões específicas de refatoração para melhorar:

Legibilidade: Nomes de variáveis, quebra de funções complexas, redução de嵌套 (nested) condicionais.

Performance: Identifique possíveis gargalos e sugere otimizações.

Boas Práticas: Adequação às convenções da linguagem [Linguagem].

Forneça o código original e uma versão refatorada como exemplo. Explique o porquê de cada mudança.

Código para refatorar:

[Linguagem]
[COLE O CÓDIGO AQUI]
text

**5. Adicionar Tratamento de Erros Robusto**
**Prompt:**
Este código está faltando um tratamento de erro adequado. Atue como um desenvolvedor meticuloso e proponha uma versão revisada que inclua:

Verificação de valores nulos ou indefinidos.

Try-Catch blocks onde exceções podem ser lançadas.

Mensagens de erro claras e informativas.

Uma maneira elegante de lidar com falhas sem quebrar o aplicativo.

Mostre o "antes" e o "depois" do código.

Código atual:

[Linguagem]
[COLE O CÓDIGO AQUI]
text

**6. Revisão de Código (Code Review)**
**Prompt:**
[Instrução: Atue como um revisor de código sênior e rigoroso. Sua tarefa é encontrar bugs, más práticas e oportunidades de melhoria.]

Por favor, revise o seguinte trecho de código como se fosse um Pull Request. Forneça feedback nos seguintes formatos:

🚀 Pontos Positivos: O que está bom.

⚠️ Preocupações: Possíveis bugs, vazamentos de memória, condições de corrida.

💡 Sugestões: Melhorias concretas para implementar.

Seja direto e técnico.

Código para revisão:

[Linguagem]
[COLE O CÓDIGO AQUI]
text

---

### **Categoria 3: Geração e Expansão de Código**

**7. Escrever Testes Unitários**
**Prompt:**
Atue como um engenheiro de QA especializado em testes unitários. Com base na função abaixo, escreva um conjunto abrangente de testes unitários usando o framework [Jest/JUnit/pytest/etc.].

Os testes devem cobrir:

Casos de sucesso esperados.

Casos de erro (entradas inválidas, exceções).

Casos extremos (edge cases).

Função a ser testada:

[Linguagem]
[COLE A FUNÇÃO AQUI]
text

**8. Gerar Documentação Técnica**
**Prompt:**
Atue como um escritor técnico. Gere documentação para a seguinte função/classe. Use o formato padrão de docstring da linguagem [Linguagem] (ex: JSDoc para JavaScript, Docstring para Python).

Inclua:

Descrição concisa da função.

@param: Descrição de cada parâmetro e seu tipo.

@returns: Descrição do que é retornado.

@throws: Quais exceções podem ser lançadas.

Um exemplo de uso breve.

Código:

[Linguagem]
[COLE O CÓDIGO AQUI]
text

**9. Traduzir Código entre Linguagens**
**Prompt:**
Atue como um tradutor especializado em linguagens de programação. Converta o seguinte código de [Linguagem de Origem] para [Linguagem de Destino]. Mantenha a mesma lógica, estilo e idiomas da linguagem de destino.

Explique quaisquer diferenças conceituais significativas entre as duas linguagens que afetam a implementação.

Código para traduzir:

[Linguagem
[COLE O CÓDIGO AQUI]
text

---

### **Categoria 4: Troubleshooting e Debugging**

**10. Diagnosticar um Erro ou Log**
**Prompt:**
Atue como um especialista em debugging. Analise a mensagem de erro ou stack trace abaixo e me ajude a diagnosticar o problema:

Causa Raiz: Qual é a provável causa deste erro?

Solução: Quais são os passos para corrigi-lo?

Prevenção: Como evitar que esse erro aconteça no futuro?

Mensagem de erro:

text
[COLE A MENSAGEM DE ERRO OU STACK TRACE AQUI]
text

**11. Analisar e Explicar um Bloco de Código Complexo**
**Prompt:**
[Instrução: Atue como um professor paciente de ciência da computação.]

Este código parece complexo e difícil de entender. Por favor, desmonte-o para mim. Explique:

O que cada parte faz, linha por linha ou bloco por bloco.

O conceito de computação por trás disso (ex: recursão, promise, fechamento (closure)).

Fornece uma analogia do mundo real para ajudar na compreensão.

Obrigado pela paciência!

Código complexo:

[Linguagem]
[COLE O CÓDIGO AQUI]
text

### **Dica Final para OpenWebUI:**

A OpenWebUI permite criar **Personas** (personagens pré-configurados). Você pode criar uma persona chamada "Code Reviewer Sênior" usando as instruções `[Instrução: ...]` dos prompts acima. Isso poupa tempo, pois você não precisa reescrever a instrução toda vez, basta começar seu prompt com o contexto do código.

Experimente esses modelos e ajuste-os conforme suas necessidades específicas!
crie mais exemplos deixando ele mais completo
Hmm, o usuário pediu para criar mais exemplos de prompts, deixando a lista mais completa. Ele já recebeu uma boa base antes, mas quer expandir. 
Vou pensar em categorias que não foram cobertas antes e aprofundar as existentes. O usuário parece ser um desenvolvedor usando Ollama/OpenWebUI, então preciso focar em casos práticos e úteis para o dia a dia dele. 
Lembrar de incluir desde planejamento até deploy, e também cenários mais complexos como análise de segurança e legacy code. Manter a estrutura de antes com instruções claras e exemplos de código placeholder. 
Incluir uma seção de "como usar" ainda mais detalhada, pois o usuário gostou da anterior. Talvez adicionar dicas de como combinar prompts para fluxos completos.
Modelos de Prompt Completos para Desenvolvimento com Ollama/Open WebUI
Guia de Utilização Avançada
Como Maximizar os Resultados:
Especificação de Modelo: Sempre inicie prompts complexos com [Instrução: Atue como [especialista] com [X] anos de experiência em [tecnologia]]

Fornecimento de Contexto: Use o recurso de upload de arquivos da OpenWebUI para projetos completos

Configuração de Personas: Crie personas especializadas na OpenWebUI para diferentes funções

Temperatura e Criatividade: Ajuste para valores bairos (0.1-0.3) para código e alto (0.7-0.9) para brainstorming

📁 Categoria Expandida: Análise de Repositórios GitHub
1. Análise Técnica Profunda de Repositório
Prompt:

text
[Instrução: Atue como um arquiteto de software sênior com 15 anos de experiência em análise de sistemas complexos]

Realize uma análise técnica completa do repositório com base na estrutura e arquivos fornecidos. Forneça um relatório detalhado incluindo:

**1. Análise Arquitetural:**
- Padrão arquitetural identificado (MVC, Microserviços, Hexagonal, etc.)
- Acoplamento e coesão entre módulos
- Pontos de violação arquitetural

**2. Análise de Qualidade de Código:**
- Indicadores de dívida técnica
- Complexidade ciclomática média
- Possíveis code smells (baseado em convenções)

**3. Análise de Dependências:**
- Dependências obsoletas ou com vulnerabilidades conhecidas
- Dependências desnecessárias ou subutilizadas

**4. Recomendações Prioritárias:**
- [P1] Crítico:必须立即解决的问题
- [P2] Alto:应该尽快解决的问题
- [P3] Médio:建议改进的问题

Estrutura do repositório:
[COLE A SAÍDA DE tree -a -I 'node_modules|.git' AQUI]

text

Arquivos críticos para análise:
[LISTE OS ARQUIVOS PRINCIPAIS COMO package.json, pom.xml, Dockerfile, etc.]

text
2. Análise de Commits e Evolução do Projeto
Prompt:

text
[Instrução: Atue como um engenheiro de devops e analista de qualidade de código]

Analise o histórico de commits abaixo e forneça insights sobre:

**1. Padrões de Desenvolvimento:**
- Frequência e consistência dos commits
- Padrão de mensagens de commit (conventionnal commits?)
- Horários predominantes de commits (indicativo de burnout?)

**2. Análise de Colaboração:**
- Principais contribuidores e seus padrões
- Possíveis gargalos no desenvolvimento
- Arquivos com maior número de modificações

**3. Indicadores de Qualidade:**
- Razão entre commits de feature/bugfix/refatoração
- Arquivos com maior churn (muitas alterações)
- Possíveis áreas de instabilidade

**4. Recomendações para Melhoria do Processo:**

Histórico de commits (últimos 30 dias):
[COLE A SAÍDA DE git log --oneline --since="30 days" --pretty=format:"%h|%an|%ad|%s" --date=short]

text
📁 Categoria Expandida: Desenvolvimento e Refatoração
3. Refatoração de Sistema Legado
Prompt:

text
[Instrução: Atue como um especialista em modernização de sistemas legados com expertise em [linguagem/framework]]

Estou trabalhando em um sistema legado e preciso de um plano de refatoração em fases. 

**Contexto do Sistema:**
- Linguagem: [ex: PHP 5.6, Java 8, etc.]
- Principais desafios: [ex: acoplamento alto, testes frágeis, documentação inexistente]
- Objetivos de negócio: [ex: permitir novas funcionalidades, melhorar performance]

**Solicito:**
1. **Análise de Risco:** Quais são os riscos mais críticos nesta refatoração?
2. **Estratégia de Refatoração:** 
   - Fase 1: Estabilização (1-2 semanas)
   - Fase 2: Refatoração arquitetural (3-4 semanas) 
   - Fase 3: Modernização (2-3 semanas)
3. **Plano de Testes:** Como garantir que não haverá regressões?
4. **Métricas de Sucesso:** Como medir o progresso?

Código exemplar do sistema atual:
```[linguagem]
[COLE 2-3 EXCERTOS REPRESENTATIVOS DO CÓDIGO LEGADO]
text

### 4. Padrões de Design Aplicados a Problemas Específicos
**Prompt:**
[Instrução: Atue como um software architect especializado em padrões de design e clean code]

Tenho o seguinte desafio de design:
[DESCREVA O PROBLEMA OU REQUISITO COMPLEXO]

Contexto do Sistema:

Linguagem: [JavaScript/Python/Java/etc.]

Requisitos não-funcionais: [escalabilidade, baixa latência, etc.]

Restrições técnicas: [ex:必须使用现有库X, 不能迁移数据库]

Solicito:

Análise de Opções: Apresente 2-3 padrões de design aplicáveis

Diagrama Conceptual: Descreva a solução em formato de diagrama

Vantagens e Desvantagens: de cada abordagem

Implementação de Referência: Forneça um exemplo concreto do padrão recomendado

Problema:
[DESCREVA O PROBLEMA EM DETALHE]

text

## 📁 Categoria Nova: Arquitetura e Design de Sistemas

### 5. Design de API RESTful Avançado
**Prompt:**
[Instrução: Atue como um expert em API design com foco em RESTful principles]

Preciso projetar uma API para: [DESCREVA O DOMÍNIO/ENTIDADES]

Requisitos:

Deve seguir princípios RESTful maduros (HATEOAS, etc.)

Suporte a versionamento

Paginação, filtros, sorting

Autenticação e autorização

Rate limiting

Documentação automática

Entidades Principais:
[LISTE AS PRINCIPAIS ENTIDADES E SEUS ATRIBUTOS]

Solicito:

Design de Recursos: Estrutura de endpoints (URL hierarchy)

Operações: HTTP verbs para cada recurso

Esquemas de Request/Response: JSON schemas exemplares

Códigos de Status HTTP: Para cada operação

Exemplo de Implementação: Em [Node.js/Spring/Python]

text

### 6. Design de Sistema Distribuído
**Prompt:**
[Instrução: Atue como um engenheiro de sistemas distribuídos com experiência em scalable systems]

Preciso projetar um sistema distribuído para: [DESCREVA A CARGA E REQUISITOS]

Requisitos Não-Funcionais:

Carga esperada: [X requests/segundo]

Latência máxima: [Y ms]

Disponibilidade: [Z% uptime]

Consistência vs. Disponibilidade: [CAP theorem tradeoffs]

Solicito:

Diagrama Arquitetural: Componentes e suas interações

Estratégia de Escalabilidade: Horizontal vs vertical

Gestão de Estado: Stateless vs stateful

Comunicação entre Serviços: Synchronous vs asynchronous

Considerações de Banco de Dados: SQL vs NoSQL, sharding, replication

Pontos de Falha Potenciais: e mitigações

text

## 📁 Categoria Nova: Performance e Otimização

### 7. Análise e Otimização de Performance
**Prompt:**
[Instrução: Atue como um performance engineer especializado em [linguagem/plataforma]]

Analise o seguinte código/arquitetura para problemas de performance:

Contexto:

Ambiente: [ex: Node.js v18, 4GB RAM, AWS t3.medium]

Padrão de uso: [ex: pico de 1000 req/segundo às 14h]

Métricas atuais: [ex: latency p95 de 450ms, CPU 80%]

Código/Arquitetura:

[linguagem]
[COLE O CÓDIGO OU DESCREVA A ARQUITETURA]
Solicito:

Identificação de Gargalos: Onde estão os principais problemas?

Análise de Complexidade: Notação Big-O das operações críticas

Recomendações de Otimização: Específicas para cada gargalo

Ferramentas de Profiling: Recomendações para confirmar análise

Implementação Otimizada: Versão melhorada do código

text

### 8. Otimização de Consultas de Banco de Dados
**Prompt:**
[Instrução: Atue como um database administrator e query optimization expert]

Otimize a seguinte consulta SQL e o esquema relacionado:

Consulta:

sql
[COLE A CONSULTA SQL AQUI]
Esquema da Tabela:

sql
[COLE O SCHEMA DAS TABELAS ENVOLVIDAS]
Contexto:

SGBD: [MySQL 8.0/PostgreSQL 14/etc.]

Volume de dados: [ex: tabela com 50M de registros]

Padrão de acesso: [ex: 70% reads, 30% writes]

Solicito:

Análise do Plano de Execução: Identifique problemas

Otimizações de Índices: Quais índices criar/remover

Rewriting da Query: Versão otimizada

Modificações de Esquema: Se necessário

Métricas Esperadas: Melhoria estimada em performance

text

## 📁 Categoria Nova: Segurança e DevSecOps

### 9. Análise de Segurança de Código (SAST)
**Prompt:**
[Instrução: Atue como um ethical hacker e application security expert]

Realize uma análise de segurança estática no seguinte código:

Código para análise:

[linguagem]
[COLE O CÓDIGO VULNERÁVEL AQUI]
Solicito:

Vulnerabilidades Identificadas: Liste por categoria (OWASP Top 10)

Severidade: Classifique como Crítica/Alta/Média/Baixa

Prova de Conceito: Como explorar cada vulnerabilidade

Correção: Código corrigido para cada issue

Recomendações Preventivas: Como evitar similar no futuro

text

### 10. Hardening de Configuração e Deployment
**Prompt:**
[Instrução: Atue como um DevSecOps engineer especializado em secure deployments]

Analise a seguinte configuração de deployment e forneça recomendações de hardening:

Arquivos de Configuração:

yaml
[COLE DOCKERCOMPOSE, KUBERNETES DEPLOYMENT, OU SERVER CONFIG]
Contexto:

Ambiente: [Kubernetes AWS/Azure/On-prem]

Sensibilidade dos dados: [ex: dados pessoais, financeiros]

Requisitos regulatórios: [GDPR, HIPAA, etc.]

Solicito:

Riscos Identificados: Configurações inseguras

Recomendações de Hardening: Por categoria (network, secrets, permissions)

Configurações Seguras Exemplares: Arquivos corrigidos

Ferramentas de Scanning: Recomendações para validar segurança

text

## 📊 Tabelas de Referência para Melhores Resultados

### Modelos Recomendados por Tarefa:
| Tarefa | Modelos Recomendados | Temperatura |
|--------|---------------------|-------------|
| Geração de Código | CodeLlama, WizardCoder, Codestral | 0.1-0.3 |
| Análise/Refatoração | DeepSeek-Coder, CodeBooga | 0.2-0.4 |
| Design Arquitetural | Mixtral, Claude-instant | 0.5-0.7 |
| Documentação | Llama2-70B, GPT-4 | 0.3-0.5 |
| Brainstorming | Mixtral, MythoMax | 0.7-0.9 |

### Estrutura de Personas na OpenWebUI:
Nome: Senior Code Reviewer
Instrução: Você é um engenheiro de software sênior com 20 anos de experiência especializado em revisão de código. Seja direto, técnico e forneça exemplos concretos. Foque em clean code, performance e boas práticas.

Nome: System Architect
Instrução: Você é um arquiteto de sistemas distribuídos. Pense em escala, resiliência e manutenibilidade. Forneça diagramas conceituais e explique tradeoffs técnicos.

Nome: Security Expert
Instrução: Você é um especialista em segurança de aplicações. Identifique vulnerabilidades, forneça PoCs e recomendações de mitigação baseadas no OWASP Top 10.

text

## 🔄 Fluxos de Trabalho Integrados

### Fluxo para Novo Feature Development:
1. **Análise de Requisitos**: Use prompts de design arquitetural
2. **Implementação**: Use prompts de geração de código
3. **Testes**: Use prompts para gerar testes unitários/integração
4. **Review**: Use personas de code review
5. **Deployment**: Use prompts de configuração DevSecOps

### Fluxo para Refatoração:
1. **Análise**: Use prompts de análise de repositório
2. **Priorização**: Use prompts de identificação de dívida técnica  
3. **Implementação**: Use prompts de refatoração guiada
4. **Validação**: Use prompts de geração de testes
5. **Documentação**: Use prompts de documentação técnica

Estes modelos avançados permitem cobrir praticamente todos os aspectos do ciclo de vida de desenvolvimento de software, desde a concepção até a manutenção em produção.



Modelos de Prompt para Deploy e Infraestrutura
📋 Guia de Utilização para Deploy
Modelos Recomendados:

CodeLlama (para scripts de deployment)

Mistral/Mixtral (para estratégias e conceitos)

WizardCoder (para automação CI/CD)

Configurações Ideais:

Temperature: 0.1-0.3 (para scripts precisos)

Temperature: 0.5-0.7 (para estratégias e planejamento)

🚀 Categoria: Análise de Prontidão para Deploy
1. Checklist de Pré-Deploy
Prompt:

text
[Instrução: Atue como um engenheiro de DevOps sênior com 10 anos de experiência]

Baseado no contexto abaixo, crie um checklist completo de pré-deploy para garantir uma implantação bem-sucedida:

**Contexto do Projeto:**
- Tipo de aplicação: [Web App/Mobile API/Microserviço]
- Ambiente de destino: [AWS/Azure/GCP/On-premise]
- Tecnologias: [Node.js + PostgreSQL/Java + MySQL/etc.]
- Equipe: [X desenvolvedores, Y ambientes]

**Solicito:**
1. **Checklist de Segurança** (10 itens críticos)
2. **Checklist de Performance** (5 métricas essenciais)
3. **Checklist de Configuração** (variáveis de ambiente, secrets)
4. **Checklist de Banco de Dados** (migrations, backups)
5. **Plano de Rollback** (condições e procedimentos)

Forneça em formato de tabela markdown com colunas: [Item, Descrição, Criticidade, Responsável]
2. Análise de Configuração para Produção
Prompt:

text
[Instrução: Atue como um SRE especializado em ambientes de produção]

Analise a seguinte configuração de deployment e identifique problemas potenciais:

**Arquivos de Configuração:**
```yaml
[COLE AQUI O docker-compose.yml OU Kubernetes deployment]
Variáveis de Ambiente:

bash
[COLE AQUI AS VARIÁVEIS DE AMBIENTE]
Solicito:

Problemas Imediatos (críticos para produção)

Recomendações de Otimização (recursos, limites)

Configurações de Segurança missing

Versionamento e tags inadequadas

Configuração revisada com as correções

text

---

## 🛠️ Categoria: Estratégias de Deploy

### 3. Escolha de Estratégia de Deploy
**Prompt:**
[Instrução: Atue como um arquiteto de cloud com expertise em estratégias de implantação]

Recomende a melhor estratégia de deploy para o seguinte cenário:

Contexto:

Aplicação: [Monolítico/Microserviços]

Tráfego: [X usuários simultâneos, pico às Y horas]

Requisitos de Disponibilidade: [Z% uptime]

Tolerância a Downtime: [Nenhuma/Mínima/Moderada]

Equipe: [Tamanho e experiência]

Solicito:

Análise Comparativa de estratégias:

Blue-Green vs Canary vs Rolling vs Recreate

Recomendação justificada

Diagrama da estratégia escolhida

Pré-requisitos para implementação

Riscos e mitigações

text

### 4. Configuração de Blue-Green Deployment
**Prompt:**
[Instrução: Atue como um engenheiro de AWS/Azure/GCP especializado em implantações de baixo risco]

Crie um script completo para implementar Blue-Green deployment para:

Tecnologias:

Cloud: [AWS ELB + Auto Scaling/Azure Load Balancer/GCP Cloud Load Balancing]

Aplicação: [Docker containers/VM-based]

Banco de Dados: [MySQL/PostgreSQL/MongoDB]

Solicito:

Script de Implantação (bash/powershell)

Script de Troca (switch between environments)

Script de Rollback

Monitoramento durante a transição

Validação pós-deploy

Inclua tratamentos de erro e logging adequado.

text

---

## 📊 Categoria: Deploy em Plataformas Específicas

### 5. Deploy no Kubernetes (EKS/GKE/AKS)
**Prompt:**
[Instrução: Atue como um engenheiro de Kubernetes certificado (CKA/CKAD)]

Gere os manifestos YAML completos para deploy em Kubernetes com melhores práticas:

Aplicação:

Nome: [my-app]

Port: [3000]

Recursos: [2CPU, 4GB RAM]

Replicas: [3]

Health checks: [Liveness, Readiness]

Requisitos:

ConfigMaps para configuração

Secrets management

Auto-scaling (HPA)

Resource limits

Service e Ingress

Probes configuradas

Solicito:

Deployment.yaml completo

Service.yaml

Ingress.yaml (com SSL)

HPA.yaml

ConfigMap.yaml

Instructions para aplicação

text

### 6. Deploy no AWS com Terraform
**Prompt:**
[Instrução: Atue como um engenheiro de DevOps especializado em Infrastructure as Code]

Crie configurações Terraform para deploy de uma aplicação web na AWS:

Stack Requerida:

VPC com subnets públicas e privadas

EC2 Auto Scaling Group ou ECS Fargate

RDS PostgreSQL

Application Load Balancer

CloudWatch logging e monitoring

S3 para assets

Solicito:

Arquitetura em diagrama

Variáveis (variables.tf)

Configurações principais (main.tf)

Outputs (outputs.tf)

Instruções de deploy (terraform apply)

text

### 7. Deploy no Azure DevOps
**Prompt:**
[Instrução: Atue como um especialista em Azure DevOps pipelines]

Crie um pipeline completo no Azure DevOps para CI/CD:

Processo:

Build: [Docker image/NuGet package]

Test: [Unit tests/Integration tests]

Scan: [Security scanning]

Deploy: [Para dev/staging/prod]

Solicito:

azure-pipelines.yml completo

Variáveis de Grupo recomendadas

Approval gates entre ambientes

Integração com monitoramento

Rollback automation

text

---

## 🔍 Categoria: Troubleshooting de Deploy

### 8. Diagnóstico de Falha no Deploy
**Prompt:**
[Instrução: Atue como um engenheiro de SRE especializado em troubleshooting]

Analise os logs de deploy abaixo e diagnostique a causa raiz do problema:

Logs de Deploy:

text
[COLE OS LOGS DE ERRO AQUI]
Contexto:

Plataforma: [Kubernetes/AWS ECS/Heroku]

Última mudança: [O que foi alterado?]

Solicito:

Diagnóstico da causa raiz

Passos para Resolução imediata

Prevenção para o futuro

Script de correção (se aplicável)

text

### 9. Rollback Automatizado
**Prompt:**
[Instrução: Atue como um engenheiro de confiabilidade (SRE)]

Desenvolva um script de rollback automatizado para:

Contexto:

Plataforma: [Kubernetes/AWS/Azure]

Método de deploy: [Blue-Green/Canary]

Indicadores de falha: [Latência > Xms, Error rate > Y%]

Solicito:

Script de Monitoramento contínuo

Condições para trigger de rollback

Script de Rollback automático

Notificações (Slack/Email)

Documentação pós-rollback

text

---

## 🏗️ Categoria: Deploy de Databases

### 10. Deploy e Migração de Database
**Prompt:**
[Instrução: Atue como um database administrator (DBA) especializado em migrações]

Planeje a estratégia de deploy para mudanças no banco de dados:

Contexto:

Database: [PostgreSQL 12 -> 14/MySQL 5.7 -> 8.0]

Tamanho: [XXX GB]

Downtime permitido: [Nenhum/Mínimo/Z horas]

Mudanças:

sql
[COLE AS ALTERAÇÕES SCHEMA AQUI]
Solicito:

Estratégia de Migração (com downtime/zero-downtime)

Scripts de Migração passo a passo

Plano de Rollback para database

Teste de Validação pós-migração

Monitoramento durante a migração

text

---

## 📝 Categoria: Documentação e Runbooks

### 11. Criando Runbooks de Deploy
**Prompt:**
[Instrução: Atue como um engenheiro de confiabilidade (SRE) experiente]

Crie um runbook completo para deploy em produção:

Estrutura Solicita:

Pré-requisitos e verificações

Comandos passo a passo

Verificações pós-deploy

Procedimento de Rollback

Lista de Contatos em caso de emergência

Contexto Específico:

Aplicação: [Nome e versão]

Equipe: [Plantão e responsáveis]

SLA: [Tempo máximo de recuperação]

Forneça em formato de tabela com timestamps e responsabilidades.

text

### 12. Documentação de Procedimentos de Emergência
**Prompt:**
[Instrução: Atue como um engenheiro de incident response]

Crie documentação para lidar com emergências durante deploy:

Cenários:

Deploy falha e aplicação não sobe

Deploy completo mas performance degradada

Deploy causa errors em cadeia

Data corruption durante deploy

Solicito:

Procedimentos passo a passo para cada cenário

Comunicação (o que dizer, para quem)

Decisão de rollback vs fix forward

Documentação pós-incidente

text

---

## 🎯 Tabela de Modelos por Plataforma

| Plataforma | Modelo Recomendado | Prompt Tipo |
|------------|-------------------|-------------|
| **Kubernetes** | CodeLlama 34B | Manifestos YAML |
| **AWS** | Mixtral 8x7B | Terraform/CloudFormation |
| **Azure** | WizardCoder 33B | Azure DevOps Pipelines |
| **GCP** | Mistral 7B | Deployment Manager |
| **Docker** | CodeLlama 13B | Dockerfiles e Compose |
| **Heroku** | Mistral 7B | App.json e scripts |
| **Serverless** | Mixtral 8x7B | SAM/Serverless Framework |

---

## 🔄 Fluxo de Deploy Seguro

### Pipeline Completo de CI/CD:
Análise de Código → Prompt 1 (Checklist pré-deploy)

Build e Test → Prompts específicos da plataforma

Deploy Staging → Prompt 3 (Estratégia de deploy)

Validação → Prompt 8 (Troubleshooting)

Deploy Produção → Prompt 4 (Blue-Green)

Monitoramento → Prompt 9 (Rollback automático)

Documentação → Prompt 11 (Runbooks)

text

### Comandos Úteis para Ollama/OpenWebUI:
```bash
# Para scripts de deploy (baixa temperatura)
ollama run codellama --temperature 0.1 --prompt "file:deploy-prompt.txt"

# Para estratégia e planejamento (temperatura média)  
ollama run mixtral --temperature 0.5 --prompt "file:deploy-strategy-prompt.txt"
Estes modelos cobrem todo o ciclo de vida do deploy, desde o planejamento até a resposta a incidentes, fornecendo uma base sólida para implantações seguras e eficientes.


📘 Biblioteca Completa de Prompts para Desenvolvedores
Para Ollama & Open WebUI

Este documento é um guia completo e organizado de prompts, criados para auxiliar desenvolvedores em diversas tarefas, desde a concepção de projetos até a manutenção e deploy.

Sumário
Análise e Revisão de Código

Refatoração e Reestruturação

Documentação

Segurança

Performance e Escalabilidade

DevOps e Infraestrutura

Bancos de Dados

APIs e Integrações

Cloud e Deploy

Aprendizado e Ensino

Planejamento e Gestão

Outros Prompts Úteis

UI/UX e Frontend

Machine Learning / Data Science

Testes Avançados

Observabilidade e Monitoramento

Integração com Negócio

Microserviços e Arquitetura

Automação e Scripting

Internacionalização e Localização

API Avançada

Integrações e Plugins

Confiabilidade e Resiliência

Roadmaps Técnicos

Git & GitHub

Versionamento e Lançamentos

Colaboração & Fluxos de Trabalho

Organização de Repositórios

Extras Úteis

Modelos de Prompts para Deploy e Infraestrutura

1. Análise e Revisão de Código
Prompt – Code Review Detalhado
Faça um code review do seguinte trecho de código: [código aqui]

Liste problemas de clareza, manutenção e estilo

Aponte possíveis bugs ou edge cases

Sugira melhorias

Explique como deixá-lo aderente ao padrão da linguagem (PEP8 no Python, ESLint no JS, etc.)

Prompt – Comparar Implementações
Compare as duas versões de código abaixo: [código versão A] e [código versão B]

Qual é mais eficiente?

Qual é mais legível?

Qual é mais fácil de manter?

Qual você recomenda e por quê?

2. Refatoração e Reestruturação
Prompt – Reestruturar Projeto
Tenho o seguinte projeto: [cole estrutura de diretórios ou link do repo]
Sugira uma nova organização de pastas e módulos para:

Melhorar a escalabilidade

Separar responsabilidades

Seguir boas práticas da linguagem/framework

Prompt – Refatoração Progressiva
Sugira um plano de refatoração progressiva para este projeto: [descrição ou código]
Inclua:

Mudanças imediatas (baixo risco, alto impacto)

Refatorações intermediárias

Reestruturações de longo prazo

Prompt – Transformar Código Procedural em Orientado a Objetos
Converta o seguinte código procedural em uma versão orientada a objetos: [código aqui]
Explique:

Quais classes e métodos criou

Como isso melhora manutenibilidade e reuso

3. Documentação
Prompt – Gerar README Profissional
Com base neste projeto: [código/descrição]
Crie um README.md contendo:

Nome e descrição

Tecnologias utilizadas

Instalação e execução

Exemplos de uso

Roadmap

Contribuições

Prompt – Documentação Automática
Analise o seguinte código e gere documentação automática em Markdown, incluindo:

Lista de funções/métodos com descrição

Parâmetros e retornos

Exemplos de uso

4. Segurança
Prompt – Security Review
Analise este código e identifique riscos de segurança: [código aqui]

Validação de entradas

Autenticação/autorização

Uso de dependências inseguras

Sugestões de correção

Prompt – Hardening
Sugira técnicas de hardening para este sistema: [descrição ou código]

Banco de dados

API

Infraestrutura

5. Performance e Escalabilidade
Prompt – Performance Profiling
Analise este código: [código aqui]

Identifique gargalos

Sugira estruturas de dados melhores

Reescreva o trecho mais crítico de forma otimizada

Prompt – Escalabilidade de API
Tenho esta API: [código ou descrição]
Como escalá-la para suportar milhares de usuários simultâneos?

Estratégias de cache

Load balancing

Sharding de banco

Uso de filas

6. DevOps e Infraestrutura
Prompt – Criar Dockerfile
Crie um Dockerfile otimizado para este projeto: [código ou estrutura de pastas]

Prompt – CI/CD Pipeline
Gere um pipeline de CI/CD no GitHub Actions para este projeto que:

Rode testes

Faça linting

Gere build

Faça deploy em staging

7. Bancos de Dados
Prompt – Modelagem
Crie um modelo de banco de dados para este sistema: [descrição do projeto]
Liste:

Tabelas

Relacionamentos

Tipos de dados

Prompt – Query Optimization
Otimize a seguinte query SQL: [query aqui]
Explique:

Problemas atuais

Índices recomendados

Alternativas mais eficientes

8. APIs e Integrações
Prompt – OpenAPI
Gere uma especificação OpenAPI (YAML) para os endpoints abaixo: [descrição ou código]

Prompt – Integração Externa
Explique como integrar este sistema com a API do [serviço X].
Forneça exemplos em Python usando httpx.

9. Cloud e Deploy
Prompt – Arquitetura Cloud
Sugira uma arquitetura na AWS para este projeto: [descrição]
Inclua:

Serviços

Custos estimados

Estratégia de escalabilidade

Prompt – Kubernetes
Crie manifestos Kubernetes (YAML) para rodar este serviço em produção: [imagem docker ou código]

10. Aprendizado e Ensino
Prompt – Explicar Código
Explique o seguinte código como se eu fosse um iniciante: [código aqui]

Prompt – Tutor de Conceito
Me ensine o conceito de [ex: programação reativa] com exemplos práticos em Python.

11. Planejamento e Gestão
Prompt – Roadmap
Crie um roadmap para este projeto: [descrição]
Inclua:

Features curto, médio e longo prazo

Priorização

Dependências

Prompt – User Stories
Com base neste sistema: [descrição]
Escreva user stories no formato: "Como [persona], quero [ação] para [benefício]".

12. Outros Prompts Úteis
Migrar de framework
Sugira como migrar este projeto de Flask para FastAPI: [código/descrição]

Converter linguagem
Converta este código Python para Go, mantendo a mesma lógica e boas práticas: [código aqui]

Gerar testes automáticos
Crie testes unitários para este código usando pytest: [código aqui]

Explicar logs de erro complexos
Explique este log de erro, possíveis causas e soluções: [log aqui]

13. UI/UX e Frontend
Prompt – Revisão de UI/UX
Analise esta interface web (HTML/CSS/JS): [código aqui]
Sugira melhorias de:

Acessibilidade (WCAG)

Responsividade

Usabilidade

Prompt – Componentização
Transforme este código em componentes reutilizáveis: [código frontend aqui]
Sugira:

Componentes básicos e compostos

Benefícios da componentização

14. Machine Learning / Data Science
Prompt – Data Cleaning
Analise este dataset (CSV/JSON): [exemplo de dados]

Identifique problemas (valores nulos, duplicados)

Sugira estratégias de limpeza

Gere código Python (pandas) para corrigir

Prompt – Escolha de Modelo
Tenho este problema: [descrição]
Sugira algoritmos de ML adequados e explique prós e contras de cada.

15. Testes Avançados
Prompt – Testes End-to-End
Crie testes E2E para esta aplicação web usando Playwright: [descrição ou código]

Prompt – Testes de Performance
Sugira um plano de testes de performance para esta API: [endpoints ou código]
Inclua:

Ferramentas recomendadas

Métricas a coletar

16. Observabilidade e Monitoramento
Prompt – Logs Estruturados
Transforme este código para usar logs estruturados (JSON): [código aqui]
Explique benefícios e como integrá-los com ELK Stack.

Prompt – Alertas
Sugira alertas importantes para monitorar este sistema em produção.

17. Integração com Negócio
Prompt – Geração de Relatórios
Gere um relatório executivo a partir desses dados técnicos: [logs, métricas ou código]
Explique em termos de negócio, sem jargões técnicos.

Prompt – User Journey
Com base neste sistema, descreva a jornada típica de um usuário final e identifique pontos de atrito.

18. Microserviços e Arquitetura
Prompt – Quebrar em Microserviços
Tenho este projeto monolítico: [descrição/código]
Sugira como quebrá-lo em microserviços.

Prompt – Mensageria
Explique como integrar RabbitMQ ou Kafka neste projeto para desacoplar serviços: [código/descrição]

19. Automação e Scripting
Prompt – Automação de Tarefas
Crie um script em Python que:

Leia arquivos em uma pasta

Extraia informações específicas

Gere um relatório em CSV

Prompt – CI/CD Avançado
Crie um pipeline CI/CD que:

Execute testes

Gere imagens Docker

Rode análise de segurança (SAST/DAST)

Faça deploy em Kubernetes

20. Internacionalização e Localização
Prompt – i18n
Adapte este projeto para suportar múltiplos idiomas: [código aqui]
Explique:

Onde usar placeholders

Como estruturar arquivos de tradução

21. API Avançada
Prompt – Versionamento
Sugira estratégia de versionamento para esta API: [endpoints/código]
Explique vantagens de cada abordagem.

Prompt – Rate Limiting
Adicione suporte a rate limiting nesta API: [código aqui]
Sugira bibliotecas ou middlewares para implementar.

22. Integrações e Plugins
Prompt – Integração com Pagamentos
Explique como integrar este sistema com a API do Stripe/PagSeguro/Pix.

Prompt – Plugin System
Sugira como transformar este projeto em um sistema com suporte a plugins: [descrição ou código]

23. Confiabilidade e Resiliência
Prompt – Retry Strategy
Implemente uma estratégia de retries com backoff exponencial para este código: [código aqui]

Prompt – Chaos Engineering
Sugira experimentos de Chaos Engineering para testar a resiliência deste sistema.

24. Roadmaps Técnicos
Prompt – Evolução Tecnológica
Crie um roadmap para migrar este projeto de monólito para microserviços em 12 meses.
Inclua:

Fases

Riscos

Métricas de sucesso

25. Git & GitHub
Prompt – Análise de Commits
Analise os seguintes commits e gere um resumo de mudanças em linguagem clara: [lista de commits]

Prompt – Estratégia de Branches
Sugira uma estratégia de branches para este projeto em GitHub: [descrição]

Prompt – PR Template
Crie um template de Pull Request para este projeto.

26. Versionamento e Lançamentos
Prompt – Estratégia de Versionamento
Defina uma estratégia de versionamento para este projeto: [descrição]
Explique como aplicar SemVer.

Prompt – Release Notes
Gere notas de release para a versão X.Y.Z deste projeto com base nos commits.

27. Colaboração & Fluxos de Trabalho
Prompt – Contributing.md
Crie um arquivo CONTRIBUTING.md para este projeto.

Prompt – Pair Programming AI
Atue como par de programação revisando este código linha a linha: [código aqui]

28. Organização de Repositórios
Prompt – Estrutura Multi-Repo vs Monorepo
Analise este projeto: [descrição]
Sugira se é melhor usar monorepo ou múltiplos repositórios.

Prompt – Submódulos
Explique como organizar este sistema usando Git Submodules ou Git Subtree.

29. Extras Úteis
Prompt – Comparar tecnologias
Compare [framework A] e [framework B] para este projeto: [descrição]

Prompt – Geração de Cheatsheet
Crie uma cheatsheet com comandos mais usados de [tecnologia X].

Prompt – Code Smells
Liste code smells neste código e como removê-los: [código aqui]

30. Modelos de Prompts para Deploy e Infraestrutura
Prompt – Checklist de Deploy
Quero fazer o deploy de uma aplicação FastAPI em um servidor Ubuntu.
Liste todos os passos necessários, incluindo:

Instalação de dependências

Configuração do ambiente

Configuração do banco

Servidor WSGI/ASGI

Nginx

Boas práticas de segurança

Prompt – Dockerfile otimizado
Analise meu projeto Python abaixo e gere um Dockerfile otimizado: [código/projeto aqui]

Usar multistage build

Fixar dependências

Prompt – Deploy com Kubernetes
Crie os manifests YAML para rodar minha aplicação FastAPI no Kubernetes, incluindo Deployment, Service e Ingress.

Prompt – Diagnóstico de Falha
Analise os logs de deploy abaixo e diagnostique a causa raiz do problema: [logs de erro aqui]

Guia de Utilização Avançada
Especificação de Modelo: Inicie prompts complexos com [Instrução: Atue como [especialista] com [X] anos de experiência em [tecnologia]].

Fornecimento de Contexto: Use o recurso de upload de arquivos da OpenWebUI para fornecer projetos completos.

Configuração de Personas: Crie personas especializadas na OpenWebUI para diferentes funções (Code Reviewer Sênior, System Architect, etc.).

Temperatura: Ajuste para valores baixos (0.1-0.3) para código e altos (0.7-0.9) para brainstorming.







📚 Biblioteca de Prompts para Desenvolvedores - Versão Expandida
================================================================

Para Ollama & Open WebUI

Este documento é um guia completo e organizado de prompts, criado para auxiliar desenvolvedores em todas as fases do ciclo de vida de software, com foco em tarefas técnicas e de gestão.

## 📖 Sumário

1.  [Análise e Revisão de Código](#1-análise-e-revisão-de-código)
2.  [Refatoração e Reestruturação](#2-refatoração-e-reestruturação)
3.  [Documentação](#3-documentação)
4.  [Segurança](#4-segurança)
5.  [Performance e Escalabilidade](#5-performance-e-escalabilidade)
6.  [DevOps e Infraestrutura](#6-devops-e-infraestrutura)
7.  [Bancos de Dados](#7-bancos-de-dados)
8.  [APIs e Integrações](#8-apis-e-integrações)
9.  [Cloud e Deploy](#9-cloud-e-deploy)
10. [Aprendizado e Ensino](#10-aprendizado-e-ensino)
11. [Planejamento e Gestão](#11-planejamento-e-gestão)
12. [UI/UX e Frontend](#12-uiux-e-frontend)
13. [Machine Learning / Data Science](#13-machine-learning--data-science)
14. [Testes Avançados](#14-testes-avançados)
15. [Observabilidade e Monitoramento](#15-observabilidade-e-monitoramento)
16. [Integração com Negócio](#16-integração-com-negócio)
17. [Microserviços e Arquitetura](#17-microserviços-e-arquitetura)
18. [Automação e Scripting](#18-automação-e-scripting)
19. [Internacionalização e Localização](#19-internacionalização-e-localização)
20. [Git & GitHub](#20-git--github)
21. [Soft Skills e Carreira](#21-soft-skills-e-carreira)
22. [Desenvolvimento Mobile (iOS/Android)](#22-desenvolvimento-mobile-iosandroid)
23. [Data Engineering](#23-data-engineering)
24. [Web3 e Blockchain](#24-web3-e-blockchain)
25. [FinOps (Gestão de Custos em Cloud)](#25-finops-gestão-de-custos-em-cloud)
26. [Troubleshooting Avançado](#26-troubleshooting-avançado)
27. [Modelos de Prompts Úteis](#27-modelos-de-prompts-úteis)

---

Com certeza. O documento que você forneceu é um excelente ponto de partida. Eu organizei, aprimorei e expandi a lista de prompts para incluir áreas essenciais que estavam faltando ou poderiam ser aprofundadas.

A nova versão abrange temas como Machine Learning (MLOps), desenvolvimento mobile, Web3, FinOps, além de prompts focados em soft skills e carreira.

Aqui está o documento aprimorado, pronto para ser usado:

## 1. Análise e Revisão de Código
Prompt – Code Review Detalhado
Faça um code review do seguinte trecho de código: [código aqui]

Liste problemas de clareza, manutenção e estilo.

Aponte possíveis bugs, vulnerabilidades de segurança ou edge cases.

Sugira melhorias com exemplos de código.

Explique como deixá-lo aderente ao padrão da linguagem (PEP8, ESLint, etc.).

Prompt – Comparar Implementações
Compare as duas versões de código abaixo: [código versão A] e [código versão B]

Qual é mais eficiente em termos de tempo de execução e uso de memória?

Qual é mais legível e fácil de manter?

Qual você recomenda para um ambiente de produção e por quê?

## 2. Refatoração e Reestruturação
Prompt – Reestruturar Projeto
Tenho o seguinte projeto: [cole estrutura de diretórios ou link do repo]
Sugira uma nova organização de pastas e módulos para:

Melhorar a escalabilidade e a modularidade.

Separar responsabilidades (MVC, Hexagonal, etc.).

Seguir as melhores práticas da linguagem/framework.

Prompt – Refatoração Progressiva
Sugira um plano de refatoração progressiva para este projeto: [descrição ou código]
Inclua:

Mudanças imediatas (baixo risco, alto impacto).

Refatorações intermediárias.

Reestruturações de longo prazo.

Prompt – Transformar Código Procedural em Orientado a Objetos
Converta o seguinte código procedural em uma versão orientada a objetos: [código aqui]
Explique:

Quais classes e métodos foram criados.

Como a nova estrutura melhora a manutenibilidade e o reuso.

## 3. Documentação
Prompt – Gerar README Profissional
Com base neste projeto: [código/descrição]
Crie um README.md completo, incluindo:

Nome e descrição do projeto.

Tecnologias utilizadas.

Seções de instalação, configuração e execução.

Exemplos de uso claros.

Roadmap e seção de contribuições.

Prompt – Documentação de API
Analise o seguinte código de API e gere a documentação em Markdown para os endpoints, incluindo:

Métodos (GET, POST, etc.) e URLs.

Parâmetros de requisição e corpo da requisição.

Possíveis códigos de status de resposta.

Exemplos de requisição e resposta.

## 4. Segurança
Prompt – Security Review
Analise este código e identifique riscos de segurança: [código aqui]

Validação de entradas (prevenção de injeção de SQL, XSS, etc.).

Gerenciamento de segredos e autenticação.

Uso de dependências inseguras.

Sugestões de correção e bibliotecas recomendadas.

Prompt – Hardening de Sistema
Sugira técnicas de hardening (endurecimento) para este sistema: [descrição ou código]

Recomendações para bancos de dados, APIs e infraestrutura.

Uso de least privilege.

Estratégias de monitoramento de segurança.

## 5. Performance e Escalabilidade
Prompt – Análise de Performance
Analise este código: [código aqui]

Identifique gargalos e ineficiências.

Sugira estruturas de dados ou algoritmos mais adequados.

Reescreva o trecho mais crítico de forma otimizada.

Prompt – Escalabilidade de API
Tenho esta API: [código ou descrição]
Como escalá-la para suportar milhões de requisições por dia?

Estratégias de cache (Redis, memcached).

Load balancing.

Sharding e replicação de banco de dados.

Uso de filas de mensagem (RabbitMQ, Kafka).

## 6. DevOps e Infraestrutura
Prompt – Criar Dockerfile
Crie um Dockerfile otimizado para este projeto, seguindo as melhores práticas: [código ou estrutura de pastas]

Use multistage build para reduzir o tamanho da imagem.

Organize as camadas para otimizar o cache.

Configure variáveis de ambiente e volumes.

Prompt – CI/CD Pipeline Avançado
Gere um pipeline de CI/CD para GitHub Actions para este projeto que:

Execute testes unitários e de integração.

Faça análise estática de código (linters, SAST).

Gere o build e a imagem Docker.

Faça deploy automático em um ambiente de staging.

Inclua um processo de aprovação manual para o deploy em produção.

## 7. Bancos de Dados
Prompt – Modelagem de Banco de Dados
Crie um modelo de banco de dados (relacional ou NoSQL) para este sistema: [descrição do projeto]
Liste:

Tabelas, coleções ou entidades.

Relacionamentos e índices.

Tipos de dados e restrições.

Justifique a escolha do modelo de banco (PostgreSQL, MongoDB, etc.).

Prompt – Otimização de Query
Otimize a seguinte query SQL: [query aqui]
Explique:

Problemas de performance na query original.

Quais índices seriam úteis.

Alternativas mais eficientes.

## 8. APIs e Integrações
Prompt – Especificação OpenAPI
Gere uma especificação OpenAPI (anteriormente Swagger) em YAML para os endpoints abaixo: [descrição ou código]

Prompt – Estratégia de Versionamento
Sugira uma estratégia de versionamento para esta API (/v1/, header, etc.) e explique as vantagens e desvantagens de cada abordagem.

Prompt – Integração Externa
Explique como integrar este sistema com a API do [serviço X, ex: Stripe, Slack] em [linguagem/framework].

## 9. Cloud e Deploy
Prompt – Arquitetura na AWS
Sugira uma arquitetura na AWS para este projeto: [descrição]

Inclua os serviços recomendados (EC2, ECS, Lambda, etc.).

Descreva a topologia da rede (VPC, subnets, etc.).

Estime os custos e sugira estratégias de otimização (FinOps).

Prompt – Manifestos Kubernetes
Crie manifestos Kubernetes (YAML) para rodar este serviço em produção, incluindo:

Deployment

Service para expor o serviço

Ingress com TLS

ConfigMap e Secret para variáveis de ambiente.

## 10. Aprendizado e Ensino
Prompt – Explicar Código Complexo
Explique o seguinte código como se eu fosse um iniciante na área: [código aqui]

Divida em partes menores e mais fáceis de entender.

Use analogias e exemplos práticos.

Prompt – Tutor de Conceito
Me ensine o conceito de [ex: Programação Funcional] com exemplos práticos em [linguagem].

Explique os princípios (imutabilidade, funções de primeira classe, etc.).

Mostre a diferença com a abordagem imperativa.

## 11. Planejamento e Gestão
Prompt – Roadmap de Projeto
Crie um roadmap detalhado para este projeto: [descrição]

Divida em fases (curto, médio, longo prazo).

Priorize features usando uma matriz de impacto/esforço.

Identifique dependências e riscos.

Prompt – Geração de User Stories
Com base neste sistema: [descrição]
Escreva user stories no formato: "Como [persona], quero [ação] para [benefício]".

## 12. UI/UX e Frontend
Prompt – Revisão de Acessibilidade
Analise esta interface web (HTML/CSS/JS): [código aqui]

Sugira melhorias para conformidade com WCAG (Web Content Accessibility Guidelines).

Aponte problemas de navegação para usuários de leitores de tela.

Prompt – Componentização
Transforme este código em componentes reutilizáveis, seguindo o padrão de design [ex: Atomic Design].

Liste os componentes básicos, como botões e inputs.

Mostre como compor componentes maiores, como um formulário.

## 13. Machine Learning / Data Science
Prompt – Engenharia de Dados
Analise este dataset (CSV/JSON): [exemplo de dados]

Identifique problemas (valores nulos, duplicados, outliers).

Sugira estratégias de limpeza e pré-processamento.

Gere um script Python (usando pandas ou PySpark) para realizar as transformações.

Prompt – Escolha de Modelo ML
Tenho este problema: [descrição do problema, ex: previsão de churn]

Sugira 3 algoritmos de Machine Learning adequados.

Explique os prós e contras de cada um e qual seria a melhor escolha.

## 14. Testes Avançados
Prompt – Testes End-to-End
Crie testes E2E (End-to-End) para esta aplicação web usando Playwright ou Cypress: [descrição ou código]

Prompt – Testes de Performance
Sugira um plano de testes de performance para esta API: [endpoints ou código]

Inclua ferramentas recomendadas (JMeter, k6).

Defina métricas a coletar (latência, throughput, taxa de erros).

## 15. Observabilidade e Monitoramento
Prompt – Logs Estruturados
Transforme este código para usar logs estruturados (JSON): [código aqui]

Explique os benefícios de logs estruturados.

Mostre como integrar com sistemas como ELK Stack ou Grafana Loki.

Prompt – Alertas Críticos
Sugira alertas importantes para monitorar este sistema em produção, incluindo:

Métricas de sistema (CPU, memória, disco).

Métricas de aplicação (taxa de erros, latência, throughput).

Recomendações de ferramentas (Prometheus, Grafana, Datadog).

## 16. Integração com Negócio
Prompt – Geração de Relatórios Executivos
Gere um relatório executivo a partir destes dados técnicos: [logs, métricas ou código]

Explique em termos de negócio, sem jargões técnicos.

Apresente os resultados e sugira próximos passos.

Prompt – Análise de User Journey
Com base neste sistema, descreva a jornada típica de um usuário final.

Identifique pontos de atrito ou frustração.

Sugira melhorias para cada etapa da jornada.

## 17. Microserviços e Arquitetura
Prompt – Quebrar em Microserviços
Tenho este projeto monolítico: [descrição/código]

Sugira como quebrá-lo em microserviços.

Defina os limites de cada serviço.

Aborde a comunicação entre os serviços (síncrona vs. assíncrona).

Prompt – Mensageria Assíncrona
Explique como integrar RabbitMQ ou Kafka neste projeto para desacoplar serviços: [código/descrição]

Descreva o conceito de Produtores, Consumers e Filas/Tópicos.

Forneça exemplos de código para enviar e consumir mensagens.

## 18. Automação e Scripting
Prompt – Automação de Tarefas
Crie um script em Python que:

Leia arquivos em uma pasta.

Extraia informações específicas (ex: datas, IDs).

Gere um relatório em CSV ou JSON com os dados.

Prompt – GitOps e IaC
Explique o conceito de GitOps e como ele pode ser aplicado a este projeto.

Inclua o uso de ferramentas como ArgoCD e Terraform.

## 19. Internacionalização e Localização
Prompt – i18n para Projeto Web
Adapte este projeto para suportar múltiplos idiomas: [código aqui]

Explique onde usar placeholders para textos.

Mostre a estrutura de arquivos de tradução (ex: JSON).

Prompt – L10n
Sugira como adaptar este projeto para a localização (L10n) de [país] e [idioma], considerando formatos de data, moeda e fuso horário.

## 20. Git & GitHub
Prompt – Estratégia de Branches
Sugira uma estratégia de branches para este projeto (ex: Git Flow, Trunk-Based Development) e justifique a escolha.

Prompt – Template de Pull Request
Crie um template de Pull Request (PULL_REQUEST_TEMPLATE.md) que force a inclusão de:

Descrição das mudanças.

Issues relacionadas.

Checklists para testes.

## 21. Soft Skills e Carreira
Prompt – Otimizar Currículo
Analise o seguinte trecho de currículo: [texto do currículo]

Reescreva as experiências para focar em resultados quantificáveis.

Sugira palavras-chave relevantes para a área.

Prompt – Roteiro de Entrevista Técnica
Crie um roteiro de entrevista técnica para a posição de [ex: Desenvolvedor Back-end Sênior] com perguntas sobre:

Estruturas de dados.

Algoritmos.

Design de sistemas.

Resolução de problemas.

## 22. Desenvolvimento Mobile (iOS/Android)
Prompt – Arquitetura Mobile
Sugira uma arquitetura limpa (Clean Architecture) para um projeto mobile em [plataforma, ex: Android]

Explique as camadas de Domínio, Dados e Apresentação.

Dê exemplos de como organizar os módulos.

Prompt – Testes para Mobile
Crie um plano de testes para um aplicativo mobile.

Inclua testes unitários, de integração e UI.

Sugira frameworks de testes (XCTest para iOS, JUnit para Android).

## 23. Data Engineering
Prompt – Pipeline de Dados
Crie um plano para construir um pipeline de dados que:

Extraia dados de [fonte, ex: API]

Transforme os dados.

Carregue em um [destino, ex: Data Warehouse].

Sugira ferramentas (Apache Airflow, dbt, Dagster).

Prompt – Modelagem Dimensional
Modele um Data Warehouse para este cenário: [descrição]

Inclua tabelas de fatos e dimensões.

Defina as chaves e os relacionamentos.

## 24. Web3 e Blockchain
Prompt – Contrato Inteligente
Escreva um contrato inteligente em [linguagem, ex: Solidity] para um [tipo de projeto, ex: token ERC-20].

Inclua funções de transferência e aprovação.

Adicione comentários de segurança.

Prompt – DApp Frontend
Crie um frontend básico em [framework, ex: React] para interagir com um contrato inteligente [endereço do contrato].

Use bibliotecas como ethers.js ou web3.js.

## 25. FinOps (Gestão de Custos em Cloud)
Prompt – Otimização de Custos
Analise esta arquitetura na AWS ([descrição da arquitetura]) e sugira estratégias para otimizar custos.

Foco em instâncias, armazenamento e serviços.

Recomende o uso de instâncias reservadas ou spot instances.

Prompt – Relatório de Gastos
Gere um relatório de gastos com base em dados de [plataforma de cloud] e sugira otimizações.

## 26. Troubleshooting Avançado
Prompt – Diagnóstico de Erros
Analise este log de erro complexo: [log aqui]

Explique a causa raiz.

Liste os possíveis cenários que levaram ao erro.

Sugira um plano de ação para resolver e prevenir futuras ocorrências.

Prompt – Decisão de Rollback vs. Rollforward
Analisando o incidente [descrição] em produção, qual a melhor estratégia: rollback para a versão anterior ou um hotfix (rollforward)? Justifique.

## 27. Modelos de Prompts Úteis
Prompt – Geração de Cheatsheet
Crie uma cheatsheet com os comandos mais usados de [tecnologia X, ex: Docker, Git, Linux].

Prompt – Comparar Tecnologias
Compare [framework A] e [framework B] para este projeto: [descrição]

Liste os prós e contras de cada um.

Sugira a melhor escolha com base nos requisitos.

Guia de Utilização Avançada
Especificação de Modelo: Inicie prompts complexos com [Instrução: Atue como [especialista] com [X] anos de experiência em [tecnologia]].

Fornecimento de Contexto: Use o recurso de upload de arquivos da OpenWebUI para fornecer projetos completos.

Configuração de Personas: Crie personas especializadas na OpenWebUI para diferentes funções (Code Reviewer Sênior, System Architect, Data Engineer).

Temperatura: Ajuste para valores baixos (0.1-0.3) para código e altos (0.7-0.9) para brainstorming.
