import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  Alert,
  Skeleton,
  useTheme,
  Tabs,
  Tab,
  Paper
} from '@mui/material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import {
  Timeline as TimelineIcon,
  BarChart as BarChartIcon,
  PieChart as PieChartIcon,
  TrendingUp as TrendingUpIcon
} from '@mui/icons-material';
import axios from 'axios';
import { format } from 'date-fns';

const AdvancedMetrics = () => {
  const theme = useTheme();
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(true);
  const [metricsData, setMetricsData] = useState([]);
  const [clusterData, setClusterData] = useState(null);
  const [workersData, setWorkersData] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchMetricsData();
    const interval = setInterval(fetchMetricsData, 60000); // Update every minute
    return () => clearInterval(interval);
  }, []);

  const fetchMetricsData = async () => {
    try {
      setLoading(true);
      setError(null);

      const [metricsRes, clusterRes, workersRes] = await Promise.all([
        axios.get('http://localhost:8000/metrics/system?limit=50'),
        axios.get('http://localhost:8000/cluster/status'),
        axios.get('http://localhost:8000/workers')
      ]);

      if (metricsRes.data) {
        // Process metrics for charts
        const processedData = metricsRes.data.map(m => ({
          timestamp: new Date(m.timestamp),
          time: format(new Date(m.timestamp), 'HH:mm'),
          cpu: m.cpu_percent,
          memory: m.memory_percent,
          disk: m.disk_percent,
          network_rx: m.network_rx / 1024, // Convert to KB/s
          network_tx: m.network_tx / 1024
        }));
        setMetricsData(processedData);
      }

      setClusterData(clusterRes.data);
      setWorkersData(workersRes.data);

    } catch (err) {
      console.error('Failed to fetch metrics data:', err);
      setError('Failed to load metrics data. Please check if the backend is running.');
    } finally {
      setLoading(false);
    }
  };

  const handleTabChange = (event, newValue) => {
    setActiveTab(newValue);
  };

  // Colors for charts
  const COLORS = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#00ff00'];

  // Worker status distribution for pie chart
  const workerStatusData = workersData.reduce((acc, worker) => {
    const status = worker.status || 'unknown';
    acc[status] = (acc[status] || 0) + 1;
    return acc;
  }, {});

  const pieData = Object.entries(workerStatusData).map(([status, count], index) => ({
    name: status.charAt(0).toUpperCase() + status.slice(1),
    value: count,
    color: COLORS[index % COLORS.length]
  }));

  // Performance metrics for bar chart
  const performanceData = [
    {
      name: 'CPU',
      current: metricsData[metricsData.length - 1]?.cpu || 0,
      average: metricsData.reduce((sum, m) => sum + m.cpu, 0) / metricsData.length || 0,
      peak: Math.max(...metricsData.map(m => m.cpu)) || 0
    },
    {
      name: 'Memory',
      current: metricsData[metricsData.length - 1]?.memory || 0,
      average: metricsData.reduce((sum, m) => sum + m.memory, 0) / metricsData.length || 0,
      peak: Math.max(...metricsData.map(m => m.memory)) || 0
    },
    {
      name: 'Disk',
      current: metricsData[metricsData.length - 1]?.disk || 0,
      average: metricsData.reduce((sum, m) => sum + m.disk, 0) / metricsData.length || 0,
      peak: Math.max(...metricsData.map(m => m.disk)) || 0
    }
  ];

  const renderTabContent = () => {
    switch (activeTab) {
      case 0: // System Resources
        return (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                    <TimelineIcon sx={{ mr: 1 }} />
                    System Resources Over Time
                  </Typography>
                  {loading ? (
                    <Skeleton variant="rectangular" height={400} />
                  ) : (
                    <ResponsiveContainer width="100%" height={400}>
                      <LineChart data={metricsData}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="time" />
                        <YAxis />
                        <Tooltip
                          labelFormatter={(label) => `Time: ${label}`}
                          formatter={(value, name) => [`${value.toFixed(1)}%`, name]}
                        />
                        <Line
                          type="monotone"
                          dataKey="cpu"
                          stroke="#8884d8"
                          strokeWidth={2}
                          name="CPU Usage"
                          dot={false}
                        />
                        <Line
                          type="monotone"
                          dataKey="memory"
                          stroke="#82ca9d"
                          strokeWidth={2}
                          name="Memory Usage"
                          dot={false}
                        />
                        <Line
                          type="monotone"
                          dataKey="disk"
                          stroke="#ffc658"
                          strokeWidth={2}
                          name="Disk Usage"
                          dot={false}
                        />
                      </LineChart>
                    </ResponsiveContainer>
                  )}
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                    <BarChartIcon sx={{ mr: 1 }} />
                    Network Activity
                  </Typography>
                  {loading ? (
                    <Skeleton variant="rectangular" height={300} />
                  ) : (
                    <ResponsiveContainer width="100%" height={300}>
                      <AreaChart data={metricsData}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="time" />
                        <YAxis />
                        <Tooltip
                          formatter={(value, name) => [`${value.toFixed(2)} KB/s`, name]}
                        />
                        <Area
                          type="monotone"
                          dataKey="network_rx"
                          stackId="1"
                          stroke="#8884d8"
                          fill="#8884d8"
                          fillOpacity={0.6}
                          name="Network RX"
                        />
                        <Area
                          type="monotone"
                          dataKey="network_tx"
                          stackId="1"
                          stroke="#82ca9d"
                          fill="#82ca9d"
                          fillOpacity={0.6}
                          name="Network TX"
                        />
                      </AreaChart>
                    </ResponsiveContainer>
                  )}
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                    <TrendingUpIcon sx={{ mr: 1 }} />
                    Performance Metrics
                  </Typography>
                  {loading ? (
                    <Skeleton variant="rectangular" height={300} />
                  ) : (
                    <ResponsiveContainer width="100%" height={300}>
                      <BarChart data={performanceData}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="name" />
                        <YAxis />
                        <Tooltip formatter={(value) => `${value.toFixed(1)}%`} />
                        <Bar dataKey="current" fill="#8884d8" name="Current" />
                        <Bar dataKey="average" fill="#82ca9d" name="Average" />
                        <Bar dataKey="peak" fill="#ffc658" name="Peak" />
                      </BarChart>
                    </ResponsiveContainer>
                  )}
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        );

      case 1: // Cluster Overview
        return (
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                    <PieChartIcon sx={{ mr: 1 }} />
                    Worker Status Distribution
                  </Typography>
                  {loading ? (
                    <Skeleton variant="rectangular" height={300} />
                  ) : (
                    <ResponsiveContainer width="100%" height={300}>
                      <PieChart>
                        <Pie
                          data={pieData}
                          cx="50%"
                          cy="50%"
                          labelLine={false}
                          label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                          outerRadius={80}
                          fill="#8884d8"
                          dataKey="value"
                        >
                          {pieData.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry.color} />
                          ))}
                        </Pie>
                        <Tooltip />
                      </PieChart>
                    </ResponsiveContainer>
                  )}
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Cluster Health Summary
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
                        <Typography variant="body1">Total Workers:</Typography>
                        <Chip
                          label={workersData.length}
                          color="primary"
                          size="small"
                        />
                      </Box>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                        <Typography variant="body1">Active Workers:</Typography>
                        <Chip
                          label={workersData.filter(w => w.status === 'active').length}
                          color="success"
                          size="small"
                        />
                      </Box>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                        <Typography variant="body1">Total CPU Cores:</Typography>
                        <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                          {clusterData?.total_cpu?.toFixed(1) || '--'}
                        </Typography>
                      </Box>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                        <Typography variant="body1">Total Memory:</Typography>
                        <Typography variant="body1" sx={{ fontWeight: 'bold' }}>
                          {clusterData?.total_memory?.toFixed(1) || '--'} GB
                        </Typography>
                      </Box>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                        <Typography variant="body1">Cluster Status:</Typography>
                        <Chip
                          label={clusterData?.status || 'Unknown'}
                          color={clusterData?.status === 'healthy' ? 'success' : 'warning'}
                          size="small"
                        />
                      </Box>
                    </Box>
                  )}
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Dask Performance Metrics
                  </Typography>
                  {loading ? (
                    <Box display="flex" gap={2}>
                      <Skeleton width={120} height={60} />
                      <Skeleton width={120} height={60} />
                      <Skeleton width={120} height={60} />
                      <Skeleton width={120} height={60} />
                    </Box>
                  ) : (
                    <Grid container spacing={2}>
                      <Grid item xs={6} sm={3}>
                        <Paper sx={{ p: 2, textAlign: 'center' }}>
                          <Typography variant="h4" color="primary">
                            {clusterData?.dask_tasks_completed || 0}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            Tasks Completed
                          </Typography>
                        </Paper>
                      </Grid>
                      <Grid item xs={6} sm={3}>
                        <Paper sx={{ p: 2, textAlign: 'center' }}>
                          <Typography variant="h4" color="warning.main">
                            {clusterData?.dask_tasks_pending || 0}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            Tasks Pending
                          </Typography>
                        </Paper>
                      </Grid>
                      <Grid item xs={6} sm={3}>
                        <Paper sx={{ p: 2, textAlign: 'center' }}>
                          <Typography variant="h4" color="error.main">
                            {clusterData?.dask_tasks_failed || 0}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            Tasks Failed
                          </Typography>
                        </Paper>
                      </Grid>
                      <Grid item xs={6} sm={3}>
                        <Paper sx={{ p: 2, textAlign: 'center' }}>
                          <Typography variant="h4" color="success.main">
                            {clusterData?.dask_task_throughput?.toFixed(2) || '0.00'}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            Tasks/sec
                          </Typography>
                        </Paper>
                      </Grid>
                    </Grid>
                  )}
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        );

      default:
        return null;
    }
  };

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
        Advanced Metrics Dashboard
      </Typography>

      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={activeTab}
          onChange={handleTabChange}
          indicatorColor="primary"
          textColor="primary"
          centered
        >
          <Tab label="System Resources" />
          <Tab label="Cluster Overview" />
        </Tabs>
      </Paper>

      {renderTabContent()}
    </Box>
  );
};

export default AdvancedMetrics;
