import React, { useState, useEffect } from 'react';
import { Grid, Card, CardContent, Typography, Box, LinearProgress, Chip, Alert } from '@mui/material';
import { Memory, Storage, People, Speed, CheckCircle, Error, Warning } from '@mui/icons-material';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { useApi } from '../contexts/ApiContext';

interface ClusterStatus {
  total_workers: number;
  active_workers: number;
  total_cpu: number;
  total_memory: number;
  status: string;
  ollama_running: boolean;
  dask_running: boolean;
  webui_running: boolean;
  dask_tasks_completed: number;
  dask_tasks_failed: number;
  dask_tasks_pending: number;
  dask_tasks_processing: number;
  dask_task_throughput: number;
  dask_avg_task_time: number;
}

interface SystemMetrics {
  timestamp: string;
  cpu_percent: number;
  memory_percent: number;
  disk_percent: number;
  network_rx: number;
  network_tx: number;
}

const defaultSystemData = {
  cpu: 0,
  memory: 0,
  storage: 0,
  activeWorkers: 0,
  totalWorkers: 0,
  gpuUsage: 0,
};

const defaultClusterStatus: ClusterStatus = {
  total_workers: 0,
  active_workers: 0,
  total_cpu: 0,
  total_memory: 0,
  status: 'unknown',
  ollama_running: false,
  dask_running: false,
  webui_running: false,
  dask_tasks_completed: 0,
  dask_tasks_failed: 0,
  dask_tasks_pending: 0,
  dask_tasks_processing: 0,
  dask_task_throughput: 0,
  dask_avg_task_time: 0,
};

const DashboardPage: React.FC = () => {
  const { api } = useApi();
  const [systemData, setSystemData] = useState(defaultSystemData);
  const [clusterStatus, setClusterStatus] = useState<ClusterStatus>(defaultClusterStatus);
  const [chartData, setChartData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);

        // Fetch cluster status
        const clusterResponse = await api.get('/cluster/status');
        const clusterData = clusterResponse.data;
        setClusterStatus(clusterData);

        // Update system data from cluster status
        setSystemData({
          cpu: clusterData.total_cpu / Math.max(clusterData.total_workers, 1),
          memory: clusterData.total_memory / Math.max(clusterData.total_workers, 1),
          storage: 0, // Will be updated from metrics
          activeWorkers: clusterData.active_workers,
          totalWorkers: clusterData.total_workers,
          gpuUsage: 0, // Not available yet
        });

        // Fetch system metrics for charts
        const metricsResponse = await api.get('/metrics/system?limit=24');
        const metricsData = metricsResponse.data;

        // Process metrics for chart
        const processedChartData = metricsData.slice(-24).map((metric: SystemMetrics, index: number) => ({
          time: new Date(metric.timestamp).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
          cpu: metric.cpu_percent,
          memory: metric.memory_percent,
          disk: metric.disk_percent,
          network: metric.network_rx / 1000, // Convert to KB/s
        }));

        setChartData(processedChartData);

        // Update storage from latest metric
        if (metricsData.length > 0) {
          const latestMetric = metricsData[metricsData.length - 1];
          setSystemData(prev => ({
            ...prev,
            storage: latestMetric.disk_percent,
          }));
        }

      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
        setError('Failed to load dashboard data. Using fallback data.');
        // Keep default data on error
      } finally {
        setLoading(false);
      }
    };

    fetchData();

    // Refresh data every 30 seconds
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, [api]);

  const MetricCard = ({ title, value, icon, color, unit = '%' }: any) => (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between">
          <Box>
            <Typography color="textSecondary" gutterBottom>
              {title}
            </Typography>
            <Typography variant="h4" component="div">
              {value}{unit}
            </Typography>
          </Box>
          <Box color={color}>
            {icon}
          </Box>
        </Box>
        <LinearProgress
          variant="determinate"
          value={value}
          sx={{ mt: 2, height: 8, borderRadius: 4 }}
        />
      </CardContent>
    </Card>
  );

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <Typography>Loading dashboard...</Typography>
      </Box>
    );
  }

  const workerData = [
    { name: 'Active', value: clusterStatus.active_workers, color: '#4caf50' },
    { name: 'Idle', value: Math.max(0, clusterStatus.total_workers - clusterStatus.active_workers), color: '#ff9800' },
  ];

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard Overview
      </Typography>

      {error && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Service Status */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          Service Status
        </Typography>
        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
          <Chip
            icon={clusterStatus.ollama_running ? <CheckCircle /> : <Error />}
            label="Ollama"
            color={clusterStatus.ollama_running ? "success" : "error"}
            variant="outlined"
          />
          <Chip
            icon={clusterStatus.dask_running ? <CheckCircle /> : <Error />}
            label="Dask"
            color={clusterStatus.dask_running ? "success" : "error"}
            variant="outlined"
          />
          <Chip
            icon={clusterStatus.webui_running ? <CheckCircle /> : <Error />}
            label="WebUI"
            color={clusterStatus.webui_running ? "success" : "error"}
            variant="outlined"
          />
          <Chip
            label={`Tasks: ${clusterStatus.dask_tasks_completed} ✓ / ${clusterStatus.dask_tasks_failed} ✗ / ${clusterStatus.dask_tasks_pending} ⏳`}
            color="info"
            variant="outlined"
          />
        </Box>
      </Box>

      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
        {/* System Metrics */}
        <Box sx={{ flex: '1 1 250px', minWidth: '250px' }}>
          <MetricCard
            title="CPU Usage"
            value={Math.round(systemData.cpu)}
            icon={<Speed fontSize="large" />}
            color="primary.main"
          />
        </Box>
        <Box sx={{ flex: '1 1 250px', minWidth: '250px' }}>
          <MetricCard
            title="Memory Usage"
            value={Math.round(systemData.memory)}
            icon={<Memory fontSize="large" />}
            color="secondary.main"
          />
        </Box>
        <Box sx={{ flex: '1 1 250px', minWidth: '250px' }}>
          <MetricCard
            title="Storage Usage"
            value={Math.round(systemData.storage)}
            icon={<Storage fontSize="large" />}
            color="warning.main"
          />
        </Box>
        <Box sx={{ flex: '1 1 250px', minWidth: '250px' }}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom>
                    Active Workers
                  </Typography>
                  <Typography variant="h4" component="div">
                    {systemData.activeWorkers}/{systemData.totalWorkers}
                  </Typography>
                </Box>
                <Box color="success.main">
                  <People fontSize="large" />
                </Box>
              </Box>
              <Box mt={2}>
                <Chip
                  label={`${clusterStatus.total_workers > 0 ? Math.round((systemData.activeWorkers / systemData.totalWorkers) * 100) : 0}% Active`}
                  color="success"
                  size="small"
                />
              </Box>
            </CardContent>
          </Card>
        </Box>

        {/* Charts */}
        <Box sx={{ flex: '2 1 500px', minWidth: '500px' }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                System Performance (Real-time)
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={chartData.length > 0 ? chartData : [
                  { time: '00:00', cpu: 0, memory: 0, disk: 0, network: 0 }
                ]}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="cpu" stroke="#8884d8" name="CPU %" />
                  <Line type="monotone" dataKey="memory" stroke="#82ca9d" name="Memory %" />
                  <Line type="monotone" dataKey="disk" stroke="#ffc658" name="Disk %" />
                  <Line type="monotone" dataKey="network" stroke="#ff7300" name="Network KB/s" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Box>

        <Box sx={{ flex: '1 1 300px', minWidth: '300px' }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Worker Status
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={workerData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, value }: any) => `${name} ${value}`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {workerData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Box>

        {/* Dask Performance Metrics */}
        {clusterStatus.dask_running && (
          <Box sx={{ flex: '1 1 300px', minWidth: '300px' }}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Dask Performance
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Throughput:</Typography>
                    <Typography variant="body2">{clusterStatus.dask_task_throughput.toFixed(1)} tasks/s</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Avg Task Time:</Typography>
                    <Typography variant="body2">{clusterStatus.dask_avg_task_time.toFixed(3)}s</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Tasks Processing:</Typography>
                    <Typography variant="body2">{clusterStatus.dask_tasks_processing}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Tasks Pending:</Typography>
                    <Typography variant="body2">{clusterStatus.dask_tasks_pending}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Box>
        )}
      </Box>
    </Box>
  );
};

export default DashboardPage;
