import React, { useState, useEffect } from 'react';
import { Card, CardContent, Typography, Box, Button, TextField, MenuItem } from '@mui/material';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import { Refresh } from '@mui/icons-material';
import { useApi } from '../contexts/ApiContext';

// Mock data for demonstration
const mockMetricsData = [
  { time: '00:00', cpu: 30, memory: 50, network: 20, disk: 15 },
  { time: '04:00', cpu: 45, memory: 60, network: 35, disk: 20 },
  { time: '08:00', cpu: 55, memory: 70, network: 60, disk: 25 },
  { time: '12:00', cpu: 65, memory: 75, network: 75, disk: 30 },
  { time: '16:00', cpu: 70, memory: 80, network: 80, disk: 35 },
  { time: '20:00', cpu: 50, memory: 65, network: 55, disk: 25 },
];

const MetricsPage: React.FC = () => {
  const { api } = useApi();
  const [metrics, setMetrics] = useState(mockMetricsData);
  const [timeRange, setTimeRange] = useState('24h');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // TODO: Fetch real metrics data from API
    // fetchMetrics();
  }, [api, timeRange]);

  const handleRefresh = async () => {
    setLoading(true);
    try {
      // TODO: Implement metrics refresh
      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (error) {
      console.error('Failed to refresh metrics:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" gutterBottom>
          System Metrics
        </Typography>
        <Box display="flex" gap={2}>
          <TextField
            select
            label="Time Range"
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            size="small"
            sx={{ minWidth: 120 }}
          >
            <MenuItem value="1h">Last Hour</MenuItem>
            <MenuItem value="24h">Last 24 Hours</MenuItem>
            <MenuItem value="7d">Last 7 Days</MenuItem>
            <MenuItem value="30d">Last 30 Days</MenuItem>
          </TextField>
          <Button
            variant="contained"
            startIcon={<Refresh />}
            onClick={handleRefresh}
            disabled={loading}
          >
            Refresh
          </Button>
        </Box>
      </Box>

      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
        {/* CPU and Memory Chart */}
        <Box sx={{ flex: '1 1 600px', minWidth: '600px' }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                CPU & Memory Usage
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={metrics}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="cpu" stroke="#8884d8" name="CPU %" />
                  <Line type="monotone" dataKey="memory" stroke="#82ca9d" name="Memory %" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Box>

        {/* Network and Disk Chart */}
        <Box sx={{ flex: '1 1 600px', minWidth: '600px' }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Network & Disk I/O
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={metrics}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="network" fill="#ffc658" name="Network %" />
                  <Bar dataKey="disk" fill="#ff7300" name="Disk %" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Box>

        {/* System Health Summary */}
        <Box sx={{ flex: '1 1 300px', minWidth: '300px' }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                System Health Summary
              </Typography>
              <Box sx={{ mt: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Average CPU: {Math.round(metrics.reduce((sum, m) => sum + m.cpu, 0) / metrics.length)}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Peak Memory: {Math.max(...metrics.map(m => m.memory))}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Total Data Points: {metrics.length}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Time Range: {timeRange}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Box>
      </Box>
    </Box>
  );
};

export default MetricsPage;
