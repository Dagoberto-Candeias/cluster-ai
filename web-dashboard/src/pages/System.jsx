import React, { useEffect, useState, useRef } from 'react';
import { Typography, Box, Paper, Grid, Chip, Alert, Tabs, Tab } from '@mui/material';
import axios from 'axios';
import Charts from '../components/Charts';

function System() {
  const [systemInfo, setSystemInfo] = useState({
    cpu_percent: null,
    memory_percent: null,
    disk_percent: null,
    dask_status: 'Unknown',
    gpu_info: { available: false, name: null },
  });

  const [historicalData, setHistoricalData] = useState([]);
  const [realtimeData, setRealtimeData] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const [lastUpdate, setLastUpdate] = useState(null);
  const [tabValue, setTabValue] = useState(0);
  const wsRef = useRef(null);

  const connectWebSocket = () => {
    const clientId = `system-${Date.now()}`;
    const wsUrl = `ws://localhost:8000/ws/${clientId}`;

    wsRef.current = new WebSocket(wsUrl);

    wsRef.current.onopen = () => {
      console.log('System WebSocket connected');
      setConnectionStatus('connected');
    };

    wsRef.current.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        console.log('System received WebSocket message:', message);

        if (message.type === 'realtime_update') {
          setRealtimeData(message.data);
          setLastUpdate(new Date(message.timestamp));

          // Update current metrics from real-time data
          if (message.data.system_metrics) {
            setSystemInfo(prev => ({
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
      console.log('System WebSocket disconnected');
      setConnectionStatus('disconnected');
      setTimeout(connectWebSocket, 5000);
    };

    wsRef.current.onerror = (error) => {
      console.error('System WebSocket error:', error);
      setConnectionStatus('error');
    };
  };

  const fetchHistoricalData = async () => {
    try {
      const response = await axios.get('/api/metrics/system?limit=50');
      if (response.data && response.data.length > 0) {
        // Format data for charts
        const formattedData = response.data.map(item => ({
          timestamp: new Date(item.timestamp).toLocaleTimeString(),
          cpu_percent: item.cpu_percent,
          memory_percent: item.memory_percent,
          disk_percent: item.disk_percent,
          network_rx: item.network_rx || 0,
          network_tx: item.network_tx || 0,
        }));
        setHistoricalData(formattedData);
      }
    } catch (error) {
      console.error('Failed to fetch historical data:', error);
    }
  };

  const fetchCurrentMetrics = async () => {
    try {
      const response = await axios.get('/api/metrics/system?limit=1');
      if (response.data && response.data.length > 0) {
        const latest = response.data[0];
        setSystemInfo(prev => ({
          ...prev,
          cpu_percent: latest.cpu_percent,
          memory_percent: latest.memory_percent,
          disk_percent: latest.disk_percent,
        }));
      }
    } catch (error) {
      console.error('Failed to fetch current metrics:', error);
    }
  };

  useEffect(() => {
    fetchCurrentMetrics();
    fetchHistoricalData();
    connectWebSocket();

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  const handleTabChange = (event, newValue) => {
    setTabValue(newValue);
  };

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
          System Monitoring
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

      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={tabValue} onChange={handleTabChange} aria-label="system monitoring tabs">
          <Tab label="Current Metrics" />
          <Tab label="Historical Charts" />
          <Tab label="System Details" />
        </Tabs>
      </Box>

      {tabValue === 0 && (
        <Grid container spacing={3} sx={{ mt: 1 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h6">CPU Usage</Typography>
              <Typography variant="h4" color={systemInfo.cpu_percent > 80 ? 'error' : 'primary'}>
                {systemInfo.cpu_percent !== null ? `${systemInfo.cpu_percent.toFixed(1)}%` : '--'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Real-time
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h6">Memory Usage</Typography>
              <Typography variant="h4" color={systemInfo.memory_percent > 80 ? 'error' : 'primary'}>
                {systemInfo.memory_percent !== null ? `${systemInfo.memory_percent.toFixed(1)}%` : '--'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Real-time
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h6">Disk Usage</Typography>
              <Typography variant="h4" color={systemInfo.disk_percent > 80 ? 'error' : 'primary'}>
                {systemInfo.disk_percent !== null ? `${systemInfo.disk_percent.toFixed(1)}%` : '--'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Real-time
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h6">Network RX</Typography>
              <Typography variant="h4" color="primary">
                {realtimeData?.system_metrics?.network_rx ? `${(realtimeData.system_metrics.network_rx / 1024).toFixed(1)} KB/s` : '--'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Real-time
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      )}

      {tabValue === 1 && (
        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" gutterBottom>
            System Metrics History (Last 50 readings)
          </Typography>
          {historicalData.length > 0 ? (
            <Charts data={historicalData} />
          ) : (
            <Alert severity="info">
              No historical data available. Data will appear as the system collects metrics.
            </Alert>
          )}
        </Box>
      )}

      {tabValue === 2 && (
        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" gutterBottom>
            System Details
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 2 }}>
                <Typography variant="subtitle1" gutterBottom>Service Status</Typography>
                <Box display="flex" flexDirection="column" gap={1}>
                  <Box display="flex" justifyContent="space-between">
                    <Typography>Dask Scheduler:</Typography>
                    <Chip
                      label={realtimeData?.cluster_status?.dask_running ? 'Running' : 'Stopped'}
                      color={realtimeData?.cluster_status?.dask_running ? 'success' : 'error'}
                      size="small"
                    />
                  </Box>
                  <Box display="flex" justifyContent="space-between">
                    <Typography>Ollama API:</Typography>
                    <Chip
                      label={realtimeData?.cluster_status?.ollama_running ? 'Running' : 'Stopped'}
                      color={realtimeData?.cluster_status?.ollama_running ? 'success' : 'error'}
                      size="small"
                    />
                  </Box>
                  <Box display="flex" justifyContent="space-between">
                    <Typography>OpenWebUI:</Typography>
                    <Chip
                      label={realtimeData?.cluster_status?.webui_running ? 'Running' : 'Stopped'}
                      color={realtimeData?.cluster_status?.webui_running ? 'success' : 'error'}
                      size="small"
                    />
                  </Box>
                </Box>
              </Paper>
            </Grid>

            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 2 }}>
                <Typography variant="subtitle1" gutterBottom>System Information</Typography>
                <Box display="flex" flexDirection="column" gap={1}>
                  <Typography variant="body2">
                    <strong>Active Workers:</strong> {realtimeData?.active_workers ?? '--'}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Total Workers:</strong> {realtimeData?.workers_count ?? '--'}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Active Alerts:</strong> {realtimeData?.alerts_count ?? '--'}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Last Update:</strong> {lastUpdate ? lastUpdate.toLocaleString() : 'Never'}
                  </Typography>
                </Box>
              </Paper>
            </Grid>
          </Grid>
        </Box>
      )}
    </Box>
  );
}

export default System;
