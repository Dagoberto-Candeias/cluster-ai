# 🏗️ Cluster AI Dashboard - Arquitetura Técnica

## 📋 Visão Geral da Arquitetura

O Dashboard Web do Cluster AI seguirá uma arquitetura **micro-frontend** com backend API separado, utilizando tecnologias modernas para escalabilidade, manutenibilidade e experiência do usuário.

## 🏛️ Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           User Browser                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   React SPA     │  │   WebSocket     │  │   REST API      │             │
│  │   (Frontend)    │◄►│   Client        │◄►│   Client        │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Load Balancer (Nginx)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   API Gateway   │  │   WebSocket     │  │   Static Files  │             │
│  │   (FastAPI)     │  │   Server        │  │   (CDN)         │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Application Server                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   FastAPI       │  │   WebSocket     │  │   Background    │             │
│  │   App           │  │   Manager       │  │   Tasks         │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Auth Service  │  │   Metrics       │  │   Alert System  │             │
│  │   (JWT)         │  │   Collector     │  │   (Email/SMS)   │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Data Layer                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   PostgreSQL    │  │   Redis Cache   │  │   Time Series   │             │
│  │   (Main DB)     │  │   (Sessions)    │  │   DB (Metrics)  │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           External Systems                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Dask Cluster  │  │   Ollama API    │  │   OpenWebUI     │             │
│  │   (8786/8787)   │  │   (11434)       │  │   (3000)        │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🛠️ Stack Tecnológico

### Frontend
- **Framework**: React 18+ com TypeScript
- **Build Tool**: Vite
- **UI Library**: Material-UI v5 (MUI)
- **State Management**: Redux Toolkit
- **Routing**: React Router v6
- **HTTP Client**: Axios com interceptors
- **WebSocket**: Socket.io-client
- **Charts**: Recharts
- **Testing**: Jest + React Testing Library
- **PWA**: Workbox

### Backend
- **Framework**: FastAPI (Python)
- **ASGI Server**: Uvicorn
- **WebSocket**: FastAPI WebSocket support
- **Authentication**: JWT (PyJWT)
- **Database**: SQLAlchemy + PostgreSQL
- **Cache**: Redis
- **Background Tasks**: Celery
- **API Documentation**: Swagger/OpenAPI
- **Testing**: Pytest

### DevOps & Deployment
- **Container**: Docker + Docker Compose
- **Reverse Proxy**: Nginx
- **SSL/TLS**: Let's Encrypt
- **Monitoring**: Prometheus + Grafana
- **CI/CD**: GitHub Actions
- **Hosting**: VPS/Cloud (AWS/DigitalOcean)

## 📁 Estrutura do Projeto

```
cluster-ai-dashboard/
├── frontend/
│   ├── public/
│   │   ├── favicon.ico
│   │   ├── manifest.json
│   │   └── robots.txt
│   ├── src/
│   │   ├── assets/
│   │   │   ├── images/
│   │   │   └── icons/
│   │   ├── components/
│   │   │   ├── common/
│   │   │   ├── dashboard/
│   │   │   ├── auth/
│   │   │   └── layout/
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx
│   │   │   ├── System.tsx
│   │   │   ├── Workers.tsx
│   │   │   ├── Alerts.tsx
│   │   │   └── Settings.tsx
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   ├── useWebSocket.ts
│   │   │   └── useMetrics.ts
│   │   ├── services/
│   │   │   ├── api.ts
│   │   │   ├── auth.ts
│   │   │   └── websocket.ts
│   │   ├── store/
│   │   │   ├── index.ts
│   │   │   ├── authSlice.ts
│   │   │   └── metricsSlice.ts
│   │   ├── types/
│   │   │   ├── index.ts
│   │   │   └── api.ts
│   │   ├── utils/
│   │   │   ├── constants.ts
│   │   │   ├── helpers.ts
│   │   │   └── formatters.ts
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   └── index.css
│   ├── index.html
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── package.json
│   └── tailwind.config.js
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models/
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── alert.py
│   │   │   └── metric.py
│   │   ├── routers/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py
│   │   │   ├── dashboard.py
│   │   │   ├── metrics.py
│   │   │   ├── workers.py
│   │   │   └── alerts.py
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   ├── auth_service.py
│   │   │   ├── metrics_service.py
│   │   │   ├── alert_service.py
│   │   │   └── websocket_service.py
│   │   ├── utils/
│   │   │   ├── __init__.py
│   │   │   ├── security.py
│   │   │   └── helpers.py
│   │   └── dependencies.py
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── test_auth.py
│   │   ├── test_metrics.py
│   │   └── test_websocket.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
├── docker/
│   ├── nginx.conf
│   ├── docker-compose.prod.yml
│   └── docker-compose.dev.yml
├── docs/
│   ├── api/
│   ├── deployment/
│   └── user-guide/
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── docker-compose.yml
├── README.md
└── .env.example
```

## 🔄 Fluxos de Dados

### 1. Autenticação Flow
```
User Login → Frontend → API Gateway → Auth Service → JWT Token → Database
     ↓
Frontend Stores Token → Subsequent Requests Include Bearer Token
```

### 2. Real-time Metrics Flow
```
Cluster AI System → Metrics Collector → Redis Cache → WebSocket Server → Frontend
     ↓
Dashboard Updates → Charts Refresh → User Notification (if needed)
```

### 3. Alert System Flow
```
System Event → Alert Rules Engine → Alert Created → Database → WebSocket Push
     ↓
Email Service → User Email/SMS → Dashboard Notification → User Acknowledgment
```

## 🔐 Segurança

### Autenticação
- **JWT Tokens**: Access (15min) + Refresh (7 dias)
- **Password Hashing**: bcrypt
- **Rate Limiting**: 100 requests/minute por IP
- **Session Management**: Redis-based sessions

### Autorização
- **Role-Based Access**: Admin, Operator, Viewer
- **Resource Permissions**: CRUD por entidade
- **API Scopes**: Granular permissions
- **Audit Logging**: Todas as operações sensíveis

### Comunicação
- **HTTPS Only**: TLS 1.3 obrigatório
- **CORS**: Configurado para domínios específicos
- **HSTS**: Strict Transport Security
- **CSP**: Content Security Policy

## 📊 Escalabilidade

### Horizontal Scaling
- **Load Balancer**: Nginx com sticky sessions
- **Database**: Read replicas para queries
- **Cache**: Redis cluster para sessions/metrics
- **WebSocket**: Multiple server instances

### Performance Optimization
- **CDN**: Static assets via CloudFlare
- **Caching**: API responses cached por 30s
- **Compression**: Gzip/Brotli para responses
- **Database Indexing**: Otimizado para queries comuns

### Monitoring
- **Application**: Prometheus metrics
- **Infrastructure**: System monitoring
- **User Experience**: Real User Monitoring (RUM)
- **Logging**: Structured logging com ELK stack

## 🚀 Estratégia de Deployment

### Development
- **Local**: Docker Compose com hot reload
- **Staging**: Deploy automático via GitHub Actions
- **Database**: SQLite para desenvolvimento

### Production
- **Container**: Multi-stage Docker builds
- **Orchestration**: Docker Compose (simples) ou Kubernetes
- **Database**: PostgreSQL com backups automáticos
- **SSL**: Let's Encrypt com auto-renewal

### CI/CD Pipeline
```
Git Push → GitHub Actions → Tests → Build → Deploy Staging → Manual Approval → Deploy Production
```

## 🔧 APIs e Integrações

### Internal APIs
- **Auth API**: `/api/v1/auth/*`
- **Dashboard API**: `/api/v1/dashboard/*`
- **Metrics API**: `/api/v1/metrics/*`
- **Workers API**: `/api/v1/workers/*`
- **Alerts API**: `/api/v1/alerts/*`

### External Integrations
- **Cluster AI System**: HTTP APIs para métricas
- **Email Service**: SMTP ou SendGrid
- **SMS Service**: Twilio (opcional)
- **Monitoring**: Prometheus/Grafana

## 📈 Plano de Migração

### Fase 1: Foundation (Semanas 1-2)
- Setup da arquitetura base
- Implementação de autenticação
- Database schema inicial

### Fase 2: Core Features (Semanas 3-4)
- Dashboard principal
- Sistema de métricas
- Interface básica

### Fase 3: Advanced Features (Semanas 5-6)
- WebSocket real-time
- Sistema de alertas
- Gerenciamento de workers

### Fase 4: Production Ready (Semanas 7-8)
- Otimizações de performance
- Testes completos
- Deploy e documentação

---

**Data**: Janeiro 2025
**Versão**: 1.0
**Status**: Arquitetura definida e aprovada
