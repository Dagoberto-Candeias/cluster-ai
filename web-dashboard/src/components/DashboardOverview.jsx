import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  LinearProgress,
  Chip,
  Alert,
  Skeleton,
  useTheme
} from '@mui/material';
import {
  Memory as MemoryIcon,
  Storage as StorageIcon,
  Speed as SpeedIcon,
  People as PeopleIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  TrendingUp as TrendingUpIcon,
  Timeline as TimelineIcon
} from '@mui/icons-material';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Area, AreaChart } from 'recharts';
import axios from 'axios';

const DashboardOverview = () => {
  const theme = useTheme();
  const [loading, setLoading] = useState(true);
  const [metrics, setMetrics] = useState({
    cpu_percent: null,
    memory_percent: null,
    disk_percent: null,
    network_rx: null,
    network_tx: null
  });
  const [clusterStatus, setClusterStatus] = useState(null);
  const [workers, setWorkers] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [metricsHistory, setMetricsHistory] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchDashboardData();
    const interval = setInterval(fetchDashboardData, 30000); // Update every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Fetch all data in parallel
      const [metricsRes, clusterRes, workersRes, alertsRes] = await Promise.all([
        axios.get('http://localhost:8000/metrics/system?limit=20'),
        axios.get('http://localhost:8000/cluster/status'),
        axios.get('http://localhost:8000/workers'),
        axios.get('http://localhost:8000/alerts?limit=10')
      ]);

      // Process metrics
      if (metricsRes.data && metricsRes.data.length > 0) {
        const latest = metricsRes.data[metricsRes.data.length - 1];
        setMetrics({
          cpu_percent: latest.cpu_percent,
          memory_percent: latest.memory_percent,
          disk_percent: latest.disk_percent,
          network_rx: latest.network_rx,
          network_tx: latest.network_tx
        });

        // Prepare history data for charts
        const history = metricsRes.data.slice(-10).map(m => ({
          time: new Date(m.timestamp).toLocaleTimeString(),
          cpu: m.cpu_percent,
          memory: m.memory_percent,
          disk: m.disk_percent
        }));
        setMetricsHistory(history);
      }

      setClusterStatus(clusterRes.data);
      setWorkers(workersRes.data);
      setAlerts(alertsRes.data);

    } catch (err) {
      console.error('Failed to fetch dashboard data:', err);
      setError('Failed to load dashboard data. Please check if the backend is running.');
    } finally {
      setLoading(false);
    }
  };

  const MetricCard = ({ title, value, icon, color = 'primary', progress = false, subtitle = '' }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={1}>
          <Box display="flex" alignItems="center">
            {React.cloneElement(icon, { color, sx: { mr: 1, fontSize: 28 } })}
            <Typography variant="h6" color="text.secondary">
              {title}
            </Typography>
          </Box>
          {value !== null && value > 80 && (
            <WarningIcon color="error" />
          )}
        </Box>

        {loading ? (
          <Skeleton variant="text" width="60%" height={40} />
        ) : (
          <Typography variant="h4" color={value > 80 ? 'error' : color} sx={{ mb: 1 }}>
            {value !== null ? `${value.toFixed(1)}${progress ? '%' : ''}` : '--'}
          </Typography>
        )}

        {progress && value !== null && (
          <LinearProgress
            variant="determinate"
            value={value}
            color={value > 80 ? 'error' : color}
            sx={{ height: 8, borderRadius: 4, mb: 1 }}
          />
        )}

        {subtitle && (
          <Typography variant="body2" color="text.secondary">
            {subtitle}
          </Typography>
        )}
      </CardContent>
    </Card>
  );

  const ServiceStatusCard = ({ service, status, title }) => (
    <Box display="flex" justifyContent="space-between" alignItems="center" p={2}>
      <Box display="flex" alignItems="center">
        <Box
          sx={{
            width: 12,
            height: 12,
            borderRadius: '50%',
            bgcolor: status ? 'success.main' : 'error.main',
            mr: 2
          }}
        />
        <Typography>{title}</Typography>
      </Box>
      <Chip
        label={status ? 'Running' : 'Stopped'}
        color={status ? 'success' : 'error'}
        size="small"
        variant="outlined"
      />
    </Box>
  );

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        {error}
      </Alert>
    );
  }

  return (
    <Box p={3}>
      <Typography variant="h4" component="h1" gutterBottom sx={{ mb: 3 }}>
        Cluster AI Dashboard
      </Typography>

      {/* System Metrics Grid */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="CPU Usage"
            value={metrics.cpu_percent}
            icon={<SpeedIcon />}
            progress={true}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Memory Usage"
            value={metrics.memory_percent}
            icon={<MemoryIcon />}
            progress={true}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Disk Usage"
            value={metrics.disk_percent}
            icon={<StorageIcon />}
            progress={true}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Active Workers"
            value={workers.filter(w => w.status === 'active').length}
            icon={<PeopleIcon />}
            subtitle={`of ${workers.length} total`}
          />
        </Grid>
      </Grid>

      {/* Charts Section */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <TimelineIcon sx={{ mr: 1 }} />
                System Metrics History
              </Typography>
              {loading ? (
                <Skeleton variant="rectangular" height={300} />
              ) : (
                <ResponsiveContainer width="100%" height={300}>
                  <AreaChart data={metricsHistory}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="time" />
                    <YAxis />
                    <Tooltip />
                    <Area type="monotone" dataKey="cpu" stackId="1" stroke="#8884d8" fill="#8884d8" fillOpacity={0.6} />
                    <Area type="monotone" dataKey="memory" stackId="1" stroke="#82ca9d" fill="#82ca9d" fillOpacity={0.6} />
                    <Area type="monotone" dataKey="disk" stackId="1" stroke="#ffc658" fill="#ffc658" fillOpacity={0.6} />
                  </AreaChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <CheckCircleIcon sx={{ mr: 1 }} />
                Service Status
              </Typography>
              {loading ? (
                <Box>
                  <Skeleton height={40} sx={{ mb: 2 }} />
                  <Skeleton height={40} sx={{ mb: 2 }} />
                  <Skeleton height={40} />
                </Box>
              ) : (
                <Box>
                  <ServiceStatusCard
                    service="dask"
                    status={clusterStatus?.dask_running}
                    title="Dask Scheduler"
                  />
                  <ServiceStatusCard
                    service="ollama"
                    status={clusterStatus?.ollama_running}
                    title="Ollama API"
                  />
                  <ServiceStatusCard
                    service="webui"
                    status={clusterStatus?.webui_running}
                    title="OpenWebUI"
                  />
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Alerts and Performance Summary */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <WarningIcon sx={{ mr: 1 }} />
                Recent Alerts ({alerts.length})
              </Typography>
              {loading ? (
                <Box>
                  <Skeleton height={30} sx={{ mb: 1 }} />
                  <Skeleton height={30} sx={{ mb: 1 }} />
                  <Skeleton height={30} />
                </Box>
              ) : alerts.length > 0 ? (
                <Box sx={{ maxHeight: 200, overflow: 'auto' }}>
                  {alerts.slice(0, 5).map((alert, index) => (
                    <Box key={index} sx={{ mb: 1, p: 1, bgcolor: 'background.paper', borderRadius: 1 }}>
                      <Typography variant="body2" color="text.secondary">
                        {alert.timestamp}
                      </Typography>
                      <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                        {alert.component}: {alert.message}
                      </Typography>
                      <Chip
                        label={alert.severity}
                        size="small"
                        color={alert.severity === 'CRITICAL' ? 'error' : 'warning'}
                        sx={{ mt: 0.5 }}
                      />
                    </Box>
                  ))}
                </Box>
              ) : (
                <Typography variant="body2" color="text.secondary">
                  No recent alerts
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <TrendingUpIcon sx={{ mr: 1 }} />
                Performance Summary
              </Typography>
              {loading ? (
                <Box>
                  <Skeleton height={40} sx={{ mb: 2 }} />
                  <Skeleton height={40} sx={{ mb: 2 }} />
                  <Skeleton height={40} />
                </Box>
              ) : (
                <Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                    <Typography variant="body2">Total CPU Cores:</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                      {clusterStatus?.total_cpu?.toFixed(1) || '--'}
                    </Typography>
                  </Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                    <Typography variant="body2">Total Memory:</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                      {clusterStatus?.total_memory?.toFixed(1) || '--'} GB
                    </Typography>
                  </Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                    <Typography variant="body2">Tasks Completed:</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                      {clusterStatus?.dask_tasks_completed || '--'}
                    </Typography>
                  </Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2">Health Score:</Typography>
                    <Chip
                      label={`${clusterStatus?.status || 'Unknown'}`}
                      color={clusterStatus?.status === 'healthy' ? 'success' : 'warning'}
                      size="small"
                    />
                  </Box>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default DashboardOverview;
