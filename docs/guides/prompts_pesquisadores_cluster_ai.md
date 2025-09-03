# 🔬 Catálogo de Prompts para Pesquisadores Acadêmicos

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para análise sistemática, revisões de literatura
- **Temperatura Média (0.4-0.6)**: Para síntese de informações, planejamento de pesquisa
- **Temperatura Alta (0.7-0.9)**: Para geração de hipóteses, ideias inovadoras

### Modelos por Categoria
- **LLM Geral**: Llama 3, Mixtral (análise, síntese)
- **Especializados**: Mixtral (pesquisa acadêmica)
- **Código**: CodeLlama (análise de dados, estatística)

---

## 📁 CATEGORIA: REVISÃO DE LITERATURA

### 1. Levantamento Sistemático da Literatura
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em revisões sistemáticas de literatura]

Desenvolva um protocolo completo para revisão sistemática:

**Tema de pesquisa:**
- **Pergunta de pesquisa:** [PICO ou similar]
- **Bases de dados:** [PubMed, Scopus, Web of Science, etc.]
- **Período:** [últimos 5-10 anos]
- **Idioma:** [português, inglês, espanhol]

**Solicito:**
1. **Pergunta de pesquisa** bem definida
2. **Estratégia de busca** detalhada
3. **Critérios de inclusão/exclusão** objetivos
4. **Processo de seleção** de artigos
5. **Extração de dados** sistemática
6. **Síntese qualitativa** dos achados
7. **Avaliação de qualidade** metodológica
```

### 2. Análise Crítica de Artigo Científico
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um revisor experiente de artigos científicos]

Realize uma análise crítica completa de um artigo científico:

**Informações do artigo:**
- **Título e autores:** [informações básicas]
- **Revista/Periódico:** [qualis, impacto]
- **Ano de publicação:** [atualidade]
- **Metodologia utilizada:** [qualitativa/quantitativa/mista]

**Solicito:**
1. **Avaliação da relevância** do tema
2. **Análise da metodologia** e adequação
3. **Crítica aos resultados** e interpretação
4. **Avaliação das limitações** reconhecidas
5. **Contribuições originais** para a área
6. **Implicações práticas** e teóricas
7. **Sugestões de pesquisa** futura
```

### 3. Mapeamento Sistemático (Scoping Review)
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em mapeamento sistemático]

Desenvolva um protocolo para mapeamento sistemático da literatura:

**Objetivos do mapeamento:**
- **Amplitude do tema:** [delimitação do escopo]
- **Objetivo principal:** [mapear evidências, identificar gaps]
- **Stakeholders:** [pesquisadores, profissionais, policymakers]

**Solicito:**
1. **Justificativa metodológica** do mapeamento
2. **Estratégia de busca** abrangente
3. **Processo de seleção** iterativo
4. **Extração de dados** qualitativa
5. **Síntese narrativa** dos achados
6. **Identificação de gaps** de pesquisa
7. **Implicações para prática** e política
```

---

## 📁 CATEGORIA: DESENVOLVIMENTO DE PROJETOS

### 4. Elaboração de Projeto de Pesquisa
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um consultor de projetos de pesquisa experiente]

Desenvolva um projeto de pesquisa completo e viável:

**Parâmetros do projeto:**
- **Título preliminar:** [tema específico]
- **Área de conhecimento:** [grande área CNPq]
- **Prazo de execução:** [12-48 meses]
- **Recursos necessários:** [bolsas, equipamentos, softwares]

**Solicito:**
1. **Introdução e justificativa** contextualizada
2. **Objetivos específicos** e mensuráveis
3. **Revisão de literatura** atualizada
4. **Metodologia detalhada** e adequada
5. **Cronograma de atividades** realista
6. **Orçamento detalhado** e justificativas
7. **Produtos esperados** (artigos, patentes, software)
```

### 5. Formulação de Hipóteses de Pesquisa
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um epistemólogo especializado em pesquisa científica]

Ajude na formulação de hipóteses científicas bem estruturadas:

**Contexto da pesquisa:**
- **Problema de pesquisa:** [questão central]
- **Variáveis independentes:** [fatores manipuláveis]
- **Variáveis dependentes:** [resultados esperados]
- **Variáveis de controle:** [fatores a controlar]

**Solicito:**
1. **Hipóteses principais** testáveis
2. **Hipóteses alternativas** (nula e contrária)
3. **Justificativa teórica** das hipóteses
4. **Operacionalização** das variáveis
5. **Método de teste** apropriado
6. **Poder estatístico** da análise
7. **Limitações potenciais** das hipóteses
```

### 6. Planejamento de Coleta de Dados
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em métodos de pesquisa quantitativa]

Desenvolva um plano detalhado de coleta de dados:

**Tipo de pesquisa:**
- **Abordagem:** [quantitativa/qualitativa/mista]
- **Método:** [experimental, survey, estudo de caso]
- **População e amostra:** [tamanho, critérios de seleção]

**Solicito:**
1. **Instrumentos de coleta** adequados
2. **Procedimentos de aplicação** padronizados
3. **Piloto e validação** dos instrumentos
4. **Controle de viés** e qualidade dos dados
5. **Análise preliminar** do poder estatístico
6. **Plano de contingência** para problemas
7. **Aspectos éticos** da coleta de dados
```

---

## 📁 CATEGORIA: ANÁLISE DE DADOS E ESTATÍSTICA

### 7. Análise Estatística Avançada
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um estatístico especializado em pesquisa acadêmica]

Desenvolva uma análise estatística completa para dados de pesquisa:

**Características dos dados:**
- **Tipo de variável:** [contínua, categórica, ordinal]
- **Distribuição:** [normal, não-normal, assimétrica]
- **Tamanho da amostra:** [n pequeno/médio/grande]
- **Número de grupos:** [comparação simples/múltipla]

**Solicito:**
1. **Análise descritiva** completa (médias, desvios, distribuições)
2. **Testes de normalidade** e adequação dos dados
3. **Testes inferenciais** apropriados (t-test, ANOVA, regressão)
4. **Análise de poder** e tamanho do efeito
5. **Validação de pressupostos** estatísticos
6. **Correção para múltiplas comparações** (Bonferroni, etc.)
7. **Interpretação prática** dos resultados
```

### 8. Modelagem Estatística e Machine Learning
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em modelagem estatística]

Desenvolva modelos estatísticos/ML para análise de dados de pesquisa:

**Objetivo da modelagem:**
- **Tipo de problema:** [regressão, classificação, clustering]
- **Variáveis preditoras:** [quantidade e tipo]
- **Métrica de avaliação:** [R², AUC, silhueta]

**Solicito:**
1. **Pré-processamento** adequado dos dados
2. **Seleção de modelos** candidatos
3. **Comparação de performance** entre modelos
4. **Validação cruzada** e teste hold-out
5. **Interpretabilidade** dos modelos
6. **Diagnóstico de overfitting/underfitting**
7. **Implementação prática** em Python/R
```

### 9. Meta-análise e Síntese de Evidências
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em meta-análise]

Desenvolva um protocolo para meta-análise de estudos:

**Tema da meta-análise:**
- **Intervenção:** [tratamento, método, tecnologia]
- **Desfecho principal:** [resultado de interesse]
- **Tipo de estudo:** [RCTs, coortes, estudos transversais]

**Solicito:**
1. **Critérios de elegibilidade** rigorosos
2. **Estratégia de busca** abrangente
3. **Avaliação de risco de viés** (Cochrane, Newcastle-Ottawa)
4. **Extração de dados** padronizada
5. **Análise estatística** (modelos de efeito fixo/aleatório)
