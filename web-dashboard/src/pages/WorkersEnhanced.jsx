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
  useTheme
} from '@mui/material';
import {
  Memory as MemoryIcon,
  Speed as SpeedIcon,
  Schedule as ScheduleIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Warning as WarningIcon
} from '@mui/icons-material';
import axios from 'axios';

function WorkersEnhanced() {
  const [workers, setWorkers] = useState([]);
  const [loading, setLoading] = useState(true);
  const theme = useTheme();

  const fetchWorkers = async () => {
    try {
      const response = await axios.get('/api/workers');
      setWorkers(response.data || []);
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch workers status:', error);
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status.toLowerCase()) {
      case 'active':
        return 'success';
      case 'inactive':
        return 'error';
      case 'busy':
        return 'warning';
      default:
        return 'default';
    }
  };

  const getStatusIcon = (status) => {
    switch (status.toLowerCase()) {
      case 'active':
        return <CheckCircleIcon color="success" />;
      case 'inactive':
        return <ErrorIcon color="error" />;
      case 'busy':
        return <WarningIcon color="warning" />;
      default:
        return <ScheduleIcon />;
    }
  };

  const formatMemory = (bytes) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    const minutes = Math.floor(diff / 60000);

    if (minutes < 1) return 'Agora';
    if (minutes < 60) return `${minutes}m atrás`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h atrás`;
    const days = Math.floor(hours / 24);
    return `${days}d atrás`;
  };

  useEffect(() => {
    fetchWorkers();
    const interval = setInterval(fetchWorkers, 5000); // Update every 5 seconds
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <Box p={3}>
        <Typography variant="h4" component="h1" gutterBottom>
          Workers Management
        </Typography>
        <LinearProgress />
      </Box>
    );
  }

  const activeWorkers = workers.filter(w => w.status === 'active').length;
  const totalTasks = workers.reduce((sum, w) => sum + (w.tasks || 0), 0);
  const totalMemory = workers.reduce((sum, w) => sum + (w.memory || 0), 0);
  const avgCpu = workers.length > 0 ? workers.reduce((sum, w) => sum + (w.cpu || 0), 0) / workers.length : 0;

  return (
    <Box p={3}>
      <Typography variant="h4" component="h1" gutterBottom>
        Workers Management
      </Typography>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Active Workers
              </Typography>
              <Typography variant="h4" component="div">
                {activeWorkers}/{workers.length}
              </Typography>
              <Chip
                label={`${Math.round((activeWorkers / workers.length) * 100)}% Active`}
                color={activeWorkers === workers.length ? 'success' : 'warning'}
                size="small"
              />
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Tasks
              </Typography>
              <Typography variant="h4" component="div">
                {totalTasks}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Running tasks
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Memory Usage
              </Typography>
              <Typography variant="h4" component="div">
                {formatMemory(totalMemory)}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Total allocated
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Avg CPU Usage
              </Typography>
              <Typography variant="h4" component="div">
                {Math.round(avgCpu * 100)}%
              </Typography>
              <LinearProgress
                variant="determinate"
                value={avgCpu * 100}
                sx={{ mt: 1 }}
              />
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Workers List */}
      {workers.length === 0 ? (
        <Paper sx={{ p: 3, textAlign: 'center' }}>
          <Typography variant="h6" color="textSecondary">
            No workers data available
          </Typography>
          <Typography variant="body2" color="textSecondary">
            Make sure Dask scheduler is running and workers are connected
          </Typography>
        </Paper>
      ) : (
        <Grid container spacing={3}>
          {workers.map((worker) => (
            <Grid item xs={12} md={6} key={worker.id}>
              <Card>
                <CardContent>
                  <Box display="flex" alignItems="center" mb={2}>
                    <Avatar sx={{ mr: 2, bgcolor: theme.palette.primary.main }}>
                      {worker.name.charAt(0).toUpperCase()}
                    </Avatar>
                    <Box flexGrow={1}>
                      <Typography variant="h6" component="div">
                        {worker.name}
                      </Typography>
                      <Box display="flex" alignItems="center" gap={1}>
                        {getStatusIcon(worker.status)}
                        <Chip
                          label={worker.status}
                          color={getStatusColor(worker.status)}
                          size="small"
                        />
                      </Box>
                    </Box>
                  </Box>

                  <List dense>
                    <ListItem>
                      <ListItemAvatar>
                        <Avatar sx={{ bgcolor: theme.palette.info.main }}>
                          <ScheduleIcon />
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary="Tasks"
                        secondary={`${worker.tasks || 0} running tasks`}
                      />
                    </ListItem>

                    <ListItem>
                      <ListItemAvatar>
                        <Avatar sx={{ bgcolor: theme.palette.success.main }}>
                          <MemoryIcon />
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary="Memory"
                        secondary={formatMemory(worker.memory || 0)}
                      />
                    </ListItem>

                    <ListItem>
                      <ListItemAvatar>
                        <Avatar sx={{ bgcolor: theme.palette.warning.main }}>
                          <SpeedIcon />
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary="CPU Usage"
                        secondary={`${Math.round((worker.cpu || 0) * 100)}%`}
                      />
                      <Box sx={{ width: 100, ml: 2 }}>
                        <LinearProgress
                          variant="determinate"
                          value={(worker.cpu || 0) * 100}
                        />
                      </Box>
                    </ListItem>

                    <Divider sx={{ my: 1 }} />

                    <ListItem>
                      <ListItemText
                        primary="Threads"
                        secondary={`${worker.nthreads || 0} threads available`}
                      />
                    </ListItem>

                    <ListItem>
                      <ListItemText
                        primary="Last Seen"
                        secondary={formatTime(worker.last_seen)}
                      />
                    </ListItem>
                  </List>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}
    </Box>
  );
}

export default WorkersEnhanced;
