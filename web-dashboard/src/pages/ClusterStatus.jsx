import React, { useEffect, useState } from 'react';
import {
  Typography,
  Box,
  Paper,
  Grid,
  Card,
  CardContent,
  Chip,
  LinearProgress,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Divider,
  Alert,
  useTheme,
  CircularProgress
} from '@mui/material';
import {
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  Storage as StorageIcon,
  Memory as MemoryIcon,
  Speed as SpeedIcon,
  NetworkCheck as NetworkIcon,
  People as PeopleIcon,
  Timeline as TimelineIcon
} from '@mui/icons-material';
import axios from 'axios';

function ClusterStatus() {
  const theme = useTheme();
  const [clusterData, setClusterData] = useState(null);
  const [systemMetrics, setSystemMetrics] = useState(null);
  const [workers, setWorkers] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [wsStatus, setWsStatus] = useState('disconnected');

  useEffect(() => {
    fetchAllData();
    setupWebSocket();
  }, []);

  const fetchAllData = async () => {
    setLoading(true);
    try {
      const [clusterRes, metricsRes, workersRes, alertsRes] = await Promise.all([
        axios.get('/api/cluster/status'),
        axios.get('/api/metrics/system?limit=1'),
        axios.get('/api/workers'),
        axios.get('/api/alerts?limit=10')
      ]);

      setClusterData(clusterRes.data);
      setSystemMetrics(metricsRes.data[0] || null);
      setWorkers(workersRes.data);
      setAlerts(alertsRes.data);
    } catch (error) {
      console.error('Failed to fetch cluster data:', error);
    } finally {
      setLoading(false);
    }
  };

  const setupWebSocket = () => {
    const clientId = `cluster-status-${Date.now()}`;
    const ws = new WebSocket(`ws://localhost:8000/ws/${clientId}`);

    ws.onopen = () => {
      console.log('Cluster status WebSocket connected');
      setWsStatus('connected');
    };

    ws.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        if (message.type === 'realtime_update') {
          setClusterData(message.data.cluster_status);
          setSystemMetrics(message.data.system_metrics);
          setWorkers(message.data.workers_count);
          setAlerts(message.data.alerts_count);
        }
      } catch (error) {
        console.error('Failed to parse WebSocket message:', error);
      }
    };

    ws.onclose = () => {
      console.log('Cluster status WebSocket disconnected');
      setWsStatus('disconnected');
      setTimeout(setupWebSocket, 5000);
    };

    ws.onerror = () => {
      setWsStatus('error');
    };
  };

  const getServiceStatus = (serviceName) => {
    if (!clusterData) return { status: 'unknown', color: 'default' };

    const status = clusterData[`${serviceName}_running`];
    return {
      status: status ? 'running' : 'stopped',
      color: status ? 'success' : 'error'
    };
  };

  const getOverallHealth = () => {
    if (!clusterData) return { status: 'unknown', color: 'default', score: 0 };

    const services = ['dask', 'ollama', 'webui'];
    const runningServices = services.filter(service => clusterData[`${service}_running`]).length;
    const score = (runningServices / services.length) * 100;

    if (score === 100) return { status: 'healthy', color: 'success', score };
    if (score >= 50) return { status: 'degraded', color: 'warning', score };
    return { status: 'critical', color: 'error', score };
  };

  const getResourceStatus = (value, thresholds = { warning: 70, critical: 85 }) => {
    if (value >= thresholds.critical) return { status: 'critical', color: 'error' };
    if (value >= thresholds.warning) return { status: 'warning', color: 'warning' };
    return { status: 'normal', color: 'success' };
  };

  const health = getOverallHealth();

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
        <Typography variant="h6" sx={{ ml: 2 }}>Loading cluster status...</Typography>
      </Box>
    );
  }

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1" sx={{ display: 'flex', alignItems: 'center' }}>
          <TimelineIcon sx={{ mr: 2 }} />
          Cluster Status Overview
        </Typography>
        <Box display="flex" alignItems="center" gap={2}>
          <Chip
            label={`WebSocket: ${wsStatus}`}
            color={wsStatus === 'connected' ? 'success' : 'error'}
            size="small"
          />
          <Chip
            label={`Health: ${health.status}`}
            color={health.color}
            size="small"
          />
        </Box>
      </Box>

      {/* Overall Health Score */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>Cluster Health Score</Typography>
          <Box display="flex" alignItems="center" gap={2}>
            <Box sx={{ width: '100%', mr: 1 }}>
              <LinearProgress
                variant="determinate"
                value={health.score}
                color={health.color}
                sx={{ height: 10, borderRadius: 5 }}
              />
            </Box>
            <Typography variant="h6" color={`${health.color}.main`}>
              {health.score.toFixed(0)}%
            </Typography>
          </Box>
        </CardContent>
      </Card>

      <Grid container spacing={3}>
        {/* System Resources */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <StorageIcon sx={{ mr: 1 }} />
                System Resources
              </Typography>
              <Box display="flex" flexDirection="column" gap={2}>
                {systemMetrics && (
                  <>
                    <Box>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                        <Typography variant="body2">CPU Usage</Typography>
                        <Chip
                          label={`${systemMetrics.cpu_percent?.toFixed(1)}%`}
                          color={getResourceStatus(systemMetrics.cpu_percent).color}
                          size="small"
                        />
                      </Box>
                      <LinearProgress
                        variant="determinate"
                        value={systemMetrics.cpu_percent || 0}
                        color={getResourceStatus(systemMetrics.cpu_percent).color}
                        sx={{ height: 8, borderRadius: 4 }}
                      />
                    </Box>

                    <Box>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                        <Typography variant="body2">Memory Usage</Typography>
                        <Chip
                          label={`${systemMetrics.memory_percent?.toFixed(1)}%`}
                          color={getResourceStatus(systemMetrics.memory_percent).color}
                          size="small"
                        />
                      </Box>
                      <LinearProgress
                        variant="determinate"
                        value={systemMetrics.memory_percent || 0}
                        color={getResourceStatus(systemMetrics.memory_percent).color}
                        sx={{ height: 8, borderRadius: 4 }}
                      />
                    </Box>

                    <Box>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                        <Typography variant="body2">Disk Usage</Typography>
                        <Chip
                          label={`${systemMetrics.disk_percent?.toFixed(1)}%`}
                          color={getResourceStatus(systemMetrics.disk_percent).color}
                          size="small"
                        />
                      </Box>
                      <LinearProgress
                        variant="determinate"
                        value={systemMetrics.disk_percent || 0}
                        color={getResourceStatus(systemMetrics.disk_percent).color}
                        sx={{ height: 8, borderRadius: 4 }}
                      />
                    </Box>
                  </>
                )}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Services Status */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <CheckCircleIcon sx={{ mr: 1 }} />
                Services Status
              </Typography>
              <Box display="flex" flexDirection="column" gap={2}>
                {['dask', 'ollama', 'webui'].map((service) => {
                  const serviceStatus = getServiceStatus(service);
                  return (
                    <Box key={service} display="flex" justifyContent="space-between" alignItems="center">
                      <Box display="flex" alignItems="center">
                        <Box
                          sx={{
                            width: 12,
                            height: 12,
                            borderRadius: '50%',
                            bgcolor: serviceStatus.color === 'success' ? 'success.main' : 'error.main',
                            mr: 2
                          }}
                        />
                        <Typography variant="body2" sx={{ textTransform: 'capitalize' }}>
                          {service}
                        </Typography>
                      </Box>
                      <Chip
                        label={serviceStatus.status}
                        color={serviceStatus.color}
                        size="small"
                        variant="outlined"
                      />
                    </Box>
                  );
                })}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Workers Overview */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <PeopleIcon sx={{ mr: 1 }} />
                Workers Overview
              </Typography>
              <Box display="flex" flexDirection="column" gap={2}>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="body2">Total Workers</Typography>
                  <Typography variant="h6" color="primary">
                    {clusterData?.total_workers || 0}
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="body2">Active Workers</Typography>
                  <Typography variant="h6" color="success.main">
                    {clusterData?.active_workers || 0}
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="body2">Total CPU</Typography>
                  <Typography variant="body2">
                    {clusterData?.total_cpu?.toFixed(1) || 0}%
                  </Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="body2">Total Memory</Typography>
                  <Typography variant="body2">
                    {clusterData?.total_memory?.toFixed(1) || 0}%
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Recent Alerts */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <WarningIcon sx={{ mr: 1 }} />
                Recent Alerts
              </Typography>
              {alerts.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  No recent alerts
                </Typography>
              ) : (
                <List dense>
                  {alerts.slice(0, 5).map((alert, index) => (
                    <React.Fragment key={index}>
                      <ListItem sx={{ px: 0 }}>
                        <ListItemAvatar sx={{ minWidth: 40 }}>
                          <Avatar sx={{
                            width: 24,
                            height: 24,
                            bgcolor: alert.severity === 'CRITICAL' ? 'error.main' :
                                     alert.severity === 'WARNING' ? 'warning.main' : 'info.main'
                          }}>
                            {alert.severity === 'CRITICAL' ? <ErrorIcon sx={{ fontSize: 14 }} /> :
                             alert.severity === 'WARNING' ? <WarningIcon sx={{ fontSize: 14 }} /> :
                             <InfoIcon sx={{ fontSize: 14 }} />}
                          </Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={
                            <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                              {alert.component || 'SYSTEM'}
                            </Typography>
                          }
                          secondary={
                            <Typography variant="caption" color="text.secondary">
                              {alert.message?.length > 50
                                ? `${alert.message.substring(0, 50)}...`
                                : alert.message}
                            </Typography>
                          }
                        />
                      </ListItem>
                      {index < Math.min(alerts.length - 1, 4) && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Performance Metrics */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
            <SpeedIcon sx={{ mr: 1 }} />
            Performance Metrics
          </Typography>
          <Grid container spacing={3}>
            <Grid item xs={12} sm={6} md={3}>
              <Box textAlign="center">
                <Typography variant="h4" color="primary">
                  {clusterData?.dask_tasks_completed || 0}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Tasks Completed
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box textAlign="center">
                <Typography variant="h4" color="warning.main">
                  {clusterData?.dask_tasks_pending || 0}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Tasks Pending
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box textAlign="center">
                <Typography variant="h4" color="error.main">
                  {clusterData?.dask_tasks_failed || 0}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Tasks Failed
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box textAlign="center">
                <Typography variant="h4" color="success.main">
                  {clusterData?.dask_task_throughput?.toFixed(2) || 0}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Tasks/sec
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
}

export default ClusterStatus;
