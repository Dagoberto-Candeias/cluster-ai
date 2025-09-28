import React, { useEffect, useState, useRef } from 'react';
import { Typography, Grid, Paper, Box, Chip, Alert, Card, CardContent, LinearProgress } from '@mui/material';
import {
  Memory as MemoryIcon,
  Storage as StorageIcon,
  Speed as SpeedIcon,
  People as PeopleIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon
} from '@mui/icons-material';
import axios from 'axios';

function Dashboard() {
  const [metrics, setMetrics] = useState({
    cpu_percent: null,
    memory_percent: null,
    disk_percent: null,
    dask_status: 'Unknown',
    gpu_info: { available: false, name: null },
  });

  const [realtimeData, setRealtimeData] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const [lastUpdate, setLastUpdate] = useState(null);
  const wsRef = useRef(null);

  const connectWebSocket = () => {
    const clientId = `dashboard-${Date.now()}`;
    const wsUrl = `ws://localhost:8000/ws/${clientId}`;

    wsRef.current = new WebSocket(wsUrl);

    wsRef.current.onopen = () => {
      console.log('WebSocket connected');
      setConnectionStatus('connected');
    };

    wsRef.current.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        console.log('Received WebSocket message:', message);

        if (message.type === 'realtime_update') {
          setRealtimeData(message.data);
          setLastUpdate(new Date(message.timestamp));

          // Update metrics from real-time data
          if (message.data.system_metrics) {
            setMetrics(prev => ({
              ...prev,
              cpu_percent: message.data.system_metrics.cpu_percent,
              memory_percent: message.data.system_metrics.memory_percent,
              disk_percent: message.data.system_metrics.disk_percent,
            }));
          }
        }
      } catch (error) {
        console.error('Failed to parse WebSocket message:', error);
      }
    };

    wsRef.current.onclose = () => {
      console.log('WebSocket disconnected');
      setConnectionStatus('disconnected');
      // Attempt to reconnect after 5 seconds
      setTimeout(connectWebSocket, 5000);
    };

    wsRef.current.onerror = (error) => {
      console.error('WebSocket error:', error);
      setConnectionStatus('error');
    };
  };

  const fetchInitialMetrics = async () => {
    try {
      const response = await axios.get('/api/system_metrics');
      if (response.data && response.data.length > 0) {
        const latest = response.data[response.data.length - 1];
        setMetrics(prev => ({
          ...prev,
          cpu_percent: latest.cpu_percent,
          memory_percent: latest.memory_percent,
          disk_percent: latest.disk_percent,
        }));
      }
    } catch (error) {
      console.error('Failed to fetch initial system metrics:', error);
    }
  };

  useEffect(() => {
    fetchInitialMetrics();
    connectWebSocket();

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  const getStatusColor = (status) => {
    switch (status) {
      case 'connected': return 'success';
      case 'disconnected': return 'error';
      case 'error': return 'warning';
      default: return 'default';
    }
  };

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h4" component="h1" gutterBottom>
          Dashboard
        </Typography>
        <Box display="flex" alignItems="center" gap={2}>
          <Chip
            label={`WebSocket: ${connectionStatus}`}
            color={getStatusColor(connectionStatus)}
            size="small"
          />
          {lastUpdate && (
            <Typography variant="caption" color="text.secondary">
              Última atualização: {lastUpdate.toLocaleTimeString()}
            </Typography>
          )}
        </Box>
      </Box>

      {connectionStatus === 'error' && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          Conexão WebSocket com problemas. Tentando reconectar...
        </Alert>
      )}

      {/* System Metrics Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <SpeedIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">CPU Usage</Typography>
              </Box>
              <Typography variant="h4" color={metrics.cpu_percent > 80 ? 'error' : 'primary'}>
                {metrics.cpu_percent !== null ? `${metrics.cpu_percent.toFixed(1)}%` : '--'}
              </Typography>
              <LinearProgress
                variant="determinate"
                value={metrics.cpu_percent || 0}
                color={metrics.cpu_percent > 80 ? 'error' : 'primary'}
                sx={{ mt: 1, height: 8, borderRadius: 4 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <MemoryIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Memory Usage</Typography>
              </Box>
              <Typography variant="h4" color={metrics.memory_percent > 80 ? 'error' : 'primary'}>
                {metrics.memory_percent !== null ? `${metrics.memory_percent.toFixed(1)}%` : '--'}
              </Typography>
              <LinearProgress
                variant="determinate"
                value={metrics.memory_percent || 0}
                color={metrics.memory_percent > 80 ? 'error' : 'primary'}
                sx={{ mt: 1, height: 8, borderRadius: 4 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <StorageIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Disk Usage</Typography>
              </Box>
              <Typography variant="h4" color={metrics.disk_percent > 80 ? 'error' : 'primary'}>
                {metrics.disk_percent !== null ? `${metrics.disk_percent.toFixed(1)}%` : '--'}
              </Typography>
              <LinearProgress
                variant="determinate"
                value={metrics.disk_percent || 0}
                color={metrics.disk_percent > 80 ? 'error' : 'primary'}
                sx={{ mt: 1, height: 8, borderRadius: 4 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <PeopleIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Active Workers</Typography>
              </Box>
              <Typography variant="h4" color="primary">
                {realtimeData?.active_workers ?? '--'}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                of {realtimeData?.workers_count ?? '--'} total
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Additional Metrics */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <PeopleIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Total Workers</Typography>
              </Box>
              <Typography variant="h4" color="primary">
                {realtimeData?.workers_count ?? '--'}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Registered workers
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <WarningIcon color={realtimeData?.alerts_count > 0 ? 'error' : 'primary'} sx={{ mr: 1 }} />
                <Typography variant="h6">Active Alerts</Typography>
              </Box>
              <Typography variant="h4" color={realtimeData?.alerts_count > 0 ? 'error' : 'primary'}>
                {realtimeData?.alerts_count ?? '--'}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                System alerts
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <CheckCircleIcon color={realtimeData?.cluster_status?.dask_running ? 'success' : 'error'} sx={{ mr: 1 }} />
                <Typography variant="h6">Dask Scheduler</Typography>
              </Box>
              <Typography variant="h4" color={realtimeData?.cluster_status?.dask_running ? 'success' : 'error'}>
                {realtimeData?.cluster_status?.dask_running ? 'Active' : 'Inactive'}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Distributed computing
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <CheckCircleIcon color={realtimeData?.cluster_status?.ollama_running ? 'success' : 'error'} sx={{ mr: 1 }} />
                <Typography variant="h6">Ollama API</Typography>
              </Box>
              <Typography variant="h4" color={realtimeData?.cluster_status?.ollama_running ? 'success' : 'error'}>
                {realtimeData?.cluster_status?.ollama_running ? 'Active' : 'Inactive'}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                AI model inference
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* System Status Overview */}
      <Box mt={4}>
        <Typography variant="h6" gutterBottom sx={{ mb: 3 }}>
          System Overview
        </Typography>
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                  <CheckCircleIcon sx={{ mr: 1 }} />
                  Service Status
                </Typography>
                <Box display="flex" flexDirection="column" gap={2}>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Box display="flex" alignItems="center">
                      <Box
                        sx={{
                          width: 12,
                          height: 12,
                          borderRadius: '50%',
                          bgcolor: realtimeData?.cluster_status?.dask_running ? 'success.main' : 'error.main',
                          mr: 2
                        }}
                      />
                      <Typography>Dask Scheduler</Typography>
                    </Box>
                    <Chip
                      label={realtimeData?.cluster_status?.dask_running ? 'Running' : 'Stopped'}
                      color={realtimeData?.cluster_status?.dask_running ? 'success' : 'error'}
                      size="small"
                      variant="outlined"
                    />
                  </Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Box display="flex" alignItems="center">
                      <Box
                        sx={{
                          width: 12,
                          height: 12,
                          borderRadius: '50%',
                          bgcolor: realtimeData?.cluster_status?.ollama_running ? 'success.main' : 'error.main',
                          mr: 2
                        }}
                      />
                      <Typography>Ollama API</Typography>
                    </Box>
                    <Chip
                      label={realtimeData?.cluster_status?.ollama_running ? 'Running' : 'Stopped'}
                      color={realtimeData?.cluster_status?.ollama_running ? 'success' : 'error'}
                      size="small"
                      variant="outlined"
                    />
                  </Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Box display="flex" alignItems="center">
                      <Box
                        sx={{
                          width: 12,
                          height: 12,
                          borderRadius: '50%',
                          bgcolor: realtimeData?.cluster_status?.webui_running ? 'success.main' : 'error.main',
                          mr: 2
                        }}
                      />
                      <Typography>OpenWebUI</Typography>
                    </Box>
                    <Chip
                      label={realtimeData?.cluster_status?.webui_running ? 'Running' : 'Stopped'}
                      color={realtimeData?.cluster_status?.webui_running ? 'success' : 'error'}
                      size="small"
                      variant="outlined"
                    />
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                  <SpeedIcon sx={{ mr: 1 }} />
                  Real-time Monitoring
                </Typography>
                <Box display="flex" flexDirection="column" gap={2}>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2">WebSocket Connection:</Typography>
                    <Chip
                      label={connectionStatus}
                      color={getStatusColor(connectionStatus)}
                      size="small"
                      variant="outlined"
                    />
                  </Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2">Last Update:</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {lastUpdate ? lastUpdate.toLocaleTimeString() : 'Never'}
                    </Typography>
                  </Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2">Update Interval:</Typography>
                    <Typography variant="body2" color="text.secondary">
                      5 seconds
                    </Typography>
                  </Box>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2">Active Connections:</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {realtimeData?.workers_count || 0} workers
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Box>
    </Box>
  );
}

export default Dashboard;
