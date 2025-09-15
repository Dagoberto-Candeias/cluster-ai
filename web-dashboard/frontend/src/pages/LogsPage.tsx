import React, { useState, useEffect } from 'react';
import { Card, CardContent, Typography, Box, Button, TextField, MenuItem, List, ListItem, ListItemText, Chip, Alert } from '@mui/material';
import { Refresh, Download, Warning, Error, Info } from '@mui/icons-material';
import { useApi } from '../contexts/ApiContext';

interface AlertInfo {
  timestamp: string;
  severity: string;
  component: string;
  message: string;
}

const defaultAlerts: AlertInfo[] = [];

const LogsPage: React.FC = () => {
  const { api } = useApi();
  const [logs, setLogs] = useState<AlertInfo[]>(defaultAlerts);
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'ERROR': return 'error';
      case 'WARN': return 'warning';
      case 'INFO': return 'info';
      case 'DEBUG': return 'default';
      default: return 'default';
    }
  };

  const fetchLogs = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/alerts?limit=100');
      setLogs(response.data);
    } catch (err) {
      console.error('Failed to fetch logs:', err);
      setError('Failed to load logs.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [api]);

  const handleRefresh = async () => {
    await fetchLogs();
  };

  const handleExport = () => {
    const logText = logs.map(log =>
      `[${log.timestamp}] [${log.severity}] [${log.component}] ${log.message}`
    ).join('\n');

    const blob = new Blob([logText], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `cluster-logs-${new Date().toISOString().split('T')[0]}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const filteredLogs = filter === 'all' ? logs : logs.filter(log => log.severity === filter);

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" gutterBottom>
          System Logs
        </Typography>
        <Box display="flex" gap={2}>
          <TextField
            select
            label="Filter Level"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            size="small"
            sx={{ minWidth: 120 }}
          >
            <MenuItem value="all">All Levels</MenuItem>
            <MenuItem value="CRITICAL">Critical</MenuItem>
            <MenuItem value="WARNING">Warning</MenuItem>
            <MenuItem value="INFO">Info</MenuItem>
          </TextField>
          <Button
            variant="outlined"
            startIcon={<Download />}
            onClick={handleExport}
          >
            Export
          </Button>
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

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Recent Logs ({filteredLogs.length} entries)
          </Typography>
          <List sx={{ maxHeight: 600, overflow: 'auto' }}>
            {filteredLogs.map((log, index) => (
              <ListItem key={index} divider>
                <ListItemText
                  primary={
                    <Box display="flex" alignItems="center" gap={2}>
                      <Typography variant="body2" color="text.secondary" sx={{ minWidth: 160 }}>
                        {log.timestamp}
                      </Typography>
                      <Chip
                        label={log.severity}
                        color={getLevelColor(log.severity) as any}
                        size="small"
                        sx={{ minWidth: 80 }}
                      />
                      <Typography variant="body2" sx={{ minWidth: 120 }}>
                        {log.component}
                      </Typography>
                      <Typography variant="body1">
                        {log.message}
                      </Typography>
                    </Box>
                  }
                />
              </ListItem>
            ))}
          </List>
        </CardContent>
      </Card>
    </Box>
  );
};

export default LogsPage;
