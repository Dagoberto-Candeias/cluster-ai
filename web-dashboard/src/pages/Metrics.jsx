import React, { useEffect, useState } from 'react';
import {
  Typography,
  Box,
  Paper,
  Grid,
  Card,
  CardContent,
  Tabs,
  Tab,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Button,
  Alert,
  useTheme
} from '@mui/material';
import {
  Timeline as TimelineIcon,
  BarChart as BarChartIcon,
  ShowChart as LineChartIcon,
  PieChart as PieChartIcon,
  Download as DownloadIcon
} from '@mui/icons-material';
import axios from 'axios';
import Charts from '../components/Charts';

function Metrics() {
  const theme = useTheme();
  const [metricsData, setMetricsData] = useState([]);
  const [filteredData, setFilteredData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState(0);
  const [timeRange, setTimeRange] = useState('1h');
  const [metricType, setMetricType] = useState('all');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  useEffect(() => {
    fetchMetrics();
  }, [timeRange]);

  useEffect(() => {
    filterMetrics();
  }, [metricsData, metricType]);

  const fetchMetrics = async () => {
    setLoading(true);
    try {
      // Calculate limit based on time range
      const limit = getLimitFromTimeRange(timeRange);
      const response = await axios.get(`/api/metrics/system?limit=${limit}`);
      const data = response.data || [];
      setMetricsData(data);
    } catch (error) {
      console.error('Failed to fetch metrics:', error);
    } finally {
      setLoading(false);
    }
  };

  const getLimitFromTimeRange = (range) => {
    switch (range) {
      case '15m': return 15;
      case '30m': return 30;
      case '1h': return 60;
      case '6h': return 360;
      case '24h': return 1440;
      default: return 100;
    }
  };

  const filterMetrics = () => {
    let filtered = [...metricsData];

    // Filter by metric type
    if (metricType !== 'all') {
      // For now, we show all metrics since the API returns combined data
      // In a real implementation, you might have separate endpoints for different metrics
    }

    // Filter by date range if specified
    if (startDate && endDate) {
      const start = new Date(startDate);
      const end = new Date(endDate);
      filtered = filtered.filter(item => {
        const itemDate = new Date(item.timestamp);
        return itemDate >= start && itemDate <= end;
      });
    }

    setFilteredData(filtered);
  };

  const handleTabChange = (event, newValue) => {
    setActiveTab(newValue);
  };

  const handleExportData = () => {
    const csvContent = [
      ['Timestamp', 'CPU %', 'Memory %', 'Disk %', 'Network RX', 'Network TX'],
      ...filteredData.map(item => [
        item.timestamp,
        item.cpu_percent || 0,
        item.memory_percent || 0,
        item.disk_percent || 0,
        item.network_rx || 0,
        item.network_tx || 0
      ])
    ].map(row => row.join(',')).join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `cluster-metrics-${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  const getMetricsSummary = () => {
    if (filteredData.length === 0) return null;

    const latest = filteredData[filteredData.length - 1];
    const averages = {
      cpu: filteredData.reduce((sum, item) => sum + (item.cpu_percent || 0), 0) / filteredData.length,
      memory: filteredData.reduce((sum, item) => sum + (item.memory_percent || 0), 0) / filteredData.length,
      disk: filteredData.reduce((sum, item) => sum + (item.disk_percent || 0), 0) / filteredData.length,
    };

    return { latest, averages };
  };

  const summary = getMetricsSummary();

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1" sx={{ display: 'flex', alignItems: 'center' }}>
          <BarChartIcon sx={{ mr: 2 }} />
          System Metrics
        </Typography>
        <Button
          variant="outlined"
          startIcon={<DownloadIcon />}
          onClick={handleExportData}
          disabled={filteredData.length === 0}
        >
          Export CSV
        </Button>
      </Box>

      {/* Controls */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Time Range</InputLabel>
              <Select
                value={timeRange}
                label="Time Range"
                onChange={(e) => setTimeRange(e.target.value)}
              >
                <MenuItem value="15m">Last 15 minutes</MenuItem>
                <MenuItem value="30m">Last 30 minutes</MenuItem>
                <MenuItem value="1h">Last hour</MenuItem>
                <MenuItem value="6h">Last 6 hours</MenuItem>
                <MenuItem value="24h">Last 24 hours</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Metric Type</InputLabel>
              <Select
                value={metricType}
                label="Metric Type"
                onChange={(e) => setMetricType(e.target.value)}
              >
                <MenuItem value="all">All Metrics</MenuItem>
                <MenuItem value="cpu">CPU Only</MenuItem>
                <MenuItem value="memory">Memory Only</MenuItem>
                <MenuItem value="disk">Disk Only</MenuItem>
                <MenuItem value="network">Network Only</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <TextField
              label="Start Date"
              type="datetime-local"
              size="small"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
              fullWidth
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <TextField
              label="End Date"
              type="datetime-local"
              size="small"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
              fullWidth
            />
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <Button
              variant="contained"
              onClick={filterMetrics}
              fullWidth
            >
              Apply Filters
            </Button>
          </Grid>
          <Grid item xs={12} sm={6} md={2}>
            <Button
              variant="outlined"
              onClick={() => {
                setStartDate('');
                setEndDate('');
                setMetricType('all');
                filterMetrics();
              }}
              fullWidth
            >
              Clear Filters
            </Button>
          </Grid>
        </Grid>
      </Paper>

      {/* Summary Cards */}
      {summary && (
        <Grid container spacing={3} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>Current CPU</Typography>
                <Typography variant="h4" color="primary">
                  {summary.latest.cpu_percent?.toFixed(1)}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Avg: {summary.averages.cpu.toFixed(1)}%
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>Current Memory</Typography>
                <Typography variant="h4" color="primary">
                  {summary.latest.memory_percent?.toFixed(1)}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Avg: {summary.averages.memory.toFixed(1)}%
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>Current Disk</Typography>
                <Typography variant="h4" color="primary">
                  {summary.latest.disk_percent?.toFixed(1)}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Avg: {summary.averages.disk.toFixed(1)}%
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>Data Points</Typography>
                <Typography variant="h4" color="primary">
                  {filteredData.length}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Total readings
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Charts Tabs */}
      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={activeTab}
          onChange={handleTabChange}
          indicatorColor="primary"
          textColor="primary"
          variant="fullWidth"
        >
          <Tab icon={<LineChartIcon />} label="Line Charts" />
          <Tab icon={<BarChartIcon />} label="Bar Charts" />
          <Tab icon={<TimelineIcon />} label="Combined View" />
          <Tab icon={<PieChartIcon />} label="Summary" />
        </Tabs>
      </Paper>

      {/* Charts Content */}
      {loading ? (
        <Alert severity="info">Loading metrics data...</Alert>
      ) : filteredData.length === 0 ? (
        <Alert severity="warning">No metrics data available for the selected time range.</Alert>
      ) : (
        <Box>
          {activeTab === 0 && (
            <Charts data={filteredData} chartType="line" />
          )}
          {activeTab === 1 && (
            <Charts data={filteredData} chartType="bar" />
          )}
          {activeTab === 2 && (
            <Charts data={filteredData} chartType="combined" />
          )}
          {activeTab === 3 && (
            <Charts data={filteredData} chartType="summary" />
          )}
        </Box>
      )}
    </Box>
  );
}

export default Metrics;
