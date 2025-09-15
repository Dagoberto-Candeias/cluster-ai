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
import Layout from './components/Layout'

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#ff9800',
    },
  },
})

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Layout>
          <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/system" element={<System />} />
            <Route path="/workers" element={<Workers />} />
            <Route path="/alerts" element={<Alerts />} />
            <Route path="/logs" element={<Logs />} />
            <Route path="/metrics" element={<Metrics />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/cluster-status" element={<ClusterStatus />} />
        </Routes>
      </Layout>
      </Router>
    </ThemeProvider>
  )
}

export default App
