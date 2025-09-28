# 🎨 Cluster AI Dashboard - Design de Interface

## 📋 Visão Geral do Design

O dashboard será construído com uma abordagem **mobile-first**, utilizando Material-UI v5 para consistência e acessibilidade. O tema será **dark mode** por padrão, com opção de light mode.

## 🏗️ Estrutura Geral

### Layout Principal
```
┌─────────────────────────────────────────────────┐
│ Header Bar (Top Navigation)                     │
├─────────────────────────────────────────────────┤
│ ┌─────┐ ┌─────────────────────────────────────┐ │
│ │     │ │                                     │ │
│ │  S  │ │         Main Content Area            │ │
│ │  I  │ │                                     │ │
│ │  D  │ └─────────────────────────────────────┘ │
│ │  E  │                                         │
│ │  B  │ ┌─────────────────────────────────────┐ │
│ │  A  │ │         Secondary Content            │ │
│ │  R  │ │         (Charts/Alerts)              │ │
│ └─────┘ └─────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## 📱 Componentes Principais

### 1. Header Bar
- **Logo**: Cluster AI (esquerda)
- **User Menu**: Avatar + nome + dropdown (direita)
- **Notifications**: Badge com contador de alertas
- **Theme Toggle**: Dark/Light mode
- **Responsive**: Collapse em mobile

### 2. Sidebar Navigation
- **Dashboard**: Visão geral
- **System**: Métricas do sistema
- **Workers**: Gerenciamento de workers
- **Alerts**: Sistema de alertas
- **Reports**: Relatórios
- **Settings**: Configurações
- **Collapsible**: Toggle para expandir/colapsar

### 3. Dashboard Principal

#### Overview Cards (Grid 4x2)
```
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ System Status   │ │ CPU Usage       │ │ Memory Usage    │ │ Disk Usage      │
│ 🟢 Online       │ │ 45%             │ │ 67%             │ │ 23%             │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘

┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Network I/O     │ │ Active Workers  │ │ Queue Tasks     │ │ Alerts Today    │
│ ↑ 2.3 MB/s      │ │ 8/10            │ │ 45              │ │ ⚠️ 3             │
│ ↓ 1.8 MB/s      │ └─────────────────┘ └─────────────────┘ └─────────────────┘
└─────────────────┘
```

#### Charts Section
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ System Metrics Over Time                                                   │
│                                                                             │
│   CPU ──────────────────────────────────────────────────────────────────   │
│         ████▌                                                              │
│                                                                             │
│   Memory ───────────────────────────────────────────────────────────────   │
│            ████████▌                                                       │
│                                                                             │
│   Network ──────────────────────────────────────────────────────────────   │
│              ███▌                                                          │
│                                                                             │
│   Time: Last 24 Hours                    Zoom: 1h 6h 24h 7d 30d           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4. System Monitoring Page

#### Service Status Panel
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Service Status                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🟢 Dask Scheduler    8786    CPU: 12%    Memory: 256MB    Uptime: 2d 4h    │
│ 🟢 Dask Dashboard    8787    CPU: 8%     Memory: 180MB    Uptime: 2d 4h    │
│ 🟢 Ollama API        11434   CPU: 35%    Memory: 2.1GB    Uptime: 1d 12h   │
│ 🟢 OpenWebUI         3000    CPU: 5%     Memory: 120MB    Uptime: 2d 4h    │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Resource Charts
```
┌─────────────────────────────┐ ┌─────────────────────────────┐
│ CPU Usage Trend             │ │ Memory Usage Trend          │
│                             │ │                             │
│ ████████████████████████▌   │ │ ████████████████████▌       │
│ ████████████████████████▌   │ │ █████████████████████▌      │
│ ███████████████████████▌    │ │ ██████████████████████▌     │
│ ██████████████████████▌     │ │ ███████████████████████▌    │
│ █████████████████████▌      │ │ ████████████████████████▌   │
│ ████████████████████▌       │ │ █████████████████████████▌  │
│ ███████████████████▌        │ │ ██████████████████████████▌ │
│ █████████████████▌          │ │ ███████████████████████████▌│
└─────────────────────────────┘ └─────────────────────────────┘
```

### 5. Workers Management Page

#### Workers List
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Workers Management                                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ ┌─ Worker Node 1 (192.168.1.100) ──────────────────────────────────────┐    │
│ │ Status: 🟢 Active    CPU: 45%    Memory: 2.1GB    Tasks: 12         │    │
│ │ Last Seen: 2 min ago    Uptime: 3d 2h    Load: Medium              │    │
│ │ [Restart] [Stop] [Configure] [View Details]                         │    │
│ └──────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│ ┌─ Worker Node 2 (192.168.1.101) ──────────────────────────────────────┐    │
│ │ Status: 🟡 Warning   CPU: 78%    Memory: 3.2GB    Tasks: 8          │    │
│ │ Last Seen: 1 min ago    Uptime: 2d 18h   Load: High                │    │
│ │ [Restart] [Stop] [Configure] [View Details]                         │    │
│ └──────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6. Alerts System

#### Active Alerts
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Active Alerts                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│ ⚠️  HIGH: Worker Node 2 CPU > 75% (78%) - 5 min ago                     │
│ ⚠️  MEDIUM: Memory usage > 80% (85%) - 12 min ago                       │
│ ℹ️  LOW: Network latency spike - 1h 23m ago                             │
│ ✅ ACKNOWLEDGED: Disk space low - 2h 15m ago                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Alert Configuration
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Alert Rules                                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ CPU Usage > 80%              Threshold: 80%     Action: Email + Dashboard │
│ Memory Usage > 85%           Threshold: 85%     Action: Email            │
│ Disk Usage > 90%             Threshold: 90%     Action: Email + SMS      │
│ Worker Offline > 5min        Threshold: 5min    Action: Email            │
│ Network Latency > 100ms      Threshold: 100ms   Action: Dashboard        │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🎨 Paleta de Cores

### Tema Dark (Padrão)
- **Background**: #121212
- **Surface**: #1E1E1E
- **Primary**: #2196F3 (Blue)
- **Secondary**: #FF9800 (Orange)
- **Success**: #4CAF50 (Green)
- **Warning**: #FF9800 (Orange)
- **Error**: #F44336 (Red)
- **Text Primary**: #FFFFFF
- **Text Secondary**: #B3B3B3

### Tema Light
- **Background**: #FAFAFA
- **Surface**: #FFFFFF
- **Primary**: #1976D2 (Dark Blue)
- **Secondary**: #F57C00 (Dark Orange)
- **Success**: #388E3C (Dark Green)
- **Warning**: #F57C00 (Dark Orange)
- **Error**: #D32F2F (Dark Red)
- **Text Primary**: #212121
- **Text Secondary**: #757575

## 📱 Design Responsivo

### Desktop (>1200px)
- Sidebar expandida
- 4 colunas de cards
- Charts lado a lado
- Full navigation

### Tablet (768px - 1199px)
- Sidebar colapsada por padrão
- 3 colunas de cards
- Charts empilhados
- Touch-friendly buttons

### Mobile (<768px)
- Sidebar drawer
- 2 colunas de cards (single column em alguns casos)
- Charts empilhados verticalmente
- Bottom navigation tabs
- Swipe gestures

## 🔄 Estados e Interações

### Loading States
- Skeleton loaders para cards
- Spinner para charts
- Progress bars para ações longas

### Error States
- Error boundaries com retry
- Offline indicators
- Connection status

### Empty States
- Placeholder illustrations
- Clear call-to-actions
- Helpful guidance text

## ♿ Acessibilidade

### WCAG 2.1 AA Compliance
- **Keyboard Navigation**: Tab order lógico
- **Screen Reader**: ARIA labels e roles
- **Color Contrast**: Mínimo 4.5:1
- **Focus Indicators**: Visíveis e destacados
- **Alt Text**: Para todas as imagens

### Inclusive Design
- **Font Size**: Escalável (16px base)
- **Touch Targets**: Mínimo 44px
- **Motion**: Respeita preferências do usuário
- **Language**: Suporte i18n

## 🎯 Próximos Passos

1. **Criar Protótipo**: Figma/Adobe XD mockups detalhados
2. **Design System**: Component library com Storybook
3. **User Testing**: Validação de UX com usuários
4. **Iteração**: Refinar baseado em feedback

---

**Data**: Janeiro 2025
**Versão**: 1.0
**Status**: Design inicial aprovado
