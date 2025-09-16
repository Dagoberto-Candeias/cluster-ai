import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { ThemeProvider, createTheme } from '@mui/material/styles'
import CssBaseline from '@mui/material/CssBaseline'
import Dashboard from './pages/Dashboard'
import System from './pages/System'
import Workers from './pages/Workers'
import Alerts from './pages/Alerts'
import Logs from './pages/Logs'
import Settings from './pages/Settings'
import Metrics from './pages/Metrics'
import ClusterStatus from './pages/ClusterStatus'
import LayoutWithNotifications from './components/LayoutWithNotifications'
import DashboardOverview from './components/DashboardOverview'
import AdvancedMetrics from './components/AdvancedMetrics'

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#ff9800',
    },
    background: {
      default: '#121212',
      paper: '#1e1e1e',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h4: {
      fontWeight: 600,
    },
    h6: {
      fontWeight: 500,
    },
  },
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          borderRadius: 12,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
        },
      },
    },
  },
})

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <LayoutWithNotifications>
          <Routes>
            <Route path="/" element={<DashboardOverview />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/system" element={<System />} />
            <Route path="/workers" element={<Workers />} />
            <Route path="/alerts" element={<Alerts />} />
            <Route path="/logs" element={<Logs />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/metrics" element={<Metrics />} />
            <Route path="/cluster-status" element={<ClusterStatus />} />
            <Route path="/advanced-metrics" element={<AdvancedMetrics />} />
          </Routes>
        </LayoutWithNotifications>
      </Router>
    </ThemeProvider>
  )
}

export default App
