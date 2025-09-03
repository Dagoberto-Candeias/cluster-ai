# 🧠 Catálogo de Prompts para Aprendizado em IA e Data Science

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para explicações técnicas precisas, debugging
- **Temperatura Média (0.4-0.6)**: Para tutoriais passo-a-passo, projetos práticos
- **Temperatura Alta (0.7-0.9)**: Para geração de ideias criativas, exploração de conceitos

### Modelos por Categoria
- **LLM Geral**: Llama 3, Mixtral
- **Código e Tutoriais**: CodeLlama, Qwen2.5-Coder, DeepSeek-Coder

---

## 📁 CATEGORIA: FUNDAMENTOS DE IA E MACHINE LEARNING

### 1. Introdução aos Conceitos Básicos
**Modelo**: Llama 3/Mixtral

```
[Instrução: Atue como um professor de IA acessível e paciente]

Explique os conceitos fundamentais de Inteligência Artificial para iniciantes:

**Tópicos a cobrir:**
- O que é IA, ML e Deep Learning?
- Diferenças entre IA fraca e forte
- Tipos de aprendizado (supervisionado, não supervisionado, por reforço)
- Exemplos práticos do dia a dia

**Nível do aluno:** [absolutamente iniciante/intermediário/avançado]
**Estilo de explicação:** [simples/técnico/com exemplos práticos]

**Solicito:**
1. **Explicação conceitual** clara e acessível
2. **Analogias do mundo real** para facilitar compreensão
3. **Exemplos práticos** de aplicações
4. **Recursos adicionais** para aprofundamento
5. **Exercícios práticos** para fixação
```

### 2. Matemática Essencial para IA
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um tutor de matemática aplicada à IA]

Ensine os conceitos matemáticos fundamentais necessários para IA:

**Áreas matemáticas:**
- Álgebra Linear (vetores, matrizes, operações)
- Cálculo (derivadas, gradientes, otimização)
- Probabilidade e Estatística (distribuições, inferência)
- Otimização (gradiente descendente, funções de custo)

**Contexto prático:** [relacionar com algoritmos de ML]
**Nível de profundidade:** [conceitual/prático/avançado]

**Solicito:**
1. **Explicação intuitiva** dos conceitos
2. **Aplicações práticas** em algoritmos de ML
3. **Exercícios resolvidos** passo-a-passo
4. **Ferramentas e bibliotecas** para implementação
5. **Projetos práticos** para aplicação
```

### 3. Python para Data Science e IA
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um instrutor de Python para ciência de dados]

Ensine Python com foco em aplicações de IA e Data Science:

**Tópicos fundamentais:**
- Sintaxe básica e estruturas de dados
- NumPy para computação numérica
- Pandas para manipulação de dados
- Matplotlib/Seaborn para visualização

**Projeto prático:** [análise de dataset simples/classificação básica]
**Pré-requisitos:** [nenhum/básico de programação]

**Solicito:**
1. **Introdução à sintaxe** Python
2. **Bibliotecas essenciais** para DS/AI
3. **Projeto completo** do início ao fim
4. **Boas práticas** de código
5. **Recursos para prática** adicional
```

---

## 📁 CATEGORIA: MACHINE LEARNING PRÁTICO

### 4. Algoritmos de Classificação
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em algoritmos de ML]

Ensine algoritmos de classificação com implementação prática:

**Algoritmos a cobrir:**
- Regressão Logística
- Árvores de Decisão e Random Forest
- SVM (Support Vector Machines)
- KNN (K-Nearest Neighbors)
- Redes Neurais para Classificação

**Dataset:** [iris/dígitos MNIST/clientes bancários/etc.]
**Métricas:** [accuracy, precision, recall, F1-score]

**Solicito:**
1. **Explicação teórica** de cada algoritmo
2. **Implementação em Python** com scikit-learn
3. **Comparação de performance** entre algoritmos
4. **Tuning de hiperparâmetros** e otimização
5. **Casos de uso** reais para cada algoritmo
```

### 5. Algoritmos de Regressão
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em modelos de regressão]

Ensine técnicas de regressão para previsão de valores contínuos:

**Técnicas de regressão:**
- Regressão Linear Simples e Múltipla
- Regressão Polinomial
- Ridge e Lasso Regression
- Regressão com Árvores (Decision Trees, Random Forest)
- SVR (Support Vector Regression)

**Aplicações práticas:** [preço de imóveis/salários/previsão de vendas]
**Métricas de avaliação:** [MSE, RMSE, MAE, R²]

**Solicito:**
1. **Fundamentos matemáticos** de cada técnica
2. **Implementação prática** em Python
3. **Análise de resíduos** e validação de modelos
4. **Feature engineering** e seleção de variáveis
5. **Comparação e escolha** do melhor modelo
```

### 6. Técnicas de Pré-processamento de Dados
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em preparação de dados]

Ensine técnicas essenciais de pré-processamento para ML:

**Técnicas de limpeza:**
- Tratamento de valores ausentes
- Detecção e tratamento de outliers
- Codificação de variáveis categóricas
- Normalização e padronização

**Feature Engineering:**
- Criação de novas features
- Seleção de features importantes
- Redução de dimensionalidade (PCA)
- Transformações não lineares

**Solicito:**
1. **Pipeline completo** de pré-processamento
2. **Implementação prática** com pandas/sklearn
3. **Impacto no desempenho** dos modelos
4. **Técnicas avançadas** de feature engineering
5. **Boas práticas** e armadilhas comuns
```

---

## 📁 CATEGORIA: DEEP LEARNING E REDES NEURAIS

### 7. Redes Neurais Artificiais Básicas
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um professor de Deep Learning]

Ensine os fundamentos de redes neurais artificiais:

**Conceitos fundamentais:**
- Neurônios e camadas
- Funções de ativação
- Propagação para frente e para trás
- Otimização com gradiente descendente

**Framework:** [TensorFlow/PyTorch/Keras]
**Aplicação prática:** [classificação de imagens/previsão]

**Solicito:**
1. **Explicação intuitiva** do funcionamento
2. **Implementação passo-a-passo** de uma RNA simples
3. **Visualização** do processo de treinamento
4. **Tuning de hiperparâmetros** e arquitetura
5. **Debugging** de problemas comuns
```

### 8. Redes Neurais Convolucionais (CNN)
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em Computer Vision]

Ensine Convolutional Neural Networks para visão computacional:

**Conceitos de CNN:**
- Camadas convolucionais e pooling
- Arquiteturas modernas (ResNet, EfficientNet)
- Transfer Learning com modelos pré-treinados
- Data Augmentation para imagens

**Aplicações:** [classificação de imagens/detecção de objetos/segmentação]
**Datasets:** [CIFAR-10/ImageNet/MNIST]

**Solicito:**
1. **Fundamentos matemáticos** das convoluções
2. **Implementação prática** com PyTorch/TensorFlow
3. **Arquiteturas avançadas** e melhores práticas
4. **Otimização de performance** e eficiência
5. **Projetos completos** de visão computacional
```

### 9. Processamento de Linguagem Natural (NLP)
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em NLP]

Ensine técnicas de Processamento de Linguagem Natural:

**Técnicas fundamentais:**
- Tokenização e pré-processamento de texto
- Bag of Words e TF-IDF
- Word Embeddings (Word2Vec, GloVe)
- Modelos de linguagem (BERT, GPT)

**Aplicações práticas:** [análise de sentimento/classificação de texto/geração de texto]
**Bibliotecas:** [NLTK, spaCy, Transformers]

**Solicito:**
1. **Pipeline completo** de processamento de texto
2. **Implementação de modelos** clássicos e modernos
3. **Fine-tuning** de modelos pré-treinados
4. **Avaliação de performance** em tarefas de NLP
5. **Casos de uso** reais e aplicações práticas
```

---

## 📁 CATEGORIA: PROJETOS PRÁTICOS E APLICAÇÕES

### 10. Projeto Completo de Classificação
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um mentor de projeto de ML]

Guie o desenvolvimento de um projeto completo de classificação:

**Problema de negócio:** [fraude em cartões/previsão de churn/análise de crédito]
**Dataset:** [disponibilizar ou sugerir fonte]
**Requisitos:** [accuracy mínimo, interpretabilidade]

**Stack tecnológico:** [Python, scikit-learn, pandas, etc.]

**Solicito:**
1. **Análise exploratória** completa dos dados
2. **Pré-processamento** e feature engineering
3. **Comparação de algoritmos** e seleção do melhor
4. **Otimização de hiperparâmetros** e validação
5. **Deployment** e monitoramento do modelo
```

### 11. Sistema de Recomendação
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em sistemas de recomendação]

Ensine a construir sistemas de recomendação inteligentes:

**Tipos de recomendação:**
- Baseado em conteúdo (content-based)
- Filtragem colaborativa (collaborative filtering)
- Sistemas híbridos
- Deep Learning para recomendações

**Aplicações:** [Netflix/Amazon/YouTube-style recommendations]
**Algoritmos:** [Matrix Factorization, Neural Collaborative Filtering]

**Solicito:**
1. **Implementação de baseline** (filtragem colaborativa simples)
2. **Sistema avançado** com deep learning
3. **Avaliação de qualidade** das recomendações
4. **Otimização de performance** e escalabilidade
5. **A/B testing** e métricas de negócio
```

### 12. Análise de Séries Temporais
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em forecasting]

Ensine técnicas de análise e previsão de séries temporais:

**Técnicas fundamentais:**
- Análise exploratória de séries temporais
- Modelos ARIMA e SARIMA
- Exponential Smoothing
- Prophet (Facebook)
- Deep Learning para séries temporais (LSTM, GRU)

**Aplicações:** [previsão de vendas/demanda/estoque/preços]

**Solicito:**
1. **Análise exploratória** e identificação de padrões
2. **Implementação de modelos** tradicionais
3. **Modelos de deep learning** para séries temporais
4. **Avaliação de previsões** e métricas adequadas
5. **Deployment** e atualização automática de modelos
```

---

## 📁 CATEGORIA: APRENDIZADO AVANÇADO E PESQUISA

### 13. Reinforcement Learning
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um pesquisador de RL]

Ensine os fundamentos de Reinforcement Learning:

**Conceitos fundamentais:**
- Agente, ambiente, estados, ações, recompensas
- Políticas, funções de valor, Q-learning
- Deep Q Networks (DQN)
- Actor-Critic methods

**Aplicações:** [jogos/otimização/robótica]
**Bibliotecas:** [OpenAI Gym, Stable Baselines]

**Solicito:**
1. **Implementação de Q-learning** clássico
2. **Deep RL** com redes neurais
3. **Algoritmos avançados** (PPO, SAC, etc.)
4. **Aplicações práticas** e casos de uso
5. **Pesquisa atual** e tendências em RL
```

### 14. AutoML e Automated Machine Learning
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em AutoML]

Ensine técnicas de Automated Machine Learning:

**Ferramentas AutoML:**
- Auto-sklearn, TPOT, H2O AutoML
- Google Cloud AutoML, Azure AutoML
- Técnicas de Auto Feature Engineering
- Neural Architecture Search (NAS)

**Casos de uso:** [quando usar AutoML vs ML tradicional]
**Limitações e desafios:** [interpretabilidade, custo, controle]

**Solicito:**
1. **Comparação** entre abordagens manuais e AutoML
2. **Implementação prática** com diferentes ferramentas
3. **Otimização de pipelines** AutoML
4. **Integração** com sistemas de produção
5. **Melhores práticas** e quando evitar AutoML
```

### 15. IA Explicável (XAI) e Interpretabilidade
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em interpretabilidade de ML]

Ensine técnicas de interpretabilidade e explicabilidade em IA:

**Técnicas de interpretabilidade:**
- Feature Importance (SHAP, LIME)
- Partial Dependence Plots
- Model-agnostic methods
- Interpretable models by design

**Frameworks:** [SHAP, LIME, InterpretML]
**Regulamentações:** [LGPD, GDPR requirements]

**Solicito:**
1. **Importância de interpretabilidade** em ML
2. **Técnicas locais vs globais** de explicação
3. **Implementação prática** com bibliotecas
4. **Avaliação de explicações** e validação
5. **Casos de uso** onde interpretabilidade é crítica
```

### 16. Conceitos Fundamentais de Estatística
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um professor de estatística aplicada à IA]

Ensine os conceitos fundamentais de estatística para ciência de dados:

**Tópicos essenciais:**
- Tipos de dados (qualitativos/quantitativos, discretos/contínuos)
- Medidas de tendência central (média, mediana, moda)
- Medidas de dispersão (variância, desvio padrão, amplitude)
- Distribuições de frequência e histogramas
- Correlação vs causalidade

**Aplicação prática:** [relacionar com análise de dados em ML]
**Ferramentas:** [Python com pandas, numpy, scipy]

**Solicito:**
1. **Explicação intuitiva** de cada conceito
2. **Exemplos práticos** com dados reais
3. **Implementação em Python** para cálculos
4. **Interpretação** dos resultados estatísticos
5. **Aplicações em ML** e tomada de decisão
```

### 17. Distribuições de Probabilidade
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em probabilidade e estatística]

Ensine distribuições de probabilidade essenciais para ML:

**Distribuições fundamentais:**
- Distribuição Normal (Gaussiana)
- Distribuição Binomial e Poisson
- Distribuição Exponencial e Gamma
- Distribuição t-Student e F
- Distribuição Qui-Quadrado

**Aplicações em ML:** [modelos probabilísticos, testes de hipóteses]
**Bibliotecas:** [scipy.stats, numpy.random]

**Solicito:**
1. **Propriedades matemáticas** de cada distribuição
2. **Parâmetros e formas** características
3. **Implementação prática** em Python
4. **Aplicações em ML** e inferência estatística
5. **Visualizações** e interpretação gráfica
```

### 18. Testes de Hipóteses e Inferência Estatística
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um estatístico especializado em testes de hipóteses]

Ensine metodologia de testes de hipóteses para validação de modelos:

**Tipos de testes:**
- Testes paramétricos (t-test, ANOVA, correlação de Pearson)
- Testes não-paramétricos (Mann-Whitney, Kruskal-Wallis, Spearman)
- Testes de qui-quadrado para independência
- Testes de normalidade (Shapiro-Wilk, Kolmogorov-Smirnov)

**Conceitos fundamentais:** [p-valor, nível de significância, poder do teste]
**Aplicações:** [validação A/B, comparação de modelos, análise de features]

**Solicito:**
1. **Lógica dos testes** de hipóteses passo-a-passo
2. **Escolha adequada** do teste estatístico
3. **Implementação prática** com scipy e statsmodels
4. **Interpretação de resultados** e p-valores
5. **Limitações e armadilhas** comuns
```

### 19. Análise de Regressão e Correlação
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em modelos de regressão]

Ensine técnicas avançadas de análise de regressão:

**Técnicas de regressão:**
- Regressão linear múltipla
- Regressão polinomial e não-linear
- Regressão robusta (Huber, RANSAC)
- Análise de correlação (Pearson, Spearman, Kendall)
- Diagnóstico de modelos (resíduos, multicolinearidade)

**Métricas de avaliação:** [R², RMSE, MAE, F-statistic]
**Ferramentas:** [statsmodels, scikit-learn, seaborn]

**Solicito:**
1. **Fundamentos matemáticos** da regressão
2. **Implementação completa** em Python
3. **Análise de diagnóstico** e validação de pressupostos
4. **Seleção de variáveis** e feature engineering
5. **Interpretação prática** dos coeficientes
```

### 20. Estatística Não-Paramétrica
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em métodos não-paramétricos]

Ensine técnicas estatísticas não-paramétricas para dados não-normais:

**Métodos não-paramétricos:**
- Testes de sinais e Wilcoxon
- Teste de Mann-Whitney U
- Teste de Kruskal-Wallis
- Correlação de Spearman e Kendall
- Bootstrap e reamostragem

**Quando usar:** [dados não-normais, amostras pequenas, distribuições desconhecidas]
**Vantagens:** [robustez, flexibilidade, menos pressupostos]

**Solicito:**
1. **Comparação** com métodos paramétricos
2. **Implementação prática** dos testes
3. **Interpretação de resultados** não-paramétricos
4. **Aplicações em ML** e análise de dados
5. **Limitações e melhores práticas**
```

### 21. Análise Multivariada
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em análise multivariada]

Ensine técnicas de análise multivariada para datasets complexos:

**Técnicas multivariadas:**
- Análise de Componentes Principais (PCA)
- Análise Fatorial
- Análise de Agrupamento (Cluster Analysis)
- Análise Discriminante
- Análise de Correspondência

**Aplicações:** [redução de dimensionalidade, segmentação, visualização]
**Bibliotecas:** [scikit-learn, statsmodels, seaborn]

**Solicito:**
1. **Fundamentos matemáticos** de cada técnica
2. **Implementação passo-a-passo** em Python
3. **Interpretação de resultados** e loadings
4. **Visualização de dados** multidimensionais
5. **Aplicações práticas** em projetos de ML
```

### 22. Estatística Bayesiana
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em estatística bayesiana]

Ensine princípios da estatística bayesiana aplicada a ML:

**Conceitos fundamentais:**
- Teorema de Bayes e probabilidade condicional
- Distribuições a priori e a posteriori
- Inferência bayesiana vs frequentista
- MCMC (Markov Chain Monte Carlo)
- Modelos bayesianos em ML

**Aplicações modernas:** [redes bayesianas, Bayesian optimization]
**Ferramentas:** [PyMC3, Stan, TensorFlow Probability]

**Solicito:**
1. **Intuição bayesiana** vs abordagem frequentista
2. **Implementação prática** de modelos simples
3. **MCMC e sampling** para inferência
4. **Aplicações em ML** (Naive Bayes, Bayesian Neural Networks)
5. **Vantagens e desafios** da abordagem bayesiana
```

### 23. Controle Estatístico de Processo (CEP)
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em controle de qualidade]

Ensine técnicas de Controle Estatístico de Processo para monitoramento:

**Ferramentas de CEP:**
- Gráficos de controle (X-bar, R, p, c)
- Capability analysis (Cp, Cpk)
- Análise de Pareto
- Diagramas de causa e efeito (Ishikawa)
- Six Sigma methodology

**Aplicações:** [monitoramento de processos, garantia de qualidade]
**Ferramentas:** [Python com pandas, matplotlib, scipy]

**Solicito:**
1. **Fundamentos do CEP** e gráficos de controle
2. **Implementação prática** em Python
3. **Análise de capability** e performance
4. **Identificação de causas** de variação
5. **Aplicações em ML** e otimização de processos
```

### 24. Amostragem e Pesquisa por Survey
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em métodos de amostragem]

Ensine técnicas de amostragem estatística para pesquisa e ML:

**Métodos de amostragem:**
- Amostragem aleatória simples
- Amostragem estratificada
- Amostragem por conglomerados
- Amostragem sistemática
- Técnicas de survey (questionários, entrevistas)

**Conceitos importantes:** [tamanho da amostra, erro de amostragem, power analysis]
**Aplicações:** [pesquisa de mercado, validação de modelos, A/B testing]

**Solicito:**
1. **Cálculo de tamanho** de amostra adequado
2. **Implementação prática** de métodos de amostragem
3. **Análise de viés** e erro de amostragem
4. **Design de surveys** e questionários
5. **Análise de resposta** e tratamento de missing data
```

### 25. Estatística Computacional e Simulação
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em métodos computacionais]

Ensine técnicas de estatística computacional e simulação:

**Técnicas computacionais:**
- Monte Carlo simulation
- Bootstrap e reamostragem
- Cross-validation para validação de modelos
- Métodos de otimização numérica
- Algoritmos de sampling (MCMC, Gibbs)

**Aplicações:** [estimação robusta, validação de modelos, otimização]
**Bibliotecas:** [numpy, scipy, scikit-learn, pymc3]

**Solicito:**
1. **Implementação de Monte Carlo** para estimação
2. **Bootstrap** para intervalos de confiança
3. **Simulação de distribuições** complexas
4. **Otimização numérica** para ML
5. **Aplicações práticas** em projetos de data science
```

---

## 📋 TABELA DE USO POR NÍVEL DE CONHECIMENTO

| Nível | Foco | Prompts Recomendados | Modelo Principal |
|-------|------|----------------------|------------------|
| **Iniciante** | Conceitos básicos | 1, 2, 3, 16 | Llama 3 |
| **Intermediário** | Algoritmos práticos | 4, 5, 6, 7, 17, 18 | CodeLlama |
| **Avançado** | Deep Learning | 8, 9, 10, 11, 19, 20, 21 | DeepSeek-Coder |
| **Especialista** | Pesquisa aplicada | 12, 13, 14, 15, 22, 23, 24, 25 | Mixtral |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona Professor de IA:
```yaml
name: "Professor de IA e Data Science"
description: "Assistente educacional para aprendizado de IA, ML e Data Science"
instruction: |
  Você é um professor experiente de IA e Data Science com paciência para explicar conceitos complexos.
  Adapte o nível de explicação ao conhecimento do aluno, forneça exemplos práticos e incentive a experimentação.
  Foque em aplicações práticas e ajude na resolução de dúvidas passo-a-passo.
```

### Template de Persona Mentor de Projetos:
```yaml
name: "Mentor de Projetos de IA"
description: "Guia prático para desenvolvimento de projetos de IA do início ao fim"
instruction: |
  Você é um mentor experiente em projetos de IA com foco em aplicações práticas.
  Guie o aluno através de todo o processo de desenvolvimento, desde a concepção até o deployment.
  Enfatize boas práticas, debugging e otimização de performance.
```

### Template de Configuração para Aprendizado:
```yaml
model: "codellama"
temperature: 0.4
max_tokens: 2000
system: |
  Você é um educador especializado em IA e Data Science.
  Forneça explicações claras, exemplos práticos e código funcional.
  Adapte a complexidade ao nível do aluno e incentive a prática hands-on.
```

---

## 💡 DICAS PARA APRENDIZADO EFICAZ

### Estratégia de Aprendizado
1. **Comece com os fundamentos** antes de avançar
2. **Pratique com projetos reais** desde o início
3. **Participe de comunidades** (Kaggle, Reddit, Discord)
4. **Contribua para open source** para ganhar experiência
5. **Mantenha um portfolio** de projetos

### Recursos Recomendados
- **Plataformas**: Coursera, edX, Udacity, DataCamp
- **Livros**: "Hands-On ML", "Deep Learning", "Python for Data Science"
- **Comunidades**: Kaggle, Towards Data Science, Reddit r/MachineLearning
- **Prática**: LeetCode, HackerRank, Kaggle competitions

### Carreira em IA
- **Especializações**: ML Engineer, Data Scientist, Research Scientist
- **Habilidades essenciais**: Python, SQL, Cloud, MLOps
- **Certificações**: TensorFlow Developer, AWS ML, GCP ML Engineer

---

Este catálogo oferece **25 prompts especializados** para aprendizado em IA e Data Science, abrangendo desde conceitos básicos até técnicas avançadas de pesquisa e estatística aplicada.

**Última atualização**: Dezembro 2024
**Total de prompts**: 25
**Níveis de dificuldade**: Iniciante → Especialista
**Foco**: Aprendizado prático e aplicado de IA com ênfase em estatística
