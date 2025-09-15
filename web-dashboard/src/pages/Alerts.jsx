import React, { useEffect, useState } from 'react';
import {
  Typography,
  Box,
  Paper,
  Grid,
  Card,
  CardContent,
  Chip,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Divider,
  Tabs,
  Tab,
  Badge,
  IconButton,
  Tooltip,
  useTheme,
  Alert as MuiAlert
} from '@mui/material';
import {
  Error as ErrorIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  CheckCircle as CheckCircleIcon,
  Refresh as RefreshIcon,
  FilterList as FilterIcon
} from '@mui/icons-material';
import axios from 'axios';

function AlertsEnhanced() {
  const [alerts, setAlerts] = useState([]);
  const [filteredAlerts, setFilteredAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState(0);
  const theme = useTheme();

  const fetchAlerts = async () => {
    try {
      const response = await axios.get('/api/alerts?limit=100');
      const alertData = response.data || [];
      setAlerts(alertData);
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch alerts:', error);
      setLoading(false);
    }
  };

  const getSeverityIcon = (severity) => {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return <ErrorIcon color="error" />;
      case 'warning':
        return <WarningIcon color="warning" />;
      case 'info':
        return <InfoIcon color="info" />;
      default:
        return <InfoIcon />;
    }
  };

  const getSeverityColor = (severity) => {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return 'error';
      case 'warning':
        return 'warning';
      case 'info':
        return 'info';
      default:
        return 'default';
    }
  };

  const getSeverityBgColor = (severity) => {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return theme.palette.error.main + '20';
      case 'warning':
        return theme.palette.warning.main + '20';
      case 'info':
        return theme.palette.info.main + '20';
      default:
        return theme.palette.grey[100];
    }
  };

  const formatTimestamp = (timestamp) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    const minutes = Math.floor(diff / 60000);

    if (minutes < 1) return 'Agora';
    if (minutes < 60) return `${minutes} minutos atrás`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours} horas atrás`;
    const days = Math.floor(hours / 24);
    return `${days} dias atrás`;
  };

  const filterAlerts = (tabIndex) => {
    let filtered = alerts;

    switch (tabIndex) {
      case 1: // Critical
        filtered = alerts.filter(alert => alert.severity === 'CRITICAL');
        break;
      case 2: // Warning
        filtered = alerts.filter(alert => alert.severity === 'WARNING');
        break;
      case 3: // Info
        filtered = alerts.filter(alert => alert.severity === 'INFO');
        break;
      default: // All
        filtered = alerts;
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    setFilteredAlerts(filtered);
  };

  const handleTabChange = (event, newValue) => {
    setActiveTab(newValue);
    filterAlerts(newValue);
  };

  const getTabCount = (severity) => {
    if (severity === 'all') return alerts.length;
    return alerts.filter(alert => alert.severity === severity).length;
  };

  useEffect(() => {
    fetchAlerts();
    const interval = setInterval(fetchAlerts, 10000); // Update every 10 seconds
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    filterAlerts(activeTab);
  }, [alerts, activeTab]);

  const criticalCount = getTabCount('CRITICAL');
  const warningCount = getTabCount('WARNING');
  const infoCount = getTabCount('INFO');

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          System Alerts
        </Typography>
        <Tooltip title="Refresh alerts">
          <IconButton onClick={fetchAlerts} disabled={loading}>
            <RefreshIcon />
          </IconButton>
        </Tooltip>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <Avatar sx={{ bgcolor: theme.palette.error.main, mr: 2 }}>
                  <ErrorIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" color="error">
                    {criticalCount}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Critical Alerts
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <Avatar sx={{ bgcolor: theme.palette.warning.main, mr: 2 }}>
                  <WarningIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" color="warning.main">
                    {warningCount}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Warnings
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <Avatar sx={{ bgcolor: theme.palette.info.main, mr: 2 }}>
                  <InfoIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" color="info.main">
                    {infoCount}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Info Messages
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Tabs for filtering */}
      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={activeTab}
          onChange={handleTabChange}
          indicatorColor="primary"
          textColor="primary"
          variant="fullWidth"
        >
          <Tab
            label={
              <Badge badgeContent={alerts.length} color="primary">
                All Alerts
              </Badge>
            }
          />
          <Tab
            label={
              <Badge badgeContent={criticalCount} color="error">
                Critical
              </Badge>
            }
          />
          <Tab
            label={
              <Badge badgeContent={warningCount} color="warning">
                Warnings
              </Badge>
            }
          />
          <Tab
            label={
              <Badge badgeContent={infoCount} color="info">
                Info
              </Badge>
            }
          />
        </Tabs>
      </Paper>

      {/* Alerts List */}
      {filteredAlerts.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h6" color="textSecondary" gutterBottom>
            {loading ? 'Loading alerts...' : 'No alerts found'}
          </Typography>
          <Typography variant="body2" color="textSecondary">
            {activeTab === 0 ? 'All alerts will appear here' :
             activeTab === 1 ? 'No critical alerts at this time' :
             activeTab === 2 ? 'No warning alerts at this time' :
             'No info alerts at this time'}
          </Typography>
        </Paper>
      ) : (
        <List>
          {filteredAlerts.map((alert, index) => (
            <React.Fragment key={`${alert.timestamp}-${index}`}>
              <ListItem
                sx={{
                  bgcolor: getSeverityBgColor(alert.severity),
                  borderRadius: 1,
                  mb: 1,
                  border: `1px solid ${theme.palette.divider}`
                }}
              >
                <ListItemAvatar>
                  <Avatar sx={{
                    bgcolor: theme.palette[getSeverityColor(alert.severity)].main
                  }}>
                    {getSeverityIcon(alert.severity)}
                  </Avatar>
                </ListItemAvatar>
                <ListItemText
                  primary={
                    <Box display="flex" alignItems="center" gap={1}>
                      <Typography variant="subtitle1" component="span">
                        {alert.component || 'SYSTEM'}
                      </Typography>
                      <Chip
                        label={alert.severity}
                        color={getSeverityColor(alert.severity)}
                        size="small"
                      />
                    </Box>
                  }
                  secondary={
                    <Box>
                      <Typography variant="body1" sx={{ mb: 1 }}>
                        {alert.message}
                      </Typography>
                      <Typography variant="caption" color="textSecondary">
                        {formatTimestamp(alert.timestamp)}
                      </Typography>
                    </Box>
                  }
                />
              </ListItem>
              {index < filteredAlerts.length - 1 && <Divider />}
            </React.Fragment>
          ))}
        </List>
      )}

      {/* Recent Critical Alert Banner */}
      {criticalCount > 0 && activeTab === 0 && (
        <MuiAlert
          severity="error"
          sx={{ mt: 3 }}
          action={
            <Chip
              label={`${criticalCount} Critical`}
              color="error"
              size="small"
              onClick={() => setActiveTab(1)}
            />
          }
        >
          <Typography variant="subtitle2">
            Critical alerts detected
          </Typography>
          <Typography variant="body2">
            Click to view critical alerts that require immediate attention
          </Typography>
        </MuiAlert>
      )}
    </Box>
  );
}

export default AlertsEnhanced;
